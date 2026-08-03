import 'package:eter/core/arrival.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap(Widget child, {bool reduceMotion = false}) {
  return MediaQuery(
    data: MediaQueryData(disableAnimations: reduceMotion),
    child: MaterialApp(
      home: Scaffold(
        body: DefaultTextStyle(
          style: const TextStyle(
            fontSize: 20,
            height: 1.4,
            color: Color(0xFF1C2B3A),
          ),
          child: child,
        ),
      ),
    ),
  );
}

/// Every span of every RichText is settled when none carries a foreground
/// paint — settled text is crisp by construction.
bool _allSettled(WidgetTester tester) {
  for (final rich in tester.widgetList<RichText>(find.byType(RichText))) {
    final root = rich.text;
    final stack = <InlineSpan>[root];
    while (stack.isNotEmpty) {
      final span = stack.removeLast();
      if (span is TextSpan) {
        if (span.style?.foreground != null) return false;
        stack.addAll(span.children ?? const <InlineSpan>[]);
      }
    }
  }
  return true;
}

void main() {
  const oneSentence = 'Keep one promise to yourself tonight.';
  const twoSentences =
      'Begin gently. Your body is asking for steadiness, not intensity.';

  testWidgets('words resolve progressively, then settle crisp', (tester) async {
    await tester.pumpWidget(_wrap(EterArrival.single(oneSentence)));
    await tester.pump();
    // Mid-arrival: some words still carry blur/alpha paint.
    expect(_allSettled(tester), isFalse);
    expect(tester.hasRunningAnimations, isTrue);

    // Six words in groups of two at a 190 ms stagger: 2*190 + 520 ms.
    await tester.pump(const Duration(milliseconds: 1300));
    expect(_allSettled(tester), isTrue);
    expect(tester.hasRunningAnimations, isFalse);
  });

  testWidgets('a long sentence arrives at the same rate, up to a ceiling',
      (tester) async {
    // The budget used to be fixed at `durSentence`, which made the stagger a
    // remainder: twenty words divided 1200 ms among seven groups and revealed
    // them about a hundred milliseconds apart. That is the "in batches,
    // quickly" the owner reported. The *rate* is what is held now, so a long
    // sentence takes longer — but never past the ceiling.
    const longSentence =
        'One two three four five six seven eight nine ten eleven twelve '
        'thirteen fourteen fifteen sixteen seventeen eighteen nineteen twenty.';
    await tester.pumpWidget(_wrap(EterArrival.single(longSentence)));
    await tester.pump();

    // Well past the old budget, it is still arriving — the point of the
    // change.
    await tester.pump(const Duration(milliseconds: 1250));
    expect(_allSettled(tester), isFalse);

    // And it still lands inside the ceiling, plus a frame of slack.
    await tester.pump(const Duration(milliseconds: 3200));
    expect(_allSettled(tester), isTrue);
  });

  testWidgets('a pause falls between sentences, not between words',
      (tester) async {
    await tester.pumpWidget(_wrap(EterArrival.single(twoSentences)));
    await tester.pump();
    // After the first sentence's 800 ms the second sentence must not have
    // begun: it is still fully transparent, so the whole passage is unsettled
    // but nothing new has appeared mid-pause.
    await tester.pump(const Duration(milliseconds: 820));
    expect(tester.hasRunningAnimations, isTrue);
    expect(_allSettled(tester), isFalse);
    // 800 + 280 pause + 800 for the second sentence.
    await tester.pump(const Duration(milliseconds: 1200));
    expect(_allSettled(tester), isTrue);
  });

  testWidgets('a tap resolves the whole passage immediately', (tester) async {
    var settled = false;
    await tester.pumpWidget(
      _wrap(EterArrival.single(twoSentences, onSettled: () => settled = true)),
    );
    await tester.pump(const Duration(milliseconds: 200));
    expect(_allSettled(tester), isFalse);

    await tester.tap(find.byType(EterArrival));
    await tester.pump();
    expect(_allSettled(tester), isTrue);
    expect(tester.hasRunningAnimations, isFalse);
    await tester.pump();
    expect(settled, isTrue);
  });

  testWidgets('reduced motion renders the final state on the first frame',
      (tester) async {
    await tester.pumpWidget(
      _wrap(EterArrival.single(twoSentences), reduceMotion: true),
    );
    await tester.pump();
    expect(_allSettled(tester), isTrue);
    expect(tester.hasRunningAnimations, isFalse);
    expect(find.text(twoSentences, findRichText: true), findsOneWidget);
  });

  testWidgets('playArrival false renders settled without a ticker',
      (tester) async {
    await tester.pumpWidget(
      _wrap(EterArrival.single(oneSentence, playArrival: false)),
    );
    await tester.pump();
    expect(_allSettled(tester), isTrue);
    expect(tester.hasRunningAnimations, isFalse);
  });

  testWidgets('passages arrive in order with a breath between them',
      (tester) async {
    await tester.pumpWidget(
      _wrap(
        EterArrival(passages: const [
          ArrivalPassage('Begin gently.'),
          ArrivalPassage('A short walk may restore more.'),
        ]),
      ),
    );
    await tester.pump();
    // One word in one group: 520 ms for the first passage, then a 520 ms
    // inter-passage pause, then the second passage's groups.
    await tester.pump(const Duration(milliseconds: 530));
    final richTexts =
        tester.widgetList<RichText>(find.byType(RichText)).toList();
    expect(richTexts.length, 2);
    TextSpan rootOf(RichText rich) => rich.text as TextSpan;
    // First passage settled; second not yet started (still painted).
    bool painted(InlineSpan span) {
      if (span is! TextSpan) return false;
      if (span.style?.foreground != null) return true;
      return (span.children ?? const <InlineSpan>[]).any(painted);
    }

    expect(painted(rootOf(richTexts[0])), isFalse);
    expect(painted(rootOf(richTexts[1])), isTrue);
  });

  testWidgets('the passage rises once and never jumps back', (tester) async {
    // Displacement used to be driven by whichever group had most recently
    // started, so it reset to its maximum every time a new group began: the
    // block dropped and rose repeatedly, which reads as a shake. It must
    // decrease monotonically to zero.
    const passage =
        'A long passage with enough words to fall into several groups, '
        'because the fault only appeared when a second group began.';
    await tester.pumpWidget(_wrap(EterArrival.single(passage)));
    await tester.pump();

    double displacement() {
      var lowest = 0.0;
      for (final transform
          in tester.widgetList<Transform>(find.byType(Transform))) {
        final dy = transform.transform.getTranslation().y;
        if (dy.abs() > lowest.abs()) lowest = dy;
      }
      return lowest;
    }

    var previous = displacement();
    expect(previous, greaterThan(0), reason: 'it should start displaced');

    // Long enough to cover the whole passage at the current cadence: two
    // sentences, a pause between them, and a stagger that is now a rate
    // rather than a remainder.
    for (var elapsed = 0; elapsed < 6000; elapsed += 50) {
      await tester.pump(const Duration(milliseconds: 50));
      final current = displacement();
      expect(
        current,
        lessThanOrEqualTo(previous + 0.001),
        reason: 'displacement rose again at ${elapsed}ms — that is the shake',
      );
      previous = current;
    }

    expect(previous, closeTo(0, 0.001));
  });
}
