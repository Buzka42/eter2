import 'package:eter/core/db/app_database.dart';
import 'package:eter/core/controls.dart';
import 'package:eter/core/register.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/prototype_harness.dart';

void main() {
  late AppDatabase db;

  setUpAll(loadEterFonts);
  setUp(() async => db = await eterTestDatabase());

  Future<void> pumpPrototype(
    WidgetTester tester, {
    required EterRegister register,
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

  const dashboardSizes = <(int, int)>[
    (320, 568),
    (390, 844),
    (600, 960),
  ];

  for (final register in EterRegister.values) {
    final registerName = register.name;
    for (final size in dashboardSizes) {
      for (final textScale in const [1.0, 2.0]) {
        final scaleName = textScale.toStringAsFixed(0);
        final captureName =
            'dashboard-$registerName-${size.$1}x${size.$2}-text-$scaleName.png';
        testWidgets(captureName, (tester) async {
          await pumpPrototype(
            tester,
            register: register,
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

    final journalCaptureName = 'journal-$registerName-390x844.png';
    testWidgets('journal $registerName review capture', (tester) async {
      await pumpPrototype(tester, register: register);
      await tester.tap(find.text('JOURNAL'));
      await tester.pump(const Duration(milliseconds: 400));
      await tester.enterText(
        find.byType(TextField),
        'I slept badly, but the morning walk helped me feel clearer.',
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
  }

  for (final register in EterRegister.values) {
    final registerName = register.name;
    final captureName = 'guidance-expanded-$registerName-390x844.png';
    testWidgets(captureName, (tester) async {
      await pumpPrototype(tester, register: register);
      await tester.tap(find.text('LOOK DEEPER'));
      await tester.pump();
      await tester.tap(find.text('GUIDANCE'));
      await tester.pump();
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 120)),
      );
      await tester.pump();
      await expectLater(
        find.byType(ProviderScope),
        matchesGoldenFile(captureName),
      );
      await disposePrototype(tester);
    });
  }

  for (final register in EterRegister.values) {
    final registerName = register.name;
    final captureName = 'body-expanded-$registerName-390x844.png';
    testWidgets(captureName, (tester) async {
      await pumpPrototype(tester, register: register);
      await tester.tap(find.text('LOOK DEEPER'));
      await tester.pump();
      await tester.tap(find.text('THE BODY'));
      await tester.pump();
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 120)),
      );
      await tester.pump(const Duration(milliseconds: 700));
      await expectLater(
        find.byType(ProviderScope),
        matchesGoldenFile(captureName),
      );
      await disposePrototype(tester);
    });
  }

  testWidgets('body estimate correction day review capture', (tester) async {
    await pumpPrototype(tester, register: EterRegister.day);
    await tester.tap(find.text('LOOK DEEPER'));
    await tester.pump();
    await tester.tap(find.text('THE BODY'));
    await tester.pump();
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 120)),
    );
    await tester.pump(const Duration(milliseconds: 700));

    final review = find.text('REVIEW');
    tester
        .widget<EterAction>(
          find.ancestor(of: review, matching: find.byType(EterAction)),
        )
        .onPressed!
        .call();
    await tester.pump();
    final verticalScroll = find
        .byWidgetPredicate(
          (widget) =>
              widget is Scrollable &&
              widget.axisDirection == AxisDirection.down,
        )
        .hitTestable();
    final position = tester.state<ScrollableState>(verticalScroll).position;
    position.jumpTo(position.maxScrollExtent);
    await tester.pump();
    await expectLater(
      find.byType(ProviderScope),
      matchesGoldenFile('body-estimate-correction-day-390x844.png'),
    );
    await disposePrototype(tester);
  });

  testWidgets('body historical signals day review capture', (tester) async {
    await pumpPrototype(tester, register: EterRegister.day);
    await tester.tap(find.text('LOOK DEEPER'));
    await tester.pump();
    await tester.tap(find.text('THE BODY'));
    await tester.pump();
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 120)),
    );
    await tester.pump(const Duration(milliseconds: 700));
    final verticalScroll = find
        .byWidgetPredicate(
          (widget) =>
              widget is Scrollable &&
              widget.axisDirection == AxisDirection.down,
        )
        .hitTestable();
    tester.state<ScrollableState>(verticalScroll).position.jumpTo(650);
    await tester.pump();
    await expectLater(
      find.byType(ProviderScope),
      matchesGoldenFile('body-historical-signals-day-390x844.png'),
    );
    await disposePrototype(tester);
  });

  for (final register in EterRegister.values) {
    final registerName = register.name;
    final captureName = 'vessel-$registerName-390x844.png';
    testWidgets(captureName, (tester) async {
      await pumpPrototype(tester, register: register);
      await tester.tap(find.text('LOOK DEEPER'));
      await tester.pump();
      await tester.tap(find.text('VESSEL'));
      await tester.pump();
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 300)),
      );
      await tester.pump();
      await expectLater(
        find.byType(ProviderScope),
        matchesGoldenFile(captureName),
      );
      await disposePrototype(tester);
    });
  }

  testWidgets('vessel day 320x568 text 2 review capture', (tester) async {
    await pumpPrototype(
      tester,
      register: EterRegister.day,
      width: 320,
      height: 568,
      textScale: 2,
    );
    await tester.tap(find.text('LOOK DEEPER'));
    await tester.pump();
    await tester.tap(find.text('VESSEL'));
    await tester.pump();
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 300)),
    );
    await tester.pump();
    await expectLater(
      find.byType(ProviderScope),
      matchesGoldenFile('vessel-day-320x568-text-2.png'),
    );
    await disposePrototype(tester);
  });

  testWidgets('dashboard day mid-arrival review capture', (tester) async {
    await pumpPrototype(
      tester,
      register: EterRegister.day,
      reduceMotion: false,
      arrivalTime: const Duration(milliseconds: 360),
    );
    await expectLater(
      find.byType(ProviderScope),
      matchesGoldenFile('dashboard-day-mid-arrival-390x844.png'),
    );
    await disposePrototype(tester);
  });

  for (final register in EterRegister.values) {
    final registerName = register.name;
    for (final configuration in const [
      (390, 844, 1.0),
      (320, 568, 2.0),
    ]) {
      final scaleName = configuration.$3.toStringAsFixed(0);
      final captureName =
          'sanctum-$registerName-${configuration.$1}x${configuration.$2}'
          '-text-$scaleName.png';
      testWidgets(captureName, (tester) async {
        await pumpPrototype(
          tester,
          register: register,
          width: configuration.$1.toDouble(),
          height: configuration.$2.toDouble(),
          textScale: configuration.$3,
        );
        await tester.tap(find.bySemanticsLabel('Open Sanctum'));
        await tester.pump(const Duration(milliseconds: 400));
        await expectLater(
          find.byType(ProviderScope),
          matchesGoldenFile(captureName),
        );
        await disposePrototype(tester);
      });
    }
  }
}
