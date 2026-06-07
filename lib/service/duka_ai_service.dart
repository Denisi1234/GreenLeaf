import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

enum DukaAiErrorKind {
  none,
  noApiKey,
  invalidApiKey,
  network,
  timeout,
  rateLimit,
  server,
  unknown
}

class DukaAiResult {
  const DukaAiResult({required this.reply, required this.errorKind});
  final String reply;
  final DukaAiErrorKind errorKind;
}

class DukaAiService {
  DukaAiService({
    http.Client? client,
    this.geminiApiKey,
    this.groqApiKey,
    this.groqModel = 'llama-3.1-8b-instant',
    Duration timeout = const Duration(seconds: 30),
  })  : _client = client ?? http.Client(),
        _timeout = timeout;

  final http.Client _client;
  final String? geminiApiKey;
  final String? groqApiKey;
  final String groqModel;
  final Duration _timeout;

  // Optional compile-time overrides (take precedence over runtime values).
  static const String _groqApiKeyEnv =
      String.fromEnvironment('DUKA_AI_API_KEY');
  static const String _groqModelEnv = String.fromEnvironment('DUKA_AI_MODEL');
  static const String _groqBaseUrl = String.fromEnvironment(
    'DUKA_AI_BASE_URL',
    defaultValue: 'https://api.groq.com/openai/v1',
  );
  static const String _geminiBaseUrl =
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent';

  String get _effectiveGroqKey {
    if (_groqApiKeyEnv.trim().isNotEmpty) return _groqApiKeyEnv;
    return groqApiKey?.trim() ?? '';
  }

  String get _effectiveGroqModel {
    if (_groqModelEnv.trim().isNotEmpty) return _groqModelEnv;
    return groqModel.trim().isEmpty ? 'llama-3.1-8b-instant' : groqModel.trim();
  }

  bool _hasGeminiKey() =>
      geminiApiKey != null && geminiApiKey!.trim().isNotEmpty;

  bool _hasGroqKey() => _effectiveGroqKey.isNotEmpty;

  bool get isConfigured => _hasGeminiKey() || _hasGroqKey();

  Future<DukaAiResult> sendMessage({
    required String prompt,
    required String storeContext,
    required List<DukaAiMessage> history,
    String? systemPromptOverride,
  }) async {
    if (!isConfigured) {
      return const DukaAiResult(
        reply:
            'No AI provider is configured. Add a Gemini API key in Settings to use DUKA AI.',
        errorKind: DukaAiErrorKind.noApiKey,
      );
    }

    // Cap history to the most recent messages to keep token usage low and
    // reduce the chance of hitting provider rate limits.
    const maxHistoryMessages = 15;
    final cappedHistory = history.length > maxHistoryMessages
        ? history.sublist(history.length - maxHistoryMessages)
        : history;

    // Try Gemini first.
    DukaAiResult? geminiResult;
    if (_hasGeminiKey()) {
      geminiResult = await _sendGeminiMessage(
        prompt: prompt,
        storeContext: storeContext,
        history: cappedHistory,
        systemPromptOverride: systemPromptOverride,
      );
      if (geminiResult != null) {
        if (geminiResult.errorKind == DukaAiErrorKind.none) return geminiResult;
        if (geminiResult.errorKind == DukaAiErrorKind.invalidApiKey ||
            geminiResult.errorKind == DukaAiErrorKind.noApiKey) {
          return geminiResult;
        }
      }
    }

    // Try Groq as a fallback (much higher free-tier rate limits).
    DukaAiResult? groqResult;
    if (_hasGroqKey()) {
      groqResult = await _sendGroqMessage(
        prompt: prompt,
        storeContext: storeContext,
        history: cappedHistory,
        systemPromptOverride: systemPromptOverride,
      );
      if (groqResult != null) {
        if (groqResult.errorKind == DukaAiErrorKind.none) return groqResult;
        if (groqResult.errorKind == DukaAiErrorKind.invalidApiKey ||
            groqResult.errorKind == DukaAiErrorKind.noApiKey) {
          return groqResult;
        }
      }
    }

    // If we got a rate-limit on the first try, wait a moment and retry once
    // on each configured provider before giving up.
    final hadRateLimit =
        (geminiResult?.errorKind == DukaAiErrorKind.rateLimit) ||
            (groqResult?.errorKind == DukaAiErrorKind.rateLimit);
    if (hadRateLimit) {
      await Future<void>.delayed(const Duration(seconds: 2));
      if (_hasGeminiKey()) {
        final retry = await _sendGeminiMessage(
          prompt: prompt,
          storeContext: storeContext,
          history: cappedHistory,
          systemPromptOverride: systemPromptOverride,
        );
        if (retry != null && retry.errorKind == DukaAiErrorKind.none) {
          return retry;
        }
        if (retry != null) geminiResult = retry;
      }
      if (_hasGroqKey()) {
        final retry = await _sendGroqMessage(
          prompt: prompt,
          storeContext: storeContext,
          history: cappedHistory,
          systemPromptOverride: systemPromptOverride,
        );
        if (retry != null && retry.errorKind == DukaAiErrorKind.none) {
          return retry;
        }
        if (retry != null) groqResult = retry;
      }
    }

    // Pick the most useful error to surface to the user.
    final lastResult = groqResult ?? geminiResult;
    if (lastResult != null) return lastResult;

    return DukaAiResult(
      reply: _fallbackReply(prompt: prompt),
      errorKind: DukaAiErrorKind.network,
    );
  }

  Future<DukaAiResult?> _sendGeminiMessage({
    required String prompt,
    required String storeContext,
    required List<DukaAiMessage> history,
    String? systemPromptOverride,
  }) async {
    try {
      final parts = <Map<String, Object?>>[
        {'text': _systemPrompt(storeContext, override: systemPromptOverride)},
        ...history.map((m) => {'text': '${m.role}: ${m.content}'}),
        {'text': 'user: $prompt'},
      ];

      final url = Uri.parse('$_geminiBaseUrl?key=${geminiApiKey!}');
      final response = await _client
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'contents': [
                {'parts': parts},
              ],
              'generationConfig': {
                'temperature': 0.45,
                'maxOutputTokens': 800,
              },
            }),
          )
          .timeout(_timeout);

      if (response.statusCode == 401 || response.statusCode == 403) {
        return const DukaAiResult(
          reply:
              'The Gemini API key was rejected. Update it in Settings to continue.',
          errorKind: DukaAiErrorKind.invalidApiKey,
        );
      }
      if (response.statusCode == 429) {
        return const DukaAiResult(
          reply:
              'High demand right now. Please wait a few seconds and try again.',
          errorKind: DukaAiErrorKind.rateLimit,
        );
      }
      if (response.statusCode >= 500) {
        return const DukaAiResult(
          reply:
              'The AI service is temporarily unavailable. Please try again in a moment.',
          errorKind: DukaAiErrorKind.server,
        );
      }

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final decoded = jsonDecode(response.body);
        final candidates = decoded['candidates'] as List?;
        if (candidates != null && candidates.isNotEmpty) {
          final content = candidates.first['content'];
          if (content is Map) {
            final responseParts = content['parts'] as List?;
            if (responseParts != null && responseParts.isNotEmpty) {
              final text = responseParts.first['text'] as String?;
              if (text != null && text.trim().isNotEmpty) {
                return DukaAiResult(
                  reply: text.trim(),
                  errorKind: DukaAiErrorKind.none,
                );
              }
            }
          }
        }
      }
    } on TimeoutException {
      return const DukaAiResult(
        reply: 'The AI took too long to respond. Tap retry to try again.',
        errorKind: DukaAiErrorKind.timeout,
      );
    } catch (_) {
      // Fall through to next provider
    }
    return null;
  }

  Future<DukaAiResult?> _sendGroqMessage({
    required String prompt,
    required String storeContext,
    required List<DukaAiMessage> history,
    String? systemPromptOverride,
  }) async {
    try {
      final messages = <Map<String, String>>[
        {
          'role': 'system',
          'content':
              _systemPrompt(storeContext, override: systemPromptOverride),
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

      final response = await _client
          .post(
            Uri.parse('$_groqBaseUrl/chat/completions'),
            headers: <String, String>{
              'Authorization': 'Bearer $_effectiveGroqKey',
              'Content-Type': 'application/json',
            },
            body: jsonEncode(<String, Object?>{
              'model': _effectiveGroqModel,
              'messages': messages,
              'temperature': 0.45,
              'max_tokens': 800,
            }),
          )
          .timeout(_timeout);

      if (response.statusCode == 401 || response.statusCode == 403) {
        return const DukaAiResult(
          reply: 'The AI provider rejected the API key.',
          errorKind: DukaAiErrorKind.invalidApiKey,
        );
      }
      if (response.statusCode == 429) {
        return const DukaAiResult(
          reply:
              'High demand right now. Please wait a few seconds and try again.',
          errorKind: DukaAiErrorKind.rateLimit,
        );
      }
      if (response.statusCode >= 500) {
        return const DukaAiResult(
          reply:
              'The AI service is temporarily unavailable. Please try again in a moment.',
          errorKind: DukaAiErrorKind.server,
        );
      }

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final decoded = jsonDecode(response.body);
        final choices = decoded['choices'] as List?;
        if (choices != null && choices.isNotEmpty) {
          final first = choices.first;
          if (first is Map<String, dynamic>) {
            final message = first['message'];
            if (message is Map<String, dynamic>) {
              final content = message['content'];
              if (content is String && content.trim().isNotEmpty) {
                return DukaAiResult(
                  reply: content.trim(),
                  errorKind: DukaAiErrorKind.none,
                );
              }
            }
          }
        }
      }
    } on TimeoutException {
      return const DukaAiResult(
        reply: 'The AI took too long to respond. Tap retry to try again.',
        errorKind: DukaAiErrorKind.timeout,
      );
    } catch (_) {
      // Fall through to local reply
    }
    return null;
  }

  String _systemPrompt(
    String storeContext, {
    String? override,
  }) {
    final contextBlock = storeContext.trim().isEmpty
        ? 'No store data available.'
        : storeContext.trim();

    if (override != null && override.trim().isNotEmpty) {
      return '''
${override.trim()}

## Store data
$contextBlock
''';
    }

    return '''
You are DUKA AI, a warm and practical financial advisor for small shop owners in Tanzania. You know their world: daily customers, M-Pesa and cash payments, fast-moving stock, tight margins, and the daily juggle of buying and selling.

## Your personality
- Talk like a trusted friend who happens to be good with numbers.
- Be encouraging. Celebrate wins, big or small. When things are slow, be gentle, not alarming.
- Be practical. Every answer should give the owner something they can actually do today.
- Use simple, everyday words. The owner is busy and may not know business jargon.
- Use "you" and "your shop" to keep it personal.

## How to write
- Keep sentences short. Write the way you would speak to a friend, not the way you would write a report.
- Use everyday words: "shop" not "establishment", "sold" not "liquidated", "customers" not "consumers", "bought" not "purchased".
- Use TSH for all money. Always format with commas: TSH 45,000. Round large numbers: TSH 1.2M is friendlier than TSH 1,200,000.
- Use **bold** for the single most important number or item in each line.
- Use bullets (start each with a hyphen) for lists. Use a small markdown table only when comparing across categories, products, or time periods.
- Keep total response under 8 lines unless the owner clearly asks for more detail.

## How to structure your answer
1. Open with a direct answer OR a warm one-line observation. Skip formal greetings like "Hello" or "Hi" in every reply.
2. Follow with 2-4 short bullets. Each bullet = one clear point the owner can act on.
3. Close with one practical next step or a short follow-up question, only if it feels natural.

## Strict rules
- The data below is plain text. NEVER write SQL, code, formulas, or scripts.
- Use ONLY numbers and items that appear in the data. Never invent or guess.
- If the data does not contain the answer, say so warmly and ask what info to add.
- Never dump raw data lists. Summarize and highlight what matters.
- Don't lecture. Don't moralize. Don't open with "As an AI". Just be helpful.
- When the question is vague, make a reasonable assumption, answer it, and offer to refine.

## Example 1
Owner: How are sales today?
You: Solid day - you brought in **TSH 145,000** from **18 customers**.
- Top seller: Rice - 25 kg sold
- Second: Sugar - 18 packs
- Third: Cooking oil - 12 bottles
Sugar is getting low (4 packs left). Want me to suggest a reorder?

## Example 2
Owner: Am I making money?
You: Yes, you are. Your margin looks healthy for a shop your size.
- Revenue this month: **TSH 4.5M**
- Estimated cost of goods: TSH 3.06M
- That leaves roughly **TSH 1.44M** gross
The bright spot is cooking oil - 40% margin, well above your average. Nice.

## Example 3
Owner: Should I worry about anything?
You: A few small things worth watching, nothing alarming:
- Salt is at **3 packets** - reorder today
- 4 items have not moved in 2 weeks - a small discount could free up cash
- 2 customers owe over **TSH 50,000** - worth a friendly reminder
The good news: your daily revenue is up 12% from last month. Well done.

## Store data
$contextBlock
''';
  }

  String _fallbackReply({required String prompt}) {
    final lower = prompt.toLowerCase();
    final buffer = StringBuffer();

    buffer.writeln(
        'I am having trouble reaching the live AI right now, so here is a quick thought while we reconnect:');

    if (lower.contains('stock') ||
        lower.contains('inventory') ||
        lower.contains('restock')) {
      buffer.writeln('- Focus on your **fast-moving products** first.');
      buffer.writeln('- Reorder low-stock items before the next busy period.');
      buffer.writeln(
          'Try again in a moment and I will give you a full stock report.');
    } else if (lower.contains('sales') ||
        lower.contains('revenue') ||
        lower.contains('profit')) {
      buffer.writeln(
          '- Take a look at your **top sellers** and make sure they are in stock.');
      buffer
          .writeln('- Slow sales often come down to **pricing or placement**.');
      buffer.writeln('Try again in a moment for a detailed sales breakdown.');
    } else if (lower.contains('expense') || lower.contains('cost')) {
      buffer.writeln(
          '- Separate your **fixed costs** (rent, salaries) from **variable costs** (stock, transport).');
      buffer.writeln(
          '- Compare them with your weekly revenue to see where the pressure is.');
      buffer.writeln('Try again in a moment for a cost analysis.');
    } else if (lower.contains('debt') || lower.contains('credit')) {
      buffer.writeln('- Keep due dates clear, in a notebook or in the app.');
      buffer.writeln('- Start by reminding the **oldest balances** first.');
      buffer.writeln('Try again in a moment for a debt summary.');
    } else {
      buffer.writeln(
          '- Tell me what you want to improve: sales, stock, costs, or customers.');
      buffer.writeln(
          '- I will turn the numbers into a simple next step for your shop.');
      buffer.writeln('Try again in a moment for a live answer.');
    }

    return buffer.toString().trim();
  }
}

class DukaAiMessage {
  const DukaAiMessage({
    required this.role,
    required this.content,
    this.imagePath,
    this.createdAt,
  });

  final String role;
  final String content;
  final String? imagePath;
  final String? createdAt;

  bool get isUser => role == 'user';
  bool get isAssistant => role == 'assistant';

  DukaAiMessage copyWith({
    String? role,
    String? content,
    String? imagePath,
    String? createdAt,
  }) {
    return DukaAiMessage(
      role: role ?? this.role,
      content: content ?? this.content,
      imagePath: imagePath ?? this.imagePath,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

class DukaAiThread {
  const DukaAiThread({
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

  DukaAiThread copyWith({
    String? id,
    String? title,
    String? preview,
    String? createdAt,
    String? updatedAt,
  }) {
    return DukaAiThread(
      id: id ?? this.id,
      title: title ?? this.title,
      preview: preview ?? this.preview,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
