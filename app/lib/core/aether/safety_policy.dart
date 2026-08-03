import 'guidance_mode.dart';

class AetherSafetyException implements Exception {
  const AetherSafetyException(this.reason);
  final String reason;

  @override
  String toString() => 'AetherSafetyException: $reason';
}

class AetherSafetyPolicy {
  const AetherSafetyPolicy();

  static const _blockedPhrases = [
    'stop taking your medication',
    'change your medication',
    'ignore the pain',
    'push through the pain',
    'you have been diagnosed',
    'you definitely have',
    'do not seek medical',
    'less than 1200 calories',
    'less than 1200 kcal',
    'punish yourself',
    'must consult aether',
  ];

  /// The safety rules, without the conciseness rule.
  ///
  /// [validateGuidance] refuses anything past 3000 characters, and that is
  /// right for guidance: the day's reading is a few sentences and a long one
  /// has lost the plot. It is wrong for the Vessel's two synopses, which the
  /// owner asked to be the longest parts of the surface — applying a brevity
  /// rule to them would be the product quietly disagreeing with its own
  /// instruction, and the failure would look like a model error rather than a
  /// policy choice.
  ///
  /// Everything that is actually about safety still applies: the blocked
  /// phrases, and the fated phrasing that grounded mode does not allow.
  void validateReading(
    String passage, {
    GuidanceMode mode = GuidanceMode.balanced,
  }) {
    _validate(passage.toLowerCase(), mode: mode);
  }

  void validateGuidance({
    required List<String> sentences,
    required String primaryAction,
    GuidanceMode mode = GuidanceMode.balanced,
  }) {
    final combined = [...sentences, primaryAction].join(' ').toLowerCase();
    if (combined.length > 3000) {
      throw const AetherSafetyException('Guidance is not concise');
    }
    _validate(combined, mode: mode);
  }

  void _validate(String combined, {required GuidanceMode mode}) {
    for (final phrase in _blockedPhrases) {
      if (combined.contains(phrase)) {
        throw AetherSafetyException('Unsafe guidance phrase: $phrase');
      }
    }
    if (mode == GuidanceMode.grounded) {
      const fatedPhrases = [
        'the stars mean you must',
        'the stars require',
        'your chart means you must',
        'your destiny requires',
        'you are fated to',
      ];
      for (final phrase in fatedPhrases) {
        if (combined.contains(phrase)) {
          throw AetherSafetyException(
            'Fated phrasing is not allowed in grounded mode: $phrase',
          );
        }
      }
    }
  }
}
