import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';

/// Callback for incoming transcript from WebSocket clients.
typedef OnWsTranscriptCallback = void Function(
    String text, String source, String lang);

/// Callback for incoming chat question from WebSocket clients.
typedef OnWsChatCallback = void Function(String question);

/// WebSocket server (port 8766) for bidirectional real-time streaming
/// between Chrome extension and Flutter app.
///
/// Protocol (JSON messages):
/// - Client → Server: { "type": "transcript", "text": "...", "source": "tab|mic", "lang": "id-ID" }
/// - Client → Server: { "type": "chat", "question": "..." }
/// - Server → Client: { "type": "ai_chunk", "text": "..." }
/// - Server → Client: { "type": "ai_done" }
/// - Server → Client: { "type": "transcript_ack", "status": "ok" }
class WebSocketBridgeService {
  HttpServer? _server;
  final List<WebSocket> _clients = [];
  bool _isRunning = false;
  int _port = 8766;

  OnWsTranscriptCallback? onTranscriptReceived;
  OnWsChatCallback? onChatReceived;

  bool get isRunning => _isRunning;
  int get port => _port;
  int get clientCount => _clients.length;

  Future<void> start({
    int port = 8766,
    OnWsTranscriptCallback? onTranscript,
    OnWsChatCallback? onChat,
  }) async {
    if (kIsWeb) return;
    if (_isRunning) return;

    _port = port;
    onTranscriptReceived = onTranscript;
    onChatReceived = onChat;

    try {
      _server = await HttpServer.bind(InternetAddress.loopbackIPv4, _port);
      _isRunning = true;
      debugPrint('[WebSocketBridge] Listening on ws://127.0.0.1:$_port');

      _server!.listen(_handleRequest);
    } catch (e) {
      debugPrint('[WebSocketBridge] Failed to start: $e');
      _isRunning = false;
    }
  }

  void _handleRequest(HttpRequest request) async {
    // CORS headers for extension
    request.response.headers.add('Access-Control-Allow-Origin', '*');

    if (WebSocketTransformer.isUpgradeRequest(request)) {
      final socket = await WebSocketTransformer.upgrade(request);
      _clients.add(socket);
      debugPrint('[WebSocketBridge] Client connected (${_clients.length} total)');

      socket.listen(
        (dynamic data) {
          _handleMessage(data, socket);
        },
        onDone: () {
          _clients.remove(socket);
          debugPrint(
              '[WebSocketBridge] Client disconnected (${_clients.length} total)');
        },
        onError: (error) {
          _clients.remove(socket);
          debugPrint('[WebSocketBridge] Client error: $error');
        },
      );
    } else {
      // Serve a simple health check for non-WebSocket requests
      request.response.statusCode = HttpStatus.ok;
      request.response.write(jsonEncode({
        'service': 'StealthOverlay WebSocket Bridge',
        'clients': _clients.length,
        'status': 'online',
      }));
      await request.response.close();
    }
  }

  void _handleMessage(dynamic data, WebSocket sender) {
    try {
      final msg = jsonDecode(data as String) as Map<String, dynamic>;
      final type = msg['type'] as String?;

      switch (type) {
        case 'transcript':
          final text = msg['text'] as String? ?? '';
          final source = msg['source'] as String? ?? 'mic';
          final lang = msg['lang'] as String? ?? 'id-ID';
          onTranscriptReceived?.call(text, source, lang);
          sender.add(jsonEncode({'type': 'transcript_ack', 'status': 'ok'}));
          break;

        case 'chat':
          final question = msg['question'] as String? ?? '';
          onChatReceived?.call(question);
          break;

        default:
          debugPrint('[WebSocketBridge] Unknown message type: $type');
      }
    } catch (e) {
      debugPrint('[WebSocketBridge] Message parse error: $e');
    }
  }

  /// Broadcast a message to all connected WebSocket clients.
  void broadcast(Map<String, dynamic> message) {
    final encoded = jsonEncode(message);
    for (final client in _clients) {
      try {
        client.add(encoded);
      } catch (_) {}
    }
  }

  /// Send a streaming AI chunk to all clients.
  void sendAIChunk(String text) {
    broadcast({'type': 'ai_chunk', 'text': text});
  }

  /// Signal that AI response generation is complete.
  void sendAIDone() {
    broadcast({'type': 'ai_done'});
  }

  Future<void> stop() async {
    if (kIsWeb) return;
    for (final client in _clients) {
      try {
        await client.close();
      } catch (_) {}
    }
    _clients.clear();

    if (_server != null) {
      await _server!.close(force: true);
      _server = null;
    }
    _isRunning = false;
  }
}
