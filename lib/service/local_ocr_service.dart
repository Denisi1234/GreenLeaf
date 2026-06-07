import 'dart:io';

import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class LocalOcrService {
  static Future<String> recognizeText(File imageFile) async {
    final inputImage = InputImage.fromFile(imageFile);
    final recognizer = TextRecognizer(script: TextRecognitionScript.latin);
    try {
      final recognizedText = await recognizer.processImage(inputImage);
      return _cleanOcrOutput(recognizedText.text);
    } finally {
      await recognizer.close();
    }
  }

  static String _cleanOcrOutput(String text) {
    var cleaned = text.replaceAll('×', 'x').replaceAll('✕', 'x');
    cleaned = cleaned.replaceAll(RegExp(r'\b[tT][sS][hH]\b'), 'tsh');
    cleaned = cleaned.replaceAll(RegExp(r'[–—−]'), '-');
    cleaned = cleaned.replaceAll(RegExp(r'\s+'), ' ').trim();
    return cleaned;
  }
}
