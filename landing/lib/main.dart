import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';

enum UserOS { macOS, windows, linux }

void main() {
  runApp(const WhisperCueLandingApp());
}

class WhisperCueLandingApp extends StatelessWidget {
  const WhisperCueLandingApp({super.key});

  static TextStyle deaconStyle({
    double? fontSize,
    FontWeight? fontWeight,
    double? letterSpacing,
    Color? color,
    double? height,
  }) {
    return TextStyle(
      fontFamily: 'Deacon',
      fontFamilyFallback: const ['Graphik', 'sans-serif'],
      fontSize: fontSize,
      fontWeight: fontWeight ?? FontWeight.w600,
      letterSpacing: letterSpacing,
      color: color ?? const Color(0xFFF3EDE4),
      height: height,
    );
  }

  static TextStyle graphikStyle({
    double? fontSize,
    FontWeight? fontWeight,
    double? letterSpacing,
    Color? color,
    double? height,
  }) {
    return TextStyle(
      fontFamily: 'Graphik',
      fontFamilyFallback: const ['sans-serif'],
      fontSize: fontSize,
      fontWeight: fontWeight ?? FontWeight.normal,
      letterSpacing: letterSpacing,
      color: color ?? const Color(0xFFF3EDE4),
      height: height,
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'WhisperCue — Invisible AI Desktop Overlay Assistant',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF06090E),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF55DD4A),
          onPrimary: Color(0xFF0A1A08),
          secondary: Color(0xFF73D3EB),
          surface: Color(0xFF101722),
          onSurface: Color(0xFFF3EDE4),
        ),
        textTheme: TextTheme(
          displayLarge: graphikStyle(
            fontSize: 56.0,
            fontWeight: FontWeight.bold,
            letterSpacing: -1.2,
          ),
          headlineMedium: graphikStyle(
            fontSize: 36.0,
            fontWeight: FontWeight.bold,
            letterSpacing: -0.5,
          ),
          bodyLarge: graphikStyle(
            fontSize: 18.0,
            height: 1.6,
            color: const Color(0xFF94A3B8),
          ),
          bodyMedium: graphikStyle(
            fontSize: 15.0,
            height: 1.5,
          ),
          labelSmall: deaconStyle(
            fontSize: 12.0,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ),
      home: const LandingScreen(),
    );
  }
}

class LandingScreen extends StatefulWidget {
  const LandingScreen({super.key});

  @override
  State<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends State<LandingScreen> {
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _featuresKey = GlobalKey();
  final GlobalKey _downloadKey = GlobalKey();
  late VideoPlayerController _videoController;

  @override
  void initState() {
    super.initState();
    _videoController = VideoPlayerController.asset('assets/videos/examplevidio.mp4')
      ..initialize().then((_) {
        setState(() {});
        _videoController.setLooping(true);
        _videoController.setVolume(0.0);
        _videoController.play();
      });
  }

  @override
  void dispose() {
    _videoController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  UserOS get _detectedOS {
    switch (defaultTargetPlatform) {
      case TargetPlatform.windows:
        return UserOS.windows;
      case TargetPlatform.linux:
        return UserOS.linux;
      case TargetPlatform.macOS:
      case TargetPlatform.iOS:
      default:
        return UserOS.macOS;
    }
  }

  String get _primaryDownloadLabel {
    switch (_detectedOS) {
      case UserOS.windows:
        return 'Download Windows';
      case UserOS.linux:
        return 'Download Linux';
      case UserOS.macOS:
        return 'Download macOS';
    }
  }

  IconData get _primaryDownloadIcon {
    switch (_detectedOS) {
      case UserOS.windows:
        return Icons.window_rounded;
      case UserOS.linux:
        return Icons.terminal_rounded;
      case UserOS.macOS:
        return Icons.apple_rounded;
    }
  }

  VoidCallback get _primaryDownloadAction {
    switch (_detectedOS) {
      case UserOS.windows:
        return () => _showBuildGuideDialog(
              'Windows',
              'flutter pub get\nflutter build windows --release',
            );
      case UserOS.linux:
        return () => _showBuildGuideDialog(
              'Linux',
              'sudo apt install clang cmake ninja-build pkg-config libgtk-3-dev\nflutter pub get\nflutter build linux --release',
            );
      case UserOS.macOS:
        return () => _launchDownloadUrl('dist/macos/WhisperCue-macOS.dmg');
    }
  }

  Future<void> _launchDownloadUrl(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      debugPrint('Could not launch $url');
    }
  }

  void _showBuildGuideDialog(String platformName, String commands) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF101722),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Color(0xFF55DD4A)),
        ),
        title: Text(
          '$platformName Setup & Build Guide',
          style: WhisperCueLandingApp.deaconStyle(
            fontSize: 20,
            color: const Color(0xFFF3EDE4),
          ),
        ),
        content: SizedBox(
          width: 500,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'To run or compile WhisperCue natively on $platformName:',
                style: WhisperCueLandingApp.graphikStyle(
                  fontSize: 14,
                  color: const Color(0xFF94A3B8),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF04060A),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF334155)),
                ),
                child: SelectableText(
                  commands,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 13,
                    color: Color(0xFF55DD4A),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Note: Pre-built automated installer binaries are also compiled automatically via GitHub Actions.',
                style: WhisperCueLandingApp.graphikStyle(
                  fontSize: 12,
                  color: const Color(0xFF94A3B8),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Close',
              style: WhisperCueLandingApp.graphikStyle(
                color: const Color(0xFF55DD4A),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _scrollToSection(GlobalKey key) {
    final context = key.currentContext;
    if (context != null) {
      Scrollable.ensureVisible(
        context,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isMobile = screenWidth < 800;

    return Scaffold(
      backgroundColor: const Color(0xFF06090E),
      body: Stack(
        children: [
          // Main Scrollable Body
          SingleChildScrollView(
            controller: _scrollController,
            physics: const ClampingScrollPhysics(),
            child: Column(
              children: [
                const SizedBox(height: 100),

                // Hero Section
                RepaintBoundary(
                  child: _buildHeroSection(isMobile),
                ),

                const SizedBox(height: 80),

                // Interactive App Showcase Demo Frame
                RepaintBoundary(
                  child: _buildShowcaseFrame(isMobile),
                ),

                const SizedBox(height: 100),

                // Features Section
                RepaintBoundary(
                  child: Container(
                    key: _featuresKey,
                    child: _buildFeaturesSection(isMobile),
                  ),
                ),

                const SizedBox(height: 100),

                // Download Section
                RepaintBoundary(
                  child: Container(
                    key: _downloadKey,
                    child: _buildDownloadSection(isMobile),
                  ),
                ),

                const SizedBox(height: 100),

                // Footer
                RepaintBoundary(
                  child: _buildFooter(),
                ),
              ],
            ),
          ),

          // Sticky Header / Navbar
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: RepaintBoundary(
              child: _buildNavbar(isMobile),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // NAVBAR
  // ---------------------------------------------------------------------------
  Widget _buildNavbar(bool isMobile) {
    return Container(
      height: 72,
      padding: const EdgeInsets.symmetric(horizontal: 32),
      decoration: const BoxDecoration(
        color: Color(0xFF06090E),
        border: Border(
          bottom: BorderSide(color: Color(0x1FFFFFFF), width: 1),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  image: const DecorationImage(
                    image: AssetImage('assets/icons/logo.png'),
                    fit: BoxFit.cover,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF55DD4A).withOpacity(0.3),
                      blurRadius: 10,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'WhisperCue',
                style: WhisperCueLandingApp.deaconStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),

          if (!isMobile)
            Row(
              children: [
                _navButton('Features', () => _scrollToSection(_featuresKey)),
                _navButton('Download', () => _scrollToSection(_downloadKey)),
              ],
            ),

          ElevatedButton.icon(
            onPressed: _primaryDownloadAction,
            icon: Icon(_primaryDownloadIcon, size: 18, color: const Color(0xFF0A1A08)),
            label: Text(
              _primaryDownloadLabel,
              style: WhisperCueLandingApp.graphikStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: const Color(0xFF0A1A08),
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF55DD4A),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _navButton(String label, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: TextButton(
        onPressed: onTap,
        child: Text(
          label,
          style: WhisperCueLandingApp.graphikStyle(
            color: const Color(0xFF94A3B8),
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // HERO SECTION
  // ---------------------------------------------------------------------------
  Widget _buildHeroSection(bool isMobile) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 900),
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          const SizedBox(height: 20),

          Text(
            'Never Miss a Cue.\nCompletely Invisible.',
            textAlign: TextAlign.center,
            style: WhisperCueLandingApp.deaconStyle(
              fontSize: isMobile ? 38 : 58,
              fontWeight: FontWeight.bold,
              height: 1.1,
              letterSpacing: -1.5,
            ),
          ),
          const SizedBox(height: 24),

          Text(
            'WhisperCue captures live meeting audio, transcribes it in real-time, and delivers instant AI answers in a stealth floating overlay hidden from Zoom, Meet, and Teams.',
            textAlign: TextAlign.center,
            style: WhisperCueLandingApp.graphikStyle(
              fontSize: 18,
              height: 1.6,
              color: const Color(0xFF94A3B8),
            ),
          ),
          const SizedBox(height: 36),

          _buildHeroDownloadButtons(),
        ],
      ),
    );
  }

  Widget _buildHeroDownloadButtons() {
    final os = _detectedOS;

    Widget macButton({bool isPrimary = false}) {
      if (isPrimary) {
        return ElevatedButton.icon(
          onPressed: () => _launchDownloadUrl('dist/macos/WhisperCue-macOS.dmg'),
          icon: const Icon(Icons.apple_rounded, color: Color(0xFF0A1A08)),
          label: Text(
            'Download macOS',
            style: WhisperCueLandingApp.graphikStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
              color: const Color(0xFF0A1A08),
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF55DD4A),
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 18),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        );
      }
      return OutlinedButton.icon(
        onPressed: () => _launchDownloadUrl('dist/macos/WhisperCue-macOS.dmg'),
        icon: const Icon(Icons.apple_rounded, size: 18, color: Color(0xFFF3EDE4)),
        label: Text(
          'Download macOS',
          style: WhisperCueLandingApp.graphikStyle(
            color: const Color(0xFFF3EDE4),
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Color(0x33FFFFFF)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      );
    }

    Widget windowsButton({bool isPrimary = false}) {
      final action = () => _showBuildGuideDialog(
            'Windows',
            'flutter pub get\nflutter build windows --release',
          );
      if (isPrimary) {
        return ElevatedButton.icon(
          onPressed: action,
          icon: const Icon(Icons.window_rounded, color: Color(0xFF0A1A08)),
          label: Text(
            'Download Windows',
            style: WhisperCueLandingApp.graphikStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
              color: const Color(0xFF0A1A08),
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF55DD4A),
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 18),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        );
      }
      return OutlinedButton.icon(
        onPressed: action,
        icon: const Icon(Icons.window_rounded, size: 18, color: Color(0xFF73D3EB)),
        label: Text(
          'Download Windows',
          style: WhisperCueLandingApp.graphikStyle(
            color: const Color(0xFFF3EDE4),
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Color(0x33FFFFFF)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      );
    }

    Widget linuxButton({bool isPrimary = false}) {
      final action = () => _showBuildGuideDialog(
            'Linux',
            'sudo apt install clang cmake ninja-build pkg-config libgtk-3-dev\nflutter pub get\nflutter build linux --release',
          );
      if (isPrimary) {
        return ElevatedButton.icon(
          onPressed: action,
          icon: const Icon(Icons.terminal_rounded, color: Color(0xFF0A1A08)),
          label: Text(
            'Download Linux',
            style: WhisperCueLandingApp.graphikStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
              color: const Color(0xFF0A1A08),
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF55DD4A),
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 18),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        );
      }
      return OutlinedButton.icon(
        onPressed: action,
        icon: const Icon(Icons.terminal_rounded, size: 18, color: Color(0xFF55DD4A)),
        label: Text(
          'Download Linux',
          style: WhisperCueLandingApp.graphikStyle(
            color: const Color(0xFFF3EDE4),
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Color(0x33FFFFFF)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      );
    }

    List<Widget> buttons = [];
    if (os == UserOS.windows) {
      buttons = [windowsButton(isPrimary: true), macButton(), linuxButton()];
    } else if (os == UserOS.linux) {
      buttons = [linuxButton(isPrimary: true), macButton(), windowsButton()];
    } else {
      buttons = [macButton(isPrimary: true), windowsButton(), linuxButton()];
    }

    return Wrap(
      spacing: 16,
      runSpacing: 16,
      alignment: WrapAlignment.center,
      children: buttons,
    );
  }  // ---------------------------------------------------------------------------
  // SHOWCASE FRAME (Clean Media Container for examplevidio.mp4)
  // ---------------------------------------------------------------------------
  Widget _buildShowcaseFrame(bool isMobile) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 1040),
      margin: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: const Color(0xFF0A0F18),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0x2255DD4A)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 20,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          // Sleek Mac Window Header
          Container(
            height: 42,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: const BoxDecoration(
              color: Color(0xFF06090E),
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              border: Border(bottom: BorderSide(color: Color(0x15FFFFFF))),
            ),
            child: Row(
              children: [
                const CircleAvatar(radius: 5, backgroundColor: Color(0xFFFF5F56)),
                const SizedBox(width: 6),
                const CircleAvatar(radius: 5, backgroundColor: Color(0xFFFFBD2E)),
                const SizedBox(width: 6),
                const CircleAvatar(radius: 5, backgroundColor: Color(0xFF27C93F)),
                const Spacer(),
                Text(
                  'WhisperCue — Live Product Demo',
                  style: WhisperCueLandingApp.graphikStyle(
                    color: const Color(0xFF64748B),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Spacer(),
              ],
            ),
          ),

          // Video Container
          Container(
            padding: const EdgeInsets.all(16),
            height: isMobile ? 320 : 540,
            child: Container(
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: const Color(0xFF04060A),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0x15FFFFFF)),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  if (_videoController.value.isInitialized)
                    IgnorePointer(
                      child: RepaintBoundary(
                        child: SizedBox.expand(
                          child: FittedBox(
                            fit: BoxFit.cover,
                            child: SizedBox(
                              width: _videoController.value.size.width,
                              height: _videoController.value.size.height,
                              child: VideoPlayer(_videoController),
                            ),
                          ),
                        ),
                      ),
                    )
                  else
                    const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF55DD4A),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // FEATURES SECTION (Clean Asymmetric Product Cards)
  // ---------------------------------------------------------------------------
  Widget _buildFeaturesSection(bool isMobile) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 1040),
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Built for Total Privacy & Low Latency',
            style: WhisperCueLandingApp.deaconStyle(
              fontSize: isMobile ? 28 : 38,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'High-performance desktop architecture that runs locally alongside your meetings.',
            style: WhisperCueLandingApp.graphikStyle(
              fontSize: 16,
              color: const Color(0xFF94A3B8),
            ),
          ),
          const SizedBox(height: 40),

          // Feature Grid
          Flex(
            direction: isMobile ? Axis.vertical : Axis.horizontal,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: isMobile ? 0 : 1,
                child: Container(
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0B1017),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0x1FFFFFFF)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '100% Anti-Screen Capture',
                        style: WhisperCueLandingApp.deaconStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF55DD4A),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Utilizes macOS NSWindow.sharingType = .none and Win32 SetWindowDisplayAffinity to ensure the overlay is completely excluded from Zoom, Meet, and Teams screen sharing.',
                        style: WhisperCueLandingApp.graphikStyle(
                          fontSize: 14,
                          color: const Color(0xFF94A3B8),
                          height: 1.6,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 20, height: 20),
              Expanded(
                flex: isMobile ? 0 : 1,
                child: Container(
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0B1017),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0x1FFFFFFF)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Whisper AI Live Transcription',
                        style: WhisperCueLandingApp.deaconStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFFF3EDE4),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Streams live system audio and microphone input directly into real-time transcription, processing context-aware answers without lagging your system.',
                        style: WhisperCueLandingApp.graphikStyle(
                          fontSize: 14,
                          color: const Color(0xFF94A3B8),
                          height: 1.6,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Feature Row 2 (Click-Through & Custom Context)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: const Color(0xFF0B1017),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0x1FFFFFFF)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Click-Through Mode & Document Context',
                  style: WhisperCueLandingApp.deaconStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFFF3EDE4),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Lock the overlay into click-through mode so your mouse passes straight to your IDE or browser behind it. Load custom resume points or interview notes so the AI tailors responses specifically to your background.',
                  style: WhisperCueLandingApp.graphikStyle(
                    fontSize: 14,
                    color: const Color(0xFF94A3B8),
                    height: 1.6,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // DOWNLOAD SECTION
  // ---------------------------------------------------------------------------
  Widget _buildDownloadSection(bool isMobile) {
    final os = _detectedOS;
    return Container(
      constraints: const BoxConstraints(maxWidth: 1280),
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          Text(
            'Download WhisperCue',
            style: WhisperCueLandingApp.deaconStyle(
              fontSize: 40,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Choose your platform to download the latest pre-built release binary.',
            style: WhisperCueLandingApp.graphikStyle(
              fontSize: 16,
              color: const Color(0xFF94A3B8),
            ),
          ),
          const SizedBox(height: 48),

          Flex(
            direction: isMobile ? Axis.vertical : Axis.horizontal,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildDownloadCard(
                '🍏',
                'macOS',
                'macOS 11+ (Intel & Apple Silicon)',
                'Download macOS',
                () => _launchDownloadUrl('dist/macos/WhisperCue-macOS.dmg'),
                isPrimary: os == UserOS.macOS,
              ),
              const SizedBox(width: 24, height: 24),
              _buildDownloadCard(
                '🪟',
                'Windows',
                'Windows 10 & 11 (64-bit)',
                'Windows Build Guide',
                () => _showBuildGuideDialog(
                  'Windows',
                  'flutter pub get\nflutter build windows --release',
                ),
                isPrimary: os == UserOS.windows,
              ),
              const SizedBox(width: 24, height: 24),
              _buildDownloadCard(
                '🐧',
                'Linux',
                'Ubuntu / Debian / Arch',
                'Linux Build Guide',
                () => _showBuildGuideDialog(
                  'Linux',
                  'sudo apt install clang cmake ninja-build pkg-config libgtk-3-dev\nflutter pub get\nflutter build linux --release',
                ),
                isPrimary: os == UserOS.linux,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDownloadCard(
    String icon,
    String title,
    String subtitle,
    String btnText,
    VoidCallback onTap, {
    bool isPrimary = false,
  }) {
    return Container(
      width: 280,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: const Color(0xFF101722),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isPrimary ? const Color(0xFF55DD4A) : const Color(0x1FFFFFFF),
          width: isPrimary ? 1.5 : 1.0,
        ),
      ),
      child: Column(
        children: [
          Text(icon, style: const TextStyle(fontSize: 48)),
          const SizedBox(height: 16),
          Text(
            title,
            style: WhisperCueLandingApp.deaconStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: WhisperCueLandingApp.graphikStyle(
              fontSize: 13,
              color: const Color(0xFF94A3B8),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: onTap,
            style: ElevatedButton.styleFrom(
              backgroundColor: isPrimary ? const Color(0xFF55DD4A) : const Color(0xFF202D3F),
              minimumSize: const Size(double.infinity, 48),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              btnText,
              style: WhisperCueLandingApp.graphikStyle(
                fontWeight: FontWeight.bold,
                color: isPrimary ? const Color(0xFF0A1A08) : const Color(0xFFF3EDE4),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // FOOTER
  // ---------------------------------------------------------------------------
  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Color(0x1FFFFFFF))),
      ),
      child: Center(
        child: Text(
          '© 2026 WhisperCue. All rights reserved. Open-source high-performance desktop assistant.',
          style: WhisperCueLandingApp.graphikStyle(
            color: const Color(0xFF94A3B8),
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}
