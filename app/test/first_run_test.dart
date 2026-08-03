import 'package:drift/native.dart';
import 'package:eter/core/clock.dart';
import 'package:eter/core/db/app_database.dart';
import 'package:eter/core/tokens.dart';
import 'package:eter/features/onboarding/tutorial.dart';
import 'package:eter/features/onboarding/walkthrough.dart';
import 'package:eter/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/prototype_harness.dart';

/// The one path every real user takes, end to end.
///
/// Every other test starts from a seeded fixture, which is efficient and
/// leaves the most important sequence — empty database, onboarding, tutorial,
/// first day, first entry — covered only in pieces. This walks it as a person
/// would, through the real app root, with nothing pre-populated.
void main() {
  // The Journal's date needs `intl`'s locale data, and no test runs `main()`.
  setUpAll(eterInitializeFormatting);

  late AppDatabase db;

  setUp(() => db = AppDatabase(NativeDatabase.memory()));
  tearDown(() => db.close());

  /// The app root, exactly as `main()` assembles it minus the platform bits.
  Widget app() => ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
          nowProvider.overrideWithValue(() => eterPinnedNow),
        ],
        child: const EterApp(),
      );

  /// The root reads intake asynchronously before it can decide what to show.
  Future<void> settle(WidgetTester tester) async {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 40)),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
  }

  testWidgets('a fresh install walks intake, tutorial and the first day',
      (tester) async {
    eterSurfaceSize(tester, 390, 844);
    await tester.pumpWidget(app());
    await settle(tester);

    // ---- Onboarding -------------------------------------------------------
    // Step one is the language; see the walkthrough above.
    expect(find.text('What language should Eter speak?'), findsOneWidget);
    await tester.tap(find.text('CONTINUE'));
    await settle(tester);

    expect(find.text('Begin with what matters'), findsOneWidget);
    await tester.enterText(
      find.widgetWithText(TextField, 'What should Eter call you?'),
      'Mara',
    );
    await tester.tap(find.text('CONTINUE'));
    await settle(tester);

    expect(find.text('Your point of origin'), findsOneWidget);
    await tester.enterText(
      find.widgetWithText(TextField, 'Birth date'),
      '1990-03-14',
    );
    await tester.enterText(
      find.widgetWithText(TextField, 'Current weight in kilograms'),
      '70',
    );
    await tester.enterText(
      find.widgetWithText(TextField, 'Current height in centimetres'),
      '175',
    );
    await tester.ensureVisible(find.text('CONTINUE'));
    await tester.tap(find.text('CONTINUE'));
    await settle(tester);

    expect(find.text('How Eter should speak'), findsOneWidget);
    await tester.ensureVisible(find.text('CONTINUE'));
    await tester.tap(find.text('CONTINUE'));
    await settle(tester);

    expect(find.text('Choose what may leave this device'), findsOneWidget);
    await tester.ensureVisible(find.text('ENTER ETER'));
    await tester.tap(find.text('ENTER ETER'));
    await settle(tester);

    // ---- Tutorial ---------------------------------------------------------
    // It comes between intake and the shell, once, and must not be skippable
    // by accident on its last passage.
    expect(find.text('ETER'), findsWidgets);
    for (var passage = 0; passage < 3; passage++) {
      await tester.tap(find.text('NEXT'));
      await settle(tester);
    }
    expect(find.text('BEGIN'), findsOneWidget);
    await tester.tap(find.text('BEGIN'));
    await settle(tester);

    // ---- The walkthrough --------------------------------------------------
    // The second half of the first minute runs *over the shell*, so the real
    // rail and the real Sanctum mark are what get lit. Five stops, and the
    // last one commits.
    expect(find.byKey(const ValueKey('walkthrough-advance')), findsOneWidget);
    expect(find.byKey(const ValueKey('walkthrough-skip')), findsOneWidget);
    for (var step = 0; step < 4; step++) {
      await tester.tap(find.byKey(const ValueKey('walkthrough-advance')));
      await settle(tester);
    }
    // The last stop has no SKIP: there is nothing left to skip past.
    expect(find.byKey(const ValueKey('walkthrough-skip')), findsNothing);
    await tester.tap(find.byKey(const ValueKey('walkthrough-advance')));
    await settle(tester);
    expect(find.byKey(const ValueKey('walkthrough-advance')), findsNothing);
    expect(
      (await db.loadIntakeAnswers())[EterTutorial.walkthroughKey]?.value,
      'true',
      reason: 'a finished walkthrough must survive a restart',
    );

    // ---- The shell, on a day with nothing in it ---------------------------
    // The first thing a real user sees is an empty product. It has to be
    // whole rather than a set of blanks waiting to be filled.
    expect(find.text('JOURNAL'), findsWidgets);
    expect(find.text('DASHBOARD'), findsWidgets);
    expect(tester.takeException(), isNull);

    // ---- The first entry --------------------------------------------------
    // The shell opens on the Dashboard by default, so writing means crossing
    // to the Journal first — which is itself part of the path being tested.
    await tester.tap(find.text('JOURNAL').first);
    await settle(tester);
    final composer = find.byType(TextField).first;
    expect(composer, findsOneWidget);
    await tester.enterText(composer, 'The first thing I have written here.');

    // There is no save button: the page keeps itself, 900 ms after the last
    // keystroke. Nobody should have to commit their own journal entry.
    await tester.pump(const Duration(milliseconds: 1200));
    await settle(tester);

    final entries = await db.loadJournalForRange(
      DateTime(eterPinnedNow.year, eterPinnedNow.month, eterPinnedNow.day),
      DateTime(eterPinnedNow.year, eterPinnedNow.month, eterPinnedNow.day)
          .add(const Duration(days: 1)),
    );
    expect(entries, hasLength(1));
    expect(entries.single.entryText, 'The first thing I have written here.');

    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(milliseconds: 50));
  }, timeout: const Timeout(Duration(seconds: 40)));

  testWidgets('intake and tutorial are each shown once, and survive a restart',
      (tester) async {
    eterSurfaceSize(tester, 390, 844);

    // Someone who has already been through both.
    await db.saveProfile(ProfilesCompanion.insert(
      dob: DateTime(1990, 3, 14),
      sex: 'other',
      weightKg: 70,
      units: 'metric',
    ));
    await db.saveIntakeAnswer(
      key: 'onboarding_complete',
      value: 'true',
      tier: 'essential',
    );
    await db.saveIntakeAnswer(
      key: EterTutorial.answerKey,
      value: 'true',
      tier: 'essential',
    );
    await db.saveIntakeAnswer(
      key: EterTutorial.walkthroughKey,
      value: 'true',
      tier: 'essential',
    );

    await tester.pumpWidget(app());
    await settle(tester);

    expect(find.text('Begin with what matters'), findsNothing);
    expect(find.text('BEGIN'), findsNothing);
    expect(find.text('JOURNAL'), findsWidgets);

    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(milliseconds: 50));
  }, timeout: const Timeout(Duration(seconds: 30)));

  testWidgets('a fresh install has no account and says nothing is backed up',
      (tester) async {
    eterSurfaceSize(tester, 390, 844);
    await db.saveProfile(ProfilesCompanion.insert(
      dob: DateTime(1990, 3, 14),
      sex: 'other',
      weightKg: 70,
      units: 'metric',
    ));
    await db.saveIntakeAnswer(
      key: 'onboarding_complete',
      value: 'true',
      tier: 'essential',
    );
    await db.saveIntakeAnswer(
      key: EterTutorial.answerKey,
      value: 'true',
      tier: 'essential',
    );
    await db.saveIntakeAnswer(
      key: EterTutorial.walkthroughKey,
      value: 'true',
      tier: 'essential',
    );

    await tester.pumpWidget(app());
    await settle(tester);

    // The account system is absent in a test build, and that is a shipped
    // configuration rather than a broken one: nothing may crash, and the
    // Sanctum must still open.
    await tester.tap(find.text('ETER').first);
    await settle(tester);
    expect(find.text('ACCOUNT'), findsOneWidget);
    expect(find.textContaining('no account system'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(milliseconds: 50));
  }, timeout: const Timeout(Duration(seconds: 30)));

  group('the walkthrough caption always stands on scrim', () {
    // Both of these were found on a phone, on the first step of the first
    // minute, where DALEJ and POMIN were drawn in white over the cream journal
    // page — on top of the date and the History control. Nothing in the suite
    // could see it: the caption is positioned and painted correctly in
    // isolation, and it is only the *relation* between the caption and the hole
    // that was wrong.
    const screen = Size(1080, 2412);

    test('the caption takes the roomier side, and that is not enough', () {
      // The journal step: the hole starts below the rail and runs almost to the
      // bottom. Above is the roomier side, and picking it is still not enough —
      // 508 px for a caption that needs about 600. Choosing a side cannot fix
      // this, which is what the carve below is for.
      const journal = Rect.fromLTRB(0, 508, 1080, 2280);
      expect(WalkthroughScrim.captionBelow(journal, screen), isFalse);
      expect(journal.top, lessThan(600),
          reason: 'the roomier gap is still too small; this is the real fault');

      const control = Rect.fromLTRB(600, 2100, 1000, 2200);
      expect(WalkthroughScrim.captionBelow(control, screen), isFalse);

      const rail = Rect.fromLTRB(0, 120, 1080, 260);
      expect(WalkthroughScrim.captionBelow(rail, screen), isTrue);

      // No target at all: the scrim is whole and the caption sits at the foot.
      expect(WalkthroughScrim.captionBelow(null, screen), isTrue);

      // Choosing by room and choosing by the hole's centre are the same
      // predicate — both reduce to `top + bottom < height`. Pinned so nobody
      // "fixes" the side selection again believing it is the bug.
      for (final probe in const [
        Rect.fromLTRB(0, 508, 1080, 2280),
        Rect.fromLTRB(0, 120, 1080, 260),
        Rect.fromLTRB(0, 300, 1080, 1400),
        Rect.fromLTRB(600, 2100, 1000, 2200),
        Rect.fromLTRB(0, 0, 1080, 2412),
      ]) {
        expect(
          WalkthroughScrim.captionBelow(probe, screen),
          probe.center.dy <= screen.height / 2,
          reason: '$probe: the two formulations must agree, always',
        );
      }
    });

    test('the spotlight gives up the ground the caption stands on', () {
      const journal = Rect.fromLTRB(0, 508, 1080, 2280);
      const caption = Rect.fromLTRB(60, 100, 1020, 700);
      expect(caption.overlaps(journal), isTrue,
          reason: 'this is the case that has to be handled, not avoided');

      final lit = WalkthroughScrim.lit(journal, caption);

      // Nothing the caption is written on is lit. Probed just inside the
      // caption rather than on its corners: the carve is rounded like every
      // other shape here, so the exact corner points sit outside it by design
      // and prove nothing either way. The letters are what must stay dark.
      final inset = caption.deflate(EterSpace.rChip);
      for (final point in [
        inset.topLeft,
        inset.topRight,
        inset.bottomLeft,
        inset.bottomRight,
        inset.center,
        Offset(inset.center.dx, inset.bottom),
      ]) {
        expect(
          lit.contains(point),
          isFalse,
          reason: '$point is under the caption and must stay scrimmed',
        );
      }

      // The rest of the target is still lit, so the step still points at
      // something.
      expect(lit.contains(const Offset(540, 1600)), isTrue);
      expect(lit.contains(const Offset(540, 2200)), isTrue);
    });

    test('a caption clear of the hole costs the spotlight nothing', () {
      const rail = Rect.fromLTRB(0, 120, 1080, 260);
      const caption = Rect.fromLTRB(60, 1700, 1020, 2300);
      expect(caption.overlaps(rail), isFalse);

      final lit = WalkthroughScrim.lit(rail, caption);
      expect(lit.contains(rail.center), isTrue);
      expect(
        lit.getBounds(),
        WalkthroughScrim.lit(rail, null).getBounds(),
        reason: 'an untouched spotlight must be exactly the untouched shape',
      );
    });
  });
}
