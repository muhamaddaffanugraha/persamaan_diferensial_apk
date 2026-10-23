import 'package:flutter/material.dart';
import 'package:flutter_math_fork/flutter_math.dart';

/// Widget untuk menampilkan satu rumus matematika LaTeX secara rapi (Block Math)
class MathBlock extends StatelessWidget {
  final String tex;
  final TextStyle? textStyle;
  final Alignment alignment;

  const MathBlock({
    super.key,
    required this.tex,
    this.textStyle,
    this.alignment = Alignment.centerLeft,
  });

  @override
  Widget build(BuildContext context) {
    if (tex.trim().isEmpty) return const SizedBox.shrink();

    // Bersihkan pembungkus $ atau $$ jika ada
    String cleanTex = tex.trim();
    if (cleanTex.startsWith(r'$$') && cleanTex.endsWith(r'$$') && cleanTex.length >= 4) {
      cleanTex = cleanTex.substring(2, cleanTex.length - 2).trim();
    } else if (cleanTex.startsWith(r'$') && cleanTex.endsWith(r'$') && cleanTex.length >= 2) {
      cleanTex = cleanTex.substring(1, cleanTex.length - 1).trim();
    }

    return Align(
      alignment: alignment,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: Math.tex(
          cleanTex,
          textStyle: textStyle ??
              const TextStyle(
                fontSize: 16,
                color: Color(0xFF1E293B),
              ),
          mathStyle: MathStyle.display,
          onErrorFallback: (err) {
            return Text(
              tex,
              style: textStyle ??
                  const TextStyle(
                    fontSize: 15,
                    fontFamily: 'monospace',
                    color: Color(0xFF1E293B),
                  ),
            );
          },
        ),
      ),
    );
  }
}

/// Widget untuk menampilkan paragraf teks biasa yang diselingi rumus inline $...$
class MixedMathText extends StatelessWidget {
  final String text;
  final TextStyle? style;

  const MixedMathText({
    super.key,
    required this.text,
    this.style,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveStyle = style ??
        Theme.of(context).textTheme.bodyMedium ??
        const TextStyle(fontSize: 14, color: Color(0xFF334155), height: 1.5);

    // Deteksi segmen yang diapit tanda $ (misal: "maka $y = e^x$ adalah...")
    final regex = RegExp(r'\$([^\$]+?)\$');
    final spans = <InlineSpan>[];

    int lastIndex = 0;
    for (final match in regex.allMatches(text)) {
      if (match.start > lastIndex) {
        spans.add(TextSpan(
          text: text.substring(lastIndex, match.start),
          style: effectiveStyle,
        ));
      }

      final mathContent = match.group(1)?.trim() ?? '';
      spans.add(WidgetSpan(
        alignment: PlaceholderAlignment.middle,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2.0),
          child: Math.tex(
            mathContent,
            textStyle: effectiveStyle.copyWith(
              fontSize: (effectiveStyle.fontSize ?? 14) * 1.05,
              fontWeight: FontWeight.w500,
            ),
            mathStyle: MathStyle.text,
            onErrorFallback: (err) => Text('\$$mathContent\$', style: effectiveStyle),
          ),
        ),
      ));

      lastIndex = match.end;
    }

    if (lastIndex < text.length) {
      spans.add(TextSpan(
        text: text.substring(lastIndex),
        style: effectiveStyle,
      ));
    }

    return Text.rich(
      TextSpan(children: spans),
      style: effectiveStyle,
    );
  }
}
