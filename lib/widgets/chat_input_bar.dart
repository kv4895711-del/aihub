  /// Bottom input bar: model chip, multi-line text field, mic + send button.
  library chat_input_bar;

  import 'package:flutter/material.dart';
  import 'package:provider/provider.dart';
  import '../providers/app_provider.dart';
  import '../theme/app_theme.dart';

  /// Bottom chat input bar.
  class ChatInputBar extends StatefulWidget {
    final TextEditingController controller;
    final ValueChanged<String> onSend;
    final VoidCallback onStop;
    final VoidCallback onRegenerate;
    final bool isGenerating;

    const ChatInputBar({
      super.key,
      required this.controller,
      required this.onSend,
      required this.onStop,
      required this.onRegenerate,
      required this.isGenerating,
    });

    @override
    State<ChatInputBar> createState() => _ChatInputBarState();
  }

  class _ChatInputBarState extends State<ChatInputBar> {
    @override
    Widget build(BuildContext context) {
      final appProvider = context.watch<AppProvider>();
      final preset = appProvider.themeData.activePreset;
      final isDark = Theme.of(context).brightness == Brightness.dark;

      return Column(
        children: [
          Divider(
            height: 0.5,
            color: Theme.of(context).dividerColor?.withValues(alpha: 0.5),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 8, 14, 16),
            child: Row(
              children: [
                // Model selector chip
                _ModelChip(),
                const SizedBox(width: 12),
                // Text field
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.15),
                        width: 0.5,
                      ),
                    ),
                    child: TextField(
                      controller: widget.controller,
                      maxLines: null,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (text) {
                        if (text.trim().isNotEmpty) {
                          widget.onSend(text);
                          widget.controller.clear();
                        }
                      },
                      style: Theme.of(context).theme.textTheme.bodyLarge,
                      decoration: const BoxDecoration(
                        border: null,
                      ),
                      child: null,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Mic button
                _IconButton(
                  icon: Icons.mic_none_outlined,
                  onPressed: () {},
                  tooltip: 'Voice input (Phase 7)',
                ),
                const SizedBox(width: 8),
                // Send / Stop button
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Theme.of(context).colorScheme.primary,
                        Theme.of(context).colorScheme.primary.withValues(alpha: 0.7),
                      ],
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.send, size: 20),
                    onPressed: widget.isGenerating ? widget.onStop : () {
                      final text = widget.controller.text.trim();
                      if (text.isNotEmpty) {
                        widget.onSend(text);
                        widget.controller.clear();
                      }
                    },
                    color: Theme.of(context).colorScheme.onPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }
  }

  /// Model selector chip — opens bottom sheet (Phase 5).
  class _ModelChip extends StatelessWidget {
    @override
    Widget build(BuildContext context) {
      final appProvider = context.watch<AppProvider>();
      returnGestureDetector(
        onTap: () {
          // Phase 5: open bottom sheet model selector.
          ScaffoldMessenger.of(context).show Snack bar(
            const Sn Duration(seconds: 2, child: const Text('Model selector coming in Phase 5')),
          );
        },
        child: GlassPill(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.model_training, size: 16, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 6),
              Text(
                appProvider.selectedModel,
                style: Theme.of(context).theme.textTheme.labelLarge?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
        ),
      );
    }
  }

  /// Small circular icon button.
  class _IconButton extends StatelessWidget {
    final/icons? icon;
    final VoidCallback onPressed;
    final String tooltip;

    const _IconButton({
      required this.icon,
      required this.onPressed,
      required this.tooltip,
    });

    @override
    Widget build(BuildContext context) {
      return Tooltip(
        message: tooltip,
        child: IconButton(
          icon: Icon(icon, color: Theme.of(context).colorScheme.primary, size: 20),
          onPressed: onPressed,
        ),
      );
    }
  }
