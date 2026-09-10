/// Audio source enum for tracking where transcripts come from.
enum AudioSource {
  /// Hardware microphone (via WebSpeech or MediaRecorder in Chrome extension)
  mic,

  /// Tab audio capture (via chrome.tabCapture in Chrome extension)
  tab,

  /// System audio loopback (via native platform: ScreenCaptureKit/WASAPI)
  system,
}

/// Overlay interaction mode (mirrors Chrome extension modes).
enum OverlayMode { answer, screenshot, chat }

class AppSettings {
  bool stealthEnabled;
  bool alwaysOnTop;
  bool clickThrough;
  bool showGrid;
  double opacity;
  int serverPort;

  // AI & API Configuration
  String apiKey;
  String apiProvider;
  String apiBaseUrl;
  String aiModel;

  // Voice & Speech
  String speechLang;
  bool autoStartMic;
  String systemPrompt;
  String userProfile;
  bool isMinimized;

  AppSettings({
    this.stealthEnabled = true,
    this.alwaysOnTop = true,
    this.clickThrough = false,
    this.showGrid = false,
    this.opacity = 0.85,
    this.serverPort = 8765,
    this.apiKey = '',
    this.apiProvider = 'groq',
    this.apiBaseUrl = '',
    this.aiModel = '',
    this.speechLang = 'id-ID',
    this.autoStartMic = true,
    this.systemPrompt = 'You are a live technical interview copilot. Format response with "### 📌 [Topic Title]" at top followed by natural spoken response.',
    this.userProfile = '',
    this.isMinimized = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'stealthEnabled': stealthEnabled,
      'alwaysOnTop': alwaysOnTop,
      'clickThrough': clickThrough,
      'showGrid': showGrid,
      'opacity': opacity,
      'serverPort': serverPort,
      'apiKey': apiKey,
      'apiProvider': apiProvider,
      'apiBaseUrl': apiBaseUrl,
      'aiModel': aiModel,
      'speechLang': speechLang,
      'autoStartMic': autoStartMic,
      'systemPrompt': systemPrompt,
      'userProfile': userProfile,
      'isMinimized': isMinimized,
    };
  }

  factory AppSettings.fromJson(Map<String, dynamic> json) {
    return AppSettings(
      stealthEnabled: json['stealthEnabled'] as bool? ?? true,
      alwaysOnTop: json['alwaysOnTop'] as bool? ?? true,
      clickThrough: json['clickThrough'] as bool? ?? false,
      showGrid: json['showGrid'] as bool? ?? false,
      opacity: (json['opacity'] as num?)?.toDouble() ?? 0.85,
      serverPort: json['serverPort'] as int? ?? 8765,
      apiKey: json['apiKey'] as String? ?? '',
      apiProvider: json['apiProvider'] as String? ?? 'groq',
      apiBaseUrl: json['apiBaseUrl'] as String? ?? '',
      aiModel: json['aiModel'] as String? ?? '',
      speechLang: json['speechLang'] as String? ?? 'id-ID',
      autoStartMic: json['autoStartMic'] as bool? ?? true,
      systemPrompt: json['systemPrompt'] as String? ?? 'You are a concise live technical interview copilot. Answer directly with max 3-4 bullet points.',
      userProfile: json['userProfile'] as String? ?? '',
      isMinimized: json['isMinimized'] as bool? ?? false,
    );
  }
}
