/// Main chat screen: message list, input bar, empty state,     streaming.
  library chat_screen;

  import 'package:flutter/material.dart';                         import 'package:provider/provider.dart';
  import '../providers/app_provider.dart';
  import '../models/chat_message.dart';
  import '../theme/app_theme.dart';
  import '../core/constants/app_constants.dart';
  import '../widgets/message_bubble.dart';                        import '../widgets/chat_input_bar.dart';

  class ChatScreen extends StatefulWidget {
    const ChatScreen({super.key});                              
    @override
    State<ChatScreen> createState() => _ChatScreenState();
  }                                                             
  class _ChatScreenState extends State<ChatScreen> {
    final ScrollController _scrollController =
  ScrollController();
    final TextEditingController _inputController =
  TextEditingController();
    final List<ChatMessage> _messages = [];
    bool _isGenerating = false;
    bool _hasStarted = false;

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
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }

    Future<void> _sendMessage(String text) async {
      final trimmed = text.trim();
      if (trimmed.isEmpty) return;
      setState(() {                                                     _hasStarted = true;
        _isGenerating = true;
      });                                                       
      final userMsg = ChatMessage(
        id: '${DateTime.now().microsecondsSinceEpoch}_u',
        text: trimmed,                                                  role: MessageRole.user,
        timestamp: DateTime.now(),                                    );
      final aiMsg = ChatMessage(                                        id: '${DateTime.now().microsecondsSinceEpoch}_a',
        text: '',
        role: MessageRole.ai,
        timestamp: DateTime.now(),                                      status: MessageStatus.streaming,
        isStreaming: true,                                            );

      _messages.add(userMsg);
      _messages.add(aiMsg);                                           setState(() {});
      _scrollToBottom();

      final reply = 'Hello! You said: "$trimmed". (This is a
  placeholder reply - Phase 4 will connect to the real            gateway.)';
      var buffer = '';
      for (final token in reply.split(' ')) {
        await Future<void>.delayed(const Duration(milliseconds:   40));
        buffer += (buffer.isEmpty ? '' : ' ') + token;                  final idx = _messages.indexWhere((m) => m.id ==
  aiMsg.id);                                                            if (idx >= 0) {
          _messages[idx] = aiMsg.copyWith(
            text: buffer,                                                   status: MessageStatus.streaming,
            isStreaming: true,                                            );
        }                                                               if (mounted) setState(() {});
      }                                                               final doneIdx = _messages.indexWhere((m) => m.id ==
  aiMsg.id);
      if (doneIdx >= 0) {
        _messages[doneIdx] = aiMsg.copyWith(                              text: reply,
          status: MessageStatus.done,
          isStreaming: false,
        );                                                            }
      setState(() {                                                     _isGenerating = false;
      });
      _scrollToBottom();
    }                                                           
    void _stopGenerating() {
      final idx = _messages.lastIndexWhere((m) =>
  m.isStreaming);
      if (idx >= 0) {
        _messages[idx] = _messages[idx].copyWith(
          status: MessageStatus.done,                                     isStreaming: false,
        );
      }                                                               setState(() => _isGenerating = false);
    }                                                           
    void _regenerate() {
      final lastAiIdx = _messages.lastIndexWhere((m) => m.role
  == MessageRole.ai);
      if (lastAiIdx < 0) return;
      final lastUserMsg = _messages
          .lastWhere((m) => m.role == MessageRole.user, orElse:
  () => _messages.first);
      _messages.removeWhere((m) => m.id ==                        _messages[lastAiIdx].id);
      _sendMessage(lastUserMsg.text);
    }

    @override                                                       Widget build(BuildContext context) {
      final preset =
  context.watch<AppProvider>().themeData.activePreset;
      final isDark = Theme.of(context).brightness ==
  Brightness.dark;                                              
      return Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: _hasStarted                                                  ? ListView.builder(
                        controller: _scrollController,
                        padding: const
  EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        itemCount: _messages.length +
  (_isGenerating ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index == _messages.length) {
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
                          return MessageBubble(message: msg);
                        },
                      )
                    : _EmptyState(onSend: _sendMessage),
              ),
              ChatInputBar(
                controller: _inputController,
                onSend: (text) async {
                  await _sendMessage(text);                                       _inputController.clear();
                },
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

  class _EmptyState extends StatelessWidget {
    final ValueChanged<String> onSend;

    const _EmptyState({required this.onSend});

    static const List<String> _examples = [
      'Write a short poem about the ocean',
      'Explain quantum physics in simple words',
      'Give me 5 healthy breakfast ideas',
      'Draft a professional email to my team',
    ];

    @override
    Widget build(BuildContext context) {
      final preset =
  context.watch<AppProvider>().themeData.activePreset;
      final isDark = Theme.of(context).brightness ==
  Brightness.dark;

      return Center(
        child: ConstrainedBox(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Hello! 👋',
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.black,
                    fontSize: 32,                                                   fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),                                      Text(
                  'Start a conversation with AI Hub',                             style: TextStyle(
                    color: (isDark ? Colors.white :
  Colors.black).withValues(alpha: 0.6),                                             fontSize: 16,
                  ),
                ),
                const SizedBox(height: 32),
                ..._examples.map((example) => GlassContainer(
                  margin: const EdgeInsets.only(bottom: 12),                      child: ListTile(
                    title: Text(
                      example,
                      style: TextStyle(                                                 color: isDark ? Colors.white :
  Colors.black,
                        fontSize: 15,                                                 ),
                    ),                                                              trailing: Icon(Icons.arrow_upward, size: 18,
  color: preset.accent),
                    onTap: () => onSend(example),
                  ),                                                            )),
              ],
            ),                                                            ),
        ),
      );
    }                                                             }
