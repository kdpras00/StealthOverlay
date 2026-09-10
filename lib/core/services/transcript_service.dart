import 'dart:async';
import 'package:flutter/foundation.dart';
import 'llm_service.dart';
import '../models/settings.dart';

/// Transcript entry from any audio source.
class TranscriptEntry {
  final String text;
  final AudioSource source;
  final DateTime timestamp;
  final String lang;

  TranscriptEntry({
    required this.text,
    required this.source,
    DateTime? timestamp,
    this.lang = 'id-ID',
  }) : timestamp = timestamp ?? DateTime.now();
}

/// Central service that aggregates transcripts from multiple sources,
/// maintains conversation history, and dispatches to LLM for answers.
class TranscriptService extends ChangeNotifier {
  final LlmService _llm;

  // Live state
  final List<TranscriptEntry> _transcripts = [];
  final List<String> _wordChips = [];
  String _currentTranscript = '';
  String _aiAnswer = '';
  bool _isAiGenerating = false;
  bool _isListening = false;
  AudioSource _activeSource = AudioSource.mic;

  // Auto-clear state for interview turns
  DateTime? _lastSpeechTime;
  bool _shouldClearOnNextTurn = false;

  // Debounce timer for auto-AI trigger (Waits for speaker to finish completely)
  // Must be longer than chunk duration (5s) so AI only fires after true silence
  Timer? _aiDebounceTimer;
  final Duration _aiDebounceDelay = const Duration(milliseconds: 6000);

  // Max word chips to display
  int maxChips = 60;

  TranscriptService({required LlmService llm}) : _llm = llm;

  // ── Getters ──
  List<TranscriptEntry> get transcripts => List.unmodifiable(_transcripts);
  List<String> get wordChips => List.unmodifiable(_wordChips);
  String get currentTranscript => _currentTranscript;
  String get aiAnswer => _aiAnswer;
  bool get isAiGenerating => _isAiGenerating;
  bool get isListening => _isListening;
  AudioSource get activeSource => _activeSource;
  bool get hasPendingAiTimer => _aiDebounceTimer != null && _aiDebounceTimer!.isActive;

  // ── Incoming transcript handling ──

  /// Add a new transcript from any source.
  /// If [autoTriggerAI] is true, will debounce and auto-send to LLM.
  void addTranscript(String text, AudioSource source, {
    String lang = 'id-ID',
    bool autoTriggerAI = true,
  }) {
    final cleaned = text.trim();
    if (cleaned.isEmpty) return;

    // If interviewer starts speaking again while AI is generating, cancel generation to listen
    if (_isAiGenerating) {
      stopAIGeneration();
    }

    final now = DateTime.now();
    final isPauseExceeded = _lastSpeechTime != null && now.difference(_lastSpeechTime!).inSeconds >= 5;

    // Auto-clear previous question & AI answer when a new interview question turn starts
    if (_shouldClearOnNextTurn || isPauseExceeded) {
      _currentTranscript = '';
      _wordChips.clear();
      _aiAnswer = '';
      _shouldClearOnNextTurn = false;
    }
    _lastSpeechTime = now;

    final entry = TranscriptEntry(text: cleaned, source: source, lang: lang);
    _transcripts.add(entry);
    _activeSource = source;

    // Accumulate speech chunks cleanly with smart overlap deduplication!
    _currentTranscript = _mergeTranscripts(_currentTranscript, cleaned);

    // Update word chips
    final words = _currentTranscript.split(RegExp(r'\s+'));
    _wordChips.clear();
    _wordChips.addAll(words.length > maxChips ? words.sublist(words.length - maxChips) : words);

    notifyListeners();

    if (autoTriggerAI && _currentTranscript.length > 3) {
      _scheduleAIAnswer(_currentTranscript);
    }
  }

  /// Add interim (partial) transcript for live display without triggering AI.
  void addInterimTranscript(String text, AudioSource source) {
    if (text.trim().isEmpty) return;

    final now = DateTime.now();
    final isPauseExceeded = _lastSpeechTime != null && now.difference(_lastSpeechTime!).inSeconds >= 5;

    if (_shouldClearOnNextTurn || isPauseExceeded) {
      _currentTranscript = '';
      _wordChips.clear();
      _aiAnswer = '';
      _shouldClearOnNextTurn = false;
    }
    _lastSpeechTime = now;

    _currentTranscript = text.trim();
    _activeSource = source;

    final words = text.trim().split(RegExp(r'\s+'));
    _wordChips.clear();
    _wordChips.addAll(words.length > maxChips ? words.sublist(words.length - maxChips) : words);

    notifyListeners();
  }

  /// Manually send a question to the LLM.
  Future<void> askQuestion(String question) async {
    _cancelPendingAI();
    await _generateAIAnswer(question);
  }

  StreamSubscription<String>? _streamSub;

  /// Stop ongoing AI generation immediately.
  void stopAIGeneration() {
    _cancelPendingAI();
    _streamSub?.cancel();
    _streamSub = null;
    _isAiGenerating = false;
    _shouldClearOnNextTurn = true;
    notifyListeners();
  }

  /// Regenerate AI answer for the current active question.
  Future<void> regenerateAIAnswer() async {
    if (_currentTranscript.isNotEmpty) {
      await askQuestion(_currentTranscript);
    }
  }

  // ── AI Generation ──

  void _scheduleAIAnswer(String text) {
    _cancelPendingAI();
    _aiDebounceTimer = Timer(_aiDebounceDelay, () {
      _aiDebounceTimer = null;
      _generateAIAnswer(text);
    });
    notifyListeners();
  }

  void _cancelPendingAI() {
    if (_aiDebounceTimer != null) {
      _aiDebounceTimer?.cancel();
      _aiDebounceTimer = null;
      notifyListeners();
    }
  }

  Future<void> _generateAIAnswer(String question) async {
    if (!_llm.hasValidKey) {
      _aiAnswer = '⚠️ Set API key in settings to enable AI answers.';
      notifyListeners();
      return;
    }

    _isAiGenerating = true;
    _aiAnswer = '';
    notifyListeners();

    final buffer = StringBuffer();
    _streamSub?.cancel();
    _streamSub = _llm.streamAnswer(question).listen(
      (chunk) {
        buffer.write(chunk);
        _aiAnswer = buffer.toString();
        notifyListeners();
      },
      onDone: () {
        _isAiGenerating = false;
        _shouldClearOnNextTurn = true;
        _streamSub = null;
        notifyListeners();
      },
      onError: (e) {
        _aiAnswer = '[Error: $e]';
        _isAiGenerating = false;
        _shouldClearOnNextTurn = true;
        _streamSub = null;
        notifyListeners();
      },
    );
  }

  // ── Listening state ──

  void setListening(bool listening) {
    _isListening = listening;
    notifyListeners();
  }

  // ── Clear ──

  void clearTranscripts() {
    _transcripts.clear();
    _wordChips.clear();
    _currentTranscript = '';
    _aiAnswer = '';
    notifyListeners();
  }

  void clearAIAnswer() {
    _aiAnswer = '';
    notifyListeners();
  }

  /// Intelligently merge audio transcript chunks, removing overlapping words/suffixes
  String _mergeTranscripts(String existing, String newChunk) {
    final cleanExisting = existing.trim();
    final cleanNew = newChunk.trim();
    if (cleanExisting.isEmpty) return cleanNew;
    if (cleanNew.isEmpty) return cleanExisting;
    if (cleanExisting.endsWith(cleanNew)) return cleanExisting;
    if (cleanExisting.contains(cleanNew)) return cleanExisting;
    if (cleanNew.contains(cleanExisting)) return cleanNew;

    final existingWords = cleanExisting.split(RegExp(r'\s+'));
    final newWords = cleanNew.split(RegExp(r'\s+'));

    int maxOverlap = 0;
    final maxCheck = existingWords.length < newWords.length ? existingWords.length : newWords.length;

    for (int i = 1; i <= maxCheck; i++) {
      final existingSuffix = existingWords.sublist(existingWords.length - i).join(' ').toLowerCase();
      final newPrefix = newWords.sublist(0, i).join(' ').toLowerCase();
      if (existingSuffix == newPrefix) {
        maxOverlap = i;
      }
    }

    if (maxOverlap > 0) {
      final nonOverlappingNewWords = newWords.sublist(maxOverlap).join(' ');
      return nonOverlappingNewWords.isEmpty ? cleanExisting : '$cleanExisting $nonOverlappingNewWords';
    }

    return '$cleanExisting $cleanNew';
  }

  @override
  void dispose() {
    _cancelPendingAI();
    super.dispose();
  }
}
