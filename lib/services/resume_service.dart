import 'dart:io';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

class ResumeService extends GetxService {
  final _storage = GetStorage();

  static const String _storageKeyText = 'cached_resume_text';
  static const String _storageKeyPath = 'cached_resume_path';

  /// Extracts text from the user's resume PDF.
  /// Uses cached text if the file path has not changed.
  Future<String> extractResumeText(String filePath, {bool forceReload = false}) async {
    if (filePath.isEmpty) {
      return '';
    }

    final file = File(filePath);
    if (!await file.exists()) {
      return '';
    }

    // Check cache first
    final cachedPath = _storage.read<String>(_storageKeyPath);
    final cachedText = _storage.read<String>(_storageKeyText);
    if (!forceReload && cachedPath == filePath && cachedText != null && cachedText.isNotEmpty) {
      return cachedText;
    }

    try {
      final bytes = await file.readAsBytes();
      final PdfDocument document = PdfDocument(inputBytes: bytes);
      final PdfTextExtractor extractor = PdfTextExtractor(document);
      final String extractedText = extractor.extractText();
      document.dispose();

      // Clean excessive whitespace
      final cleanedText = extractedText.replaceAll(RegExp(r'\s+'), ' ').trim();

      // Save to cache
      await _storage.write(_storageKeyPath, filePath);
      await _storage.write(_storageKeyText, cleanedText);

      return cleanedText;
    } catch (e) {
      print("[ResumeService] Error parsing resume PDF: $e");
      return '';
    }
  }

  /// Returns already-cached resume text without reading disk
  String getCachedResumeText() {
    return _storage.read<String>(_storageKeyText) ?? '';
  }

  /// Clears resume cache
  void clearCache() {
    _storage.remove(_storageKeyPath);
    _storage.remove(_storageKeyText);
  }
}

