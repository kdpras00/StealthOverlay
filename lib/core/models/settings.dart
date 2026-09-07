class AppSettings {
  bool stealthEnabled;
  bool alwaysOnTop;
  bool clickThrough;
  bool showGrid;
  double opacity;
  int serverPort;

  AppSettings({
    this.stealthEnabled = true,
    this.alwaysOnTop = true,
    this.clickThrough = false,
    this.showGrid = false,
    this.opacity = 0.85,
    this.serverPort = 8765,
  });

  Map<String, dynamic> toJson() {
    return {
      'stealthEnabled': stealthEnabled,
      'alwaysOnTop': alwaysOnTop,
      'clickThrough': clickThrough,
      'showGrid': showGrid,
      'opacity': opacity,
      'serverPort': serverPort,
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
    );
  }
}
