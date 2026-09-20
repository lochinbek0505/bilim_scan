import 'package:flutter/material.dart';

/// A widget that renders formatted text with math support, including:
/// - Superscripts (x², x^2, x^{2})
/// - Subscripts (H₂O, x_1, x_{1})
/// - Fractions (a/b, \frac{a}{b})
/// - Square roots (√x, \sqrt{x})
/// - Unicode math symbols & Greek letters (±, ≠, ≤, ≥, α, β, π, ∑, ∫, ∞)
class FormattedMathText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;

  const FormattedMathText({
    super.key,
    required this.text,
    this.style,
    this.textAlign,
    this.maxLines,
    this.overflow,
  });

  @override
  Widget build(BuildContext context) {
    if (text.isEmpty) return const SizedBox.shrink();

    final defaultStyle = style ?? Theme.of(context).textTheme.bodyMedium ?? const TextStyle();
    final spans = _parseFormattedSpans(text, defaultStyle);

    return RichText(
      textAlign: textAlign ?? TextAlign.start,
      maxLines: maxLines,
      overflow: overflow ?? TextOverflow.clip,
      text: TextSpan(children: spans),
    );
  }

  List<InlineSpan> _parseFormattedSpans(String rawText, TextStyle baseStyle) {
    String cleaned = _unescapeXml(rawText);

    final List<InlineSpan> spans = [];
    int pos = 0;

    final regExp = RegExp(
      r'(\\frac\{([^}]+)\}\{([^}]+)\})|(\\sqrt\{([^}]+)\})|(\^\{([^}]+)\})|(\_\{([^}]+)\})|(\^([0-9a-zA-A\+\-]+))|(\_([0-9a-zA-A\+\-]+))',
    );

    final matches = regExp.allMatches(cleaned);

    for (final m in matches) {
      if (m.start > pos) {
        final textBefore = cleaned.substring(pos, m.start);
        spans.add(TextSpan(text: textBefore, style: baseStyle));
      }

      if (m.group(1) != null) {
        // \frac{a}{b}
        final num = m.group(2) ?? '';
        final den = m.group(3) ?? '';
        spans.add(TextSpan(
          text: '($num/$den)',
          style: baseStyle.copyWith(fontWeight: FontWeight.w600),
        ));
      } else if (m.group(4) != null) {
        // \sqrt{x}
        final body = m.group(5) ?? '';
        spans.add(TextSpan(
          text: '√($body)',
          style: baseStyle.copyWith(fontWeight: FontWeight.w600),
        ));
      } else if (m.group(6) != null) {
        // ^{exp}
        final exp = m.group(7) ?? '';
        spans.add(WidgetSpan(
          alignment: PlaceholderAlignment.top,
          child: Transform.translate(
            offset: const Offset(0, -4),
            child: Text(
              _toSuperscript(exp),
              style: baseStyle.copyWith(fontSize: (baseStyle.fontSize ?? 14) * 0.75),
            ),
          ),
        ));
      } else if (m.group(8) != null) {
        // _{sub}
        final sub = m.group(9) ?? '';
        spans.add(WidgetSpan(
          alignment: PlaceholderAlignment.bottom,
          child: Transform.translate(
            offset: const Offset(0, 2),
            child: Text(
              _toSubscript(sub),
              style: baseStyle.copyWith(fontSize: (baseStyle.fontSize ?? 14) * 0.75),
            ),
          ),
        ));
      } else if (m.group(10) != null) {
        // ^x
        final exp = m.group(11) ?? '';
        spans.add(WidgetSpan(
          alignment: PlaceholderAlignment.top,
          child: Transform.translate(
            offset: const Offset(0, -4),
            child: Text(
              _toSuperscript(exp),
              style: baseStyle.copyWith(fontSize: (baseStyle.fontSize ?? 14) * 0.75),
            ),
          ),
        ));
      } else if (m.group(12) != null) {
        // _x
        final sub = m.group(13) ?? '';
        spans.add(WidgetSpan(
          alignment: PlaceholderAlignment.bottom,
          child: Transform.translate(
            offset: const Offset(0, 2),
            child: Text(
              _toSubscript(sub),
              style: baseStyle.copyWith(fontSize: (baseStyle.fontSize ?? 14) * 0.75),
            ),
          ),
        ));
      }

      pos = m.end;
    }

    if (pos < cleaned.length) {
      final remaining = cleaned.substring(pos);
      spans.add(TextSpan(text: remaining, style: baseStyle));
    }

    if (spans.isEmpty) {
      spans.add(TextSpan(text: cleaned, style: baseStyle));
    }

    return spans;
  }

  static String _unescapeXml(String input) {
    return input
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&apos;', "'")
        .replaceAll('&amp;', '&')
        .replaceAll('&#178;', '²')
        .replaceAll('&#179;', '³')
        .replaceAll('&#185;', '¹');
  }

  static String _toSuperscript(String str) {
    const normal = '0123456789+-=()nixyabcdekmpt';
    const superChars = '⁰¹²³⁴⁵⁶⁷⁸⁹⁺⁻⁼⁽⁾ⁿⁱˣʸªᵇᶜᵈᵉᵏᵐᵖᵗ';
    final sb = StringBuffer();
    for (int i = 0; i < str.length; i++) {
      final char = str[i];
      final idx = normal.indexOf(char);
      if (idx != -1) {
        sb.write(superChars[idx]);
      } else {
        sb.write(char);
      }
    }
    return sb.toString();
  }

  static String _toSubscript(String str) {
    const normal = '0123456789+-=()aeoxhklmnpst';
    const subChars = '₀₁₂₃₄₅₆₇₈₉₊₋₌₍₎ₐₑₒₓₕₖₗₘₙₚₛₜ';
    final sb = StringBuffer();
    for (int i = 0; i < str.length; i++) {
      final char = str[i];
      final idx = normal.indexOf(char);
      if (idx != -1) {
        sb.write(subChars[idx]);
      } else {
        sb.write(char);
      }
    }
    return sb.toString();
  }
}
