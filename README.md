# WhisperCue

A high-performance AI desktop assistant application designed to display real-time information overlays during meetings, presentations, and interviews. Built with Flutter for macOS, Windows, and Linux.

[![Download macOS](https://img.shields.io/badge/Download-macOS-000000?style=for-the-badge&logo=apple&logoColor=white)](https://github.com/kdpras00/WhisperCue/releases/latest/download/WhisperCue-macOS.zip)
[![Download Windows](https://img.shields.io/badge/Download-Windows-0078D4?style=for-the-badge&logo=windows&logoColor=white)](https://github.com/kdpras00/WhisperCue/releases/latest/download/WhisperCue-Windows.zip)
[![Download Linux](https://img.shields.io/badge/Download-Linux-FCC624?style=for-the-badge&logo=linux&logoColor=black)](https://github.com/kdpras00/WhisperCue/releases/latest/download/WhisperCue-Linux.tar.gz)

> **Note**: Releases are currently **unsigned**. macOS Gatekeeper and Windows SmartScreen will show a warning on first launch — this is expected (see install steps below). Verify downloads against `SHA256SUMS.txt` in each release.

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

[![Download macOS Zip](https://img.shields.io/badge/Direct_Download-macOS_.zip-black?style=flat-square&logo=apple)](https://github.com/kdpras00/WhisperCue/releases/latest/download/WhisperCue-macOS.zip)

1. Download **[`WhisperCue-macOS.zip`](https://github.com/kdpras00/WhisperCue/releases/latest/download/WhisperCue-macOS.zip)** (or `WhisperCue-macOS.dmg`).
2. Extract the archive to locate `WhisperCue.app`.
3. Move `WhisperCue.app` to your `/Applications` directory.
4. **Launching the App** (unsigned build → Gatekeeper warning is expected):
   - Right-click `WhisperCue.app`, select **Open**, and confirm **Open**.
   - Alternatively, navigate to **System Settings > Privacy & Security > Security** and click **Open Anyway**.
   - If the app launches very slowly or misbehaves, it is likely quarantined (AppTranslocation). Fix:
     ```bash
     xattr -dr com.apple.quarantine /Applications/WhisperCue.app
     ```
5. Grant Microphone access when prompted for real-time audio transcription.

> **Note for macOS 15+ (Sequoia)**: For maximum stealth effectiveness, share specific application windows rather than the full display, or use Google Meet via Google Chrome.

---

### Windows (Windows 10 & 11)

1. Download the pre-built Windows bundle: **[`WhisperCue-Windows.zip`](https://github.com/kdpras00/WhisperCue/releases/latest/download/WhisperCue-Windows.zip)** (build notes: [dist/windows/](./dist/windows/README.md)).
2. Extract the contents of the ZIP archive.
3. Launch `whisper_cue.exe`.
4. If SmartScreen warns about an unrecognized app (unsigned build), click **More info → Run anyway**.

> **Note for Windows**: Stealth Mode operates for both Window Sharing and Entire Display Sharing across Zoom, Teams, Meet, Discord, and OBS.

---

### Linux

1. Download the pre-built Linux bundle: **[`WhisperCue-Linux.tar.gz`](https://github.com/kdpras00/WhisperCue/releases/latest/download/WhisperCue-Linux.tar.gz)** (build notes: [dist/linux/](./dist/linux/README.md)).
2. Extract the archive.
3. Make the executable runnable and launch:
   ```bash
   chmod +x whisper_cue
   ./whisper_cue
   ```
4. Optional: install the app icon + launcher shortcut — see [dist/linux/README.md](./dist/linux/README.md).

### Verify Your Download

Compare the file hash against `SHA256SUMS.txt` from the same release:

```bash
shasum -a 256 WhisperCue-macOS.zip   # macOS
certutil -hashfile WhisperCue-Windows.zip SHA256   # Windows (cmd)
sha256sum WhisperCue-Linux.tar.gz   # Linux
```

---

## Global Hotkeys

| Feature            | macOS Shortcut    | Windows / Linux Shortcut | Description                                             |
| :----------------- | :---------------- | :----------------------- | :------------------------------------------------------ |
| **Panic Hide**     | `Cmd + Shift + H` | `Ctrl + Shift + H`       | Instantly toggles application UI visibility.            |
| **Stealth Toggle** | `Cmd + Shift + S` | `Ctrl + Shift + S`       | Toggles window capture protection.                      |
| **Click-Through**  | `Cmd + Shift + L` | `Ctrl + Shift + L`       | Locks or unlocks mouse interaction through the overlay. |
| **Mic Capture**    | `Cmd + Shift + M` | `Ctrl + Shift + M`       | Toggles microphone audio recording and transcription.   |
| **Ask AI**         | `Cmd + Enter`     | `Ctrl + Enter`           | Queries AI based on the latest transcription context.   |
| **Screenshot**     | `Cmd + Shift + C` | `Ctrl + Shift + C`       | Switches overlay to screenshot mode.                    |
| **Chat**           | `Cmd + K`         | `Ctrl + K`               | Switches overlay to chat mode.                          |

---

## Best Practices

1. **Overlay Alignment**: Position the overlay near your webcam to maintain natural eye contact while reading.
2. **Transparency Tuning**: Adjust window opacity to maintain readability without obscuring background applications.
3. **Pre-Flight Verification**: Perform a test call on your preferred screen-sharing software prior to critical meetings.

---

## Development

Prerequisites: Flutter stable (`flutter doctor`), Xcode (macOS), Visual Studio C++ workload (Windows), or `clang cmake ninja-build pkg-config libgtk-3-dev` (Linux).

```bash
flutter pub get
flutter run -d macos        # desktop app
flutter test                # unit/widget tests
flutter analyze
```

The marketing landing page lives in [`landing/`](./landing/README.md) (Flutter web, Deacon headings + Graphik body).

## Releasing

Builds are produced per-OS by GitHub Actions (`.github/workflows/build_desktop.yml`). To publish a release:

```bash
git tag v1.0.x
git push origin v1.0.x
```

This builds macOS, Windows, and Linux, then attaches `WhisperCue-macOS.zip`, `WhisperCue-Windows.zip`, `WhisperCue-Linux.tar.gz`, and `SHA256SUMS.txt` to the GitHub Release.
