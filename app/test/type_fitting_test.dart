import 'package:eter/core/type_fitting.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/prototype_harness.dart';

/// Setting large type so no word is broken in half.
///
/// Flutter does not hyphenate. A word wider than its line is broken wherever
/// the engine runs out of room — no hyphen, no overflow error, because nothing
/// has overflowed. Guidance at 68 pt on a real phone read "tętno spocz /
/// ynkowe", and no golden could have caught it: the word came from the model
/// rather than from a fixture.
void main() {
  setUpAll(loadEterFonts);

  const style = TextStyle(fontFamily: 'Cormorant Garamond', fontSize: 68);
  const scaler = TextScaler.noScaling;

  double fit(String text, double width) => eterUnbrokenFontSize(
        text: text,
        style: style,
        maxWidth: width,
        textScaler: scaler,
      );

  test('a passage that already fits is left at the size it was asked for', () {
    // The owner asked for twice the size. Nothing here may quietly undo that.
    expect(fit('Ruch zwolnił.', 1000), 68);
  });

  test('a word wider than the line brings the size down until it fits', () {
    final size = fit('tętno spoczynkowe', 300);
    expect(size, lessThan(68));

    // And down to *fit*, not further: at the returned size the longest word
    // must actually be inside the line.
    final painter = TextPainter(
      text: TextSpan(
        text: 'spoczynkowe',
        style: style.copyWith(fontSize: size),
      ),
      textDirection: TextDirection.ltr,
      textScaler: scaler,
    )..layout();
    expect(painter.width, lessThanOrEqualTo(300 + 0.5));
    painter.dispose();
  });

  test('the shortening is driven by the longest word, not the paragraph', () {
    // A long paragraph of short words is not a reason to shrink anything; the
    // passage scrolls. Only a word that cannot be set whole is.
    final many = List.filled(80, 'ruch').join(' ');
    expect(fit(many, 300), 68);
  });

  test('width is measured, not counted in letters', () {
    // At display sizes a wide short word beats a narrow long one often enough
    // to matter, so the widest word is found by laying it out.
    final wide = fit('WWWWWW', 300);
    final narrow = fit('iiiiiiiiiiii', 300);
    expect(wide, lessThan(narrow));
  });

  test('a floor stops one absurd word turning the passage into fine print',
      () {
    // A URL, a chemical name. Better that one word breaks than that the
    // display type the design asked for becomes body copy.
    expect(fit('a' * 200, 300), 28);
  });

  test('text scaling is taken into account, because the reader sets it', () {
    final plain = eterUnbrokenFontSize(
      text: 'spoczynkowe',
      style: style,
      maxWidth: 300,
      textScaler: scaler,
    );
    final doubled = eterUnbrokenFontSize(
      text: 'spoczynkowe',
      style: style,
      maxWidth: 300,
      textScaler: const TextScaler.linear(2),
    );
    expect(doubled, lessThan(plain));
  });

  test('the style keeps its identity, and its leading follows the size', () {
    final fitted = eterFitStyleToWords(
      text: 'tętno spoczynkowe',
      style: style.copyWith(height: 1.1),
      maxWidth: 300,
      textScaler: scaler,
    );
    expect(fitted.fontSize, lessThan(68));
    // `height` is a ratio in these themes, so leading scales with the size on
    // its own — the same reason doubling the size alone would have set the
    // passage solid.
    expect(fitted.height, 1.1);
    expect(fitted.fontFamily, 'Cormorant Garamond');
  });

  test('an empty passage and a zero width are not arithmetic errors', () {
    expect(fit('', 300), 68);
    expect(fit('spoczynkowe', 0), 68);
  });
}
