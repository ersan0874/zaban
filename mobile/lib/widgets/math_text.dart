import 'package:flutter/material.dart';
import 'package:flutter_math_fork/flutter_math.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:zaban/theme/app_theme.dart';

/// Matches display math `$$..$$`, inline math `$..$`, `**bold**` and `code`.
final _tokenPattern = RegExp(
  r'\$\$([\s\S]+?)\$\$|(?<!\\)\$([^$\n]+?)\$|\*\*([^*\n]+?)\*\*|`([^`\n]+?)`',
);

final _rtlChar = RegExp(r'[֐-ࣿיִ-﷿ﹰ-﻿]');
final _ltrChar = RegExp(r'[A-Za-z]');

/// Direction of the first strong character (Persian/Arabic → RTL).
TextDirection detectTextDirection(String text) {
  final plain = text.replaceAll(_tokenPattern, ' ');
  final rtl = _rtlChar.firstMatch(plain)?.start;
  final ltr = _ltrChar.firstMatch(plain)?.start;
  if (rtl == null) return ltr == null ? TextDirection.rtl : TextDirection.ltr;
  if (ltr == null) return TextDirection.rtl;
  return rtl < ltr ? TextDirection.rtl : TextDirection.ltr;
}

/// Learner-facing text from AI content: renders LaTeX (`$x^2$`, `$$..$$`)
/// and light Markdown (`**bold**`, `` `code` ``). Plain text stays a [Text].
class MathText extends StatelessWidget {
  const MathText(
    this.text, {
    super.key,
    this.style,
    this.textAlign,
    this.textDirection,
  });

  final String text;
  final TextStyle? style;
  final TextAlign? textAlign;

  /// Defaults to the direction of the first strong character.
  final TextDirection? textDirection;

  @override
  Widget build(BuildContext context) {
    final direction = textDirection ?? detectTextDirection(text);
    final base = style ?? GoogleFonts.vazirmatn(fontSize: 16);
    final align = textAlign ??
        (direction == TextDirection.rtl ? TextAlign.right : TextAlign.left);

    if (!_tokenPattern.hasMatch(text)) {
      return Text(
        text,
        style: base,
        textAlign: align,
        textDirection: direction,
      );
    }

    final hasMath = _tokenPattern
        .allMatches(text)
        .any((m) => m.group(1) != null || m.group(2) != null);
    if (hasMath) return _buildWithMath(base, direction, align);

    // Only bold/code: plain rich text is enough.
    final spans = <InlineSpan>[];
    var last = 0;
    for (final match in _tokenPattern.allMatches(text)) {
      if (match.start > last) {
        spans.add(TextSpan(text: text.substring(last, match.start)));
      }
      spans.add(_styledSpan(match.group(3), match.group(4), base));
      last = match.end;
    }
    if (last < text.length) spans.add(TextSpan(text: text.substring(last)));

    return Text.rich(
      TextSpan(style: base, children: spans),
      textAlign: align,
      textDirection: direction,
    );
  }

  TextSpan _styledSpan(String? bold, String? code, TextStyle base) {
    if (bold != null) {
      return TextSpan(
        text: bold,
        style: const TextStyle(fontWeight: FontWeight.w900),
      );
    }
    return TextSpan(
      text: code,
      style: AppTheme.latin(
        fontSize: (base.fontSize ?? 16) * 0.95,
        color: AppColors.grape,
      ),
    );
  }

  /// Formulas are laid out word by word in a [Wrap]: WidgetSpans inside
  /// right-to-left paragraphs come out in the wrong order.
  Widget _buildWithMath(
    TextStyle base,
    TextDirection direction,
    TextAlign align,
  ) {
    final space = (base.fontSize ?? 16) * 0.28;
    final items = <Widget>[];

    void addWords(String chunk, {TextStyle? extra}) {
      final parts = chunk.split(RegExp(r'(?<=\s)|(?=\s)'));
      for (final part in parts) {
        if (part.trim().isEmpty) {
          if (part.contains('\n') && items.isNotEmpty) {
            items.add(const SizedBox(width: double.infinity));
          } else if (items.isNotEmpty) {
            items.add(SizedBox(width: space));
          }
          continue;
        }
        items.add(
          Text(
            part,
            style: extra == null ? base : base.merge(extra),
            textDirection: detectTextDirection(part) == TextDirection.ltr &&
                    direction == TextDirection.rtl
                ? TextDirection.ltr
                : direction,
          ),
        );
      }
    }

    var last = 0;
    for (final match in _tokenPattern.allMatches(text)) {
      if (match.start > last) addWords(text.substring(last, match.start));
      final display = match.group(1);
      final inline = match.group(2);
      if (display != null) {
        items.add(_math(display, base, display: true));
      } else if (inline != null) {
        items.add(_math(inline, base, display: false));
      } else {
        final styled = _styledSpan(match.group(3), match.group(4), base);
        addWords(styled.text ?? '', extra: styled.style);
      }
      last = match.end;
    }
    if (last < text.length) addWords(text.substring(last));

    final WrapAlignment alignment;
    switch (align) {
      case TextAlign.center:
        alignment = WrapAlignment.center;
      case TextAlign.left:
        alignment = direction == TextDirection.rtl
            ? WrapAlignment.end
            : WrapAlignment.start;
      case TextAlign.right:
        alignment = direction == TextDirection.rtl
            ? WrapAlignment.start
            : WrapAlignment.end;
      default:
        alignment = WrapAlignment.start;
    }
    return Wrap(
      textDirection: direction,
      alignment: alignment,
      crossAxisAlignment: WrapCrossAlignment.center,
      runSpacing: 4,
      children: items,
    );
  }

  Widget _math(String tex, TextStyle base, {required bool display}) {
    final math = Math.tex(
      tex.trim(),
      mathStyle: display ? MathStyle.display : MathStyle.text,
      textStyle: TextStyle(fontSize: base.fontSize, color: base.color),
      onErrorFallback: (_) => Text(
        display ? '\$\$$tex\$\$' : '\$$tex\$',
        style: base,
        textDirection: TextDirection.ltr,
      ),
    );
    final ltr = Directionality(textDirection: TextDirection.ltr, child: math);
    if (!display) return ltr;
    // A display formula takes its own centered line.
    return SizedBox(
      width: double.infinity,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Center(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ltr,
          ),
        ),
      ),
    );
  }
}
