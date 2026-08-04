/// Reads an Apple Health `export.xml`.
///
/// The one import that arrives when somebody changes phone rather than changes
/// app, and the only one whose file is too large to hold. It is read through
/// [AppleHealthScanner], a chunk at a time.
///
/// **What it takes, and why so little of what is in there.**
///
/// The file holds everything the phone ever measured, most of it at a
/// resolution nothing here wants: a heart rate every few seconds, a step count
/// every few minutes. Eter already has a pipeline for those — connected
/// sources, minute buckets, one winner per minute — and a file cannot join it
/// honestly, because it carries no notion of which device measured what or
/// whether the same minute is already counted from somewhere else. Importing
/// steps and energy from a file would double days that a live source is
/// already reporting.
///
/// So this takes the four things a file is genuinely better at than a live
/// connection: **the long history**. Weight, sleep, resting heart rate and
/// heart-rate variability, going back further than any integration will
/// backfill. Everything else is counted by name and reported.
///
/// **Nothing here outranks the device.** Sleep is written at
/// [SourcePriority.importedFile], last of all, so a night a live source also
/// knows about wins. A day whose vitals are already recorded is left exactly as
/// it is and counted, because `DailyVitals` holds one row per date and a
/// snapshot from an old phone must not overwrite what this one measured.
library;

import 'apple_health_scanner.dart';
import 'foreign_import.dart';

class AppleHealthImportSource {
  const AppleHealthImportSource();

  String get name => 'Apple Health';

  /// The source string every row from this import carries.
  static const sourceId = 'apple-health:file';

  /// Whether the first characters of a file look like an Apple Health export.
  ///
  /// Given the head of the file rather than all of it, because the whole point
  /// of this reader is never to hold the whole of it.
  static bool looksLikeExport(String head) =>
      head.contains('<HealthData') || head.contains('HKQuantityTypeIdentifier');

  /// The five types this reads. Everything else in the file is counted as it
  /// goes past and never parsed.
  static const _wanted = {
    'HKQuantityTypeIdentifierBodyMass',
    'HKCategoryTypeIdentifierSleepAnalysis',
    'HKQuantityTypeIdentifierRestingHeartRate',
    'HKQuantityTypeIdentifierHeartRateVariabilitySDNN',
    'HKQuantityTypeIdentifierRespiratoryRate',
  };

  /// The `type` attribute, by looking for it rather than by parsing the tag.
  ///
  /// The full attribute parse is a regex over the whole tag and it is most of
  /// the cost of a scan — spent, in a real export, overwhelmingly on records
  /// that are about to be thrown away.
  static String? typeOf(String tag) {
    const marker = 'type="';
    final at = tag.indexOf(marker);
    if (at < 0) return null;
    final from = at + marker.length;
    final to = tag.indexOf('"', from);
    return to < 0 ? null : tag.substring(from, to);
  }

  /// Reads the export from a stream of text chunks.
  ///
  /// Everything kept is small: weights, nights and daily vitals are hundreds or
  /// thousands of rows, not the millions the file holds. Everything not kept is
  /// counted as it goes past and never accumulates.
  Future<ForeignRecords> read(Stream<String> chunks) async {
    final weight = <ForeignWeightEntry>[];
    final sleep = <ForeignSleepSegment>[];
    final ignored = <String, int>{};
    var unreadable = 0;

    // Vitals arrive as many samples a day and Eter keeps one row per day, so
    // they are averaged as they stream past rather than collected.
    final resting = <String, _Mean>{};
    final hrv = <String, _Mean>{};
    final respiratory = <String, _Mean>{};

    void count(String what) => ignored[what] = (ignored[what] ?? 0) + 1;

    // The filter and the report are the same pass. Skipping a record early is
    // what makes a large file bearable; counting it there is what keeps
    // "not brought across: Step count, Heart rate" true.
    final scanner = AppleHealthScanner(
      keep: (tag) {
        final type = typeOf(tag);
        if (type == null) return false;
        if (_wanted.contains(type)) return true;
        count(_readableType(type));
        return false;
      },
    );

    void handle(AppleHealthRecord record) {
      final start = record.start;
      final end = record.end ?? start;
      if (start == null || end == null) {
        unreadable++;
        return;
      }

      switch (record.type) {
        case 'HKQuantityTypeIdentifierBodyMass':
          final kg = _asKilograms(record.value, record.unit);
          if (kg == null) {
            unreadable++;
            return;
          }
          weight.add(ForeignWeightEntry(at: start, kg: kg, source: sourceId));

        case 'HKCategoryTypeIdentifierSleepAnalysis':
          final stage = _sleepStage(record['value']);
          if (stage == null) {
            unreadable++;
            return;
          }
          // A zero-length or reversed segment is not a stretch of sleep. They
          // turn up in real exports around daylight-saving changes.
          if (!end.isAfter(start)) {
            unreadable++;
            return;
          }
          sleep.add(ForeignSleepSegment(
            start: start,
            end: end,
            stage: stage,
            source: sourceId,
          ));

        case 'HKQuantityTypeIdentifierRestingHeartRate':
          _add(resting, start, record.value);

        case 'HKQuantityTypeIdentifierHeartRateVariabilitySDNN':
          // Apple records SDNN in milliseconds, which is what `hrvMs` holds.
          // A unit that is not milliseconds is not a unit conversion problem,
          // it is a different measurement, and it is left alone.
          if (record.unit.isNotEmpty && record.unit != 'ms') {
            count('Heart-rate variability in ${record.unit}');
            return;
          }
          _add(hrv, start, record.value);

        case 'HKQuantityTypeIdentifierRespiratoryRate':
          _add(respiratory, start, record.value);

        default:
          // Unreachable: the scanner's filter counted and dropped everything
          // that is not one of the five, so nothing else arrives here. Kept as
          // a total rather than removed, because a type added to `_wanted`
          // without a branch here would otherwise vanish in silence.
          count(_readableType(record.type));
      }
    }

    await for (final chunk in chunks) {
      for (final record in scanner.add(chunk)) {
        handle(record);
      }
    }
    scanner.flush();

    final dates = {...resting.keys, ...hrv.keys, ...respiratory.keys};
    final vitals = [
      for (final date in dates.toList()..sort())
        ForeignDailyVital(
          date: date,
          source: sourceId,
          restingHr: resting[date]?.mean,
          hrvMs: hrv[date]?.mean,
          respiratoryRate: respiratory[date]?.mean,
        ),
    ];

    return ForeignRecords(
      weight: weight,
      sleep: sleep,
      vitals: vitals,
      ignored: ignored,
      unreadableRows: unreadable,
    );
  }

  static void _add(Map<String, _Mean> into, DateTime at, double? value) {
    if (value == null) return;
    into.putIfAbsent(_localDate(at), () => _Mean()).add(value);
  }

  static String _localDate(DateTime at) {
    final local = at.toLocal();
    final month = local.month.toString().padLeft(2, '0');
    final day = local.day.toString().padLeft(2, '0');
    return '${local.year}-$month-$day';
  }

  /// Apple's own sleep values, across the versions that wrote them.
  ///
  /// The staged ones arrived with watchOS 9; before that every night was one
  /// undifferentiated block, and an export spanning both — which any long
  /// history does — carries both shapes. `InBed` is time in bed rather than
  /// sleep and covers the same minutes as the stages inside it, so it is
  /// `unknown` and the writer drops it for any night that has real stages.
  static String? _sleepStage(String? value) => switch (value) {
        'HKCategoryValueSleepAnalysisAsleepDeep' => 'deep',
        'HKCategoryValueSleepAnalysisAsleepREM' => 'rem',
        'HKCategoryValueSleepAnalysisAsleepCore' => 'light',
        'HKCategoryValueSleepAnalysisAwake' => 'awake',
        'HKCategoryValueSleepAnalysisAsleep' ||
        'HKCategoryValueSleepAnalysisAsleepUnspecified' ||
        'HKCategoryValueSleepAnalysisInBed' =>
          'unknown',
        _ => null,
      };

  /// Weight arrives in whichever unit the phone was set to.
  static double? _asKilograms(double? value, String unit) {
    if (value == null) return null;
    return switch (unit.trim().toLowerCase()) {
      'kg' => value,
      'g' => value / 1000,
      'lb' || 'lbs' => value * 0.45359237,
      'st' => value * 6.35029318,
      // No unit is not kilograms by default. Guessing halves or doubles
      // somebody's body.
      _ => null,
    };
  }

  /// `HKQuantityTypeIdentifierStepCount` → `Step count`.
  static String _readableType(String type) {
    final bare = type
        .replaceFirst('HKQuantityTypeIdentifier', '')
        .replaceFirst('HKCategoryTypeIdentifier', '')
        .replaceFirst('HKDataTypeIdentifier', '');
    if (bare.isEmpty) return type;
    final spaced = bare.replaceAllMapped(
      RegExp(r'(?<=[a-z])(?=[A-Z])'),
      (_) => ' ',
    );
    return spaced[0].toUpperCase() + spaced.substring(1).toLowerCase();
  }
}

class _Mean {
  double _total = 0;
  int _count = 0;

  void add(double value) {
    _total += value;
    _count++;
  }

  double? get mean => _count == 0 ? null : _total / _count;
}
