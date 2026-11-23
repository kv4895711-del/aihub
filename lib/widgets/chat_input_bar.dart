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
    void _submit() {
      final text = widget.controller.text.trim();
      if (text.isEmpty) return;
      widget.onSend(text);
      widget.controller.clear();
    }

    @override
    Widget build(BuildContext context) {
      final appProvider = context.watch<AppProvider>();
      final preset = appProvider.themeData.activePreset;
      final isDark = Theme.of(context).brightness == Brightness.dark;

      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Divider(
            height: 0.5,
            color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.1),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 8, 14, 16),
            child: Row(                                                                                            crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Model selector chip
                const _ModelChip(),
                const SizedBox(width: 10),
                // Text field
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
                    constraints: const BoxConstraints(minHeight: 44),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: isDark ? 0.15 : 0.4),
                        width: 0.8,
                      ),
                    ),
                    child: TextField(
                      controller: widget.controller,
                      maxLines: 5,
                      minLines: 1,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _submit(),
                      style: Theme.of(context).textTheme.bodyLarge,
                      decoration: const InputDecoration(
                        hintText: 'Message AI Hub...',
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Mic button
                IconButton(
                  tooltip: 'Voice input',
                  icon: Icon(
                    Icons.mic_none_rounded,
                    color: preset.accent,
                    size: 22,
                  ),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                    );
                  },
                ),
                // Send / Stop button
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        preset.accent,
                        preset.accent.withValues(alpha: 0.75),
                      ],
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: preset.accent.withValues(alpha: 0.35),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    icon: Icon(
                      widget.isGenerating ? Icons.stop_rounded : Icons.arrow_upward_rounded,
                      size: 22,
                      color: preset.accentOnSurface,
                    ),
                    onPressed: widget.isGenerating ? widget.onStop : _submit,
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
    const _ModelChip();

    @override
    Widget build(BuildContext context) {
      final appProvider = context.watch<AppProvider>();
      final preset = appProvider.themeData.activePreset;

      return GestureDetector(
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Model selector coming in Phase 5')),
          );
        },
        child: GlassPill(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.auto_awesome_rounded, size: 15, color: preset.accent),
              const SizedBox(width: 6),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 90),
                child: Text(
                  appProvider.selectedModel,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: preset.accent,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }
  }
