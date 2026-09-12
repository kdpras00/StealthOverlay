import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
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
      fontSize: fontSize,
      fontWeight: fontWeight ?? FontWeight.bold,
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
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF06090E),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF00CC8E),
          onPrimary: Color(0xFF0A1A08),
          secondary: Color(0xFF73D3EB),
          surface: Color(0xFF101722),
          onSurface: Color(0xFFF3EDE4),
        ),
        textTheme: TextTheme(
          displayLarge: deaconStyle(
            fontSize: 56.0,
            fontWeight: FontWeight.bold,
            letterSpacing: -1.2,
          ),
          headlineMedium: deaconStyle(
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
          labelLarge: graphikStyle(
            fontSize: 15.0,
            fontWeight: FontWeight.bold,
          ),
          labelSmall: graphikStyle(
            fontSize: 12.0,
            fontWeight: FontWeight.bold,
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

  String get _primaryDownloadIconAsset {
    switch (_detectedOS) {
      case UserOS.windows:
        return 'assets/icons/windows.webp';
      case UserOS.linux:
        return 'assets/icons/linux-platform.webp';
      case UserOS.macOS:
        return 'assets/icons/mac-os-logo.webp';
    }
  }

  VoidCallback get _primaryDownloadAction {
    switch (_detectedOS) {
      case UserOS.windows:
        return () => _launchDownloadUrl('https://github.com/kdpras00/WhisperCue/releases/latest/download/WhisperCue-Windows.zip');
      case UserOS.linux:
        return () => _launchDownloadUrl('https://github.com/kdpras00/WhisperCue/releases/latest/download/WhisperCue-Linux.tar.gz');
      case UserOS.macOS:
        return () => _launchDownloadUrl('https://github.com/kdpras00/WhisperCue/releases/latest/download/WhisperCue-macOS.zip');
    }
  }

  Future<void> _launchDownloadUrl(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      debugPrint('Could not launch $url');
    }
  }

  /// Platform icon with correct contrast:
  /// - [onGreen] = true → black icon on green primary button (visible).
  /// - [onGreen] = false → white-tinted icon on dark card/secondary button.
  /// Aset webp bawaan berwarna hitam sehingga harus di-tint putih di atas
  /// background gelap agar terlihat.
  Widget _platformIcon(String asset, double size, {required bool onGreen}) {
    if (onGreen) {
      return Image.asset(asset, width: size, height: size, fit: BoxFit.contain);
    }
    return Image.asset(
      asset,
      width: size,
      height: size,
      fit: BoxFit.contain,
      color: const Color(0xFFF3EDE4),
      colorBlendMode: BlendMode.srcIn,
    );
  }

  void _showBuildGuideDialog(String platformName, String commands) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF101722),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Color(0xFF00CC8E)),
        ),
        title: Text(
          '$platformName Setup & Build Guide',
          style: WhisperCueLandingApp.deaconStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
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
                    color: Color(0xFF00CC8E),
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
                color: const Color(0xFF00CC8E),
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
                // Hero Section (starts directly under the sticky navbar)
                RepaintBoundary(
                  child: _buildHeroSection(isMobile),
                ),

                // Interactive App Showcase Demo Frame — own distinct section band
                Container(
                  width: double.infinity,
                  constraints: BoxConstraints(
                    minHeight: MediaQuery.of(context).size.height,
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 80),
                  decoration: const BoxDecoration(
                    color: Color(0xFF090D13),
                    border: Border(
                      top: BorderSide(color: Color(0x1FFFFFFF)),
                      bottom: BorderSide(color: Color(0x1FFFFFFF)),
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      RepaintBoundary(
                        child: _buildShowcaseFrame(isMobile),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 80),

                // Features Section (Independent section with background.svg & smooth gradient fade)
                RepaintBoundary(
                  child: Container(
                    key: _featuresKey,
                    width: double.infinity,
                    child: Stack(
                      children: [
                        // Background SVG with subtle opacity
                        Positioned.fill(
                          child: Opacity(
                            opacity: 0.15,
                            child: SvgPicture.asset(
                              'assets/images/background.svg',
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        // Soft top & bottom gradient fade to seamlessly merge with #06090E scaffold
                        Positioned.fill(
                          child: Container(
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Color(0xFF06090E),
                                  Color(0x0006090E),
                                  Color(0x0006090E),
                                  Color(0xFF06090E),
                                ],
                                stops: [0.0, 0.2, 0.8, 1.0],
                              ),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 90),
                          child: Center(
                            child: _buildFeaturesSection(isMobile),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 100),

                // Download Section (Independent Section)
                RepaintBoundary(
                  child: Container(
                    key: _downloadKey,
                    child: _buildDownloadSection(isMobile),
                  ),
                ),

                const SizedBox(height: 100),

                // Footer (Sleek Minimalist Footer)
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
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 32),
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
                width: isMobile ? 32 : 36,
                height: isMobile ? 32 : 36,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  image: const DecorationImage(
                    image: AssetImage('assets/icons/logo.webp'),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              SizedBox(width: isMobile ? 8 : 12),
              Text(
                'WhisperCue',
                style: WhisperCueLandingApp.deaconStyle(
                  fontSize: isMobile ? 18 : 20,
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

          if (!isMobile)
            ElevatedButton.icon(
              onPressed: _primaryDownloadAction,
              icon: Image.asset(_primaryDownloadIconAsset, width: 18, height: 18),
              label: Text(
                _primaryDownloadLabel,
                style: WhisperCueLandingApp.graphikStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: const Color(0xFF0A1A08),
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00CC8E),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                shape: const StadiumBorder(),
                elevation: 0,
              ),
            )
          else
            Row(
              children: [
                ElevatedButton(
                  onPressed: _primaryDownloadAction,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00CC8E),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    minimumSize: const Size(0, 38),
                    shape: const StadiumBorder(),
                    elevation: 0,
                  ),
                  child: Text(
                    'Get App',
                    style: WhisperCueLandingApp.graphikStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: const Color(0xFF0A1A08),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.menu_rounded, color: Colors.white, size: 26),
                  onPressed: () => _openMobileMenu(context),
                  tooltip: 'Menu',
                ),
              ],
            ),
        ],
      ),
    );
  }

  void _openMobileMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0A0F18),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            image: const DecorationImage(
                              image: AssetImage('assets/icons/logo.webp'),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'WhisperCue',
                          style: WhisperCueLandingApp.deaconStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: Colors.white70),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const Divider(color: Color(0x1FFFFFFF), height: 24),
                ListTile(
                  leading: const Icon(Icons.star_outline_rounded, color: Color(0xFF00CC8E)),
                  title: Text(
                    'Features',
                    style: WhisperCueLandingApp.graphikStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    _scrollToSection(_featuresKey);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.download_rounded, color: Color(0xFF00CC8E)),
                  title: Text(
                    'Download Options',
                    style: WhisperCueLandingApp.graphikStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    _scrollToSection(_downloadKey);
                  },
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
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
    final double viewportHeight = MediaQuery.of(context).size.height;
    return Container(
      width: double.infinity,
      constraints: BoxConstraints(minHeight: isMobile ? 0 : viewportHeight),
      child: Stack(
        children: [
          // Layered teal-wave backdrop with a uniform dark scrim,
          // so the motif reads evenly across the whole section.
          Positioned.fill(
            child: SvgPicture.asset(
              'assets/images/background.svg',
              fit: BoxFit.cover,
            ),
          ),
          Positioned.fill(
            child: Container(
              color: const Color(0x9906090E),
            ),
          ),
          Center(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 900),
              padding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 24),
              child: Column(
                children: [
                  SizedBox(height: isMobile ? 160 : 250),

                  Text(
                    'Never Miss a Cue.\nCompletely Invisible.',
                    textAlign: TextAlign.center,
                    style: WhisperCueLandingApp.deaconStyle(
                      fontSize: isMobile ? 32 : 58,
                      fontWeight: FontWeight.bold,
                      height: 1.1,
                      letterSpacing: isMobile ? -0.8 : -1.5,
                    ),
                  ),
                  const SizedBox(height: 24),

                  Text(
                    'WhisperCue captures live meeting audio, transcribes it in real-time, and delivers instant AI answers in a stealth floating overlay hidden from Zoom, Meet, and Teams.',
                    textAlign: TextAlign.center,
                    style: WhisperCueLandingApp.graphikStyle(
                      fontSize: isMobile ? 15 : 18,
                      height: 1.6,
                      color: const Color(0xFF94A3B8),
                    ),
                  ),
                  const SizedBox(height: 36),

                  _buildHeroDownloadButtons(isMobile),
                  SizedBox(height: isMobile ? 32 : 48),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroDownloadButtons(bool isMobile) {
    final os = _detectedOS;

    final double horizPrimaryPad = isMobile ? 22 : 32;
    final double horizSecondaryPad = isMobile ? 20 : 28;
    final double vertPad = isMobile ? 14 : 22;

    Widget macButton({bool isPrimary = false}) {
      if (isPrimary) {
        return ElevatedButton.icon(
          onPressed: () => _launchDownloadUrl('https://github.com/kdpras00/WhisperCue/releases/latest/download/WhisperCue-macOS.zip'),
          icon: _platformIcon('assets/icons/mac-os-logo.webp', 18, onGreen: true),
          label: Text(
            'Download macOS',
            style: WhisperCueLandingApp.graphikStyle(
              fontWeight: FontWeight.bold,
              fontSize: isMobile ? 14 : 15,
              color: const Color(0xFF0A1A08),
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF00CC8E),
            padding: EdgeInsets.symmetric(horizontal: horizPrimaryPad, vertical: vertPad),
            shape: const StadiumBorder(),
            elevation: 0,
          ),
        );
      }
      return OutlinedButton.icon(
        onPressed: () => _launchDownloadUrl('https://github.com/kdpras00/WhisperCue/releases/latest/download/WhisperCue-macOS.zip'),
        icon: _platformIcon('assets/icons/mac-os-logo.webp', 18, onGreen: false),
        label: Text(
          'Download macOS',
          style: WhisperCueLandingApp.graphikStyle(
            color: const Color(0xFFF3EDE4),
            fontSize: isMobile ? 14 : 15,
            fontWeight: FontWeight.w600,
          ),
        ),
        style: OutlinedButton.styleFrom(
          backgroundColor: const Color(0xFF101722),
          side: const BorderSide(color: Color(0x33FFFFFF)),
          padding: EdgeInsets.symmetric(horizontal: horizSecondaryPad, vertical: vertPad),
          shape: const StadiumBorder(),
          elevation: 0,
        ),
      );
    }

    Widget windowsButton({bool isPrimary = false}) {
      final action = () => _launchDownloadUrl('https://github.com/kdpras00/WhisperCue/releases/latest/download/WhisperCue-Windows.zip');
      if (isPrimary) {
        return ElevatedButton.icon(
          onPressed: action,
          icon: _platformIcon('assets/icons/windows.webp', 18, onGreen: true),
          label: Text(
            'Download Windows',
            style: WhisperCueLandingApp.graphikStyle(
              fontWeight: FontWeight.bold,
              fontSize: isMobile ? 14 : 15,
              color: const Color(0xFF0A1A08),
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF00CC8E),
            padding: EdgeInsets.symmetric(horizontal: horizPrimaryPad, vertical: vertPad),
            shape: const StadiumBorder(),
            elevation: 0,
          ),
        );
      }
      return OutlinedButton.icon(
        onPressed: action,
        icon: _platformIcon('assets/icons/windows.webp', 18, onGreen: false),
        label: Text(
          'Download Windows',
          style: WhisperCueLandingApp.graphikStyle(
            color: const Color(0xFFF3EDE4),
            fontSize: isMobile ? 14 : 15,
            fontWeight: FontWeight.w600,
          ),
        ),
        style: OutlinedButton.styleFrom(
          backgroundColor: const Color(0xFF101722),
          side: const BorderSide(color: Color(0x33FFFFFF)),
          padding: EdgeInsets.symmetric(horizontal: horizSecondaryPad, vertical: vertPad),
          shape: const StadiumBorder(),
          elevation: 0,
        ),
      );
    }

    Widget linuxButton({bool isPrimary = false}) {
      final action = () => _launchDownloadUrl('https://github.com/kdpras00/WhisperCue/releases/latest/download/WhisperCue-Linux.tar.gz');
      if (isPrimary) {
        return ElevatedButton.icon(
          onPressed: action,
          icon: _platformIcon('assets/icons/linux-platform.webp', 18, onGreen: true),
          label: Text(
            'Download Linux',
            style: WhisperCueLandingApp.graphikStyle(
              fontWeight: FontWeight.bold,
              fontSize: isMobile ? 14 : 15,
              color: const Color(0xFF0A1A08),
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF00CC8E),
            padding: EdgeInsets.symmetric(horizontal: horizPrimaryPad, vertical: vertPad),
            shape: const StadiumBorder(),
            elevation: 0,
          ),
        );
      }
      return OutlinedButton.icon(
        onPressed: action,
        icon: _platformIcon('assets/icons/linux-platform.webp', 18, onGreen: false),
        label: Text(
          'Download Linux',
          style: WhisperCueLandingApp.graphikStyle(
            color: const Color(0xFFF3EDE4),
            fontSize: isMobile ? 14 : 15,
            fontWeight: FontWeight.w600,
          ),
        ),
        style: OutlinedButton.styleFrom(
          backgroundColor: const Color(0xFF101722),
          side: const BorderSide(color: Color(0x33FFFFFF)),
          padding: EdgeInsets.symmetric(horizontal: horizSecondaryPad, vertical: vertPad),
          shape: const StadiumBorder(),
          elevation: 0,
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
      spacing: isMobile ? 10 : 16,
      runSpacing: isMobile ? 10 : 16,
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
        border: Border.all(color: const Color(0x2200CC8E)),
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
                        color: Color(0xFF00CC8E),
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
                          color: const Color(0xFFF3EDE4),
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
      constraints: const BoxConstraints(maxWidth: 1040),
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
                'assets/icons/mac-os-logo.webp',
                'macOS',
                'macOS 11+ (Intel & Apple Silicon)',
                'Download macOS',
                () => _launchDownloadUrl('https://github.com/kdpras00/WhisperCue/releases/latest/download/WhisperCue-macOS.zip'),
                isPrimary: os == UserOS.macOS,
              ),
              const SizedBox(width: 24, height: 24),
              _buildDownloadCard(
                'assets/icons/windows.webp',
                'Windows',
                'Windows 10 & 11 (64-bit)',
                'Download Windows',
                () => _launchDownloadUrl('https://github.com/kdpras00/WhisperCue/releases/latest/download/WhisperCue-Windows.zip'),
                isPrimary: os == UserOS.windows,
              ),
              const SizedBox(width: 24, height: 24),
              _buildDownloadCard(
                'assets/icons/linux-platform.webp',
                'Linux',
                'Ubuntu / Debian / Arch',
                'Download Linux',
                () => _launchDownloadUrl('https://github.com/kdpras00/WhisperCue/releases/latest/download/WhisperCue-Linux.tar.gz'),
                isPrimary: os == UserOS.linux,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDownloadCard(
    String iconAsset,
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
          color: const Color(0x1FFFFFFF),
          width: 1.0,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x59000000),
            blurRadius: 16,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          _platformIcon(iconAsset, 48, onGreen: false),
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
              backgroundColor: isPrimary ? const Color(0xFF00CC8E) : const Color(0xFF1A2536),
              minimumSize: const Size(double.infinity, 54),
              padding: const EdgeInsets.symmetric(vertical: 18),
              elevation: 0,
              side: isPrimary ? BorderSide.none : const BorderSide(color: Color(0x33FFFFFF)),
              shape: const StadiumBorder(),
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
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
      decoration: const BoxDecoration(
        color: Color(0xFF04060A),
        border: Border(
          top: BorderSide(color: Color(0x1FFFFFFF), width: 1),
        ),
      ),
      child: Center(
        child: Text(
          '© WhisperCue. All rights reserved. Open-source high-performance desktop assistant.',
          textAlign: TextAlign.center,
          style: WhisperCueLandingApp.graphikStyle(
            color: const Color(0xFF64748B),
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}
