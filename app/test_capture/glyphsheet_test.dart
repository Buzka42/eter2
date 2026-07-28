import 'dart:io';

import 'package:eter/core/symbolic/astro_glyphs.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// A specimen of the whole astrological set, which is how the hand-drawn
/// version's wrong glyphs were caught. Kept so the font can be checked the
/// same way after any regeneration.
void main() {
  setUpAll(() async {
    final loader = FontLoader(AstroGlyph.fontFamily)
      ..addFont(Future.value(
        ByteData.view(
          File('assets/fonts/EterAstro.ttf').readAsBytesSync().buffer,
        ),
      ));
    await loader.load();
  });

  testWidgets('glyph sheet', (tester) async {
    tester.view.physicalSize = const Size(620, 300);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        // Inside a Material: text rendered outside one is debug-underlined
        // in yellow by Flutter itself, which is a harness artefact rather
        // than anything the app does.
        home: Material(
          color: const Color(0xFFFAF5EA),
          child: Center(
            child: Wrap(
              spacing: 22,
              runSpacing: 18,
              alignment: WrapAlignment.center,
              children: [
                for (final glyph in AstroGlyph.values)
                  AstroGlyphMark(
                    glyph: glyph,
                    color: const Color(0xFF1C2B3A),
                    size: 40,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('../../artifacts/ui/glyph-sheet.png'),
    );
  });
}
