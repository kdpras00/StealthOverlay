# WhisperCue Landing Page

Marketing/download site for WhisperCue, built with Flutter web.

## Run Locally

```bash
flutter pub get
flutter run -d chrome
```

## Build

```bash
flutter build web --no-web-resources-cdn
```

Output goes to `build/web/`.

## Conventions

- **Fonts**: Deacon for large headings (`deaconStyle`), Graphik for body/small text (`graphikStyle`). Fonts load only via `pubspec.yaml` — do not add `@font-face` rules to `web/index.html` (duplicate loading causes fallback warnings).
- **Download buttons**: navbar, hero, and cards auto-highlight the visitor's OS (`UserOS`) with the green primary style. All buttons link to the latest GitHub Release assets.
- **Favicon/PWA icons** (`web/favicon.png`, `web/icons/`): generated from `assets/icons/logo.webp`. Bump the `?v=N` query in `index.html` after regenerating so browsers drop the cached icon.
- **Tests**: `flutter test` (font mapping), `flutter analyze`.
