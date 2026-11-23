/// Markdown renderer: splits fenced code blocks into styled
  code cards
  /// (monospace, horizontal scroll, copy button) and renders     the rest as markdown.
  library markdown_body;

  import 'package:flutter/material.dart';
  import 'package:flutter/services.dart';
  import 'package:flutter_markdown/flutter_markdown.dart';

  /// A segment of a message: either markdown prose or a fenced
  code block.
  class MarkdownSegment {
    final bool isCode;
    final String language;
    final String text;

    const MarkdownSegment({
      required this.isCode,
      this.language = '',
      this.text = '',
    });
  }

  /// Splits text on ``` fences. An unterminated fence (still
  streaming)
  /// is treated as code so it renders nicely while tokens
  arrive.
  List<MarkdownSegment> splitMarkdownSegments(String data) {
    final result = <MarkdownSegment>[];
    final lines = data.split('\n');
    final buffer = StringBuffer();
    var inCode = false;
    var language = '';

    void flushProse() {
      final text = buffer.toString();
      if (text.trim().isNotEmpty) {
        result.add(MarkdownSegment(isCode: false, text: text));
      }                                                               buffer.clear();
    }
    for (final line in lines) {
      final trimmed = line.trimLeft();
      if (trimmed.startsWith('```')) {
        if (!inCode) {
          flushProse();
          inCode = true;
          language = trimmed.substring(3).trim();
        } else {
          result.add(MarkdownSegment(
            isCode: true,                                                   language: language,
            text: buffer.toString(),
          ));
          buffer.clear();
          inCode = false;                                                 language = '';
        }
      } else {
        buffer.writeln(line);
      }
    }
    final rest = buffer.toString();
    if (rest.trim().isNotEmpty) {
      result.add(MarkdownSegment(
        isCode: inCode,
        language: language,
        text: rest,
      ));
    }
    return result;
  }

  /// Renders a message body: markdown prose + code cards.
  class AppMarkdown extends StatelessWidget {
    final String data;
    final Color textColor;
    final Color accent;
    final bool isDark;                                              final double fontSize;

    const AppMarkdown({
      super.key,
      required this.data,
      required this.textColor,
      required this.accent,                                           required this.isDark,
      this.fontSize = 15,
    });

    @override
    Widget build(BuildContext context) {
      final segments = splitMarkdownSegments(data);
      if (segments.isEmpty) {
        return SelectableText(
          data,
          style: TextStyle(color: textColor, fontSize: fontSize,  height: 1.45),
        );
      }
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final seg in segments)
            seg.isCode
                ? _CodeBlock(
                    language: seg.language,
                    code: seg.text.trimRight(),
                    textColor: textColor,
                    accent: accent,
                    isDark: isDark,
                    fontSize: fontSize,
                  )
                : MarkdownBody(
                    data: seg.text,
                    selectable: true,
                    styleSheet: _styleSheet(),
                  ),
        ],
      );
    }

    MarkdownStyleSheet _styleSheet() {
      return MarkdownStyleSheet(
        p: TextStyle(color: textColor, fontSize: fontSize,
  height: 1.45),
        a: TextStyle(
          color: accent,
          decoration: TextDecoration.underline,
          decorationColor: accent,
        ),                                                              strong: TextStyle(color: textColor, fontWeight:
  FontWeight.w700),
        em: TextStyle(color: textColor, fontStyle:
  FontStyle.italic),                                                    h1: TextStyle(
          color: textColor,
          fontSize: fontSize * 1.5,                                       fontWeight: FontWeight.w700,
          height: 1.3,
        ),
        h2: TextStyle(
          color: textColor,
          fontSize: fontSize * 1.3,
          fontWeight: FontWeight.w700,
          height: 1.3,
        ),
        h3: TextStyle(
          color: textColor,
          fontSize: fontSize * 1.15,
          fontWeight: FontWeight.w600,
          height: 1.3,
        ),                                                              code: TextStyle(
          fontFamily: 'monospace',
          fontSize: fontSize * 0.88,                                      color: textColor,
          backgroundColor: accent.withValues(alpha: 0.12),
        ),
        blockquote: TextStyle(
          color: textColor.withValues(alpha: 0.8),
          fontSize: fontSize,
        ),
        blockquoteDecoration: BoxDecoration(
          color: accent.withValues(alpha: 0.08),
          border: Border(left: BorderSide(color: accent, width:
  3)),
        ),
        blockSpacing: 8,
        listBullet: TextStyle(color: textColor, fontSize:
  fontSize),
      );
    }
  }

  /// Code card: language label, copy button, monospace
  horizontally scrollable code.
  class _CodeBlock extends StatelessWidget {
    final String language;
    final String code;
    final Color textColor;
    final Color accent;
    final bool isDark;
    final double fontSize;

    const _CodeBlock({
      required this.language,
      required this.code,
      required this.textColor,
      required this.accent,
      required this.isDark,
      required this.fontSize,
    });

    @override
    Widget build(BuildContext context) {
      final bg = isDark
          ? Colors.black.withValues(alpha: 0.35)
          : Colors.black.withValues(alpha: 0.06);

      return Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.white.withValues(alpha: isDark ? 0.12
  : 0.2),
            width: 0.6,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 4, 4, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      language.isEmpty ? 'CODE' :
  language.toUpperCase(),
                      style: TextStyle(
                        fontSize: 11,
                        letterSpacing: 0.6,
                        fontWeight: FontWeight.w600,
                        fontWeight: FontWeight.w600,
                        color: textColor.withValues(alpha: 0.6),
                      ),
                    ),
                  ),
                  IconButton(
                    visualDensity: VisualDensity.compact,                                                                iconSize: 16,
                    tooltip: 'Copy code',                                                                                icon: Icon(
                      Icons.copy_rounded,                                                                                  color: textColor.withValues(alpha: 0.7),
                    ),
                    onPressed: () async {
                      await Clipboard.setData(ClipboardData(text: code));
                      if (context.mounted) {                                                                                 ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(                                                                                        content: Text('Code copied'),
                            duration: Duration(seconds: 1),
                          ),                                                                                                 );
                      }                                                                                                  },
                  ),
                ],
              ),                                                                                                 ),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
              child: Text(
                code,
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: fontSize * 0.85,
                  height: 1.4,
                  color: textColor,
                ),
              ),                                                                                                 ),
          ],
        ),
      );
    }
  }
