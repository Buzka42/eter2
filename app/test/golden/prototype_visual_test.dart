import 'package:eter/core/db/app_database.dart';
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
    Duration arrivalTime = const Duration(seconds: 4),
  }) async {
    eterSurfaceSize(tester, width, height);
    await tester.pumpWidget(
      eterPrototypeApp(
        db: db,
        register: register,
        textScale: textScale,
      ),
    );
    await tester.pump();
    // Asset decoding runs on the real async queue; give the first frame a
    // brief warm-up before advancing product animations in FakeAsync.
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 120)),
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

  testWidgets('dashboard day mid-arrival review capture', (tester) async {
    await pumpPrototype(
      tester,
      register: EterRegister.day,
      arrivalTime: const Duration(milliseconds: 360),
    );
    await expectLater(
      find.byType(ProviderScope),
      matchesGoldenFile('dashboard-day-mid-arrival-390x844.png'),
    );
    await disposePrototype(tester);
  });
}
