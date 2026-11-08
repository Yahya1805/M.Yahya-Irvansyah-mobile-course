import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../ai/ai_service.dart';

class ChatMessage {
  const ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.isFallback = false,
  });

  final String text;
  final bool isUser;
  final DateTime timestamp;
  final bool isFallback;
}

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key, this.aiService});

  final AiService? aiService;

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  late final AiService _aiService;
  late final bool _ownsAiService;
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  /// Hanya bubble streaming yang mendengarkan notifier ini, sehingga chunk
  /// token tidak me-rebuild seluruh halaman chat.
  final ValueNotifier<String> _streamingText = ValueNotifier<String>('');

  final List<ChatMessage> _messages = [];
  bool _isLoading = false;
  bool _hasStreamingBubble = false;
  String _pendingText = '';
  Timer? _streamTimer;

  StreamSubscription<String>? _streamSubscription;

  @override
  void initState() {
    super.initState();
    _ownsAiService = widget.aiService == null;
    _aiService = widget.aiService ?? AiService();
  }

  @override
  void dispose() {
    _streamTimer?.cancel();
    _streamSubscription?.cancel();
    _streamingText.dispose();
    _inputController.dispose();
    _scrollController.dispose();
    if (_ownsAiService) _aiService.dispose();
    super.dispose();
  }

  /// Scroll otomatis hanya jika pengguna masih berada di dekat dasar list.
  void _scrollToBottom({bool animate = false}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) return;
      final position = _scrollController.position;
      final distanceFromBottom = position.maxScrollExtent - position.pixels;
      if (distanceFromBottom > 160) return;
      if (animate) {
        position.animateTo(
          position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      } else {
        position.jumpTo(position.maxScrollExtent);
      }
    });
  }

  Future<void> _sendMessage() async {
    final text = _inputController.text.trim();
    if (text.isEmpty || _isLoading) return;

    _inputController.clear();
    _pendingText = '';
    setState(() {
      _messages.add(
        ChatMessage(text: text, isUser: true, timestamp: DateTime.now()),
      );
      _isLoading = true;
      _hasStreamingBubble = true;
    });
    _streamingText.value = '';
    _scrollToBottom(animate: true);

    try {
      final stream = _aiService.askStream(text);
      await _streamSubscription?.cancel();
      _streamSubscription = stream.listen(
        _onStreamChunk,
        onError: (Object error) {
          _handleErrorWithFallback(error, text);
        },
        onDone: _onStreamDone,
        cancelOnError: true,
      );
    } catch (e) {
      _handleErrorWithFallback(e, text);
    }
  }

  /// Throttle update visual agar maksimal ~20 rebuild/detik, bukan satu
  /// rebuild untuk setiap kata yang keluar dari stream.
  void _onStreamChunk(String chunk) {
    _pendingText = chunk;
    _streamTimer ??= Timer(const Duration(milliseconds: 50), () {
      _streamTimer = null;
      if (!mounted) return;
      _streamingText.value = _pendingText;
      _scrollToBottom();
    });
  }

  void _onStreamDone() {
    _streamTimer?.cancel();
    _streamTimer = null;

    final finalText = _pendingText.isNotEmpty
        ? _pendingText
        : _streamingText.value;
    if (!mounted) return;

    if (finalText.isEmpty) {
      setState(() {
        _hasStreamingBubble = false;
        _isLoading = false;
      });
      return;
    }

    final isOfflineFallback =
        finalText.contains('Mode Offline') ||
        finalText.contains('Layanan AI sedang sibuk');

    setState(() {
      _messages.add(
        ChatMessage(
          text: finalText,
          isUser: false,
          timestamp: DateTime.now(),
          isFallback: isOfflineFallback,
        ),
      );
      _streamingText.value = '';
      _hasStreamingBubble = false;
      _isLoading = false;
    });
    _scrollToBottom();
  }

  void _handleErrorWithFallback(Object error, String originalQuestion) {
    _streamTimer?.cancel();
    _streamTimer = null;

    setState(() {
      _isLoading = false;
      _hasStreamingBubble = false;
      _streamingText.value = '';
    });

    final errorMsg = error.toString().replaceAll('Exception: ', '');

    // Fallback Dialog jika Layanan AI Sibuk / Kuota Tercapai / Down
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.cloud_off, color: Colors.orange.shade800),
            const SizedBox(width: 8),
            const Text('Layanan AI Sibuk'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(errorMsg),
            const SizedBox(height: 12),
            const Text(
              'Sistem telah mengaktifkan mode offline lokal atau Anda dapat mencoba lagi beberapa saat lagi.',
              style: TextStyle(color: Colors.grey, fontSize: 13),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Tutup'),
          ),
          FilledButton.icon(
            onPressed: () {
              Navigator.pop(ctx);
              _inputController.text = originalQuestion;
              _sendMessage();
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Coba Lagi'),
          ),
        ],
      ),
    );
  }

  Future<void> _showApiKeyDialog() async {
    final currentKey = await _aiService.getApiKey() ?? '';
    final keyController = TextEditingController(text: currentKey);
    if (!mounted) return;

    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Pengaturan API Key'),
        content: TextField(
          controller: keyController,
          decoration: const InputDecoration(
            labelText: 'Gemini / AI API Key',
            hintText: 'Masukkan AI API Key',
            border: OutlineInputBorder(),
          ),
          obscureText: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () async {
              await _aiService.saveApiKey(keyController.text.trim());
              if (ctx.mounted) Navigator.pop(ctx);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('API Key berhasil disimpan')),
                );
              }
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
    keyController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Assistant'),
        actions: [
          IconButton(
            tooltip: 'Pengaturan API Key',
            icon: const Icon(Icons.key),
            onPressed: _showApiKeyDialog,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _messages.isEmpty && !_hasStreamingBubble
                ? const _ChatEmptyState()
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(12),
                    itemCount: _messages.length + (_hasStreamingBubble ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index < _messages.length) {
                        return _MessageBubble(message: _messages[index]);
                      }
                      return _StreamingBubble(text: _streamingText);
                    },
                  ),
          ),
          if (_isLoading && !_hasStreamingBubble)
            const LinearProgressIndicator(),
          _ChatInputField(
            controller: _inputController,
            isLoading: _isLoading,
            onSend: _sendMessage,
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message});

  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;
    final isFallback = message.isFallback;
    final theme = Theme.of(context);
    // sizeOf hanya rebuild saat ukuran layar berubah, bukan setiap frame.
    final maxWidth = MediaQuery.sizeOf(context).width * 0.78;

    Color bgColor;
    if (isUser) {
      bgColor = theme.colorScheme.primary;
    } else if (isFallback) {
      bgColor = Colors.amber.shade100;
    } else {
      bgColor = theme.colorScheme.surfaceContainerHighest;
    }

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(maxWidth: maxWidth),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(16).copyWith(
            bottomRight: isUser ? const Radius.circular(0) : null,
            bottomLeft: !isUser ? const Radius.circular(0) : null,
          ),
          border: isFallback ? Border.all(color: Colors.amber.shade400) : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isFallback) ...[
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.offline_bolt,
                    size: 14,
                    color: Colors.amber.shade900,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Offline Fallback',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.amber.shade900,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
            ],
            Text(
              message.text,
              style: TextStyle(
                color: isUser
                    ? theme.colorScheme.onPrimary
                    : (isFallback
                          ? Colors.brown.shade900
                          : theme.colorScheme.onSurface),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StreamingBubble extends StatelessWidget {
  const _StreamingBubble({required this.text});

  final ValueListenable<String> text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final maxWidth = MediaQuery.sizeOf(context).width * 0.78;

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(maxWidth: maxWidth),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16)
              .copyWith(bottomLeft: const Radius.circular(0)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Flexible(
              child: ValueListenableBuilder<String>(
                valueListenable: text,
                builder: (context, value, _) {
                  return Text(
                    value.isEmpty ? 'Mengetik respons...' : value,
                    style: TextStyle(
                      color: theme.colorScheme.onSurface,
                      fontStyle: value.isEmpty
                          ? FontStyle.italic
                          : FontStyle.normal,
                    ),
                  );
                },
              ),
            ),
            const SizedBox(width: 4),
            const SizedBox(
              width: 8,
              height: 8,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChatInputField extends StatelessWidget {
  const _ChatInputField({
    required this.controller,
    required this.isLoading,
    required this.onSend,
  });

  final TextEditingController controller;
  final bool isLoading;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 6, 12, 12),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              key: const Key('chatInputField'),
              controller: controller,
              decoration: const InputDecoration(
                hintText: 'Tanyakan sesuatu ke AI...',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              onSubmitted: (_) => onSend(),
            ),
          ),
          const SizedBox(width: 8),
          IconButton.filled(
            key: const Key('chatSendButton'),
            icon: isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.send),
            onPressed: isLoading ? null : onSend,
          ),
        ],
      ),
    );
  }
}

class _ChatEmptyState extends StatelessWidget {
  const _ChatEmptyState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.auto_awesome, size: 64, color: Colors.blueAccent),
          SizedBox(height: 12),
          Text(
            'Halo! Ada yang bisa AI bantu?',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 6),
          Text(
            'Tanyakan catatan, jadwal, atau pertanyaan lainnya.',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
