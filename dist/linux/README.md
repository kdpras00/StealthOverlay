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
   - Tarball rilis sudah menyertakan `WhisperCue.desktop` dan `whispercue.png` (logo).

4. **Pasang Ikon + Shortcut** (setelah extract tarball):
   ```bash
   sudo mkdir -p /opt/whispercue && sudo tar -xzf WhisperCue-Linux.tar.gz -C /opt/whispercue
   sudo cp /opt/whispercue/WhisperCue.desktop /usr/share/applications/whispercue.desktop
   sudo mkdir -p /usr/share/icons/hicolor/512x512/apps
   sudo cp /opt/whispercue/whispercue.png /usr/share/icons/hicolor/512x512/apps/whispercue.png
   sudo update-desktop-database
   ```
   Jika extract di lokasi lain, sesuaikan path `Exec=` di `WhisperCue.desktop`.
