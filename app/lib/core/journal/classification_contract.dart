import 'dart:convert';

import '../i18n/language.dart';

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

/// A weight the person stated in prose. Never an estimate — a body weight is
/// either read off a scale or it is not a number, so there is no confidence
/// field here and no assumptions to review.
class WeightObservation {
  const WeightObservation({required this.kg});

  final double kg;

  Map<String, Object?> toJson() => {'kg': kg};
}

/// Something they said they did with their body, with the energy it cost
/// estimated the way a meal's is: reviewable, and shown with the guesses it
/// rests on.
class ActivityObservation {
  const ActivityObservation({
    required this.activity,
    required this.durationMinutes,
    required this.kcal,
    required this.confidence,
    required this.assumptions,
  });

  final String activity;
  final int durationMinutes;
  final double kcal;
  final double confidence;
  final List<String> assumptions;

  Map<String, Object?> toJson() => {
        'activity': activity,
        'durationMinutes': durationMinutes,
        'kcal': kcal,
        'confidence': confidence,
        'assumptions': assumptions,
      };
}

class StrengthSetObservation {
  const StrengthSetObservation({required this.reps, this.loadKg});

  final int reps;
  final double? loadKg;

  Map<String, Object?> toJson() => {
        'reps': reps,
        if (loadKg != null) 'loadKg': loadKg,
      };
}

/// Lifted work, as written. The energy is not estimated here: the strength
/// service derives it from body weight and the work itself, which is the same
/// arithmetic the Register uses and the only one that agrees with it.
class StrengthObservation {
  const StrengthObservation({required this.name, required this.sets});

  final String name;
  final List<StrengthSetObservation> sets;

  Map<String, Object?> toJson() => {
        'name': name,
        'sets': sets.map((set) => set.toJson()).toList(),
      };
}

class JournalClassification {
  const JournalClassification({
    required this.status,
    required this.food,
    required this.lifestyle,
    this.weight = const [],
    this.activity = const [],
    this.strength = const [],
    this.clarifyingQuestion,
  });

  final String status;
  final List<FoodEstimate> food;
  final List<LifestyleEstimate> lifestyle;
  final List<WeightObservation> weight;
  final List<ActivityObservation> activity;
  final List<StrengthObservation> strength;
  final String? clarifyingQuestion;

  /// True when the page produced nothing at all to commit.
  bool get isEmpty =>
      food.isEmpty &&
      lifestyle.isEmpty &&
      weight.isEmpty &&
      activity.isEmpty &&
      strength.isEmpty;

  Map<String, Object?> toJson() => {
        'status': status,
        'food': food.map((item) => item.toJson()).toList(),
        'lifestyle': lifestyle.map((item) => item.toJson()).toList(),
        'weight': weight.map((item) => item.toJson()).toList(),
        'activity': activity.map((item) => item.toJson()).toList(),
        'strength': strength.map((item) => item.toJson()).toList(),
        'clarifyingQuestion': clarifyingQuestion,
      };
}

class JournalClassificationParser {
  const JournalClassificationParser();

  static const _statuses = {'classified', 'needsDetail'};
  /// What a page may report about the inside of a day.
  ///
  /// Deliberately wider than the margin's check-in, which offers three
  /// readings and two practices. A page is where someone says the week is
  /// heavy, that they felt adrift, that a conversation went badly — and a
  /// companion that could only record mood, stress and recovery threw all of
  /// that away at the point of reading it.
  ///
  /// `carrying` is the open one: whatever is weighing on them. It is stored as
  /// context and never as a problem the product then tries to solve.
  static const _lifestyleKinds = {
    'mood',
    'stress',
    'recovery',
    'energy',
    'focus',
    'motivation',
    'social',
    'spirit',
    'carrying',
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
    // The three shapes added when capture left the Dashboard. Absent is the
    // normal case — most pages mention none of them — so each defaults to
    // empty rather than being required of every response.
    final rawWeight = decoded['weight'] ?? const [];
    final rawActivity = decoded['activity'] ?? const [];
    final rawStrength = decoded['strength'] ?? const [];
    if (rawWeight is! List || rawActivity is! List || rawStrength is! List) {
      throw const JournalClassificationException(
        'Weight, activity and strength must be lists when present',
      );
    }

    if (status == 'needsDetail' &&
        (rawFood.isNotEmpty ||
            rawLifestyle.isNotEmpty ||
            rawWeight.isNotEmpty ||
            rawActivity.isNotEmpty ||
            rawStrength.isNotEmpty)) {
      throw const JournalClassificationException(
        'Ambiguous entries cannot create derived records',
      );
    }

    return JournalClassification(
      status: status,
      food: List.unmodifiable(rawFood.map(_parseFood)),
      lifestyle: List.unmodifiable(rawLifestyle.map(_parseLifestyle)),
      weight: List.unmodifiable(rawWeight.map(_parseWeight)),
      activity: List.unmodifiable(rawActivity.map(_parseActivity)),
      strength: List.unmodifiable(rawStrength.map(_parseStrength)),
      clarifyingQuestion: question is String ? question.trim() : null,
    );
  }

  /// The same bounds `ManualWeightService` enforces. A page that says "I feel
  /// heavy today" must not become a 0 kg reading.
  WeightObservation _parseWeight(Object? raw) {
    if (raw is! Map<String, dynamic>) {
      throw const JournalClassificationException('Weight must be an object');
    }
    final kg = _number(raw['kg']);
    if (kg == null || kg < 20 || kg > 500) {
      throw const JournalClassificationException('Invalid weight observation');
    }
    return WeightObservation(kg: kg);
  }

  ActivityObservation _parseActivity(Object? raw) {
    if (raw is! Map<String, dynamic>) {
      throw const JournalClassificationException('Activity must be an object');
    }
    final activity = raw['activity'];
    final duration = _number(raw['durationMinutes']);
    final kcal = _number(raw['kcal']);
    final confidence = _number(raw['confidence']);
    final assumptions = raw['assumptions'];
    if (activity is! String ||
        activity.trim().isEmpty ||
        activity.trim().length > 80 ||
        duration == null ||
        duration < 1 ||
        duration > 1440 ||
        kcal == null ||
        kcal <= 0 ||
        kcal > 10000 ||
        confidence == null ||
        confidence < 0 ||
        confidence > 1 ||
        assumptions is! List ||
        assumptions.any((item) => item is! String)) {
      throw const JournalClassificationException('Invalid activity estimate');
    }
    return ActivityObservation(
      activity: activity.trim(),
      durationMinutes: duration.round(),
      kcal: kcal,
      confidence: confidence,
      assumptions: List.unmodifiable(assumptions.cast<String>()),
    );
  }

  StrengthObservation _parseStrength(Object? raw) {
    if (raw is! Map<String, dynamic>) {
      throw const JournalClassificationException('Strength must be an object');
    }
    final name = raw['name'];
    final sets = raw['sets'];
    if (name is! String ||
        name.trim().isEmpty ||
        name.trim().length > 80 ||
        sets is! List ||
        sets.isEmpty ||
        sets.length > 30) {
      throw const JournalClassificationException('Invalid strength exercise');
    }
    return StrengthObservation(
      name: name.trim(),
      sets: List.unmodifiable(sets.map(_parseStrengthSet)),
    );
  }

  StrengthSetObservation _parseStrengthSet(Object? raw) {
    if (raw is! Map<String, dynamic>) {
      throw const JournalClassificationException('A set must be an object');
    }
    final reps = _number(raw['reps']);
    final load = _number(raw['loadKg']);
    if (reps == null ||
        reps < 1 ||
        reps > 500 ||
        (load != null && (load < 0 || load > 1000))) {
      throw const JournalClassificationException('Invalid strength set');
    }
    return StrengthSetObservation(reps: reps.round(), loadKg: load);
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
    final text = note is String ? note.trim() : null;
    // A report with no rating, no duration and no words is not a report. The
    // wider vocabulary makes this reachable: `carrying` and `spirit` have no
    // natural number, so an empty one would be a kind with nothing in it.
    if (value == null &&
        duration == null &&
        (text == null || text.isEmpty)) {
      throw const JournalClassificationException(
        'A lifestyle report needs a rating, a duration or the words it came from',
      );
    }
    return LifestyleEstimate(
      kind: kind,
      value: value,
      durationMinutes: duration,
      note: text,
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
    required this.language,
    this.clarification,
  });

  final String text;
  final String source;
  final Map<String, Object> responseSchema;
  final String? clarification;

  /// Which language the derived prose comes back in.
  ///
  /// Part of the request rather than of the provider, because a provider is
  /// built once at startup and the language can change at any time. It governs
  /// the prose only — the food names, the assumptions, the clarifying question —
  /// and never `status` or `kind`, which are the values above and are what the
  /// parser validates against.
  final AppLanguage language;
}

const journalClassificationSchema = <String, Object>{
  'status': <String>['classified', 'needsDetail'],
  'foodRequires': <String>['meal', 'kcal', 'confidence', 'assumptions'],
  'foodOptional': <String>['proteinG', 'carbsG', 'fatG'],
  'lifestyleKinds': <String>[
    'mood',
    'stress',
    'recovery',
    'energy',
    'focus',
    'motivation',
    'social',
    'spirit',
    'carrying',
    'sleep',
    'meditation',
    'breathwork',
  ],
  'weightRequires': <String>['kg'],
  'activityRequires': <String>[
    'activity',
    'durationMinutes',
    'kcal',
    'confidence',
    'assumptions',
  ],
  'strengthRequires': <String>['name', 'sets'],
  'unconfirmedFood': true,
};
