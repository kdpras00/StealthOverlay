// stealth_audio.cpp — Windows WASAPI Loopback Audio Capture (Stub)
//
// Stub implementation. See stealth_audio.h for full TODO.
// This will be implemented when testing on a Windows machine.

#include "stealth_audio.h"

namespace stealth_audio {

static bool g_capturing = false;
static TranscriptCallback g_callback = nullptr;

bool StartSystemCapture(const char* api_key, const char* api_provider, const char* lang) {
    // TODO: Implement WASAPI loopback capture
    // See stealth_audio.h for detailed implementation plan
    g_capturing = false;
    return false;
}

void StopSystemCapture() {
    g_capturing = false;
}

bool IsCapturing() {
    return g_capturing;
}

void SetTranscriptCallback(TranscriptCallback callback) {
    g_callback = callback;
}

}  // namespace stealth_audio
