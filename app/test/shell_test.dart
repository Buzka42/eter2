import 'dart:convert';

import 'package:eter/core/db/app_database.dart';
import 'package:eter/core/aether/guidance_contract.dart';
import 'package:eter/core/icons.dart';
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
    // The automatic compose has to finish before REFRESH can do anything:
    // the surface guards against composing twice at once, so tapping while
    // the first pass is still in flight is correctly a no-op.
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 600)),
    );
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

  testWidgets('the resting Dashboard shows guidance and the three depths',
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
    // The row is the whole control now. `LOOK DEEPER` used to stand in front
    // of it, so reaching a surface that was always there cost two taps.
    expect(find.text('LOOK DEEPER'), findsNothing);
    expect(find.byType(EterSectionMark), findsNWidgets(3));
    // By day nothing is open until one is chosen, and nothing can be closed.
    expect(find.text('CLOSE'), findsNothing);
    await closeShell(tester);
  });

  testWidgets('a depth opens with no disclosure, and there is nothing to close',
      (tester) async {
    await pumpShell(tester);
    await expandBody(tester);

    expect(
      find.textContaining('1,610 kcal eaten against 1,870 kcal burned'),
      findsOneWidget,
    );
    // No close anywhere. Leaving the Body means choosing one of the other two,
    // which is why the row above it never goes away.
    expect(find.text('CLOSE'), findsNothing);
    expect(find.byType(EterSectionMark), findsNWidgets(3));
    // The guidance is still there, untouched, above it.
    expect(
      find.text(
        'Begin gently. Your body is asking for steadiness, not intensity.',
        findRichText: true,
      ),
      findsOneWidget,
    );
    await closeShell(tester);
  });

  testWidgets('at night a depth is already open, with nothing tapped',
      (tester) async {
    // The owner's rule: in the immersive and balanced registers after dark it
    // opens on its own. `EterRegister.night` is exactly those two — grounded
    // resolves to day at every hour — so this is the whole condition.
    await pumpShell(tester, register: EterRegister.night);
    expect(find.byType(EterSectionMark), findsNWidgets(3));

    final selected = tester
        .widgetList<Semantics>(find.byType(Semantics))
        .where((widget) => widget.properties.selected ?? false)
        .map((widget) => widget.properties.label)
        .toList();
    expect(selected, contains('guidance'));
    await closeShell(tester);
  });

  // The threshold row: three depths that stay siblings.
  //
  // The disclosure used to expand one section *in place*, so reaching a second
  // one meant collapsing back to the top and starting again — the "shell game"
  // the owner reported. The row now survives the opening, and these are the
  // assertions that would catch that regressing.

  testWidgets('the row names all three depths and marks the open one',
      (tester) async {
    await pumpShell(tester);
    // The three are named from the first frame; there is no state in which
    // they are hidden behind something else.
    expect(find.byType(EterSectionMark), findsNWidgets(3));
    expect(find.text('GUIDANCE'), findsOneWidget);
    expect(find.text('THE BODY'), findsOneWidget);
    expect(find.text('VESSEL'), findsOneWidget);

    await tester.tap(find.text('THE BODY'));
    await tester.pump(const Duration(milliseconds: 700));

    // The row survived the opening: the other two are still one tap away.
    expect(find.byType(EterSectionMark), findsNWidgets(3));
    expect(find.text('VESSEL'), findsOneWidget);
    expect(find.text('CLOSE'), findsNothing);

    // The open one is the only one marked selected, so a screen reader can
    // say where it is.
    final selected = tester
        .widgetList<Semantics>(find.byType(Semantics))
        .where((widget) => widget.properties.selected ?? false)
        .map((widget) => widget.properties.label)
        .toList();
    expect(selected, contains('the body'));
    expect(selected, isNot(contains('vessel')));
    await closeShell(tester);
  });

  testWidgets('a second depth is reachable without collapsing to the top',
      (tester) async {
    await pumpShell(tester);
    await expandBody(tester);
    expect(find.textContaining('1,610 kcal'), findsOneWidget);

    // Straight across to the Vessel — no CLOSE, no LOOK DEEPER in between.
    // This is the move the old in-place expansion made impossible.
    final vessel = find.text('VESSEL');
    await tester.ensureVisible(vessel);
    await tester.pump();
    await tester.tap(vessel);
    // Three pumps, not one: the slide runs, then `AnimatedSwitcher` drops the
    // outgoing section from its stack on the frame *after* the animation
    // reports done, and the Vessel reads the chart off the device in between.
    await tester.pump(const Duration(milliseconds: 700));
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 300)),
    );
    await tester.pump(const Duration(milliseconds: 700));

    expect(find.byType(VesselSection), findsOneWidget);
    expect(find.byType(EterSectionMark), findsNWidgets(3));
    expect(find.textContaining('1,610 kcal'), findsNothing);
    expect(find.text('LOOK DEEPER'), findsNothing);
    await closeShell(tester);
  });

  testWidgets('the open section does not print its own name a second time',
      (tester) async {
    await pumpShell(tester);
    await tester.tap(find.text('GUIDANCE'));
    await tester.pump(const Duration(milliseconds: 700));

    // The row is the heading. A second `GUIDANCE` two lines below it reads as
    // a mistake, and did until the sections learned to drop their own.
    expect(find.text('GUIDANCE'), findsOneWidget);
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

    // Nobody asks for interpretation any more: opening the day reads what is
    // pending, and the model's question arrives on its own.
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 40)),
    );
    await tester.pumpAndSettle();
    expect(find.text('How large was the bowl?'), findsOneWidget);

    await tester.enterText(
      find.byKey(const ValueKey('journal-clarification-1')),
      'A medium bowl.',
    );
    // Answering the question is the one interpretation still triggered by
    // hand, because it is a reply rather than a request.
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 40)),
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

    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 40)),
    );
    await tester.pumpAndSettle();

    // Nobody asked for this, so nothing may be reported as having failed.
    // The page is unchanged, stays pending, and is tried again next time —
    // an error banner for work the person never requested is noise.
    expect(
      find.text('Interpretation is unavailable right now. Nothing changed.'),
      findsNothing,
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

  testWidgets('typing autosaves after a pause, and only what was typed',
      (tester) async {
    // The counterpart to the dictation rule below: an ordinary pause in
    // typing still commits, because that is what makes the page keep itself.
    await pumpShell(tester);
    await tester.tap(find.text('JOURNAL'));
    await tester.pump(const Duration(milliseconds: 400));

    await tester.enterText(find.byType(TextField).first, 'A written thought.');
    await tester.pump(const Duration(milliseconds: 1200));
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 40)),
    );
    await tester.pump();

    final entries = await db.loadJournalForRange(
      DateTime.utc(2026, 7, 27),
      DateTime.utc(2026, 7, 29),
    );
    expect(
      entries.where((row) => row.entryText == 'A written thought.'),
      hasLength(1),
    );
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
    // The automatic compose has to finish before REFRESH can do anything:
    // the surface guards against composing twice at once, so tapping while
    // the first pass is still in flight is correctly a no-op.
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 600)),
    );
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

    // Leaving Guidance means choosing another depth, not closing this one.
    expect(find.text('CLOSE'), findsNothing);
    final body = find.text('THE BODY');
    await tester.ensureVisible(body);
    await tester.pump();
    await tester.tap(body);
    await tester.pump(const Duration(milliseconds: 700));
    // The row is still there and has moved its mark, which is the whole way
    // out of a section now.
    expect(find.byType(EterSectionMark), findsNWidgets(3));
    final nowSelected = tester
        .widgetList<Semantics>(find.byType(Semantics))
        .where((widget) => widget.properties.selected ?? false)
        .map((widget) => widget.properties.label)
        .toList();
    expect(nowSelected, contains('the body'));
    await closeShell(tester);
  });

  testWidgets('the depths row reflows at 320dp and 200 percent text',
      (tester) async {
    await pumpShell(
      tester,
      width: 320,
      height: 568,
      textScale: 2,
      reduceMotion: true,
    );
    // The row wraps to more than one line at this size, which is why the
    // pinned header measures it rather than assuming a height — assuming one
    // overflowed a plain 390 dp phone by 37 px.
    final guidance = find.text('GUIDANCE');
    await tester.ensureVisible(guidance);
    await tester.pump();
    await tester.tap(guidance);
    await tester.pump();

    // REFRESH and CLOSE have both left this surface: recomposing is one
    // control in the Sanctum, and there is nothing to close.
    expect(find.text('REFRESH'), findsNothing);
    expect(find.text('CLOSE'), findsNothing);
    expect(find.byType(EterSectionMark), findsNWidgets(3));
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
      () => Future<void>.delayed(const Duration(milliseconds: 400)),
    );
    await tester.pump(const Duration(seconds: 4));
    expect(await db.loadGuidanceForDate('2026-07-27'), hasLength(4));
    expect(
      find.text('A quiet observation.', findRichText: true),
      findsWidgets,
    );
    expect(provider.calls, 1);

    // The automatic compose has to finish before REFRESH can do anything:
    // the surface guards against composing twice at once, so tapping while
    // the first pass is still in flight is correctly a no-op.
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 600)),
    );
    await tester.pump();

    await tester.tap(find.text('GUIDANCE'));
    await tester.pump();
    // Nothing to press: the day's first look is the only automatic compose,
    // and there is no per-section refresh to reuse the cache with.
    expect(find.text('REFRESH'), findsNothing);
    // Assembling now sweeps the record for patterns before it builds the
    // request, which is real work on a real database.
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 400)),
    );
    await closeShell(tester);
  });

  testWidgets('unavailable Aether transport leaves guidance uncomposed',
      (tester) async {
    await db.resetPersonalization();
    await db.updateProfileConsents(aiAllowed: true);
    await pumpShell(tester);

    // Without a transport there is nothing to compose automatically, so the
    // surface stays honest — and says so without offering a control, because
    // the one control that asks again lives in the Sanctum.
    expect(
      find.text('Today’s guidance has not been composed yet.'),
      findsOneWidget,
    );
    expect(find.text('COMPOSE NOW'), findsNothing);
    expect(await db.loadGuidanceForDate('2026-07-27'), isEmpty);
    await closeShell(tester);
  });

  /// The Vessel opens the whole chart in one menu.
  ///
  /// The Life Path and the astrogram were two disclosures with a compose
  /// button each, which framed them as two subjects. They are one chart, and
  /// the reading is now about the configuration rather than one passage per
  /// card — so there is one menu, no controls in it, and the writing arrives
  /// on its own.

  Future<void> openVessel(WidgetTester tester) async {
    // The automatic compose has to finish first: the surface guards against
    // composing twice at once, so acting while the first pass is in flight is
    // correctly a no-op.
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 600)),
    );
    await tester.pump();
    await tester.tap(find.text('VESSEL'));
    await tester.pump();
    // The section mounts before its data resolves, so wait for something the
    // loaded chart draws rather than for the widget itself.
    await waitForWidget(tester, find.text('YOUR CARD'));
  }

  /// The reading used to be behind a `READ DEEPER` inside the Vessel, and this
  /// pressed it. There is no disclosure now — the writing this surface exists
  /// to show is simply on the page — so opening the Vessel is the whole of it.
  Future<void> openTheReading(WidgetTester tester) async {
    await tester.pump();
  }

  testWidgets('the Vessel renders the chart offline, in one list',
      (tester) async {
    await pumpShell(tester);
    await openVessel(tester);

    expect(find.byType(VesselSection), findsOneWidget);
    // The card is the Sun's Arcana, fixed at birth — not a daily draw.
    expect(find.text('YOUR CARD'), findsOneWidget);
    expect(find.text('The Emperor'), findsWidgets);
    expect(find.textContaining('It does not change'), findsOneWidget);
    // Everything the device computed is here without a model being asked.
    expect(find.text('LIFE PATH 8'), findsOneWidget);
    expect(find.text('SUN'), findsOneWidget);
    expect(find.text('MOON'), findsOneWidget);
    expect(find.text('ASCENDANT'), findsOneWidget);
    expect(find.textContaining('Birth time is unknown'), findsOneWidget);

    // One menu, and the astrogram is inside it rather than beside it.
    expect(find.text('THE CHART'), findsNothing);
    await openTheReading(tester);
    for (final body in const ['MERCURY', 'SATURN', 'NEPTUNE']) {
      expect(find.text(body), findsOneWidget, reason: '$body is missing');
    }
    await closeShell(tester);
  });

  testWidgets('no control anywhere asks for the reading', (tester) async {
    await db.updateProfileConsents(aiAllowed: true);
    await pumpShell(tester, vesselProvider: _VesselProvider());
    await openVessel(tester);
    await openTheReading(tester);

    // The owner asked for the compose buttons to go: the reading is written
    // when a birth time is saved, and there is nothing to press.
    expect(find.text('COMPOSE READINGS'), findsNothing);
    expect(find.text('THE CHART'), findsNothing);
    await closeShell(tester);
  });

  testWidgets('without a birth time the reading waits rather than guessing',
      (tester) async {
    // The fixture profile has no birth time, so the angles would be a noon
    // guess — and a reading of the wrong angles would cache for life.
    final provider = _VesselProvider();
    await db.updateProfileConsents(aiAllowed: true);
    await pumpShell(tester, vesselProvider: provider);
    await openVessel(tester);
    await openTheReading(tester);
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 100)),
    );
    await tester.pump();

    expect(find.textContaining('waits for your birth time'), findsOneWidget);
    expect(provider.calls, 0);
    await closeShell(tester);
  });

  testWidgets('with a birth time the reading composes on its own',
      (tester) async {
    await db.updateProfileConsents(aiAllowed: true);
    await db.updateBirthContext(
      birthTimeMinutes: 405,
      birthTimePrecision: 'exact',
      birthUtcOffsetMinutes: 60,
      birthPlace: 'Warsaw, Poland',
      birthLatitude: 52.2297,
      birthLongitude: 21.0122,
    );
    final provider = _VesselProvider();
    await pumpShell(tester, vesselProvider: provider);
    await openVessel(tester);
    await openTheReading(tester);
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 100)),
    );
    await tester.pump();

    // Movements about the configuration, not one passage per card.
    expect(provider.calls, 1);
    expect(find.text('WHAT THE CHART KEEPS DOING'), findsOneWidget);
    expect(
      find.textContaining('These placements answer each other'),
      findsWidgets,
    );
    // And the whole chart went in one request rather than a card at a time.
    expect(provider.requestedKeys, contains('lifePath'));
    expect(provider.requestedKeys, contains('neptune'));
    await closeShell(tester);
  });

  testWidgets('Vessel refreshes after birth context changes', (tester) async {
    await pumpShell(tester);
    // The automatic compose has to finish before REFRESH can do anything:
    // the surface guards against composing twice at once, so tapping while
    // the first pass is still in flight is correctly a no-op.
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 600)),
    );
    await tester.pump();

    await tester.tap(find.text('VESSEL'));
    await tester.pump();
    await waitForWidget(
      tester,
      find.textContaining('Ascendant is not reliable'),
    );

    await db.updateBirthContext(
      birthTimeMinutes: 405,
      birthTimePrecision: 'exact',
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

  testWidgets('with no transport the reading waits, and the chart still reads',
      (tester) async {
    // No provider at all. There is no button to fail and no error to show:
    // what the device computed is on screen, and the writing says plainly
    // that it has not arrived. The next opening tries again.
    await db.updateProfileConsents(aiAllowed: true);
    await db.updateBirthContext(
      birthTimeMinutes: 405,
      birthTimePrecision: 'exact',
      birthUtcOffsetMinutes: 60,
      birthPlace: 'Warsaw, Poland',
      birthLatitude: 52.2297,
      birthLongitude: 21.0122,
    );
    await pumpShell(tester);
    await openVessel(tester);
    await openTheReading(tester);

    expect(find.textContaining('not written yet'), findsOneWidget);
    // The keywords are device arithmetic and never depended on a model.
    expect(find.textContaining('The Emperor'), findsWidgets);
    expect(find.text('ASCENDANT'), findsOneWidget);
    expect(find.text('COMPOSE READINGS'), findsNothing);
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

    // The time field only exists once the person says the time is known to
    // the minute — a remembered part of the day is a different answer.
    await tester.ensureVisible(find.text('To the minute'));
    await tester.tap(find.text('To the minute'));
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
        find.byKey(const ValueKey('journal-aware-guidance-allowed'));
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

    final aiOff = find.byKey(const ValueKey('ai-guidance-off'));
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
    // Waited for rather than slept through. This was a flat 30 ms delay racing
    // an asynchronous prepare, which passed on an idle machine and lost on a
    // busy one — it failed here while a device build was running, and failed on
    // the pristine tree too, so it was never about whatever was being changed
    // at the time. `waitForWidget` polls for up to twelve seconds and fails
    // with the same expectation if it never arrives.
    await waitForWidget(
      tester,
      find.text('Seven-day view prepared on this device.'),
    );
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
    // This harness has no account system, so no copy exists anywhere and the
    // unqualified warning is the accurate one. The other branch — a signed-in
    // device whose account still holds a restorable copy — says so instead, and
    // is covered in `account_section_test.dart`.
    expect(find.textContaining('Nothing here is recoverable'), findsOneWidget);
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
      // Lower-cased like the two destinations above it: all of these are drawn
      // in letterspaced caps, and a screen reader should be given the word
      // rather than the typography.
      //
      // `look deeper` used to be here. The three depths are the row now, and
      // each of them is a target in its own right — which is more to check,
      // not less.
      'guidance',
      'the body',
      'vessel',
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
      'movements': [
        {
          'title': 'What the chart keeps doing',
          'passage': 'These placements answer each other more than they '
              'answer anything outside.',
        },
        {
          'title': 'Where it pulls',
          'passage': 'These placements answer each other across the same '
              'quarter of the wheel.',
        },
        {
          'title': 'What is absent',
          'passage': 'These placements answer each other and leave one '
              'element unspoken.',
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
