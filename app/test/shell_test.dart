import 'package:eter/core/db/app_database.dart';
import 'package:eter/core/register.dart';
import 'package:eter/features/dashboard/dashboard_page.dart';
import 'package:eter/features/journal/journal_page.dart';
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
    expect(find.text('THE BODY'), findsOneWidget);
    expect(find.text('58 bpm resting'), findsOneWidget);
    // No chart intrudes on the resting state.
    expect(find.text('CLOSE'), findsNothing);
    await closeShell(tester);
  });

  testWidgets('the disclosure expands in place and closes back to guidance',
      (tester) async {
    await pumpShell(tester);
    await tester.tap(find.text('THE BODY'));
    await tester.pump(const Duration(milliseconds: 700));

    // Conclusion first, instrument beneath, explicit close.
    expect(
      find.textContaining('1,610 kcal eaten against 1,870 kcal burned'),
      findsOneWidget,
    );
    expect(find.text('CLOSE'), findsOneWidget);

    await tester.tap(find.text('CLOSE'));
    await tester.pump(const Duration(milliseconds: 700));
    expect(find.text('CLOSE'), findsNothing);
    expect(find.text('58 bpm resting'), findsOneWidget);
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
    await tester.tap(find.text('THE BODY'));
    await tester.pump(const Duration(milliseconds: 700));
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

  testWidgets('the marginal switch excludes the next entry from Aether',
      (tester) async {
    await pumpShell(tester);
    await tester.tap(find.text('JOURNAL'));
    await tester.pump(const Duration(milliseconds: 400));

    await tester.tap(find.text('Included in Aether guidance'));
    await tester.pump();
    expect(find.text('Kept from Aether'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'Not for the model.');
    await tester.pump(const Duration(milliseconds: 1100));
    await tester.pump();

    final rows = await db.loadJournalForRange(
      DateTime(2026, 7, 27),
      DateTime(2026, 7, 28),
    );
    expect(rows.single.excludedFromAi, isTrue);
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
    for (final label in ['journal', 'dashboard', 'The Body']) {
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
