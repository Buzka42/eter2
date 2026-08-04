import 'dart:convert';

import 'guidance_mode.dart';
import 'safety_policy.dart';

class AetherContractException implements Exception {
  const AetherContractException(this.reason);
  final String reason;
}

/// How long a dimension may run.
///
/// **Twice what it was**, at the owner's instruction on 4 August. The earlier
/// instruction — "twice the size" — had been read as font size and the display
/// type was doubled to 68 pt; seeing that on a real phone made the misreading
/// obvious in a second. What was wanted was more said, not larger letters.
///
/// The room is for specificity, and the prompt says so: a dimension that can
/// name what the records show *and* what they leave unknown needs more than
/// two sentences to do it without turning into a hedge.
const aetherMaximumDimensionSentences = 6;

/// The floor, and it is the half that actually changed anything.
///
/// Widening the ceiling alone did nothing: the first live composition after
/// the range opened to six came back with the same two sentences per dimension
/// it had always written. A model asked for "up to six" writes two. The length
/// had to be required, not permitted.
///
/// Three rather than four, because it is a floor and not the target — the
/// instruction asks for four or five — and because a genuinely empty day
/// should not be padded to a quota.
const aetherMinimumDimensionSentences = 3;

/// The synthesis is held shorter, at half again rather than double.
///
/// It is the line the home-screen widget shows, the line the Correspondence
/// may send to another person, and the only text most people read. It has to
/// stay sayable in one breath.
const aetherMaximumSynthesisSentences = 3;

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
  const AetherGuidance({required this.dimensions, this.recall});
  final List<AetherGuidanceDimension> dimensions;

  /// The telegraphic note this composition leaves for the days after it.
  ///
  /// Never shown to anyone. It is stored so tomorrow's request can carry it,
  /// which is the whole of how guidance stops repeating itself.
  final String? recall;
}

/// Everything the model was actually given, flattened, so its citations can be
/// checked against it.
///
/// The prompt has always told the model not to put a number in `evidence` that
/// was not in the context. Nothing checked, and `evidence` is rendered as
/// receipts — so an invented figure appeared on the surface wearing the
/// clothes of a measurement. This is the missing half of that pair: every
/// other rule stated in a prompt has an enforcement behind it, and this one
/// now does too.
class AetherEvidenceScope {
  const AetherEvidenceScope({
    required this.keys,
    required this.numbers,
    required this.strings,
  });

  /// Field names that appeared anywhere in the payload.
  final Set<String> keys;
  final Set<double> numbers;
  final Set<String> strings;

  /// Walks the encoded context and collects every key and leaf value.
  factory AetherEvidenceScope.fromContext(Map<String, Object?> context) {
    final keys = <String>{};
    final numbers = <double>{};
    final strings = <String>{};

    void walk(Object? node) {
      switch (node) {
        case Map<String, Object?> map:
          for (final entry in map.entries) {
            keys.add(entry.key);
            walk(entry.value);
          }
        case Iterable<Object?> list:
          list.forEach(walk);
        case num value:
          numbers.add(value.toDouble());
        case String value:
          strings.add(value);
        default:
          return;
      }
    }

    walk(context);
    return AetherEvidenceScope(keys: keys, numbers: numbers, strings: strings);
  }

  /// Throws unless every key and leaf value in [evidence] came from the
  /// context.
  ///
  /// Deliberately exact on numbers: 402 is a citation, 400 is a paraphrase of
  /// one, and a paraphrased measurement is the thing this exists to catch. The
  /// prompt tells the model to copy digit for digit and that a composition
  /// failing this is discarded, so a rejection here is the model ignoring an
  /// instruction rather than a near miss.
  void validate(String dimension, Map<String, Object?> evidence) {
    void check(Object? node, String path) {
      switch (node) {
        case Map<String, Object?> map:
          for (final entry in map.entries) {
            _requireKey(dimension, entry.key);
            check(entry.value, entry.key);
          }
        case Iterable<Object?> list:
          for (final item in list) {
            check(item, path);
          }
        case num value:
          if (!numbers.contains(value.toDouble())) {
            throw AetherContractException(
              '$dimension cites $path = $value, which is not in the context',
            );
          }
        case String value:
          if (value.trim().isEmpty) return;
          if (!strings.contains(value)) {
            throw AetherContractException(
              '$dimension cites $path = "$value", which is not in the context',
            );
          }
        default:
          return;
      }
    }

    for (final entry in evidence.entries) {
      _requireKey(dimension, entry.key);
      check(entry.value, entry.key);
    }
  }

  void _requireKey(String dimension, String key) {
    if (keys.contains(key)) return;
    throw AetherContractException(
      '$dimension cites a field that was not in the context: $key',
    );
  }
}

/// Accepts provider output only after strict shape and safety validation.
class AetherGuidanceParser {
  const AetherGuidanceParser({this.safetyPolicy = const AetherSafetyPolicy()});

  final AetherSafetyPolicy safetyPolicy;
  static const dimensionKeys = {'synthesis', 'health', 'mind', 'spirit'};

  /// The note field, which is not a dimension and is not rendered.
  static const recallKey = 'recall';

  /// The ceiling the prompt states. A note longer than this is not a note.
  static const maxRecallCharacters = 160;

  /// [evidence] is the context the model was given. When it is supplied, every
  /// citation is checked against it; when it is not, shape validation runs
  /// alone — which is what the offline composition and the older tests need.
  AetherGuidance parse(
    String raw, {
    required GuidanceMode mode,
    AetherEvidenceScope? evidence,
  }) {
    final Object? decoded;
    try {
      decoded = jsonDecode(raw);
    } on FormatException {
      throw const AetherContractException('Provider response is not JSON');
    }
    if (decoded is! Map<String, dynamic> ||
        decoded.keys
            .toSet()
            .difference({...dimensionKeys, recallKey})
            .isNotEmpty ||
        !decoded.keys.toSet().containsAll(dimensionKeys)) {
      throw const AetherContractException(
        'Provider response must contain exactly four guidance dimensions',
      );
    }

    // Optional in the parser and required in the schema, deliberately. A note
    // is for the days after this one; a day that arrives without one is a day
    // with no memory of itself, which is a smaller loss than no guidance at
    // all. Older stored responses have none either.
    final rawRecall = decoded[recallKey];
    if (rawRecall != null && rawRecall is! String) {
      throw const AetherContractException('The recall note must be text');
    }
    final recall = (rawRecall as String?)?.trim();
    if (recall != null &&
        recall.isNotEmpty &&
        recall.length > maxRecallCharacters) {
      throw const AetherContractException(
        'The recall note must be at most $maxRecallCharacters characters',
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
      // The synthesis is capped shorter than the three dimensions, for the
      // reasons on those two constants. Checked here as well as in the schema,
      // because the schema is the endpoint's promise and this is the wall.
      final ceiling = key == 'synthesis'
          ? aetherMaximumSynthesisSentences
          : aetherMaximumDimensionSentences;
      if (rawSentences.isEmpty ||
          rawSentences.length > ceiling ||
          rawSentences.any((sentence) => sentence is! String)) {
        throw AetherContractException(
          '$key requires between one and $ceiling sentences',
        );
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
      final cited = value['evidence'];
      if (cited != null && cited is! Map<String, dynamic>) {
        throw AetherContractException('$key evidence must be an object');
      }
      if (cited is Map<String, dynamic>) {
        evidence?.validate(key, cited);
      }
      dimensions.add(AetherGuidanceDimension(
        key: key,
        sentences: List.unmodifiable(sentences),
        primaryAction: action,
        evidence: cited == null
            ? null
            : Map<String, Object?>.unmodifiable(cited as Map<String, dynamic>),
      ));
    }
    if (recall != null && recall.isNotEmpty) {
      // Held to the same phrase list as anything else composed here. It is
      // never shown, but it is read back into the next request, so an unsafe
      // note would seed the next composition.
      safetyPolicy.validateGuidance(
        sentences: [recall],
        primaryAction: recall,
        mode: mode,
      );
    }

    return AetherGuidance(
      dimensions: List.unmodifiable(dimensions),
      recall: recall == null || recall.isEmpty ? null : recall,
    );
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
