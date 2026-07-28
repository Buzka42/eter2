import 'package:drift/native.dart';
import 'package:eter/core/clock.dart';
import 'package:eter/core/db/app_database.dart';
import 'package:eter/features/onboarding/tutorial.dart';
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
}
