/// How many Arcana motion loops may hold a decoder at once.
///
/// Android allocates a hardware video decoder per playing loop, and the Vessel
/// runs out of decoders long before it runs out of cards: with the readings
/// and the chart both open there are **eighteen** plates in the column. Past
/// the device's limit `initialize()` simply fails, the plate keeps its still
/// art, and the result is that *some* positions animate and others do not —
/// an arbitrary subset, different on every build. That is the symptom the
/// owner reported.
///
/// So the budget is explicit and small, and slots go to the plates actually on
/// screen rather than to whichever built first. A refused slot costs nothing
/// but motion: `DEVELOPMENT.md` makes the still art mandatory underneath every
/// loop, so a plate without a decoder is a plate, not a gap.
///
/// Pure bookkeeping, with no reference to the plugin, so the rule can be
/// tested without a platform channel.
class ArcanaLoopBudget {
  ArcanaLoopBudget({this.capacity = 6})
      : assert(capacity > 0, 'A budget of nothing would disable every loop');

  /// Chosen well under the limit of the phones this ships to rather than at
  /// it: the decoders are shared with anything else the system is playing,
  /// and a loop that stutters is worse than a plate that is still.
  final int capacity;

  int _granted = 0;

  /// How many slots are held right now.
  int get granted => _granted;

  bool get exhausted => _granted >= capacity;

  /// Takes a slot, or returns false when the budget is spent.
  bool request() {
    if (exhausted) return false;
    _granted++;
    return true;
  }

  /// Hands a slot back. Idempotent by contract — callers release from both
  /// `dispose` and their own failure path, and the two can race.
  void release() {
    if (_granted == 0) return;
    _granted--;
  }
}

/// The one budget the running app shares.
///
/// Mutable so a test can install a smaller one; nothing in the product
/// replaces it.
ArcanaLoopBudget arcanaLoopBudget = ArcanaLoopBudget();
