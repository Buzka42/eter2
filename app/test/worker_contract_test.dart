import 'dart:io';

import 'package:eter/core/ai/transport.dart';
import 'package:flutter_test/flutter_test.dart';

/// The client and the endpoint have to agree about what a call is called.
///
/// They drifted, and the drift was invisible from both sides. `letter` was
/// added to `EterAiCall` and to `CALLS` in the same commit, the app was built
/// and tested and shipped to a device — and the worker deployed two days
/// earlier answered `400 Unknown call: letter`. Nothing in the repository was
/// wrong; the *running* endpoint was behind, and no test could tell, because
/// each half was self-consistent.
///
/// This cannot catch a stale deployment — only `wrangler deploy` fixes that.
/// What it catches is the half of the problem that lives in the repository: a
/// call added to one side and forgotten on the other, which is what makes a
/// stale deployment expensive to diagnose rather than merely stale.
void main() {
  test('every call the app can make is one the worker will accept', () {
    final worker = File('../server/worker.js');
    if (!worker.existsSync()) {
      markTestSkipped('server/worker.js is not beside the app');
      return;
    }
    final source = worker.readAsStringSync();

    // `const CALLS = new Map([ ['guidance', 0.7], … ]);`
    final block = RegExp(r'const CALLS = new Map\(\[(.*?)\]\)', dotAll: true)
        .firstMatch(source);
    expect(block, isNotNull, reason: 'CALLS is not where this test expects it');
    final declared = RegExp(r"\['([a-zA-Z]+)',\s*([\d.]+)\]")
        .allMatches(block!.group(1)!)
        .map((match) => match.group(1)!)
        .toSet();

    expect(
      EterAiCall.values.map((call) => call.wireName).toSet(),
      declared,
      reason: 'The app and server/worker.js disagree about the call names. '
          'Adding a call means touching both, and then deploying.',
    );
  });

  test('every call has a temperature, and the writing calls share one', () {
    final worker = File('../server/worker.js');
    if (!worker.existsSync()) {
      markTestSkipped('server/worker.js is not beside the app');
      return;
    }
    final block = RegExp(r'const CALLS = new Map\(\[(.*?)\]\)', dotAll: true)
        .firstMatch(worker.readAsStringSync())!;
    final temperatures = {
      for (final match
          in RegExp(r"\['([a-zA-Z]+)',\s*([\d.]+)\]").allMatches(block.group(1)!))
        match.group(1)!: double.parse(match.group(2)!),
    };

    // `ENGINEERING.md` §2: interpretation 0.1, day story 0.5, the writing calls
    // 0.7. A call that quietly acquired a different temperature would change
    // what Aether writes without changing a prompt or a version.
    expect(temperatures['journalInterpretation'], 0.1);
    expect(temperatures['journalDayStory'], 0.5);
    for (final writing in const [
      'guidance',
      'vesselReadings',
      'positions',
      'letter',
    ]) {
      expect(temperatures[writing], 0.7, reason: writing);
    }
  });
}
