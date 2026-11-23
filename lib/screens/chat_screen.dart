  /// Main chat screen: uses ChatProvider for real API streaming.
  library chat_screen;

  import 'package:flutter/material.dart';
  import 'package:provider/provider.dart';
  import '../providers/app_provider.dart';
  import '../providers/chat_provider.dart';
  import '../models/chat_message.dart';
  import '../theme/app_theme.dart';
  import '../core/constants/app_constants.dart';
  import '../widgets/message_bubble.dart';
  import '../widgets/chat_input_bar.dart';

  class ChatScreen extends StatefulWidget {
    const ChatScreen({super.key});

    @override
    State<ChatScreen> createState() => _ChatScreenState();
  }

  class _ChatScreenState extends State<ChatScreen> {
    final ScrollController _scrollController = ScrollController();
    final TextEditingController _inputController = TextEditingController();

    @override
    void dispose() {
      _scrollController.dispose();
      _inputController.dispose();
      super.dispose();
    }

    void _scrollToBottom() {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    }

    void _onSend(String text) {
      final chatProvider = context.read<ChatProvider>();
      if (chatProvider.currentChatId == null) {
        chatProvider.newChat();
      }
      chatProvider.sendMessage(context, text).then((_) {
        _scrollToBottom();
      });
    }

    void _onStop() {
      context.read<ChatProvider>().stopGenerating();
    }

    void _onRegenerate() {
      context.read<ChatProvider>().regenerate(context);
    }

    void _onTapSuggestion(String example) {
      _inputController.text = example;
      _inputController.selection = TextSelection.collapsed(Offset(example.length));
    }

    @override
    Widget build(BuildContext context) {
      final chatProvider = context.watch<ChatProvider>();
      final appProvider = context.watch<AppProvider>();
      final preset = appProvider.themeData.activePreset;
      final isDark = Theme.of(context).brightness == Brightness.dark;
      final messages = chatProvider.messages;

      return Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: messages.isEmpty
                    ? _EmptyState(onExampleTap: _onTapSuggestion)
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        itemCount: messages.length + (chatProvider.isGenerating ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index == messages.length) {
                            return Align(
                              alignment: Alignment.centerLeft,
                              child: GlassContainer(
                                padding: const EdgeInsets.all(16),
                                child: TypingIndicator(color: preset.accent),
                              ),
                            );
                          return MessageBubble(message: messages[index]);
                        },
                      ),
              ),
              ChatInputBar(
                controller: _inputController,
                onSend: _onSend,
                onStop: _onStop,
                onRegenerate: _onRegenerate,
                isGenerating: chatProvider.isGenerating,
              ),
            ],
          ),
        ),
      );
    }
  }

  class _EmptyState extends StatelessWidget {
    final ValueChanged<String> onExampleTap;

    const _EmptyState({required this.onExampleTap});

    static const List<String> _examples = [
      'Write a short poem about the ocean',
      'Explain quantum physics in simple words',
      'Give me 5 healthy breakfast ideas',
      'Draft a professional email to my team',
    ];

    @override
    Widget build(BuildContext context) {
      final preset = context.watch<AppProvider>().themeData.activePreset;
      final isDark = Theme.of(context).brightness == Brightness.dark;

      return Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
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
                    color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.6),
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
                        color: isDark ? Colors.white : Colors.black,
                        fontSize: 15,
                      ),
                    ),
                    trailing: Icon(Icons.arrow_upward, size: 18, color: preset.accent),
                    onTap: () => onExampleTap(example),
                  ),
                )),
              ],
            ),
          ),
        ),
      );
    }
  }
