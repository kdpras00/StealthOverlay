// stealth_audio.h — Windows WASAPI Loopback Audio Capture (Stub)
//
// TODO: Implement WASAPI loopback capture for Windows:
//   1. Use IAudioClient with AUDCLNT_STREAMFLAGS_LOOPBACK to capture system output
//   2. Buffer PCM audio in 4-second chunks
//   3. Convert to WAV format
//   4. Send to Whisper API (Groq/OpenAI) for transcription
//   5. Return transcript via Flutter MethodChannel
//
// Reference implementation:
//   - Initialize COM: CoInitializeEx(NULL, COINIT_APARTMENTTHREADED)
//   - Get default audio render device: IMMDeviceEnumerator → GetDefaultAudioEndpoint(eRender, eConsole)
//   - Activate audio client: IMMDevice → Activate(IID_IAudioClient)
//   - Initialize with loopback: IAudioClient → Initialize(AUDCLNT_SHAREMODE_SHARED,
//       AUDCLNT_STREAMFLAGS_LOOPBACK, ...)
//   - Get capture client: IAudioClient → GetService(IID_IAudioCaptureClient)
//   - Start capture: IAudioClient → Start()
//   - Loop: IAudioCaptureClient → GetBuffer() → process PCM → ReleaseBuffer()
//
// This file is a stub. Full implementation pending Windows testing environment.

#ifndef STEALTH_AUDIO_H_
#define STEALTH_AUDIO_H_

#include <cstdint>

// Placeholder functions for Flutter MethodChannel integration
namespace stealth_audio {

// Start WASAPI loopback capture
// Returns true if capture started successfully
bool StartSystemCapture(const char* api_key, const char* api_provider, const char* lang);

// Stop capture
void StopSystemCapture();

// Check if currently capturing
bool IsCapturing();

// Callback type for transcript results
typedef void (*TranscriptCallback)(const char* text);

// Set callback for transcript results
void SetTranscriptCallback(TranscriptCallback callback);

}  // namespace stealth_audio

#endif  // STEALTH_AUDIO_H_
