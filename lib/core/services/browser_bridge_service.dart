import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';

typedef OnIncomingNoteCallback = void Function(String title, String content);
typedef OnVisibilityToggledCallback = void Function(bool visible);
typedef OnTranscriptCallback = void Function(
    String text, String source, String lang);

class BrowserBridgeService {
  HttpServer? _server;
  bool _isRunning = false;
  int _port = 8765;
  bool _isOverlayVisible = true;

  bool get isRunning => _isRunning;
  int get port => _port;

  Future<void> start({
    int port = 8765,
    OnIncomingNoteCallback? onNoteReceived,
    OnVisibilityToggledCallback? onVisibilityToggled,
    OnTranscriptCallback? onTranscriptReceived,
    bool initialVisible = true,
  }) async {
    if (kIsWeb) return;
    if (_isRunning) return;
    _port = port;
    _isOverlayVisible = initialVisible;

    try {
      try {
        _server = await HttpServer.bind(InternetAddress.anyIPv4, _port, shared: true);
      } catch (_) {
        _server = await HttpServer.bind(InternetAddress.loopbackIPv4, _port, shared: true);
      }

      _isRunning = true;
      debugPrint('BrowserBridgeService listening on port $_port');

      _server?.listen((HttpRequest request) async {
        // Enable CORS for Chrome Extensions and Localhost
        request.response.headers.add('Access-Control-Allow-Origin', '*');
        request.response.headers.add('Access-Control-Allow-Methods', 'POST, GET, OPTIONS');
        request.response.headers.add('Access-Control-Allow-Headers', 'Content-Type, Authorization');

        if (request.method == 'OPTIONS') {
          request.response.statusCode = HttpStatus.ok;
          await request.response.close();
          return;
        }

        if (request.method == 'POST' && (request.uri.path == '/api/visibility' || request.uri.path == '/api/visibility/')) {
          try {
            final String body = await utf8.decoder.bind(request).join();
            final Map<String, dynamic> data = jsonDecode(body);
            final bool visible = data['visible'] as bool? ?? true;
            _isOverlayVisible = visible;

            if (onVisibilityToggled != null) {
              onVisibilityToggled(visible);
            }

            request.response.statusCode = HttpStatus.ok;
            request.response.write(jsonEncode({'status': 'success', 'visible': _isOverlayVisible}));
          } catch (e) {
            request.response.statusCode = HttpStatus.badRequest;
            request.response.write(jsonEncode({'status': 'error', 'message': e.toString()}));
          }
        } else if (request.method == 'POST' && (request.uri.path == '/api/note' || request.uri.path == '/api/note/')) {
          try {
            final String body = await utf8.decoder.bind(request).join();
            final Map<String, dynamic> data = jsonDecode(body);
            final String title = data['title'] as String? ?? 'Browser Input';
            final String content = data['content'] as String? ?? '';

            if (onNoteReceived != null) {
              onNoteReceived(title, content);
            }

            request.response.statusCode = HttpStatus.ok;
            request.response.write(jsonEncode({'status': 'success', 'message': 'Note received'}));
          } catch (e) {
            request.response.statusCode = HttpStatus.badRequest;
            request.response.write(jsonEncode({'status': 'error', 'message': e.toString()}));
          }
        } else if (request.method == 'POST' && (request.uri.path == '/api/transcript' || request.uri.path == '/api/transcript/')) {
          try {
            final String body = await utf8.decoder.bind(request).join();
            final Map<String, dynamic> data = jsonDecode(body);
            final String text = data['text'] as String? ?? '';
            final String source = data['source'] as String? ?? 'tab_capture';
            final String lang = data['lang'] as String? ?? 'id-ID';

            if (onTranscriptReceived != null && text.isNotEmpty) {
              onTranscriptReceived(text, source, lang);
            }

            request.response.statusCode = HttpStatus.ok;
            request.response.write(jsonEncode({'status': 'success', 'message': 'Transcript received'}));
          } catch (e) {
            request.response.statusCode = HttpStatus.badRequest;
            request.response.write(jsonEncode({'status': 'error', 'message': e.toString()}));
          }
        } else if (request.method == 'GET' && (request.uri.path == '/api/status' || request.uri.path == '/api/status/' || request.uri.path == '/api/health' || request.uri.path == '/api/health/')) {
          request.response.statusCode = HttpStatus.ok;
          request.response.write(jsonEncode({
            'status': 'online',
            'service': 'WhisperCue',
            'visible': _isOverlayVisible,
          }));
        } else {
          request.response.statusCode = HttpStatus.notFound;
          request.response.write(jsonEncode({'status': 'not_found'}));
        }

        await request.response.close();
      });
    } catch (e) {
      debugPrint('Failed to start BrowserBridgeService: $e');
      _isRunning = false;
    }
  }

  Future<void> stop() async {
    if (kIsWeb) return;
    if (_server != null) {
      await _server!.close(force: true);
      _server = null;
    }
    _isRunning = false;
  }
}
