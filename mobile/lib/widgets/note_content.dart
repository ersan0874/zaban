import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:zaban/config/api_config.dart';
import 'package:zaban/theme/app_theme.dart';
import 'package:zaban/widgets/math_text.dart';

final _tableSeparator = RegExp(r'^\|?\s*:?-{2,}:?\s*(\|\s*:?-{2,}:?\s*)*\|?$');
final _heading = RegExp(r'^(#{1,6})\s+(.*)$');
final _bullet = RegExp(r'^\s*(?:[-*•]|\d+[.)])\s+(.*)$');
final _figure =
    RegExp(r'^\[(?:figure|شکل|تصویر)\s*:\s*(.*)\]$', caseSensitive: false);
final _image = RegExp(r'^!\[([^\]]*)\]\(([^)\s]+)\)$');

/// One lesson note: paragraphs with LaTeX plus Markdown headings, lists,
/// tables, images and `[figure: ...]` placeholders from the extractor.
class NoteContent extends StatelessWidget {
  const NoteContent(this.markdown, {super.key, this.style});

  final String markdown;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final base = style ??
        GoogleFonts.vazirmatn(fontSize: 15, height: 1.7, color: AppColors.ink);
    final blocks = <Widget>[];
    final paragraph = <String>[];
    final table = <String>[];

    void flushParagraph() {
      if (paragraph.isEmpty) return;
      blocks.add(MathText(paragraph.join('\n'), style: base));
      paragraph.clear();
    }

    void flushTable() {
      if (table.isEmpty) return;
      blocks.add(_NoteTable(rows: List.of(table), style: base));
      table.clear();
    }

    for (final raw in markdown.split('\n')) {
      final line = raw.trimRight();
      final trimmed = line.trim();
      if (trimmed.startsWith('|')) {
        flushParagraph();
        if (!_tableSeparator.hasMatch(trimmed)) table.add(trimmed);
        continue;
      }
      flushTable();
      if (trimmed.isEmpty) {
        flushParagraph();
        continue;
      }
      final heading = _heading.firstMatch(trimmed);
      final bullet = _bullet.firstMatch(line);
      final figure = _figure.firstMatch(trimmed);
      final image = _image.firstMatch(trimmed);
      if (heading != null) {
        flushParagraph();
        blocks.add(
          MathText(
            heading.group(2)!,
            style: base.copyWith(
              fontWeight: FontWeight.w900,
              fontSize: (base.fontSize ?? 15) +
                  (heading.group(1)!.length == 1 ? 3 : 1),
            ),
          ),
        );
      } else if (bullet != null) {
        flushParagraph();
        blocks.add(_Bullet(text: bullet.group(1)!, style: base));
      } else if (figure != null) {
        flushParagraph();
        blocks.add(_FigurePlaceholder(label: figure.group(1)!));
      } else if (image != null) {
        flushParagraph();
        blocks.add(_NoteImage(alt: image.group(1)!, url: image.group(2)!));
      } else {
        paragraph.add(line);
      }
    }
    flushParagraph();
    flushTable();

    if (blocks.length == 1) return blocks.first;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < blocks.length; i++) ...[
          if (i > 0) const SizedBox(height: 6),
          blocks[i],
        ],
      ],
    );
  }
}

class _Bullet extends StatelessWidget {
  const _Bullet({required this.text, required this.style});
  final String text;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    final direction = detectTextDirection(text);
    return Row(
      textDirection: direction,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 10),
          child: Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              color: AppColors.sunDark,
              shape: BoxShape.circle,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(child: MathText(text, style: style, textDirection: direction)),
      ],
    );
  }
}

class _NoteTable extends StatelessWidget {
  const _NoteTable({required this.rows, required this.style});
  final List<String> rows;
  final TextStyle style;

  static List<String> _cells(String row) {
    var r = row.trim();
    if (r.startsWith('|')) r = r.substring(1);
    if (r.endsWith('|')) r = r.substring(0, r.length - 1);
    return r.split('|').map((c) => c.trim()).toList();
  }

  @override
  Widget build(BuildContext context) {
    final parsed = rows.map(_cells).toList();
    final columns = parsed.fold<int>(0, (m, r) => r.length > m ? r.length : m);
    final direction = detectTextDirection(rows.join(' '));
    final cellStyle = style.copyWith(fontSize: (style.fontSize ?? 15) - 1);
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      reverse: direction == TextDirection.rtl,
      child: Table(
        textDirection: direction,
        defaultColumnWidth: const IntrinsicColumnWidth(),
        border: TableBorder.all(
          color: AppColors.sun,
          width: 1.5,
          borderRadius: BorderRadius.circular(10),
        ),
        children: [
          for (var r = 0; r < parsed.length; r++)
            TableRow(
              decoration: BoxDecoration(
                color: r == 0 ? AppColors.sun.withValues(alpha: 0.25) : null,
              ),
              children: [
                for (var c = 0; c < columns; c++)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 220),
                      child: MathText(
                        c < parsed[r].length ? parsed[r][c] : '',
                        style: r == 0
                            ? cellStyle.copyWith(fontWeight: FontWeight.w900)
                            : cellStyle,
                      ),
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}

class _FigurePlaceholder extends StatelessWidget {
  const _FigurePlaceholder({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.snow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.lineDark, width: 1.5),
      ),
      child: Row(
        children: [
          const Icon(Icons.image_outlined, color: AppColors.slate, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: MathText(
              label,
              style: GoogleFonts.vazirmatn(
                fontSize: 13,
                color: AppColors.slate,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NoteImage extends StatelessWidget {
  const _NoteImage({required this.alt, required this.url});
  final String alt;
  final String url;

  @override
  Widget build(BuildContext context) {
    final isRemote = url.startsWith('http') || url.startsWith('/');
    if (!isRemote) return _FigurePlaceholder(label: alt.isEmpty ? url : alt);
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Image.network(
        ApiConfig.resolveMediaUrl(url),
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) =>
            _FigurePlaceholder(label: alt.isEmpty ? url : alt),
      ),
    );
  }
}
