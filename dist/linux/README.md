# WhisperCue - Linux Build Instructions

Langkah-langkah membuat executable rilis untuk Linux:

1. **Jalankan di Mesin Linux** (Ubuntu/Debian):
   ```bash
   sudo apt update && sudo apt install -y clang cmake ninja-build pkg-config libgtk-3-dev
   flutter pub get
   flutter build linux --release
   ```

2. **Lokasi Hasil Build**:
   - `build/linux/x64/release/bundle/`

3. **Distribusi**:
   - Salin seluruh isi folder `bundle/` (termasuk `whisper_cue` dan folder `lib/`).
