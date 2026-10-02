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

    final spans = <InlineSpan>[];
    var last = 0;
    for (final match in _tokenPattern.allMatches(text)) {
      if (match.start > last) {
        spans.add(TextSpan(text: text.substring(last, match.start)));
      }
      final display = match.group(1);
      final inline = match.group(2);
      final bold = match.group(3);
      final code = match.group(4);
      if (display != null) {
        spans
          ..add(const TextSpan(text: '\n'))
          ..add(_mathSpan(display, base, display: true))
          ..add(const TextSpan(text: '\n'));
      } else if (inline != null) {
        spans.add(_mathSpan(inline, base, display: false));
      } else if (bold != null) {
        spans.add(
          TextSpan(
            text: bold,
            style: const TextStyle(fontWeight: FontWeight.w900),
          ),
        );
      } else if (code != null) {
        spans.add(
          TextSpan(
            text: code,
            style: AppTheme.latin(
              fontSize: (base.fontSize ?? 16) * 0.95,
              color: AppColors.grape,
            ),
          ),
        );
      }
      last = match.end;
    }
    if (last < text.length) spans.add(TextSpan(text: text.substring(last)));

    return Text.rich(
      TextSpan(style: base, children: spans),
      textAlign: align,
      textDirection: direction,
    );
  }

  InlineSpan _mathSpan(String tex, TextStyle base, {required bool display}) {
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
    return WidgetSpan(
      alignment: PlaceholderAlignment.middle,
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: display
            ? SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: math,
                ),
              )
            : math,
      ),
    );
  }
}
