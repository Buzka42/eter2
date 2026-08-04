/// Setting large type so that no word is broken in half.
///
/// Flutter does not hyphenate. When a single word is wider than the line it is
/// given, the engine breaks it wherever it runs out of room — with no hyphen,
/// no warning, and no overflow error, because nothing has overflowed. The
/// result reads as a typographic fault rather than a wrap:
///
/// > tętno spocz
/// > ynkowe
///
/// That is a real screenshot of guidance on a 1080 px phone, taken the first
/// day the passage was set at 68 pt. It cannot be caught by a golden unless the
/// golden happens to contain a long enough word, and the word that did it came
/// from the model rather than from any fixture: `spoczynkowe` is ordinary
/// Polish, and Polish is full of words that length.
///
/// So the size is chosen against the **longest word**, not the paragraph: the
/// passage is set as large as it was asked to be, except where that would break
/// a word, and then only as far down as it takes to fit the word whole.
library;

import 'package:flutter/widgets.dart';

/// The largest font size at or below `style.fontSize` at which every word of
/// [text] fits inside [maxWidth] unbroken.
///
/// [minimumFontSize] is the floor: below it the passage stops being the
/// display type the design asked for, and a single absurd word — a URL, a
/// chemical name — should be allowed to break rather than shrink the whole
/// passage into fine print.
double eterUnbrokenFontSize({
  required String text,
  required TextStyle style,
  required double maxWidth,
  required TextScaler textScaler,
  double minimumFontSize = 28,
}) {
  final base = style.fontSize ?? 16;
  if (maxWidth <= 0 || text.trim().isEmpty) return base;

  // The widest word, measured rather than guessed at from its length: at these
  // sizes a wide short word beats a narrow long one often enough to matter.
  var widest = 0.0;
  for (final word in text.split(RegExp(r'\s+'))) {
    if (word.isEmpty) continue;
    final painter = TextPainter(
      text: TextSpan(text: word, style: style),
      textDirection: TextDirection.ltr,
      textScaler: textScaler,
    )..layout();
    if (painter.width > widest) widest = painter.width;
    painter.dispose();
  }
  if (widest <= maxWidth) return base;

  // Text width is very nearly linear in font size, so one ratio lands within a
  // fraction of a point. The floor is applied last: a passage is never set
  // smaller than the design allows, even if that means one monstrous word
  // still breaks.
  //
  // A logical pixel is held back. Fitting a word to *exactly* the line width
  // is not fitting it: the engine lays out in its own rounding, and a word
  // whose measured width equals the line breaks anyway — which is precisely
  // what the first attempt at this did, on the golden that had a long word in
  // it and on the phone alike.
  final usable = maxWidth - 1;
  if (usable <= 0) return base;
  final fitted = base * (usable / widest);
  return fitted < minimumFontSize ? minimumFontSize : fitted;
}

/// [style] resized so no word of [text] is broken.
///
/// The line height travels with it. The themes store `height` as a *ratio*, so
/// a style whose size is reduced keeps its leading proportional without
/// anything further being said — which is the same reason doubling the size
/// alone would have set the passage solid.
TextStyle eterFitStyleToWords({
  required String text,
  required TextStyle style,
  required double maxWidth,
  required TextScaler textScaler,
  double minimumFontSize = 28,
}) {
  final size = eterUnbrokenFontSize(
    text: text,
    style: style,
    maxWidth: maxWidth,
    textScaler: textScaler,
    minimumFontSize: minimumFontSize,
  );
  return size == style.fontSize ? style : style.copyWith(fontSize: size);
}
