import 'package:flutter/material.dart';

/// The real symbols, from a real type designer.
///
/// These were hand-drawn as paths first, and the specimen sheet kept catching
/// glyphs that were subtly or badly wrong — Aries curling the wrong way,
/// Gemini as a capsule, Capricorn with no tail. Redrawing from memory is not a
/// process that converges: every fix is another guess.
///
/// They now come from `EterAstro.ttf`, a 5.5 KB subset of two Noto faces
/// carrying exactly the 22 codepoints below, merged and bundled under the SIL
/// Open Font License (see `assets/fonts/EterAstro.LICENSE.txt`, and
/// `tool/build_astro_font.py` to regenerate). Correct by construction rather
/// than by iteration.
///
/// The face is used for **symbols only and never for text**. Cormorant
/// Garamond and Inter remain the app's two voices; this one has no opinions
/// about prose, and appears in exactly two places: the chart wheel and the
/// Vessel's position lines.
enum AstroGlyph {
  sun('☉', 'Sun'),
  moon('☽', 'Moon'),
  mercury('☿', 'Mercury'),
  venus('♀', 'Venus'),
  mars('♂', 'Mars'),
  jupiter('♃', 'Jupiter'),
  saturn('♄', 'Saturn'),
  uranus('♅', 'Uranus'),
  neptune('♆', 'Neptune'),
  pluto('♇', 'Pluto'),
  aries('♈', 'Aries'),
  taurus('♉', 'Taurus'),
  gemini('♊', 'Gemini'),
  cancer('♋', 'Cancer'),
  leo('♌', 'Leo'),
  virgo('♍', 'Virgo'),
  libra('♎', 'Libra'),
  scorpio('♏', 'Scorpio'),
  sagittarius('♐', 'Sagittarius'),
  capricorn('♑', 'Capricorn'),
  aquarius('♒', 'Aquarius'),
  pisces('♓', 'Pisces');

  const AstroGlyph(this.character, this.label);

  /// The codepoint carried by `EterAstro.ttf`.
  final String character;

  /// Spoken form, for the semantics of anything that draws one.
  final String label;

  static const fontFamily = 'EterAstro';

  /// The signs in zodiacal order, so a ring can be walked without a lookup.
  static const signs = <AstroGlyph>[
    aries, taurus, gemini, cancer, leo, virgo,
    libra, scorpio, sagittarius, capricorn, aquarius, pisces,
  ];

  /// The catalogue's own body names, so callers need no second table.
  ///
  /// The Ascendant and Midheaven are deliberately absent: they are angles
  /// rather than bodies, and Unicode has no glyph for either. The chart names
  /// them in letters, which is what printed charts do.
  static AstroGlyph? forBody(String name) => switch (name) {
        'Sun' => sun,
        'Moon' => moon,
        'Mercury' => mercury,
        'Venus' => venus,
        'Mars' => mars,
        'Jupiter' => jupiter,
        'Saturn' => saturn,
        'Uranus' => uranus,
        'Neptune' => neptune,
        'Pluto' => pluto,
        _ => null,
      };

  static AstroGlyph? forSign(String label) {
    for (final glyph in signs) {
      if (glyph.label == label) return glyph;
    }
    return null;
  }
}

/// Draws one glyph at the size and colour the surface asks for.
class AstroGlyphMark extends StatelessWidget {
  const AstroGlyphMark({
    super.key,
    required this.glyph,
    required this.color,
    this.size = 14,
    this.semanticLabel,
  });

  final AstroGlyph glyph;
  final Color color;
  final double size;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    // Never scaled by the reader's text setting: these sit inside drawn
    // geometry that does not scale with type, and a glyph that grew would
    // collide with the ring it sits on.
    final mark = MediaQuery.withNoTextScaling(
      child: Text(
        glyph.character,
        style: TextStyle(
          fontFamily: AstroGlyph.fontFamily,
          fontSize: size,
          // No forced line height: the face's own metrics leave room for the
          // parts of a glyph that fall below the baseline, and clamping them
          // to the em box clips Capricorn's tail.
          color: color,
        ),
      ),
    );
    if (semanticLabel == null) return ExcludeSemantics(child: mark);
    return Semantics(
      label: semanticLabel,
      excludeSemantics: true,
      child: mark,
    );
  }
}
