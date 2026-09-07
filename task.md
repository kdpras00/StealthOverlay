# Task Progress — Stealth Overlay Bridge

## Completed
- [x] Fix Voice Recognition word-by-word real-time rendering & default language:
  - Change default `cfgSpeechLang` from `en-US` to `id-ID` (Bahasa Indonesia) so spoken Indonesian words are recognized immediately instead of filtered out by Chrome's US English Speech model.
  - Make `id-ID` the default selected language option in `options.html`.
  - Stream interim speech transcripts directly into real-time chips on every spoken word (`renderChips(words.slice(-8))`).

## Verification
- Verified console log shows `lang: id-ID` on start and word chips stream instantly as speech is uttered.
