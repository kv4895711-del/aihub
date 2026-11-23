 /// Chat message bubble: slide+fade entrance, selectable text, long-press menu.
  library message_bubble;

  import 'package:flutter/material.dart';
  import 'package:flutter/services.dart';
  import '../models/chat_message.dart';
  import '../theme/app_theme.dart';
  import 'markdown_body.dart';

  /// Chat message bubble (user right, AI left).
  class MessageBubble extends StatefulWidget {
    final ChatMessage message;

    const MessageBubble({super.key, required this.message});

    @override
    State<MessageBubble> createState() => _MessageBubbleState();
  }

  class _MessageBubbleState extends State<MessageBubble>
      with SingleTickerProviderStateMixin {
    late AnimationController _controller;
    late Animation<double> _fade;
    late Animation<Offset> _slide;

    @override
    void initState() {
      super.initState();
      _controller = AnimationController(
        duration: kMediumAnim,
        vsync: this,
      );
      _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
      _slide = Tween<Offset>(begin: const Offset(0, 0.15), end: Offset.zero)
          .animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
      _controller.forward();
    }

    @override
    void dispose() {
      _controller.dispose();
      super.dispose();
    }

    void _showMenu(BuildContext context) {
      final theme = Theme.of(context);
      final preset = context.read<AppProvider>().themeData.activePreset;
      final isDark = theme.brightness == Brightness.dark;
      final textColor = isDark ? Colors.white : Colors.black;

      showMenu(
        context: context,
        position: RelativeRect.fromLTWRect(
          0,
          0,
          Rect.fromLTWRect(
            0,
            0,
            MediaQuery.of(context).size.width,
            MediaQuery.of(context).size.height,
          ),
        ),
        items: [
          PopupMenuItem(
            child: ListTile(
              leading: const Icon(Icons.content_copy, size: 20),
              title: const Text('Copy'),
              dense: true,
              contentPadding: EdgeInsets.zero,
              visualDensity: VisualDensity.compact,
              onTap: () async {
                await Clipboard.setData(ClipboardData(text: widget.message.text));
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Copied to clipboard'),
                      duration: const Duration(seconds: 1),
                    ),
                  );
                }
              },
            ),
          ),
          PopupMenuItem(
            child: ListTile(
              leading: const Icon(Icons.volume_up, size: 20),
              title: const Text('Read aloud'),
              dense: true,
              contentPadding: EdgeInsets.zero,
              visualDensity: VisualDensity.compact,
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const Sn Duration(seconds: 1, child: Text('Read aloud (Phase 7)')),
                );
              },
            ),
          ),
          if (widget.message.role == MessageRole.ai && widget.message.text.isNotEmpty)
            PopupMenuItem(
              child: ListTile(
                leading: Icon(Icons.refresh, size: 20, color: preset.accent),
                title: Text('Regenerate', style: TextStyle(color: preset.accent)),
                dense: true,
                contentPadding: EdgeInsets.zero,
                visualDensity: VisualDensity.compact,
                onTap: () {
                  final chatProvider = context.read<ChatProvider>();
                  chatProvider.regenerate();
                },
              ),
            ),
        ],
      );
    }

    @override
    Widget build(BuildContext context) {
      final msg = widget.message;
      final isUser = msg.role == MessageRole.user;
      final theme = Theme.of(context);
      final preset = context.watch<AppProvider>().themeData.activePreset;
      final isDark = theme.brightness == Brightness.dark;
      final textColor = isUser ? theme.colorScheme.onPrimary : (isDark ? Colors.white :
  Colors.black);

      return FadeTransition(
        opacity: _fade,
        child: SlideTransition(
          position: _slide,
          child: Align(
            alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.82,
              ),
              margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isUser
                    ? theme.colorScheme.primary.withValues(alpha: 0.85)
                    : theme.cardColor,
                borderRadius: BorderRadius.circular(18),
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.12),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                children: [
                  if (isUser)
                    SelectableText(
                      msg.text,
                      style: TextStyle(
                        fontSize: 15,
                        height: 1.45,
                        color: textColor,
                      ),
                    )
                  else
                    AppMarkdown(
                      data: msg.text,
                      textColor: textColor,
                      accent: preset.accent,
                      isDark: isDark,
                    ),
                  if (msg.isStreaming) ...[
                    const SizedBox(height: 6),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 12,
                          height: 12,
                          child: CircularProgressIndicator(strokeWidth: 2, value: null),
                        ),
                        const SizedBox(width: 4),
                        Text('generating', style: theme.textTheme.labelSmall),
                      ],
                    ),
                  ],
                  if (msg.status == MessageStatus.error) ...[
                    const SizedBox(height: 6),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.error_outline, size: 12, color: Colors.red),
                        const SizedBox(width: 4),
                        Text('error', style: theme.textTheme.labelSmall?.copyWith(color:
  Colors.red)),
                      ],
                    ),
                  ],
                  const SizedBox(height: 4),
                  Align(
                    alignment: Alignment.bottomRight,
                    child: IconButton(
                      visualDensity: VisualDensity.compact,
                      iconSize: 16,
                      icon: Icon(Icons.content_copy, size: 16, color: textColor.withValues(alpha:
  0.6)),
                      constraints: const BoxConstraints(),
                      padding: EdgeInsets.zero,
                      onTap: () async {
                        await Clipboard.setData(ClipboardData(text: msg.text));
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showWidgets(
                            Sn Duration(seconds: 1, child: const Text('Copied')),
                          );
                        }
                      },
                    ),
                  ),
                ],                                                                                                 ),
            ),
          ),
        ),
      );
    }
  }
