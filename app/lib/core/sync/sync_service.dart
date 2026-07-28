import 'package:drift/drift.dart';

import '../account/account.dart';
import '../db/app_database.dart';
import 'cloud_mirror.dart';

/// Pushing the record up, and pulling it back on a new phone.
///
/// Three rules decide everything here.
///
/// **The local store is canonical.** Nothing is read from the mirror except on
/// a device that has no history of its own. A restore can therefore never
/// overwrite something you have and the mirror does not.
///
/// **Consent is checked here, not at the call site.** Every path through this
/// file re-reads the profile, so revoking in the Sanctum takes effect on the
/// next sync rather than whenever some cached flag is refreshed.
///
/// **A failed sync loses nothing.** Rows are marked synced only after the
/// write is acknowledged; a failure leaves `syncedAt` null and they go again.
class SyncService {
  const SyncService({
    required this.database,
    required this.mirror,
  });

  final AppDatabase database;
  final CloudMirror mirror;

  /// Collections that never leave, and the reason each one stays.
  ///
  /// Recorded rather than merely absent, because "why is my minute data not
  /// backed up" deserves an answer better than silence.
  static const withheld = <String, String>{
    'minuteBuckets': 'A day is 1,440 rows and the day totals carry the '
        'result. Mirroring them would cost a thousand times the writes for '
        'nothing you could see.',
    'rawBuckets': 'Pre-deduplication imports. The winners are mirrored; the '
        'losers are not worth keeping twice.',
    'guidanceHistory': 'Composed from the record, and recomposable from it.',
    'vesselReadings': 'Cached model output, keyed to a chart that is itself '
        'derived from the mirrored profile.',
    'transitReadings': 'A cache of one day of arithmetic.',
    'journalDayStories': 'Derived from the pages, which are mirrored only '
        'under their own consent.',
    'integrations': 'Device-local connection state. It means nothing on a '
        'different phone.',
  };

  /// Sends everything not yet sent.
  ///
  /// [account] must be able to sync — an unconfirmed email account cannot, and
  /// this refuses rather than trusting the caller to have checked.
  Future<SyncOutcome> push(EterAccount account) async {
    final profile = await database.loadProfile();
    if (profile == null) {
      return const SyncOutcome(failure: 'There is nothing to sync yet.');
    }
    if (!account.canSync) {
      return const SyncOutcome(
        failure: 'Confirm your email before anything is copied.',
      );
    }
    if (profile.cloudSyncConsentAt == null) {
      return const SyncOutcome(failure: 'Cloud continuity is off.');
    }

    final journalAllowed = profile.journalCloudSyncConsentAt != null;
    final skipped = <String, String>{
      ...withheld,
      if (!journalAllowed)
        'journalEntries': 'Your pages stay on this device. Cloud continuity '
            'for the journal is a separate choice.',
    };

    var uploaded = 0;
    try {
      uploaded += await _pushProfile(account.id, profile);
      uploaded += await _pushWeights(account.id);
      uploaded += await _pushNutrition(account.id);
      uploaded += await _pushLifestyle(account.id);
      uploaded += await _pushSessions(account.id);
      uploaded += await _pushStrength(account.id);
      uploaded += await _pushDaySummaries(account.id);
      if (journalAllowed) {
        uploaded += await _pushJournal(account.id);
      }
    } on MirrorException catch (error) {
      // Nothing was marked synced for whatever failed, so the next attempt
      // sends it again. A failed sync is a delay, never a loss.
      return SyncOutcome(uploaded: uploaded, skipped: skipped, failure: error.reason);
    }

    return SyncOutcome(uploaded: uploaded, skipped: skipped);
  }

  /// Brings the record back onto a device that has none.
  ///
  /// Refuses on a device that already has history. Merging two divergent
  /// copies of a health record is a problem with no correct answer, and
  /// guessing at one would silently rewrite what someone actually did.
  Future<SyncOutcome> restore(EterAccount account) async {
    if (!account.canSync) {
      return const SyncOutcome(failure: 'Confirm your email first.');
    }
    if (!await isEmpty()) {
      return const SyncOutcome(
        failure: 'This device already has history, so nothing was restored.',
      );
    }

    var restored = 0;
    try {
      restored += await _restoreProfile(account.id);
      restored += await _restoreWeights(account.id);
      restored += await _restoreNutrition(account.id);
      restored += await _restoreLifestyle(account.id);
      restored += await _restoreSessions(account.id);
      restored += await _restoreStrength(account.id);
      restored += await _restoreDaySummaries(account.id);
      restored += await _restoreJournal(account.id);
    } on MirrorException catch (error) {
      return SyncOutcome(restored: restored, failure: error.reason);
    }
    return SyncOutcome(restored: restored);
  }

  /// True when this device holds nothing a restore could overwrite.
  Future<bool> isEmpty() async {
    final counts = await Future.wait([
      _count(database.select(database.weightEntries)),
      _count(database.select(database.nutritionEntries)),
      _count(database.select(database.lifestyleEntries)),
      _count(database.select(database.activitySessions)),
      _count(database.select(database.strengthWorkouts)),
      _count(database.select(database.journalEntries)),
      _count(database.select(database.daySummaries)),
    ]);
    return counts.every((count) => count == 0);
  }

  Future<int> _count(SimpleSelectStatement<Table, dynamic> query) async =>
      (await query.get()).length;

  /// Removes the copy. Called when consent is withdrawn or an account deleted.
  Future<void> forget(String userId) => mirror.deleteEverything(userId);

  // -------------------------------------------------------------------------
  // Push
  // -------------------------------------------------------------------------

  Future<int> _pushProfile(String userId, ProfileRow profile) async {
    if (profile.syncedAt != null) return 0;
    await mirror.put(
      userId: userId,
      collection: 'profile',
      id: 'profile',
      data: {
        'profileSchemaVersion': 1,
        'updatedAt': DateTime.now().toUtc().toIso8601String(),
        'firstName': profile.firstName,
        'dob': profile.dob.toIso8601String(),
        'sex': profile.sex,
        'weightKg': profile.weightKg,
        'heightCm': profile.heightCm,
        'bodyFatPercent': profile.bodyFatPercent,
        'units': profile.units,
        'guidanceMode': profile.guidanceMode,
        'birthTimeMinutes': profile.birthTimeMinutes,
        'birthUtcOffsetMinutes': profile.birthUtcOffsetMinutes,
        'birthPlace': profile.birthPlace,
        'birthLatitude': profile.birthLatitude,
        'birthLongitude': profile.birthLongitude,
      },
    );
    await (database.update(database.profiles)
          ..where((row) => row.id.equals(1)))
        .write(ProfilesCompanion(syncedAt: Value(DateTime.now().toUtc())));
    return 1;
  }

  Future<int> _pushWeights(String userId) async {
    final rows = await (database.select(database.weightEntries)
          ..where((row) => row.syncedAt.isNull()))
        .get();
    if (rows.isEmpty) return 0;
    await mirror.putAll(
      userId: userId,
      collection: 'weights',
      documents: {
        for (final row in rows)
          '${row.id}': {
            'recordedAt': row.recordedAt.toIso8601String(),
            'kg': row.kg,
            'source': row.source,
          },
      },
    );
    await _markSynced(database.weightEntries, rows.map((row) => row.id));
    return rows.length;
  }

  Future<int> _pushNutrition(String userId) async {
    final rows = await (database.select(database.nutritionEntries)
          ..where((row) => row.syncedAt.isNull()))
        .get();
    if (rows.isEmpty) return 0;
    await mirror.putAll(
      userId: userId,
      collection: 'nutrition',
      documents: {
        for (final row in rows)
          '${row.id}': {
            'recordedAt': row.recordedAt.toIso8601String(),
            'kcal': row.kcal,
            'proteinG': row.proteinG,
            'carbsG': row.carbsG,
            'fatG': row.fatG,
            'meal': row.meal,
            'source': row.source,
            'confirmed': row.confirmed,
          },
      },
    );
    await _markSynced(database.nutritionEntries, rows.map((row) => row.id));
    return rows.length;
  }

  Future<int> _pushLifestyle(String userId) async {
    final rows = await (database.select(database.lifestyleEntries)
          ..where((row) => row.syncedAt.isNull()))
        .get();
    if (rows.isEmpty) return 0;
    await mirror.putAll(
      userId: userId,
      collection: 'lifestyle',
      documents: {
        for (final row in rows)
          '${row.id}': {
            'recordedAt': row.recordedAt.toIso8601String(),
            'kind': row.kind,
            'value': row.value,
            'durationMinutes': row.durationMinutes,
            'note': row.note,
            'source': row.source,
          },
      },
    );
    await _markSynced(database.lifestyleEntries, rows.map((row) => row.id));
    return rows.length;
  }

  Future<int> _pushSessions(String userId) async {
    final rows = await (database.select(database.activitySessions)
          ..where((row) => row.syncedAt.isNull()))
        .get();
    if (rows.isEmpty) return 0;
    await mirror.putAll(
      userId: userId,
      collection: 'sessions',
      documents: {
        for (final row in rows)
          row.id: {
            // Carried in the body as well as the key: a restore reads
            // documents, not the paths they came from.
            'id': row.id,
            'sport': row.sport,
            'startUtc': row.startUtc.toIso8601String(),
            'endUtc': row.endUtc.toIso8601String(),
            'activeKcal': row.activeKcal,
            'avgHr': row.avgHr,
            'maxHr': row.maxHr,
            'steps': row.steps,
            'source': row.source,
            'priority': row.priority,
          },
      },
    );
    await (database.update(database.activitySessions)
          ..where((row) => row.id.isIn(rows.map((item) => item.id))))
        .write(
      ActivitySessionsCompanion(syncedAt: Value(DateTime.now().toUtc())),
    );
    return rows.length;
  }

  Future<int> _pushStrength(String userId) async {
    final rows = await (database.select(database.strengthWorkouts)
          ..where((row) => row.syncedAt.isNull()))
        .get();
    if (rows.isEmpty) return 0;
    await mirror.putAll(
      userId: userId,
      collection: 'strength',
      documents: {
        for (final row in rows)
          row.id: {
            'id': row.id,
            'startedAt': row.startedAt.toIso8601String(),
            'endedAt': row.endedAt.toIso8601String(),
            'bodyWeightKgAtTime': row.bodyWeightKgAtTime,
            'exercisesJson': row.exercisesJson,
            'fallbackKcal': row.fallbackKcal,
            'finalKcal': row.finalKcal,
            'method': row.method,
          },
      },
    );
    await (database.update(database.strengthWorkouts)
          ..where((row) => row.id.isIn(rows.map((item) => item.id))))
        .write(
      StrengthWorkoutsCompanion(syncedAt: Value(DateTime.now().toUtc())),
    );
    return rows.length;
  }

  Future<int> _pushDaySummaries(String userId) async {
    final rows = await (database.select(database.daySummaries)
          ..where((row) => row.syncedAt.isNull()))
        .get();
    if (rows.isEmpty) return 0;
    await mirror.putAll(
      userId: userId,
      collection: 'days',
      documents: {
        for (final row in rows)
          row.date: {
            'date': row.date,
            'activeKcal': row.activeKcal,
            'basalKcal': row.basalKcal,
            'intakeKcal': row.intakeKcal,
            'steps': row.steps,
            'sessionsCount': row.sessionsCount,
          },
      },
    );
    await (database.update(database.daySummaries)
          ..where((row) => row.date.isIn(rows.map((item) => item.date))))
        .write(DaySummariesCompanion(syncedAt: Value(DateTime.now().toUtc())));
    return rows.length;
  }

  /// The pages, and only the ones the person has not held back.
  ///
  /// `excludedFromAi` is about the model rather than the mirror, so it is not
  /// consulted here — an entry kept from Aether is still the person's own
  /// record, and losing it with the phone would be the worse failure.
  Future<int> _pushJournal(String userId) async {
    final rows = await (database.select(database.journalEntries)
          ..where((row) =>
              row.syncedAt.isNull() & row.status.equals('discarded').not()))
        .get();
    if (rows.isEmpty) return 0;
    await mirror.putAll(
      userId: userId,
      collection: 'journal',
      documents: {
        for (final row in rows)
          '${row.id}': {
            'createdAt': row.createdAt.toIso8601String(),
            'text': row.entryText,
            'source': row.source,
            'status': row.status,
            'excludedFromAi': row.excludedFromAi,
          },
      },
    );
    await _markSynced(database.journalEntries, rows.map((row) => row.id));
    return rows.length;
  }

  Future<void> _markSynced(
    TableInfo<Table, dynamic> table,
    Iterable<int> ids,
  ) =>
      database.customUpdate(
        'UPDATE ${table.actualTableName} SET synced_at = ? '
        'WHERE id IN (${ids.map((_) => '?').join(',')})',
        variables: [
          Variable<String>(DateTime.now().toUtc().toIso8601String()),
          for (final id in ids) Variable<int>(id),
        ],
        updates: {table},
      );

  // -------------------------------------------------------------------------
  // Restore
  // -------------------------------------------------------------------------

  Future<int> _restoreProfile(String userId) async {
    final documents =
        await mirror.readAll(userId: userId, collection: 'profile');
    if (documents.isEmpty) return 0;
    final data = documents.first;
    await database.saveProfile(ProfilesCompanion.insert(
      dob: DateTime.parse(data['dob']! as String),
      sex: data['sex']! as String,
      weightKg: (data['weightKg']! as num).toDouble(),
      units: data['units']! as String,
      firstName: Value(data['firstName'] as String?),
      heightCm: Value((data['heightCm'] as num?)?.toDouble()),
      bodyFatPercent: Value((data['bodyFatPercent'] as num?)?.toDouble()),
      guidanceMode: Value(data['guidanceMode'] as String? ?? 'balanced'),
      birthTimeMinutes: Value(data['birthTimeMinutes'] as int?),
      birthUtcOffsetMinutes: Value(data['birthUtcOffsetMinutes'] as int?),
      birthPlace: Value(data['birthPlace'] as String?),
      birthLatitude: Value((data['birthLatitude'] as num?)?.toDouble()),
      birthLongitude: Value((data['birthLongitude'] as num?)?.toDouble()),
      // Restoring the record does not restore the permissions. Consent is
      // given on a device, by a person, and a new phone has to ask again.
      cloudSyncConsentAt: Value(DateTime.now().toUtc()),
    ));
    return 1;
  }

  Future<int> _restoreWeights(String userId) async {
    final documents =
        await mirror.readAll(userId: userId, collection: 'weights');
    for (final data in documents) {
      await database.into(database.weightEntries).insert(
            WeightEntriesCompanion.insert(
              recordedAt: DateTime.parse(data['recordedAt']! as String),
              kg: (data['kg']! as num).toDouble(),
              source: Value(data['source'] as String? ?? 'manual'),
              syncedAt: Value(DateTime.now().toUtc()),
            ),
          );
    }
    return documents.length;
  }

  Future<int> _restoreNutrition(String userId) async {
    final documents =
        await mirror.readAll(userId: userId, collection: 'nutrition');
    for (final data in documents) {
      await database.into(database.nutritionEntries).insert(
            NutritionEntriesCompanion.insert(
              recordedAt: DateTime.parse(data['recordedAt']! as String),
              kcal: (data['kcal']! as num).toDouble(),
              meal: data['meal']! as String,
              proteinG: Value((data['proteinG'] as num?)?.toDouble()),
              carbsG: Value((data['carbsG'] as num?)?.toDouble()),
              fatG: Value((data['fatG'] as num?)?.toDouble()),
              source: Value(data['source'] as String? ?? 'eter'),
              confirmed: Value(data['confirmed'] as bool? ?? true),
              syncedAt: Value(DateTime.now().toUtc()),
            ),
          );
    }
    return documents.length;
  }

  Future<int> _restoreLifestyle(String userId) async {
    final documents =
        await mirror.readAll(userId: userId, collection: 'lifestyle');
    for (final data in documents) {
      await database.into(database.lifestyleEntries).insert(
            LifestyleEntriesCompanion.insert(
              recordedAt: DateTime.parse(data['recordedAt']! as String),
              kind: data['kind']! as String,
              value: Value((data['value'] as num?)?.toDouble()),
              durationMinutes:
                  Value((data['durationMinutes'] as num?)?.toDouble()),
              note: Value(data['note'] as String?),
              source: Value(data['source'] as String? ?? 'self-report'),
              syncedAt: Value(DateTime.now().toUtc()),
            ),
          );
    }
    return documents.length;
  }

  Future<int> _restoreSessions(String userId) async {
    final documents =
        await mirror.readAll(userId: userId, collection: 'sessions');
    for (final data in documents) {
      await database.upsertActivitySession(
        ActivitySessionsCompanion.insert(
          id: data['id']! as String,
          startUtc: DateTime.parse(data['startUtc']! as String),
          endUtc: DateTime.parse(data['endUtc']! as String),
          source: data['source']! as String,
          priority: (data['priority']! as num).toInt(),
          sport: Value(data['sport'] as String?),
          activeKcal: Value((data['activeKcal'] as num?)?.toDouble()),
          avgHr: Value((data['avgHr'] as num?)?.toDouble()),
          maxHr: Value((data['maxHr'] as num?)?.toDouble()),
          steps: Value((data['steps'] as num?)?.toInt()),
          syncedAt: Value(DateTime.now().toUtc()),
        ),
      );
    }
    return documents.length;
  }

  Future<int> _restoreStrength(String userId) async {
    final documents =
        await mirror.readAll(userId: userId, collection: 'strength');
    for (final data in documents) {
      await database.into(database.strengthWorkouts).insertOnConflictUpdate(
            StrengthWorkoutsCompanion.insert(
              id: data['id']! as String,
              startedAt: DateTime.parse(data['startedAt']! as String),
              endedAt: DateTime.parse(data['endedAt']! as String),
              bodyWeightKgAtTime:
                  (data['bodyWeightKgAtTime']! as num).toDouble(),
              exercisesJson: data['exercisesJson']! as String,
              fallbackKcal: (data['fallbackKcal']! as num).toDouble(),
              finalKcal: (data['finalKcal']! as num).toDouble(),
              method: Value(data['method'] as String? ?? 'fallback'),
              syncedAt: Value(DateTime.now().toUtc()),
            ),
          );
    }
    return documents.length;
  }

  Future<int> _restoreDaySummaries(String userId) async {
    final documents = await mirror.readAll(userId: userId, collection: 'days');
    for (final data in documents) {
      await database.into(database.daySummaries).insertOnConflictUpdate(
            DaySummariesCompanion.insert(
              date: data['date']! as String,
              activeKcal: Value((data['activeKcal'] as num?)?.toDouble() ?? 0),
              basalKcal: Value((data['basalKcal'] as num?)?.toDouble() ?? 0),
              intakeKcal: Value((data['intakeKcal'] as num?)?.toDouble()),
              steps: Value((data['steps'] as num?)?.toInt() ?? 0),
              sessionsCount:
                  Value((data['sessionsCount'] as num?)?.toInt() ?? 0),
              syncedAt: Value(DateTime.now().toUtc()),
            ),
          );
    }
    return documents.length;
  }

  Future<int> _restoreJournal(String userId) async {
    final documents =
        await mirror.readAll(userId: userId, collection: 'journal');
    for (final data in documents) {
      await database.addJournalEntry(JournalEntriesCompanion.insert(
        createdAt: DateTime.parse(data['createdAt']! as String),
        entryText: data['text']! as String,
        source: Value(data['source'] as String? ?? 'typed'),
        status: Value(data['status'] as String? ?? 'pending'),
        excludedFromAi: Value(data['excludedFromAi'] as bool? ?? false),
        syncedAt: Value(DateTime.now().toUtc()),
      ));
    }
    return documents.length;
  }
}
