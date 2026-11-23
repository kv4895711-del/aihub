  /// Main chat screen: message list, input bar, empty state,
  streaming.
  library chat_screen;

  import 'dart:async';
  import 'package:flutter/material.dart';
  import 'package:provider/provider.dart';
  import 'package:intl/intl.dart';
  import '../providers/app_provider.dart';
  import '../providers/chat_provider.dart';
  import '../models/chat_message.dart';
  import '../theme/app_theme.dart';
  import '../core/constants/app_constants.dart';
  import '../widgets/message_bubble.dart';
  import '../widgets/chat_input_bar.dart';

  /// Main chat screen.
  class ChatScreen extends StatefulWidget {
    const ChatScreen({super.key});

    @override
    State<ChatScreen> createState() => _ChatScreenState();
  }

  class _ChatScreenState extends State<ChatScreen> {
    final ScrollController _scrollController =
  ScrollController();
    final List<ChatMessage> _messages = [];
    bool _isGenerating = false;
    bool _hasStarted = false;

    @override
    void dispose() {
      _scrollController.dispose();
      super.dispose();
    }

    void _scrollToBottom() {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }

    Future<void> _sendMessage(String text) async {
      if (text.trim().isEmpty) return;
      setState(() {
        _hasStarted = true;
        _isGenerating = true;
      });
      _messages.add(ChatMessage(
        id: '${DateTime.now().microsecondsSinceEpoch}_u',
        text: text.trim(),
        role: MessageRole.user,
        timestamp: DateTime.now(),
      ));
      _messages.add(ChatMessage(
        id: '${DateTime.now().microsecondsSinceEpoch}_a',
        text: '',
        role: MessageRole.ai,
        timestamp: DateTime.now(),
        status: MessageStatus.streaming,
        isStreaming: true,
      ));
      setState(() {});
      _scrollToBottom();

      // Simulate streaming reply.
      final reply = _generateReply(text);
      final aiMsg = _messages.lastWhere((m) => m.role ==
  MessageRole.ai);
      var buffer = '';
      for (final token in reply.split(' ')) {
        await Future<void>.delayed(const Duration(milliseconds:
  40));
        buffer += (buffer.isEmpty ? '' : ' ') + token;
        final idx = _messages.indexWhere((m) => m.id ==
  aiMsg.id);
        if (idx >= 0) {
          _messages[idx] = aiMsg.copyWith(text: buffer, status:
  MessageStatus.streaming, isStreaming: true);
        }
        if (mounted) setState(() {});
      }
      final idx = _messages.indexWhere((m) => m.id == aiMsg.id);
      if (idx >= 0) {
        _messages[idx] = aiMsg.copyWith(text: reply, status:
  MessageStatus.done, isStreaming: false);
      }
      setState(() {
        _isGenerating = false;
      });
      _scrollToBottom();
    }

    String _generateReply(String userText) {
      final appProvider = context.read<AppProvider>();
      final model = appProvider.selectedModel;
      return 'Hello! You said: "$userText". (This is a
  placeholder reply — Phase 4 will connect to the real
  gateway.)';
    }

    void _stopGenerating() {
      final aiMsg = _messages.lastWhere(
        (m) => m.role == MessageRole.ai && m.isStreaming,
        orElse: () => _messages.isEmpty
            ? ChatMessage(id: '', text: '', role:
  MessageRole.ai, timestamp: DateTime.now())
            : _messages.last,
      );
      if (aiMsg.id.isNotEmpty) {
        final idx = _messages.indexWhere((m) => m.id ==
  aiMsg.id);
        if (idx >= 0) {
          _messages[idx] = aiMsg.copyWith(status:
  MessageStatus.done, isStreaming: false);
        }
      }
      setState(() => _isGenerating = false);
    }

    void _regenerate() {
      final aiMsg = _messages.lastWhere(
        (m) => m.role == MessageRole.ai,
        orElse: () => _messages.isEmpty
            ? ChatMessage(id: '', text: '', role:
  MessageRole.ai, timestamp: DateTime.now())
            : _messages.last,
      );
      if (aiMsg.id.isEmpty) return;
      final userMsg = _messages.firstWhere(
        (m) => m.role == MessageRole.user,
        orElse: () => ChatMessage(id: '', text: '', role:
  MessageRole.user, timestamp: DateTime.now()),
      );
      if (userMsg.id.isEmpty) return;
      _messages.removeWhere((m) => m.id == aiMsg.id);
      _sendMessage(userMsg.text);
    }

    void _copyMessage(ChatMessage msg) {
      ScaffoldMessenger.of(context).show Snack bar(
        Snack bar(text: const Text('Copied to clipboard')),
      );
    }

    void _readAloud(ChatMessage msg) {
      ScaffoldMessenger.of(context).show Snack bar(
        Snack bar(text: const Text('Read aloud (Phase 7)')),
      );
    }

    @override
    Widget build(BuildContext context) {
      final appProvider = context.watch<AppProvider>();
      final preset = appProvider.themeData.activePreset;
      final isDark = Theme.of(context).brightness ==
  Brightness.dark;

      return Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              // Status pill area (top)
              const SizedBox(height: 8),
              // Message list
              Expanded(
                child: _hasStarted
                    ? ListView.builder(
                        controller: _scrollController,
                        padding: const
  EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        itemCount: _messages.length +
  (_isGenerating ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index == _messages.length) {
                            // Typing indicator
                            return Align(
                              alignment: Alignment.centerLeft,
                              child: GlassContainer(
                                padding: const
  EdgeInsets.all(16),
                                child: TypingIndicator(color:
  preset.accent),
                              ),
                            );
                          }
                          final msg = _messages[index];
                          return MessageBubble(
                            message: msg,
                            onCopy: () => _copyMessage(msg),
                            onReadAloud: () => _readAloud(msg),
                          );
                        },
                      )
                    : _EmptyState(onSend: _sendMessage),
              ),
              // Input bar
              ChatInputBar(
                onSend: _sendMessage,
                onStop: _stopGenerating,
                onRegenerate: _regenerate,
                isGenerating: _isGenerating,
              ),
            ],
          ),
        ),
      );
    }
  }

  /// Empty state with greeting and example prompts.
  class _EmptyState extends StatelessWidget {
    final ValueChanged<String> onSend;

    const _EmptyState({required this.onSend});

    static const List<String> _examples = [
      'Write a short poem about the ocean',
      'Explain quantum physics in simple words',
      'Give me 5 healthy breakfast ideas',
      final isDark = Theme.of(context).brightness ==
  Brightness.dark;

      return Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
             (mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Hello! 👋',
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.black,
                    fontSize: 32,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Start a conversation with AI Hub',
                  style: TextStyle(
                    color: (isDark ? Colors.white :
  Colors.black).withValues(alpha: 0.6),
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 32),
                ..._examples.map((example) => GlassContainer(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    title: Text(
                      example,
                      style: TextStyle(
                        color: isDark ? Colors.white :
  Colors.black,
                        fontSize: 15,
                      ),
                    ),
                    trailing: Icon(Icons.arrow_upward, size: 18,
  color: preset.accent),
                    onTap: () => onSend(example),
                  ),
                )),
              ],
            ),
          ),
        ),
      );
    }
  }
