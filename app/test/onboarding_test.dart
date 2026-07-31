import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:eter/core/db/app_database.dart';
import 'package:eter/core/register.dart';
import 'package:eter/core/theme.dart';
import 'package:eter/features/onboarding/onboarding_flow.dart';
import 'package:eter/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/prototype_harness.dart';

void main() {
  // The Journal's date needs `intl`'s locale data, and no test runs `main()`.
  setUpAll(eterInitializeFormatting);

  late AppDatabase db;
  late AppDatabase emptyDb;
  late ProfileRow profile;

  setUp(() async {
    db = await eterTestDatabase();
    profile = (await db.loadProfile())!;
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
    emptyDb = AppDatabase(NativeDatabase.memory());
  });

  testWidgets('onboarding is quiet, optional, and persists explicit consent',
      (tester) async {
    eterSurfaceSize(tester, 390, 844);
    var completed = false;

    await tester.pumpWidget(
      MaterialApp(
        theme: EterTheme.day(),
        home: EterRegisterScope(
          register: EterRegister.day,
          child: OnboardingFlow(
            database: db,
            profile: profile,
            onComplete: () => completed = true,
          ),
        ),
      ),
    );
    await tester.pump();

    // Step one is the language, because every step after it is written in
    // whatever this chooses. It arrives pre-selected from the device, so the
    // ordinary path is to read it and continue.
    expect(find.text('What language should Eter speak?'), findsOneWidget);
    expect(find.text('English'), findsOneWidget);
    expect(find.text('Polski'), findsOneWidget);
    await tester.tap(find.text('CONTINUE'));
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Begin with what matters'), findsOneWidget);
    expect(find.byType(Checkbox), findsNothing);
    expect(find.byType(Switch), findsNothing);
    await tester.enterText(
      find.widgetWithText(TextField, 'What should Eter call you?'),
      'Mara',
    );
    await tester.enterText(
      find.widgetWithText(TextField, 'What would you like more of?'),
      'Steadier energy',
    );

    await tester.tap(find.text('CONTINUE'));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Your point of origin'), findsOneWidget);
    expect(find.textContaining('provisional'), findsOneWidget);

    await tester.ensureVisible(find.text('CONTINUE'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('CONTINUE'));
    await tester.pump(const Duration(milliseconds: 500));
    // The register is chosen here rather than discovered in the Sanctum later.
    expect(find.text('How Eter should speak'), findsOneWidget);
    await tester.tap(find.text('Immersive'));
    await tester.pump();

    await tester.ensureVisible(find.text('CONTINUE'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('CONTINUE'));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Choose what may leave this device'), findsOneWidget);
    expect(find.text('OFF'), findsNWidgets(3));
    // Health is offered during setup, not only afterwards.
    expect(find.text('Health history'), findsOneWidget);

    await tester.tap(find.text('AI guidance'));
    await tester.pump();
    await tester.tap(find.text('Journal-aware guidance'));
    await tester.pump();
    // Both consents expand a description under themselves, so the action has
    // moved by the time it is tapped.
    await tester.ensureVisible(find.text('ENTER ETER'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('ENTER ETER'));
    // Finishing now also writes the birth context, which resolves the place
    // through the geocoder — absent under a test binding, so it fails fast,
    // but it is still a real await and 30 ms is not a guarantee.
    for (var attempt = 0; attempt < 40 && !completed; attempt++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 20)),
      );
      await tester.pump();
    }

    expect(completed, isTrue);
    final saved = (await db.loadProfile())!;
    expect(saved.firstName, 'Mara');
    expect(saved.aiConsentAt, isNotNull);
    expect(saved.journalAiConsentAt, isNotNull);
    expect(saved.cloudSyncConsentAt, isNull);
    expect(saved.guidanceMode, 'immersive');
    // The mirror is never consented to on the person's behalf.
    expect(saved.journalCloudSyncConsentAt, isNull);
    final answers = await db.loadIntakeAnswers();
    expect(answers['primary_intention']?.value, 'Steadier energy');
    expect(answers['onboarding_complete']?.value, 'true');
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(milliseconds: 50));
  }, timeout: const Timeout(Duration(seconds: 12)));

  testWidgets('onboarding remains scrollable at 320dp and 200 percent text',
      (tester) async {
    eterSurfaceSize(tester, 320, 568);
    await tester.pumpWidget(
      MaterialApp(
        theme: EterTheme.day(),
        home: Builder(
          builder: (context) {
            final query = MediaQuery.of(context);
            return MediaQuery(
              data: query.copyWith(textScaler: const TextScaler.linear(2)),
              child: EterRegisterScope(
                register: EterRegister.day,
                child: OnboardingFlow(
                  database: db,
                  profile: profile,
                  onComplete: () {},
                ),
              ),
            );
          },
        ),
      ),
    );
    await tester.pump();
    final continueAction = find.text('CONTINUE');
    await tester.ensureVisible(continueAction);
    await tester.pump();
    expect(tester.takeException(), isNull);
    expect(continueAction, findsOneWidget);
  });

  testWidgets('a fresh install creates a real profile and enforces 16 plus',
      (tester) async {
    eterSurfaceSize(tester, 390, 844);
    var completed = false;
    await tester.pumpWidget(
      MaterialApp(
        theme: EterTheme.day(),
        home: EterRegisterScope(
          register: EterRegister.day,
          child: OnboardingFlow(
            database: emptyDb,
            profile: null,
            onComplete: () => completed = true,
          ),
        ),
      ),
    );
    await tester.pump();
    // Past the language step, then past the welcome step. Both are skippable —
    // neither has a required field — which is what this walks over to reach the
    // one step that validates.
    for (var i = 0; i < 2; i++) {
      await tester.tap(find.text('CONTINUE'));
      await tester.pump(const Duration(milliseconds: 500));
    }

    final dob = find.widgetWithText(TextField, 'Birth date');
    final weight =
        find.widgetWithText(TextField, 'Current weight in kilograms');
    final height =
        find.widgetWithText(TextField, 'Current height in centimetres');
    await tester.enterText(dob, '2015-01-01');
    await tester.enterText(weight, '62');
    await tester.enterText(height, '168');
    await tester.ensureVisible(find.text('CONTINUE'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('CONTINUE'));
    await tester.pump();
    expect(find.textContaining('aged 16 and over'), findsOneWidget);

    await tester.enterText(dob, '1995-06-14');
    await tester.tap(find.text('Female'));
    await tester.ensureVisible(find.text('CONTINUE'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('CONTINUE'));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('How Eter should speak'), findsOneWidget);

    // Left untouched: the default has to survive someone walking past it.
    await tester.ensureVisible(find.text('CONTINUE'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('CONTINUE'));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Choose what may leave this device'), findsOneWidget);

    await tester.ensureVisible(find.text('ENTER ETER'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('ENTER ETER'));
    // Finishing now also writes the birth context, which resolves the place
    // through the geocoder — absent under a test binding, so it fails fast,
    // but it is still a real await and 30 ms is not a guarantee.
    for (var attempt = 0; attempt < 40 && !completed; attempt++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 20)),
      );
      await tester.pump();
    }

    expect(completed, isTrue);
    final saved = await emptyDb.loadProfile();
    expect(saved?.dob, DateTime(1995, 6, 14));
    expect(saved?.weightKg, 62);
    expect(saved?.heightCm, 168);
    expect(saved?.sex, 'female');
    expect(saved?.aiConsentAt, isNull);
    expect(saved?.cloudSyncConsentAt, isNull);
    // Balanced is the default, and walking past the step keeps it.
    expect(saved?.guidanceMode, 'balanced');
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(milliseconds: 50));
  }, timeout: const Timeout(Duration(seconds: 12)));

  testWidgets('the app root sends an empty database to onboarding',
      (tester) async {
    eterSurfaceSize(tester, 390, 844);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [databaseProvider.overrideWithValue(emptyDb)],
        child: const EterApp(),
      ),
    );
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 30)),
    );
    await tester.pump();
    expect(find.text('What language should Eter speak?'), findsOneWidget);
    expect(await emptyDb.loadProfile(), isNull);
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(milliseconds: 50));
  });
}
