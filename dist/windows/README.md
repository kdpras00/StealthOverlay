# WhisperCue - Windows Build Instructions

Langkah-langkah membuat installer/executable rilis untuk Windows:

1. **Jalankan di Mesin Windows** (dengan Visual Studio C++ Workload):
   ```cmd
   flutter pub get
   flutter build windows --release
   ```

2. **Lokasi Hasil Build**:
   - `build/windows/x64/runner/Release/`

3. **Distribusi**:
   - Salin seluruh isi folder `Release/` (termasuk `whisper_cue.exe` dan semua file `.dll`).
   - Atau gunakan **Inno Setup** / **NSIS** untuk mengemasnya menjadi 1 file installer (`whisper_cue_setup.exe`).
