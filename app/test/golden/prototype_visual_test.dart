import 'package:eter/core/db/app_database.dart';
import 'package:eter/core/controls.dart';
import 'package:eter/core/i18n/language.dart';
import 'package:eter/core/i18n/strings.dart';
import 'package:eter/core/instruments.dart';
import 'package:eter/core/register.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/prototype_harness.dart';

/// Every capture, in every language.
///
/// The whole suite is wrapped in a loop over [AppLanguage] rather than pinned to
/// English with a couple of Polish spot-checks. Translation does not break
/// layouts in the places you would guess: it breaks them where a word happens to
/// be a third longer than the one the spacing was tuned against, and that is a
/// different word on every surface. `ZAJRZYJ GŁĘBIEJ` is wider than
/// `LOOK DEEPER`, `SANKTUARIUM` is wider than `SANCTUM`, and Polish
/// diacritics sit above the cap height, which changes line boxes. The only way
/// to know is to render all of it, at 320 dp, at 200% text, in both registers.
///
/// Nothing in here reaches for an English string. Every label the test taps
/// comes out of the same table the widget drew it from, so a capture cannot
/// silently start testing the fallback.
void main() {
  late AppDatabase db;

  setUpAll(loadEterFonts);
  setUp(() async => db = await eterTestDatabase());

  Future<void> pumpPrototype(
    WidgetTester tester, {
    required EterRegister register,
    required AppLanguage language,
    double width = 390,
    double height = 844,
    double textScale = 1,
    bool reduceMotion = true,
    Duration arrivalTime = const Duration(seconds: 4),
  }) async {
    eterSurfaceSize(tester, width, height);
    await tester.pumpWidget(
      eterPrototypeApp(
        db: db,
        register: register,
        language: language,
        textScale: textScale,
        reduceMotion: reduceMotion,
      ),
    );
    await tester.pump();
    // Asset decoding runs on the real async queue; give the first frame a
    // brief warm-up before advancing product animations in FakeAsync.
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 400)),
    );
    await tester.pump();
    await tester.pump(arrivalTime);
  }

  Future<void> disposePrototype(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
  }

  /// Opens one of the three sections behind the Dashboard's threshold.
  ///
  /// Both taps scroll their target into view first. At 320 dp with text doubled
  /// the three choices wrap past the bottom of the viewport, and a `tap()` on an
  /// off-screen widget does not reach it — it warns and hits whatever is at
  /// those coordinates instead. The Vessel capture at that size was silently
  /// photographing the un-expanded Dashboard because of exactly this.
  Future<void> openSection(
    WidgetTester tester,
    EterStrings strings,
    String section,
  ) async {
    await tester.ensureVisible(find.text(strings.lookDeeper));
    await tester.pump();
    await tester.tap(find.text(strings.lookDeeper));
    await tester.pump();
    // `.last`, not the bare finder. In Polish the destination rail and the
    // guidance section are both `WGLĄD` by design, so a plain `find.text` matches
    // two widgets and throws "Too many elements". The section thresholds are
    // below the rail, so the last match is the one this opens.
    final target = find.text(section).last;
    await tester.ensureVisible(target);
    await tester.pump();
    await tester.tap(target);
    await tester.pump();
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 120)),
    );
  }

  Finder downwardScrollable() => find
      .byWidgetPredicate(
        (widget) =>
            widget is Scrollable && widget.axisDirection == AxisDirection.down,
      )
      .hitTestable();

  /// A page written in the language being captured, so the Journal's prose is
  /// set in the face and diacritics it will actually carry. Fixture text, so it
  /// lives here rather than in `EterStrings`.
  const journalEntry = <AppLanguage, String>{
    AppLanguage.english:
        'I slept badly, but the morning walk helped me feel clearer.',
    AppLanguage.polish:
        'Spałem źle, ale poranny spacer pomógł mi się rozjaśnić w głowie.',
  };

  const dashboardSizes = <(int, int)>[
    (320, 568),
    (390, 844),
    (600, 960),
  ];

  for (final language in AppLanguage.values) {
    final lang = language.code;
    final strings = EterStrings.forLanguage(language);

    for (final register in EterRegister.values) {
      final registerName = register.name;

      for (final size in dashboardSizes) {
        for (final textScale in const [1.0, 2.0]) {
          final scaleName = textScale.toStringAsFixed(0);
          final captureName = 'dashboard-$lang-$registerName'
              '-${size.$1}x${size.$2}-text-$scaleName.png';
          testWidgets(captureName, (tester) async {
            await pumpPrototype(
              tester,
              register: register,
              language: language,
              width: size.$1.toDouble(),
              height: size.$2.toDouble(),
              textScale: textScale,
            );
            await expectLater(
              find.byType(ProviderScope),
              matchesGoldenFile(captureName),
            );
            await disposePrototype(tester);
          });
        }
      }

      final journalCaptureName = 'journal-$lang-$registerName-390x844.png';
      testWidgets(journalCaptureName, (tester) async {
        await pumpPrototype(
          tester,
          register: register,
          language: language,
        );
        await tester.tap(find.text(strings.destinationJournal));
        await tester.pump(const Duration(milliseconds: 400));
        await tester.enterText(
          find.byType(TextField),
          journalEntry[language]!,
        );
        await tester.pump(const Duration(milliseconds: 1100));
        await tester.pump();
        tester.testTextInput.hide();
        await tester.pump(const Duration(seconds: 4));
        await expectLater(
          find.byType(ProviderScope),
          matchesGoldenFile(journalCaptureName),
        );
        await disposePrototype(tester);
      });

      final guidanceCaptureName =
          'guidance-expanded-$lang-$registerName-390x844.png';
      testWidgets(guidanceCaptureName, (tester) async {
        await pumpPrototype(
          tester,
          register: register,
          language: language,
        );
        await openSection(tester, strings, strings.sectionGuidance);
        await tester.pump();
        await expectLater(
          find.byType(ProviderScope),
          matchesGoldenFile(guidanceCaptureName),
        );
        await disposePrototype(tester);
      });

      final bodyCaptureName = 'body-expanded-$lang-$registerName-390x844.png';
      testWidgets(bodyCaptureName, (tester) async {
        await pumpPrototype(
          tester,
          register: register,
          language: language,
        );
        await openSection(tester, strings, strings.sectionBody);
        await tester.pump(const Duration(milliseconds: 700));
        await expectLater(
          find.byType(ProviderScope),
          matchesGoldenFile(bodyCaptureName),
        );
        await disposePrototype(tester);
      });

      final vesselCaptureName = 'vessel-$lang-$registerName-390x844.png';
      testWidgets(vesselCaptureName, (tester) async {
        await pumpPrototype(
          tester,
          register: register,
          language: language,
        );
        await openSection(tester, strings, strings.sectionVessel);
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 300)),
        );
        await tester.pump();
        expect(find.text(strings.theVessel), findsOneWidget);
        await expectLater(
          find.byType(ProviderScope),
          matchesGoldenFile(vesselCaptureName),
        );
        await disposePrototype(tester);
      });

      for (final configuration in const [
        (390, 844, 1.0),
        (320, 568, 2.0),
      ]) {
        final scaleName = configuration.$3.toStringAsFixed(0);
        final captureName = 'sanctum-$lang-$registerName'
            '-${configuration.$1}x${configuration.$2}-text-$scaleName.png';
        testWidgets(captureName, (tester) async {
          await pumpPrototype(
            tester,
            register: register,
            language: language,
            width: configuration.$1.toDouble(),
            height: configuration.$2.toDouble(),
            textScale: configuration.$3,
          );
          await tester.tap(find.bySemanticsLabel(strings.openSanctumSemantic));
          await tester.pump(const Duration(milliseconds: 400));
          await expectLater(
            find.byType(ProviderScope),
            matchesGoldenFile(captureName),
          );
          await disposePrototype(tester);
        });
      }
    }

    // --- day-only captures ---------------------------------------------------

    final estimateCaptureName =
        'body-estimate-correction-$lang-day-390x844.png';
    testWidgets(estimateCaptureName, (tester) async {
      await pumpPrototype(
        tester,
        register: EterRegister.day,
        language: language,
      );
      await openSection(tester, strings, strings.sectionBody);
      await tester.pump(const Duration(milliseconds: 700));

      // `EterAction` draws its label upper-cased, so the finder has to too.
      final review = find.text(strings.proceed.toUpperCase());
      tester
          .widget<EterAction>(
            find.ancestor(of: review, matching: find.byType(EterAction)),
          )
          .onPressed!
          .call();
      await tester.pump();
      final estimatePosition =
          tester.state<ScrollableState>(downwardScrollable()).position;
      estimatePosition.jumpTo(estimatePosition.maxScrollExtent);
      await tester.pump();
      await expectLater(
        find.byType(ProviderScope),
        matchesGoldenFile(estimateCaptureName),
      );
      await disposePrototype(tester);
    });

    final signalsCaptureName =
        'body-historical-signals-$lang-day-390x844.png';
    testWidgets(signalsCaptureName, (tester) async {
      await pumpPrototype(
        tester,
        register: EterRegister.day,
        language: language,
      );
      await openSection(tester, strings, strings.sectionBody);
      await tester.pump(const Duration(milliseconds: 700));
      tester.state<ScrollableState>(downwardScrollable()).position.jumpTo(650);
      await tester.pump();
      await expectLater(
        find.byType(ProviderScope),
        matchesGoldenFile(signalsCaptureName),
      );
      await disposePrototype(tester);
    });

    final activityCaptureName = 'body-activity-$lang-day-390x844.png';
    testWidgets(activityCaptureName, (tester) async {
      await pumpPrototype(
        tester,
        register: EterRegister.day,
        language: language,
      );
      await openSection(tester, strings, strings.sectionBody);
      await tester.pump(const Duration(milliseconds: 700));
      await tester.scrollUntilVisible(
        find.byType(EngravedActivityDay),
        500,
        scrollable: downwardScrollable(),
      );
      await tester.pump();
      await expectLater(
        find.byType(ProviderScope),
        matchesGoldenFile(activityCaptureName),
      );
      await disposePrototype(tester);
    });

    final vesselSmallCaptureName = 'vessel-$lang-day-320x568-text-2.png';
    testWidgets(vesselSmallCaptureName, (tester) async {
      await pumpPrototype(
        tester,
        register: EterRegister.day,
        language: language,
        width: 320,
        height: 568,
        textScale: 2,
      );
      await openSection(tester, strings, strings.sectionVessel);
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 300)),
      );
      await tester.pump();
      // The capture is worthless if the section never opened, and at this size
      // it silently did not. Assert the heading rather than trusting the tap.
      expect(find.text(strings.theVessel), findsOneWidget);
      await expectLater(
        find.byType(ProviderScope),
        matchesGoldenFile(vesselSmallCaptureName),
      );
      await disposePrototype(tester);
    });

    final midArrivalCaptureName =
        'dashboard-$lang-day-mid-arrival-390x844.png';
    testWidgets(midArrivalCaptureName, (tester) async {
      await pumpPrototype(
        tester,
        register: EterRegister.day,
        language: language,
        reduceMotion: false,
        arrivalTime: const Duration(milliseconds: 360),
      );
      await expectLater(
        find.byType(ProviderScope),
        matchesGoldenFile(midArrivalCaptureName),
      );
      await disposePrototype(tester);
    });
  }
}
