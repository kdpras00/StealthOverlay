import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

/// Supported LLM providers.
enum LlmProvider { groq, openai, gemini, anthropic, ollama, custom }

/// A streaming LLM client that supports multiple providers.
/// Returns AI responses word-by-word via a Stream for real-time display.
class LlmService {
  String _apiKey;
  LlmProvider _provider;
  String _baseUrl;
  String _model;
  String _userProfile;

  LlmService({
    String apiKey = '',
    LlmProvider provider = LlmProvider.groq,
    String baseUrl = '',
    String model = '',
    String userProfile = '',
  })  : _apiKey = apiKey,
        _provider = provider,
        _baseUrl = baseUrl,
        _model = model,
        _userProfile = userProfile;

  void updateConfig({
    String? apiKey,
    LlmProvider? provider,
    String? baseUrl,
    String? model,
    String? userProfile,
  }) {
    if (apiKey != null) _apiKey = apiKey;
    if (provider != null) _provider = provider;
    if (baseUrl != null) _baseUrl = baseUrl;
    if (model != null) _model = model;
    if (userProfile != null) _userProfile = userProfile;
  }

  bool get hasValidKey => _apiKey.isNotEmpty && _apiKey.length > 5;

  /// Resolved LLM provider. Uses explicit _provider setting.
  LlmProvider get _resolvedProvider => _provider;

  String get _resolvedBaseUrl {
    if (_baseUrl.isNotEmpty) return _baseUrl;
    switch (_resolvedProvider) {
      case LlmProvider.groq:
        return 'https://api.groq.com/openai/v1';
      case LlmProvider.openai:
        return 'https://api.openai.com/v1';
      case LlmProvider.gemini:
        return 'https://generativelanguage.googleapis.com';
      case LlmProvider.anthropic:
        return 'https://api.anthropic.com/v1';
      case LlmProvider.ollama:
        return 'http://localhost:11434/v1';
      case LlmProvider.custom:
        return 'http://localhost:20128/v1';
    }
  }

  static const Map<String, List<Map<String, String>>> providerModels = {
    'groq': [
      {'id': 'openai/gpt-oss-120b', 'name': 'openai/gpt-oss-120b (120B Flagship)'},
      {'id': 'openai/gpt-oss-20b', 'name': 'openai/gpt-oss-20b (20B Fast)'},
      {'id': 'qwen/qwen3.6-27b', 'name': 'qwen/qwen3.6-27b (Multimodal & Fast)'},
      {'id': 'qwen/qwen3.8-27b', 'name': 'qwen/qwen3.8-27b'},
      {'id': 'groq/compound', 'name': 'groq/compound'},
    ],
    'openai': [
      {'id': 'gpt-4o-mini', 'name': 'gpt-4o-mini (Fast & Efficient)'},
      {'id': 'gpt-4o', 'name': 'gpt-4o (Multimodal Flagship)'},
      {'id': 'o3-mini', 'name': 'o3-mini (Reasoning)'},
      {'id': 'o1', 'name': 'o1 (Reasoning)'},
      {'id': 'gpt-4-turbo', 'name': 'gpt-4-turbo'},
    ],
    'gemini': [
      {'id': 'gemini-3.6-flash', 'name': 'gemini-3.6-flash (Fast & Multimodal)'},
      {'id': 'gemini-3.5-flash', 'name': 'gemini-3.5-flash'},
      {'id': 'gemini-3.1-pro-preview', 'name': 'gemini-3.1-pro-preview (Smartest)'},
    ],
    'anthropic': [
      {'id': 'claude-3-5-sonnet-20241022', 'name': 'claude-3-5-sonnet (Smartest)'},
      {'id': 'claude-3-5-haiku-20241022', 'name': 'claude-3-5-haiku (Fast)'},
      {'id': 'claude-3-opus-20240229', 'name': 'claude-3-opus'},
    ],
    'ollama': [
      {'id': 'llama3.2', 'name': 'llama3.2'},
      {'id': 'llama3.1', 'name': 'llama3.1'},
      {'id': 'qwen2.5-coder', 'name': 'qwen2.5-coder'},
      {'id': 'deepseek-r1', 'name': 'deepseek-r1'},
      {'id': 'mistral', 'name': 'mistral'},
    ],
  };

  /// Resolves model name for API requests. Validates model against target provider.
  String get _resolvedModel {
    final providerStr = _resolvedProvider.name;
    final validModels = providerModels[providerStr]?.map((m) => m['id']!).toList() ?? [];

    if (_model.isNotEmpty && _model != 'auto' && (validModels.contains(_model) || _resolvedProvider == LlmProvider.custom)) {
      return _model;
    }

    switch (_resolvedProvider) {
      case LlmProvider.groq:
        return 'openai/gpt-oss-120b';
      case LlmProvider.openai:
        return 'gpt-4o-mini';
      case LlmProvider.gemini:
        return 'gemini-3.6-flash';
      case LlmProvider.anthropic:
        return 'claude-3-5-sonnet-20241022';
      case LlmProvider.ollama:
        return 'llama3.2';
      case LlmProvider.custom:
        return _model.isNotEmpty ? _model : 'gpt-4o-mini';
    }
  }

  /// Stream a response from the LLM. Yields text chunks as they arrive.
  Stream<String> streamAnswer(String question, {String? systemPrompt}) async* {
    var prompt = systemPrompt ??
        'You are a live technical interview copilot.\n'
            'FORMAT EVERY RESPONSE AS FOLLOWS:\n'
            '1. First line MUST be a short header title starting with "### 📌 [Short Topic Title]" summarizing the question topic.\n'
            '2. Immediately below the title, provide a natural, professional, spoken-ready first-person response ("Saya...") in the same language as the interviewer (Indonesian or English).\n'
            'Make the answer direct, polite, concise, and immediately ready to be read aloud by the candidate.';

    if (_userProfile.trim().isNotEmpty) {
      prompt = '$prompt\n\n[CANDIDATE BACKGROUND & RESUME CONTEXT]:\n'
          'Tailor all answers to match the candidate\'s exact experience, name, education, skills, and projects documented below:\n'
          '${_userProfile.trim()}';
    }

    final provider = _resolvedProvider;

    if (provider == LlmProvider.gemini) {
      yield* _streamGemini(question, prompt);
    } else if (provider == LlmProvider.anthropic) {
      yield* _streamAnthropic(question, prompt);
    } else {
      // OpenAI-compatible: Groq, OpenAI, Ollama, Custom
      yield* _streamOpenAICompatible(question, prompt);
    }
  }

  /// Non-streaming fallback — returns complete answer.
  Future<String> getAnswer(String question, {String? systemPrompt}) async {
    final buffer = StringBuffer();
    await for (final chunk in streamAnswer(question, systemPrompt: systemPrompt)) {
      buffer.write(chunk);
    }
    return buffer.toString();
  }

  // ── Gemini Streaming ──
  Stream<String> _streamGemini(String question, String systemPrompt) async* {
    final model = _resolvedModel;
    final key = _apiKey.trim();
    final url = Uri.parse(
        'https://generativelanguage.googleapis.com/v1beta/models/$model:streamGenerateContent?alt=sse&key=$key');

    try {
      final request = http.Request('POST', url);
      request.headers['Content-Type'] = 'application/json';
      request.body = jsonEncode({
        'contents': [
          {
            'parts': [
              {'text': '$systemPrompt\n\nQuestion: $question'}
            ]
          }
        ],
        'generationConfig': {'temperature': 0.3},
      });

      final client = http.Client();
      try {
        final response = await client.send(request);

        if (response.statusCode != 200) {
          final body = await response.stream.bytesToString();
          yield '[Error: Gemini HTTP ${response.statusCode}: ${body.substring(0, 150.clamp(0, body.length))}]';
          return;
        }

        await for (final chunk in response.stream
            .transform(utf8.decoder)
            .transform(const LineSplitter())) {
          if (chunk.startsWith('data: ')) {
            final jsonStr = chunk.substring(6);
            if (jsonStr.trim() == '[DONE]') break;
            try {
              final data = jsonDecode(jsonStr) as Map<String, dynamic>;
              final candidates = data['candidates'] as List?;
              if (candidates != null && candidates.isNotEmpty) {
                final content = candidates[0]['content'] as Map<String, dynamic>?;
                final parts = content?['parts'] as List?;
                if (parts != null && parts.isNotEmpty) {
                  final text = parts[0]['text'] as String?;
                  if (text != null && text.isNotEmpty) {
                    yield text;
                  }
                }
              }
            } catch (_) {
              // Skip malformed SSE lines
            }
          }
        }
      } finally {
        client.close();
      }
    } catch (e) {
      yield '[Error: Gemini stream failed: $e]';
    }
  }

  // ── Anthropic Claude Streaming ──
  Stream<String> _streamAnthropic(String question, String systemPrompt) async* {
    final model = _resolvedModel;
    final key = _apiKey.trim();
    final url = Uri.parse('${_resolvedBaseUrl.replaceAll(RegExp(r'/+$'), '')}/messages');

    try {
      final request = http.Request('POST', url);
      request.headers.addAll({
        'Content-Type': 'application/json',
        'x-api-key': key,
        'anthropic-version': '2023-06-01',
      });
      request.body = jsonEncode({
        'model': model,
        'max_tokens': 1024,
        'stream': true,
        'system': systemPrompt,
        'messages': [
          {'role': 'user', 'content': question}
        ],
      });

      final client = http.Client();
      try {
        final response = await client.send(request);

        if (response.statusCode != 200) {
          final body = await response.stream.bytesToString();
          yield '[Error: Claude HTTP ${response.statusCode}: ${body.substring(0, 150.clamp(0, body.length))}]';
          return;
        }

        await for (final chunk in response.stream
            .transform(utf8.decoder)
            .transform(const LineSplitter())) {
          if (chunk.startsWith('data: ')) {
            final jsonStr = chunk.substring(6);
            if (jsonStr.trim() == '[DONE]') break;
            try {
              final data = jsonDecode(jsonStr) as Map<String, dynamic>;
              final type = data['type'] as String?;
              if (type == 'content_block_delta') {
                final delta = data['delta'] as Map<String, dynamic>?;
                final text = delta?['text'] as String?;
                if (text != null && text.isNotEmpty) {
                  yield text;
                }
              }
            } catch (_) {}
          }
        }
      } finally {
        client.close();
      }
    } catch (e) {
      yield '[Error: Claude stream failed: $e]';
    }
  }

  // ── OpenAI-Compatible Streaming (Groq, OpenAI, Ollama, Custom) ──
  Stream<String> _streamOpenAICompatible(String question, String systemPrompt) async* {
    final model = _resolvedModel;
    final baseUrl = _resolvedBaseUrl.replaceAll(RegExp(r'/+$'), '');
    final url = Uri.parse('$baseUrl/chat/completions');
    final key = _apiKey.trim();

    try {
      final request = http.Request('POST', url);
      request.headers['Content-Type'] = 'application/json';
      if (key.isNotEmpty) {
        request.headers['Authorization'] = 'Bearer $key';
      }
      request.body = jsonEncode({
        'model': model,
        'stream': true,
        'messages': [
          {'role': 'system', 'content': systemPrompt},
          {'role': 'user', 'content': question},
        ],
        'temperature': 0.3,
      });

      final client = http.Client();
      try {
        final response = await client.send(request);

        if (response.statusCode != 200) {
          final body = await response.stream.bytesToString();
          yield '[Error: HTTP ${response.statusCode}: ${body.substring(0, 150.clamp(0, body.length))}]';
          return;
        }

        await for (final chunk in response.stream
            .transform(utf8.decoder)
            .transform(const LineSplitter())) {
          if (chunk.startsWith('data: ')) {
            final jsonStr = chunk.substring(6);
            if (jsonStr.trim() == '[DONE]') break;
            try {
              final data = jsonDecode(jsonStr) as Map<String, dynamic>;
              final choices = data['choices'] as List?;
              if (choices != null && choices.isNotEmpty) {
                final delta = choices[0]['delta'] as Map<String, dynamic>?;
                final content = delta?['content'] as String?;
                if (content != null && content.isNotEmpty) {
                  yield content;
                }
              }
            } catch (_) {}
          }
        }
      } finally {
        client.close();
      }
    } catch (e) {
      yield '[Error: Stream failed: $e]';
    }
  }

  /// Parse provider string from settings.
  static LlmProvider parseProvider(String provider) {
    switch (provider.toLowerCase()) {
      case 'groq':
        return LlmProvider.groq;
      case 'openai':
        return LlmProvider.openai;
      case 'gemini':
        return LlmProvider.gemini;
      case 'anthropic':
        return LlmProvider.anthropic;
      case 'ollama':
        return LlmProvider.ollama;
      default:
        return LlmProvider.custom;
    }
  }
}
