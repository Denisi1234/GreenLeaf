import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

import '../../service/duka_ai_service.dart';
import '../../service/pos_local_store.dart';
import '../widgets/app_design.dart';

class DukaAiPage extends StatefulWidget {
  const DukaAiPage({super.key});

  @override
  State<DukaAiPage> createState() => _DukaAiPageState();
}

class DukaAiAdvisorPage extends DukaAiPage {
  const DukaAiAdvisorPage({super.key});
}

class _DukaAiPageState extends State<DukaAiPage> {
  static const int _maxMessageLength = 4000;

  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();
  final ImagePicker _picker = ImagePicker();
  final stt.SpeechToText _speech = stt.SpeechToText();
  DukaAiService _service = DukaAiService();
  final List<DukaAiMessage> _messages = <DukaAiMessage>[];

  bool _isSending = false;
  bool _isStreaming = false;
  bool _isListening = false;
  bool _sttAvailable = false;
  bool _hydrated = false;
  int _requestToken = 0;
  int _greetingToken = 0;
  Timer? _streamTimer;
  String? _activeThreadId;
  String? _pendingAttachmentPath;

  // Context caching: recompute store context at most once per minute.
  String _cachedContext = '';
  DateTime _cachedContextAt = DateTime.fromMillisecondsSinceEpoch(0);
  String _cachedContextFingerprint = '';

  // Send cooldown: block the send button for a short period after sending to
  // avoid rapid-fire requests that trigger provider rate limits.
  static const Duration _sendCooldown = Duration(milliseconds: 1500);
  DateTime _lastSendAt = DateTime.fromMillisecondsSinceEpoch(0);
  Timer? _cooldownTicker;

  // Tracks the most recent error so we can show a retry button on the
  // assistant bubble that contained the error.
  DukaAiErrorKind? _lastAssistantErrorKind;
  int _lastAssistantErrorIndex = -1;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_hydrated) return;
    _hydrated = true;
    _syncFromStore(context.read<PosLocalStore>());
    _controller.addListener(_onControllerChanged);
  }

  void _onControllerChanged() {
    if (mounted) setState(() {});
  }

  bool get _isInCooldown {
    return DateTime.now().difference(_lastSendAt) < _sendCooldown;
  }

  void _startCooldownTicker() {
    _cooldownTicker?.cancel();
    _cooldownTicker =
        Timer.periodic(const Duration(milliseconds: 200), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (!_isInCooldown) {
        timer.cancel();
        setState(() {});
      } else {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _streamTimer?.cancel();
    _cooldownTicker?.cancel();
    _controller.removeListener(_onControllerChanged);
    _controller.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<PosLocalStore>();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = math.min(constraints.maxWidth, 760.0);
            return Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: width),
                child: Column(
                  children: [
                    _DukaAiHeroHeader(
                      onBackTap: () => Navigator.of(context).pop(),
                      onMoreTap: () => _showThreadPicker(context, store),
                      onSubtitleTap: _showTipsSheet,
                    ),
                    Expanded(
                      child: SingleChildScrollView(
                        controller: _scrollController,
                        physics: const BouncingScrollPhysics(),
                        keyboardDismissBehavior:
                            ScrollViewKeyboardDismissBehavior.onDrag,
                        padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            if (_messages.length <= 1) const _DukaAiIntroCard(),
                            const SizedBox(height: 10),
                            _ConversationCard(
                              messages: _messages,
                              isSending: _isSending,
                              isStreaming: _isStreaming,
                              onPromptTap: _handlePromptTap,
                              onRegenerate: (message) => _regenerateLast(store),
                              onRetry: (message) => _retryLastError(store),
                              lastErrorIndex: _lastAssistantErrorIndex,
                            ),
                            const SizedBox(height: 10),
                          ],
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (_isStreaming)
                            _StopGeneratingBar(onStop: _stopGenerating),
                          _Composer(
                            controller: _controller,
                            focusNode: _focusNode,
                            isSending: _isSending,
                            isListening: _isListening,
                            isStreaming: _isStreaming,
                            isInCooldown: _isInCooldown,
                            sttAvailable: _sttAvailable,
                            onVoiceTap: _toggleListening,
                            attachmentPath: _pendingAttachmentPath,
                            onAttachTap: _pickAttachment,
                            onClearAttachment: _clearAttachment,
                            onSend: () => _sendMessage(store),
                            onStopGenerating: _stopGenerating,
                            maxLength: _maxMessageLength,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  void _syncFromStore(PosLocalStore store) {
    _activeThreadId = store.activeDukaAiThreadId;
    _streamTimer?.cancel();
    _messages
      ..clear()
      ..addAll(store.dukaAiMessages);
    if (_messages.isEmpty) {
      _messages.add(DukaAiMessage(
          role: 'assistant',
          content: '',
          createdAt: DateTime.now().toIso8601String()));
      _streamGreeting();
    }
    _service = DukaAiService(
      geminiApiKey: store.geminiApiKey,
      groqApiKey: store.groqApiKey,
      groqModel: store.groqModel,
    );
    _cachedContext = '';
    _cachedContextAt = DateTime.fromMillisecondsSinceEpoch(0);
    _cachedContextFingerprint = '';
    _initSpeech();
  }

  void _stopGenerating() {
    if (!_isStreaming) return;
    _streamTimer?.cancel();
    _requestToken++;
    if (mounted) {
      setState(() {
        _isStreaming = false;
      });
    }
  }

  Future<void> _retryLastError(PosLocalStore store) async {
    if (_isSending || _isStreaming) return;
    if (_messages.isEmpty) return;
    if (_lastAssistantErrorIndex < 0 ||
        _lastAssistantErrorIndex >= _messages.length) {
      return;
    }

    // Remove the error bubble, then regenerate the last user message.
    _messages.removeAt(_lastAssistantErrorIndex);
    await _regenerateLast(store);
  }

  Future<void> _regenerateLast(PosLocalStore store) async {
    if (_isSending || _isStreaming) return;
    if (_messages.isEmpty) return;
    // Find last user message
    int userIndex = -1;
    for (var i = _messages.length - 1; i >= 0; i--) {
      if (_messages[i].isUser) {
        userIndex = i;
        break;
      }
    }
    if (userIndex < 0) return;

    // Remove any assistant messages after the last user message
    while (_messages.length - 1 > userIndex) {
      _messages.removeLast();
    }

    final userMessage = _messages[userIndex];
    final threadId = _activeThreadId ?? store.activeDukaAiThreadId;
    final thread = store.activeDukaAiThread;

    setState(() {
      _isSending = true;
      _isStreaming = false;
      _lastAssistantErrorKind = null;
      _lastAssistantErrorIndex = -1;
    });
    await store.replaceDukaAiMessagesForThread(threadId, _messages);

    _scrollToBottom();

    try {
      final currentToken = ++_requestToken;
      final result = await _service.sendMessage(
        prompt:
            userMessage.imagePath != null && userMessage.imagePath!.isNotEmpty
                ? '${userMessage.content}\n\n[Attachment included for context.]'
                : userMessage.content,
        storeContext: _buildStoreContext(store),
        history: List<DukaAiMessage>.from(_messages),
      );
      if (!mounted || currentToken != _requestToken) return;

      if (result.errorKind == DukaAiErrorKind.noApiKey ||
          result.errorKind == DukaAiErrorKind.invalidApiKey) {
        await _showApiKeyPrompt(store);
        if (!mounted || currentToken != _requestToken) return;
        setState(() {
          _isSending = false;
        });
        return;
      }

      if (result.errorKind != DukaAiErrorKind.none) {
        setState(() {
          _isSending = false;
          _isStreaming = false;
          _messages.add(DukaAiMessage(
            role: 'assistant',
            content: result.reply,
            createdAt: DateTime.now().toIso8601String(),
          ));
          _lastAssistantErrorKind = result.errorKind;
          _lastAssistantErrorIndex = _messages.length - 1;
        });
        await store.replaceDukaAiMessagesForThread(threadId, _messages);
        return;
      }

      setState(() {
        _isSending = false;
        _isStreaming = true;
        _messages.add(DukaAiMessage(
          role: 'assistant',
          content: '',
          createdAt: DateTime.now().toIso8601String(),
        ));
      });
      _streamAssistantReply(
        store: store,
        threadId: threadId,
        reply: result.reply,
        token: currentToken,
      );
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isSending = false;
        _isStreaming = false;
        _messages.add(
          DukaAiMessage(
            role: 'assistant',
            content:
                'I could not reach the live AI service right now. Please try again in a moment.',
            createdAt: DateTime.now().toIso8601String(),
          ),
        );
        _lastAssistantErrorKind = DukaAiErrorKind.network;
        _lastAssistantErrorIndex = _messages.length - 1;
      });
      await store.replaceDukaAiMessagesForThread(threadId, _messages);
    }

    if (thread != null) {
      await store.updateDukaAiThreadPreview(
        threadId,
        userMessage.imagePath != null && userMessage.imagePath!.isNotEmpty
            ? 'Image attachment'
            : userMessage.content,
      );
    }
  }

  Future<void> _showApiKeyPrompt(PosLocalStore store) async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          icon: const Icon(Icons.key_off_rounded,
              color: Color(0xFFB42318), size: 32),
          title: const Text('API key required'),
          content: const Text(
            'Add a Gemini API key in Settings to chat with DUKA AI. The AI service is not configured for this account.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Dismiss'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                Navigator.of(context).pushNamed('/settings');
              },
              child: const Text('Open settings'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _initSpeech() async {
    try {
      _sttAvailable = await _speech.initialize(
        onError: (val) => debugPrint('STT Error: $val'),
        onStatus: (val) => debugPrint('STT Status: $val'),
      );
      if (mounted) setState(() {});
    } catch (_) {}
  }

  Future<void> _toggleListening() async {
    if (!_sttAvailable) return;

    if (_isListening) {
      await _speech.stop();
      setState(() => _isListening = false);
    } else {
      setState(() => _isListening = true);
      await _speech.listen(
        onResult: (val) {
          setState(() {
            _controller.text = val.recognizedWords;
            if (val.finalResult) {
              _isListening = false;
            }
          });
        },
      );
    }
  }

  void _streamGreeting() {
    final greeting = _introMessage().content;
    final token = ++_greetingToken;
    final ts = DateTime.now().toIso8601String();
    var index = 0;
    _streamTimer = Timer.periodic(const Duration(milliseconds: 18), (timer) {
      if (!mounted || token != _greetingToken) {
        timer.cancel();
        return;
      }
      index += 2;
      final visible = greeting.substring(
          0, index > greeting.length ? greeting.length : index);
      setState(() {
        _messages[0] =
            DukaAiMessage(role: 'assistant', content: visible, createdAt: ts);
      });
      if (index >= greeting.length) {
        timer.cancel();
        setState(() {
          _messages[0] = DukaAiMessage(
              role: 'assistant', content: greeting, createdAt: ts);
        });
        _scrollToBottom();
      }
    });
  }

  Future<void> _showTipsSheet() async {
    final store = context.read<PosLocalStore>();
    final tips = <_TipExample>[
      const _TipExample(
        'Sales & revenue',
        'How is my sales performance this week compared to last month?',
      ),
      const _TipExample(
        'Stock check',
        'Which products are running low and need restocking?',
      ),
      const _TipExample(
        'Top sellers',
        'What were my top 5 best-selling products last week?',
      ),
      const _TipExample(
        'Pricing',
        'Suggest a price for sugar given my current cost.',
      ),
      const _TipExample(
        'Receipts',
        'Attach a receipt photo and ask me to summarize it.',
      ),
    ];

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Try asking DUKA AI',
                        style: TextStyle(
                          color: AppColors.ink,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(sheetContext).pop(),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                const Padding(
                  padding: EdgeInsets.only(bottom: 12),
                  child: Text(
                    'Tap a suggestion to send it to the chat.',
                    style: TextStyle(
                      color: AppColors.mutedText,
                      fontSize: 12.5,
                      height: 1.4,
                    ),
                  ),
                ),
                ...tips.map(
                  (tip) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _TipTile(
                      tip: tip,
                      onTap: () {
                        Navigator.of(sheetContext).pop();
                        _controller.text = tip.prompt;
                        _focusNode.requestFocus();
                      },
                    ),
                  ),
                ),
                if (store.geminiApiKey.isEmpty && store.groqApiKey.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF7E6),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFFCD9A1)),
                      ),
                      child: const Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.warning_amber_rounded,
                            color: Color(0xFFB45309),
                            size: 18,
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'No Gemini API key yet. Add one in Settings to get live answers.',
                              style: TextStyle(
                                color: Color(0xFF92400E),
                                fontSize: 12,
                                height: 1.4,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _showThreadPicker(
      BuildContext context, PosLocalStore store) async {
    final selected = await showModalBottomSheet<_ThreadAction>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Chats',
                        style: TextStyle(
                          color: AppColors.ink,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(sheetContext).pop(),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 360,
                  child: ListView.separated(
                    itemCount: store.dukaAiThreads.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final thread = store.dukaAiThreads[index];
                      final isActive = thread.id == store.activeDukaAiThreadId;
                      return Dismissible(
                        key: ValueKey<String>(thread.id),
                        direction: DismissDirection.endToStart,
                        resizeDuration: const Duration(milliseconds: 160),
                        confirmDismiss: (direction) async {
                          final confirmed = await showDialog<bool>(
                            context: sheetContext,
                            builder: (dialogContext) {
                              return AlertDialog(
                                title: const Text('Delete chat?'),
                                content: const Text(
                                  'This thread will be removed from history.',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.of(dialogContext).pop(false),
                                    child: const Text('Cancel'),
                                  ),
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.of(dialogContext).pop(true),
                                    child: const Text('Delete'),
                                  ),
                                ],
                              );
                            },
                          );
                          if (confirmed == true) {
                            if (!sheetContext.mounted) return false;
                            Navigator.of(sheetContext).pop(
                              _ThreadAction.delete(thread.id),
                            );
                            return true;
                          }
                          return false;
                        },
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 12),
                          child: const Icon(
                            Icons.delete_outline_rounded,
                            color: Color(0xFFB42318),
                          ),
                        ),
                        child: ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: CircleAvatar(
                            backgroundColor: isActive
                                ? const Color(0xFFEAF0FF)
                                : const Color(0xFFF2F4F7),
                            child: Icon(
                              Icons.chat_bubble_outline_rounded,
                              color: isActive
                                  ? const Color(0xFF2D6CEA)
                                  : AppColors.mutedText,
                              size: 18,
                            ),
                          ),
                          title: Text(
                            thread.title,
                            style: TextStyle(
                              color: AppColors.ink,
                              fontWeight:
                                  isActive ? FontWeight.w700 : FontWeight.w600,
                            ),
                          ),
                          subtitle: Text(
                            thread.preview.isEmpty
                                ? _formatThreadStamp(thread.updatedAt)
                                : thread.preview,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColors.mutedText,
                              fontSize: 12,
                              height: 1.35,
                            ),
                          ),
                          onTap: () {
                            Navigator.of(sheetContext)
                                .pop(_ThreadAction.open(thread.id));
                          },
                          trailing: PopupMenuButton<_ThreadActionType>(
                            padding: EdgeInsets.zero,
                            onSelected: (type) {
                              switch (type) {
                                case _ThreadActionType.rename:
                                  Navigator.of(sheetContext)
                                      .pop(_ThreadAction.rename(thread.id));
                                  break;
                                case _ThreadActionType.delete:
                                  Navigator.of(sheetContext)
                                      .pop(_ThreadAction.delete(thread.id));
                                  break;
                                case _ThreadActionType.open:
                                case _ThreadActionType.newChat:
                                  break;
                              }
                            },
                            itemBuilder: (context) => [
                              const PopupMenuItem(
                                value: _ThreadActionType.rename,
                                child: Row(
                                  children: [
                                    Icon(Icons.edit_rounded, size: 18),
                                    SizedBox(width: 10),
                                    Text('Rename'),
                                  ],
                                ),
                              ),
                              const PopupMenuItem(
                                value: _ThreadActionType.delete,
                                child: Row(
                                  children: [
                                    Icon(Icons.delete_outline_rounded,
                                        size: 18),
                                    SizedBox(width: 10),
                                    Text('Delete'),
                                  ],
                                ),
                              ),
                            ],
                            child: isActive
                                ? const Icon(
                                    Icons.check_rounded,
                                    color: Color(0xFF2E9E59),
                                  )
                                : const Icon(
                                    Icons.more_horiz_rounded,
                                    color: AppColors.mutedText,
                                  ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () =>
                        Navigator.of(sheetContext).pop(_ThreadAction.newChat()),
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('New chat'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (selected == null) return;
    if (!context.mounted) return;
    if (selected.type == _ThreadActionType.newChat) {
      await _startNewChat(store);
      return;
    }
    if (selected.type == _ThreadActionType.open) {
      await _switchThread(store, selected.threadId!);
      return;
    }
    if (selected.type == _ThreadActionType.rename) {
      await _renameThread(context, store, selected.threadId!);
      return;
    }
    if (selected.type == _ThreadActionType.delete) {
      await _deleteThread(context, store, selected.threadId!);
    }
  }

  Future<void> _startNewChat(PosLocalStore store) async {
    _streamTimer?.cancel();
    setState(() {
      _isSending = false;
      _isStreaming = false;
      _requestToken++;
    });

    await store.createDukaAiThread(
      title: 'New chat',
      seedMessages: <DukaAiMessage>[_introMessage()],
    );
    _syncFromStore(store);
    _scrollToBottom();
    _focusNode.requestFocus();
  }

  Future<void> _switchThread(PosLocalStore store, String threadId) async {
    if (_activeThreadId == threadId) return;

    _streamTimer?.cancel();
    setState(() {
      _isSending = false;
      _isStreaming = false;
      _requestToken++;
    });

    await store.setActiveDukaAiThread(threadId);
    _syncFromStore(store);
    _scrollToBottom();
    _focusNode.requestFocus();
  }

  Future<void> _renameThread(
    BuildContext context,
    PosLocalStore store,
    String threadId,
  ) async {
    final thread = store.dukaAiThreads.firstWhere(
      (item) => item.id == threadId,
      orElse: () => store.activeDukaAiThread!,
    );
    final controller = TextEditingController(text: thread.title);
    final nextTitle = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Rename chat'),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(
              hintText: 'Chat title',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(controller.text),
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
    controller.dispose();
    if (nextTitle == null || nextTitle.trim().isEmpty) return;
    await store.updateDukaAiThreadTitle(threadId, nextTitle);
    _syncFromStore(store);
  }

  Future<void> _deleteThread(
    BuildContext context,
    PosLocalStore store,
    String threadId,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Delete chat?'),
          content: const Text(
              'This removes the thread and its messages permanently.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
    if (confirmed != true) return;
    await store.deleteDukaAiThread(threadId);
    _syncFromStore(store);
    _scrollToBottom();
  }

  Future<void> _handlePromptTap(String prompt) async {
    if (_isSending) return;
    _controller.text = prompt;
    await _sendMessage(context.read<PosLocalStore>());
  }

  Future<void> _pickAttachment() async {
    if (_isSending) return;

    final source = await showModalBottomSheet<ImageSource?>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD9E1EB),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                const SizedBox(height: 16),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.photo_library_outlined),
                  title: const Text('Choose from gallery'),
                  onTap: () =>
                      Navigator.of(sheetContext).pop(ImageSource.gallery),
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.camera_alt_outlined),
                  title: const Text('Open camera'),
                  onTap: () =>
                      Navigator.of(sheetContext).pop(ImageSource.camera),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (source == null) return;

    final image = await _picker.pickImage(
      source: source,
      imageQuality: 88,
    );
    if (image == null || !mounted) return;

    setState(() {
      _pendingAttachmentPath = image.path;
    });
    _focusNode.requestFocus();
  }

  void _clearAttachment() {
    if (_pendingAttachmentPath == null) return;
    setState(() {
      _pendingAttachmentPath = null;
    });
  }

  Future<void> _sendMessage(PosLocalStore store) async {
    final prompt = _controller.text.trim();
    final attachmentPath = _pendingAttachmentPath;
    if (prompt.isEmpty && attachmentPath == null) return;
    if (_isSending) return;
    if (prompt.length > _maxMessageLength) return;
    final now = DateTime.now();
    if (now.difference(_lastSendAt) < _sendCooldown) return;

    // If the previous assistant response was a rate limit, give the provider
    // a longer breather before we hit it again.
    if (_lastAssistantErrorKind == DukaAiErrorKind.rateLimit &&
        now.difference(_lastSendAt) < const Duration(seconds: 3)) {
      return;
    }

    HapticFeedback.mediumImpact();

    final threadId = _activeThreadId ?? store.activeDukaAiThreadId;
    final thread = store.activeDukaAiThread;
    final currentToken = ++_requestToken;
    final userContent =
        prompt.isNotEmpty ? prompt : 'Please review the attached image.';
    final userMessage = DukaAiMessage(
      role: 'user',
      content: userContent,
      imagePath: attachmentPath,
      createdAt: DateTime.now().toIso8601String(),
    );

    setState(() {
      _messages.add(userMessage);
      _controller.clear();
      _pendingAttachmentPath = null;
      _isSending = true;
      _isStreaming = false;
      _greetingToken++; // cancel any greeting stream
      _lastSendAt = DateTime.now();
      _lastAssistantErrorKind = null;
      _lastAssistantErrorIndex = -1;
    });
    _startCooldownTicker();
    await store.replaceDukaAiMessagesForThread(threadId, _messages);
    await store.updateDukaAiThreadPreview(
      threadId,
      attachmentPath == null ? userContent : 'Image attachment',
    );

    if (thread != null && _shouldAutonameThread(thread.title)) {
      await store.updateDukaAiThreadTitle(
        threadId,
        _threadTitleFromPrompt(
          attachmentPath == null ? userContent : 'Image attachment',
        ),
      );
    }

    _scrollToBottom();

    try {
      final result = await _service.sendMessage(
        prompt: attachmentPath == null
            ? userContent
            : '$userContent\n\n[Attachment included for context.]',
        storeContext: _buildStoreContext(store),
        history: List<DukaAiMessage>.from(_messages),
      );
      if (!mounted || currentToken != _requestToken) return;

      if (result.errorKind == DukaAiErrorKind.noApiKey ||
          result.errorKind == DukaAiErrorKind.invalidApiKey) {
        await _showApiKeyPrompt(store);
        if (!mounted || currentToken != _requestToken) return;
        setState(() {
          _isSending = false;
        });
        return;
      }

      if (result.errorKind != DukaAiErrorKind.none) {
        setState(() {
          _isSending = false;
          _isStreaming = false;
          _messages.add(DukaAiMessage(
            role: 'assistant',
            content: result.reply,
            createdAt: DateTime.now().toIso8601String(),
          ));
          _lastAssistantErrorKind = result.errorKind;
          _lastAssistantErrorIndex = _messages.length - 1;
        });
        await store.replaceDukaAiMessagesForThread(threadId, _messages);
        await store.updateDukaAiThreadPreview(
          threadId,
          attachmentPath == null ? userContent : 'Image attachment',
        );
        return;
      }

      setState(() {
        _isSending = false;
        _isStreaming = true;
        _messages.add(DukaAiMessage(
          role: 'assistant',
          content: '',
          createdAt: DateTime.now().toIso8601String(),
        ));
        _lastAssistantErrorKind = null;
        _lastAssistantErrorIndex = -1;
      });
      _streamAssistantReply(
        store: store,
        threadId: threadId,
        reply: result.reply,
        token: currentToken,
      );
    } catch (_) {
      if (!mounted || currentToken != _requestToken) return;
      setState(() {
        _messages.add(
          DukaAiMessage(
            role: 'assistant',
            content:
                'I could not reach the live AI service right now. Please try again in a moment.',
            createdAt: DateTime.now().toIso8601String(),
          ),
        );
        _isSending = false;
        _isStreaming = false;
        _lastAssistantErrorKind = DukaAiErrorKind.network;
        _lastAssistantErrorIndex = _messages.length - 1;
      });
      await store.replaceDukaAiMessagesForThread(threadId, _messages);
      await store.updateDukaAiThreadPreview(
        threadId,
        attachmentPath == null ? userContent : 'Image attachment',
      );
    }

    _scrollToBottom();
  }

  void _streamAssistantReply({
    required PosLocalStore store,
    required String threadId,
    required String reply,
    required int token,
  }) {
    _streamTimer?.cancel();

    if (reply.isEmpty) {
      if (!mounted || token != _requestToken) return;
      setState(() {
        _isStreaming = false;
      });
      unawaited(store.replaceDukaAiMessagesForThread(threadId, _messages));
      return;
    }

    var index = 0;
    const chunk = 3;
    _streamTimer = Timer.periodic(const Duration(milliseconds: 20), (timer) {
      if (!mounted || token != _requestToken) {
        timer.cancel();
        return;
      }

      index += chunk;
      final end = index > reply.length ? reply.length : index;
      final visible = reply.substring(0, end);
      final existingTs = _messages[_messages.length - 1].createdAt;
      setState(() {
        _messages[_messages.length - 1] = DukaAiMessage(
            role: 'assistant', content: visible, createdAt: existingTs);
      });
      _scrollToBottom();

      if (end >= reply.length) {
        timer.cancel();
        setState(() {
          _isStreaming = false;
        });
        _scrollToBottom();
        unawaited(store.replaceDukaAiMessagesForThread(threadId, _messages));
        unawaited(store.updateDukaAiThreadPreview(threadId, reply));
      }
    });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
      );
    });
  }

  bool _shouldAutonameThread(String title) {
    final normalized = title.trim().toLowerCase();
    return normalized.isEmpty ||
        normalized == 'new chat' ||
        normalized == 'duka ai' ||
        normalized == 'myduka ai';
  }

  String _threadTitleFromPrompt(String prompt) {
    final words = prompt
        .trim()
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .toList();
    if (words.isEmpty) return 'New chat';
    final preview = words.take(4).join(' ');
    return preview.length > 28
        ? '${preview.substring(0, 28).trimRight()}...'
        : preview;
  }

  String _formatThreadStamp(String value) {
    final parsed = DateTime.tryParse(value);
    if (parsed == null) return value;
    final now = DateTime.now();
    final sameDay = parsed.year == now.year &&
        parsed.month == now.month &&
        parsed.day == now.day;
    if (sameDay) {
      final hour = parsed.hour == 0
          ? 12
          : parsed.hour > 12
              ? parsed.hour - 12
              : parsed.hour;
      final suffix = parsed.hour >= 12 ? 'PM' : 'AM';
      return 'Today, $hour:${parsed.minute.toString().padLeft(2, '0')} $suffix';
    }

    final monthNames = <String>[
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${monthNames[parsed.month - 1]} ${parsed.day}';
  }

  String _buildStoreContext(PosLocalStore store) {
    const cacheWindow = Duration(seconds: 60);
    const maxContextChars = 6000;

    final fingerprint =
        '${store.inventory.length}|${store.orders.length}|${store.profile.storeName}|${store.profile.ownerName}';
    final now = DateTime.now();
    final isFresh = now.difference(_cachedContextAt) < cacheWindow &&
        fingerprint == _cachedContextFingerprint &&
        _cachedContext.isNotEmpty;

    if (isFresh) return _cachedContext;

    final lines = <String>[];

    lines.add('=== STORE PROFILE ===');
    lines.add(
        'Name: ${store.profile.storeName.isEmpty ? 'Not set' : store.profile.storeName}');
    lines.add(
        'Owner: ${store.profile.ownerName.isEmpty ? 'Not set' : store.profile.ownerName}');
    lines.add('Business: ${store.profile.businessCategory}');

    // Precomputed aggregates so the model can answer totals without mental math.
    final totalInventoryValue = store.inventory.fold<double>(
      0,
      (sum, item) => sum + (item.stockCount * item.purchasePrice),
    );
    final lowStockCount =
        store.inventory.where((i) => i.stockCount <= 5).length;
    final totalRevenue =
        store.orders.fold<double>(0, (sum, o) => sum + o.total);
    final totalOrders = store.orders.length;
    final now2 = DateTime.now();
    final weekAgo = now2.subtract(const Duration(days: 7));
    int weekOrderCount = 0;
    double weekRevenue = 0;
    for (final order in store.orders) {
      final ts = DateTime.tryParse(order.dateTime);
      if (ts != null && ts.isAfter(weekAgo)) {
        weekOrderCount++;
        weekRevenue += order.total;
      }
    }

    lines.add('');
    lines.add('=== QUICK TOTALS ===');
    lines.add(
        '- Inventory items: ${store.inventory.length} (low stock: $lowStockCount)');
    lines.add(
        '- Stock value at cost: TSH ${_formatWithCommas(totalInventoryValue)}');
    lines.add(
        '- Total orders: $totalOrders | Total revenue: TSH ${_formatWithCommas(totalRevenue)}');
    lines.add(
        '- Last 7 days: $weekOrderCount orders, TSH ${_formatWithCommas(weekRevenue)} revenue');

    lines.add('');
    final inventoryCap = store.inventory.length > 80
        ? store.inventory.take(80).toList()
        : store.inventory;
    lines.add(
        '=== INVENTORY (${store.inventory.length} products, showing top ${inventoryCap.length}) ===');
    for (final item in inventoryCap) {
      final lowFlag = item.stockCount <= 5 ? ' [LOW]' : '';
      lines.add(
        '- ${item.name} (${item.category}) | Stock: ${item.stockCount}$lowFlag | Sell: TSH ${_formatWithCommas(item.sellingPrice)} | Cost: TSH ${_formatWithCommas(item.purchasePrice)}',
      );
    }

    lines.add('');
    final orderCap = store.orders.length > 15
        ? store.orders.take(15).toList()
        : store.orders;
    lines.add(
        '=== RECENT ORDERS (${store.orders.length} total, showing latest ${orderCap.length}) ===');
    for (final order in orderCap) {
      final items =
          order.lines.map((l) => '${l.itemName} x${l.quantity}').join(', ');
      lines.add(
        '- ${order.dateTime} | ${order.paymentMethod} | TSH ${_formatWithCommas(order.total)} | $items',
      );
    }

    var context = lines.join('\n');
    if (context.length > maxContextChars) {
      context = '${context.substring(0, maxContextChars)}\n[context truncated]';
    }

    _cachedContext = context;
    _cachedContextAt = now;
    _cachedContextFingerprint = fingerprint;
    return context;
  }

  String _formatWithCommas(num value) {
    final str = value.toStringAsFixed(0);
    final buffer = StringBuffer();
    var count = 0;
    for (var i = str.length - 1; i >= 0; i--) {
      buffer.write(str[i]);
      count++;
      if (count == 3 && i > 0) {
        buffer.write(',');
        count = 0;
      }
    }
    return buffer.toString().split('').reversed.join();
  }

  DukaAiMessage _introMessage() {
    return DukaAiMessage(
      role: 'assistant',
      content: 'Hi! I\'m **DUKA AI**. Ask any question about your business.',
      createdAt: DateTime.now().toIso8601String(),
    );
  }
}

enum _ThreadActionType {
  open,
  rename,
  delete,
  newChat,
}

class _ThreadAction {
  const _ThreadAction(this.type, this.threadId);

  final _ThreadActionType type;
  final String? threadId;

  factory _ThreadAction.open(String threadId) {
    return _ThreadAction(_ThreadActionType.open, threadId);
  }

  factory _ThreadAction.rename(String threadId) {
    return _ThreadAction(_ThreadActionType.rename, threadId);
  }

  factory _ThreadAction.delete(String threadId) {
    return _ThreadAction(_ThreadActionType.delete, threadId);
  }

  factory _ThreadAction.newChat() {
    return const _ThreadAction(_ThreadActionType.newChat, null);
  }
}

String _formatBubbleTime(String? createdAt) {
  final dt = createdAt != null ? DateTime.tryParse(createdAt) : null;
  final time = dt ?? DateTime.now();
  final hour = time.hour == 0
      ? 12
      : time.hour > 12
          ? time.hour - 12
          : time.hour;
  final suffix = time.hour >= 12 ? 'PM' : 'AM';
  return '$hour:${time.minute.toString().padLeft(2, '0')} $suffix';
}

class _DukaAiHeroHeader extends StatelessWidget {
  const _DukaAiHeroHeader({
    required this.onBackTap,
    required this.onMoreTap,
    required this.onSubtitleTap,
  });

  final VoidCallback onBackTap;
  final VoidCallback onMoreTap;
  final VoidCallback onSubtitleTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.95),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
        border: const Border(
          bottom: BorderSide(color: Color(0xFFF1F5F9), width: 1),
        ),
      ),
      child: Row(
        children: [
          Semantics(
            label: 'Go back',
            button: true,
            child: _HeaderActionButton(
              icon: Icons.arrow_back_ios_new_rounded,
              background: const Color(0xFFF1F5F9),
              foreground: const Color(0xFF334155),
              onTap: onBackTap,
            ),
          ),
          const SizedBox(width: 12),
          Hero(
            tag: 'duka_ai_logo',
            child: Semantics(
              label: 'Duka AI logo',
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Center(
                  child: Icon(Icons.smart_toy_rounded,
                      color: Color(0xFF16A34A), size: 32),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'DUKA',
                      style: TextStyle(
                        color: Color(0xFF0F172A),
                        fontSize: 19,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5,
                      ),
                    ),
                    SizedBox(width: 2),
                    Text(
                      'AI',
                      style: TextStyle(
                        color: Color(0xFF16A34A),
                        fontSize: 19,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Semantics(
                  label: 'Show prompt tips',
                  button: true,
                  child: InkWell(
                    onTap: onSubtitleTap,
                    borderRadius: BorderRadius.circular(6),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 2, vertical: 1),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Your business intelligence partner',
                            style: TextStyle(
                              color: Color(0xFF64748B),
                              fontSize: 11.5,
                              fontWeight: FontWeight.w500,
                              letterSpacing: 0.1,
                            ),
                          ),
                          SizedBox(width: 4),
                          Icon(
                            Icons.info_outline_rounded,
                            size: 12,
                            color: Color(0xFF7A859C),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Semantics(
            label: 'Chat history',
            button: true,
            child: _HeaderActionButton(
              icon: Icons.history_rounded,
              background: const Color(0xFFF1F5F9),
              foreground: const Color(0xFF334155),
              onTap: onMoreTap,
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderActionButton extends StatelessWidget {
  const _HeaderActionButton({
    required this.icon,
    required this.background,
    required this.foreground,
    required this.onTap,
  });

  final IconData icon;
  final Color background;
  final Color foreground;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(99),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: background,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: foreground, size: 20),
      ),
    );
  }
}

class _DukaAiIntroCard extends StatelessWidget {
  const _DukaAiIntroCard();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 64),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Icon(
              Icons.smart_toy_rounded,
              color: Color(0xFF16A34A),
              size: 56,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Ask any question about your business',
            style: TextStyle(
              color: Color(0xFF0F172A),
              fontSize: 22,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
              height: 1.25,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _ConversationCard extends StatelessWidget {
  const _ConversationCard({
    required this.messages,
    required this.isSending,
    required this.isStreaming,
    required this.onPromptTap,
    required this.onRegenerate,
    required this.onRetry,
    required this.lastErrorIndex,
  });

  final List<DukaAiMessage> messages;
  final bool isSending;
  final bool isStreaming;
  final ValueChanged<String> onPromptTap;
  final ValueChanged<DukaAiMessage> onRegenerate;
  final ValueChanged<DukaAiMessage> onRetry;
  final int lastErrorIndex;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (messages.length > 1) ...[
          for (var index = 1; index < messages.length; index++)
            () {
              final message = messages[index];
              final isLast = index == messages.length - 1;
              final canRegenerate =
                  isLast && !isSending && !isStreaming && message.isAssistant;
              final isErrorBubble = index == lastErrorIndex &&
                  message.isAssistant &&
                  !isSending &&
                  !isStreaming;
              return TweenAnimationBuilder<double>(
                key: ValueKey<String>(
                    'bubble_${index}_${message.content.length}'),
                tween: Tween<double>(begin: 0, end: 1),
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutCubic,
                builder: (context, value, child) {
                  return Opacity(
                    opacity: value,
                    child: Transform.translate(
                      offset: Offset(0, (1 - value) * 20),
                      child: child,
                    ),
                  );
                },
                child: _ChatBubble(
                  message: message,
                  onRegenerate:
                      canRegenerate ? () => onRegenerate(message) : null,
                  onRetry: isErrorBubble ? () => onRetry(message) : null,
                ),
              );
            }(),
        ] else
          _SampleConversation(onPromptTap: onPromptTap),
        if (isSending && !isStreaming)
          const Padding(
            padding: EdgeInsets.only(top: 6),
            child: _TypingBubble(),
          ),
      ],
    );
  }
}

class _SampleConversation extends StatelessWidget {
  const _SampleConversation({
    required this.onPromptTap,
  });

  final ValueChanged<String> onPromptTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        GestureDetector(
          onTap: () => onPromptTap(
            'How is my sales performance this week compared to last month?',
          ),
          child: Align(
            alignment: Alignment.centerRight,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 380),
              child: const _ChatBubble(
                message: DukaAiMessage(
                  role: 'user',
                  content:
                      'How is my sales performance this week compared to last month?',
                  createdAt: '',
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 14),
        Align(
          alignment: Alignment.centerLeft,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 430),
            child: const _ChatBubble(
              message: DukaAiMessage(
                role: 'assistant',
                content:
                    'Your sales are up by 12%!\nYou\'ve seen a significant boost in morning coffee sales.\n\nWould you like me to generate a detailed forecast for the weekend?',
                createdAt: '',
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _CopyButton extends StatefulWidget {
  const _CopyButton({required this.content});
  final String content;

  @override
  State<_CopyButton> createState() => _CopyButtonState();
}

class _CopyButtonState extends State<_CopyButton> {
  bool _copied = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Clipboard.setData(ClipboardData(text: widget.content));
        setState(() => _copied = true);
        HapticFeedback.lightImpact();
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) setState(() => _copied = false);
        });
      },
      child: _copied
          ? const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.check_rounded, size: 13, color: Color(0xFF16A34A)),
                SizedBox(width: 3),
                Text('Copied',
                    style: TextStyle(
                        color: Color(0xFF16A34A),
                        fontSize: 10,
                        fontWeight: FontWeight.w600)),
              ],
            )
          : const Icon(
              Icons.content_copy_rounded,
              size: 13,
              color: Color(0xFF8A93A7),
            ),
    );
  }
}

class _ChatBubble extends StatelessWidget {
  const _ChatBubble({
    required this.message,
    this.onRegenerate,
    this.onRetry,
  });

  final DukaAiMessage message;
  final VoidCallback? onRegenerate;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;
    final bubbleColor = isUser ? const Color(0xFFF1FBF4) : Colors.white;
    final borderColor =
        isUser ? const Color(0xFFD4EEDC) : const Color(0xFFE1E6EE);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment:
            isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment:
                isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!isUser) ...[
                Semantics(
                  label: 'Duka AI',
                  child: Container(
                    width: 40,
                    height: 40,
                    margin: const EdgeInsets.only(top: 2, right: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.smart_toy_rounded,
                      color: Color(0xFF16A34A),
                      size: 26,
                    ),
                  ),
                ),
              ],
              Flexible(
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 540),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: bubbleColor,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(20),
                      topRight: const Radius.circular(20),
                      bottomLeft: Radius.circular(isUser ? 20 : 4),
                      bottomRight: Radius.circular(isUser ? 4 : 20),
                    ),
                    border: Border.all(color: borderColor),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (message.imagePath != null &&
                          message.imagePath!.isNotEmpty) ...[
                        _ChatAttachmentPreview(imagePath: message.imagePath!),
                        const SizedBox(height: 10),
                      ],
                      if (isUser)
                        Text(
                          message.content,
                          style: const TextStyle(
                            color: Color(0xFF101828),
                            fontSize: 15,
                            height: 1.5,
                            fontWeight: FontWeight.w500,
                          ),
                        )
                      else
                        _AssistantMessageBody(text: message.content),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _formatBubbleTime(message.createdAt),
                            style: const TextStyle(
                              color: Color(0xFF8A93A7),
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          if (!isUser) ...[
                            const SizedBox(width: 8),
                            _CopyButton(content: message.content),
                            if (onRegenerate != null) ...[
                              const SizedBox(width: 6),
                              _RegenerateButton(onTap: onRegenerate!),
                            ],
                            if (onRetry != null) ...[
                              const SizedBox(width: 6),
                              _RetryButton(onTap: onRetry!),
                            ],
                          ],
                          if (isUser) ...[
                            const SizedBox(width: 6),
                            const Icon(
                              Icons.done_all_rounded,
                              size: 14,
                              color: Color(0xFF16A34A),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              if (isUser) ...[
                Container(
                  width: 30,
                  height: 30,
                  margin: const EdgeInsets.only(top: 2, left: 10),
                  decoration: const BoxDecoration(
                    color: Color(0xFF16A34A),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.person_rounded,
                    color: Colors.white,
                    size: 17,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _RegenerateButton extends StatelessWidget {
  const _RegenerateButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Regenerate response',
      button: true,
      child: GestureDetector(
        onTap: onTap,
        child: const Tooltip(
          message: 'Regenerate',
          child: Icon(
            Icons.refresh_rounded,
            size: 13,
            color: Color(0xFF8A93A7),
          ),
        ),
      ),
    );
  }
}

class _RetryButton extends StatelessWidget {
  const _RetryButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Retry last message',
      button: true,
      child: Material(
        color: const Color(0xFFFFF1F2),
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.refresh_rounded, size: 12, color: Color(0xFFB42318)),
                SizedBox(width: 4),
                Text(
                  'Retry',
                  style: TextStyle(
                    color: Color(0xFFB42318),
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TypingBubble extends StatefulWidget {
  const _TypingBubble();

  @override
  State<_TypingBubble> createState() => _TypingBubbleState();
}

class _TypingBubbleState extends State<_TypingBubble>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 40,
          height: 40,
          margin: const EdgeInsets.only(top: 2, right: 10),
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.smart_toy_rounded,
            color: Color(0xFF16A34A),
            size: 26,
          ),
        ),
        AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              constraints: const BoxConstraints(minWidth: 130),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: Color.lerp(
                    const Color(0xFFE1E6EE),
                    const Color(0xFF16A34A),
                    (_controller.value * 0.3).clamp(0.0, 0.3),
                  )!,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'DUKA AI is thinking',
                    style: TextStyle(
                      color: AppColors.mutedText,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(3, (i) {
                      return _buildDot(i);
                    }),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildDot(int index) {
    final anim = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Interval(
          index * 0.15,
          0.5 + index * 0.15,
          curve: Curves.easeInOutBack,
        ),
      ),
    );
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: AnimatedBuilder(
        animation: anim,
        builder: (context, child) {
          return Transform.scale(
            scale: anim.value,
            child: Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: Color.lerp(
                  const Color(0xFFD1D5DB),
                  const Color(0xFF16A34A),
                  anim.value,
                ),
                shape: BoxShape.circle,
              ),
            ),
          );
        },
      ),
    );
  }
}

class _AssistantMessageBody extends StatelessWidget {
  const _AssistantMessageBody({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    const baseStyle = TextStyle(
      color: Color(0xFF101828),
      fontSize: 15.2,
      height: 1.55,
      fontWeight: FontWeight.w500,
    );

    final segments = _splitCodeFences(text);
    final widgets = <Widget>[];

    for (final segment in segments) {
      if (segment.isCode) {
        widgets.add(
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: _CodeBlock(
              code: segment.text.trimRight(),
              language: segment.language,
            ),
          ),
        );
        continue;
      }
      widgets.addAll(_renderPlainLines(segment.text, baseStyle));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: widgets,
    );
  }

  List<Widget> _renderPlainLines(String text, TextStyle baseStyle) {
    final lines = text.split('\n');
    return lines.map<Widget>((line) {
      if (line.trim().isEmpty) {
        return const SizedBox(height: 8);
      }

      final bullet = _BulletLine.parse(line);
      if (bullet != null) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  bullet.marker,
                  style: baseStyle.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: RichText(
                  text: TextSpan(
                    style: baseStyle,
                    children: _buildInlineSpans(bullet.content, baseStyle),
                  ),
                ),
              ),
            ],
          ),
        );
      }

      return Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: RichText(
          text: TextSpan(
            style: baseStyle,
            children: _buildInlineSpans(line, baseStyle),
          ),
        ),
      );
    }).toList();
  }
}

class _CodeSegment {
  const _CodeSegment({required this.text, required this.isCode, this.language});
  final String text;
  final bool isCode;
  final String? language;
}

List<_CodeSegment> _splitCodeFences(String text) {
  final lines = text.split('\n');
  final segments = <_CodeSegment>[];
  final plainBuffer = StringBuffer();
  bool inCode = false;
  String? currentLang;

  for (final line in lines) {
    final trimmed = line.trimLeft();
    if (!inCode && trimmed.startsWith('```')) {
      if (plainBuffer.isNotEmpty) {
        segments.add(_CodeSegment(text: plainBuffer.toString(), isCode: false));
        plainBuffer.clear();
      }
      currentLang = trimmed.length > 3 ? trimmed.substring(3).trim() : null;
      inCode = true;
      continue;
    }
    if (inCode && trimmed == '```') {
      segments.add(_CodeSegment(
        text: plainBuffer.toString(),
        isCode: true,
        language: currentLang,
      ));
      plainBuffer.clear();
      inCode = false;
      currentLang = null;
      continue;
    }
    if (plainBuffer.isNotEmpty) {
      plainBuffer.write('\n');
    }
    plainBuffer.write(line);
  }

  if (inCode) {
    segments.add(_CodeSegment(
      text: plainBuffer.toString(),
      isCode: true,
      language: currentLang,
    ));
  } else if (plainBuffer.isNotEmpty) {
    segments.add(_CodeSegment(text: plainBuffer.toString(), isCode: false));
  }
  return segments;
}

class _CodeBlock extends StatelessWidget {
  const _CodeBlock({required this.code, this.language});

  final String code;
  final String? language;

  @override
  Widget build(BuildContext context) {
    const codeStyle = TextStyle(
      color: Color(0xFF0F172A),
      fontSize: 13.2,
      height: 1.45,
      fontWeight: FontWeight.w500,
      fontFamily: 'monospace',
    );

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE1E6EE)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (language != null && language!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 8, 0),
              child: Row(
                children: [
                  Text(
                    language!.toLowerCase(),
                    style: const TextStyle(
                      color: Color(0xFF7A859C),
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.4,
                    ),
                  ),
                ],
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
            child: SelectableText(
              code,
              style: codeStyle,
            ),
          ),
        ],
      ),
    );
  }
}

class _BulletLine {
  const _BulletLine({
    required this.marker,
    required this.content,
  });

  final String marker;
  final String content;

  static _BulletLine? parse(String line) {
    final bulletMatch = RegExp(r'^\s*[-*•]\s+(.+)$').firstMatch(line);
    if (bulletMatch != null) {
      return _BulletLine(marker: '•', content: bulletMatch.group(1) ?? '');
    }

    final numberedMatch = RegExp(r'^\s*(\d+)[.)]\s+(.+)$').firstMatch(line);
    if (numberedMatch != null) {
      return _BulletLine(
        marker: '${numberedMatch.group(1)}.',
        content: numberedMatch.group(2) ?? '',
      );
    }

    return null;
  }
}

List<InlineSpan> _buildInlineSpans(String text, TextStyle baseStyle) {
  final spans = <InlineSpan>[];
  final pattern = RegExp(r'(\*\*.+?\*\*|`.+?`)');
  var start = 0;

  for (final match in pattern.allMatches(text)) {
    if (match.start > start) {
      spans.add(TextSpan(text: text.substring(start, match.start)));
    }

    final token = match.group(0)!;
    if (token.startsWith('**') && token.endsWith('**')) {
      spans.add(
        TextSpan(
          text: token.substring(2, token.length - 2),
          style: baseStyle.copyWith(fontWeight: FontWeight.w700),
        ),
      );
    } else if (token.startsWith('`') && token.endsWith('`')) {
      spans.add(
        TextSpan(
          text: token.substring(1, token.length - 1),
          style: baseStyle.copyWith(
            fontFamily: 'monospace',
            fontSize: 14.0,
            backgroundColor: const Color(0xFFF1F5F9),
          ),
        ),
      );
    } else {
      spans.add(TextSpan(text: token));
    }

    start = match.end;
  }

  if (start < text.length) {
    spans.add(TextSpan(text: text.substring(start)));
  }

  if (spans.isEmpty) {
    spans.add(TextSpan(text: text));
  }

  return spans;
}

class _ChatAttachmentPreview extends StatelessWidget {
  const _ChatAttachmentPreview({required this.imagePath});

  final String imagePath;

  @override
  Widget build(BuildContext context) {
    final file = File(imagePath);
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 220, maxHeight: 180),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Container(
          color: const Color(0xFFF3F6FA),
          child: file.existsSync()
              ? Image.file(
                  file,
                  width: 220,
                  height: 180,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const SizedBox(
                    height: 140,
                    child: Center(
                      child: Icon(
                        Icons.image_not_supported_outlined,
                        color: AppColors.mutedText,
                      ),
                    ),
                  ),
                )
              : const SizedBox(
                  height: 140,
                  child: Center(
                    child: Icon(
                      Icons.image_not_supported_outlined,
                      color: AppColors.mutedText,
                    ),
                  ),
                ),
        ),
      ),
    );
  }
}

class _ComposerAttachmentPreview extends StatelessWidget {
  const _ComposerAttachmentPreview({
    required this.imagePath,
    required this.onClear,
  });

  final String imagePath;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final file = File(imagePath);
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: 48,
            height: 48,
            color: const Color(0xFFF2F5F9),
            child: file.existsSync()
                ? Image.file(file, fit: BoxFit.cover)
                : const Icon(
                    Icons.image_outlined,
                    color: AppColors.mutedText,
                    size: 20,
                  ),
          ),
        ),
        const SizedBox(width: 10),
        const Flexible(
          child: Text(
            'Attachment ready',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: AppColors.ink,
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        IconButton(
          onPressed: onClear,
          icon: const Icon(
            Icons.close_rounded,
            size: 18,
            color: AppColors.mutedText,
          ),
        ),
      ],
    );
  }
}

class _Composer extends StatelessWidget {
  const _Composer({
    required this.controller,
    required this.focusNode,
    required this.isSending,
    required this.isListening,
    required this.isStreaming,
    required this.isInCooldown,
    required this.sttAvailable,
    required this.onVoiceTap,
    required this.attachmentPath,
    required this.onAttachTap,
    required this.onClearAttachment,
    required this.onSend,
    required this.onStopGenerating,
    required this.maxLength,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool isSending;
  final bool isListening;
  final bool isStreaming;
  final bool isInCooldown;
  final bool sttAvailable;
  final VoidCallback onVoiceTap;
  final String? attachmentPath;
  final VoidCallback onAttachTap;
  final VoidCallback onClearAttachment;
  final VoidCallback onSend;
  final VoidCallback onStopGenerating;
  final int maxLength;

  @override
  Widget build(BuildContext context) {
    final text = controller.text;
    final isOverLimit = text.length > maxLength;
    final isAtWarn = text.length > (maxLength * 0.875).round();
    final canSend = !isSending &&
        !isInCooldown &&
        !isOverLimit &&
        (text.trim().isNotEmpty || attachmentPath != null);
    final showStopButton = isStreaming;
    final buttonEnabled = showStopButton || canSend;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        14,
        0,
        14,
        12 + MediaQuery.of(context).padding.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (attachmentPath != null) ...[
            Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _ComposerAttachmentPreview(
                  imagePath: attachmentPath!,
                  onClear: onClearAttachment,
                ),
              ),
            ),
          ],
          Container(
            constraints: const BoxConstraints(minHeight: 54),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isListening
                    ? const Color(0xFF16A34A)
                    : const Color(0xFFE1E6ED),
                width: isListening ? 1.5 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: isListening
                      ? const Color(0x2016A34A)
                      : const Color(0x060E1726),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Semantics(
                  label: 'Attach image',
                  button: true,
                  child: Material(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(14),
                    child: InkWell(
                      onTap: isSending ? null : onAttachTap,
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFE7ECF2)),
                        ),
                        child: const Icon(
                          Icons.add_photo_alternate_rounded,
                          color: Color(0xFF7E8695),
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                ),
                if (sttAvailable) ...[
                  const SizedBox(width: 8),
                  Semantics(
                    label:
                        isListening ? 'Stop voice input' : 'Start voice input',
                    button: true,
                    child: Material(
                      color: isListening
                          ? const Color(0xFF16A34A)
                          : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(14),
                      child: InkWell(
                        onTap: isSending ? null : onVoiceTap,
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isListening
                                  ? const Color(0xFF16A34A)
                                  : const Color(0xFFE7ECF2),
                            ),
                          ),
                          child: Icon(
                            isListening
                                ? Icons.mic_rounded
                                : Icons.mic_none_rounded,
                            color: isListening
                                ? Colors.white
                                : const Color(0xFF7E8695),
                            size: 19,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: controller,
                    focusNode: focusNode,
                    minLines: 1,
                    maxLines: 5,
                    enabled: !isSending && !isStreaming,
                    textInputAction: TextInputAction.send,
                    keyboardType: TextInputType.multiline,
                    textAlignVertical: TextAlignVertical.center,
                    cursorColor: const Color(0xFF16A34A),
                    onSubmitted: (_) => canSend ? onSend() : null,
                    style: const TextStyle(
                      color: Color(0xFF33363F),
                      fontSize: 13.5,
                      fontWeight: FontWeight.w500,
                    ),
                    decoration: InputDecoration(
                      isDense: true,
                      border: InputBorder.none,
                      hintText: isStreaming
                          ? 'Generating response...'
                          : isListening
                              ? 'Listening...'
                              : 'Type a message...',
                      contentPadding: const EdgeInsets.symmetric(vertical: 10),
                      hintStyle: const TextStyle(
                        color: Color(0xFF7A859C),
                        fontSize: 13.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 5),
                Semantics(
                  label: showStopButton ? 'Stop generating' : 'Send message',
                  button: true,
                  child: Material(
                    color: showStopButton
                        ? const Color(0xFFB42318)
                        : (buttonEnabled
                            ? const Color(0xFF16A34A)
                            : const Color(0xFFCBD5E1)),
                    borderRadius: BorderRadius.circular(14),
                    child: InkWell(
                      onTap: showStopButton
                          ? onStopGenerating
                          : (canSend ? onSend : null),
                      borderRadius: BorderRadius.circular(14),
                      child: SizedBox(
                        width: 40,
                        height: 40,
                        child: showStopButton
                            ? const Icon(
                                Icons.stop_rounded,
                                color: Colors.white,
                                size: 18,
                              )
                            : isSending || isInCooldown
                                ? const Padding(
                                    padding: EdgeInsets.all(11),
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white,
                                      ),
                                    ),
                                  )
                                : const Icon(
                                    Icons.send_rounded,
                                    color: Colors.white,
                                    size: 17,
                                  ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (isAtWarn)
            Padding(
              padding: const EdgeInsets.only(top: 6, left: 4, right: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    '${text.length} / $maxLength',
                    semanticsLabel:
                        '${text.length} of $maxLength characters used',
                    style: TextStyle(
                      color: isOverLimit
                          ? const Color(0xFFB42318)
                          : const Color(0xFF7A859C),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          const Padding(
            padding: EdgeInsets.only(top: 6),
            child: Text(
              'Powered by Gemini · Responses may be inaccurate — verify important numbers',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF8A93A7),
                fontSize: 10.5,
                fontWeight: FontWeight.w500,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StopGeneratingBar extends StatelessWidget {
  const _StopGeneratingBar({required this.onStop});

  final VoidCallback onStop;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFFFF1F2),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFFECDD3)),
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            onTap: onStop,
            borderRadius: BorderRadius.circular(12),
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.stop_circle_outlined,
                      size: 18, color: Color(0xFFB42318)),
                  SizedBox(width: 8),
                  Text(
                    'Stop generating',
                    style: TextStyle(
                      color: Color(0xFFB42318),
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TipExample {
  const _TipExample(this.label, this.prompt);

  final String label;
  final String prompt;
}

class _TipTile extends StatelessWidget {
  const _TipTile({required this.tip, required this.onTap});

  final _TipExample tip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFF8FAFC),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF6EE),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.chat_bubble_outline_rounded,
                  color: Color(0xFF16A34A),
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      tip.label,
                      style: const TextStyle(
                        color: AppColors.ink,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      tip.prompt,
                      style: const TextStyle(
                        color: AppColors.mutedText,
                        fontSize: 12.2,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.arrow_forward_rounded,
                size: 18,
                color: AppColors.mutedText,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
