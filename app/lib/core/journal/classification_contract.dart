import 'dart:convert';

class JournalClassificationException implements Exception {
  const JournalClassificationException(this.reason);
  final String reason;
}

class FoodEstimate {
  const FoodEstimate({
    required this.meal,
    required this.kcal,
    required this.confidence,
    required this.assumptions,
    this.proteinG,
    this.carbsG,
    this.fatG,
  });

  final String meal;
  final double kcal;
  final double? proteinG;
  final double? carbsG;
  final double? fatG;
  final double confidence;
  final List<String> assumptions;

  Map<String, Object?> toJson() => {
        'meal': meal,
        'kcal': kcal,
        'proteinG': proteinG,
        'carbsG': carbsG,
        'fatG': fatG,
        'confidence': confidence,
        'assumptions': assumptions,
      };
}

class LifestyleEstimate {
  const LifestyleEstimate({
    required this.kind,
    this.value,
    this.durationMinutes,
    this.note,
  });

  final String kind;
  final double? value;
  final double? durationMinutes;
  final String? note;

  Map<String, Object?> toJson() => {
        'kind': kind,
        'value': value,
        'durationMinutes': durationMinutes,
        'note': note,
      };
}

class JournalClassification {
  const JournalClassification({
    required this.status,
    required this.food,
    required this.lifestyle,
    this.clarifyingQuestion,
  });

  final String status;
  final List<FoodEstimate> food;
  final List<LifestyleEstimate> lifestyle;
  final String? clarifyingQuestion;

  Map<String, Object?> toJson() => {
        'status': status,
        'food': food.map((item) => item.toJson()).toList(),
        'lifestyle': lifestyle.map((item) => item.toJson()).toList(),
        'clarifyingQuestion': clarifyingQuestion,
      };
}

class JournalClassificationParser {
  const JournalClassificationParser();

  static const _statuses = {'classified', 'needsDetail'};
  static const _lifestyleKinds = {
    'mood',
    'stress',
    'recovery',
    'sleep',
    'meditation',
    'breathwork',
  };

  JournalClassification parse(String raw) {
    final Object? decoded;
    try {
      decoded = jsonDecode(raw);
    } on FormatException {
      throw const JournalClassificationException('Response is not JSON');
    }
    if (decoded is! Map<String, dynamic>) {
      throw const JournalClassificationException('Response must be an object');
    }

    final status = decoded['status'];
    final rawFood = decoded['food'];
    final rawLifestyle = decoded['lifestyle'];
    if (status is! String ||
        !_statuses.contains(status) ||
        rawFood is! List ||
        rawLifestyle is! List) {
      throw const JournalClassificationException(
        'Response is missing required classification fields',
      );
    }

    final question = decoded['clarifyingQuestion'];
    if (question != null && question is! String) {
      throw const JournalClassificationException(
        'Clarifying question must be text',
      );
    }
    if (status == 'needsDetail' &&
        (question is! String || question.trim().isEmpty)) {
      throw const JournalClassificationException(
        'A detail request requires one clarifying question',
      );
    }
    if (status == 'needsDetail' &&
        (rawFood.isNotEmpty || rawLifestyle.isNotEmpty)) {
      throw const JournalClassificationException(
        'Ambiguous entries cannot create derived records',
      );
    }

    return JournalClassification(
      status: status,
      food: List.unmodifiable(rawFood.map(_parseFood)),
      lifestyle: List.unmodifiable(rawLifestyle.map(_parseLifestyle)),
      clarifyingQuestion: question is String ? question.trim() : null,
    );
  }

  FoodEstimate _parseFood(Object? raw) {
    if (raw is! Map<String, dynamic>) {
      throw const JournalClassificationException('Food must be an object');
    }
    final meal = raw['meal'];
    final kcal = _number(raw['kcal']);
    final confidence = _number(raw['confidence']);
    final assumptions = raw['assumptions'];
    if (meal is! String ||
        meal.trim().isEmpty ||
        kcal == null ||
        kcal <= 0 ||
        kcal > 5000 ||
        confidence == null ||
        confidence < 0 ||
        confidence > 1 ||
        assumptions is! List ||
        assumptions.any((item) => item is! String)) {
      throw const JournalClassificationException('Invalid food estimate');
    }
    return FoodEstimate(
      meal: meal.trim(),
      kcal: kcal,
      proteinG: _macro(raw['proteinG']),
      carbsG: _macro(raw['carbsG']),
      fatG: _macro(raw['fatG']),
      confidence: confidence,
      assumptions: List.unmodifiable(assumptions.cast<String>()),
    );
  }

  LifestyleEstimate _parseLifestyle(Object? raw) {
    if (raw is! Map<String, dynamic>) {
      throw const JournalClassificationException(
        'Lifestyle item must be an object',
      );
    }
    final kind = raw['kind'];
    final value = _number(raw['value']);
    final duration = _number(raw['durationMinutes']);
    final note = raw['note'];
    if (kind is! String ||
        !_lifestyleKinds.contains(kind) ||
        (value != null && (value < 0 || value > 10)) ||
        (duration != null && (duration <= 0 || duration > 1440)) ||
        (note != null && note is! String)) {
      throw const JournalClassificationException('Invalid lifestyle estimate');
    }
    return LifestyleEstimate(
      kind: kind,
      value: value,
      durationMinutes: duration,
      note: note is String ? note.trim() : null,
    );
  }

  double? _macro(Object? value) {
    final number = _number(value);
    if (number != null && (number < 0 || number > 1000)) {
      throw const JournalClassificationException('Invalid macronutrient');
    }
    return number;
  }

  double? _number(Object? value) => value is num ? value.toDouble() : null;
}

abstract interface class JournalClassificationProvider {
  Future<String> classify(JournalClassificationRequest request);
}

class JournalClassificationRequest {
  const JournalClassificationRequest({
    required this.text,
    required this.source,
    required this.responseSchema,
    this.clarification,
  });

  final String text;
  final String source;
  final Map<String, Object> responseSchema;
  final String? clarification;
}

const journalClassificationSchema = <String, Object>{
  'status': <String>['classified', 'needsDetail'],
  'foodRequires': <String>['meal', 'kcal', 'confidence', 'assumptions'],
  'foodOptional': <String>['proteinG', 'carbsG', 'fatG'],
  'lifestyleKinds': <String>[
    'mood',
    'stress',
    'recovery',
    'sleep',
    'meditation',
    'breathwork',
  ],
  'unconfirmedFood': true,
};
