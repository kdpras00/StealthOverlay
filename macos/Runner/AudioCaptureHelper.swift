import Cocoa
import ScreenCaptureKit
import AVFoundation

/// Captures system audio from specific apps or the entire system using ScreenCaptureKit.
/// Transcribes audio chunks via Whisper API (Groq/OpenAI) and returns text.
///
/// Flow: SCStream → PCM Buffer → WAV Chunk (5s + 1s overlap) → Whisper API → Transcript → EventChannel
@available(macOS 13.0, *)
class AudioCaptureHelper: NSObject, SCStreamDelegate, SCStreamOutput {

    // Configuration
    private var apiKey: String = ""
    private var apiProvider: String = "groq"
    private var lang: String = "id-ID"
    private var lastPromptContext: String = ""
    
    // System audio capture state (ScreenCaptureKit)
    private var stream: SCStream?
    private var isCapturing = false
    private var audioBuffer: [Float] = []
    private var sampleRate: Double = 48000.0
    private let chunkDurationSeconds: Double = 5.0
    
    // Overlap: keep last 1s of audio from previous chunk to avoid word-boundary cuts
    private let overlapDurationSeconds: Double = 1.0
    private var systemOverlapBuffer: [Float] = []
    
    // Mic capture state (AVAudioEngine)
    private var audioEngine: AVAudioEngine?
    private var isMicCapturing = false
    private var micBuffer: [Float] = []
    private let micSampleRate: Double = 16000.0  // 16kHz is optimal for Whisper
    private var micOverlapBuffer: [Float] = []
    
    // Callback for transcript results
    var onTranscript: ((String) -> Void)?
    
    // MARK: - Public API
    
    /// Start capturing audio. If targetAppBundleId is nil, captures all system audio.
    func startCapture(
        targetAppBundleId: String?,
        apiKey: String,
        apiProvider: String,
        lang: String
    ) async throws {
        guard !isCapturing else { return }
        
        self.apiKey = apiKey
        self.apiProvider = apiProvider
        self.lang = lang
        
        // Get shareable content
        let availableContent = try await SCShareableContent.excludingDesktopWindows(
            false, onScreenWindowsOnly: false
        )
        
        // Build content filter
        let filter: SCContentFilter
        
        if let bundleId = targetAppBundleId,
           let app = availableContent.applications.first(where: { $0.bundleIdentifier == bundleId }) {
            // Capture audio from a specific app — filter windows belonging to this app
            let appWindows = availableContent.windows.filter { $0.owningApplication?.bundleIdentifier == bundleId }
            // Use display-based filter including only this app (captures app audio)
            if let display = availableContent.displays.first {
                filter = SCContentFilter(display: display, including: [app], exceptingWindows: [])
            } else if let firstWindow = appWindows.first {
                filter = SCContentFilter(desktopIndependentWindow: firstWindow)
            } else {
                throw NSError(domain: "AudioCapture", code: 2, userInfo: [
                    NSLocalizedDescriptionKey: "No display or windows found for app \(bundleId)"
                ])
            }
        } else {
            // Capture all system audio (using display filter with audio only)
            guard let display = availableContent.displays.first else {
                throw NSError(domain: "AudioCapture", code: 1, userInfo: [
                    NSLocalizedDescriptionKey: "No display found"
                ])
            }
            filter = SCContentFilter(display: display, excludingApplications: [], exceptingWindows: [])
        }
        
        // Configure stream for audio-only capture
        let config = SCStreamConfiguration()
        config.capturesAudio = true
        config.excludesCurrentProcessAudio = true
        config.sampleRate = Int(sampleRate)
        config.channelCount = 1
        
        // We don't need video, but SCStream requires some video config
        config.width = 2
        config.height = 2
        config.minimumFrameInterval = CMTime(value: 1, timescale: 1) // 1 FPS minimum
        
        stream = SCStream(filter: filter, configuration: config, delegate: self)
        
        try stream?.addStreamOutput(self, type: .audio, sampleHandlerQueue: .global(qos: .userInteractive))
        
        try await stream?.startCapture()
        isCapturing = true
        audioBuffer = []
        systemOverlapBuffer = []
        
        NSLog("[AudioCapture] Started capturing audio | provider=\(apiProvider) | hasKey=\(apiKey.count > 0)")
    }
    
    /// Stop audio capture.
    func stopCapture() async {
        guard isCapturing else { return }
        
        do {
            try await stream?.stopCapture()
        } catch {
            NSLog("[AudioCapture] Stop error: \(error)")
        }
        
        // Process any remaining audio in buffer
        if !audioBuffer.isEmpty {
            await processAudioChunk()
        }
        
        stream = nil
        isCapturing = false
        audioBuffer = []
        systemOverlapBuffer = []
        NSLog("[AudioCapture] Stopped")
    }
    
    /// List running apps that might produce audio.
    static func listAudioSources() async -> [String] {
        do {
            let content = try await SCShareableContent.excludingDesktopWindows(false, onScreenWindowsOnly: false)
            return content.applications.compactMap { app in
                let name = app.applicationName
                guard !name.isEmpty else { return nil }
                return "\(name) (\(app.bundleIdentifier))"
            }
        } catch {
            NSLog("[AudioCapture] Failed to list sources: \(error)")
            return []
        }
    }
    
    // MARK: - Mic Capture (AVAudioEngine)
    
    /// Start capturing audio from the hardware microphone.
    func startMicCapture(apiKey: String, apiProvider: String, lang: String) throws {
        guard !isMicCapturing else { return }
        
        self.apiKey = apiKey
        self.apiProvider = apiProvider
        self.lang = lang
        
        let engine = AVAudioEngine()
        let inputNode = engine.inputNode
        let inputFormat = inputNode.outputFormat(forBus: 0)
        
        NSLog("[AudioCapture:Mic] Input format: \(inputFormat)")
        
        // Target format: 16kHz mono Float32 (optimal for Whisper)
        guard let targetFormat = AVAudioFormat(
            commonFormat: .pcmFormatFloat32,
            sampleRate: micSampleRate,
            channels: 1,
            interleaved: false
        ) else {
            throw NSError(domain: "AudioCapture", code: 10, userInfo: [
                NSLocalizedDescriptionKey: "Failed to create target audio format"
            ])
        }
        
        // Install tap on input node with format conversion
        let converter = AVAudioConverter(from: inputFormat, to: targetFormat)
        
        inputNode.installTap(onBus: 0, bufferSize: 4096, format: inputFormat) { [weak self] (buffer, time) in
            guard let self = self else { return }
            
            if let converter = converter {
                // Convert to target format
                let frameCapacity = AVAudioFrameCount(
                    Double(buffer.frameLength) * self.micSampleRate / inputFormat.sampleRate
                )
                guard let convertedBuffer = AVAudioPCMBuffer(
                    pcmFormat: targetFormat,
                    frameCapacity: frameCapacity
                ) else { return }
                
                var error: NSError?
                let status = converter.convert(to: convertedBuffer, error: &error) { inNumPackets, outStatus in
                    outStatus.pointee = .haveData
                    return buffer
                }
                
                if status == .haveData, let channelData = convertedBuffer.floatChannelData {
                    let samples = Array(UnsafeBufferPointer(
                        start: channelData[0],
                        count: Int(convertedBuffer.frameLength)
                    ))
                    self.micBuffer.append(contentsOf: samples)
                }
            } else {
                // No conversion needed, use raw samples
                if let channelData = buffer.floatChannelData {
                    let samples = Array(UnsafeBufferPointer(
                        start: channelData[0],
                        count: Int(buffer.frameLength)
                    ))
                    self.micBuffer.append(contentsOf: samples)
                }
            }
            
            // Check if we have enough for a chunk
            let samplesPerChunk = Int(self.micSampleRate * self.chunkDurationSeconds)
            if self.micBuffer.count >= samplesPerChunk {
                // Prepend overlap from previous chunk for word-boundary continuity
                let chunkSamples = Array(self.micBuffer.prefix(samplesPerChunk))
                let fullChunk = self.micOverlapBuffer + chunkSamples
                
                // Save last 1s as overlap for next chunk
                let overlapSamples = Int(self.micSampleRate * self.overlapDurationSeconds)
                self.micOverlapBuffer = Array(chunkSamples.suffix(overlapSamples))
                
                self.micBuffer = Array(self.micBuffer.dropFirst(samplesPerChunk))
                
                Task {
                    await self.processMicChunkData(fullChunk)
                }
            }
        }
        
        try engine.start()
        audioEngine = engine
        isMicCapturing = true
        micBuffer = []
        micOverlapBuffer = []
        
        NSLog("[AudioCapture:Mic] Started | provider=\(apiProvider) | sampleRate=\(micSampleRate)")
    }
    
    /// Stop mic capture.
    func stopMicCapture() {
        guard isMicCapturing else { return }
        
        audioEngine?.inputNode.removeTap(onBus: 0)
        audioEngine?.stop()
        audioEngine = nil
        isMicCapturing = false
        
        // Process remaining buffer
        if !micBuffer.isEmpty {
            let remaining = micBuffer
            micBuffer = []
            Task {
                await processMicChunkData(remaining)
            }
        }
        
        NSLog("[AudioCapture:Mic] Stopped")
    }
    
    private func processMicChunkData(_ samples: [Float]) async {
        guard !samples.isEmpty else { return }
        
        // Check for silence (Ignore background noise/hiss under RMS 0.025)
        let rms = sqrt(samples.map { $0 * $0 }.reduce(0, +) / Float(samples.count))
        if rms < 0.025 {
            return  // Skip silence/background noise
        }
        
        NSLog("[AudioCapture:Mic] Processing chunk | samples=\(samples.count) | RMS=\(String(format: "%.4f", rms))")
        
        let wavData = createWAVData(from: samples, sampleRate: micSampleRate, channels: 1)
        
        if let text = await transcribeWAV(wavData) {
            NSLog("[AudioCapture:Mic] Transcript: \(text)")
            DispatchQueue.main.async { [weak self] in
                self?.onTranscript?(text)
            }
        }
    }
    
    // MARK: - SCStreamOutput
    
    func stream(_ stream: SCStream, didOutputSampleBuffer sampleBuffer: CMSampleBuffer, of type: SCStreamOutputType) {
        guard type == .audio else { return }
        guard let blockBuffer = sampleBuffer.dataBuffer else { return }
        
        let length = CMBlockBufferGetDataLength(blockBuffer)
        var data = Data(count: length)
        data.withUnsafeMutableBytes { ptr in
            if let baseAddress = ptr.baseAddress {
                CMBlockBufferCopyDataBytes(blockBuffer, atOffset: 0, dataLength: length, destination: baseAddress)
            }
        }
        
        // Convert to Float32 samples
        let floatCount = length / MemoryLayout<Float>.size
        let samples = data.withUnsafeBytes { rawPtr -> [Float] in
            guard let ptr = rawPtr.baseAddress?.assumingMemoryBound(to: Float.self) else { return [] }
            return Array(UnsafeBufferPointer(start: ptr, count: floatCount))
        }
        
        audioBuffer.append(contentsOf: samples)
        
        // Check if we have enough for a chunk
        let samplesPerChunk = Int(sampleRate * chunkDurationSeconds)
        if audioBuffer.count >= samplesPerChunk {
            // Prepend overlap from previous chunk for word-boundary continuity
            let chunkSamples = Array(audioBuffer.prefix(samplesPerChunk))
            let fullChunk = systemOverlapBuffer + chunkSamples
            
            // Save last 1s as overlap for next chunk
            let overlapSamples = Int(sampleRate * overlapDurationSeconds)
            systemOverlapBuffer = Array(chunkSamples.suffix(overlapSamples))
            
            audioBuffer = Array(audioBuffer.dropFirst(samplesPerChunk))
            
            Task {
                await processAudioChunkData(fullChunk)
            }
        }
    }
    
    // MARK: - SCStreamDelegate
    
    func stream(_ stream: SCStream, didStopWithError error: Error) {
        NSLog("[AudioCapture] Stream stopped with error: \(error)")
        isCapturing = false
    }
    
    // MARK: - Audio Processing
    
    private func processAudioChunk() async {
        let chunk = audioBuffer
        audioBuffer = []
        await processAudioChunkData(chunk)
    }
    
    private func processAudioChunkData(_ samples: [Float]) async {
        guard !samples.isEmpty else { return }
        
        // Check if there's meaningful audio (Skip background noise/hiss under RMS 0.025)
        let rms = sqrt(samples.map { $0 * $0 }.reduce(0, +) / Float(samples.count))
        if rms < 0.025 {
            NSLog("[AudioCapture] Silence detected (RMS=\(rms)), skipping")
            return
        }
        
        NSLog("[AudioCapture] Processing chunk | samples=\(samples.count) | RMS=\(String(format: "%.4f", rms))")
        
        // Downsample from capture rate (48kHz) to 16kHz for optimal Whisper accuracy
        let targetRate = 16000.0
        let downsampled = downsampleAudio(samples, fromRate: sampleRate, toRate: targetRate)
        let wavData = createWAVData(from: downsampled, sampleRate: targetRate, channels: 1)
        
        // Send to Whisper API for transcription
        if let text = await transcribeWAV(wavData) {
            NSLog("[AudioCapture] Transcript: \(text)")
            DispatchQueue.main.async { [weak self] in
                self?.onTranscript?(text)
            }
        }
    }
    
    /// Downsample audio from one sample rate to another using linear interpolation.
    private func downsampleAudio(_ samples: [Float], fromRate: Double, toRate: Double) -> [Float] {
        guard fromRate > toRate else { return samples }
        let ratio = fromRate / toRate
        let outputLength = Int(Double(samples.count) / ratio)
        var output = [Float](repeating: 0, count: outputLength)
        
        for i in 0..<outputLength {
            let srcIndex = Double(i) * ratio
            let srcFloor = Int(srcIndex)
            let frac = Float(srcIndex - Double(srcFloor))
            
            if srcFloor + 1 < samples.count {
                output[i] = samples[srcFloor] * (1.0 - frac) + samples[srcFloor + 1] * frac
            } else if srcFloor < samples.count {
                output[i] = samples[srcFloor]
            }
        }
        
        return output
    }
    
    /// Create a WAV file from Float32 PCM samples.
    private func createWAVData(from samples: [Float], sampleRate: Double, channels: Int) -> Data {
        let bitsPerSample: Int = 16
        let bytesPerSample = bitsPerSample / 8
        let dataSize = samples.count * bytesPerSample
        let fileSize = 36 + dataSize
        
        var data = Data()
        
        // RIFF header
        data.append(contentsOf: "RIFF".utf8)
        data.append(contentsOf: withUnsafeBytes(of: UInt32(fileSize).littleEndian) { Array($0) })
        data.append(contentsOf: "WAVE".utf8)
        
        // fmt chunk
        data.append(contentsOf: "fmt ".utf8)
        data.append(contentsOf: withUnsafeBytes(of: UInt32(16).littleEndian) { Array($0) })
        data.append(contentsOf: withUnsafeBytes(of: UInt16(1).littleEndian) { Array($0) }) // PCM
        data.append(contentsOf: withUnsafeBytes(of: UInt16(channels).littleEndian) { Array($0) })
        data.append(contentsOf: withUnsafeBytes(of: UInt32(sampleRate).littleEndian) { Array($0) })
        let byteRate = UInt32(sampleRate) * UInt32(channels) * UInt32(bytesPerSample)
        data.append(contentsOf: withUnsafeBytes(of: byteRate.littleEndian) { Array($0) })
        let blockAlign = UInt16(channels * bytesPerSample)
        data.append(contentsOf: withUnsafeBytes(of: blockAlign.littleEndian) { Array($0) })
        data.append(contentsOf: withUnsafeBytes(of: UInt16(bitsPerSample).littleEndian) { Array($0) })
        
        // data chunk
        data.append(contentsOf: "data".utf8)
        data.append(contentsOf: withUnsafeBytes(of: UInt32(dataSize).littleEndian) { Array($0) })
        
        // Convert Float32 → Int16
        for sample in samples {
            let clamped = max(-1.0, min(1.0, sample))
            let int16Value = Int16(clamped * Float(Int16.max))
            data.append(contentsOf: withUnsafeBytes(of: int16Value.littleEndian) { Array($0) })
        }
        
        return data
    }
    
    /// Transcribe WAV data via Whisper API.
    private func transcribeWAV(_ wavData: Data) async -> String? {
        guard !apiKey.isEmpty else {
            NSLog("[AudioCapture] No API key for transcription")
            return nil
        }
        
        let endpoint: String
        let model: String
        
        switch apiProvider.lowercased() {
        case "openai":
            endpoint = "https://api.openai.com/v1/audio/transcriptions"
            model = "whisper-1"
        case "groq":
            endpoint = "https://api.groq.com/openai/v1/audio/transcriptions"
            model = "whisper-large-v3-turbo"
        default:
            endpoint = "https://api.groq.com/openai/v1/audio/transcriptions"
            model = "whisper-large-v3-turbo"
        }
        
        guard let url = URL(string: endpoint) else { return nil }
        
        let boundary = "Boundary-\(UUID().uuidString)"
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        var body = Data()
        
        // File field
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"audio.wav\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: audio/wav\r\n\r\n".data(using: .utf8)!)
        body.append(wavData)
        body.append("\r\n".data(using: .utf8)!)
        
        // Model field
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"model\"\r\n\r\n".data(using: .utf8)!)
        body.append("\(model)\r\n".data(using: .utf8)!)
        
        // Language field
        let shortLang = lang.components(separatedBy: "-").first ?? "id"
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"language\"\r\n\r\n".data(using: .utf8)!)
        body.append("\(shortLang)\r\n".data(using: .utf8)!)
        
        // Prompt field (gives Whisper context from previous segment to prevent hallucinations and misheard words)
        if !lastPromptContext.isEmpty {
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"prompt\"\r\n\r\n".data(using: .utf8)!)
            body.append("\(lastPromptContext)\r\n".data(using: .utf8)!)
        }
        
        // Temperature = 0 for deterministic output (no creative guessing on ambiguous audio)
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"temperature\"\r\n\r\n".data(using: .utf8)!)
        body.append("0\r\n".data(using: .utf8)!)
        
        // Response format = verbose_json for segment-level confidence filtering
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"response_format\"\r\n\r\n".data(using: .utf8)!)
        body.append("verbose_json\r\n".data(using: .utf8)!)
        
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        
        request.httpBody = body
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode != 200 {
                let errorBody = String(data: data, encoding: .utf8) ?? "unknown"
                NSLog("[AudioCapture] Whisper API error \(httpResponse.statusCode): \(errorBody.prefix(200))")
                return nil
            }
            
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                // With verbose_json, filter out low-confidence segments
                if let segments = json["segments"] as? [[String: Any]] {
                    let goodSegments = segments.compactMap { segment -> String? in
                        let noSpeechProb = segment["no_speech_prob"] as? Double ?? 0.0
                        let text = segment["text"] as? String ?? ""
                        
                        // Skip segments where Whisper thinks there's no speech (>60% probability)
                        if noSpeechProb > 0.6 {
                            NSLog("[AudioCapture] Skipping low-confidence segment (no_speech_prob=\(String(format: "%.2f", noSpeechProb))): \(text.prefix(50))")
                            return nil
                        }
                        return text.trimmingCharacters(in: .whitespacesAndNewlines)
                    }.filter { !$0.isEmpty }
                    
                    let fullText = goodSegments.joined(separator: " ").trimmingCharacters(in: .whitespacesAndNewlines)
                    if isHallucination(fullText) { return nil }
                    if fullText.count > 3 {
                        self.lastPromptContext = String(fullText.suffix(300))
                    }
                    return fullText.isEmpty ? nil : fullText
                }
                
                // Fallback: use top-level "text" if no segments
                if let text = json["text"] as? String {
                    let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
                    if isHallucination(trimmed) { return nil }
                    if trimmed.count > 3 {
                        self.lastPromptContext = String(trimmed.suffix(300))
                    }
                    return trimmed
                }
            }
            
            return nil
        } catch {
            NSLog("[AudioCapture] Whisper API request failed: \(error)")
            return nil
        }
    }
    
    private func isHallucination(_ text: String) -> Bool {
        return text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}
