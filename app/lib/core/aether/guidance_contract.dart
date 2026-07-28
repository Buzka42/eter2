import 'dart:convert';

import 'guidance_mode.dart';
import 'safety_policy.dart';

class AetherContractException implements Exception {
  const AetherContractException(this.reason);
  final String reason;
}

class AetherGuidanceDimension {
  const AetherGuidanceDimension({
    required this.key,
    required this.sentences,
    required this.primaryAction,
    this.evidence,
  });

  final String key;
  final List<String> sentences;
  final String primaryAction;
  final Map<String, Object?>? evidence;

  Map<String, Object?> toJson() => {
        'sentences': sentences,
        'primaryAction': primaryAction,
      };
}

class AetherGuidance {
  const AetherGuidance({required this.dimensions});
  final List<AetherGuidanceDimension> dimensions;
}

/// Accepts provider output only after strict shape and safety validation.
class AetherGuidanceParser {
  const AetherGuidanceParser({this.safetyPolicy = const AetherSafetyPolicy()});

  final AetherSafetyPolicy safetyPolicy;
  static const dimensionKeys = {'synthesis', 'health', 'mind', 'spirit'};

  AetherGuidance parse(String raw, {required GuidanceMode mode}) {
    final Object? decoded;
    try {
      decoded = jsonDecode(raw);
    } on FormatException {
      throw const AetherContractException('Provider response is not JSON');
    }
    if (decoded is! Map<String, dynamic> ||
        decoded.keys.toSet().difference(dimensionKeys).isNotEmpty ||
        !decoded.keys.toSet().containsAll(dimensionKeys)) {
      throw const AetherContractException(
        'Provider response must contain exactly four guidance dimensions',
      );
    }

    final dimensions = <AetherGuidanceDimension>[];
    for (final key in dimensionKeys) {
      final value = decoded[key];
      if (value is! Map<String, dynamic> ||
          value['sentences'] is! List ||
          value['primaryAction'] is! String) {
        throw AetherContractException('Invalid $key guidance shape');
      }
      final rawSentences = value['sentences'] as List;
      if (rawSentences.isEmpty ||
          rawSentences.length > 3 ||
          rawSentences.any((sentence) => sentence is! String)) {
        throw AetherContractException('$key requires one to three sentences');
      }
      final sentences =
          rawSentences.cast<String>().map((s) => s.trim()).toList();
      final action = (value['primaryAction'] as String).trim();
      if (sentences.any((sentence) => sentence.isEmpty) || action.isEmpty) {
        throw AetherContractException('$key contains empty guidance');
      }
      safetyPolicy.validateGuidance(
        sentences: sentences,
        primaryAction: action,
        mode: mode,
      );
      final evidence = value['evidence'];
      if (evidence != null && evidence is! Map<String, dynamic>) {
        throw AetherContractException('$key evidence must be an object');
      }
      dimensions.add(AetherGuidanceDimension(
        key: key,
        sentences: List.unmodifiable(sentences),
        primaryAction: action,
        evidence: evidence == null
            ? null
            : Map<String, Object?>.unmodifiable(evidence),
      ));
    }
    return AetherGuidance(dimensions: List.unmodifiable(dimensions));
  }
}

abstract interface class AetherProvider {
  Future<String> compose(AetherProviderRequest request);
}

class AetherProviderRequest {
  const AetherProviderRequest({
    required this.system,
    required this.context,
    required this.responseSchema,
  });

  /// The instruction, built on the device by `EterPrompts.guidance`. It travels
  /// with the request so that the endpoint forwards a complete prompt rather
  /// than composing one of its own — the voice is the product, and it does not
  /// live on a server.
  final String system;

  final Map<String, Object> context;
  final Map<String, Object> responseSchema;
}

const aetherResponseSchema = <String, Object>{
  'dimensions': <String>['synthesis', 'health', 'mind', 'spirit'],
  'sentencesPerDimension': <int>[1, 3],
  'primaryActionRequired': true,
  'additionalDimensionsAllowed': false,
};
