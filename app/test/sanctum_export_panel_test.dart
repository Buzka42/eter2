import 'package:drift/native.dart';
import 'package:eter/core/db/app_database.dart';
import 'package:eter/core/i18n/language.dart';
import 'package:eter/core/i18n/strings.dart';
import 'package:eter/core/theme.dart';
import 'package:eter/features/sanctum/sanctum_overlay.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// The bottom of the Sanctum, which nothing else in the suite draws.
///
/// It sits at the far end of a long scroll, and a `ListView` builds nothing it
/// cannot see — so the Sanctum's own golden captures, which photograph what is
/// on screen, have never laid out a pixel of this panel. Anything that
/// overflows down here overflows in front of a person and nowhere else.
///
/// The same reasoning as `place_suggestions_widget_test.dart`: a surface the
/// suite cannot reach needs a test that reaches it directly.
void main() {
  late AppDatabase database;

  setUp(() => database = AppDatabase(NativeDatabase.memory()));
  tearDown(() => database.close());

  Future<void> pumpPanel(
    WidgetTester tester, {
    required AppLanguage language,
    required bool night,
    double width = 390,
    double height = 844,
    double textScale = 1,
  }) async {
    tester.view.physicalSize = Size(width, height);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MediaQuery(
        data: MediaQueryData(
          size: Size(width, height),
          textScaler: TextScaler.linear(textScale),
        ),
        child: EterStringsScope(
          strings: EterStrings.forLanguage(language),
          child: MaterialApp(
            theme: night ? EterTheme.night() : EterTheme.day(),
            home: Scaffold(
              // A scroll view, as the Sanctum itself gives it. Without one the
              // panel is laid out with unbounded height and cannot overflow,
              // which would make this test prove nothing at all.
              body: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: EterLocalExportPanel(database: database),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  for (final language in AppLanguage.values) {
    final strings = EterStrings.forLanguage(language);
    final lang = language.code;

    testWidgets('$lang · all three offers are on the page', (tester) async {
      await pumpPanel(tester, language: language, night: false);

      // Taking a record out, putting an Eter one back, and reading somebody
      // else's app. Three different promises, three headings.
      expect(find.text(strings.headingLocalExport), findsOneWidget);
      expect(find.text(strings.headingLocalImport), findsOneWidget);
      expect(find.text(strings.headingForeignImport), findsOneWidget);
    });

    testWidgets('$lang · it says which apps, and about the zip', (tester) async {
      await pumpPanel(tester, language: language, night: false);

      // Naming them is the whole of the discoverability. Nobody goes looking
      // for "read a file".
      for (final app in const ['Daylio', 'Bearable', 'Apple Health']) {
        expect(
          find.textContaining(app),
          findsWidgets,
          reason: '$app is not named',
        );
      }
      // Apple Health exports an archive, and a person who picks the zip gets
      // an unreadable-file sentence with no idea why.
      expect(find.textContaining('export.xml'), findsOneWidget);
    });

    testWidgets('$lang · it lays out at 320 dp with text doubled',
        (tester) async {
      // Where translation breaks layouts, and where this panel has never been
      // rendered. An overflow throws during layout, so drawing it is the test.
      await pumpPanel(
        tester,
        language: language,
        night: false,
        width: 320,
        height: 568,
        textScale: 2,
      );
      expect(tester.takeException(), isNull);
      expect(find.text(strings.headingForeignImport), findsOneWidget);
    });

    testWidgets('$lang · and at night, where the ink changes', (tester) async {
      await pumpPanel(
        tester,
        language: language,
        night: true,
        width: 320,
        height: 568,
        textScale: 2,
      );
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('every control on it clears the 48 dp tap floor', (tester) async {
    await pumpPanel(tester, language: AppLanguage.english, night: false);
    for (final element in find.byType(InkWell).evaluate()) {
      final size = tester.getSize(find.byWidget(element.widget));
      expect(
        size.height,
        greaterThanOrEqualTo(48),
        reason: 'a control is ${size.height} dp tall',
      );
    }
  });
}
