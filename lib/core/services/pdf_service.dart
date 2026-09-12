import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

/// Service for picking and extracting text from PDF and TXT files.
class PdfService {
  /// Open native file picker, extract text from selected PDF/TXT, and return text string.
  static Future<String?> pickAndExtractPdfText() async {
    try {
      String? filePath;

      final isMac = !kIsWeb && Platform.isMacOS;

      // On macOS, use osascript native panel to avoid Flutter engine embedder handle crashes
      // caused by third-party file_picker on frameless/alwaysOnTop windows.
      if (isMac) {
        filePath = await _pickFileMacos();
      }

      // Fallback to FilePicker if osascript returned null or not on macOS
      if ((filePath == null || filePath.isEmpty) && !isMac) {
        final result = await FilePicker.platform.pickFiles(
          type: FileType.custom,
          allowedExtensions: ['pdf', 'txt'],
          dialogTitle: 'Select Resume / CV (PDF or TXT)',
        );
        if (result != null && result.files.isNotEmpty) {
          filePath = result.files.first.path;
        }
      }

      if (filePath == null || filePath.isEmpty) return null;

      final file = File(filePath);
      if (!await file.exists()) return null;

      // Handle TXT files
      if (filePath.toLowerCase().endsWith('.txt')) {
        return await file.readAsString();
      }

      // Handle PDF files
      final bytes = await file.readAsBytes();
      final PdfDocument document = PdfDocument(inputBytes: bytes);
      final String extractedText = PdfTextExtractor(document).extractText();
      document.dispose();

      return extractedText.trim();
    } catch (e) {
      debugPrint('[PdfService] Failed to extract PDF text: $e');
      return null;
    }
  }

  static Future<String?> _pickFileMacos() async {
    try {
      final res = await Process.run('osascript', [
        '-e',
        'POSIX path of (choose file with prompt "Select Resume / CV (PDF or TXT)" of type {"pdf", "txt", "PDF", "TXT"})'
      ]);
      if (res.exitCode == 0) {
        final path = res.stdout.toString().trim();
        if (path.isNotEmpty && path != 'false') {
          return path;
        }
      }
    } catch (e) {
      debugPrint('[PdfService] osascript file picker error: $e');
    }
    return null;
  }
}
