import 'package:eter/core/db/app_database.dart';
import 'package:eter/core/instruments.dart';
import 'package:eter/core/register.dart';
import 'package:eter/core/controls.dart';
import 'package:eter/features/dashboard/dashboard_page.dart';
import 'package:eter/features/journal/journal_page.dart';
import 'package:eter/features/sanctum/sanctum_overlay.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:video_player/video_player.dart';

import 'helpers/prototype_harness.dart';

void main() {
  late AppDatabase db;

  setUp(() async => db = await eterTestDatabase());

  Future<void> closeShell(WidgetTester tester) async {
    // Disposing the tree makes Drift schedule a zero-duration close timer;
    // flush it now, inside the test, or teardown reports a pending timer.
    // The in-memory database is deliberately left unclosed: closing awaits
    // that same timer and would deadlock FakeAsync.
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
  }

  Future<void> pumpShell(
    WidgetTester tester, {
    EterRegister register = EterRegister.day,
    bool reduceMotion = false,
  }) async {
    eterSurfaceSize(tester, 390, 844);
    await tester.pumpWidget(
      eterPrototypeApp(
        db: db,
        register: register,
        reduceMotion: reduceMotion,
      ),
    );
    // Let the streams emit, then settle the arrival and the balance.
    await tester.pump();
    await tester.pump(const Duration(seconds: 4));
  }

  Future<void> expandBody(WidgetTester tester) async {
    await tester.tap(find.text('LOOK DEEPER'));
    await tester.pump();
    await tester.tap(find.text('THE BODY'));
    await tester.pump(const Duration(milliseconds: 700));
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 20)),
    );
    await tester.pump();
  }

  testWidgets('the resting Dashboard shows guidance and one quiet disclosure',
      (tester) async {
    await pumpShell(tester);
    expect(find.byType(DashboardPage), findsOneWidget);
    expect(
      find.text(
        'Begin gently. Your body is asking for steadiness, not intensity.',
        findRichText: true,
      ),
      findsOneWidget,
    );
    expect(find.text('LOOK DEEPER'), findsOneWidget);
    // No chart intrudes on the resting state.
    expect(find.text('CLOSE'), findsNothing);
    await closeShell(tester);
  });

  testWidgets('the disclosure expands in place and closes back to guidance',
      (tester) async {
    await pumpShell(tester);
    await expandBody(tester);

    // Conclusion first, instrument beneath, explicit close.
    expect(
      find.textContaining('1,610 kcal eaten against 1,870 kcal burned'),
      findsOneWidget,
    );
    expect(find.text('CLOSE'), findsOneWidget);

    final close = find.text('CLOSE');
    await tester.ensureVisible(close);
    await tester.pump();
    await tester.tap(close);
    await tester.pump(const Duration(milliseconds: 700));
    expect(find.text('CLOSE'), findsNothing);
    expect(find.text('LOOK DEEPER'), findsOneWidget);
    // The guidance is still there, untouched.
    expect(
      find.text(
        'Begin gently. Your body is asking for steadiness, not intensity.',
        findRichText: true,
      ),
      findsOneWidget,
    );
    await closeShell(tester);
  });

  testWidgets('expansion and a half-written entry survive the page crossing',
      (tester) async {
    await pumpShell(tester);
    await expandBody(tester);
    expect(find.text('CLOSE'), findsOneWidget);

    // Cross to the Journal and write half an entry.
    await tester.tap(find.text('JOURNAL'));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.enterText(find.byType(TextField), 'A half-formed thought');
    await tester.pump();

    // Cross back: the expansion holds; the entry holds.
    await tester.tap(find.text('DASHBOARD'));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('CLOSE'), findsOneWidget);

    await tester.tap(find.text('JOURNAL'));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('A half-formed thought'), findsOneWidget);

    // Flush the autosave debounce, then the close timer.
    await tester.pump(const Duration(milliseconds: 1100));
    await closeShell(tester);
  });

  testWidgets('a written entry autosaves and arrives', (tester) async {
    await pumpShell(tester);
    await tester.tap(find.text('JOURNAL'));
    await tester.pump(const Duration(milliseconds: 400));

    await tester.enterText(
      find.byType(TextField),
      'I slept badly, but the morning walk helped me feel clearer.',
    );
    // The 900 ms autosave debounce.
    await tester.pump(const Duration(milliseconds: 1100));
    await tester.pump();

    final rows = await db.loadJournalForRange(
      DateTime(2026, 7, 27),
      DateTime(2026, 7, 28),
    );
    expect(rows, hasLength(1));
    expect(rows.single.entryText,
        'I slept badly, but the morning walk helped me feel clearer.');
    expect(rows.single.source, 'typed');
    expect(rows.single.excludedFromAi, isFalse);
    // The database future completes before the frame carrying the cleared
    // composer is painted.
    await tester.pump();

    // It renders on the page, composer cleared.
    expect(
      find.text('I slept badly, but the morning walk helped me feel clearer.',
          findRichText: true),
      findsWidgets,
    );
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      isEmpty,
    );
    await closeShell(tester);
  });

  testWidgets('the journal composer stays to writing and dictation',
      (tester) async {
    await pumpShell(tester);
    await tester.tap(find.text('JOURNAL'));
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.byType(TextField), findsOneWidget);
    expect(find.text('DICTATE'), findsOneWidget);
    expect(find.text('DONE'), findsNothing);
    expect(find.textContaining('Aether guidance'), findsNothing);
    await closeShell(tester);
  });

  testWidgets('nothing is essential behind a gesture: words reach both pages',
      (tester) async {
    await pumpShell(tester);
    expect(find.byType(DashboardPage), findsOneWidget);
    await tester.tap(find.text('JOURNAL'));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byType(JournalPage), findsOneWidget);
    await tester.tap(find.text('DASHBOARD'));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byType(DashboardPage), findsOneWidget);
    await closeShell(tester);
  });

  testWidgets('the Eter signature opens the Sanctum and close restores state',
      (tester) async {
    await pumpShell(tester);
    await tester.tap(find.text('JOURNAL'));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.enterText(find.byType(TextField), 'Still here beneath');
    await tester.pump();

    await tester.tap(find.bySemanticsLabel('Open Sanctum'));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byType(SanctumOverlay), findsOneWidget);
    expect(find.text('How Eter meets you'), findsOneWidget);

    final guidanceClose = find.text('CLOSE');
    await tester.ensureVisible(guidanceClose);
    await tester.pump();
    await tester.tap(guidanceClose);
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byType(SanctumOverlay), findsNothing);
    expect(find.text('Still here beneath'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 1100));
    await closeShell(tester);
  });

  testWidgets('expanded Guidance shows three dimensions and evidence receipt',
      (tester) async {
    await pumpShell(tester);
    await tester.tap(find.text('LOOK DEEPER'));
    await tester.pump();
    await tester.tap(find.text('GUIDANCE'));
    await tester.pump();
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 20)),
    );
    await tester.pump();

    for (final label in ['HEALTH', 'MIND', 'SPIRIT']) {
      expect(find.text(label), findsOneWidget);
    }
    expect(
      find.textContaining('Your recovery signals favour steadiness'),
      findsOneWidget,
    );

    final evidence = find.bySemanticsLabel('Evidence for health');
    await tester.ensureVisible(evidence);
    await tester.pump();
    await tester.tap(evidence);
    await tester.pump();
    expect(
        find.textContaining('association, not proof of cause'), findsOneWidget);

    final guidanceClose = find.text('CLOSE');
    await tester.ensureVisible(guidanceClose);
    await tester.pump();
    await tester.tap(guidanceClose);
    await tester.pump();
    expect(find.text('LOOK DEEPER'), findsOneWidget);
    await closeShell(tester);
  });

  testWidgets('an estimated meal is corrected before it enters the balance',
      (tester) async {
    await pumpShell(tester);
    await expandBody(tester);

    final review = find.text('REVIEW');
    final verticalScroll = find
        .byWidgetPredicate(
          (widget) =>
              widget is Scrollable &&
              widget.axisDirection == AxisDirection.down,
        )
        .hitTestable();
    tester.state<ScrollableState>(verticalScroll).position.jumpTo(800);
    await tester.pump();
    tester
        .widget<EterAction>(
          find.ancestor(of: review, matching: find.byType(EterAction)),
        )
        .onPressed!
        .call();
    await tester.pump();

    final estimate = find.byKey(const ValueKey('nutrition-kcal-2'));
    await tester.enterText(estimate, '260');
    tester
        .widget<EterAction>(
          find.ancestor(
            of: find.text('CONFIRM'),
            matching: find.byType(EterAction),
          ),
        )
        .onPressed!
        .call();
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 20)),
    );
    await tester.pump();

    final rows = await db.loadJournalForRange(
      DateTime(2026, 7, 27),
      DateTime(2026, 7, 28),
    );
    expect(rows, isEmpty);
    final intake = await db.intakeKcalForRange(
      DateTime(2026, 7, 27),
      DateTime(2026, 7, 28),
    );
    expect(intake, 1870);
    expect(find.textContaining('NOT COUNTED'), findsNothing);
    await closeShell(tester);
  });

  testWidgets('Body renders historical signals with semantic equivalents',
      (tester) async {
    final semantics = tester.ensureSemantics();
    await pumpShell(tester);
    await expandBody(tester);
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 120)),
    );
    await tester.pump();

    expect(find.byType(EngravedTrend), findsNWidgets(3));
    expect(find.byType(EngravedSleepStages), findsOneWidget);
    expect(
      find.textContaining('Activity by time of day is unavailable'),
      findsOneWidget,
    );
    expect(
      find.bySemanticsLabel(
        RegExp(r'Resting heart rate trend, 14 readings'),
      ),
      findsOneWidget,
    );
    expect(
      find.bySemanticsLabel(RegExp(r'Sleep stages\.')),
      findsOneWidget,
    );
    semantics.dispose();
    await closeShell(tester);
  });

  testWidgets('Sanctum preferences persist without rewriting the profile',
      (tester) async {
    await pumpShell(tester);
    final before = await db.loadProfile();

    await tester.tap(find.bySemanticsLabel('Open Sanctum'));
    await tester.pump();
    await tester.tap(find.text('Journal'));
    await tester.pump();
    await tester.tap(find.text('Grounded'));
    await tester.pump();
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 20)),
    );
    await tester.pump();

    final after = await db.loadProfile();
    expect(after?.startSurface, 'journal');
    expect(after?.guidanceMode, 'grounded');
    expect(after?.dob, before?.dob);
    expect(after?.birthPlace, before?.birthPlace);
    expect(after?.weightKg, before?.weightKg);
    await closeShell(tester);
  });

  testWidgets('system back closes the Sanctum before leaving the shell',
      (tester) async {
    await pumpShell(tester);
    await tester.tap(find.bySemanticsLabel('Open Sanctum'));
    await tester.pump();
    expect(find.byType(SanctumOverlay), findsOneWidget);

    await tester.binding.handlePopRoute();
    await tester.pump();
    expect(find.byType(SanctumOverlay), findsNothing);
    expect(find.byType(DashboardPage), findsOneWidget);
    await closeShell(tester);
  });

  testWidgets('reduced motion: no video, no ambient ticker, text simply there',
      (tester) async {
    await pumpShell(tester, register: EterRegister.night, reduceMotion: true);
    expect(find.byType(VideoPlayer), findsNothing);
    expect(tester.hasRunningAnimations, isFalse);
    expect(
      find.text(
        'Begin gently. Your body is asking for steadiness, not intensity.',
        findRichText: true,
      ),
      findsOneWidget,
    );
    await closeShell(tester);
  });

  testWidgets('tap targets meet the 48 dp floor', (tester) async {
    final semanticsHandle = tester.ensureSemantics();
    await pumpShell(tester);
    // The semantics nodes sit on the hit regions themselves, so their rects
    // are the target sizes — and their existence doubles as an a11y check.
    for (final label in [
      'journal',
      'dashboard',
      'Open Sanctum',
      'Look deeper',
    ]) {
      final node = tester.getSemantics(find.bySemanticsLabel(label));
      expect(node.rect.height, greaterThanOrEqualTo(48), reason: label);
    }

    await tester.tap(find.text('JOURNAL'));
    await tester.pump(const Duration(milliseconds: 400));
    final dictate = tester.getSemantics(find.bySemanticsLabel('Dictate'));
    expect(dictate.rect.height, greaterThanOrEqualTo(48));
    expect(dictate.rect.width, greaterThanOrEqualTo(48));
    semanticsHandle.dispose();
    await closeShell(tester);
  });
}
