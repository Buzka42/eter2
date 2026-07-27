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

  void validateGuidance({
    required List<String> sentences,
    required String primaryAction,
    GuidanceMode mode = GuidanceMode.balanced,
  }) {
    final combined = [...sentences, primaryAction].join(' ').toLowerCase();
    for (final phrase in _blockedPhrases) {
      if (combined.contains(phrase)) {
        throw AetherSafetyException('Unsafe guidance phrase: $phrase');
      }
    }
    if (combined.length > 3000) {
      throw const AetherSafetyException('Guidance is not concise');
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
