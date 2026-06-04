import 'dart:convert';

import 'package:http/http.dart' as http;

class MyDukaAiService {
  MyDukaAiService({
    http.Client? client,
  }) : _client = client ?? http.Client();

  final http.Client _client;

  static const String apiKey = String.fromEnvironment('MYDUKA_AI_API_KEY');
  static const String baseUrl = String.fromEnvironment(
    'MYDUKA_AI_BASE_URL',
    defaultValue: 'https://api.groq.com/openai/v1',
  );
  static const String model = String.fromEnvironment(
    'MYDUKA_AI_MODEL',
    defaultValue: 'llama-3.1-8b-instant',
  );

  bool get isConfigured => apiKey.trim().isNotEmpty;

  Future<String> sendMessage({
    required String prompt,
    required String storeContext,
    required List<MyDukaAiMessage> history,
  }) async {
    if (!isConfigured) {
      return _fallbackReply(prompt: prompt, storeContext: storeContext);
    }

    final messages = <Map<String, String>>[
      {
        'role': 'system',
        'content': _systemPrompt(storeContext),
      },
      ...history.map(
        (message) => <String, String>{
          'role': message.role,
          'content': message.imagePath == null || message.imagePath!.isEmpty
              ? message.content
              : '${message.content}\n[Attachment path: ${message.imagePath}]',
        },
      ),
      {
        'role': 'user',
        'content': prompt,
      },
    ];

    final response = await _client.post(
      Uri.parse('$baseUrl/chat/completions'),
      headers: <String, String>{
        'Authorization': 'Bearer $apiKey',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(<String, Object?>{
        'model': model,
        'messages': messages,
        'temperature': 0.4,
      }),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      return _fallbackReply(
        prompt: prompt,
        storeContext: storeContext,
        error: 'API request failed with ${response.statusCode}.',
      );
    }

    final decoded = jsonDecode(response.body);
    final choices = decoded is Map<String, dynamic> ? decoded['choices'] : null;
    if (choices is List && choices.isNotEmpty) {
      final first = choices.first;
      if (first is Map<String, dynamic>) {
        final message = first['message'];
        if (message is Map<String, dynamic>) {
          final content = message['content'];
          if (content is String && content.trim().isNotEmpty) {
            return content.trim();
          }
        }
      }
    }

    return _fallbackReply(
      prompt: prompt,
      storeContext: storeContext,
      error: 'The model returned an unexpected response.',
    );
  }

  String _systemPrompt(String storeContext) {
    return [
      'You are MYDUKA AI, a concise and practical business assistant for a POS app.',
      'Help the user with sales, inventory, pricing, stock planning, expenses, and daily operations.',
      'Use the store context when it is relevant, but do not pretend to know data that is not provided.',
      'If the user asks for a decision, give the recommendation first, then a short reason, then a next step.',
      'Keep answers clear, direct, and business-focused.',
      '',
      'Store context:',
      storeContext.trim().isEmpty ? 'No store context was provided.' : storeContext.trim(),
    ].join('\n');
  }

  String _fallbackReply({
    required String prompt,
    required String storeContext,
    String? error,
  }) {
    final lower = prompt.toLowerCase();
    final buffer = StringBuffer();

    if (error != null) {
      buffer.writeln('I could not reach the live AI model, so I am using a local reply for now.');
    }

    if (lower.contains('stock') || lower.contains('inventory') || lower.contains('restock')) {
      buffer.writeln('Focus on your fast-moving products first, then reorder the low-stock items before the next busy period.');
    } else if (lower.contains('sales') || lower.contains('revenue') || lower.contains('profit')) {
      buffer.writeln('Review your top sellers, keep them available, and check whether slow sales are caused by pricing, placement, or stock gaps.');
    } else if (lower.contains('expense') || lower.contains('cost')) {
      buffer.writeln('Separate fixed costs from variable costs, then compare them with your daily and weekly revenue to see where pressure is coming from.');
    } else if (lower.contains('debt') || lower.contains('credit')) {
      buffer.writeln('Track due dates clearly and remind the oldest balances first so overdue accounts do not keep growing.');
    } else {
      buffer.writeln('Tell me what you want to improve, and I will help you turn the store data into a practical next step.');
    }

    if (storeContext.trim().isNotEmpty) {
      buffer.writeln();
      buffer.writeln('Current store context was included, so I can keep the advice grounded in your business data.');
    }

    return buffer.toString().trim();
  }
}

class MyDukaAiMessage {
  const MyDukaAiMessage({
    required this.role,
    required this.content,
    this.imagePath,
  });

  final String role;
  final String content;
  final String? imagePath;

  bool get isUser => role == 'user';
  bool get isAssistant => role == 'assistant';

  MyDukaAiMessage copyWith({
    String? role,
    String? content,
    String? imagePath,
  }) {
    return MyDukaAiMessage(
      role: role ?? this.role,
      content: content ?? this.content,
      imagePath: imagePath ?? this.imagePath,
    );
  }
}

class MyDukaAiThread {
  const MyDukaAiThread({
    required this.id,
    required this.title,
    required this.preview,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String title;
  final String preview;
  final String createdAt;
  final String updatedAt;

  MyDukaAiThread copyWith({
    String? id,
    String? title,
    String? preview,
    String? createdAt,
    String? updatedAt,
  }) {
    return MyDukaAiThread(
      id: id ?? this.id,
      title: title ?? this.title,
      preview: preview ?? this.preview,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
