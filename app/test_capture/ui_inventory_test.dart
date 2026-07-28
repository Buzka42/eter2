@Tags(['capture'])
library;

import 'package:drift/drift.dart' show Value, driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:eter/core/db/app_database.dart';
import 'package:eter/core/register.dart';
import 'package:eter/core/theme.dart';
import 'package:eter/features/onboarding/onboarding_flow.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../test/helpers/prototype_harness.dart';

/// The UI inventory: every surface and state, captured for review.
///
/// This is **not** a golden suite. Goldens defend a rendering against
/// regression; this walks the product and writes what it finds to
/// `artifacts/ui/` so the interface can be audited as a whole — including the
/// states a golden would never bother to pin, like a half-open editor or an
/// empty first day.
///
/// It is tagged `capture` and excluded from the default run, because it
/// asserts nothing. Refresh the inventory with:
///
///     flutter test test_capture --update-goldens
///
/// It lives outside `test/` so `flutter test` never picks it up: an inventory
/// that asserts nothing has no business failing a suite.
///
/// Captures land outside the app tree (repo `artifacts/`, gitignored) so the
/// review material never masquerades as a test fixture.
void main() {
  setUpAll(loadEterFonts);

  Future<void> shot(WidgetTester tester, String name) async {
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('../../artifacts/ui/$name.png'),
    );
  }

  Future<void> settleAssets(WidgetTester tester) async {
    // Asset decoding runs on the real async queue; product animation runs
    // under FakeAsync. Give the first frame a warm-up, then let the arrival
    // finish.
    await tester.pump();
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 400)),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 4));
  }

  Future<void> dispose(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
  }

  // Every database is built inside `runAsync`. Seeding is real sqlite I/O,
  // and a test body runs under FakeAsync, where that future never completes —
  // the first version of this file hung for five minutes per case because of
  // exactly that.
  Future<AppDatabase> emptyDatabase(WidgetTester tester) async {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
    return (await tester.runAsync(() async => AppDatabase(NativeDatabase.memory())))!;
  }

  /// A profile with no history behind it: the first real day.
  Future<AppDatabase> freshDatabase(WidgetTester tester) async {
    final db = await emptyDatabase(tester);
    await tester.runAsync(() => db.saveProfile(
          ProfilesCompanion.insert(
            dob: DateTime(1994, 3, 12),
            sex: 'other',
            weightKg: 68,
            heightCm: const Value(172),
            units: 'metric',
          ),
        ));
    return db;
  }

  /// The lived-in fixture store.
  Future<AppDatabase> seededDatabase(WidgetTester tester) async =>
      (await tester.runAsync(eterTestDatabase))!;

  Future<void> pumpShell(
    WidgetTester tester, {
    required AppDatabase db,
    EterRegister register = EterRegister.day,
    double width = 390,
    double height = 844,
    double textScale = 1,
  }) async {
    eterSurfaceSize(tester, width, height);
    await tester.pumpWidget(
      eterPrototypeApp(
        db: db,
        register: register,
        textScale: textScale,
        reduceMotion: true,
      ),
    );
    await settleAssets(tester);
  }

  Future<void> tapText(WidgetTester tester, String label) async {
    await tester.ensureVisible(find.text(label).first);
    await tester.tap(find.text(label).first);
    await tester.pump();
    // A section's own streams and futures resolve on the real queue. Below the
    // fold that resolution is hidden by scrolling; on a tall viewport
    // everything builds at once, so the wait has to be explicit or the capture
    // records instruments in their empty first frame.
    for (var i = 0; i < 3; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 150)),
      );
      await tester.pump(const Duration(milliseconds: 400));
    }
  }

  Future<void> scrollTo(WidgetTester tester, double offset) async {
    final scrollable = find
        .byWidgetPredicate(
          (widget) =>
              widget is Scrollable && widget.axisDirection == AxisDirection.down,
        )
        .hitTestable();
    tester.state<ScrollableState>(scrollable).position.jumpTo(offset);
    await tester.pump();
  }

  // ---------------------------------------------------------------------
  // Arrival — what a new user meets
  // ---------------------------------------------------------------------

  for (final step in [0, 1, 2]) {
    testWidgets('onboarding step ${step + 1}', (tester) async {
      final db = await emptyDatabase(tester);
      eterSurfaceSize(tester, 390, 844);
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: EterTheme.day(),
            home: EterRegisterScope(
              register: EterRegister.day,
              child: OnboardingFlow(
                database: db,
                profile: null,
                onComplete: () {},
              ),
            ),
          ),
        ),
      );
      await settleAssets(tester);
      for (var i = 0; i < step; i++) {
        // Step 2 validates before it will advance, so fill the birth date.
        if (i == 1) {
          final fields = find.byType(TextField);
          if (fields.evaluate().isNotEmpty) {
            await tester.enterText(fields.first, '12');
          }
        }
        await tapText(tester, 'CONTINUE');
      }
      await shot(tester, 'onboarding-${step + 1}');
      await dispose(tester);
    });
  }

  // ---------------------------------------------------------------------
  // The empty product — a profile with no history
  // ---------------------------------------------------------------------

  testWidgets('first day, dashboard', (tester) async {
    await pumpShell(tester, db: await freshDatabase(tester));
    await shot(tester, 'empty-dashboard-day');
    await dispose(tester);
  });

  testWidgets('first day, journal', (tester) async {
    await pumpShell(tester, db: await freshDatabase(tester));
    await tapText(tester, 'JOURNAL');
    await shot(tester, 'empty-journal-day');
    await dispose(tester);
  });

  testWidgets('first day, body has nothing to report', (tester) async {
    await pumpShell(tester, db: await freshDatabase(tester));
    await tapText(tester, 'LOOK DEEPER');
    await tapText(tester, 'THE BODY');
    await shot(tester, 'empty-body-day');
    await dispose(tester);
  });

  // ---------------------------------------------------------------------
  // The lived-in product, both registers
  // ---------------------------------------------------------------------

  for (final register in EterRegister.values) {
    final name = register.name;

    testWidgets('dashboard resting · $name', (tester) async {
      await pumpShell(tester, db: await seededDatabase(tester), register: register);
      await shot(tester, 'dashboard-resting-$name');
      await dispose(tester);
    });

    testWidgets('look deeper chooser · $name', (tester) async {
      await pumpShell(tester, db: await seededDatabase(tester), register: register);
      await tapText(tester, 'LOOK DEEPER');
      await shot(tester, 'chooser-$name');
      await dispose(tester);
    });

    testWidgets('guidance expanded · $name', (tester) async {
      await pumpShell(tester, db: await seededDatabase(tester), register: register);
      await tapText(tester, 'LOOK DEEPER');
      await tapText(tester, 'GUIDANCE');
      await shot(tester, 'guidance-$name');
      await dispose(tester);
    });

    testWidgets('journal · $name', (tester) async {
      await pumpShell(tester, db: await seededDatabase(tester), register: register);
      await tapText(tester, 'JOURNAL');
      await shot(tester, 'journal-$name');
      await dispose(tester);
    });

    testWidgets('vessel · $name', (tester) async {
      await pumpShell(tester, db: await seededDatabase(tester), register: register);
      await tapText(tester, 'LOOK DEEPER');
      await tapText(tester, 'VESSEL');
      await shot(tester, 'vessel-top-$name');
      await scrollTo(tester, 420);
      await shot(tester, 'vessel-readings-$name');
      await dispose(tester);
    });

    for (final (index, offset) in [(1, 0.0), (2, 420.0), (3, 900.0)]) {
      testWidgets('body expanded $index · $name', (tester) async {
        await pumpShell(
          tester,
          db: await seededDatabase(tester),
          register: register,
        );
        await tapText(tester, 'LOOK DEEPER');
        await tapText(tester, 'THE BODY');
        if (offset > 0) await scrollTo(tester, offset);
        await shot(tester, 'body-$index-$name');
        await dispose(tester);
      });
    }

    for (final (index, offset) in [(1, 0.0), (2, 700.0), (3, 1500.0)]) {
      testWidgets('sanctum $index · $name', (tester) async {
        await pumpShell(
          tester,
          db: await seededDatabase(tester),
          register: register,
        );
        await tester.tap(find.bySemanticsLabel('Open Sanctum'));
        await tester.pump(const Duration(milliseconds: 400));
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 300)),
        );
        await tester.pump();
        if (offset > 0) await scrollTo(tester, offset);
        await shot(tester, 'sanctum-$index-$name');
        await dispose(tester);
      });
    }
  }

  // ---------------------------------------------------------------------
  // Every capture surface, opened
  // ---------------------------------------------------------------------

  testWidgets('journal check-in rail', (tester) async {
    await pumpShell(tester, db: await seededDatabase(tester));
    await tapText(tester, 'JOURNAL');
    await tapText(tester, 'MOOD');
    await shot(tester, 'journal-check-in');
    await dispose(tester);
  });

  testWidgets('journal, an earlier page', (tester) async {
    await pumpShell(tester, db: await seededDatabase(tester));
    await tapText(tester, 'JOURNAL');
    await tester.tap(find.bySemanticsLabel('Previous journal day'));
    await tester.pump(const Duration(milliseconds: 400));
    await shot(tester, 'journal-earlier-day');
    await dispose(tester);
  });

  // ---------------------------------------------------------------------
  // Whole surfaces. A phone viewport crops every expansion, which is exactly
  // what makes a scrolling surface hard to audit: you review the fold, not the
  // composition. These use a tall viewport so a surface can be read entire.
  // Layout is genuinely responsive, so nothing here is a lie — it is the same
  // build at a taller window.
  // ---------------------------------------------------------------------

  for (final register in EterRegister.values) {
    final name = register.name;

    testWidgets('whole body · $name', (tester) async {
      await pumpShell(
        tester,
        db: await seededDatabase(tester),
        register: register,
        height: 2400,
      );
      await tapText(tester, 'LOOK DEEPER');
      await tapText(tester, 'THE BODY');
      await shot(tester, 'whole-body-$name');
      await dispose(tester);
    });

    testWidgets('whole vessel · $name', (tester) async {
      await pumpShell(
        tester,
        db: await seededDatabase(tester),
        register: register,
        height: 2400,
      );
      await tapText(tester, 'LOOK DEEPER');
      await tapText(tester, 'VESSEL');
      await shot(tester, 'whole-vessel-$name');
      await dispose(tester);
    });

    testWidgets('whole sanctum · $name', (tester) async {
      await pumpShell(
        tester,
        db: await seededDatabase(tester),
        register: register,
        height: 2400,
      );
      await tester.tap(find.bySemanticsLabel('Open Sanctum'));
      await tester.pump(const Duration(milliseconds: 400));
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 300)),
      );
      await tester.pump();
      await shot(tester, 'whole-sanctum-$name');
      await dispose(tester);
    });
  }

  testWidgets('whole journal, writing', (tester) async {
    await pumpShell(
      tester,
      db: await seededDatabase(tester),
      height: 1600,
    );
    await tapText(tester, 'JOURNAL');
    await shot(tester, 'whole-journal-day');
    await dispose(tester);
  });

  testWidgets('whole onboarding, consent step', (tester) async {
    final db = await emptyDatabase(tester);
    eterSurfaceSize(tester, 390, 1400);
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: EterTheme.day(),
          home: EterRegisterScope(
            register: EterRegister.day,
            child: OnboardingFlow(
              database: db,
              profile: null,
              onComplete: () {},
            ),
          ),
        ),
      ),
    );
    await settleAssets(tester);
    await tapText(tester, 'CONTINUE');
    await shot(tester, 'whole-onboarding-2');
    await dispose(tester);
  });

  // ---------------------------------------------------------------------
  // Stress: the smallest phone at the largest type
  // ---------------------------------------------------------------------

  testWidgets('dashboard at 320 dp, 200% type', (tester) async {
    await pumpShell(
      tester,
      db: await seededDatabase(tester),
      width: 320,
      height: 568,
      textScale: 2,
    );
    await shot(tester, 'stress-dashboard-320-200');
    await dispose(tester);
  });

  testWidgets('body at 320 dp, 200% type', (tester) async {
    await pumpShell(
      tester,
      db: await seededDatabase(tester),
      width: 320,
      height: 568,
      textScale: 2,
    );
    await tapText(tester, 'LOOK DEEPER');
    await tapText(tester, 'THE BODY');
    await shot(tester, 'stress-body-320-200');
    await dispose(tester);
  });
}
