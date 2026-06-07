import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class GeminiOcrService {
  static const String _baseUrl = 'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent';

  /// Sends the ledger image to Gemini 2.5 Flash to transcribe and clean up
  /// the handwritten notes into standard parsed text.
  static Future<String> transcribeLedger({
    required File imageFile,
    required String apiKey,
  }) async {
    final bytes = await imageFile.readAsBytes();
    final base64Image = base64Encode(bytes);

    final url = Uri.parse('$_baseUrl?key=$apiKey');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'contents': [
          {
            'parts': [
              {
                'text': 'You are a retail POS ledger digitizer. Analyze this handwritten ledger/notebook page containing list of items sold. '
                    'Translate each line of handwritten transaction into a clean, standardized format:\n'
                    '[Product Name] x [Quantity] [Total Price/Amount, if written]\n\n'
                    'Example output:\n'
                    'Coca-Cola x 3 11250\n'
                    'Mineral Water 500ml x 2 6000\n'
                    'Dove Beauty Bar x 1 3125\n\n'
                    'Rules:\n'
                    '- Return ONLY the standardized lines, one per transaction row.\n'
                    '- Do NOT include markdown code blocks (like ```), intro, outro, or explanations.\n'
                    '- Use standard English/Swahili product names close to common inventory names.'
              },
              {
                'inlineData': {
                  'mimeType': 'image/jpeg',
                  'data': base64Image,
                }
              }
            ]
          }
        ],
        'generationConfig': {
          'temperature': 0.1,
        }
      }),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw HttpException('Gemini API call failed with status: ${response.statusCode}');
    }

    final decoded = jsonDecode(response.body);
    final candidates = decoded['candidates'];
    if (candidates is List && candidates.isNotEmpty) {
      final content = candidates.first['content'];
      if (content is Map && content.containsKey('parts')) {
        final parts = content['parts'] as List;
        if (parts.isNotEmpty) {
          final text = parts.first['text'] as String?;
          if (text != null && text.trim().isNotEmpty) {
            return text.trim();
          }
        }
      }
    }

    throw const FormatException('Failed to parse response from Gemini API.');
  }
}
