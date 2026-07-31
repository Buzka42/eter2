import 'package:drift/native.dart';
import 'package:eter/core/correspondence/correspondence.dart';
import 'package:eter/core/correspondence/correspondence_service.dart';
import 'package:eter/core/db/app_database.dart';
import 'package:flutter_test/flutter_test.dart';

/// Pairing, and the exchange it enables.
///
/// The gateway is a map, so everything here is the sequencing rather than
/// Firestore. What is worth pinning: that a code is good exactly once, that
/// leaving is unilateral, and that a stale or unsafe line from the other side
/// is simply not shown rather than shown with a caveat.
void main() {
  late AppDatabase database;
  late _FakeGateway gateway;
  late CorrespondenceService service;

  setUp(() async {
    database = AppDatabase(NativeDatabase.memory());
    gateway = _FakeGateway('me');
    service = CorrespondenceService(database: database, gateway: gateway);
    await database.saveProfile(ProfilesCompanion.insert(
      dob: DateTime(1990, 1, 1),
      sex: 'other',
      weightKg: 70,
      units: 'metric',
    ));
  });
  tearDown(() => database.close());

  final now = DateTime(2026, 7, 31, 9);

  Future<String> aPairWith(String them) async {
    gateway.offers['ABCDEFGH'] = them;
    await service.accept('abcd-efgh', now: now);
    return (await database.loadProfile())!.correspondencePairId!;
  }

  test('a code pairs two people, once', () async {
    await aPairWith('them');
    expect(gateway.pairs.values.single, unorderedEquals(['them', 'me']));
    // Good exactly once: the offer is gone.
    expect(gateway.offers, isEmpty);
  });

  test('an unknown or spent code is refused', () async {
    await expectLater(
      service.accept('ABCDEFGH', now: now),
      throwsA(isA<CorrespondenceRefusal>()),
    );
    expect(await database.loadProfile().then((p) => p?.correspondencePairId),
        isNull);
  });

  test('a malformed code never reaches the network', () async {
    await expectLater(
      service.accept('NOT-A-CODE-0', now: now),
      throwsA(isA<CorrespondenceRefusal>()),
    );
    expect(gateway.reads, isEmpty);
  });

  test('your own code is refused with something you can act on', () async {
    gateway.offers['ABCDEFGH'] = 'me';
    await expectLater(
      service.accept('ABCDEFGH', now: now),
      throwsA(isA<CorrespondenceRefusal>()),
    );
  });

  test('leaving is unilateral and forgets the pair here', () async {
    await aPairWith('them');
    await service.end();
    expect(
      (await database.loadProfile())?.correspondencePairId,
      isNull,
    );
    expect(gateway.pairs, isEmpty);
  });

  group('the exchange', () {
    test('sends today’s sentence and returns theirs', () async {
      final pairId = await aPairWith('them');
      gateway.lines['$pairId/them'] = const CorrespondenceLine(
        date: '2026-07-31',
        sentence: 'A slower day than the one before it.',
      );

      final received = await service.exchange(
        now: now,
        todaysSentence: 'Steady, and worth keeping steady.',
      );
      expect(received?.sentence, 'A slower day than the one before it.');
      expect(
        gateway.lines['$pairId/me']?.sentence,
        'Steady, and worth keeping steady.',
      );
    });

    test('shows nothing when their line is not today’s', () async {
      final pairId = await aPairWith('them');
      gateway.lines['$pairId/them'] = const CorrespondenceLine(
        date: '2026-07-30',
        sentence: 'Yesterday.',
      );
      // Unlabelled beneath today's guidance, a stale line reads as today's.
      expect(await service.exchange(now: now, todaysSentence: null), isNull);
    });

    test('refuses to send a sentence carrying a measurement', () async {
      final pairId = await aPairWith('them');
      await service.exchange(now: now, todaysSentence: 'You slept 5 hours.');
      expect(gateway.lines['$pairId/me'], isNull);
    });

    test('still receives on a day it could not send', () async {
      final pairId = await aPairWith('them');
      gateway.lines['$pairId/them'] = const CorrespondenceLine(
        date: '2026-07-31',
        sentence: 'Theirs came through.',
      );
      final received =
          await service.exchange(now: now, todaysSentence: 'You walked 9000.');
      // Being unable to share today is not a reason to stop receiving.
      expect(received?.sentence, 'Theirs came through.');
      expect(gateway.lines['$pairId/me'], isNull);
    });

    test('forgets a pair the other person ended', () async {
      await aPairWith('them');
      gateway.pairs.clear();
      expect(await service.exchange(now: now, todaysSentence: 'A day.'), isNull);
      expect((await database.loadProfile())?.correspondencePairId, isNull);
    });

    test('does nothing at all when there is no pair', () async {
      expect(await service.exchange(now: now, todaysSentence: 'A day.'), isNull);
      expect(gateway.lines, isEmpty);
    });
  });
}

class _FakeGateway implements CorrespondenceGateway {
  _FakeGateway(this.userId);

  @override
  final String? userId;

  final offers = <String, String>{};
  final pairs = <String, List<String>>{};
  final lines = <String, CorrespondenceLine>{};
  final reads = <String>[];
  var _next = 0;

  @override
  Future<void> offerCode(String code, {required DateTime expiresAt}) async {
    offers[code] = userId!;
  }

  @override
  Future<String?> readOffer(String code) async {
    reads.add(code);
    return offers[code];
  }

  @override
  Future<void> withdrawCode(String code) async => offers.remove(code);

  @override
  Future<String> createPair(List<String> members) async {
    final id = 'pair-${_next++}';
    pairs[id] = members;
    return id;
  }

  @override
  Future<void> endPair(String pairId) async => pairs.remove(pairId);

  @override
  Future<void> putLine(String pairId, CorrespondenceLine line) async {
    lines['$pairId/$userId'] = line;
  }

  @override
  Future<CorrespondenceLine?> readLine(String pairId, String authorId) async =>
      lines['$pairId/$authorId'];

  @override
  Future<List<String>?> membersOf(String pairId) async => pairs[pairId];
}
