Aplikasi Desktop "Stealth Overlay" - Flutter Edition
Proyek	StealthAI Desktop Assistant
Versi	2.0
Status	Draft - Update Framework
Target Platform	Windows 10/11, macOS 11+ (dengan batasan)
1. Pendahuluan
1.1 Latar Belakang
Aplikasi ini adalah alat bantu yang berjalan sebagai overlay transparan di atas layar, memungkinkan pengguna melihat informasi (seperti jawaban AI, catatan, kode) secara real-time tanpa terlihat oleh peserta lain saat screenshare. Konsep ini populer dalam skenario wawancara kerja, presentasi, atau panggilan klien.

1.2 Tujuan
Membangun aplikasi desktop yang:

Menampilkan overlay informasi di layar pengguna.

Secara efektif menyembunyikan overlay tersebut dari tangkapan layar (screen capture).

Berkomunikasi dengan browser untuk mendapatkan input (opsional).

Memiliki mekanisme panik darurat untuk menyembunyikan semuanya.

2. Arsitektur Teknis
2.1 Pilihan Teknologi
Komponen	Teknologi	Alasan
UI & Logika Utama	Flutter (Dart)	Satu kode basis untuk Windows & macOS. Akses langsung ke API OS melalui platform channel dan pustaka window_manager, flutter_acrylic. Contoh nyata: GhostLayer .
Stealth Mode Windows	SetWindowDisplayAffinity via HWND	Flutter dapat mengakses HWND untuk memanggil Win32 API secara langsung .
Stealth Mode macOS	NSWindow.sharingType = .none via Swift	Flutter dapat mengakses NSWindow melalui platform channel .
Komunikasi Browser	Chrome Native Messaging API	Ekstensi browser berkomunikasi dengan aplikasi desktop melalui stdio .
State Management	Provider atau Riverpod	Manajemen state yang sederhana dan teruji di Flutter .
Local Storage	Hive	Penyimpanan data lokal yang cepat dan ringan .
2.2 Diagram Arsitektur
text
Copy
Download
+---------------------------+      Chrome Native Messaging      +-------------------------------+
|  Browser (Ekstensi)       |  ==============================>   |   Aplikasi Desktop (Flutter)  |
|  - Menangkap input        |  <==============================   |   - Overlay UI (Flutter)      |
|  - Mengirim prompt ke AI  |                                   |   - Platform Channel (Swift)  |
+---------------------------+                                   +-------------------------------+
                                                                              ||
                                                                   Platform Channel (MethodChannel)
                                                                   - Windows: Get HWND -> SetWindowDisplayAffinity
                                                                   - macOS: Get NSWindow -> window.sharingType = .none
                                                                              ||
                                                                              \/
                                                                 +-------------------------------+
                                                                 | 🔒 OS Window Server (DWM)    |
                                                                 |    Mencegah window terekam    |
                                                                 +-------------------------------+
3. Fitur dan Spesifikasi Fungsional
3.1 Fitur Inti
ID	Fitur	Deskripsi	Prioritas
F-01	Stealth Mode	Jendela aplikasi tidak terlihat di screenshare/recording.	P0
F-02	Overlay Selalu di Atas	Jendela tetap di atas semua aplikasi lain (alwaysOnTop).	P0
F-03	Klik-Tembus (Click-Through)	Pengguna bisa berinteraksi dengan aplikasi di balik overlay tanpa gangguan.	P0
F-04	Input dari Browser	Ekstensi Chrome mengirim data real-time ke aplikasi desktop via Native Messaging.	P1
F-05	Catatan Tempel	Pengguna bisa menambahkan teks/catatan langsung di overlay.	P1
F-06	Panic Hide	Pintasan keyboard untuk langsung menyembunyikan semua konten.	P0
F-07	Opacity Control	Kontrol transparansi overlay agar nyaman dibaca.	P1
F-08	Deteksi OS & Peringatan	Deteksi versi macOS, tampilkan peringatan jika menggunakan macOS 15+ untuk fitur tertentu.	P1
4. Stealth Mode: Implementasi Teknis di Flutter
4.1 Windows: SetWindowDisplayAffinity
Metode: Menggunakan SetWindowDisplayAffinity dengan flag WDA_EXCLUDEFROMCAPTURE.

Efektivitas: Sangat efektif. Jendela benar-benar tidak ada di tangkapan layar dari Zoom, Google Meet (Chrome), Teams, OBS, dan Snipping Tool .

Implementasi di Flutter (Dart + Platform Channel):

dart
Copy
Download
// main.dart - Panggil platform channel
import 'package:flutter/services.dart';

class StealthService {
  static const MethodChannel _channel = MethodChannel('stealthai/window');

  static Future<void> enableStealthMode() async {
    try {
      await _channel.invokeMethod('enableStealthMode');
    } catch (e) {
      print('Failed to enable stealth mode: $e');
    }
  }

  static Future<void> disableStealthMode() async {
    try {
      await _channel.invokeMethod('disableStealthMode');
    } catch (e) {
      print('Failed to disable stealth mode: $e');
    }
  }
}
Implementasi di Windows (C++):

cpp
Copy
Download
// windows/runner/stealth_helper.cpp
#include <windows.h>
#include <dwmapi.h>

extern "C" __declspec(dllexport) void EnableStealthMode(HWND hwnd) {
    // WDA_EXCLUDEDFROMCAPTURE = 0x00000011
    SetWindowDisplayAffinity(hwnd, 0x00000011);
}

extern "C" __declspec(dllexport) void DisableStealthMode(HWND hwnd) {
    SetWindowDisplayAffinity(hwnd, WDA_NONE);
}
Catatan Khusus: Flutter/Windows tidak otomatis re-apply proteksi setelah window di-hide/show. Wajib re-apply di event show melalui platform channel.

4.2 macOS: NSWindow.sharingType
Metode: Mengatur window.sharingType = .none pada NSWindow.

Efektivitas: BERSYARAT.

✅ Berfungsi (Invisible): macOS 14 (Sonoma) ke bawah, Google Meet di Chrome/Firefox.

❌ GAGAL (Visible): macOS 15 (Sequoia) ke atas di aplikasi yang sudah migrasi ke ScreenCaptureKit (Zoom Desktop, Teams, QuickTime, Safari).

Implementasi di Flutter (Dart + Platform Channel):

dart
Copy
Download
// main.dart - Panggil platform channel
class StealthService {
  static const MethodChannel _channel = MethodChannel('stealthai/window');

  static Future<void> enableStealthMode() async {
    try {
      await _channel.invokeMethod('enableStealthMode');
    } catch (e) {
      print('Failed to enable stealth mode: $e');
    }
  }
}
Implementasi di macOS (Swift):

swift
Copy
Download
// macos/Runner/StealthHelper.swift
import Cocoa

@objc class StealthHelper: NSObject {
    @objc static func enableStealthMode(_ window: NSWindow) {
        if #available(macOS 10.15, *) {
            window.sharingType = .none
        }
    }
    
    @objc static func disableStealthMode(_ window: NSWindow) {
        if #available(macOS 10.15, *) {
            window.sharingType = .readOnly
        }
    }
    
    // Deteksi macOS 15+ untuk peringatan
    @objc static func isMacOSSequoiaOrLater() -> Bool {
        if #available(macOS 15.0, *) {
            return true
        }
        return false
    }
}
4.3 Peringatan Pengguna di macOS 15+
Tampilkan Peringatan di UI:

dart
Copy
Download
// main.dart
class StealthWarning extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: StealthService.isMacOSSequoiaOrLater(),
      builder: (context, snapshot) {
        if (snapshot.hasData && snapshot.data == true) {
          return AlertDialog(
            title: Text('⚠️ Peringatan macOS 15+'),
            content: Text(
              'Di macOS 15 (Sequoia) ke atas, fitur "invisible" '
              'tidak berfungsi di aplikasi berikut:\n'
              '• Zoom Desktop\n'
              '• Microsoft Teams\n'
              '• QuickTime Player\n'
              '• Safari\n\n'
              'Fitur masih berfungsi di Google Meet (Chrome/Firefox).'
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Saya Mengerti'),
              ),
            ],
          );
        }
        return SizedBox.shrink();
      },
    );
  }
}
4.4 Kemungkinan Solusi untuk macOS 15+ (Eksperimental)
Metode	Deskripsi	Status
Chromium Patch	Mengadopsi patch dari Chromium yang memanggil API tidak terdokumentasi.	Memerlukan rekompilasi Flutter/Engine.
Private API	Menggunakan API internal CGSSetWindowSharingState.	Berisiko dan tidak direkomendasikan.
Deteksi Layar	Mendeteksi jika aplikasi screen capture berjalan, lalu otomatis hide.	Sebagai lapisan perlindungan tambahan.
5. Fitur Non-Fungsional
ID	Kategori	Deskripsi
NF-01	Performa	Overlay harus ringan (< 5% CPU, < 200 MB RAM).
NF-02	Keamanan	Tidak ada data yang dikirim ke server eksternal tanpa izin. Data lokal dienkripsi dengan Hive.
NF-03	Kompatibilitas	Windows 10/11 (x64), macOS 11+ (Intel & Apple Silicon).
NF-04	Privasi	Nama proses tidak mencolok (gunakan "pmodule" atau "helper"). Tidak ada ikon di Dock (macOS) .
NF-05	Keandalan	Proteksi harus tetap aktif setelah window di-hide/show (Flutter/Windows).
6. Struktur Proyek Flutter yang Direkomendasikan
text
Copy
Download
stealthai_app/
├── lib/
│   ├── main.dart
│   ├── core/
│   │   ├── services/
│   │   │   ├── stealth_service.dart      # Platform channel untuk stealth mode
│   │   │   ├── hotkey_service.dart       # Global hotkey (via hotkey_manager)
│   │   │   └── storage_service.dart      # Hive untuk local storage
│   │   └── models/
│   │       ├── sticky_note.dart
│   │       └── settings.dart
│   ├── ui/
│   │   ├── screens/
│   │   │   └── overlay_screen.dart       # Main overlay window
│   │   ├── widgets/
│   │   │   ├── draggable_note.dart       # Catatan tempel
│   │   │   ├── status_hud.dart           # Indikator status di pojok layar
│   │   │   └── grid_overlay.dart         # Opsional grid untuk bantuan
│   │   └── theme/
│   │       └── app_theme.dart
│   └── utils/
│       └── platform_detector.dart        # Deteksi macOS/Windows
├── windows/
│   ├── runner/
│   │   └── stealth_helper.cpp            # C++ untuk SetWindowDisplayAffinity
│   └── CMakeLists.txt
├── macos/
│   ├── Runner/
│   │   └── StealthHelper.swift           # Swift untuk NSWindow.sharingType
│   └── Podfile
└── pubspec.yaml
Dependencies yang Dibutuhkan di pubspec.yaml:

yaml
Copy
Download
dependencies:
  flutter:
    sdk: flutter
  window_manager: ^0.3.0          # Kontrol window (alwaysOnTop, transparansi)
  flutter_acrylic: ^1.1.0         # Efek blur dan transparansi
  hotkey_manager: ^0.1.0          # Global hotkey
  hive: ^2.2.0                    # Local storage
  hive_flutter: ^1.1.0
  provider: ^6.0.0                # State management
7. Batasan & Risiko yang Diketahui
Risiko	Deskripsi	Mitigasi
macOS 15+ Incompatibility	sharingType = .none tidak berfungsi di aplikasi yang pakai ScreenCaptureKit .	Tampilkan peringatan di UI. Fokus ke Windows untuk solusi 100%. Pantau perkembangan Flutter/Chromium.
Deteksi Proses	Nama proses ("pmodule") bisa dideteksi oleh sistem proctoring .	Beri opsi untuk mengganti nama proses saat kompilasi.
Flutter Window Re-apply	Flutter/Windows tidak otomatis re-apply proteksi setelah window di-hide/show.	Implementasikan event listener di platform channel untuk re-apply.
Perilaku Pengguna	Jeda tidak wajar saat membaca overlay lebih mudah dideteksi.	Desain UI minimalis agar pengguna cepat membaca. Sertakan fitur "voice-to-text" untuk mengurangi jeda.
8. Rencana Pengembangan
Tahap	Durasi	Deliverable
1. Prototype	1 minggu	Aplikasi Flutter dasar dengan overlay transparan dan alwaysOnTop.
2. Stealth Mode	1 minggu	Implementasi platform channel untuk Windows (SetWindowDisplayAffinity) dan macOS (NSWindow.sharingType).
3. UI & Interaksi	1 minggu	Draggable notes, opacity control, click-through mode.
4. Native Messaging	1 minggu	Implementasi komunikasi dengan ekstensi Chrome via stdio.
5. Hotkey & Panic	3 hari	Global hotkey (Cmd+Shift+H) untuk panic hide.
6. Testing & Optimasi	1 minggu	Uji coba di berbagai platform dan aplikasi screenshare.
