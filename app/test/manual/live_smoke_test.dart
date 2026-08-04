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
import 'package:eter/core/aether/guidance_contract.dart';
import 'package:eter/core/aether/letter.dart';
import 'package:eter/core/aether/guidance_mode.dart';
import 'package:eter/core/aether/request_contract.dart';
import 'package:eter/core/ai/prompts.dart';
import 'package:eter/core/ai/transport.dart';
import 'package:eter/core/journal/classification_contract.dart';
import 'package:eter/core/db/app_database.dart';
import 'package:eter/core/arcana/symbol_content.dart';
import 'package:eter/core/i18n/strings.dart';
import 'package:eter/core/journal/day_story.dart';
import 'package:eter/core/vessel/chart_reading.dart';
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
    // Not recorded. It returns a readable sheet of the movements rather than
    // the response, so a `.json` fixture of it would be prose in a file every
    // replay test expects to be able to decode. Read it in the run's output.
    test('the real composer writes the initial readings',
        () => _vesselThroughComposer(transport));
    // The four parts the Vessel gained on 3 August. They go out under the same
    // call name and are told apart by the prompt and the schema, so a live
    // pass here is the only thing that shows the worker treating them as one
    // call while the model treats them as four different jobs.
    test(
        'the twelve houses compose and parse',
        () => _recorded('vesselHouses',
            () => _vesselPart(transport, VesselReadingPart.houses)));
    test(
        'the angles compose and parse',
        () => _recorded('vesselAspects',
            () => _vesselPart(transport, VesselReadingPart.aspects)));
    test(
        'the figure composes place by place',
        () => _recorded('vesselFigure',
            () => _vesselPart(transport, VesselReadingPart.matrix)));
    test(
        'the figure’s synopsis composes and parses',
        () => _recorded('vesselFigureSynopsis',
            () => _vesselPart(transport, VesselReadingPart.matrixSynopsis)));
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
  // A chart's worth of positions, not two. The recorded response becomes the
  // fixture every parser replay runs against, and a two-position request
  // cannot show the failure this call exists to prevent — a model has nothing
  // to relate when it has only been given two things.
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
        label: 'Sun',
        card: 'The Moon',
        keywords: ['intuition', 'dream', 'the unlit path'],
      ),
      VesselReadingPosition(
        key: 'moon',
        label: 'Moon',
        card: 'Justice',
        keywords: ['balance', 'truth', 'accountability'],
      ),
      VesselReadingPosition(
        key: 'ascendant',
        label: 'Ascendant',
        card: 'The Emperor',
        keywords: ['order', 'structure', 'protection'],
      ),
      VesselReadingPosition(
        key: 'mercury',
        label: 'Mercury',
        card: 'The Moon',
        keywords: ['intuition', 'dream', 'the unlit path'],
      ),
      VesselReadingPosition(
        key: 'venus',
        label: 'Venus',
        card: 'The Star',
        keywords: ['hope', 'renewal', 'clarity'],
      ),
      VesselReadingPosition(
        key: 'mars',
        label: 'Mars',
        card: 'The Tower',
        keywords: ['upheaval', 'sudden light', 'collapse'],
      ),
      VesselReadingPosition(
        key: 'saturn',
        label: 'Saturn',
        card: 'The Devil',
        keywords: ['gravity', 'appetite', 'the shadow'],
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
  if (decoded is! Map || decoded['movements'] is! List) {
    throw const FormatException('No movements in the response');
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
  // A birth time, because nothing is composed without one: a chart cast at
  // noon would be read once and cached for life against angles nobody has.
  await database.updateBirthContext(
    birthTimeMinutes: 6 * 60 + 45,
    birthTimePrecision: 'exact',
    birthUtcOffsetMinutes: 60,
    birthPlace: 'Warsaw',
    birthLatitude: 52.2297,
    birthLongitude: 21.0122,
  );

  final written = await InitialVesselReadings(
    database: database,
    provider: TransportVesselReadingProvider(transport),
  ).composeIfPossible(now: DateTime.utc(2026, 7, 28));

  expect(written, isTrue, reason: 'composeIfPossible wrote nothing');
  final rows = await database.select(database.vesselReadings).get();
  // One row for the whole chart. The reading is about the configuration, so
  // there is nothing to key per position any more.
  expect(rows.map((row) => row.positionKey).toSet(), {vesselConfigurationKey});
  final movements = VesselConfiguration.decode(rows.single.contentJson);
  expect(movements.length, inInclusiveRange(3, 5));
  // The failure this call was rewritten to end: a movement that names one
  // placement and stops. Read the titles as well as counting them.
  final sheet = StringBuffer();
  for (final movement in movements) {
    sheet.writeln(movement.title);
    sheet.writeln(movement.passage);
    sheet.writeln();
  }
  return sheet.toString();
}

/// One of the four parts, through the real request builder and the real
/// composer, over an invented chart.
///
/// Invented is the requirement, not a convenience: what comes back is written
/// into `test/fixtures/live/` and committed, and the owner's own chart must
/// never become a fixture. The birth below belongs to nobody — but it is a
/// *real* birth as far as the engine is concerned, with a time and a place, so
/// the houses and the angles are genuine geometry rather than a hand-written
/// list of twelve identical cusps.
Future<String> _vesselPart(
  EterAiTransport transport,
  VesselReadingPart part,
) async {
  final database = AppDatabase(NativeDatabase.memory());
  addTearDown(database.close);
  await database.saveProfile(ProfilesCompanion.insert(
    dob: DateTime(1990, 3, 14),
    sex: 'other',
    weightKg: 70,
    units: 'metric',
    aiConsentAt: Value(DateTime.utc(2026, 8, 4)),
  ));
  await database.updateBirthContext(
    birthTimeMinutes: 6 * 60 + 45,
    birthTimePrecision: 'exact',
    birthUtcOffsetMinutes: 60,
    birthPlace: 'Warsaw',
    birthLatitude: 52.2297,
    birthLongitude: 21.0122,
  );

  final request = buildChartReadingRequest(
    profile: (await database.loadProfile())!,
    strings: EterStrings.forLanguage(AppLanguage.english),
    content: await SymbolContent.load(language: AppLanguage.english),
  );
  expect(request, isNotNull, reason: 'the request would not build');
  expect(request!.houses, hasLength(12), reason: 'no houses to read');
  expect(request.aspects, isNotEmpty, reason: 'no angles to read');

  // `composePart` runs the parser and the safety gate, so this is the whole
  // chain rather than a shape check — including the two rules only these parts
  // have: every house and no house invented, and a synopsis that may run to
  // four times a movement's length without being refused for it.
  try {
    return await VesselReadingComposer(
      database: database,
      provider: TransportVesselReadingProvider(transport),
    ).composePart(
      inputHash: 'live-smoke',
      request: request,
      part: part,
      now: DateTime.utc(2026, 8, 4),
    );
  } on VesselReadingException catch (error) {
    // A refusal here is the safety net working, not the transport breaking,
    // and the only way to act on it is to know which rule refused what.
    // ignore: avoid_print
    print('\n--- ${part.name} refused: ${error.reason} ---\n');
    rethrow;
  }
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
  // The real parser, including the safety policy and the "we" wall.
  const LetterParser().parse(raw, language: AppLanguage.english);
  return raw;
}
