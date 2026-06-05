import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../service/myduka_ai_service.dart';
import '../../service/pos_local_store.dart';
import '../widgets/app_design.dart';

class MyDukaAiPage extends StatefulWidget {
  const MyDukaAiPage({super.key});

  @override
  State<MyDukaAiPage> createState() => _MyDukaAiPageState();
}

class SmartDukaAiAdvisorPage extends MyDukaAiPage {
  const SmartDukaAiAdvisorPage({super.key});
}

class _MyDukaAiPageState extends State<MyDukaAiPage> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();
  final ImagePicker _picker = ImagePicker();
  final MyDukaAiService _service = MyDukaAiService();
  final List<MyDukaAiMessage> _messages = <MyDukaAiMessage>[];

  bool _isSending = false;
  bool _isStreaming = false;
  bool _hydrated = false;
  int _requestToken = 0;
  Timer? _streamTimer;
  String? _activeThreadId;
  String? _pendingAttachmentPath;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_hydrated) return;
    _hydrated = true;
    _syncFromStore(context.read<PosLocalStore>());
  }

  @override
  void dispose() {
    _streamTimer?.cancel();
    _controller.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<PosLocalStore>();
    final threadCount = store.myDukaAiThreads.length;

    return Scaffold(
      backgroundColor: const Color(0xFFF7FAF8),
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
                    ),
                    Expanded(
                      child: SingleChildScrollView(
                        controller: _scrollController,
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _DukaAiIntroCard(
                              threadCount: threadCount,
                            ),
                            const SizedBox(height: 10),
                            _ConversationCard(
                              messages: _messages,
                              isSending: _isSending,
                              isStreaming: _isStreaming,
                              onPromptTap: _handlePromptTap,
                            ),
                            const SizedBox(height: 10),
                          ],
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
                      child: _Composer(
                        controller: _controller,
                        focusNode: _focusNode,
                        isSending: _isSending,
                        attachmentPath: _pendingAttachmentPath,
                        onAttachTap: _pickAttachment,
                        onClearAttachment: _clearAttachment,
                        onSend: () => _sendMessage(store),
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
    _activeThreadId = store.activeMyDukaAiThreadId;
    _messages
      ..clear()
      ..addAll(store.myDukaAiMessages);
    if (_messages.isEmpty) {
      _messages.add(_introMessage());
    }
  }

  Future<void> _showThreadPicker(BuildContext context, PosLocalStore store) async {
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
                    itemCount: store.myDukaAiThreads.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final thread = store.myDukaAiThreads[index];
                      final isActive = thread.id == store.activeMyDukaAiThreadId;
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
                              fontWeight: isActive ? FontWeight.w700 : FontWeight.w600,
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
                            Navigator.of(sheetContext).pop(_ThreadAction.open(thread.id));
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
                                    Icon(Icons.delete_outline_rounded, size: 18),
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
                    onPressed: () => Navigator.of(sheetContext).pop(_ThreadAction.newChat()),
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

    await store.createMyDukaAiThread(
      title: 'New chat',
      seedMessages: <MyDukaAiMessage>[_introMessage()],
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

    await store.setActiveMyDukaAiThread(threadId);
    _syncFromStore(store);
    _scrollToBottom();
    _focusNode.requestFocus();
  }

  Future<void> _renameThread(
    BuildContext context,
    PosLocalStore store,
    String threadId,
  ) async {
    final thread = store.myDukaAiThreads.firstWhere(
      (item) => item.id == threadId,
      orElse: () => store.activeMyDukaAiThread!,
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
    await store.updateMyDukaAiThreadTitle(threadId, nextTitle);
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
          content: const Text('This removes the thread and its messages permanently.'),
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
    await store.deleteMyDukaAiThread(threadId);
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
                  onTap: () => Navigator.of(sheetContext).pop(ImageSource.gallery),
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.camera_alt_outlined),
                  title: const Text('Open camera'),
                  onTap: () => Navigator.of(sheetContext).pop(ImageSource.camera),
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

    final threadId = _activeThreadId ?? store.activeMyDukaAiThreadId;
    final thread = store.activeMyDukaAiThread;
    final currentToken = ++_requestToken;
    final userContent = prompt.isNotEmpty
        ? prompt
        : 'Please review the attached image.';
    final userMessage = MyDukaAiMessage(
      role: 'user',
      content: userContent,
      imagePath: attachmentPath,
    );

    setState(() {
      _messages.add(userMessage);
      _controller.clear();
      _pendingAttachmentPath = null;
      _isSending = true;
      _isStreaming = false;
    });
    await store.replaceMyDukaAiMessagesForThread(threadId, _messages);
    await store.updateMyDukaAiThreadPreview(
      threadId,
      attachmentPath == null ? userContent : 'Image attachment',
    );

    if (thread != null && _shouldAutonameThread(thread.title)) {
      await store.updateMyDukaAiThreadTitle(
        threadId,
        _threadTitleFromPrompt(
          attachmentPath == null ? userContent : 'Image attachment',
        ),
      );
    }

    _scrollToBottom();

    try {
      final reply = await _service.sendMessage(
        prompt: attachmentPath == null
            ? userContent
            : '$userContent\n\n[Attachment included for context.]',
        storeContext: _buildStoreContext(store),
        history: List<MyDukaAiMessage>.from(_messages),
      );
      if (!mounted || currentToken != _requestToken) return;

      setState(() {
        _isSending = false;
        _isStreaming = true;
        _messages.add(const MyDukaAiMessage(role: 'assistant', content: ''));
      });
      _streamAssistantReply(
        store: store,
        threadId: threadId,
        reply: reply,
        token: currentToken,
      );
    } catch (_) {
      if (!mounted || currentToken != _requestToken) return;
      setState(() {
        _messages.add(
          const MyDukaAiMessage(
            role: 'assistant',
            content:
                'I could not reach the live AI service right now. Please try again in a moment.',
          ),
        );
        _isSending = false;
        _isStreaming = false;
      });
      await store.replaceMyDukaAiMessagesForThread(threadId, _messages);
      await store.updateMyDukaAiThreadPreview(
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
      unawaited(store.replaceMyDukaAiMessagesForThread(threadId, _messages));
      return;
    }

    var index = 0;
    _streamTimer = Timer.periodic(const Duration(milliseconds: 14), (timer) {
      if (!mounted || token != _requestToken) {
        timer.cancel();
        return;
      }

      index++;
      final visible = reply.substring(0, math.min(index, reply.length));
      setState(() {
        _messages[_messages.length - 1] =
            MyDukaAiMessage(role: 'assistant', content: visible);
      });

      if (index >= reply.length) {
        timer.cancel();
        setState(() {
          _isStreaming = false;
        });
        unawaited(store.replaceMyDukaAiMessagesForThread(threadId, _messages));
        unawaited(store.updateMyDukaAiThreadPreview(threadId, reply));
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
    return normalized.isEmpty || normalized == 'new chat' || normalized == 'myduka ai';
  }

  String _threadTitleFromPrompt(String prompt) {
    final words = prompt.trim().split(RegExp(r'\s+')).where((word) => word.isNotEmpty).toList();
    if (words.isEmpty) return 'New chat';
    final preview = words.take(4).join(' ');
    return preview.length > 28 ? '${preview.substring(0, 28).trimRight()}...' : preview;
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
    final today = DateTime.now();
    final todayStart = DateTime(today.year, today.month, today.day);
    final tomorrowStart = todayStart.add(const Duration(days: 1));
    final weekStart = todayStart.subtract(const Duration(days: 6));

    final todayOrders = store.orders.where((order) {
      final parsed = DateTime.tryParse(order.dateTime);
      if (parsed == null) return false;
      return !parsed.isBefore(todayStart) && parsed.isBefore(tomorrowStart);
    }).toList();
    final weekOrders = store.orders.where((order) {
      final parsed = DateTime.tryParse(order.dateTime);
      if (parsed == null) return false;
      return !parsed.isBefore(weekStart) && parsed.isBefore(tomorrowStart);
    }).toList();
    final totalRevenue = store.orders.fold<double>(0, (sum, order) => sum + order.total);
    final lowStock = store.inventory.where((item) => item.stockCount <= 20).toList();
    final topProducts = <String, int>{};
    for (final order in weekOrders) {
      for (final line in order.lines) {
        final key = line.itemName;
        topProducts[key] = (topProducts[key] ?? 0) + line.quantity;
      }
    }
    final topSelling = topProducts.entries.toList()
      ..sort((left, right) => right.value.compareTo(left.value));

    return [
      'Store name: ${store.profile.storeName.isEmpty ? 'Not set' : store.profile.storeName}',
      'Owner: ${store.profile.ownerName.isEmpty ? 'Not set' : store.profile.ownerName}',
      'Today orders: ${todayOrders.length}',
      'Week orders: ${weekOrders.length}',
      'Total revenue: TSH ${totalRevenue.toStringAsFixed(0)}',
      'Low stock items: ${lowStock.isEmpty ? 'None' : lowStock.take(5).map((item) => '${item.name} (${item.stockCount})').join(', ')}',
      'Top sellers this week: ${topSelling.isEmpty ? 'None yet' : topSelling.take(5).map((entry) => '${entry.key} (${entry.value})').join(', ')}',
    ].join('\n');
  }

  MyDukaAiMessage _introMessage() {
    return const MyDukaAiMessage(
      role: 'assistant',
      content:
          'Hi, I am MYDUKA AI. Ask me anything about sales, stock, pricing, expenses, or what to do next.',
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

String _formatBubbleTime() {
  final now = DateTime.now();
  final hour = now.hour == 0
      ? 12
      : now.hour > 12
          ? now.hour - 12
          : now.hour;
  final suffix = now.hour >= 12 ? 'PM' : 'AM';
  return '$hour:${now.minute.toString().padLeft(2, '0')} $suffix';
}

class _DukaAiHeroHeader extends StatelessWidget {
  const _DukaAiHeroHeader({
    required this.onBackTap,
    required this.onMoreTap,
  });

  final VoidCallback onBackTap;
  final VoidCallback onMoreTap;

  @override
  Widget build(BuildContext context) {
      return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
        child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Material(
            color: const Color(0xFFF5F7FA),
            shape: const CircleBorder(),
            child: InkWell(
              onTap: onBackTap,
              customBorder: const CircleBorder(),
              child: const SizedBox(
                width: 44,
                height: 44,
                child: Icon(
                  Icons.chevron_left_rounded,
                  color: Color(0xFF111827),
                  size: 26,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            width: 82,
            height: 82,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFFF1FBF5),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 66,
                  height: 66,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFFD7EEDD)),
                  ),
                ),
                const Icon(
                  Icons.smart_toy_outlined,
                  color: Color(0xFF16A34A),
                  size: 32,
                ),
                const Positioned(
                  left: 9,
                  top: 16,
                  child: Icon(
                    Icons.auto_awesome,
                    color: Color(0xFF16A34A),
                    size: 11,
                  ),
                ),
                const Positioned(
                  right: 9,
                  bottom: 16,
                  child: Icon(
                    Icons.auto_awesome,
                    color: Color(0xFF16A34A),
                    size: 9,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          const Expanded(child: _DukaAiTitle()),
          const SizedBox(width: 6),
          Material(
            color: const Color(0xFFF5F7FA),
            shape: const CircleBorder(),
            child: InkWell(
              onTap: onMoreTap,
              customBorder: const CircleBorder(),
              child: const SizedBox(
                width: 54,
                height: 54,
                child: Icon(
                  Icons.more_horiz_rounded,
                  color: Color(0xFF111827),
                  size: 24,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DukaAiTitle extends StatelessWidget {
  const _DukaAiTitle();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: const [
        Text.rich(
          TextSpan(
            style: TextStyle(
              color: Color(0xFF0F172A),
              fontSize: 34,
              fontWeight: FontWeight.w900,
              letterSpacing: -1.2,
            ),
            children: [
              TextSpan(text: 'DUKA '),
              TextSpan(
                text: 'AI',
                style: TextStyle(color: Color(0xFF16A34A)),
              ),
            ],
          ),
        ),
        SizedBox(height: 8),
        Text(
          'Ask me about your business',
          style: TextStyle(
            color: Color(0xFF728098),
            fontSize: 15,
            fontWeight: FontWeight.w500,
            letterSpacing: -0.2,
          ),
        ),
      ],
    );
  }
}

class _DukaAiIntroCard extends StatelessWidget {
  const _DukaAiIntroCard({
    required this.threadCount,
  });

  final int threadCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE3E8EF)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A0F172A),
            blurRadius: 20,
            offset: Offset(0, 7),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFFF6FBF8),
              border: Border.all(color: const Color(0xFFD7EEDD)),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x080F172A),
                  blurRadius: 16,
                  offset: Offset(0, 7),
                ),
              ],
            ),
            child: const Center(
              child: Icon(
                Icons.auto_awesome_rounded,
                color: Color(0xFF16A34A),
                  size: 34,
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Hi there!',
            style: TextStyle(
              color: Color(0xFF0F172A),
              fontSize: 26,
              fontWeight: FontWeight.w900,
              letterSpacing: -1.0,
            ),
          ),
          const SizedBox(height: 8),
          RichText(
            textAlign: TextAlign.center,
            text: const TextSpan(
              style: TextStyle(
                color: Color(0xFF667085),
                fontSize: 16,
                height: 1.32,
                fontWeight: FontWeight.w500,
              ),
              children: [
                TextSpan(text: 'I\'m '),
                TextSpan(
                  text: 'DUKA AI',
                  style: TextStyle(
                    color: Color(0xFF16A34A),
                    fontWeight: FontWeight.w800,
                  ),
                ),
                TextSpan(text: ', your smart business assistant.\nHow can I help you today?'),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: const [
              Expanded(child: Divider(color: Color(0xFFE2E8F0), thickness: 1)),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 10),
                child: Text(
                  'Today',
                  style: TextStyle(
                    color: Color(0xFF8A93A7),
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Expanded(child: Divider(color: Color(0xFFE2E8F0), thickness: 1)),
            ],
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
  });

  final List<MyDukaAiMessage> messages;
  final bool isSending;
  final bool isStreaming;
  final ValueChanged<String> onPromptTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (messages.length > 1)
          for (final message in messages.skip(1)) _ChatBubble(message: message)
        else
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
        Align(
          alignment: Alignment.centerRight,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 380),
            child: _ChatBubble(
              message: const MyDukaAiMessage(
                role: 'user',
                content: 'How is my sales performance this week compared to last month?',
              ),
            ),
          ),
        ),
        const SizedBox(height: 14),
        Align(
          alignment: Alignment.centerLeft,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 430),
            child: _ChatBubble(
              message: const MyDukaAiMessage(
                role: 'assistant',
                content:
                    'Your sales are up by 12%!\nYou\'ve seen a significant boost in morning coffee sales.\n\nWould you like me to generate a detailed forecast for the weekend?',
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ChatBubble extends StatelessWidget {
  const _ChatBubble({required this.message});

  final MyDukaAiMessage message;

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;
    final bubbleColor = isUser ? const Color(0xFFF1FBF4) : Colors.white;
    final textColor = const Color(0xFF101828);
    final borderColor = isUser ? const Color(0xFFD4EEDC) : const Color(0xFFE1E6EE);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            Container(
              width: 28,
              height: 28,
              margin: const EdgeInsets.only(top: 2, right: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFF2FBF6),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.smart_toy_outlined,
                color: Color(0xFF16A34A),
                size: 15,
              ),
            ),
          ],
          Flexible(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 560),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
              decoration: BoxDecoration(
                color: bubbleColor,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(22),
                  topRight: const Radius.circular(22),
                  bottomLeft: Radius.circular(isUser ? 22 : 8),
                  bottomRight: Radius.circular(isUser ? 8 : 22),
                ),
                border: Border.all(color: borderColor),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x060F172A),
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (message.imagePath != null && message.imagePath!.isNotEmpty) ...[
                    _ChatAttachmentPreview(imagePath: message.imagePath!),
                    const SizedBox(height: 10),
                  ],
                  if (isUser)
                    Text(
                      message.content,
                      style: TextStyle(
                        color: textColor,
                        fontSize: 15.2,
                        height: 1.55,
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
                        _formatBubbleTime(),
                        style: const TextStyle(
                          color: Color(0xFF8A93A7),
                          fontSize: 11.5,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (isUser) ...[
                        const SizedBox(width: 6),
                        const Icon(
                          Icons.done_all_rounded,
                          size: 15,
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
              width: 28,
              height: 28,
              margin: const EdgeInsets.only(top: 2, left: 10),
              decoration: BoxDecoration(
                color: const Color(0xFF16A34A),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.person_rounded,
                color: Colors.white,
                size: 16,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _TypingBubble extends StatelessWidget {
  const _TypingBubble();

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 28,
          height: 28,
          margin: const EdgeInsets.only(top: 2, right: 10),
          decoration: BoxDecoration(
            color: const Color(0xFFF2FBF6),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(
            Icons.smart_toy_outlined,
            color: Color(0xFF16A34A),
            size: 15,
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          constraints: const BoxConstraints(minWidth: 140),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFE1E6EE)),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'MYDUKA AI is typing',
                style: TextStyle(
                  color: AppColors.mutedText,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 8),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _TypingDot(delay: 0),
                  SizedBox(width: 5),
                  _TypingDot(delay: 1),
                  SizedBox(width: 5),
                  _TypingDot(delay: 2),
                ],
              ),
            ],
          ),
        ),
      ],
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
    final lines = text.split('\n');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: lines.map((line) {
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
      }).toList(),
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

class _TypingDot extends StatefulWidget {
  const _TypingDot({required this.delay});

  final int delay;

  @override
  State<_TypingDot> createState() => _TypingDotState();
}

class _TypingDotState extends State<_TypingDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _scale = Tween<double>(begin: 0.5, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Interval(
          (widget.delay * 0.16).clamp(0.0, 0.8),
          1.0,
          curve: Curves.easeInOut,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scale,
      child: Container(
        width: 6,
        height: 6,
        decoration: const BoxDecoration(
          color: Color(0xFF6B7280),
          shape: BoxShape.circle,
        ),
      ),
    );
  }
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
    required this.attachmentPath,
    required this.onAttachTap,
    required this.onClearAttachment,
    required this.onSend,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool isSending;
  final String? attachmentPath;
  final VoidCallback onAttachTap;
  final VoidCallback onClearAttachment;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
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
            height: 54,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE1E6ED)),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x060E1726),
                  blurRadius: 6,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Material(
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
                        Icons.auto_awesome_rounded,
                        color: Color(0xFF7E8695),
                        size: 18,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: controller,
                    focusNode: focusNode,
                    minLines: 1,
                    maxLines: 5,
                    enabled: !isSending,
                    textInputAction: TextInputAction.send,
                    keyboardType: TextInputType.multiline,
                    textAlignVertical: TextAlignVertical.center,
                    cursorColor: const Color(0xFF16A34A),
                    onSubmitted: (_) => onSend(),
                    style: const TextStyle(
                      color: Color(0xFF33363F),
                      fontSize: 13.5,
                      fontWeight: FontWeight.w500,
                    ),
                    decoration: const InputDecoration(
                      isDense: true,
                      border: InputBorder.none,
                      hintText: 'Type a message...',
                      contentPadding: EdgeInsets.symmetric(vertical: 10),
                      hintStyle: TextStyle(
                        color: Color(0xFF7A859C),
                        fontSize: 13.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 5),
                Material(
                  color: const Color(0xFF16A34A),
                  borderRadius: BorderRadius.circular(14),
                  child: InkWell(
                    onTap: isSending ? null : onSend,
                    borderRadius: BorderRadius.circular(14),
                    child: SizedBox(
                      width: 40,
                      height: 40,
                      child: Icon(
                        isSending ? Icons.hourglass_top_rounded : Icons.send_rounded,
                        color: Colors.white,
                        size: 17,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
