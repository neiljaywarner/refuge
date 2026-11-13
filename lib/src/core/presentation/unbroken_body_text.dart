import 'package:flutter/material.dart';

/// Characters a URL may wrap after. A break here keeps `web.app` from painting
/// as `we` / `b.app` when system text is large (#932).
const String _urlBreakAfter = './?&=_%-:#@';

final RegExp _urlPattern = RegExp(
  r'(?:https?:\/\/|www\.)\S+|\b(?:[A-Za-z0-9-]+\.)+[A-Za-z]{2,}(?:\/\S*)?',
  caseSensitive: false,
);

/// Inserts zero-width breaks after URL punctuation so a link wraps at `.` and
/// `/` instead of inside a word.
String insertUrlSoftBreaks(String text) => text.replaceAllMapped(_urlPattern, (match) {
  final url = match.group(0)!;
  final buffer = StringBuffer();
  for (var i = 0; i < url.length; i++) {
    final char = url[i];
    buffer.write(char);
    if (i < url.length - 1 && _urlBreakAfter.contains(char)) {
      buffer.write('\u200B');
    }
  }
  return buffer.toString();
});

/// [text] with URL soft breaks. A token wider than [maxWidth] keeps every
/// character and may wrap after a grapheme, so a space-free paragraph or a
/// long URL segment is not replaced by an ellipsis.
String fitUnbrokenText(
  String text, {
  required double maxWidth,
  required TextStyle style,
  required TextScaler textScaler,
  required TextDirection textDirection,
}) {
  if (!maxWidth.isFinite || maxWidth <= 0) return text;
  final broken = insertUrlSoftBreaks(text);
  final painter = TextPainter(textDirection: textDirection, textScaler: textScaler, maxLines: 1);
  final segments = broken.split('\u200B');
  final buffer = StringBuffer();
  for (var i = 0; i < segments.length; i++) {
    buffer.write(_fitWideWords(segments[i], painter: painter, style: style, maxWidth: maxWidth));
    if (i != segments.length - 1) buffer.write('\u200B');
  }
  painter.dispose();
  return buffer.toString();
}

String _fitWideWords(
  String segment, {
  required TextPainter painter,
  required TextStyle style,
  required double maxWidth,
}) {
  // split() drops the separators, even with a capturing group, so walk both
  // the words and the spaces they sit between.
  final buffer = StringBuffer();
  for (final match in RegExp(r'\s+|\S+').allMatches(segment)) {
    final part = match.group(0)!;
    if (RegExp(r'^\s').hasMatch(part)) {
      buffer.write(part);
      continue;
    }
    buffer.write(_fitToken(part, painter: painter, style: style, maxWidth: maxWidth));
  }
  return buffer.toString();
}

/// Keeps [token] when it fits. Otherwise inserts a wrap opportunity after each
/// grapheme so a surrogate pair or joined emoji is never sliced in half.
String _fitToken(
  String token, {
  required TextPainter painter,
  required TextStyle style,
  required double maxWidth,
}) {
  painter.text = TextSpan(text: token, style: style);
  painter.layout();
  if (painter.width <= maxWidth) return token;
  final graphemes = token.characters;
  if (graphemes.length <= 1) return token;
  return graphemes.join('\u200B');
}

/// Body copy that wraps on spaces and URL punctuation.
///
/// A token with no punctuation still wraps, and every character stays visible.
/// Screen readers hear [text]. The painted string may contain zero-width
/// breaks so `web.app` stays intact on each side of the dot (#932).
class UnbrokenBodyText extends StatelessWidget {
  const UnbrokenBodyText({
    super.key,
    required this.text,
    this.style,
    this.maxLines,
    this.overflow,
    this.textAlign,
  });

  final String text;
  final TextStyle? style;
  final int? maxLines;
  final TextOverflow? overflow;
  final TextAlign? textAlign;

  @override
  Widget build(BuildContext context) {
    final resolved = _resolvedBodyStyle(context, style);
    return LayoutBuilder(
      builder: (context, constraints) {
        final display = fitUnbrokenText(
          text,
          maxWidth: constraints.maxWidth,
          style: resolved,
          textScaler: MediaQuery.textScalerOf(context),
          textDirection: Directionality.of(context),
        );
        return Text(
          display,
          style: resolved,
          maxLines: maxLines,
          overflow: overflow,
          textAlign: textAlign,
          semanticsLabel: text,
        );
      },
    );
  }
}

/// The style [Text] paints: inherited [DefaultTextStyle], accessibility bold,
/// and any text-spacing overrides. Measurement uses this same value.
TextStyle _resolvedBodyStyle(BuildContext context, TextStyle? style) {
  final defaults = DefaultTextStyle.of(context).style;
  var resolved = style == null || style.inherit ? defaults.merge(style) : style;
  if (MediaQuery.boldTextOf(context)) {
    resolved = resolved.merge(const TextStyle(fontWeight: FontWeight.bold));
  }
  final lineHeight = MediaQuery.maybeLineHeightScaleFactorOverrideOf(context);
  final letterSpacing = MediaQuery.maybeLetterSpacingOverrideOf(context);
  final wordSpacing = MediaQuery.maybeWordSpacingOverrideOf(context);
  if (lineHeight == null && letterSpacing == null && wordSpacing == null) return resolved;
  return resolved.merge(
    TextStyle(height: lineHeight, letterSpacing: letterSpacing, wordSpacing: wordSpacing),
  );
}
