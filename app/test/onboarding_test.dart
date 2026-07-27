import 'package:eter/core/db/app_database.dart';
import 'package:eter/core/register.dart';
import 'package:eter/core/theme.dart';
import 'package:eter/features/onboarding/onboarding_flow.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/prototype_harness.dart';

void main() {
  late AppDatabase db;
  late ProfileRow profile;

  setUp(() async {
    db = await eterTestDatabase();
    profile = (await db.loadProfile())!;
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

    await tester.tap(find.text('CONTINUE'));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Choose what may leave this device'), findsOneWidget);
    expect(find.text('OFF'), findsNWidgets(3));

    await tester.tap(find.text('AI guidance'));
    await tester.pump();
    await tester.tap(find.text('Journal-aware guidance'));
    await tester.pump();
    await tester.tap(find.text('ENTER ETER'));
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 30)),
    );
    await tester.pump();

    expect(completed, isTrue);
    final saved = (await db.loadProfile())!;
    expect(saved.firstName, 'Mara');
    expect(saved.aiConsentAt, isNotNull);
    expect(saved.journalAiConsentAt, isNotNull);
    expect(saved.cloudSyncConsentAt, isNull);
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
}
