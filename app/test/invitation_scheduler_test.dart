import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:eter/core/db/app_database.dart';
import 'package:eter/core/invitation/evening_invitation.dart';
import 'package:eter/core/invitation/invitation_scheduler.dart';
import 'package:flutter_test/flutter_test.dart';

/// The half that reads consent and the record.
///
/// The platform call cannot be tested without a phone, so the sink is faked
/// and everything up to it is pinned: that consent is re-read, that revoking
/// cancels immediately rather than at the next sunset, that a refused system
/// permission stores nothing, and that somebody who wrote today is not asked.
void main() {
  late AppDatabase database;
  late _FakeSink sink;
  late EveningInvitationScheduler scheduler;

  setUp(() {
    database = AppDatabase(NativeDatabase.memory());
    sink = _FakeSink();
    scheduler = EveningInvitationScheduler(database: database, sink: sink);
  });
  tearDown(() => database.close());

  Future<void> profile({DateTime? consentedAt}) =>
      database.saveProfile(ProfilesCompanion.insert(
        dob: DateTime(1990, 1, 1),
        sex: 'other',
        weightKg: 70,
        units: 'metric',
        eveningInvitationConsentAt: Value(consentedAt),
      ));

  test('nothing is scheduled without consent, and anything pending is cut',
      () async {
    await profile();
    final decision = await scheduler.sync(now: DateTime(2026, 7, 31, 9));
    expect(decision.refusal, InvitationRefusal.notConsented);
    expect(sink.scheduled, isEmpty);
    expect(sink.cancels, 1);
  });

  test('granting asks the phone first and stores nothing if it says no',
      () async {
    await profile();
    sink.permitted = false;
    expect(await scheduler.grant(now: DateTime(2026, 7, 31, 9)), isFalse);
    // A consent reading ALLOWED that the system will not honour is a lie in
    // the one place in this product that must not tell one.
    expect((await database.loadProfile())?.eveningInvitationConsentAt, isNull);
    expect(sink.scheduled, isEmpty);
  });

  test('granting stores the consent and schedules one invitation', () async {
    await profile();
    expect(await scheduler.grant(now: DateTime(2026, 7, 31, 9)), isTrue);
    expect(
      (await database.loadProfile())?.eveningInvitationConsentAt,
      isNotNull,
    );
    expect(sink.scheduled, hasLength(1));
  });

  test('revoking cancels now, not at the next sunset', () async {
    await profile(consentedAt: DateTime(2026, 7, 1));
    await scheduler.sync(now: DateTime(2026, 7, 31, 9));
    expect(sink.scheduled, hasLength(1));

    await scheduler.revoke();
    expect((await database.loadProfile())?.eveningInvitationConsentAt, isNull);
    expect(sink.cancels, greaterThan(0));
  });

  test('a page written today moves the invitation to tomorrow', () async {
    await profile(consentedAt: DateTime(2026, 7, 1));
    final now = DateTime(2026, 7, 31, 9);
    await database.addJournalEntry(JournalEntriesCompanion.insert(
      entryText: 'Already written.',
      createdAt: DateTime(2026, 7, 31, 8),
    ));

    final decision = await scheduler.sync(now: now);
    // An invitation, not a reminder.
    expect(decision.at!.day, 1);
    expect(decision.at!.month, 8);
  });

  test('an empty page does not count as having written', () async {
    await profile(consentedAt: DateTime(2026, 7, 1));
    await database.addJournalEntry(JournalEntriesCompanion.insert(
      entryText: '   ',
      createdAt: DateTime(2026, 7, 31, 8),
    ));
    final decision = await scheduler.sync(now: DateTime(2026, 7, 31, 9));
    expect(decision.at!.day, 31);
  });
}

class _FakeSink implements InvitationSink {
  bool permitted = true;
  int cancels = 0;
  final scheduled = <DateTime>[];

  @override
  Future<bool> requestPermission() async => permitted;

  @override
  Future<void> scheduleAt(
    DateTime at, {
    required String title,
    required String body,
  }) async {
    scheduled.add(at);
  }

  @override
  Future<void> cancel() async => cancels++;
}
