import 'dart:convert';

import 'package:eter/core/db/app_database.dart';
import 'package:eter/core/aether/guidance_contract.dart';
import 'package:eter/core/instruments.dart';
import 'package:eter/core/journal/classification_contract.dart';
import 'package:eter/core/register.dart';
import 'package:eter/core/profile/birth_context.dart';
import 'package:eter/core/vessel/reading_composer.dart';
import 'package:eter/core/controls.dart';
import 'package:eter/features/dashboard/dashboard_page.dart';
import 'package:eter/features/journal/journal_page.dart';
import 'package:eter/features/sanctum/sanctum_overlay.dart';
import 'package:eter/features/vessel/vessel_section.dart';
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
    JournalClassificationProvider? journalProvider,
    AetherProvider? aetherProvider,
    VesselReadingProvider? vesselProvider,
    BirthplaceResolver? birthplaceResolver,
    double width = 390,
    double height = 844,
    double textScale = 1,
  }) async {
    eterSurfaceSize(tester, width, height);
    final app = eterPrototypeApp(
      db: db,
      register: register,
      reduceMotion: reduceMotion,
      journalProvider: journalProvider,
      aetherProvider: aetherProvider,
      vesselProvider: vesselProvider,
      birthplaceResolver: birthplaceResolver,
      textScale: textScale,
    );
    await tester.pumpWidget(
      app,
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

  Future<void> waitForWidget(
    WidgetTester tester,
    Finder finder, {
    int attempts = 120,
  }) async {
    for (var i = 0; i < attempts; i++) {
      if (finder.evaluate().isNotEmpty) return;
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 100)),
      );
      await tester.pump();
    }
    expect(finder, findsWidgets);
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

    // The composer clears; the page itself stays today's, so the entry is
    // read in the archive rather than below the field.
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      isEmpty,
    );
    await tester.tap(find.bySemanticsLabel('Open journal history'));
    await tester.pumpAndSettle();
    expect(
      find.text('I slept badly, but the morning walk helped me feel clearer.',
          findRichText: true),
      findsWidgets,
    );
    final keepLocal = find.text('KEEP LOCAL');
    await tester.ensureVisible(keepLocal);
    await tester.tap(keepLocal);
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 20)),
    );
    await tester.pump();
    final excluded = await db.loadJournalForRange(
      DateTime(2026, 7, 27),
      DateTime(2026, 7, 28),
    );
    expect(excluded.single.excludedFromAi, isTrue);
    expect(find.textContaining('Kept from Aether'), findsOneWidget);
    expect(find.text('ALLOW AETHER'), findsOneWidget);
    await closeShell(tester);
  });

  testWidgets(
      'journal interpretation asks for detail, applies estimates, and undoes',
      (tester) async {
    await db.updateProfileConsents(aiAllowed: true);
    await db.addJournalEntry(
      JournalEntriesCompanion.insert(
        createdAt: eterPinnedNow,
        entryText: 'I had soup for lunch.',
      ),
    );
    final provider = _JournalSequenceProvider();
    await pumpShell(tester, journalProvider: provider);
    await tester.tap(find.text('JOURNAL'));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.tap(find.bySemanticsLabel('Open journal history'));
    await tester.pumpAndSettle();

    final interpret = find.text('INTERPRET');
    await tester.ensureVisible(interpret);
    await tester.tap(interpret);
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 20)),
    );
    await tester.pump();
    expect(find.text('How large was the bowl?'), findsOneWidget);

    await tester.enterText(
      find.byKey(const ValueKey('journal-clarification-1')),
      'A medium bowl.',
    );
    // The clarification field and the marginal check-ins above it both grow
    // the page; the action has to be brought back into view before the tap.
    await tester.ensureVisible(find.text('INTERPRET'));
    await tester.tap(find.text('INTERPRET'));
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 20)),
    );
    await tester.pump();
    expect(find.textContaining('waiting for review in Body'), findsOneWidget);
    expect(provider.clarification, 'A medium bowl.');
    expect((await db.loadJournalEntry(1))?.status, 'classified');
    final undo = find.text('UNDO INTERPRETATION');
    tester
        .widget<GestureDetector>(
          find.ancestor(of: undo, matching: find.byType(GestureDetector)).first,
        )
        .onTap!
        .call();
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 20)),
    );
    await tester.pump();
    expect((await db.loadJournalEntry(1))?.status, 'pending');
    await closeShell(tester);
  }, timeout: const Timeout(Duration(seconds: 20)));

  testWidgets('journal provider failure changes no source or derived state',
      (tester) async {
    await db.updateProfileConsents(aiAllowed: true);
    await db.addJournalEntry(
      JournalEntriesCompanion.insert(
        createdAt: eterPinnedNow,
        entryText: 'Lunch was soup.',
      ),
    );
    await pumpShell(tester, journalProvider: _FailingJournalProvider());
    await tester.tap(find.text('JOURNAL'));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.tap(find.bySemanticsLabel('Open journal history'));
    await tester.pumpAndSettle();

    final interpret = find.text('INTERPRET');
    await tester.ensureVisible(interpret);
    await tester.tap(interpret);
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 20)),
    );
    await tester.pump();

    expect(
      find.text('Interpretation is unavailable right now. Nothing changed.'),
      findsOneWidget,
    );
    final entry = await db.loadJournalEntry(1);
    expect(entry?.status, 'pending');
    expect(entry?.entryText, 'Lunch was soup.');
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

  testWidgets('History opens the archive, saving today before it does',
      (tester) async {
    await db.addJournalEntry(
      JournalEntriesCompanion.insert(
        createdAt: DateTime.utc(2026, 7, 26, 9),
        entryText: 'Yesterday held a quieter rhythm.',
      ),
    );
    await pumpShell(tester);
    await tester.tap(find.text('JOURNAL'));
    await tester.pump();

    // The page itself is today only: nothing already written is on it.
    expect(
      find.text('Yesterday held a quieter rhythm.', findRichText: true),
      findsNothing,
    );

    final composer = find.byType(TextField).first;
    await tester.enterText(composer, 'A thought from today.');
    await tester.tap(find.bySemanticsLabel('Open journal history'));
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 30)),
    );
    await tester.pumpAndSettle();

    // Leaving the page commits the draft rather than discarding it.
    final todayEntries = await db.loadJournalForRange(
      DateTime(2026, 7, 27),
      DateTime(2026, 7, 28),
    );
    expect(
      todayEntries.map((entry) => entry.entryText),
      contains('A thought from today.'),
    );

    // Two: the button that opened it and the sheet's own heading.
    expect(find.text('HISTORY'), findsNWidgets(2));
    await tester.tap(find.bySemanticsLabel('Previous journal day'));
    await tester.pumpAndSettle();
    expect(find.text('Sunday 26 July'), findsOneWidget);
    final olderEntry = find.text(
      'Yesterday held a quieter rhythm.',
      findRichText: true,
    );
    await waitForWidget(tester, olderEntry);
    expect(olderEntry, findsOneWidget);

    await tester.tap(find.bySemanticsLabel('Close history'));
    await tester.pumpAndSettle();
    expect(find.text('HISTORY'), findsOneWidget);
    expect(find.text('DICTATE'), findsOneWidget);
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

  testWidgets('Guidance actions reflow at 320dp and 200 percent text',
      (tester) async {
    await pumpShell(
      tester,
      width: 320,
      height: 568,
      textScale: 2,
      reduceMotion: true,
    );
    final lookDeeper = find.text('LOOK DEEPER');
    await tester.ensureVisible(lookDeeper);
    await tester.pump();
    await tester.tap(lookDeeper);
    await tester.pump();
    await tester.tap(find.text('GUIDANCE'));
    await tester.pump();

    expect(find.text('REFRESH'), findsOneWidget);
    expect(find.text('CLOSE'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await closeShell(tester);
  });

  testWidgets(
      'the first look of the day composes once, and refresh reuses the cache',
      (tester) async {
    await db.resetPersonalization();
    await db.updateProfileConsents(aiAllowed: true);
    final provider = _DashboardAetherProvider();
    // Composition is automatic on the day's first look: nothing is tapped
    // here, and the guidance still arrives.
    await pumpShell(tester, aetherProvider: provider);
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 100)),
    );
    await tester.pump(const Duration(seconds: 4));
    expect(await db.loadGuidanceForDate('2026-07-27'), hasLength(4));
    expect(
      find.text('A quiet observation.', findRichText: true),
      findsWidgets,
    );
    expect(provider.calls, 1);

    await tester.tap(find.text('LOOK DEEPER'));
    await tester.pump();
    await tester.tap(find.text('GUIDANCE'));
    await tester.pump();
    await tester.tap(find.text('REFRESH'));
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 100)),
    );
    await tester.pump();
    expect(
      find.text('Guidance is already current for the available context.'),
      findsOneWidget,
    );
    expect(provider.calls, 1);
    await closeShell(tester);
  });

  testWidgets('unavailable Aether transport leaves guidance uncomposed',
      (tester) async {
    await db.resetPersonalization();
    await db.updateProfileConsents(aiAllowed: true);
    await pumpShell(tester);

    // Without a transport there is nothing to compose automatically, so the
    // surface stays honest and the explicit retry says why.
    expect(
      find.text('Today’s guidance has not been composed yet.'),
      findsOneWidget,
    );
    await tester.tap(find.text('COMPOSE NOW'));
    await tester.pump();

    expect(
      find.text('Aether composition is not connected on this build yet.'),
      findsOneWidget,
    );
    expect(await db.loadGuidanceForDate('2026-07-27'), isEmpty);
    await closeShell(tester);
  });

  testWidgets('Vessel renders deterministic offline positions and cached depth',
      (tester) async {
    await pumpShell(tester);
    await tester.tap(find.text('LOOK DEEPER'));
    await tester.pump();
    await tester.tap(find.text('VESSEL'));
    await tester.pump();
    await waitForWidget(tester, find.text('READ DEEPER'));

    expect(find.byType(VesselSection), findsOneWidget);
    expect(find.text('TODAY’S CARD'), findsOneWidget);
    expect(find.text('Strength'), findsWidgets);
    expect(find.text('LIFE PATH 8'), findsOneWidget);
    expect(find.text('SUN'), findsOneWidget);
    expect(find.text('MOON'), findsOneWidget);
    expect(find.text('ASCENDANT'), findsOneWidget);
    expect(find.textContaining('Birth time is unknown'), findsOneWidget);

    tester
        .widget<EterAction>(
          find.ancestor(
            of: find.text('READ DEEPER'),
            matching: find.byType(EterAction),
          ),
        )
        .onPressed!
        .call();
    await tester.pump();
    expect(
      find.textContaining('Life Path 8 describes'),
      findsOneWidget,
    );
    expect(
      find.textContaining('has not been composed yet'),
      findsNWidgets(3),
    );
    await closeShell(tester);
  });

  testWidgets(
      'Vessel composes only missing readings and preserves cached depth',
      (tester) async {
    await db.updateProfileConsents(aiAllowed: true);
    final provider = _VesselProvider();
    await pumpShell(tester, vesselProvider: provider);
    await tester.tap(find.text('LOOK DEEPER'));
    await tester.pump();
    await tester.tap(find.text('VESSEL'));
    await tester.pump();
    await waitForWidget(tester, find.text('READ DEEPER'));
    tester
        .widget<EterAction>(
          find.ancestor(
            of: find.text('READ DEEPER'),
            matching: find.byType(EterAction),
          ),
        )
        .onPressed!
        .call();
    await tester.pump();

    final compose = find.text('COMPOSE READINGS');
    await tester.ensureVisible(compose);
    await tester.tap(compose);
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 50)),
    );
    await tester.pump();

    expect(find.text('Composed reflection for sun.'), findsOneWidget);
    expect(
      find.textContaining('Life Path 8 describes'),
      findsOneWidget,
    );
    expect(provider.calls, 1);
    expect(provider.requestedKeys, isNot(contains('lifePath')));
    expect(find.textContaining('missing personal readings'), findsOneWidget);
    await closeShell(tester);
  });

  testWidgets('Vessel refreshes after birth context changes', (tester) async {
    await pumpShell(tester);
    await tester.tap(find.text('LOOK DEEPER'));
    await tester.pump();
    await tester.tap(find.text('VESSEL'));
    await tester.pump();
    await waitForWidget(
      tester,
      find.textContaining('Ascendant is not reliable'),
    );

    await db.updateBirthContext(
      birthTimeMinutes: 405,
      birthUtcOffsetMinutes: 60,
      birthPlace: 'Warsaw, Poland',
      birthLatitude: 52.2297,
      birthLongitude: 21.0122,
    );
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 50)),
    );
    await tester.pump();
    await waitForWidget(tester, find.text('ASCENDANT'));

    expect(
      find.textContaining('Ascendant is not reliable'),
      findsNothing,
    );
    expect(find.text('ASCENDANT'), findsOneWidget);
    await closeShell(tester);
  });

  testWidgets('Vessel states unavailable composition without losing keywords',
      (tester) async {
    await db.updateProfileConsents(aiAllowed: true);
    await pumpShell(tester);
    await tester.tap(find.text('LOOK DEEPER'));
    await tester.pump();
    await tester.tap(find.text('VESSEL'));
    await tester.pump();
    await waitForWidget(tester, find.text('READ DEEPER'));
    tester
        .widget<EterAction>(
          find.ancestor(
            of: find.text('READ DEEPER'),
            matching: find.byType(EterAction),
          ),
        )
        .onPressed!
        .call();
    await tester.pump();

    final compose = find.text('COMPOSE READINGS');
    await tester.ensureVisible(compose);
    await tester.tap(compose);
    await tester.pump();

    expect(
      find.text(
        'Personal reading composition is not connected on this build yet.',
      ),
      findsOneWidget,
    );
    expect(find.text('LIFE PATH 8'), findsWidgets);
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
    expect(find.byType(EngravedSleepHistory), findsOneWidget);
    expect(find.byType(EngravedActivityDay), findsOneWidget);
    expect(find.textContaining('Activity by time of day is unavailable'),
        findsNothing);
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
    expect(
      find.bySemanticsLabel(
        RegExp(r'7 day sleep history, 7 nights\.'),
      ),
      findsOneWidget,
    );
    expect(
      find.bySemanticsLabel(
        RegExp(r'Activity by time of day\. Total 430 kilocalories\.'),
      ),
      findsOneWidget,
    );

    final thirtyDays = find.text('30 DAYS');
    await tester.ensureVisible(thirtyDays);
    await tester.pump();
    await tester.tap(thirtyDays);
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 20)),
    );
    await tester.pump();
    expect(
      find.bySemanticsLabel(
        RegExp(r'30 day sleep history, 7 nights\.'),
      ),
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

  testWidgets('Sanctum completes birth context and improves chart inputs',
      (tester) async {
    final resolver = _BirthplaceResolver();
    await pumpShell(tester, birthplaceResolver: resolver);
    await tester.tap(find.bySemanticsLabel('Open Sanctum'));
    await tester.pump();
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 20)),
    );
    await tester.pump();

    final action = find.byKey(const ValueKey('birth-context-primary-action'));
    await tester.ensureVisible(action);
    tester.widget<EterAction>(action).onPressed!.call();
    await tester.pump();
    await tester.enterText(
      find.byKey(const ValueKey('birth-context-time')),
      '06:45',
    );
    await tester.enterText(
      find.byKey(const ValueKey('birth-context-offset')),
      '+01:00',
    );
    await tester.enterText(
      find.byKey(const ValueKey('birth-context-place')),
      'Warsaw, Poland',
    );
    tester.widget<EterAction>(action).onPressed!.call();
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 30)),
    );
    await tester.pump();

    expect(find.text('Birth context saved on this device.'), findsOneWidget);
    final profile = await db.loadProfile();
    expect(profile?.birthTimeMinutes, 405);
    expect(profile?.birthUtcOffsetMinutes, 60);
    expect(profile?.birthLatitude, 52.2297);
    expect(profile?.birthLongitude, 21.0122);
    expect(resolver.queries, ['Warsaw, Poland']);
    await closeShell(tester);
  });

  testWidgets('Sanctum grants and revokes outbound permissions independently',
      (tester) async {
    await pumpShell(tester);
    await tester.tap(find.bySemanticsLabel('Open Sanctum'));
    await tester.pump();
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 20)),
    );
    await tester.pump();

    final journalAllowed =
        find.byKey(const ValueKey('JOURNAL-AWARE GUIDANCE-allowed'));
    await tester.ensureVisible(journalAllowed);
    tester.widget<GestureDetector>(journalAllowed).onTap!();
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 20)),
    );
    await tester.pump();
    var profile = await db.loadProfile();
    expect(profile?.aiConsentAt, isNotNull);
    expect(profile?.journalAiConsentAt, isNotNull);
    expect(profile?.cloudSyncConsentAt, isNull);

    final aiOff = find.byKey(const ValueKey('AI GUIDANCE-off'));
    await tester.ensureVisible(aiOff);
    tester.widget<GestureDetector>(aiOff).onTap!();
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 20)),
    );
    await tester.pump();
    profile = await db.loadProfile();
    expect(profile?.aiConsentAt, isNull);
    expect(profile?.journalAiConsentAt, isNull);
    expect(profile?.cloudSyncConsentAt, isNull);
    await closeShell(tester);
  });

  testWidgets('Sanctum makes learned patterns inspectable and dismissible',
      (tester) async {
    await db.upsertPattern(
      PatternCandidatesCompanion.insert(
        key: 'mood-after-walking',
        computedAt: DateTime.utc(2026, 7, 27),
        summary: 'Mood was higher after walking.',
        evidenceJson: '{"n":12,"window":"30 days"}',
        confidence: 0.68,
      ),
    );
    final semantics = tester.ensureSemantics();
    await pumpShell(tester);
    await tester.tap(find.bySemanticsLabel('Open Sanctum'));
    await tester.pump();
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 20)),
    );
    await tester.pump();

    final summary = find.bySemanticsLabel(
      RegExp(r'Mood was higher after walking.*12 observations.*30 days'),
    );
    await tester.ensureVisible(summary);
    await tester.pump();
    expect(summary, findsOneWidget);

    final dismiss = find.text('DISMISS');
    await tester.ensureVisible(dismiss);
    tester
        .widget<EterAction>(
          find.ancestor(of: dismiss, matching: find.byType(EterAction)),
        )
        .onPressed!
        .call();
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 20)),
    );
    await tester.pump();

    expect(await db.loadActivePatterns(), isEmpty);
    expect(find.textContaining('will not use it'), findsOneWidget);
    semantics.dispose();
    await closeShell(tester);
  });

  testWidgets('Sanctum reviews local patterns without claiming weak evidence',
      (tester) async {
    final semantics = tester.ensureSemantics();
    await pumpShell(tester);
    await tester.tap(find.bySemanticsLabel('Open Sanctum'));
    await tester.pump();

    final review = find.text('REVIEW');
    await tester.ensureVisible(review);
    tester
        .widget<EterAction>(
          find.ancestor(of: review, matching: find.byType(EterAction)),
        )
        .onPressed!
        .call();
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 30)),
    );
    await tester.pump();

    expect(
      find.text('Not enough consistent local evidence yet.'),
      findsOneWidget,
    );
    expect(await db.loadActivePatterns(), isEmpty);
    semantics.dispose();
    await closeShell(tester);
  });

  testWidgets('Sanctum prepares and speaks a factual weekly view',
      (tester) async {
    final semantics = tester.ensureSemantics();
    await pumpShell(tester);
    await tester.tap(find.bySemanticsLabel('Open Sanctum'));
    await tester.pump();

    final prepare = find.text('PREPARE');
    await tester.ensureVisible(prepare);
    tester
        .widget<EterAction>(
          find.ancestor(of: prepare, matching: find.byType(EterAction)),
        )
        .onPressed!
        .call();
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 30)),
    );
    await tester.pump();

    expect(
      find.text('Seven-day view prepared on this device.'),
      findsOneWidget,
    );
    final headline = find.textContaining('Your ');
    await waitForWidget(tester, headline);
    await tester.ensureVisible(headline.first);
    await tester.pump();
    expect(
      find.bySemanticsLabel(
        RegExp(r'Your (partial )?seven-day view'),
      ),
      findsOneWidget,
    );
    expect(await db.loadRetrospectives(), hasLength(1));
    semantics.dispose();
    await closeShell(tester);
  });

  testWidgets('local deletion requires a second explicit action',
      (tester) async {
    await pumpShell(tester);
    await tester.tap(find.bySemanticsLabel('Open Sanctum'));
    await tester.pump();

    final first = find.text('DELETE');
    await tester.ensureVisible(first);
    tester
        .widget<EterAction>(
          find.ancestor(of: first, matching: find.byType(EterAction)),
        )
        .onPressed!
        .call();
    await tester.pump();

    expect(find.text('DELETE NOW'), findsOneWidget);
    expect(find.textContaining('future cloud account copy'), findsOneWidget);
    expect(await db.loadProfile(), isNotNull);
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

class _JournalSequenceProvider implements JournalClassificationProvider {
  int calls = 0;
  String? clarification;

  @override
  Future<String> classify(JournalClassificationRequest request) async {
    calls += 1;
    clarification = request.clarification;
    if (calls == 1) {
      return jsonEncode({
        'status': 'needsDetail',
        'food': [],
        'lifestyle': [],
        'clarifyingQuestion': 'How large was the bowl?',
      });
    }
    return jsonEncode({
      'status': 'classified',
      'food': [
        {
          'meal': 'Soup',
          'kcal': 280,
          'confidence': 0.6,
          'assumptions': ['One medium bowl'],
        },
      ],
      'lifestyle': [],
      'clarifyingQuestion': null,
    });
  }
}

class _FailingJournalProvider implements JournalClassificationProvider {
  @override
  Future<String> classify(JournalClassificationRequest request) =>
      Future.error(StateError('offline'));
}

class _DashboardAetherProvider implements AetherProvider {
  int calls = 0;

  @override
  Future<String> compose(AetherProviderRequest request) async {
    calls += 1;
    return jsonEncode({
      for (final key in const ['synthesis', 'health', 'mind', 'spirit'])
        key: {
          'sentences': ['A quiet observation.'],
          'primaryAction': 'Pause and notice.',
        },
    });
  }
}

class _VesselProvider implements VesselReadingProvider {
  int calls = 0;
  final requestedKeys = <String>[];

  @override
  Future<String> compose(VesselReadingProviderRequest request) async {
    calls += 1;
    final positions = request.context['positions'] as List<Object?>;
    requestedKeys
      ..clear()
      ..addAll(
        positions.map(
          (raw) => (raw as Map<String, Object>)['key']! as String,
        ),
      );
    return jsonEncode({
      'readings': [
        for (final key in requestedKeys)
          {
            'key': key,
            'passage': 'Composed reflection for $key.',
          },
      ],
    });
  }
}

class _BirthplaceResolver implements BirthplaceResolver {
  final queries = <String>[];

  @override
  Future<BirthplaceCoordinates> resolve(String place) async {
    queries.add(place);
    return const BirthplaceCoordinates(
      latitude: 52.2297,
      longitude: 21.0122,
    );
  }
}
