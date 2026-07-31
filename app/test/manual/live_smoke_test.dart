// Drives all five contracts through the real transport to a running endpoint,
// and runs each contract's real parser over what comes back.
//
// This is the check that the chain actually holds end to end: prompt built on
// the device → transport → endpoint → model → the parser that decides whether
// a single character is allowed into the record. Nothing here is mocked, which
// is why it is skipped by default — it needs the network and it spends tokens.
//
//   dart run tool/dev_endpoint.dart                       (in one shell)
//   flutter test test/manual/live_smoke_test.dart \
//     --dart-define=ETER_LIVE_SMOKE=true                  (in another)
//
// A pass means every call composed and parsed. A failure names the call and
// the stage, which is the distinction that matters: a refused parse is the
// safety net working, not the transport breaking.

import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:eter/core/i18n/language.dart';
import 'package:eter/core/arcana/matrix.dart';
import 'package:eter/core/aether/guidance_contract.dart';
import 'package:eter/core/aether/letter.dart';
import 'package:eter/core/aether/guidance_mode.dart';
import 'package:eter/core/aether/request_contract.dart';
import 'package:eter/core/ai/prompts.dart';
import 'package:eter/core/ai/transport.dart';
import 'package:eter/core/journal/classification_contract.dart';
import 'package:eter/core/db/app_database.dart';
import 'package:eter/core/journal/day_story.dart';
import 'package:eter/core/vessel/initial_readings.dart';
import 'package:eter/core/symbolic/natal_chart.dart';
import 'package:eter/core/vessel/positions_composer.dart';
import 'package:eter/core/symbolic/transits.dart';
import 'package:eter/core/vessel/reading_composer.dart';
import 'package:flutter_test/flutter_test.dart';

/// Off unless asked for, so `flutter test` stays offline, free and green.
const _enabled = bool.fromEnvironment('ETER_LIVE_SMOKE');
const _endpoint = String.fromEnvironment(
  'ETER_AI_ENDPOINT',
  defaultValue: 'http://127.0.0.1:8787',
);

/// Empty for the local dev endpoint, which does not check one. The deployed
/// worker does, and answers 401 without it.
const _token = String.fromEnvironment('ETER_AI_TOKEN');

/// A directory to record what the model actually said, or empty for none.
///
/// This is how the prompt fixtures get made. Every parser in the app is tested
/// against hand-written JSON, which proves the parser and proves nothing about
/// the prompt: a contract can drift until the model stops answering the shape
/// the parser expects, and only a recorded real response shows it. Written
/// under a name per call so a later run overwrites rather than accumulates.
const _record = String.fromEnvironment('ETER_RECORD');

Future<String> _recorded(String call, Future<String> Function() run) async {
  final raw = await run();
  if (_record.isNotEmpty) {
    final file = File('$_record/$call.json');
    await file.parent.create(recursive: true);
    await file.writeAsString(raw);
  }
  return raw;
}

void main() {
  // SymbolContent reads an asset, so the composer path needs a binding. The
  // binding also stubs every HttpClient to answer 400, which is right for an
  // ordinary widget test and exactly wrong here: this suite exists to make
  // real calls.
  TestWidgetsFlutterBinding.ensureInitialized();
  HttpOverrides.global = null;

  final transport = EterAiTransport(
    config: const EterAiConfig(endpoint: _endpoint, token: _token),
    timeout: const Duration(seconds: 90),
  );

  group('live · $_endpoint', () {
    test('guidance composes and parses', () => _recorded('guidance', () => _guidance(transport)));
    test('the day story composes and parses', () => _recorded('journalDayStory', () => _dayStory(transport)));
    test(
        'interpretation composes and parses', () => _recorded('journalInterpretation', () => _interpretation(transport)));
    test('interpretation reads weight, a run and lifted work',
        () => _bodyInterpretation(transport));
    test('vessel readings compose and parse', () => _recorded('vesselReadings', () => _vesselReadings(transport)));
    test('the real composer writes the initial readings',
        () => _vesselThroughComposer(transport));
    test('positions compose and parse', () => _recorded('positions', () => _positions(transport)));
    test('the letter composes and parses', () => _recorded('letter', () => _letter(transport)));
  },
      skip: _enabled
          ? false
          : 'Live call. Start tool/dev_endpoint.dart and pass '
              '--dart-define=ETER_LIVE_SMOKE=true');
}

/// Prints what the model actually said when a parser refuses it.
///
/// A refusal here is not a bug report against the parser. It is the one
/// signal that says the prompt and the contract have drifted apart, and the
/// only way to act on it is to read the text that was rejected.
T _parsed<T>(String raw, T Function() parse) {
  try {
    return parse();
  } catch (error) {
    // ignore: avoid_print
    print('\n--- rejected by the parser: $error ---\n$raw\n---\n');
    rethrow;
  }
}

Future<String> _guidance(EterAiTransport transport) async {
  final request = const AetherRequestBuilder().build(
    aiConsented: true,
    journalConsented: true,
    ageYears: 36,
    mode: GuidanceMode.balanced,
    health: [
      for (var day = 21; day <= 27; day++)
        AetherHealthContext(
          localDate: '2026-07-${day.toString().padLeft(2, '0')}',
          steps: 6000 + day * 120,
          activeKcal: 300 + day * 5,
          sleepMinutes: 380 + day,
          restingHeartRate: 54,
          hrvMs: 62,
        ),
    ],
    journal: [
      AetherJournalContext(
        createdAt: DateTime.utc(2026, 7, 27, 21),
        text: 'Long week. Slept badly before the deadline and ate at my desk.',
      ),
    ],
  );
  final raw = await TransportAetherProvider(transport).compose(
    AetherProviderRequest(
      system:
          EterPrompts.guidance(request, language: AppLanguage.english).system,
      context: request.toJson(),
      responseSchema:
          EterPrompts.guidance(request, language: AppLanguage.english)
              .responseSchema
              .cast<String, Object>(),
    ),
  );
  _parsed(
      raw, () => const AetherGuidanceParser().parse(raw, mode: request.mode));
  return raw;
}

Future<String> _dayStory(EterAiTransport transport) async {
  final prompt = EterPrompts.journalDayStory(
    date: '2026-07-28',
    entries: [
      (
        at: DateTime(2026, 7, 28, 8, 10),
        text: 'Woke before the alarm. Porridge and black coffee.'
      ),
      (
        at: DateTime(2026, 7, 28, 19, 40),
        text: 'Ran six kilometres along the river. Legs heavy, head clear.'
      ),
    ],
    language: AppLanguage.english,
  );
  final raw = await TransportJournalDayStoryProvider(transport).compose(
    JournalDayStoryProviderRequest(
      system: prompt.system,
      context: prompt.user,
      responseSchema: prompt.responseSchema,
    ),
  );
  _parsed(raw, () => const JournalDayStoryParser().parse(raw));
  return raw;
}

Future<String> _interpretation(EterAiTransport transport) async {
  final raw = await TransportJournalClassificationProvider(transport).classify(
    const JournalClassificationRequest(
      text: 'Two poached eggs on rye with butter, and a flat white. '
          'Slept about seven hours, woke twice.',
      source: 'typed',
      responseSchema: journalClassificationSchema,
      language: AppLanguage.english,
    ),
  );
  _parsed(raw, () => const JournalClassificationParser().parse(raw));
  return raw;
}

/// The three shapes that reach the body log. A page naming all of them at once
/// is rare in life and exactly right here: it is the only way to see that the
/// model keeps them apart — that a run does not become an exercise and a
/// stated weight does not acquire a confidence it never had.
Future<String> _bodyInterpretation(EterAiTransport transport) async {
  final raw = await TransportJournalClassificationProvider(transport).classify(
    const JournalClassificationRequest(
      text: '84.2 on the scale this morning. Easy run along the river, about '
          'half an hour. Then back squats, 100 kilos for five, three times, '
          'and pull-ups until they ran out.',
      source: 'typed',
      responseSchema: journalClassificationSchema,
      language: AppLanguage.english,
    ),
  );
  final parsed =
      _parsed(raw, () => const JournalClassificationParser().parse(raw));

  expect(parsed.weight.single.kg, closeTo(84.2, 0.01));
  expect(parsed.activity, isNotEmpty);
  expect(parsed.activity.first.durationMinutes, inInclusiveRange(20, 40));
  expect(parsed.activity.first.assumptions, isNotEmpty);
  expect(parsed.strength.map((item) => item.name).join(' ').toLowerCase(),
      contains('squat'));
  expect(
    parsed.strength.first.sets.first.loadKg,
    closeTo(100, 0.01),
  );
  return raw;
}

Future<String> _vesselReadings(EterAiTransport transport) async {
  const request = VesselReadingRequest(
    mode: GuidanceMode.balanced,
    positions: [
      VesselReadingPosition(
        key: 'lifePath',
        label: 'Life Path 8',
        card: 'Strength',
        keywords: ['resolve', 'patience', 'inner authority'],
      ),
      VesselReadingPosition(
        key: 'sun',
        label: 'Sun in Pisces',
        card: 'The Moon',
        keywords: ['intuition', 'dream', 'the unlit path'],
      ),
    ],
    approximateTime: true,
    approximatePlace: false,
  );
  final raw = await TransportVesselReadingProvider(transport).compose(
    VesselReadingProviderRequest(
      system: EterPrompts.vesselReading(request, language: AppLanguage.english)
          .system,
      context: request.toJson(),
      responseSchema:
          EterPrompts.vesselReading(request, language: AppLanguage.english)
              .responseSchema
              .cast<String, Object>(),
    ),
  );
  final decoded = jsonDecode(raw);
  if (decoded is! Map || decoded['readings'] is! List) {
    throw const FormatException('No readings in the response');
  }
  return raw;
}

/// The composer as the app actually calls it, with its own parser and its own
/// safety gate — not just a JSON shape check. The shape check passed while the
/// real path was failing, which is exactly the gap this closes.
Future<String> _vesselThroughComposer(EterAiTransport transport) async {
  final database = AppDatabase(NativeDatabase.memory());
  addTearDown(database.close);
  await database.saveProfile(ProfilesCompanion.insert(
    dob: DateTime(1990, 3, 14),
    sex: 'other',
    weightKg: 70,
    units: 'metric',
    aiConsentAt: Value(DateTime.utc(2026, 7, 28)),
  ));

  final written = await InitialVesselReadings(
    database: database,
    provider: TransportVesselReadingProvider(transport),
  ).composeIfPossible(now: DateTime.utc(2026, 7, 28));

  expect(written, isTrue, reason: 'composeIfPossible wrote nothing');
  final rows = await database.select(database.vesselReadings).get();
  expect(rows.map((row) => row.positionKey).toSet(), {
    'lifePath',
    'sun',
    'moon',
    'ascendant',
    // The figure composes through the same path, which is the point of having
    // built it as ordinary reading positions.
    for (final position in MatrixPosition.values) position.key,
  });
  return 'wrote readings';
}

Future<String> _positions(EterAiTransport transport) async {
  final natal = NatalChartEngine().calculate(NatalInput(
    localDateTime: DateTime(1990, 3, 14, 9, 20),
    utcOffsetMinutes: 60,
    latitude: 52.23,
    longitude: 21.01,
  ));
  final reading = TransitEngine().forDay(
    natal: natal,
    at: DateTime.now(),
    latitude: 52.23,
    longitude: 21.01,
  );
  final prompt = EterPrompts.positions(
    mode: GuidanceMode.balanced,
    transits: reading.toJson(),
    ascendantReliable: true,
    language: AppLanguage.english,
  );
  final raw = await TransportPositionsProvider(transport).compose(
    PositionsProviderRequest(
      system: prompt.system,
      context: prompt.user,
      responseSchema: prompt.responseSchema,
    ),
  );
  final decoded = jsonDecode(raw);
  if (decoded is! Map ||
      decoded['passage'] is! String ||
      decoded['guidanceNote'] is! String) {
    throw const FormatException('No passage and note in the response');
  }
  return raw;
}

/// The sixth call, and the only one that composes over a month.
///
/// The recalls it is handed here are shaped like the ones guidance writes —
/// telegraphic, no articles, its own words about what it had already said —
/// because the instruction's hardest constraint is that the letter must never
/// attribute them to the person. A live pass proves the schema and the ceiling
/// hold; whether it *obeys* that constraint is what reading the output is for,
/// which is why this prints it.
Future<String> _letter(EterAiTransport transport) async {
  final prompt = EterPrompts.letter(
    mode: GuidanceMode.balanced,
    language: AppLanguage.english,
    month: '2026-06',
    recalls: const [
      'third short night. hrv down. deadline friday. offered early wind-down.',
      'slept 8h. hrv recovering. lighter mood. suggested keeping the evening.',
      'no movement logged. wrote about a hard conversation.',
      'long walk. steps double the week. said it felt like clearing.',
      'short night again. same week pattern as before the deadline.',
      'rest day taken deliberately. first time this month.',
      'steady. nothing to flag.',
    ],
    retrospective: const [
      'Movement was recorded on 22 of 30 days, 9100 steps across 22 measured '
          'days.',
      'Sleep was available for 19 of 30 nights, averaging 6.8 hours.',
      'You made 11 journal entries during this window.',
      'Missing days are omitted, not treated as zero.',
    ],
  );
  final raw = await TransportLetterProvider(transport).compose(
    LetterProviderRequest(
      system: prompt.system,
      context: prompt.user,
      responseSchema: prompt.responseSchema,
    ),
  );
  // The real parser, including the safety policy.
  const LetterParser().parse(raw);
  return raw;
}
