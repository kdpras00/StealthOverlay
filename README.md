# WhisperCue

A high-performance AI desktop assistant application designed to display real-time information overlays during meetings, presentations, and interviews. Built with Flutter for macOS, Windows, and Linux.

[![Download macOS](https://img.shields.io/badge/Download-macOS-000000?style=for-the-badge&logo=apple&logoColor=white)](./dist/macos/whisper_cue-macOS.zip)
[![Download Windows](https://img.shields.io/badge/Download-Windows-0078D4?style=for-the-badge&logo=windows&logoColor=white)](#windows-windows-10--11)
[![Download Linux](https://img.shields.io/badge/Download-Linux-FCC624?style=for-the-badge&logo=linux&logoColor=black)](#linux)

---

## Key Features

- **Anti-Screen Capture (Stealth Mode)**: Excludes the overlay window from being captured by screen-sharing software (Zoom, Google Meet, Microsoft Teams, OBS).
- **Always-on-Top & Click-Through**: Keeps the window floating above all desktop applications with an optional click-through mode for uninterrupted workflow.
- **Real-Time Audio Transcription**: Automatically transcribes microphone and system audio via Whisper AI.
- **AI Assistance**: Provides instant AI answers and context-aware chat directly within the overlay interface.
- **Global Panic Shortcut**: Instantly toggles application UI visibility using global hotkeys.

---

## Quick Start Guide (Pre-Built Binaries)

### macOS (macOS 11+)

[![Download macOS Zip](https://img.shields.io/badge/Direct_Download-macOS_.zip-black?style=flat-square&logo=apple)](./dist/macos/whisper_cue-macOS.zip)

1. Download **[`whisper_cue-macOS.zip`](./dist/macos/whisper_cue-macOS.zip)**.
2. Extract the archive to locate `WhisperCue.app`.
3. Move `WhisperCue.app` to your `/Applications` directory.
4. **Launching the App**:
   - Double-click `WhisperCue.app`.
   - If prompted by macOS Gatekeeper ("App is from an unidentified developer"), right-click `WhisperCue.app`, select **Open**, and confirm **Open**.
   - Alternatively, navigate to **System Settings > Privacy & Security > Security** and click **Open Anyway**.
5. Grant Microphone access when prompted for real-time audio transcription.

> **Note for macOS 15+ (Sequoia)**: For maximum stealth effectiveness, share specific application windows rather than the full display, or use Google Meet via Google Chrome.

---

### Windows (Windows 10 & 11)

1. Download the pre-built Windows bundle from [dist/windows/](./dist/windows/README.md) or GitHub Releases.
2. Extract the contents of the ZIP archive.
3. Launch `whisper_cue.exe`.

> **Note for Windows**: Stealth Mode operates for both Window Sharing and Entire Display Sharing across Zoom, Teams, Meet, Discord, and OBS.

---

### Linux

1. Download the pre-built Linux bundle from [dist/linux/](./dist/linux/README.md) or GitHub Releases.
2. Extract the archive.
3. Make the executable runnable and launch:
   ```bash
   chmod +x whisper_cue
   ./whisper_cue
   ```

---

## Global Hotkeys

| Feature            | macOS Shortcut    | Windows / Linux Shortcut | Description                                             |
| :----------------- | :---------------- | :----------------------- | :------------------------------------------------------ |
| **Panic Hide**     | `Cmd + Shift + H` | `Ctrl + Shift + H`       | Instantly toggles application UI visibility.            |
| **Stealth Toggle** | `Cmd + Shift + S` | `Ctrl + Shift + S`       | Toggles window capture protection.                      |
| **Click-Through**  | `Cmd + Shift + L` | `Ctrl + Shift + L`       | Locks or unlocks mouse interaction through the overlay. |
| **Mic Capture**    | `Cmd + Shift + M` | `Ctrl + Shift + M`       | Toggles microphone audio recording and transcription.   |
| **Ask AI**         | `Cmd + Shift + A` | `Ctrl + Shift + A`       | Queries AI based on the latest transcription context.   |

---

## Best Practices

1. **Overlay Alignment**: Position the overlay near your webcam to maintain natural eye contact while reading.
2. **Transparency Tuning**: Adjust window opacity to maintain readability without obscuring background applications.
3. **Pre-Flight Verification**: Perform a test call on your preferred screen-sharing software prior to critical meetings.
