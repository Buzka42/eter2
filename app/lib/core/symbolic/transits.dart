import 'natal_chart.dart';

/// Today's sky, measured against the chart a person was born under.
///
/// The natal chart is fixed for life and its readings are written once. This
/// is the part that moves: where the planets actually are today, and which of
/// them are currently within orb of a natal position. It is the only symbolic
/// input that changes daily, which is why it is the only one the daily
/// guidance is allowed to consider.
///
/// Everything here is arithmetic, on the device, from the same engine the
/// natal chart uses. The model receives the result and interprets it; it never
/// computes it — the steering brief is explicit and this file is where that
/// promise is kept for the moving half.
class TransitContact {
  const TransitContact({
    required this.transiting,
    required this.natal,
    required this.type,
    required this.orb,
    required this.applying,
  });

  /// The body in today's sky.
  final String transiting;

  /// The natal point it is contacting.
  final String natal;

  /// `conjunction` | `sextile` | `square` | `trine` | `opposition`.
  final String type;

  /// Degrees from exact. Smaller is stronger.
  final double orb;

  /// True while the contact is still tightening. An applying contact is the
  /// one worth mentioning; a separating one has already happened.
  final bool applying;

  /// Slow bodies matter more than fast ones, and a tight orb more than a wide
  /// one. Used only to choose which few contacts are worth a sentence.
  double get weight {
    const slow = {
      'Saturn': 1.0,
      'Jupiter': 0.9,
      'Uranus': 0.85,
      'Neptune': 0.85,
      'Mars': 0.6,
      'Sun': 0.55,
      'Venus': 0.45,
      'Mercury': 0.45,
      'Moon': 0.25,
    };
    final body = slow[transiting] ?? 0.4;
    final tightness = 1 - (orb / 8).clamp(0.0, 1.0);
    return body * (0.4 + 0.6 * tightness) * (applying ? 1.0 : 0.8);
  }

  Map<String, Object?> toJson() => {
        'transiting': transiting,
        'natal': natal,
        'type': type,
        'orb': double.parse(orb.toStringAsFixed(2)),
        'applying': applying,
      };
}

class TransitReading {
  const TransitReading({
    required this.forDate,
    required this.sky,
    required this.contacts,
    required this.moonPhase,
  });

  /// Local calendar day this was computed for.
  final String forDate;

  /// Where the bodies are today, regardless of the natal chart.
  final List<ZodiacPosition> sky;

  /// Today's contacts to natal points, strongest first.
  final List<TransitContact> contacts;

  /// 0 = new, 0.5 = full. Deterministic, from the Sun–Moon separation.
  final double moonPhase;

  String get moonPhaseLabel {
    if (moonPhase < 0.03 || moonPhase > 0.97) return 'new';
    if (moonPhase < 0.22) return 'waxing crescent';
    if (moonPhase < 0.28) return 'first quarter';
    if (moonPhase < 0.47) return 'waxing gibbous';
    if (moonPhase < 0.53) return 'full';
    if (moonPhase < 0.72) return 'waning gibbous';
    if (moonPhase < 0.78) return 'last quarter';
    return 'waning crescent';
  }

  /// Bounded context for a provider. Derived positions only — no birth inputs,
  /// no coordinates, no identity.
  /// The bodies standing still or walking backwards today.
  ///
  /// Retrograde motion was computed and then thrown away: `sky` has carried it
  /// per position all along and nothing downstream was given it, so the one
  /// fact a person is most likely to already know about today's sky — that
  /// Mercury is retrograde — was the one fact the reading could not mention.
  List<String> get retrograde => [
        for (final position in sky)
          if (position.retrograde) position.name,
      ];

  Map<String, Object?> toJson({int maxContacts = 5}) => {
        'forDate': forDate,
        'moonPhase': moonPhaseLabel,
        'moonSign': sky
            .firstWhere((position) => position.name == 'Moon')
            .sign,
        'sunSign':
            sky.firstWhere((position) => position.name == 'Sun').sign,
        // The whole sky, not two signs out of it. Where a body stands today
        // and whether it is retrograde is what makes a transit *this* transit
        // rather than a category of transit.
        'sky': [
          for (final position in sky)
            {
              'body': position.name,
              'sign': position.sign,
              'degrees': double.parse(position.degreeInSign.toStringAsFixed(1)),
              if (position.retrograde) 'retrograde': true,
            },
        ],
        'retrograde': retrograde,
        'contacts': contacts
            .take(maxContacts)
            .map((contact) => contact.toJson())
            .toList(),
      };
}

class TransitEngine {
  TransitEngine({NatalChartEngine? engine})
      : _engine = engine ?? NatalChartEngine();

  final NatalChartEngine _engine;

  static const _targets = <String, double>{
    'conjunction': 0,
    'sextile': 60,
    'square': 90,
    'trine': 120,
    'opposition': 180,
  };

  /// Contacts are measured against these natal points only. Transit-to-transit
  /// aspects are the general sky and say nothing about this person.
  static const _natalPoints = {
    'Sun',
    'Moon',
    'Ascendant',
    'Midheaven',
    'Mercury',
    'Venus',
    'Mars',
    'Jupiter',
    'Saturn',
  };

  /// Today's sky measured against [natal].
  ///
  /// [at] is the instant to compute for; the chart's own birth coordinates are
  /// reused so the ascendant of the moment is meaningful, but they never leave
  /// the device and no part of them enters the result.
  TransitReading forDay({
    required NatalChart natal,
    required DateTime at,
    required double latitude,
    required double longitude,
  }) {
    final local = at.toLocal();
    final today = _engine.calculate(NatalInput(
      localDateTime: DateTime(
        local.year,
        local.month,
        local.day,
        12, // Noon: a day's transits should not swing on the hour it is read.
      ),
      utcOffsetMinutes: local.timeZoneOffset.inMinutes,
      latitude: latitude,
      longitude: longitude,
    ));
    // The following day, to tell an applying contact from a separating one.
    final tomorrow = _engine.calculate(NatalInput(
      localDateTime: DateTime(local.year, local.month, local.day + 1, 12),
      utcOffsetMinutes: local.timeZoneOffset.inMinutes,
      latitude: latitude,
      longitude: longitude,
    ));

    final natalByName = {
      for (final position in natal.positions)
        if (_natalPoints.contains(position.name)) position.name: position,
    };

    final contacts = <TransitContact>[];
    for (final moving in today.positions) {
      if (moving.name == 'Ascendant' || moving.name == 'Midheaven') continue;
      final later = tomorrow.positions
          .where((position) => position.name == moving.name)
          .firstOrNull;
      for (final entry in natalByName.entries) {
        final separation = _separation(moving.longitude, entry.value.longitude);
        for (final target in _targets.entries) {
          final orb = (separation - target.value).abs();
          final allowed = _allowedOrb(moving.name, entry.key);
          if (orb > allowed) continue;
          var applying = true;
          if (later != null) {
            final nextOrb = (_separation(
                      later.longitude,
                      entry.value.longitude,
                    ) -
                    target.value)
                .abs();
            applying = nextOrb < orb;
          }
          contacts.add(TransitContact(
            transiting: moving.name,
            natal: entry.key,
            type: target.key,
            orb: orb,
            applying: applying,
          ));
          break;
        }
      }
    }
    contacts.sort((a, b) => b.weight.compareTo(a.weight));

    final sun = today.positions.firstWhere((p) => p.name == 'Sun');
    final moonBody = today.positions.firstWhere((p) => p.name == 'Moon');
    final phase = _normalize(moonBody.longitude - sun.longitude) / 360;

    return TransitReading(
      forDate: '${local.year.toString().padLeft(4, '0')}-'
          '${local.month.toString().padLeft(2, '0')}-'
          '${local.day.toString().padLeft(2, '0')}',
      sky: today.positions,
      contacts: List.unmodifiable(contacts),
      moonPhase: phase,
    );
  }

  /// Luminaries carry a wider orb, as they do in the natal aspect table.
  double _allowedOrb(String transiting, String natal) {
    const luminaries = {'Sun', 'Moon'};
    if (luminaries.contains(transiting) || luminaries.contains(natal)) {
      return 6;
    }
    return 4;
  }

  double _separation(double first, double second) {
    final delta = _normalize(first - second);
    return delta > 180 ? 360 - delta : delta;
  }

  double _normalize(double value) {
    final result = value % 360;
    return result < 0 ? result + 360 : result;
  }
}
