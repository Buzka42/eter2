import 'package:eter/core/arcana/loop_budget.dart';
import 'package:flutter_test/flutter_test.dart';

/// The rule that stops the Vessel asking a phone for eighteen video decoders.
///
/// Pure bookkeeping, so it can be tested without a platform channel — which
/// matters, because `eterRunningTests()` disables the plugin outright and the
/// widget half of this can only be checked on a device.
void main() {
  test('grants up to capacity and no further', () {
    final budget = ArcanaLoopBudget(capacity: 3);
    expect(budget.request(), isTrue);
    expect(budget.request(), isTrue);
    expect(budget.request(), isTrue);
    expect(budget.granted, 3);
    expect(budget.exhausted, isTrue);
    expect(budget.request(), isFalse);
    expect(budget.request(), isFalse);
    // A refusal must not quietly bank a slot it did not give out.
    expect(budget.granted, 3);
  });

  test('a released slot goes to the next asker', () {
    final budget = ArcanaLoopBudget(capacity: 1);
    expect(budget.request(), isTrue);
    expect(budget.request(), isFalse);
    budget.release();
    expect(budget.granted, 0);
    // This is the scroll case: the plate that left gave its decoder to the
    // plate that arrived.
    expect(budget.request(), isTrue);
  });

  test('releasing more than was granted cannot mint slots', () {
    // Callers release from `dispose` and from their own failure path, and the
    // two race. Over-releasing has to be inert rather than lending the budget
    // capacity it never had.
    final budget = ArcanaLoopBudget(capacity: 2);
    budget.release();
    budget.release();
    expect(budget.granted, 0);
    expect(budget.request(), isTrue);
    budget.release();
    budget.release();
    budget.release();
    expect(budget.granted, 0);
    expect(budget.request(), isTrue);
    expect(budget.request(), isTrue);
    expect(budget.request(), isFalse);
  });

  test('the shipped budget is small enough to be a budget', () {
    // The Vessel can put eighteen plates in one column with the readings and
    // the chart both open. If this ever grows past what a mid-range phone
    // decodes at once, the symptom is silent: an arbitrary subset animates.
    expect(arcanaLoopBudget.capacity, lessThan(10));
    expect(arcanaLoopBudget.capacity, greaterThan(0));
  });
}
