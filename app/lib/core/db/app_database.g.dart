// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $ProfilesTable extends Profiles
    with TableInfo<$ProfilesTable, ProfileRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ProfilesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(1));
  static const VerificationMeta _dobMeta = const VerificationMeta('dob');
  @override
  late final GeneratedColumn<DateTime> dob = GeneratedColumn<DateTime>(
      'dob', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _sexMeta = const VerificationMeta('sex');
  @override
  late final GeneratedColumn<String> sex = GeneratedColumn<String>(
      'sex', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _weightKgMeta =
      const VerificationMeta('weightKg');
  @override
  late final GeneratedColumn<double> weightKg = GeneratedColumn<double>(
      'weight_kg', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _heightCmMeta =
      const VerificationMeta('heightCm');
  @override
  late final GeneratedColumn<double> heightCm = GeneratedColumn<double>(
      'height_cm', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _bodyFatPercentMeta =
      const VerificationMeta('bodyFatPercent');
  @override
  late final GeneratedColumn<double> bodyFatPercent = GeneratedColumn<double>(
      'body_fat_percent', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _unitsMeta = const VerificationMeta('units');
  @override
  late final GeneratedColumn<String> units = GeneratedColumn<String>(
      'units', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _firstNameMeta =
      const VerificationMeta('firstName');
  @override
  late final GeneratedColumn<String> firstName = GeneratedColumn<String>(
      'first_name', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _hapticsEnabledMeta =
      const VerificationMeta('hapticsEnabled');
  @override
  late final GeneratedColumn<bool> hapticsEnabled = GeneratedColumn<bool>(
      'haptics_enabled', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("haptics_enabled" IN (0, 1))'),
      defaultValue: const Constant(true));
  static const VerificationMeta _guidanceModeMeta =
      const VerificationMeta('guidanceMode');
  @override
  late final GeneratedColumn<String> guidanceMode = GeneratedColumn<String>(
      'guidance_mode', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('balanced'));
  static const VerificationMeta _startSurfaceMeta =
      const VerificationMeta('startSurface');
  @override
  late final GeneratedColumn<String> startSurface = GeneratedColumn<String>(
      'start_surface', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('dashboard'));
  static const VerificationMeta _birthTimeMinutesMeta =
      const VerificationMeta('birthTimeMinutes');
  @override
  late final GeneratedColumn<int> birthTimeMinutes = GeneratedColumn<int>(
      'birth_time_minutes', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _birthTimePrecisionMeta =
      const VerificationMeta('birthTimePrecision');
  @override
  late final GeneratedColumn<String> birthTimePrecision =
      GeneratedColumn<String>('birth_time_precision', aliasedName, false,
          type: DriftSqlType.string,
          requiredDuringInsert: false,
          defaultValue: const Constant('unknown'));
  static const VerificationMeta _birthUtcOffsetMinutesMeta =
      const VerificationMeta('birthUtcOffsetMinutes');
  @override
  late final GeneratedColumn<int> birthUtcOffsetMinutes = GeneratedColumn<int>(
      'birth_utc_offset_minutes', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _birthPlaceMeta =
      const VerificationMeta('birthPlace');
  @override
  late final GeneratedColumn<String> birthPlace = GeneratedColumn<String>(
      'birth_place', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _birthLatitudeMeta =
      const VerificationMeta('birthLatitude');
  @override
  late final GeneratedColumn<double> birthLatitude = GeneratedColumn<double>(
      'birth_latitude', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _birthLongitudeMeta =
      const VerificationMeta('birthLongitude');
  @override
  late final GeneratedColumn<double> birthLongitude = GeneratedColumn<double>(
      'birth_longitude', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _aiConsentAtMeta =
      const VerificationMeta('aiConsentAt');
  @override
  late final GeneratedColumn<DateTime> aiConsentAt = GeneratedColumn<DateTime>(
      'ai_consent_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _journalAiConsentAtMeta =
      const VerificationMeta('journalAiConsentAt');
  @override
  late final GeneratedColumn<DateTime> journalAiConsentAt =
      GeneratedColumn<DateTime>('journal_ai_consent_at', aliasedName, true,
          type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _crashReportConsentAtMeta =
      const VerificationMeta('crashReportConsentAt');
  @override
  late final GeneratedColumn<DateTime> crashReportConsentAt =
      GeneratedColumn<DateTime>('crash_report_consent_at', aliasedName, true,
          type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _cloudSyncConsentAtMeta =
      const VerificationMeta('cloudSyncConsentAt');
  @override
  late final GeneratedColumn<DateTime> cloudSyncConsentAt =
      GeneratedColumn<DateTime>('cloud_sync_consent_at', aliasedName, true,
          type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _journalCloudSyncConsentAtMeta =
      const VerificationMeta('journalCloudSyncConsentAt');
  @override
  late final GeneratedColumn<DateTime> journalCloudSyncConsentAt =
      GeneratedColumn<DateTime>(
          'journal_cloud_sync_consent_at', aliasedName, true,
          type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _connectedSourcesJsonMeta =
      const VerificationMeta('connectedSourcesJson');
  @override
  late final GeneratedColumn<String> connectedSourcesJson =
      GeneratedColumn<String>('connected_sources_json', aliasedName, false,
          type: DriftSqlType.string,
          requiredDuringInsert: false,
          defaultValue: const Constant('[]'));
  static const VerificationMeta _syncedAtMeta =
      const VerificationMeta('syncedAt');
  @override
  late final GeneratedColumn<DateTime> syncedAt = GeneratedColumn<DateTime>(
      'synced_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        dob,
        sex,
        weightKg,
        heightCm,
        bodyFatPercent,
        units,
        firstName,
        hapticsEnabled,
        guidanceMode,
        startSurface,
        birthTimeMinutes,
        birthTimePrecision,
        birthUtcOffsetMinutes,
        birthPlace,
        birthLatitude,
        birthLongitude,
        aiConsentAt,
        journalAiConsentAt,
        crashReportConsentAt,
        cloudSyncConsentAt,
        journalCloudSyncConsentAt,
        connectedSourcesJson,
        syncedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'profiles';
  @override
  VerificationContext validateIntegrity(Insertable<ProfileRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('dob')) {
      context.handle(
          _dobMeta, dob.isAcceptableOrUnknown(data['dob']!, _dobMeta));
    } else if (isInserting) {
      context.missing(_dobMeta);
    }
    if (data.containsKey('sex')) {
      context.handle(
          _sexMeta, sex.isAcceptableOrUnknown(data['sex']!, _sexMeta));
    } else if (isInserting) {
      context.missing(_sexMeta);
    }
    if (data.containsKey('weight_kg')) {
      context.handle(_weightKgMeta,
          weightKg.isAcceptableOrUnknown(data['weight_kg']!, _weightKgMeta));
    } else if (isInserting) {
      context.missing(_weightKgMeta);
    }
    if (data.containsKey('height_cm')) {
      context.handle(_heightCmMeta,
          heightCm.isAcceptableOrUnknown(data['height_cm']!, _heightCmMeta));
    }
    if (data.containsKey('body_fat_percent')) {
      context.handle(
          _bodyFatPercentMeta,
          bodyFatPercent.isAcceptableOrUnknown(
              data['body_fat_percent']!, _bodyFatPercentMeta));
    }
    if (data.containsKey('units')) {
      context.handle(
          _unitsMeta, units.isAcceptableOrUnknown(data['units']!, _unitsMeta));
    } else if (isInserting) {
      context.missing(_unitsMeta);
    }
    if (data.containsKey('first_name')) {
      context.handle(_firstNameMeta,
          firstName.isAcceptableOrUnknown(data['first_name']!, _firstNameMeta));
    }
    if (data.containsKey('haptics_enabled')) {
      context.handle(
          _hapticsEnabledMeta,
          hapticsEnabled.isAcceptableOrUnknown(
              data['haptics_enabled']!, _hapticsEnabledMeta));
    }
    if (data.containsKey('guidance_mode')) {
      context.handle(
          _guidanceModeMeta,
          guidanceMode.isAcceptableOrUnknown(
              data['guidance_mode']!, _guidanceModeMeta));
    }
    if (data.containsKey('start_surface')) {
      context.handle(
          _startSurfaceMeta,
          startSurface.isAcceptableOrUnknown(
              data['start_surface']!, _startSurfaceMeta));
    }
    if (data.containsKey('birth_time_minutes')) {
      context.handle(
          _birthTimeMinutesMeta,
          birthTimeMinutes.isAcceptableOrUnknown(
              data['birth_time_minutes']!, _birthTimeMinutesMeta));
    }
    if (data.containsKey('birth_time_precision')) {
      context.handle(
          _birthTimePrecisionMeta,
          birthTimePrecision.isAcceptableOrUnknown(
              data['birth_time_precision']!, _birthTimePrecisionMeta));
    }
    if (data.containsKey('birth_utc_offset_minutes')) {
      context.handle(
          _birthUtcOffsetMinutesMeta,
          birthUtcOffsetMinutes.isAcceptableOrUnknown(
              data['birth_utc_offset_minutes']!, _birthUtcOffsetMinutesMeta));
    }
    if (data.containsKey('birth_place')) {
      context.handle(
          _birthPlaceMeta,
          birthPlace.isAcceptableOrUnknown(
              data['birth_place']!, _birthPlaceMeta));
    }
    if (data.containsKey('birth_latitude')) {
      context.handle(
          _birthLatitudeMeta,
          birthLatitude.isAcceptableOrUnknown(
              data['birth_latitude']!, _birthLatitudeMeta));
    }
    if (data.containsKey('birth_longitude')) {
      context.handle(
          _birthLongitudeMeta,
          birthLongitude.isAcceptableOrUnknown(
              data['birth_longitude']!, _birthLongitudeMeta));
    }
    if (data.containsKey('ai_consent_at')) {
      context.handle(
          _aiConsentAtMeta,
          aiConsentAt.isAcceptableOrUnknown(
              data['ai_consent_at']!, _aiConsentAtMeta));
    }
    if (data.containsKey('journal_ai_consent_at')) {
      context.handle(
          _journalAiConsentAtMeta,
          journalAiConsentAt.isAcceptableOrUnknown(
              data['journal_ai_consent_at']!, _journalAiConsentAtMeta));
    }
    if (data.containsKey('crash_report_consent_at')) {
      context.handle(
          _crashReportConsentAtMeta,
          crashReportConsentAt.isAcceptableOrUnknown(
              data['crash_report_consent_at']!, _crashReportConsentAtMeta));
    }
    if (data.containsKey('cloud_sync_consent_at')) {
      context.handle(
          _cloudSyncConsentAtMeta,
          cloudSyncConsentAt.isAcceptableOrUnknown(
              data['cloud_sync_consent_at']!, _cloudSyncConsentAtMeta));
    }
    if (data.containsKey('journal_cloud_sync_consent_at')) {
      context.handle(
          _journalCloudSyncConsentAtMeta,
          journalCloudSyncConsentAt.isAcceptableOrUnknown(
              data['journal_cloud_sync_consent_at']!,
              _journalCloudSyncConsentAtMeta));
    }
    if (data.containsKey('connected_sources_json')) {
      context.handle(
          _connectedSourcesJsonMeta,
          connectedSourcesJson.isAcceptableOrUnknown(
              data['connected_sources_json']!, _connectedSourcesJsonMeta));
    }
    if (data.containsKey('synced_at')) {
      context.handle(_syncedAtMeta,
          syncedAt.isAcceptableOrUnknown(data['synced_at']!, _syncedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ProfileRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ProfileRow(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      dob: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}dob'])!,
      sex: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}sex'])!,
      weightKg: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}weight_kg'])!,
      heightCm: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}height_cm']),
      bodyFatPercent: attachedDatabase.typeMapping.read(
          DriftSqlType.double, data['${effectivePrefix}body_fat_percent']),
      units: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}units'])!,
      firstName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}first_name']),
      hapticsEnabled: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}haptics_enabled'])!,
      guidanceMode: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}guidance_mode'])!,
      startSurface: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}start_surface'])!,
      birthTimeMinutes: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}birth_time_minutes']),
      birthTimePrecision: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}birth_time_precision'])!,
      birthUtcOffsetMinutes: attachedDatabase.typeMapping.read(
          DriftSqlType.int, data['${effectivePrefix}birth_utc_offset_minutes']),
      birthPlace: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}birth_place']),
      birthLatitude: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}birth_latitude']),
      birthLongitude: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}birth_longitude']),
      aiConsentAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}ai_consent_at']),
      journalAiConsentAt: attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime,
          data['${effectivePrefix}journal_ai_consent_at']),
      crashReportConsentAt: attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime,
          data['${effectivePrefix}crash_report_consent_at']),
      cloudSyncConsentAt: attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime,
          data['${effectivePrefix}cloud_sync_consent_at']),
      journalCloudSyncConsentAt: attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime,
          data['${effectivePrefix}journal_cloud_sync_consent_at']),
      connectedSourcesJson: attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}connected_sources_json'])!,
      syncedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}synced_at']),
    );
  }

  @override
  $ProfilesTable createAlias(String alias) {
    return $ProfilesTable(attachedDatabase, alias);
  }
}

class ProfileRow extends DataClass implements Insertable<ProfileRow> {
  final int id;
  final DateTime dob;

  /// `female` | `male` | `other`.
  ///
  /// v1 emitted `unspecified` from Dart while firestore.rules only allowed
  /// `other`, so those users' profile mirrors were rejected and the error was
  /// swallowed. The names now agree; do not change one without the other.
  final String sex;
  final double weightKg;
  final double? heightCm;

  /// Optional body fat, 5–40% in 2.5-point steps. Null means unknown, which is
  /// the honest and common case — it is never estimated from weight and height.
  ///
  /// When present it improves two different things: resting burn is derived
  /// from lean mass (Katch-McArdle) rather than from body mass alone, and the
  /// guidance context can speak about composition instead of a single number.
  final double? bodyFatPercent;
  final String units;
  final String? firstName;
  final bool hapticsEnabled;

  /// `grounded` | `balanced` | `immersive`. The setting, not the appearance —
  /// `balanced` resolves against real sunrise and sunset at run time.
  final String guidanceMode;

  /// `journal` | `dashboard`. Which surface the app opens on.
  final String startSurface;

  /// Birth data. Nullable because only the date is required; the chart
  /// degrades gracefully without a time or place.
  final int? birthTimeMinutes;

  /// `exact` | `approximate` | `unknown`. See `core/profile/birth_time.dart`.
  ///
  /// Distinguishes a time read off a record from a period someone remembers.
  /// Both produce an ascendant; only the first earns one stated without a
  /// hedge, because the ascendant crosses a sign roughly every two hours.
  final String birthTimePrecision;
  final int? birthUtcOffsetMinutes;
  final String? birthPlace;
  final double? birthLatitude;
  final double? birthLongitude;

  /// When the user consented to AI processing, and to journal prose crossing
  /// the boundary specifically. Null means never — and with these null the
  /// guidance pipeline must not send prose. Separate fields because they are
  /// separate decisions and the second is the consequential one.
  final DateTime? aiConsentAt;
  final DateTime? journalAiConsentAt;

  /// When the user agreed to send crash reports. Null means never, which is
  /// the default and the shipped state until someone chooses otherwise.
  ///
  /// A crash report carries a stack trace, a device model and an OS version.
  /// It never carries a journal page, a measurement or an identifier Eter
  /// chose — see `core/diagnostics/crash_reporter.dart`, which is where that
  /// promise is kept rather than merely stated.
  final DateTime? crashReportConsentAt;

  /// When the user consented to cloud sync. Null means local-only.
  ///
  /// This covers the measured record: weights, meals, sessions, sleep, day
  /// totals. It deliberately does not cover journal prose.
  final DateTime? cloudSyncConsentAt;

  /// When the user consented to their journal prose leaving the device for
  /// the mirror specifically.
  ///
  /// Separate for the same reason [journalAiConsentAt] is separate from
  /// [aiConsentAt]: the pages are the most personal thing in the database and
  /// agreeing to keep a copy of your weights is not agreeing to keep a copy of
  /// what you wrote at 2am. A person can have full recovery of their body log
  /// and no copy of their journal anywhere but this phone.
  final DateTime? journalCloudSyncConsentAt;
  final String connectedSourcesJson;
  final DateTime? syncedAt;
  const ProfileRow(
      {required this.id,
      required this.dob,
      required this.sex,
      required this.weightKg,
      this.heightCm,
      this.bodyFatPercent,
      required this.units,
      this.firstName,
      required this.hapticsEnabled,
      required this.guidanceMode,
      required this.startSurface,
      this.birthTimeMinutes,
      required this.birthTimePrecision,
      this.birthUtcOffsetMinutes,
      this.birthPlace,
      this.birthLatitude,
      this.birthLongitude,
      this.aiConsentAt,
      this.journalAiConsentAt,
      this.crashReportConsentAt,
      this.cloudSyncConsentAt,
      this.journalCloudSyncConsentAt,
      required this.connectedSourcesJson,
      this.syncedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['dob'] = Variable<DateTime>(dob);
    map['sex'] = Variable<String>(sex);
    map['weight_kg'] = Variable<double>(weightKg);
    if (!nullToAbsent || heightCm != null) {
      map['height_cm'] = Variable<double>(heightCm);
    }
    if (!nullToAbsent || bodyFatPercent != null) {
      map['body_fat_percent'] = Variable<double>(bodyFatPercent);
    }
    map['units'] = Variable<String>(units);
    if (!nullToAbsent || firstName != null) {
      map['first_name'] = Variable<String>(firstName);
    }
    map['haptics_enabled'] = Variable<bool>(hapticsEnabled);
    map['guidance_mode'] = Variable<String>(guidanceMode);
    map['start_surface'] = Variable<String>(startSurface);
    if (!nullToAbsent || birthTimeMinutes != null) {
      map['birth_time_minutes'] = Variable<int>(birthTimeMinutes);
    }
    map['birth_time_precision'] = Variable<String>(birthTimePrecision);
    if (!nullToAbsent || birthUtcOffsetMinutes != null) {
      map['birth_utc_offset_minutes'] = Variable<int>(birthUtcOffsetMinutes);
    }
    if (!nullToAbsent || birthPlace != null) {
      map['birth_place'] = Variable<String>(birthPlace);
    }
    if (!nullToAbsent || birthLatitude != null) {
      map['birth_latitude'] = Variable<double>(birthLatitude);
    }
    if (!nullToAbsent || birthLongitude != null) {
      map['birth_longitude'] = Variable<double>(birthLongitude);
    }
    if (!nullToAbsent || aiConsentAt != null) {
      map['ai_consent_at'] = Variable<DateTime>(aiConsentAt);
    }
    if (!nullToAbsent || journalAiConsentAt != null) {
      map['journal_ai_consent_at'] = Variable<DateTime>(journalAiConsentAt);
    }
    if (!nullToAbsent || crashReportConsentAt != null) {
      map['crash_report_consent_at'] = Variable<DateTime>(crashReportConsentAt);
    }
    if (!nullToAbsent || cloudSyncConsentAt != null) {
      map['cloud_sync_consent_at'] = Variable<DateTime>(cloudSyncConsentAt);
    }
    if (!nullToAbsent || journalCloudSyncConsentAt != null) {
      map['journal_cloud_sync_consent_at'] =
          Variable<DateTime>(journalCloudSyncConsentAt);
    }
    map['connected_sources_json'] = Variable<String>(connectedSourcesJson);
    if (!nullToAbsent || syncedAt != null) {
      map['synced_at'] = Variable<DateTime>(syncedAt);
    }
    return map;
  }

  ProfilesCompanion toCompanion(bool nullToAbsent) {
    return ProfilesCompanion(
      id: Value(id),
      dob: Value(dob),
      sex: Value(sex),
      weightKg: Value(weightKg),
      heightCm: heightCm == null && nullToAbsent
          ? const Value.absent()
          : Value(heightCm),
      bodyFatPercent: bodyFatPercent == null && nullToAbsent
          ? const Value.absent()
          : Value(bodyFatPercent),
      units: Value(units),
      firstName: firstName == null && nullToAbsent
          ? const Value.absent()
          : Value(firstName),
      hapticsEnabled: Value(hapticsEnabled),
      guidanceMode: Value(guidanceMode),
      startSurface: Value(startSurface),
      birthTimeMinutes: birthTimeMinutes == null && nullToAbsent
          ? const Value.absent()
          : Value(birthTimeMinutes),
      birthTimePrecision: Value(birthTimePrecision),
      birthUtcOffsetMinutes: birthUtcOffsetMinutes == null && nullToAbsent
          ? const Value.absent()
          : Value(birthUtcOffsetMinutes),
      birthPlace: birthPlace == null && nullToAbsent
          ? const Value.absent()
          : Value(birthPlace),
      birthLatitude: birthLatitude == null && nullToAbsent
          ? const Value.absent()
          : Value(birthLatitude),
      birthLongitude: birthLongitude == null && nullToAbsent
          ? const Value.absent()
          : Value(birthLongitude),
      aiConsentAt: aiConsentAt == null && nullToAbsent
          ? const Value.absent()
          : Value(aiConsentAt),
      journalAiConsentAt: journalAiConsentAt == null && nullToAbsent
          ? const Value.absent()
          : Value(journalAiConsentAt),
      crashReportConsentAt: crashReportConsentAt == null && nullToAbsent
          ? const Value.absent()
          : Value(crashReportConsentAt),
      cloudSyncConsentAt: cloudSyncConsentAt == null && nullToAbsent
          ? const Value.absent()
          : Value(cloudSyncConsentAt),
      journalCloudSyncConsentAt:
          journalCloudSyncConsentAt == null && nullToAbsent
              ? const Value.absent()
              : Value(journalCloudSyncConsentAt),
      connectedSourcesJson: Value(connectedSourcesJson),
      syncedAt: syncedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(syncedAt),
    );
  }

  factory ProfileRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ProfileRow(
      id: serializer.fromJson<int>(json['id']),
      dob: serializer.fromJson<DateTime>(json['dob']),
      sex: serializer.fromJson<String>(json['sex']),
      weightKg: serializer.fromJson<double>(json['weightKg']),
      heightCm: serializer.fromJson<double?>(json['heightCm']),
      bodyFatPercent: serializer.fromJson<double?>(json['bodyFatPercent']),
      units: serializer.fromJson<String>(json['units']),
      firstName: serializer.fromJson<String?>(json['firstName']),
      hapticsEnabled: serializer.fromJson<bool>(json['hapticsEnabled']),
      guidanceMode: serializer.fromJson<String>(json['guidanceMode']),
      startSurface: serializer.fromJson<String>(json['startSurface']),
      birthTimeMinutes: serializer.fromJson<int?>(json['birthTimeMinutes']),
      birthTimePrecision:
          serializer.fromJson<String>(json['birthTimePrecision']),
      birthUtcOffsetMinutes:
          serializer.fromJson<int?>(json['birthUtcOffsetMinutes']),
      birthPlace: serializer.fromJson<String?>(json['birthPlace']),
      birthLatitude: serializer.fromJson<double?>(json['birthLatitude']),
      birthLongitude: serializer.fromJson<double?>(json['birthLongitude']),
      aiConsentAt: serializer.fromJson<DateTime?>(json['aiConsentAt']),
      journalAiConsentAt:
          serializer.fromJson<DateTime?>(json['journalAiConsentAt']),
      crashReportConsentAt:
          serializer.fromJson<DateTime?>(json['crashReportConsentAt']),
      cloudSyncConsentAt:
          serializer.fromJson<DateTime?>(json['cloudSyncConsentAt']),
      journalCloudSyncConsentAt:
          serializer.fromJson<DateTime?>(json['journalCloudSyncConsentAt']),
      connectedSourcesJson:
          serializer.fromJson<String>(json['connectedSourcesJson']),
      syncedAt: serializer.fromJson<DateTime?>(json['syncedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'dob': serializer.toJson<DateTime>(dob),
      'sex': serializer.toJson<String>(sex),
      'weightKg': serializer.toJson<double>(weightKg),
      'heightCm': serializer.toJson<double?>(heightCm),
      'bodyFatPercent': serializer.toJson<double?>(bodyFatPercent),
      'units': serializer.toJson<String>(units),
      'firstName': serializer.toJson<String?>(firstName),
      'hapticsEnabled': serializer.toJson<bool>(hapticsEnabled),
      'guidanceMode': serializer.toJson<String>(guidanceMode),
      'startSurface': serializer.toJson<String>(startSurface),
      'birthTimeMinutes': serializer.toJson<int?>(birthTimeMinutes),
      'birthTimePrecision': serializer.toJson<String>(birthTimePrecision),
      'birthUtcOffsetMinutes': serializer.toJson<int?>(birthUtcOffsetMinutes),
      'birthPlace': serializer.toJson<String?>(birthPlace),
      'birthLatitude': serializer.toJson<double?>(birthLatitude),
      'birthLongitude': serializer.toJson<double?>(birthLongitude),
      'aiConsentAt': serializer.toJson<DateTime?>(aiConsentAt),
      'journalAiConsentAt': serializer.toJson<DateTime?>(journalAiConsentAt),
      'crashReportConsentAt':
          serializer.toJson<DateTime?>(crashReportConsentAt),
      'cloudSyncConsentAt': serializer.toJson<DateTime?>(cloudSyncConsentAt),
      'journalCloudSyncConsentAt':
          serializer.toJson<DateTime?>(journalCloudSyncConsentAt),
      'connectedSourcesJson': serializer.toJson<String>(connectedSourcesJson),
      'syncedAt': serializer.toJson<DateTime?>(syncedAt),
    };
  }

  ProfileRow copyWith(
          {int? id,
          DateTime? dob,
          String? sex,
          double? weightKg,
          Value<double?> heightCm = const Value.absent(),
          Value<double?> bodyFatPercent = const Value.absent(),
          String? units,
          Value<String?> firstName = const Value.absent(),
          bool? hapticsEnabled,
          String? guidanceMode,
          String? startSurface,
          Value<int?> birthTimeMinutes = const Value.absent(),
          String? birthTimePrecision,
          Value<int?> birthUtcOffsetMinutes = const Value.absent(),
          Value<String?> birthPlace = const Value.absent(),
          Value<double?> birthLatitude = const Value.absent(),
          Value<double?> birthLongitude = const Value.absent(),
          Value<DateTime?> aiConsentAt = const Value.absent(),
          Value<DateTime?> journalAiConsentAt = const Value.absent(),
          Value<DateTime?> crashReportConsentAt = const Value.absent(),
          Value<DateTime?> cloudSyncConsentAt = const Value.absent(),
          Value<DateTime?> journalCloudSyncConsentAt = const Value.absent(),
          String? connectedSourcesJson,
          Value<DateTime?> syncedAt = const Value.absent()}) =>
      ProfileRow(
        id: id ?? this.id,
        dob: dob ?? this.dob,
        sex: sex ?? this.sex,
        weightKg: weightKg ?? this.weightKg,
        heightCm: heightCm.present ? heightCm.value : this.heightCm,
        bodyFatPercent:
            bodyFatPercent.present ? bodyFatPercent.value : this.bodyFatPercent,
        units: units ?? this.units,
        firstName: firstName.present ? firstName.value : this.firstName,
        hapticsEnabled: hapticsEnabled ?? this.hapticsEnabled,
        guidanceMode: guidanceMode ?? this.guidanceMode,
        startSurface: startSurface ?? this.startSurface,
        birthTimeMinutes: birthTimeMinutes.present
            ? birthTimeMinutes.value
            : this.birthTimeMinutes,
        birthTimePrecision: birthTimePrecision ?? this.birthTimePrecision,
        birthUtcOffsetMinutes: birthUtcOffsetMinutes.present
            ? birthUtcOffsetMinutes.value
            : this.birthUtcOffsetMinutes,
        birthPlace: birthPlace.present ? birthPlace.value : this.birthPlace,
        birthLatitude:
            birthLatitude.present ? birthLatitude.value : this.birthLatitude,
        birthLongitude:
            birthLongitude.present ? birthLongitude.value : this.birthLongitude,
        aiConsentAt: aiConsentAt.present ? aiConsentAt.value : this.aiConsentAt,
        journalAiConsentAt: journalAiConsentAt.present
            ? journalAiConsentAt.value
            : this.journalAiConsentAt,
        crashReportConsentAt: crashReportConsentAt.present
            ? crashReportConsentAt.value
            : this.crashReportConsentAt,
        cloudSyncConsentAt: cloudSyncConsentAt.present
            ? cloudSyncConsentAt.value
            : this.cloudSyncConsentAt,
        journalCloudSyncConsentAt: journalCloudSyncConsentAt.present
            ? journalCloudSyncConsentAt.value
            : this.journalCloudSyncConsentAt,
        connectedSourcesJson: connectedSourcesJson ?? this.connectedSourcesJson,
        syncedAt: syncedAt.present ? syncedAt.value : this.syncedAt,
      );
  ProfileRow copyWithCompanion(ProfilesCompanion data) {
    return ProfileRow(
      id: data.id.present ? data.id.value : this.id,
      dob: data.dob.present ? data.dob.value : this.dob,
      sex: data.sex.present ? data.sex.value : this.sex,
      weightKg: data.weightKg.present ? data.weightKg.value : this.weightKg,
      heightCm: data.heightCm.present ? data.heightCm.value : this.heightCm,
      bodyFatPercent: data.bodyFatPercent.present
          ? data.bodyFatPercent.value
          : this.bodyFatPercent,
      units: data.units.present ? data.units.value : this.units,
      firstName: data.firstName.present ? data.firstName.value : this.firstName,
      hapticsEnabled: data.hapticsEnabled.present
          ? data.hapticsEnabled.value
          : this.hapticsEnabled,
      guidanceMode: data.guidanceMode.present
          ? data.guidanceMode.value
          : this.guidanceMode,
      startSurface: data.startSurface.present
          ? data.startSurface.value
          : this.startSurface,
      birthTimeMinutes: data.birthTimeMinutes.present
          ? data.birthTimeMinutes.value
          : this.birthTimeMinutes,
      birthTimePrecision: data.birthTimePrecision.present
          ? data.birthTimePrecision.value
          : this.birthTimePrecision,
      birthUtcOffsetMinutes: data.birthUtcOffsetMinutes.present
          ? data.birthUtcOffsetMinutes.value
          : this.birthUtcOffsetMinutes,
      birthPlace:
          data.birthPlace.present ? data.birthPlace.value : this.birthPlace,
      birthLatitude: data.birthLatitude.present
          ? data.birthLatitude.value
          : this.birthLatitude,
      birthLongitude: data.birthLongitude.present
          ? data.birthLongitude.value
          : this.birthLongitude,
      aiConsentAt:
          data.aiConsentAt.present ? data.aiConsentAt.value : this.aiConsentAt,
      journalAiConsentAt: data.journalAiConsentAt.present
          ? data.journalAiConsentAt.value
          : this.journalAiConsentAt,
      crashReportConsentAt: data.crashReportConsentAt.present
          ? data.crashReportConsentAt.value
          : this.crashReportConsentAt,
      cloudSyncConsentAt: data.cloudSyncConsentAt.present
          ? data.cloudSyncConsentAt.value
          : this.cloudSyncConsentAt,
      journalCloudSyncConsentAt: data.journalCloudSyncConsentAt.present
          ? data.journalCloudSyncConsentAt.value
          : this.journalCloudSyncConsentAt,
      connectedSourcesJson: data.connectedSourcesJson.present
          ? data.connectedSourcesJson.value
          : this.connectedSourcesJson,
      syncedAt: data.syncedAt.present ? data.syncedAt.value : this.syncedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ProfileRow(')
          ..write('id: $id, ')
          ..write('dob: $dob, ')
          ..write('sex: $sex, ')
          ..write('weightKg: $weightKg, ')
          ..write('heightCm: $heightCm, ')
          ..write('bodyFatPercent: $bodyFatPercent, ')
          ..write('units: $units, ')
          ..write('firstName: $firstName, ')
          ..write('hapticsEnabled: $hapticsEnabled, ')
          ..write('guidanceMode: $guidanceMode, ')
          ..write('startSurface: $startSurface, ')
          ..write('birthTimeMinutes: $birthTimeMinutes, ')
          ..write('birthTimePrecision: $birthTimePrecision, ')
          ..write('birthUtcOffsetMinutes: $birthUtcOffsetMinutes, ')
          ..write('birthPlace: $birthPlace, ')
          ..write('birthLatitude: $birthLatitude, ')
          ..write('birthLongitude: $birthLongitude, ')
          ..write('aiConsentAt: $aiConsentAt, ')
          ..write('journalAiConsentAt: $journalAiConsentAt, ')
          ..write('crashReportConsentAt: $crashReportConsentAt, ')
          ..write('cloudSyncConsentAt: $cloudSyncConsentAt, ')
          ..write('journalCloudSyncConsentAt: $journalCloudSyncConsentAt, ')
          ..write('connectedSourcesJson: $connectedSourcesJson, ')
          ..write('syncedAt: $syncedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
        id,
        dob,
        sex,
        weightKg,
        heightCm,
        bodyFatPercent,
        units,
        firstName,
        hapticsEnabled,
        guidanceMode,
        startSurface,
        birthTimeMinutes,
        birthTimePrecision,
        birthUtcOffsetMinutes,
        birthPlace,
        birthLatitude,
        birthLongitude,
        aiConsentAt,
        journalAiConsentAt,
        crashReportConsentAt,
        cloudSyncConsentAt,
        journalCloudSyncConsentAt,
        connectedSourcesJson,
        syncedAt
      ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ProfileRow &&
          other.id == this.id &&
          other.dob == this.dob &&
          other.sex == this.sex &&
          other.weightKg == this.weightKg &&
          other.heightCm == this.heightCm &&
          other.bodyFatPercent == this.bodyFatPercent &&
          other.units == this.units &&
          other.firstName == this.firstName &&
          other.hapticsEnabled == this.hapticsEnabled &&
          other.guidanceMode == this.guidanceMode &&
          other.startSurface == this.startSurface &&
          other.birthTimeMinutes == this.birthTimeMinutes &&
          other.birthTimePrecision == this.birthTimePrecision &&
          other.birthUtcOffsetMinutes == this.birthUtcOffsetMinutes &&
          other.birthPlace == this.birthPlace &&
          other.birthLatitude == this.birthLatitude &&
          other.birthLongitude == this.birthLongitude &&
          other.aiConsentAt == this.aiConsentAt &&
          other.journalAiConsentAt == this.journalAiConsentAt &&
          other.crashReportConsentAt == this.crashReportConsentAt &&
          other.cloudSyncConsentAt == this.cloudSyncConsentAt &&
          other.journalCloudSyncConsentAt == this.journalCloudSyncConsentAt &&
          other.connectedSourcesJson == this.connectedSourcesJson &&
          other.syncedAt == this.syncedAt);
}

class ProfilesCompanion extends UpdateCompanion<ProfileRow> {
  final Value<int> id;
  final Value<DateTime> dob;
  final Value<String> sex;
  final Value<double> weightKg;
  final Value<double?> heightCm;
  final Value<double?> bodyFatPercent;
  final Value<String> units;
  final Value<String?> firstName;
  final Value<bool> hapticsEnabled;
  final Value<String> guidanceMode;
  final Value<String> startSurface;
  final Value<int?> birthTimeMinutes;
  final Value<String> birthTimePrecision;
  final Value<int?> birthUtcOffsetMinutes;
  final Value<String?> birthPlace;
  final Value<double?> birthLatitude;
  final Value<double?> birthLongitude;
  final Value<DateTime?> aiConsentAt;
  final Value<DateTime?> journalAiConsentAt;
  final Value<DateTime?> crashReportConsentAt;
  final Value<DateTime?> cloudSyncConsentAt;
  final Value<DateTime?> journalCloudSyncConsentAt;
  final Value<String> connectedSourcesJson;
  final Value<DateTime?> syncedAt;
  const ProfilesCompanion({
    this.id = const Value.absent(),
    this.dob = const Value.absent(),
    this.sex = const Value.absent(),
    this.weightKg = const Value.absent(),
    this.heightCm = const Value.absent(),
    this.bodyFatPercent = const Value.absent(),
    this.units = const Value.absent(),
    this.firstName = const Value.absent(),
    this.hapticsEnabled = const Value.absent(),
    this.guidanceMode = const Value.absent(),
    this.startSurface = const Value.absent(),
    this.birthTimeMinutes = const Value.absent(),
    this.birthTimePrecision = const Value.absent(),
    this.birthUtcOffsetMinutes = const Value.absent(),
    this.birthPlace = const Value.absent(),
    this.birthLatitude = const Value.absent(),
    this.birthLongitude = const Value.absent(),
    this.aiConsentAt = const Value.absent(),
    this.journalAiConsentAt = const Value.absent(),
    this.crashReportConsentAt = const Value.absent(),
    this.cloudSyncConsentAt = const Value.absent(),
    this.journalCloudSyncConsentAt = const Value.absent(),
    this.connectedSourcesJson = const Value.absent(),
    this.syncedAt = const Value.absent(),
  });
  ProfilesCompanion.insert({
    this.id = const Value.absent(),
    required DateTime dob,
    required String sex,
    required double weightKg,
    this.heightCm = const Value.absent(),
    this.bodyFatPercent = const Value.absent(),
    required String units,
    this.firstName = const Value.absent(),
    this.hapticsEnabled = const Value.absent(),
    this.guidanceMode = const Value.absent(),
    this.startSurface = const Value.absent(),
    this.birthTimeMinutes = const Value.absent(),
    this.birthTimePrecision = const Value.absent(),
    this.birthUtcOffsetMinutes = const Value.absent(),
    this.birthPlace = const Value.absent(),
    this.birthLatitude = const Value.absent(),
    this.birthLongitude = const Value.absent(),
    this.aiConsentAt = const Value.absent(),
    this.journalAiConsentAt = const Value.absent(),
    this.crashReportConsentAt = const Value.absent(),
    this.cloudSyncConsentAt = const Value.absent(),
    this.journalCloudSyncConsentAt = const Value.absent(),
    this.connectedSourcesJson = const Value.absent(),
    this.syncedAt = const Value.absent(),
  })  : dob = Value(dob),
        sex = Value(sex),
        weightKg = Value(weightKg),
        units = Value(units);
  static Insertable<ProfileRow> custom({
    Expression<int>? id,
    Expression<DateTime>? dob,
    Expression<String>? sex,
    Expression<double>? weightKg,
    Expression<double>? heightCm,
    Expression<double>? bodyFatPercent,
    Expression<String>? units,
    Expression<String>? firstName,
    Expression<bool>? hapticsEnabled,
    Expression<String>? guidanceMode,
    Expression<String>? startSurface,
    Expression<int>? birthTimeMinutes,
    Expression<String>? birthTimePrecision,
    Expression<int>? birthUtcOffsetMinutes,
    Expression<String>? birthPlace,
    Expression<double>? birthLatitude,
    Expression<double>? birthLongitude,
    Expression<DateTime>? aiConsentAt,
    Expression<DateTime>? journalAiConsentAt,
    Expression<DateTime>? crashReportConsentAt,
    Expression<DateTime>? cloudSyncConsentAt,
    Expression<DateTime>? journalCloudSyncConsentAt,
    Expression<String>? connectedSourcesJson,
    Expression<DateTime>? syncedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (dob != null) 'dob': dob,
      if (sex != null) 'sex': sex,
      if (weightKg != null) 'weight_kg': weightKg,
      if (heightCm != null) 'height_cm': heightCm,
      if (bodyFatPercent != null) 'body_fat_percent': bodyFatPercent,
      if (units != null) 'units': units,
      if (firstName != null) 'first_name': firstName,
      if (hapticsEnabled != null) 'haptics_enabled': hapticsEnabled,
      if (guidanceMode != null) 'guidance_mode': guidanceMode,
      if (startSurface != null) 'start_surface': startSurface,
      if (birthTimeMinutes != null) 'birth_time_minutes': birthTimeMinutes,
      if (birthTimePrecision != null)
        'birth_time_precision': birthTimePrecision,
      if (birthUtcOffsetMinutes != null)
        'birth_utc_offset_minutes': birthUtcOffsetMinutes,
      if (birthPlace != null) 'birth_place': birthPlace,
      if (birthLatitude != null) 'birth_latitude': birthLatitude,
      if (birthLongitude != null) 'birth_longitude': birthLongitude,
      if (aiConsentAt != null) 'ai_consent_at': aiConsentAt,
      if (journalAiConsentAt != null)
        'journal_ai_consent_at': journalAiConsentAt,
      if (crashReportConsentAt != null)
        'crash_report_consent_at': crashReportConsentAt,
      if (cloudSyncConsentAt != null)
        'cloud_sync_consent_at': cloudSyncConsentAt,
      if (journalCloudSyncConsentAt != null)
        'journal_cloud_sync_consent_at': journalCloudSyncConsentAt,
      if (connectedSourcesJson != null)
        'connected_sources_json': connectedSourcesJson,
      if (syncedAt != null) 'synced_at': syncedAt,
    });
  }

  ProfilesCompanion copyWith(
      {Value<int>? id,
      Value<DateTime>? dob,
      Value<String>? sex,
      Value<double>? weightKg,
      Value<double?>? heightCm,
      Value<double?>? bodyFatPercent,
      Value<String>? units,
      Value<String?>? firstName,
      Value<bool>? hapticsEnabled,
      Value<String>? guidanceMode,
      Value<String>? startSurface,
      Value<int?>? birthTimeMinutes,
      Value<String>? birthTimePrecision,
      Value<int?>? birthUtcOffsetMinutes,
      Value<String?>? birthPlace,
      Value<double?>? birthLatitude,
      Value<double?>? birthLongitude,
      Value<DateTime?>? aiConsentAt,
      Value<DateTime?>? journalAiConsentAt,
      Value<DateTime?>? crashReportConsentAt,
      Value<DateTime?>? cloudSyncConsentAt,
      Value<DateTime?>? journalCloudSyncConsentAt,
      Value<String>? connectedSourcesJson,
      Value<DateTime?>? syncedAt}) {
    return ProfilesCompanion(
      id: id ?? this.id,
      dob: dob ?? this.dob,
      sex: sex ?? this.sex,
      weightKg: weightKg ?? this.weightKg,
      heightCm: heightCm ?? this.heightCm,
      bodyFatPercent: bodyFatPercent ?? this.bodyFatPercent,
      units: units ?? this.units,
      firstName: firstName ?? this.firstName,
      hapticsEnabled: hapticsEnabled ?? this.hapticsEnabled,
      guidanceMode: guidanceMode ?? this.guidanceMode,
      startSurface: startSurface ?? this.startSurface,
      birthTimeMinutes: birthTimeMinutes ?? this.birthTimeMinutes,
      birthTimePrecision: birthTimePrecision ?? this.birthTimePrecision,
      birthUtcOffsetMinutes:
          birthUtcOffsetMinutes ?? this.birthUtcOffsetMinutes,
      birthPlace: birthPlace ?? this.birthPlace,
      birthLatitude: birthLatitude ?? this.birthLatitude,
      birthLongitude: birthLongitude ?? this.birthLongitude,
      aiConsentAt: aiConsentAt ?? this.aiConsentAt,
      journalAiConsentAt: journalAiConsentAt ?? this.journalAiConsentAt,
      crashReportConsentAt: crashReportConsentAt ?? this.crashReportConsentAt,
      cloudSyncConsentAt: cloudSyncConsentAt ?? this.cloudSyncConsentAt,
      journalCloudSyncConsentAt:
          journalCloudSyncConsentAt ?? this.journalCloudSyncConsentAt,
      connectedSourcesJson: connectedSourcesJson ?? this.connectedSourcesJson,
      syncedAt: syncedAt ?? this.syncedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (dob.present) {
      map['dob'] = Variable<DateTime>(dob.value);
    }
    if (sex.present) {
      map['sex'] = Variable<String>(sex.value);
    }
    if (weightKg.present) {
      map['weight_kg'] = Variable<double>(weightKg.value);
    }
    if (heightCm.present) {
      map['height_cm'] = Variable<double>(heightCm.value);
    }
    if (bodyFatPercent.present) {
      map['body_fat_percent'] = Variable<double>(bodyFatPercent.value);
    }
    if (units.present) {
      map['units'] = Variable<String>(units.value);
    }
    if (firstName.present) {
      map['first_name'] = Variable<String>(firstName.value);
    }
    if (hapticsEnabled.present) {
      map['haptics_enabled'] = Variable<bool>(hapticsEnabled.value);
    }
    if (guidanceMode.present) {
      map['guidance_mode'] = Variable<String>(guidanceMode.value);
    }
    if (startSurface.present) {
      map['start_surface'] = Variable<String>(startSurface.value);
    }
    if (birthTimeMinutes.present) {
      map['birth_time_minutes'] = Variable<int>(birthTimeMinutes.value);
    }
    if (birthTimePrecision.present) {
      map['birth_time_precision'] = Variable<String>(birthTimePrecision.value);
    }
    if (birthUtcOffsetMinutes.present) {
      map['birth_utc_offset_minutes'] =
          Variable<int>(birthUtcOffsetMinutes.value);
    }
    if (birthPlace.present) {
      map['birth_place'] = Variable<String>(birthPlace.value);
    }
    if (birthLatitude.present) {
      map['birth_latitude'] = Variable<double>(birthLatitude.value);
    }
    if (birthLongitude.present) {
      map['birth_longitude'] = Variable<double>(birthLongitude.value);
    }
    if (aiConsentAt.present) {
      map['ai_consent_at'] = Variable<DateTime>(aiConsentAt.value);
    }
    if (journalAiConsentAt.present) {
      map['journal_ai_consent_at'] =
          Variable<DateTime>(journalAiConsentAt.value);
    }
    if (crashReportConsentAt.present) {
      map['crash_report_consent_at'] =
          Variable<DateTime>(crashReportConsentAt.value);
    }
    if (cloudSyncConsentAt.present) {
      map['cloud_sync_consent_at'] =
          Variable<DateTime>(cloudSyncConsentAt.value);
    }
    if (journalCloudSyncConsentAt.present) {
      map['journal_cloud_sync_consent_at'] =
          Variable<DateTime>(journalCloudSyncConsentAt.value);
    }
    if (connectedSourcesJson.present) {
      map['connected_sources_json'] =
          Variable<String>(connectedSourcesJson.value);
    }
    if (syncedAt.present) {
      map['synced_at'] = Variable<DateTime>(syncedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ProfilesCompanion(')
          ..write('id: $id, ')
          ..write('dob: $dob, ')
          ..write('sex: $sex, ')
          ..write('weightKg: $weightKg, ')
          ..write('heightCm: $heightCm, ')
          ..write('bodyFatPercent: $bodyFatPercent, ')
          ..write('units: $units, ')
          ..write('firstName: $firstName, ')
          ..write('hapticsEnabled: $hapticsEnabled, ')
          ..write('guidanceMode: $guidanceMode, ')
          ..write('startSurface: $startSurface, ')
          ..write('birthTimeMinutes: $birthTimeMinutes, ')
          ..write('birthTimePrecision: $birthTimePrecision, ')
          ..write('birthUtcOffsetMinutes: $birthUtcOffsetMinutes, ')
          ..write('birthPlace: $birthPlace, ')
          ..write('birthLatitude: $birthLatitude, ')
          ..write('birthLongitude: $birthLongitude, ')
          ..write('aiConsentAt: $aiConsentAt, ')
          ..write('journalAiConsentAt: $journalAiConsentAt, ')
          ..write('crashReportConsentAt: $crashReportConsentAt, ')
          ..write('cloudSyncConsentAt: $cloudSyncConsentAt, ')
          ..write('journalCloudSyncConsentAt: $journalCloudSyncConsentAt, ')
          ..write('connectedSourcesJson: $connectedSourcesJson, ')
          ..write('syncedAt: $syncedAt')
          ..write(')'))
        .toString();
  }
}

class $DaySummariesTable extends DaySummaries
    with TableInfo<$DaySummariesTable, DaySummaryRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DaySummariesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<String> date = GeneratedColumn<String>(
      'date', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _activeKcalMeta =
      const VerificationMeta('activeKcal');
  @override
  late final GeneratedColumn<double> activeKcal = GeneratedColumn<double>(
      'active_kcal', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _basalKcalMeta =
      const VerificationMeta('basalKcal');
  @override
  late final GeneratedColumn<double> basalKcal = GeneratedColumn<double>(
      'basal_kcal', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _intakeKcalMeta =
      const VerificationMeta('intakeKcal');
  @override
  late final GeneratedColumn<double> intakeKcal = GeneratedColumn<double>(
      'intake_kcal', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _stepsMeta = const VerificationMeta('steps');
  @override
  late final GeneratedColumn<int> steps = GeneratedColumn<int>(
      'steps', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _sessionsCountMeta =
      const VerificationMeta('sessionsCount');
  @override
  late final GeneratedColumn<int> sessionsCount = GeneratedColumn<int>(
      'sessions_count', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _recalibratedMeta =
      const VerificationMeta('recalibrated');
  @override
  late final GeneratedColumn<bool> recalibrated = GeneratedColumn<bool>(
      'recalibrated', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("recalibrated" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _syncedAtMeta =
      const VerificationMeta('syncedAt');
  @override
  late final GeneratedColumn<DateTime> syncedAt = GeneratedColumn<DateTime>(
      'synced_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        date,
        activeKcal,
        basalKcal,
        intakeKcal,
        steps,
        sessionsCount,
        recalibrated,
        syncedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'day_summaries';
  @override
  VerificationContext validateIntegrity(Insertable<DaySummaryRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('date')) {
      context.handle(
          _dateMeta, date.isAcceptableOrUnknown(data['date']!, _dateMeta));
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('active_kcal')) {
      context.handle(
          _activeKcalMeta,
          activeKcal.isAcceptableOrUnknown(
              data['active_kcal']!, _activeKcalMeta));
    }
    if (data.containsKey('basal_kcal')) {
      context.handle(_basalKcalMeta,
          basalKcal.isAcceptableOrUnknown(data['basal_kcal']!, _basalKcalMeta));
    }
    if (data.containsKey('intake_kcal')) {
      context.handle(
          _intakeKcalMeta,
          intakeKcal.isAcceptableOrUnknown(
              data['intake_kcal']!, _intakeKcalMeta));
    }
    if (data.containsKey('steps')) {
      context.handle(
          _stepsMeta, steps.isAcceptableOrUnknown(data['steps']!, _stepsMeta));
    }
    if (data.containsKey('sessions_count')) {
      context.handle(
          _sessionsCountMeta,
          sessionsCount.isAcceptableOrUnknown(
              data['sessions_count']!, _sessionsCountMeta));
    }
    if (data.containsKey('recalibrated')) {
      context.handle(
          _recalibratedMeta,
          recalibrated.isAcceptableOrUnknown(
              data['recalibrated']!, _recalibratedMeta));
    }
    if (data.containsKey('synced_at')) {
      context.handle(_syncedAtMeta,
          syncedAt.isAcceptableOrUnknown(data['synced_at']!, _syncedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {date};
  @override
  DaySummaryRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DaySummaryRow(
      date: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}date'])!,
      activeKcal: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}active_kcal'])!,
      basalKcal: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}basal_kcal'])!,
      intakeKcal: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}intake_kcal']),
      steps: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}steps'])!,
      sessionsCount: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}sessions_count'])!,
      recalibrated: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}recalibrated'])!,
      syncedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}synced_at']),
    );
  }

  @override
  $DaySummariesTable createAlias(String alias) {
    return $DaySummariesTable(attachedDatabase, alias);
  }
}

class DaySummaryRow extends DataClass implements Insertable<DaySummaryRow> {
  /// ISO `yyyy-MM-dd` in the user's local day, not UTC.
  final String date;
  final double activeKcal;
  final double basalKcal;
  final double? intakeKcal;
  final int steps;
  final int sessionsCount;

  /// Set when a recomputation lowered the day's total, so the surface can say
  /// so rather than silently shrinking a number the user already read.
  final bool recalibrated;
  final DateTime? syncedAt;
  const DaySummaryRow(
      {required this.date,
      required this.activeKcal,
      required this.basalKcal,
      this.intakeKcal,
      required this.steps,
      required this.sessionsCount,
      required this.recalibrated,
      this.syncedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['date'] = Variable<String>(date);
    map['active_kcal'] = Variable<double>(activeKcal);
    map['basal_kcal'] = Variable<double>(basalKcal);
    if (!nullToAbsent || intakeKcal != null) {
      map['intake_kcal'] = Variable<double>(intakeKcal);
    }
    map['steps'] = Variable<int>(steps);
    map['sessions_count'] = Variable<int>(sessionsCount);
    map['recalibrated'] = Variable<bool>(recalibrated);
    if (!nullToAbsent || syncedAt != null) {
      map['synced_at'] = Variable<DateTime>(syncedAt);
    }
    return map;
  }

  DaySummariesCompanion toCompanion(bool nullToAbsent) {
    return DaySummariesCompanion(
      date: Value(date),
      activeKcal: Value(activeKcal),
      basalKcal: Value(basalKcal),
      intakeKcal: intakeKcal == null && nullToAbsent
          ? const Value.absent()
          : Value(intakeKcal),
      steps: Value(steps),
      sessionsCount: Value(sessionsCount),
      recalibrated: Value(recalibrated),
      syncedAt: syncedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(syncedAt),
    );
  }

  factory DaySummaryRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DaySummaryRow(
      date: serializer.fromJson<String>(json['date']),
      activeKcal: serializer.fromJson<double>(json['activeKcal']),
      basalKcal: serializer.fromJson<double>(json['basalKcal']),
      intakeKcal: serializer.fromJson<double?>(json['intakeKcal']),
      steps: serializer.fromJson<int>(json['steps']),
      sessionsCount: serializer.fromJson<int>(json['sessionsCount']),
      recalibrated: serializer.fromJson<bool>(json['recalibrated']),
      syncedAt: serializer.fromJson<DateTime?>(json['syncedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'date': serializer.toJson<String>(date),
      'activeKcal': serializer.toJson<double>(activeKcal),
      'basalKcal': serializer.toJson<double>(basalKcal),
      'intakeKcal': serializer.toJson<double?>(intakeKcal),
      'steps': serializer.toJson<int>(steps),
      'sessionsCount': serializer.toJson<int>(sessionsCount),
      'recalibrated': serializer.toJson<bool>(recalibrated),
      'syncedAt': serializer.toJson<DateTime?>(syncedAt),
    };
  }

  DaySummaryRow copyWith(
          {String? date,
          double? activeKcal,
          double? basalKcal,
          Value<double?> intakeKcal = const Value.absent(),
          int? steps,
          int? sessionsCount,
          bool? recalibrated,
          Value<DateTime?> syncedAt = const Value.absent()}) =>
      DaySummaryRow(
        date: date ?? this.date,
        activeKcal: activeKcal ?? this.activeKcal,
        basalKcal: basalKcal ?? this.basalKcal,
        intakeKcal: intakeKcal.present ? intakeKcal.value : this.intakeKcal,
        steps: steps ?? this.steps,
        sessionsCount: sessionsCount ?? this.sessionsCount,
        recalibrated: recalibrated ?? this.recalibrated,
        syncedAt: syncedAt.present ? syncedAt.value : this.syncedAt,
      );
  DaySummaryRow copyWithCompanion(DaySummariesCompanion data) {
    return DaySummaryRow(
      date: data.date.present ? data.date.value : this.date,
      activeKcal:
          data.activeKcal.present ? data.activeKcal.value : this.activeKcal,
      basalKcal: data.basalKcal.present ? data.basalKcal.value : this.basalKcal,
      intakeKcal:
          data.intakeKcal.present ? data.intakeKcal.value : this.intakeKcal,
      steps: data.steps.present ? data.steps.value : this.steps,
      sessionsCount: data.sessionsCount.present
          ? data.sessionsCount.value
          : this.sessionsCount,
      recalibrated: data.recalibrated.present
          ? data.recalibrated.value
          : this.recalibrated,
      syncedAt: data.syncedAt.present ? data.syncedAt.value : this.syncedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DaySummaryRow(')
          ..write('date: $date, ')
          ..write('activeKcal: $activeKcal, ')
          ..write('basalKcal: $basalKcal, ')
          ..write('intakeKcal: $intakeKcal, ')
          ..write('steps: $steps, ')
          ..write('sessionsCount: $sessionsCount, ')
          ..write('recalibrated: $recalibrated, ')
          ..write('syncedAt: $syncedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(date, activeKcal, basalKcal, intakeKcal,
      steps, sessionsCount, recalibrated, syncedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DaySummaryRow &&
          other.date == this.date &&
          other.activeKcal == this.activeKcal &&
          other.basalKcal == this.basalKcal &&
          other.intakeKcal == this.intakeKcal &&
          other.steps == this.steps &&
          other.sessionsCount == this.sessionsCount &&
          other.recalibrated == this.recalibrated &&
          other.syncedAt == this.syncedAt);
}

class DaySummariesCompanion extends UpdateCompanion<DaySummaryRow> {
  final Value<String> date;
  final Value<double> activeKcal;
  final Value<double> basalKcal;
  final Value<double?> intakeKcal;
  final Value<int> steps;
  final Value<int> sessionsCount;
  final Value<bool> recalibrated;
  final Value<DateTime?> syncedAt;
  final Value<int> rowid;
  const DaySummariesCompanion({
    this.date = const Value.absent(),
    this.activeKcal = const Value.absent(),
    this.basalKcal = const Value.absent(),
    this.intakeKcal = const Value.absent(),
    this.steps = const Value.absent(),
    this.sessionsCount = const Value.absent(),
    this.recalibrated = const Value.absent(),
    this.syncedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DaySummariesCompanion.insert({
    required String date,
    this.activeKcal = const Value.absent(),
    this.basalKcal = const Value.absent(),
    this.intakeKcal = const Value.absent(),
    this.steps = const Value.absent(),
    this.sessionsCount = const Value.absent(),
    this.recalibrated = const Value.absent(),
    this.syncedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : date = Value(date);
  static Insertable<DaySummaryRow> custom({
    Expression<String>? date,
    Expression<double>? activeKcal,
    Expression<double>? basalKcal,
    Expression<double>? intakeKcal,
    Expression<int>? steps,
    Expression<int>? sessionsCount,
    Expression<bool>? recalibrated,
    Expression<DateTime>? syncedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (date != null) 'date': date,
      if (activeKcal != null) 'active_kcal': activeKcal,
      if (basalKcal != null) 'basal_kcal': basalKcal,
      if (intakeKcal != null) 'intake_kcal': intakeKcal,
      if (steps != null) 'steps': steps,
      if (sessionsCount != null) 'sessions_count': sessionsCount,
      if (recalibrated != null) 'recalibrated': recalibrated,
      if (syncedAt != null) 'synced_at': syncedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DaySummariesCompanion copyWith(
      {Value<String>? date,
      Value<double>? activeKcal,
      Value<double>? basalKcal,
      Value<double?>? intakeKcal,
      Value<int>? steps,
      Value<int>? sessionsCount,
      Value<bool>? recalibrated,
      Value<DateTime?>? syncedAt,
      Value<int>? rowid}) {
    return DaySummariesCompanion(
      date: date ?? this.date,
      activeKcal: activeKcal ?? this.activeKcal,
      basalKcal: basalKcal ?? this.basalKcal,
      intakeKcal: intakeKcal ?? this.intakeKcal,
      steps: steps ?? this.steps,
      sessionsCount: sessionsCount ?? this.sessionsCount,
      recalibrated: recalibrated ?? this.recalibrated,
      syncedAt: syncedAt ?? this.syncedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (date.present) {
      map['date'] = Variable<String>(date.value);
    }
    if (activeKcal.present) {
      map['active_kcal'] = Variable<double>(activeKcal.value);
    }
    if (basalKcal.present) {
      map['basal_kcal'] = Variable<double>(basalKcal.value);
    }
    if (intakeKcal.present) {
      map['intake_kcal'] = Variable<double>(intakeKcal.value);
    }
    if (steps.present) {
      map['steps'] = Variable<int>(steps.value);
    }
    if (sessionsCount.present) {
      map['sessions_count'] = Variable<int>(sessionsCount.value);
    }
    if (recalibrated.present) {
      map['recalibrated'] = Variable<bool>(recalibrated.value);
    }
    if (syncedAt.present) {
      map['synced_at'] = Variable<DateTime>(syncedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DaySummariesCompanion(')
          ..write('date: $date, ')
          ..write('activeKcal: $activeKcal, ')
          ..write('basalKcal: $basalKcal, ')
          ..write('intakeKcal: $intakeKcal, ')
          ..write('steps: $steps, ')
          ..write('sessionsCount: $sessionsCount, ')
          ..write('recalibrated: $recalibrated, ')
          ..write('syncedAt: $syncedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $RawBucketsTable extends RawBuckets
    with TableInfo<$RawBucketsTable, RawBucketRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RawBucketsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _minuteUtcMeta =
      const VerificationMeta('minuteUtc');
  @override
  late final GeneratedColumn<DateTime> minuteUtc = GeneratedColumn<DateTime>(
      'minute_utc', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _sourceMeta = const VerificationMeta('source');
  @override
  late final GeneratedColumn<String> source = GeneratedColumn<String>(
      'source', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _activeKcalMeta =
      const VerificationMeta('activeKcal');
  @override
  late final GeneratedColumn<double> activeKcal = GeneratedColumn<double>(
      'active_kcal', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _stepsMeta = const VerificationMeta('steps');
  @override
  late final GeneratedColumn<int> steps = GeneratedColumn<int>(
      'steps', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _avgHrMeta = const VerificationMeta('avgHr');
  @override
  late final GeneratedColumn<double> avgHr = GeneratedColumn<double>(
      'avg_hr', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _hrSampleCountMeta =
      const VerificationMeta('hrSampleCount');
  @override
  late final GeneratedColumn<int> hrSampleCount = GeneratedColumn<int>(
      'hr_sample_count', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _priorityMeta =
      const VerificationMeta('priority');
  @override
  late final GeneratedColumn<int> priority = GeneratedColumn<int>(
      'priority', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _externalIdMeta =
      const VerificationMeta('externalId');
  @override
  late final GeneratedColumn<String> externalId = GeneratedColumn<String>(
      'external_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        minuteUtc,
        source,
        activeKcal,
        steps,
        avgHr,
        hrSampleCount,
        priority,
        externalId
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'raw_buckets';
  @override
  VerificationContext validateIntegrity(Insertable<RawBucketRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('minute_utc')) {
      context.handle(_minuteUtcMeta,
          minuteUtc.isAcceptableOrUnknown(data['minute_utc']!, _minuteUtcMeta));
    } else if (isInserting) {
      context.missing(_minuteUtcMeta);
    }
    if (data.containsKey('source')) {
      context.handle(_sourceMeta,
          source.isAcceptableOrUnknown(data['source']!, _sourceMeta));
    } else if (isInserting) {
      context.missing(_sourceMeta);
    }
    if (data.containsKey('active_kcal')) {
      context.handle(
          _activeKcalMeta,
          activeKcal.isAcceptableOrUnknown(
              data['active_kcal']!, _activeKcalMeta));
    } else if (isInserting) {
      context.missing(_activeKcalMeta);
    }
    if (data.containsKey('steps')) {
      context.handle(
          _stepsMeta, steps.isAcceptableOrUnknown(data['steps']!, _stepsMeta));
    }
    if (data.containsKey('avg_hr')) {
      context.handle(
          _avgHrMeta, avgHr.isAcceptableOrUnknown(data['avg_hr']!, _avgHrMeta));
    }
    if (data.containsKey('hr_sample_count')) {
      context.handle(
          _hrSampleCountMeta,
          hrSampleCount.isAcceptableOrUnknown(
              data['hr_sample_count']!, _hrSampleCountMeta));
    }
    if (data.containsKey('priority')) {
      context.handle(_priorityMeta,
          priority.isAcceptableOrUnknown(data['priority']!, _priorityMeta));
    } else if (isInserting) {
      context.missing(_priorityMeta);
    }
    if (data.containsKey('external_id')) {
      context.handle(
          _externalIdMeta,
          externalId.isAcceptableOrUnknown(
              data['external_id']!, _externalIdMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {source, minuteUtc};
  @override
  RawBucketRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return RawBucketRow(
      minuteUtc: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}minute_utc'])!,
      source: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}source'])!,
      activeKcal: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}active_kcal'])!,
      steps: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}steps']),
      avgHr: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}avg_hr']),
      hrSampleCount: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}hr_sample_count'])!,
      priority: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}priority'])!,
      externalId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}external_id']),
    );
  }

  @override
  $RawBucketsTable createAlias(String alias) {
    return $RawBucketsTable(attachedDatabase, alias);
  }
}

class RawBucketRow extends DataClass implements Insertable<RawBucketRow> {
  final DateTime minuteUtc;
  final String source;
  final double activeKcal;
  final int? steps;
  final double? avgHr;
  final int hrSampleCount;
  final int priority;
  final String? externalId;
  const RawBucketRow(
      {required this.minuteUtc,
      required this.source,
      required this.activeKcal,
      this.steps,
      this.avgHr,
      required this.hrSampleCount,
      required this.priority,
      this.externalId});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['minute_utc'] = Variable<DateTime>(minuteUtc);
    map['source'] = Variable<String>(source);
    map['active_kcal'] = Variable<double>(activeKcal);
    if (!nullToAbsent || steps != null) {
      map['steps'] = Variable<int>(steps);
    }
    if (!nullToAbsent || avgHr != null) {
      map['avg_hr'] = Variable<double>(avgHr);
    }
    map['hr_sample_count'] = Variable<int>(hrSampleCount);
    map['priority'] = Variable<int>(priority);
    if (!nullToAbsent || externalId != null) {
      map['external_id'] = Variable<String>(externalId);
    }
    return map;
  }

  RawBucketsCompanion toCompanion(bool nullToAbsent) {
    return RawBucketsCompanion(
      minuteUtc: Value(minuteUtc),
      source: Value(source),
      activeKcal: Value(activeKcal),
      steps:
          steps == null && nullToAbsent ? const Value.absent() : Value(steps),
      avgHr:
          avgHr == null && nullToAbsent ? const Value.absent() : Value(avgHr),
      hrSampleCount: Value(hrSampleCount),
      priority: Value(priority),
      externalId: externalId == null && nullToAbsent
          ? const Value.absent()
          : Value(externalId),
    );
  }

  factory RawBucketRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return RawBucketRow(
      minuteUtc: serializer.fromJson<DateTime>(json['minuteUtc']),
      source: serializer.fromJson<String>(json['source']),
      activeKcal: serializer.fromJson<double>(json['activeKcal']),
      steps: serializer.fromJson<int?>(json['steps']),
      avgHr: serializer.fromJson<double?>(json['avgHr']),
      hrSampleCount: serializer.fromJson<int>(json['hrSampleCount']),
      priority: serializer.fromJson<int>(json['priority']),
      externalId: serializer.fromJson<String?>(json['externalId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'minuteUtc': serializer.toJson<DateTime>(minuteUtc),
      'source': serializer.toJson<String>(source),
      'activeKcal': serializer.toJson<double>(activeKcal),
      'steps': serializer.toJson<int?>(steps),
      'avgHr': serializer.toJson<double?>(avgHr),
      'hrSampleCount': serializer.toJson<int>(hrSampleCount),
      'priority': serializer.toJson<int>(priority),
      'externalId': serializer.toJson<String?>(externalId),
    };
  }

  RawBucketRow copyWith(
          {DateTime? minuteUtc,
          String? source,
          double? activeKcal,
          Value<int?> steps = const Value.absent(),
          Value<double?> avgHr = const Value.absent(),
          int? hrSampleCount,
          int? priority,
          Value<String?> externalId = const Value.absent()}) =>
      RawBucketRow(
        minuteUtc: minuteUtc ?? this.minuteUtc,
        source: source ?? this.source,
        activeKcal: activeKcal ?? this.activeKcal,
        steps: steps.present ? steps.value : this.steps,
        avgHr: avgHr.present ? avgHr.value : this.avgHr,
        hrSampleCount: hrSampleCount ?? this.hrSampleCount,
        priority: priority ?? this.priority,
        externalId: externalId.present ? externalId.value : this.externalId,
      );
  RawBucketRow copyWithCompanion(RawBucketsCompanion data) {
    return RawBucketRow(
      minuteUtc: data.minuteUtc.present ? data.minuteUtc.value : this.minuteUtc,
      source: data.source.present ? data.source.value : this.source,
      activeKcal:
          data.activeKcal.present ? data.activeKcal.value : this.activeKcal,
      steps: data.steps.present ? data.steps.value : this.steps,
      avgHr: data.avgHr.present ? data.avgHr.value : this.avgHr,
      hrSampleCount: data.hrSampleCount.present
          ? data.hrSampleCount.value
          : this.hrSampleCount,
      priority: data.priority.present ? data.priority.value : this.priority,
      externalId:
          data.externalId.present ? data.externalId.value : this.externalId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('RawBucketRow(')
          ..write('minuteUtc: $minuteUtc, ')
          ..write('source: $source, ')
          ..write('activeKcal: $activeKcal, ')
          ..write('steps: $steps, ')
          ..write('avgHr: $avgHr, ')
          ..write('hrSampleCount: $hrSampleCount, ')
          ..write('priority: $priority, ')
          ..write('externalId: $externalId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(minuteUtc, source, activeKcal, steps, avgHr,
      hrSampleCount, priority, externalId);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RawBucketRow &&
          other.minuteUtc == this.minuteUtc &&
          other.source == this.source &&
          other.activeKcal == this.activeKcal &&
          other.steps == this.steps &&
          other.avgHr == this.avgHr &&
          other.hrSampleCount == this.hrSampleCount &&
          other.priority == this.priority &&
          other.externalId == this.externalId);
}

class RawBucketsCompanion extends UpdateCompanion<RawBucketRow> {
  final Value<DateTime> minuteUtc;
  final Value<String> source;
  final Value<double> activeKcal;
  final Value<int?> steps;
  final Value<double?> avgHr;
  final Value<int> hrSampleCount;
  final Value<int> priority;
  final Value<String?> externalId;
  final Value<int> rowid;
  const RawBucketsCompanion({
    this.minuteUtc = const Value.absent(),
    this.source = const Value.absent(),
    this.activeKcal = const Value.absent(),
    this.steps = const Value.absent(),
    this.avgHr = const Value.absent(),
    this.hrSampleCount = const Value.absent(),
    this.priority = const Value.absent(),
    this.externalId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  RawBucketsCompanion.insert({
    required DateTime minuteUtc,
    required String source,
    required double activeKcal,
    this.steps = const Value.absent(),
    this.avgHr = const Value.absent(),
    this.hrSampleCount = const Value.absent(),
    required int priority,
    this.externalId = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : minuteUtc = Value(minuteUtc),
        source = Value(source),
        activeKcal = Value(activeKcal),
        priority = Value(priority);
  static Insertable<RawBucketRow> custom({
    Expression<DateTime>? minuteUtc,
    Expression<String>? source,
    Expression<double>? activeKcal,
    Expression<int>? steps,
    Expression<double>? avgHr,
    Expression<int>? hrSampleCount,
    Expression<int>? priority,
    Expression<String>? externalId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (minuteUtc != null) 'minute_utc': minuteUtc,
      if (source != null) 'source': source,
      if (activeKcal != null) 'active_kcal': activeKcal,
      if (steps != null) 'steps': steps,
      if (avgHr != null) 'avg_hr': avgHr,
      if (hrSampleCount != null) 'hr_sample_count': hrSampleCount,
      if (priority != null) 'priority': priority,
      if (externalId != null) 'external_id': externalId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  RawBucketsCompanion copyWith(
      {Value<DateTime>? minuteUtc,
      Value<String>? source,
      Value<double>? activeKcal,
      Value<int?>? steps,
      Value<double?>? avgHr,
      Value<int>? hrSampleCount,
      Value<int>? priority,
      Value<String?>? externalId,
      Value<int>? rowid}) {
    return RawBucketsCompanion(
      minuteUtc: minuteUtc ?? this.minuteUtc,
      source: source ?? this.source,
      activeKcal: activeKcal ?? this.activeKcal,
      steps: steps ?? this.steps,
      avgHr: avgHr ?? this.avgHr,
      hrSampleCount: hrSampleCount ?? this.hrSampleCount,
      priority: priority ?? this.priority,
      externalId: externalId ?? this.externalId,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (minuteUtc.present) {
      map['minute_utc'] = Variable<DateTime>(minuteUtc.value);
    }
    if (source.present) {
      map['source'] = Variable<String>(source.value);
    }
    if (activeKcal.present) {
      map['active_kcal'] = Variable<double>(activeKcal.value);
    }
    if (steps.present) {
      map['steps'] = Variable<int>(steps.value);
    }
    if (avgHr.present) {
      map['avg_hr'] = Variable<double>(avgHr.value);
    }
    if (hrSampleCount.present) {
      map['hr_sample_count'] = Variable<int>(hrSampleCount.value);
    }
    if (priority.present) {
      map['priority'] = Variable<int>(priority.value);
    }
    if (externalId.present) {
      map['external_id'] = Variable<String>(externalId.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RawBucketsCompanion(')
          ..write('minuteUtc: $minuteUtc, ')
          ..write('source: $source, ')
          ..write('activeKcal: $activeKcal, ')
          ..write('steps: $steps, ')
          ..write('avgHr: $avgHr, ')
          ..write('hrSampleCount: $hrSampleCount, ')
          ..write('priority: $priority, ')
          ..write('externalId: $externalId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $MinuteBucketsTable extends MinuteBuckets
    with TableInfo<$MinuteBucketsTable, MinuteBucketRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MinuteBucketsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _minuteUtcMeta =
      const VerificationMeta('minuteUtc');
  @override
  late final GeneratedColumn<DateTime> minuteUtc = GeneratedColumn<DateTime>(
      'minute_utc', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _activeKcalMeta =
      const VerificationMeta('activeKcal');
  @override
  late final GeneratedColumn<double> activeKcal = GeneratedColumn<double>(
      'active_kcal', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _stepsMeta = const VerificationMeta('steps');
  @override
  late final GeneratedColumn<int> steps = GeneratedColumn<int>(
      'steps', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _avgHrMeta = const VerificationMeta('avgHr');
  @override
  late final GeneratedColumn<double> avgHr = GeneratedColumn<double>(
      'avg_hr', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _winningSourceMeta =
      const VerificationMeta('winningSource');
  @override
  late final GeneratedColumn<String> winningSource = GeneratedColumn<String>(
      'winning_source', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _provenanceMeta =
      const VerificationMeta('provenance');
  @override
  late final GeneratedColumn<String> provenance = GeneratedColumn<String>(
      'provenance', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns =>
      [minuteUtc, activeKcal, steps, avgHr, winningSource, provenance];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'minute_buckets';
  @override
  VerificationContext validateIntegrity(Insertable<MinuteBucketRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('minute_utc')) {
      context.handle(_minuteUtcMeta,
          minuteUtc.isAcceptableOrUnknown(data['minute_utc']!, _minuteUtcMeta));
    } else if (isInserting) {
      context.missing(_minuteUtcMeta);
    }
    if (data.containsKey('active_kcal')) {
      context.handle(
          _activeKcalMeta,
          activeKcal.isAcceptableOrUnknown(
              data['active_kcal']!, _activeKcalMeta));
    } else if (isInserting) {
      context.missing(_activeKcalMeta);
    }
    if (data.containsKey('steps')) {
      context.handle(
          _stepsMeta, steps.isAcceptableOrUnknown(data['steps']!, _stepsMeta));
    }
    if (data.containsKey('avg_hr')) {
      context.handle(
          _avgHrMeta, avgHr.isAcceptableOrUnknown(data['avg_hr']!, _avgHrMeta));
    }
    if (data.containsKey('winning_source')) {
      context.handle(
          _winningSourceMeta,
          winningSource.isAcceptableOrUnknown(
              data['winning_source']!, _winningSourceMeta));
    } else if (isInserting) {
      context.missing(_winningSourceMeta);
    }
    if (data.containsKey('provenance')) {
      context.handle(
          _provenanceMeta,
          provenance.isAcceptableOrUnknown(
              data['provenance']!, _provenanceMeta));
    } else if (isInserting) {
      context.missing(_provenanceMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {minuteUtc};
  @override
  MinuteBucketRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MinuteBucketRow(
      minuteUtc: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}minute_utc'])!,
      activeKcal: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}active_kcal'])!,
      steps: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}steps']),
      avgHr: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}avg_hr']),
      winningSource: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}winning_source'])!,
      provenance: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}provenance'])!,
    );
  }

  @override
  $MinuteBucketsTable createAlias(String alias) {
    return $MinuteBucketsTable(attachedDatabase, alias);
  }
}

class MinuteBucketRow extends DataClass implements Insertable<MinuteBucketRow> {
  final DateTime minuteUtc;
  final double activeKcal;
  final int? steps;
  final double? avgHr;
  final String winningSource;

  /// Human-readable, so the health surface can answer "why is my number X?"
  /// with "13:00-14:00 · Polar strap" instead of an argument.
  final String provenance;
  const MinuteBucketRow(
      {required this.minuteUtc,
      required this.activeKcal,
      this.steps,
      this.avgHr,
      required this.winningSource,
      required this.provenance});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['minute_utc'] = Variable<DateTime>(minuteUtc);
    map['active_kcal'] = Variable<double>(activeKcal);
    if (!nullToAbsent || steps != null) {
      map['steps'] = Variable<int>(steps);
    }
    if (!nullToAbsent || avgHr != null) {
      map['avg_hr'] = Variable<double>(avgHr);
    }
    map['winning_source'] = Variable<String>(winningSource);
    map['provenance'] = Variable<String>(provenance);
    return map;
  }

  MinuteBucketsCompanion toCompanion(bool nullToAbsent) {
    return MinuteBucketsCompanion(
      minuteUtc: Value(minuteUtc),
      activeKcal: Value(activeKcal),
      steps:
          steps == null && nullToAbsent ? const Value.absent() : Value(steps),
      avgHr:
          avgHr == null && nullToAbsent ? const Value.absent() : Value(avgHr),
      winningSource: Value(winningSource),
      provenance: Value(provenance),
    );
  }

  factory MinuteBucketRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MinuteBucketRow(
      minuteUtc: serializer.fromJson<DateTime>(json['minuteUtc']),
      activeKcal: serializer.fromJson<double>(json['activeKcal']),
      steps: serializer.fromJson<int?>(json['steps']),
      avgHr: serializer.fromJson<double?>(json['avgHr']),
      winningSource: serializer.fromJson<String>(json['winningSource']),
      provenance: serializer.fromJson<String>(json['provenance']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'minuteUtc': serializer.toJson<DateTime>(minuteUtc),
      'activeKcal': serializer.toJson<double>(activeKcal),
      'steps': serializer.toJson<int?>(steps),
      'avgHr': serializer.toJson<double?>(avgHr),
      'winningSource': serializer.toJson<String>(winningSource),
      'provenance': serializer.toJson<String>(provenance),
    };
  }

  MinuteBucketRow copyWith(
          {DateTime? minuteUtc,
          double? activeKcal,
          Value<int?> steps = const Value.absent(),
          Value<double?> avgHr = const Value.absent(),
          String? winningSource,
          String? provenance}) =>
      MinuteBucketRow(
        minuteUtc: minuteUtc ?? this.minuteUtc,
        activeKcal: activeKcal ?? this.activeKcal,
        steps: steps.present ? steps.value : this.steps,
        avgHr: avgHr.present ? avgHr.value : this.avgHr,
        winningSource: winningSource ?? this.winningSource,
        provenance: provenance ?? this.provenance,
      );
  MinuteBucketRow copyWithCompanion(MinuteBucketsCompanion data) {
    return MinuteBucketRow(
      minuteUtc: data.minuteUtc.present ? data.minuteUtc.value : this.minuteUtc,
      activeKcal:
          data.activeKcal.present ? data.activeKcal.value : this.activeKcal,
      steps: data.steps.present ? data.steps.value : this.steps,
      avgHr: data.avgHr.present ? data.avgHr.value : this.avgHr,
      winningSource: data.winningSource.present
          ? data.winningSource.value
          : this.winningSource,
      provenance:
          data.provenance.present ? data.provenance.value : this.provenance,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MinuteBucketRow(')
          ..write('minuteUtc: $minuteUtc, ')
          ..write('activeKcal: $activeKcal, ')
          ..write('steps: $steps, ')
          ..write('avgHr: $avgHr, ')
          ..write('winningSource: $winningSource, ')
          ..write('provenance: $provenance')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      minuteUtc, activeKcal, steps, avgHr, winningSource, provenance);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MinuteBucketRow &&
          other.minuteUtc == this.minuteUtc &&
          other.activeKcal == this.activeKcal &&
          other.steps == this.steps &&
          other.avgHr == this.avgHr &&
          other.winningSource == this.winningSource &&
          other.provenance == this.provenance);
}

class MinuteBucketsCompanion extends UpdateCompanion<MinuteBucketRow> {
  final Value<DateTime> minuteUtc;
  final Value<double> activeKcal;
  final Value<int?> steps;
  final Value<double?> avgHr;
  final Value<String> winningSource;
  final Value<String> provenance;
  final Value<int> rowid;
  const MinuteBucketsCompanion({
    this.minuteUtc = const Value.absent(),
    this.activeKcal = const Value.absent(),
    this.steps = const Value.absent(),
    this.avgHr = const Value.absent(),
    this.winningSource = const Value.absent(),
    this.provenance = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MinuteBucketsCompanion.insert({
    required DateTime minuteUtc,
    required double activeKcal,
    this.steps = const Value.absent(),
    this.avgHr = const Value.absent(),
    required String winningSource,
    required String provenance,
    this.rowid = const Value.absent(),
  })  : minuteUtc = Value(minuteUtc),
        activeKcal = Value(activeKcal),
        winningSource = Value(winningSource),
        provenance = Value(provenance);
  static Insertable<MinuteBucketRow> custom({
    Expression<DateTime>? minuteUtc,
    Expression<double>? activeKcal,
    Expression<int>? steps,
    Expression<double>? avgHr,
    Expression<String>? winningSource,
    Expression<String>? provenance,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (minuteUtc != null) 'minute_utc': minuteUtc,
      if (activeKcal != null) 'active_kcal': activeKcal,
      if (steps != null) 'steps': steps,
      if (avgHr != null) 'avg_hr': avgHr,
      if (winningSource != null) 'winning_source': winningSource,
      if (provenance != null) 'provenance': provenance,
      if (rowid != null) 'rowid': rowid,
    });
  }

  MinuteBucketsCompanion copyWith(
      {Value<DateTime>? minuteUtc,
      Value<double>? activeKcal,
      Value<int?>? steps,
      Value<double?>? avgHr,
      Value<String>? winningSource,
      Value<String>? provenance,
      Value<int>? rowid}) {
    return MinuteBucketsCompanion(
      minuteUtc: minuteUtc ?? this.minuteUtc,
      activeKcal: activeKcal ?? this.activeKcal,
      steps: steps ?? this.steps,
      avgHr: avgHr ?? this.avgHr,
      winningSource: winningSource ?? this.winningSource,
      provenance: provenance ?? this.provenance,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (minuteUtc.present) {
      map['minute_utc'] = Variable<DateTime>(minuteUtc.value);
    }
    if (activeKcal.present) {
      map['active_kcal'] = Variable<double>(activeKcal.value);
    }
    if (steps.present) {
      map['steps'] = Variable<int>(steps.value);
    }
    if (avgHr.present) {
      map['avg_hr'] = Variable<double>(avgHr.value);
    }
    if (winningSource.present) {
      map['winning_source'] = Variable<String>(winningSource.value);
    }
    if (provenance.present) {
      map['provenance'] = Variable<String>(provenance.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MinuteBucketsCompanion(')
          ..write('minuteUtc: $minuteUtc, ')
          ..write('activeKcal: $activeKcal, ')
          ..write('steps: $steps, ')
          ..write('avgHr: $avgHr, ')
          ..write('winningSource: $winningSource, ')
          ..write('provenance: $provenance, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $IntegrationsTable extends Integrations
    with TableInfo<$IntegrationsTable, IntegrationRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $IntegrationsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _vendorMeta = const VerificationMeta('vendor');
  @override
  late final GeneratedColumn<String> vendor = GeneratedColumn<String>(
      'vendor', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
      'status', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _lastAttemptMeta =
      const VerificationMeta('lastAttempt');
  @override
  late final GeneratedColumn<DateTime> lastAttempt = GeneratedColumn<DateTime>(
      'last_attempt', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _lastSyncMeta =
      const VerificationMeta('lastSync');
  @override
  late final GeneratedColumn<DateTime> lastSync = GeneratedColumn<DateTime>(
      'last_sync', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _changesTokenMeta =
      const VerificationMeta('changesToken');
  @override
  late final GeneratedColumn<String> changesToken = GeneratedColumn<String>(
      'changes_token', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _recordsTodayMeta =
      const VerificationMeta('recordsToday');
  @override
  late final GeneratedColumn<int> recordsToday = GeneratedColumn<int>(
      'records_today', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _diagnosticsJsonMeta =
      const VerificationMeta('diagnosticsJson');
  @override
  late final GeneratedColumn<String> diagnosticsJson = GeneratedColumn<String>(
      'diagnostics_json', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('{}'));
  static const VerificationMeta _lastErrorMeta =
      const VerificationMeta('lastError');
  @override
  late final GeneratedColumn<String> lastError = GeneratedColumn<String>(
      'last_error', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        vendor,
        status,
        lastAttempt,
        lastSync,
        changesToken,
        recordsToday,
        diagnosticsJson,
        lastError
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'integrations';
  @override
  VerificationContext validateIntegrity(Insertable<IntegrationRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('vendor')) {
      context.handle(_vendorMeta,
          vendor.isAcceptableOrUnknown(data['vendor']!, _vendorMeta));
    } else if (isInserting) {
      context.missing(_vendorMeta);
    }
    if (data.containsKey('status')) {
      context.handle(_statusMeta,
          status.isAcceptableOrUnknown(data['status']!, _statusMeta));
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('last_attempt')) {
      context.handle(
          _lastAttemptMeta,
          lastAttempt.isAcceptableOrUnknown(
              data['last_attempt']!, _lastAttemptMeta));
    }
    if (data.containsKey('last_sync')) {
      context.handle(_lastSyncMeta,
          lastSync.isAcceptableOrUnknown(data['last_sync']!, _lastSyncMeta));
    }
    if (data.containsKey('changes_token')) {
      context.handle(
          _changesTokenMeta,
          changesToken.isAcceptableOrUnknown(
              data['changes_token']!, _changesTokenMeta));
    }
    if (data.containsKey('records_today')) {
      context.handle(
          _recordsTodayMeta,
          recordsToday.isAcceptableOrUnknown(
              data['records_today']!, _recordsTodayMeta));
    }
    if (data.containsKey('diagnostics_json')) {
      context.handle(
          _diagnosticsJsonMeta,
          diagnosticsJson.isAcceptableOrUnknown(
              data['diagnostics_json']!, _diagnosticsJsonMeta));
    }
    if (data.containsKey('last_error')) {
      context.handle(_lastErrorMeta,
          lastError.isAcceptableOrUnknown(data['last_error']!, _lastErrorMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {vendor};
  @override
  IntegrationRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return IntegrationRow(
      vendor: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}vendor'])!,
      status: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}status'])!,
      lastAttempt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}last_attempt']),
      lastSync: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}last_sync']),
      changesToken: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}changes_token']),
      recordsToday: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}records_today'])!,
      diagnosticsJson: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}diagnostics_json'])!,
      lastError: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}last_error']),
    );
  }

  @override
  $IntegrationsTable createAlias(String alias) {
    return $IntegrationsTable(attachedDatabase, alias);
  }
}

class IntegrationRow extends DataClass implements Insertable<IntegrationRow> {
  final String vendor;

  /// `connected` | `disconnected` | `reauthNeeded` | `error`.
  final String status;
  final DateTime? lastAttempt;
  final DateTime? lastSync;

  /// Health Connect differential-sync token. v1 plumbed this end to end and
  /// then discarded it in the hub, so every sync was a full re-read; the v2
  /// hub must actually use it.
  final String? changesToken;
  final int recordsToday;
  final String diagnosticsJson;
  final String? lastError;
  const IntegrationRow(
      {required this.vendor,
      required this.status,
      this.lastAttempt,
      this.lastSync,
      this.changesToken,
      required this.recordsToday,
      required this.diagnosticsJson,
      this.lastError});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['vendor'] = Variable<String>(vendor);
    map['status'] = Variable<String>(status);
    if (!nullToAbsent || lastAttempt != null) {
      map['last_attempt'] = Variable<DateTime>(lastAttempt);
    }
    if (!nullToAbsent || lastSync != null) {
      map['last_sync'] = Variable<DateTime>(lastSync);
    }
    if (!nullToAbsent || changesToken != null) {
      map['changes_token'] = Variable<String>(changesToken);
    }
    map['records_today'] = Variable<int>(recordsToday);
    map['diagnostics_json'] = Variable<String>(diagnosticsJson);
    if (!nullToAbsent || lastError != null) {
      map['last_error'] = Variable<String>(lastError);
    }
    return map;
  }

  IntegrationsCompanion toCompanion(bool nullToAbsent) {
    return IntegrationsCompanion(
      vendor: Value(vendor),
      status: Value(status),
      lastAttempt: lastAttempt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastAttempt),
      lastSync: lastSync == null && nullToAbsent
          ? const Value.absent()
          : Value(lastSync),
      changesToken: changesToken == null && nullToAbsent
          ? const Value.absent()
          : Value(changesToken),
      recordsToday: Value(recordsToday),
      diagnosticsJson: Value(diagnosticsJson),
      lastError: lastError == null && nullToAbsent
          ? const Value.absent()
          : Value(lastError),
    );
  }

  factory IntegrationRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return IntegrationRow(
      vendor: serializer.fromJson<String>(json['vendor']),
      status: serializer.fromJson<String>(json['status']),
      lastAttempt: serializer.fromJson<DateTime?>(json['lastAttempt']),
      lastSync: serializer.fromJson<DateTime?>(json['lastSync']),
      changesToken: serializer.fromJson<String?>(json['changesToken']),
      recordsToday: serializer.fromJson<int>(json['recordsToday']),
      diagnosticsJson: serializer.fromJson<String>(json['diagnosticsJson']),
      lastError: serializer.fromJson<String?>(json['lastError']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'vendor': serializer.toJson<String>(vendor),
      'status': serializer.toJson<String>(status),
      'lastAttempt': serializer.toJson<DateTime?>(lastAttempt),
      'lastSync': serializer.toJson<DateTime?>(lastSync),
      'changesToken': serializer.toJson<String?>(changesToken),
      'recordsToday': serializer.toJson<int>(recordsToday),
      'diagnosticsJson': serializer.toJson<String>(diagnosticsJson),
      'lastError': serializer.toJson<String?>(lastError),
    };
  }

  IntegrationRow copyWith(
          {String? vendor,
          String? status,
          Value<DateTime?> lastAttempt = const Value.absent(),
          Value<DateTime?> lastSync = const Value.absent(),
          Value<String?> changesToken = const Value.absent(),
          int? recordsToday,
          String? diagnosticsJson,
          Value<String?> lastError = const Value.absent()}) =>
      IntegrationRow(
        vendor: vendor ?? this.vendor,
        status: status ?? this.status,
        lastAttempt: lastAttempt.present ? lastAttempt.value : this.lastAttempt,
        lastSync: lastSync.present ? lastSync.value : this.lastSync,
        changesToken:
            changesToken.present ? changesToken.value : this.changesToken,
        recordsToday: recordsToday ?? this.recordsToday,
        diagnosticsJson: diagnosticsJson ?? this.diagnosticsJson,
        lastError: lastError.present ? lastError.value : this.lastError,
      );
  IntegrationRow copyWithCompanion(IntegrationsCompanion data) {
    return IntegrationRow(
      vendor: data.vendor.present ? data.vendor.value : this.vendor,
      status: data.status.present ? data.status.value : this.status,
      lastAttempt:
          data.lastAttempt.present ? data.lastAttempt.value : this.lastAttempt,
      lastSync: data.lastSync.present ? data.lastSync.value : this.lastSync,
      changesToken: data.changesToken.present
          ? data.changesToken.value
          : this.changesToken,
      recordsToday: data.recordsToday.present
          ? data.recordsToday.value
          : this.recordsToday,
      diagnosticsJson: data.diagnosticsJson.present
          ? data.diagnosticsJson.value
          : this.diagnosticsJson,
      lastError: data.lastError.present ? data.lastError.value : this.lastError,
    );
  }

  @override
  String toString() {
    return (StringBuffer('IntegrationRow(')
          ..write('vendor: $vendor, ')
          ..write('status: $status, ')
          ..write('lastAttempt: $lastAttempt, ')
          ..write('lastSync: $lastSync, ')
          ..write('changesToken: $changesToken, ')
          ..write('recordsToday: $recordsToday, ')
          ..write('diagnosticsJson: $diagnosticsJson, ')
          ..write('lastError: $lastError')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(vendor, status, lastAttempt, lastSync,
      changesToken, recordsToday, diagnosticsJson, lastError);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is IntegrationRow &&
          other.vendor == this.vendor &&
          other.status == this.status &&
          other.lastAttempt == this.lastAttempt &&
          other.lastSync == this.lastSync &&
          other.changesToken == this.changesToken &&
          other.recordsToday == this.recordsToday &&
          other.diagnosticsJson == this.diagnosticsJson &&
          other.lastError == this.lastError);
}

class IntegrationsCompanion extends UpdateCompanion<IntegrationRow> {
  final Value<String> vendor;
  final Value<String> status;
  final Value<DateTime?> lastAttempt;
  final Value<DateTime?> lastSync;
  final Value<String?> changesToken;
  final Value<int> recordsToday;
  final Value<String> diagnosticsJson;
  final Value<String?> lastError;
  final Value<int> rowid;
  const IntegrationsCompanion({
    this.vendor = const Value.absent(),
    this.status = const Value.absent(),
    this.lastAttempt = const Value.absent(),
    this.lastSync = const Value.absent(),
    this.changesToken = const Value.absent(),
    this.recordsToday = const Value.absent(),
    this.diagnosticsJson = const Value.absent(),
    this.lastError = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  IntegrationsCompanion.insert({
    required String vendor,
    required String status,
    this.lastAttempt = const Value.absent(),
    this.lastSync = const Value.absent(),
    this.changesToken = const Value.absent(),
    this.recordsToday = const Value.absent(),
    this.diagnosticsJson = const Value.absent(),
    this.lastError = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : vendor = Value(vendor),
        status = Value(status);
  static Insertable<IntegrationRow> custom({
    Expression<String>? vendor,
    Expression<String>? status,
    Expression<DateTime>? lastAttempt,
    Expression<DateTime>? lastSync,
    Expression<String>? changesToken,
    Expression<int>? recordsToday,
    Expression<String>? diagnosticsJson,
    Expression<String>? lastError,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (vendor != null) 'vendor': vendor,
      if (status != null) 'status': status,
      if (lastAttempt != null) 'last_attempt': lastAttempt,
      if (lastSync != null) 'last_sync': lastSync,
      if (changesToken != null) 'changes_token': changesToken,
      if (recordsToday != null) 'records_today': recordsToday,
      if (diagnosticsJson != null) 'diagnostics_json': diagnosticsJson,
      if (lastError != null) 'last_error': lastError,
      if (rowid != null) 'rowid': rowid,
    });
  }

  IntegrationsCompanion copyWith(
      {Value<String>? vendor,
      Value<String>? status,
      Value<DateTime?>? lastAttempt,
      Value<DateTime?>? lastSync,
      Value<String?>? changesToken,
      Value<int>? recordsToday,
      Value<String>? diagnosticsJson,
      Value<String?>? lastError,
      Value<int>? rowid}) {
    return IntegrationsCompanion(
      vendor: vendor ?? this.vendor,
      status: status ?? this.status,
      lastAttempt: lastAttempt ?? this.lastAttempt,
      lastSync: lastSync ?? this.lastSync,
      changesToken: changesToken ?? this.changesToken,
      recordsToday: recordsToday ?? this.recordsToday,
      diagnosticsJson: diagnosticsJson ?? this.diagnosticsJson,
      lastError: lastError ?? this.lastError,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (vendor.present) {
      map['vendor'] = Variable<String>(vendor.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (lastAttempt.present) {
      map['last_attempt'] = Variable<DateTime>(lastAttempt.value);
    }
    if (lastSync.present) {
      map['last_sync'] = Variable<DateTime>(lastSync.value);
    }
    if (changesToken.present) {
      map['changes_token'] = Variable<String>(changesToken.value);
    }
    if (recordsToday.present) {
      map['records_today'] = Variable<int>(recordsToday.value);
    }
    if (diagnosticsJson.present) {
      map['diagnostics_json'] = Variable<String>(diagnosticsJson.value);
    }
    if (lastError.present) {
      map['last_error'] = Variable<String>(lastError.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('IntegrationsCompanion(')
          ..write('vendor: $vendor, ')
          ..write('status: $status, ')
          ..write('lastAttempt: $lastAttempt, ')
          ..write('lastSync: $lastSync, ')
          ..write('changesToken: $changesToken, ')
          ..write('recordsToday: $recordsToday, ')
          ..write('diagnosticsJson: $diagnosticsJson, ')
          ..write('lastError: $lastError, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SleepSegmentsTable extends SleepSegments
    with TableInfo<$SleepSegmentsTable, SleepSegmentRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SleepSegmentsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _startUtcMeta =
      const VerificationMeta('startUtc');
  @override
  late final GeneratedColumn<DateTime> startUtc = GeneratedColumn<DateTime>(
      'start_utc', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _endUtcMeta = const VerificationMeta('endUtc');
  @override
  late final GeneratedColumn<DateTime> endUtc = GeneratedColumn<DateTime>(
      'end_utc', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _stageMeta = const VerificationMeta('stage');
  @override
  late final GeneratedColumn<String> stage = GeneratedColumn<String>(
      'stage', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _sourceMeta = const VerificationMeta('source');
  @override
  late final GeneratedColumn<String> source = GeneratedColumn<String>(
      'source', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _priorityMeta =
      const VerificationMeta('priority');
  @override
  late final GeneratedColumn<int> priority = GeneratedColumn<int>(
      'priority', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _nightOfMeta =
      const VerificationMeta('nightOf');
  @override
  late final GeneratedColumn<String> nightOf = GeneratedColumn<String>(
      'night_of', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _externalIdMeta =
      const VerificationMeta('externalId');
  @override
  late final GeneratedColumn<String> externalId = GeneratedColumn<String>(
      'external_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _syncedAtMeta =
      const VerificationMeta('syncedAt');
  @override
  late final GeneratedColumn<DateTime> syncedAt = GeneratedColumn<DateTime>(
      'synced_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        startUtc,
        endUtc,
        stage,
        source,
        priority,
        nightOf,
        externalId,
        syncedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sleep_segments';
  @override
  VerificationContext validateIntegrity(Insertable<SleepSegmentRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('start_utc')) {
      context.handle(_startUtcMeta,
          startUtc.isAcceptableOrUnknown(data['start_utc']!, _startUtcMeta));
    } else if (isInserting) {
      context.missing(_startUtcMeta);
    }
    if (data.containsKey('end_utc')) {
      context.handle(_endUtcMeta,
          endUtc.isAcceptableOrUnknown(data['end_utc']!, _endUtcMeta));
    } else if (isInserting) {
      context.missing(_endUtcMeta);
    }
    if (data.containsKey('stage')) {
      context.handle(
          _stageMeta, stage.isAcceptableOrUnknown(data['stage']!, _stageMeta));
    } else if (isInserting) {
      context.missing(_stageMeta);
    }
    if (data.containsKey('source')) {
      context.handle(_sourceMeta,
          source.isAcceptableOrUnknown(data['source']!, _sourceMeta));
    } else if (isInserting) {
      context.missing(_sourceMeta);
    }
    if (data.containsKey('priority')) {
      context.handle(_priorityMeta,
          priority.isAcceptableOrUnknown(data['priority']!, _priorityMeta));
    } else if (isInserting) {
      context.missing(_priorityMeta);
    }
    if (data.containsKey('night_of')) {
      context.handle(_nightOfMeta,
          nightOf.isAcceptableOrUnknown(data['night_of']!, _nightOfMeta));
    } else if (isInserting) {
      context.missing(_nightOfMeta);
    }
    if (data.containsKey('external_id')) {
      context.handle(
          _externalIdMeta,
          externalId.isAcceptableOrUnknown(
              data['external_id']!, _externalIdMeta));
    }
    if (data.containsKey('synced_at')) {
      context.handle(_syncedAtMeta,
          syncedAt.isAcceptableOrUnknown(data['synced_at']!, _syncedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SleepSegmentRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SleepSegmentRow(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      startUtc: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}start_utc'])!,
      endUtc: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}end_utc'])!,
      stage: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}stage'])!,
      source: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}source'])!,
      priority: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}priority'])!,
      nightOf: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}night_of'])!,
      externalId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}external_id']),
      syncedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}synced_at']),
    );
  }

  @override
  $SleepSegmentsTable createAlias(String alias) {
    return $SleepSegmentsTable(attachedDatabase, alias);
  }
}

class SleepSegmentRow extends DataClass implements Insertable<SleepSegmentRow> {
  final int id;
  final DateTime startUtc;
  final DateTime endUtc;

  /// `awake` | `light` | `deep` | `rem` | `unknown`. Hubs frequently report
  /// only `unknown`; the charts must render that honestly rather than
  /// inventing a distribution.
  final String stage;
  final String source;
  final int priority;

  /// The night this segment belongs to, as a local `yyyy-MM-dd`. A sleep
  /// period crossing midnight belongs to the morning it ends on.
  final String nightOf;
  final String? externalId;
  final DateTime? syncedAt;
  const SleepSegmentRow(
      {required this.id,
      required this.startUtc,
      required this.endUtc,
      required this.stage,
      required this.source,
      required this.priority,
      required this.nightOf,
      this.externalId,
      this.syncedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['start_utc'] = Variable<DateTime>(startUtc);
    map['end_utc'] = Variable<DateTime>(endUtc);
    map['stage'] = Variable<String>(stage);
    map['source'] = Variable<String>(source);
    map['priority'] = Variable<int>(priority);
    map['night_of'] = Variable<String>(nightOf);
    if (!nullToAbsent || externalId != null) {
      map['external_id'] = Variable<String>(externalId);
    }
    if (!nullToAbsent || syncedAt != null) {
      map['synced_at'] = Variable<DateTime>(syncedAt);
    }
    return map;
  }

  SleepSegmentsCompanion toCompanion(bool nullToAbsent) {
    return SleepSegmentsCompanion(
      id: Value(id),
      startUtc: Value(startUtc),
      endUtc: Value(endUtc),
      stage: Value(stage),
      source: Value(source),
      priority: Value(priority),
      nightOf: Value(nightOf),
      externalId: externalId == null && nullToAbsent
          ? const Value.absent()
          : Value(externalId),
      syncedAt: syncedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(syncedAt),
    );
  }

  factory SleepSegmentRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SleepSegmentRow(
      id: serializer.fromJson<int>(json['id']),
      startUtc: serializer.fromJson<DateTime>(json['startUtc']),
      endUtc: serializer.fromJson<DateTime>(json['endUtc']),
      stage: serializer.fromJson<String>(json['stage']),
      source: serializer.fromJson<String>(json['source']),
      priority: serializer.fromJson<int>(json['priority']),
      nightOf: serializer.fromJson<String>(json['nightOf']),
      externalId: serializer.fromJson<String?>(json['externalId']),
      syncedAt: serializer.fromJson<DateTime?>(json['syncedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'startUtc': serializer.toJson<DateTime>(startUtc),
      'endUtc': serializer.toJson<DateTime>(endUtc),
      'stage': serializer.toJson<String>(stage),
      'source': serializer.toJson<String>(source),
      'priority': serializer.toJson<int>(priority),
      'nightOf': serializer.toJson<String>(nightOf),
      'externalId': serializer.toJson<String?>(externalId),
      'syncedAt': serializer.toJson<DateTime?>(syncedAt),
    };
  }

  SleepSegmentRow copyWith(
          {int? id,
          DateTime? startUtc,
          DateTime? endUtc,
          String? stage,
          String? source,
          int? priority,
          String? nightOf,
          Value<String?> externalId = const Value.absent(),
          Value<DateTime?> syncedAt = const Value.absent()}) =>
      SleepSegmentRow(
        id: id ?? this.id,
        startUtc: startUtc ?? this.startUtc,
        endUtc: endUtc ?? this.endUtc,
        stage: stage ?? this.stage,
        source: source ?? this.source,
        priority: priority ?? this.priority,
        nightOf: nightOf ?? this.nightOf,
        externalId: externalId.present ? externalId.value : this.externalId,
        syncedAt: syncedAt.present ? syncedAt.value : this.syncedAt,
      );
  SleepSegmentRow copyWithCompanion(SleepSegmentsCompanion data) {
    return SleepSegmentRow(
      id: data.id.present ? data.id.value : this.id,
      startUtc: data.startUtc.present ? data.startUtc.value : this.startUtc,
      endUtc: data.endUtc.present ? data.endUtc.value : this.endUtc,
      stage: data.stage.present ? data.stage.value : this.stage,
      source: data.source.present ? data.source.value : this.source,
      priority: data.priority.present ? data.priority.value : this.priority,
      nightOf: data.nightOf.present ? data.nightOf.value : this.nightOf,
      externalId:
          data.externalId.present ? data.externalId.value : this.externalId,
      syncedAt: data.syncedAt.present ? data.syncedAt.value : this.syncedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SleepSegmentRow(')
          ..write('id: $id, ')
          ..write('startUtc: $startUtc, ')
          ..write('endUtc: $endUtc, ')
          ..write('stage: $stage, ')
          ..write('source: $source, ')
          ..write('priority: $priority, ')
          ..write('nightOf: $nightOf, ')
          ..write('externalId: $externalId, ')
          ..write('syncedAt: $syncedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, startUtc, endUtc, stage, source, priority,
      nightOf, externalId, syncedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SleepSegmentRow &&
          other.id == this.id &&
          other.startUtc == this.startUtc &&
          other.endUtc == this.endUtc &&
          other.stage == this.stage &&
          other.source == this.source &&
          other.priority == this.priority &&
          other.nightOf == this.nightOf &&
          other.externalId == this.externalId &&
          other.syncedAt == this.syncedAt);
}

class SleepSegmentsCompanion extends UpdateCompanion<SleepSegmentRow> {
  final Value<int> id;
  final Value<DateTime> startUtc;
  final Value<DateTime> endUtc;
  final Value<String> stage;
  final Value<String> source;
  final Value<int> priority;
  final Value<String> nightOf;
  final Value<String?> externalId;
  final Value<DateTime?> syncedAt;
  const SleepSegmentsCompanion({
    this.id = const Value.absent(),
    this.startUtc = const Value.absent(),
    this.endUtc = const Value.absent(),
    this.stage = const Value.absent(),
    this.source = const Value.absent(),
    this.priority = const Value.absent(),
    this.nightOf = const Value.absent(),
    this.externalId = const Value.absent(),
    this.syncedAt = const Value.absent(),
  });
  SleepSegmentsCompanion.insert({
    this.id = const Value.absent(),
    required DateTime startUtc,
    required DateTime endUtc,
    required String stage,
    required String source,
    required int priority,
    required String nightOf,
    this.externalId = const Value.absent(),
    this.syncedAt = const Value.absent(),
  })  : startUtc = Value(startUtc),
        endUtc = Value(endUtc),
        stage = Value(stage),
        source = Value(source),
        priority = Value(priority),
        nightOf = Value(nightOf);
  static Insertable<SleepSegmentRow> custom({
    Expression<int>? id,
    Expression<DateTime>? startUtc,
    Expression<DateTime>? endUtc,
    Expression<String>? stage,
    Expression<String>? source,
    Expression<int>? priority,
    Expression<String>? nightOf,
    Expression<String>? externalId,
    Expression<DateTime>? syncedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (startUtc != null) 'start_utc': startUtc,
      if (endUtc != null) 'end_utc': endUtc,
      if (stage != null) 'stage': stage,
      if (source != null) 'source': source,
      if (priority != null) 'priority': priority,
      if (nightOf != null) 'night_of': nightOf,
      if (externalId != null) 'external_id': externalId,
      if (syncedAt != null) 'synced_at': syncedAt,
    });
  }

  SleepSegmentsCompanion copyWith(
      {Value<int>? id,
      Value<DateTime>? startUtc,
      Value<DateTime>? endUtc,
      Value<String>? stage,
      Value<String>? source,
      Value<int>? priority,
      Value<String>? nightOf,
      Value<String?>? externalId,
      Value<DateTime?>? syncedAt}) {
    return SleepSegmentsCompanion(
      id: id ?? this.id,
      startUtc: startUtc ?? this.startUtc,
      endUtc: endUtc ?? this.endUtc,
      stage: stage ?? this.stage,
      source: source ?? this.source,
      priority: priority ?? this.priority,
      nightOf: nightOf ?? this.nightOf,
      externalId: externalId ?? this.externalId,
      syncedAt: syncedAt ?? this.syncedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (startUtc.present) {
      map['start_utc'] = Variable<DateTime>(startUtc.value);
    }
    if (endUtc.present) {
      map['end_utc'] = Variable<DateTime>(endUtc.value);
    }
    if (stage.present) {
      map['stage'] = Variable<String>(stage.value);
    }
    if (source.present) {
      map['source'] = Variable<String>(source.value);
    }
    if (priority.present) {
      map['priority'] = Variable<int>(priority.value);
    }
    if (nightOf.present) {
      map['night_of'] = Variable<String>(nightOf.value);
    }
    if (externalId.present) {
      map['external_id'] = Variable<String>(externalId.value);
    }
    if (syncedAt.present) {
      map['synced_at'] = Variable<DateTime>(syncedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SleepSegmentsCompanion(')
          ..write('id: $id, ')
          ..write('startUtc: $startUtc, ')
          ..write('endUtc: $endUtc, ')
          ..write('stage: $stage, ')
          ..write('source: $source, ')
          ..write('priority: $priority, ')
          ..write('nightOf: $nightOf, ')
          ..write('externalId: $externalId, ')
          ..write('syncedAt: $syncedAt')
          ..write(')'))
        .toString();
  }
}

class $DailyVitalsTable extends DailyVitals
    with TableInfo<$DailyVitalsTable, DailyVitalsRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DailyVitalsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<String> date = GeneratedColumn<String>(
      'date', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _restingHrMeta =
      const VerificationMeta('restingHr');
  @override
  late final GeneratedColumn<double> restingHr = GeneratedColumn<double>(
      'resting_hr', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _hrvMsMeta = const VerificationMeta('hrvMs');
  @override
  late final GeneratedColumn<double> hrvMs = GeneratedColumn<double>(
      'hrv_ms', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _respiratoryRateMeta =
      const VerificationMeta('respiratoryRate');
  @override
  late final GeneratedColumn<double> respiratoryRate = GeneratedColumn<double>(
      'respiratory_rate', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _bodyTemperatureDeltaMeta =
      const VerificationMeta('bodyTemperatureDelta');
  @override
  late final GeneratedColumn<double> bodyTemperatureDelta =
      GeneratedColumn<double>('body_temperature_delta', aliasedName, true,
          type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _sleepScoreMeta =
      const VerificationMeta('sleepScore');
  @override
  late final GeneratedColumn<double> sleepScore = GeneratedColumn<double>(
      'sleep_score', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _readinessScoreMeta =
      const VerificationMeta('readinessScore');
  @override
  late final GeneratedColumn<double> readinessScore = GeneratedColumn<double>(
      'readiness_score', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _sourceMeta = const VerificationMeta('source');
  @override
  late final GeneratedColumn<String> source = GeneratedColumn<String>(
      'source', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _syncedAtMeta =
      const VerificationMeta('syncedAt');
  @override
  late final GeneratedColumn<DateTime> syncedAt = GeneratedColumn<DateTime>(
      'synced_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        date,
        restingHr,
        hrvMs,
        respiratoryRate,
        bodyTemperatureDelta,
        sleepScore,
        readinessScore,
        source,
        syncedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'daily_vitals';
  @override
  VerificationContext validateIntegrity(Insertable<DailyVitalsRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('date')) {
      context.handle(
          _dateMeta, date.isAcceptableOrUnknown(data['date']!, _dateMeta));
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('resting_hr')) {
      context.handle(_restingHrMeta,
          restingHr.isAcceptableOrUnknown(data['resting_hr']!, _restingHrMeta));
    }
    if (data.containsKey('hrv_ms')) {
      context.handle(
          _hrvMsMeta, hrvMs.isAcceptableOrUnknown(data['hrv_ms']!, _hrvMsMeta));
    }
    if (data.containsKey('respiratory_rate')) {
      context.handle(
          _respiratoryRateMeta,
          respiratoryRate.isAcceptableOrUnknown(
              data['respiratory_rate']!, _respiratoryRateMeta));
    }
    if (data.containsKey('body_temperature_delta')) {
      context.handle(
          _bodyTemperatureDeltaMeta,
          bodyTemperatureDelta.isAcceptableOrUnknown(
              data['body_temperature_delta']!, _bodyTemperatureDeltaMeta));
    }
    if (data.containsKey('sleep_score')) {
      context.handle(
          _sleepScoreMeta,
          sleepScore.isAcceptableOrUnknown(
              data['sleep_score']!, _sleepScoreMeta));
    }
    if (data.containsKey('readiness_score')) {
      context.handle(
          _readinessScoreMeta,
          readinessScore.isAcceptableOrUnknown(
              data['readiness_score']!, _readinessScoreMeta));
    }
    if (data.containsKey('source')) {
      context.handle(_sourceMeta,
          source.isAcceptableOrUnknown(data['source']!, _sourceMeta));
    } else if (isInserting) {
      context.missing(_sourceMeta);
    }
    if (data.containsKey('synced_at')) {
      context.handle(_syncedAtMeta,
          syncedAt.isAcceptableOrUnknown(data['synced_at']!, _syncedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {date};
  @override
  DailyVitalsRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DailyVitalsRow(
      date: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}date'])!,
      restingHr: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}resting_hr']),
      hrvMs: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}hrv_ms']),
      respiratoryRate: attachedDatabase.typeMapping.read(
          DriftSqlType.double, data['${effectivePrefix}respiratory_rate']),
      bodyTemperatureDelta: attachedDatabase.typeMapping.read(
          DriftSqlType.double,
          data['${effectivePrefix}body_temperature_delta']),
      sleepScore: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}sleep_score']),
      readinessScore: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}readiness_score']),
      source: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}source'])!,
      syncedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}synced_at']),
    );
  }

  @override
  $DailyVitalsTable createAlias(String alias) {
    return $DailyVitalsTable(attachedDatabase, alias);
  }
}

class DailyVitalsRow extends DataClass implements Insertable<DailyVitalsRow> {
  final String date;
  final double? restingHr;
  final double? hrvMs;
  final double? respiratoryRate;
  final double? bodyTemperatureDelta;

  /// Vendor-computed scores. Kept separate from the raw signals because they
  /// are opinions, not measurements, and guidance should say which it is using.
  final double? sleepScore;
  final double? readinessScore;
  final String source;
  final DateTime? syncedAt;
  const DailyVitalsRow(
      {required this.date,
      this.restingHr,
      this.hrvMs,
      this.respiratoryRate,
      this.bodyTemperatureDelta,
      this.sleepScore,
      this.readinessScore,
      required this.source,
      this.syncedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['date'] = Variable<String>(date);
    if (!nullToAbsent || restingHr != null) {
      map['resting_hr'] = Variable<double>(restingHr);
    }
    if (!nullToAbsent || hrvMs != null) {
      map['hrv_ms'] = Variable<double>(hrvMs);
    }
    if (!nullToAbsent || respiratoryRate != null) {
      map['respiratory_rate'] = Variable<double>(respiratoryRate);
    }
    if (!nullToAbsent || bodyTemperatureDelta != null) {
      map['body_temperature_delta'] = Variable<double>(bodyTemperatureDelta);
    }
    if (!nullToAbsent || sleepScore != null) {
      map['sleep_score'] = Variable<double>(sleepScore);
    }
    if (!nullToAbsent || readinessScore != null) {
      map['readiness_score'] = Variable<double>(readinessScore);
    }
    map['source'] = Variable<String>(source);
    if (!nullToAbsent || syncedAt != null) {
      map['synced_at'] = Variable<DateTime>(syncedAt);
    }
    return map;
  }

  DailyVitalsCompanion toCompanion(bool nullToAbsent) {
    return DailyVitalsCompanion(
      date: Value(date),
      restingHr: restingHr == null && nullToAbsent
          ? const Value.absent()
          : Value(restingHr),
      hrvMs:
          hrvMs == null && nullToAbsent ? const Value.absent() : Value(hrvMs),
      respiratoryRate: respiratoryRate == null && nullToAbsent
          ? const Value.absent()
          : Value(respiratoryRate),
      bodyTemperatureDelta: bodyTemperatureDelta == null && nullToAbsent
          ? const Value.absent()
          : Value(bodyTemperatureDelta),
      sleepScore: sleepScore == null && nullToAbsent
          ? const Value.absent()
          : Value(sleepScore),
      readinessScore: readinessScore == null && nullToAbsent
          ? const Value.absent()
          : Value(readinessScore),
      source: Value(source),
      syncedAt: syncedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(syncedAt),
    );
  }

  factory DailyVitalsRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DailyVitalsRow(
      date: serializer.fromJson<String>(json['date']),
      restingHr: serializer.fromJson<double?>(json['restingHr']),
      hrvMs: serializer.fromJson<double?>(json['hrvMs']),
      respiratoryRate: serializer.fromJson<double?>(json['respiratoryRate']),
      bodyTemperatureDelta:
          serializer.fromJson<double?>(json['bodyTemperatureDelta']),
      sleepScore: serializer.fromJson<double?>(json['sleepScore']),
      readinessScore: serializer.fromJson<double?>(json['readinessScore']),
      source: serializer.fromJson<String>(json['source']),
      syncedAt: serializer.fromJson<DateTime?>(json['syncedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'date': serializer.toJson<String>(date),
      'restingHr': serializer.toJson<double?>(restingHr),
      'hrvMs': serializer.toJson<double?>(hrvMs),
      'respiratoryRate': serializer.toJson<double?>(respiratoryRate),
      'bodyTemperatureDelta': serializer.toJson<double?>(bodyTemperatureDelta),
      'sleepScore': serializer.toJson<double?>(sleepScore),
      'readinessScore': serializer.toJson<double?>(readinessScore),
      'source': serializer.toJson<String>(source),
      'syncedAt': serializer.toJson<DateTime?>(syncedAt),
    };
  }

  DailyVitalsRow copyWith(
          {String? date,
          Value<double?> restingHr = const Value.absent(),
          Value<double?> hrvMs = const Value.absent(),
          Value<double?> respiratoryRate = const Value.absent(),
          Value<double?> bodyTemperatureDelta = const Value.absent(),
          Value<double?> sleepScore = const Value.absent(),
          Value<double?> readinessScore = const Value.absent(),
          String? source,
          Value<DateTime?> syncedAt = const Value.absent()}) =>
      DailyVitalsRow(
        date: date ?? this.date,
        restingHr: restingHr.present ? restingHr.value : this.restingHr,
        hrvMs: hrvMs.present ? hrvMs.value : this.hrvMs,
        respiratoryRate: respiratoryRate.present
            ? respiratoryRate.value
            : this.respiratoryRate,
        bodyTemperatureDelta: bodyTemperatureDelta.present
            ? bodyTemperatureDelta.value
            : this.bodyTemperatureDelta,
        sleepScore: sleepScore.present ? sleepScore.value : this.sleepScore,
        readinessScore:
            readinessScore.present ? readinessScore.value : this.readinessScore,
        source: source ?? this.source,
        syncedAt: syncedAt.present ? syncedAt.value : this.syncedAt,
      );
  DailyVitalsRow copyWithCompanion(DailyVitalsCompanion data) {
    return DailyVitalsRow(
      date: data.date.present ? data.date.value : this.date,
      restingHr: data.restingHr.present ? data.restingHr.value : this.restingHr,
      hrvMs: data.hrvMs.present ? data.hrvMs.value : this.hrvMs,
      respiratoryRate: data.respiratoryRate.present
          ? data.respiratoryRate.value
          : this.respiratoryRate,
      bodyTemperatureDelta: data.bodyTemperatureDelta.present
          ? data.bodyTemperatureDelta.value
          : this.bodyTemperatureDelta,
      sleepScore:
          data.sleepScore.present ? data.sleepScore.value : this.sleepScore,
      readinessScore: data.readinessScore.present
          ? data.readinessScore.value
          : this.readinessScore,
      source: data.source.present ? data.source.value : this.source,
      syncedAt: data.syncedAt.present ? data.syncedAt.value : this.syncedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DailyVitalsRow(')
          ..write('date: $date, ')
          ..write('restingHr: $restingHr, ')
          ..write('hrvMs: $hrvMs, ')
          ..write('respiratoryRate: $respiratoryRate, ')
          ..write('bodyTemperatureDelta: $bodyTemperatureDelta, ')
          ..write('sleepScore: $sleepScore, ')
          ..write('readinessScore: $readinessScore, ')
          ..write('source: $source, ')
          ..write('syncedAt: $syncedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(date, restingHr, hrvMs, respiratoryRate,
      bodyTemperatureDelta, sleepScore, readinessScore, source, syncedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DailyVitalsRow &&
          other.date == this.date &&
          other.restingHr == this.restingHr &&
          other.hrvMs == this.hrvMs &&
          other.respiratoryRate == this.respiratoryRate &&
          other.bodyTemperatureDelta == this.bodyTemperatureDelta &&
          other.sleepScore == this.sleepScore &&
          other.readinessScore == this.readinessScore &&
          other.source == this.source &&
          other.syncedAt == this.syncedAt);
}

class DailyVitalsCompanion extends UpdateCompanion<DailyVitalsRow> {
  final Value<String> date;
  final Value<double?> restingHr;
  final Value<double?> hrvMs;
  final Value<double?> respiratoryRate;
  final Value<double?> bodyTemperatureDelta;
  final Value<double?> sleepScore;
  final Value<double?> readinessScore;
  final Value<String> source;
  final Value<DateTime?> syncedAt;
  final Value<int> rowid;
  const DailyVitalsCompanion({
    this.date = const Value.absent(),
    this.restingHr = const Value.absent(),
    this.hrvMs = const Value.absent(),
    this.respiratoryRate = const Value.absent(),
    this.bodyTemperatureDelta = const Value.absent(),
    this.sleepScore = const Value.absent(),
    this.readinessScore = const Value.absent(),
    this.source = const Value.absent(),
    this.syncedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DailyVitalsCompanion.insert({
    required String date,
    this.restingHr = const Value.absent(),
    this.hrvMs = const Value.absent(),
    this.respiratoryRate = const Value.absent(),
    this.bodyTemperatureDelta = const Value.absent(),
    this.sleepScore = const Value.absent(),
    this.readinessScore = const Value.absent(),
    required String source,
    this.syncedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : date = Value(date),
        source = Value(source);
  static Insertable<DailyVitalsRow> custom({
    Expression<String>? date,
    Expression<double>? restingHr,
    Expression<double>? hrvMs,
    Expression<double>? respiratoryRate,
    Expression<double>? bodyTemperatureDelta,
    Expression<double>? sleepScore,
    Expression<double>? readinessScore,
    Expression<String>? source,
    Expression<DateTime>? syncedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (date != null) 'date': date,
      if (restingHr != null) 'resting_hr': restingHr,
      if (hrvMs != null) 'hrv_ms': hrvMs,
      if (respiratoryRate != null) 'respiratory_rate': respiratoryRate,
      if (bodyTemperatureDelta != null)
        'body_temperature_delta': bodyTemperatureDelta,
      if (sleepScore != null) 'sleep_score': sleepScore,
      if (readinessScore != null) 'readiness_score': readinessScore,
      if (source != null) 'source': source,
      if (syncedAt != null) 'synced_at': syncedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DailyVitalsCompanion copyWith(
      {Value<String>? date,
      Value<double?>? restingHr,
      Value<double?>? hrvMs,
      Value<double?>? respiratoryRate,
      Value<double?>? bodyTemperatureDelta,
      Value<double?>? sleepScore,
      Value<double?>? readinessScore,
      Value<String>? source,
      Value<DateTime?>? syncedAt,
      Value<int>? rowid}) {
    return DailyVitalsCompanion(
      date: date ?? this.date,
      restingHr: restingHr ?? this.restingHr,
      hrvMs: hrvMs ?? this.hrvMs,
      respiratoryRate: respiratoryRate ?? this.respiratoryRate,
      bodyTemperatureDelta: bodyTemperatureDelta ?? this.bodyTemperatureDelta,
      sleepScore: sleepScore ?? this.sleepScore,
      readinessScore: readinessScore ?? this.readinessScore,
      source: source ?? this.source,
      syncedAt: syncedAt ?? this.syncedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (date.present) {
      map['date'] = Variable<String>(date.value);
    }
    if (restingHr.present) {
      map['resting_hr'] = Variable<double>(restingHr.value);
    }
    if (hrvMs.present) {
      map['hrv_ms'] = Variable<double>(hrvMs.value);
    }
    if (respiratoryRate.present) {
      map['respiratory_rate'] = Variable<double>(respiratoryRate.value);
    }
    if (bodyTemperatureDelta.present) {
      map['body_temperature_delta'] =
          Variable<double>(bodyTemperatureDelta.value);
    }
    if (sleepScore.present) {
      map['sleep_score'] = Variable<double>(sleepScore.value);
    }
    if (readinessScore.present) {
      map['readiness_score'] = Variable<double>(readinessScore.value);
    }
    if (source.present) {
      map['source'] = Variable<String>(source.value);
    }
    if (syncedAt.present) {
      map['synced_at'] = Variable<DateTime>(syncedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DailyVitalsCompanion(')
          ..write('date: $date, ')
          ..write('restingHr: $restingHr, ')
          ..write('hrvMs: $hrvMs, ')
          ..write('respiratoryRate: $respiratoryRate, ')
          ..write('bodyTemperatureDelta: $bodyTemperatureDelta, ')
          ..write('sleepScore: $sleepScore, ')
          ..write('readinessScore: $readinessScore, ')
          ..write('source: $source, ')
          ..write('syncedAt: $syncedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ActivitySessionsTable extends ActivitySessions
    with TableInfo<$ActivitySessionsTable, ActivitySessionRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ActivitySessionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _sportMeta = const VerificationMeta('sport');
  @override
  late final GeneratedColumn<String> sport = GeneratedColumn<String>(
      'sport', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _startUtcMeta =
      const VerificationMeta('startUtc');
  @override
  late final GeneratedColumn<DateTime> startUtc = GeneratedColumn<DateTime>(
      'start_utc', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _endUtcMeta = const VerificationMeta('endUtc');
  @override
  late final GeneratedColumn<DateTime> endUtc = GeneratedColumn<DateTime>(
      'end_utc', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _activeKcalMeta =
      const VerificationMeta('activeKcal');
  @override
  late final GeneratedColumn<double> activeKcal = GeneratedColumn<double>(
      'active_kcal', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _avgHrMeta = const VerificationMeta('avgHr');
  @override
  late final GeneratedColumn<double> avgHr = GeneratedColumn<double>(
      'avg_hr', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _maxHrMeta = const VerificationMeta('maxHr');
  @override
  late final GeneratedColumn<double> maxHr = GeneratedColumn<double>(
      'max_hr', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _stepsMeta = const VerificationMeta('steps');
  @override
  late final GeneratedColumn<int> steps = GeneratedColumn<int>(
      'steps', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _sourceMeta = const VerificationMeta('source');
  @override
  late final GeneratedColumn<String> source = GeneratedColumn<String>(
      'source', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _priorityMeta =
      const VerificationMeta('priority');
  @override
  late final GeneratedColumn<int> priority = GeneratedColumn<int>(
      'priority', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _externalIdMeta =
      const VerificationMeta('externalId');
  @override
  late final GeneratedColumn<String> externalId = GeneratedColumn<String>(
      'external_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _syncedAtMeta =
      const VerificationMeta('syncedAt');
  @override
  late final GeneratedColumn<DateTime> syncedAt = GeneratedColumn<DateTime>(
      'synced_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        sport,
        startUtc,
        endUtc,
        activeKcal,
        avgHr,
        maxHr,
        steps,
        source,
        priority,
        externalId,
        syncedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'activity_sessions';
  @override
  VerificationContext validateIntegrity(Insertable<ActivitySessionRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('sport')) {
      context.handle(
          _sportMeta, sport.isAcceptableOrUnknown(data['sport']!, _sportMeta));
    }
    if (data.containsKey('start_utc')) {
      context.handle(_startUtcMeta,
          startUtc.isAcceptableOrUnknown(data['start_utc']!, _startUtcMeta));
    } else if (isInserting) {
      context.missing(_startUtcMeta);
    }
    if (data.containsKey('end_utc')) {
      context.handle(_endUtcMeta,
          endUtc.isAcceptableOrUnknown(data['end_utc']!, _endUtcMeta));
    } else if (isInserting) {
      context.missing(_endUtcMeta);
    }
    if (data.containsKey('active_kcal')) {
      context.handle(
          _activeKcalMeta,
          activeKcal.isAcceptableOrUnknown(
              data['active_kcal']!, _activeKcalMeta));
    }
    if (data.containsKey('avg_hr')) {
      context.handle(
          _avgHrMeta, avgHr.isAcceptableOrUnknown(data['avg_hr']!, _avgHrMeta));
    }
    if (data.containsKey('max_hr')) {
      context.handle(
          _maxHrMeta, maxHr.isAcceptableOrUnknown(data['max_hr']!, _maxHrMeta));
    }
    if (data.containsKey('steps')) {
      context.handle(
          _stepsMeta, steps.isAcceptableOrUnknown(data['steps']!, _stepsMeta));
    }
    if (data.containsKey('source')) {
      context.handle(_sourceMeta,
          source.isAcceptableOrUnknown(data['source']!, _sourceMeta));
    } else if (isInserting) {
      context.missing(_sourceMeta);
    }
    if (data.containsKey('priority')) {
      context.handle(_priorityMeta,
          priority.isAcceptableOrUnknown(data['priority']!, _priorityMeta));
    } else if (isInserting) {
      context.missing(_priorityMeta);
    }
    if (data.containsKey('external_id')) {
      context.handle(
          _externalIdMeta,
          externalId.isAcceptableOrUnknown(
              data['external_id']!, _externalIdMeta));
    }
    if (data.containsKey('synced_at')) {
      context.handle(_syncedAtMeta,
          syncedAt.isAcceptableOrUnknown(data['synced_at']!, _syncedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ActivitySessionRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ActivitySessionRow(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      sport: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}sport']),
      startUtc: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}start_utc'])!,
      endUtc: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}end_utc'])!,
      activeKcal: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}active_kcal']),
      avgHr: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}avg_hr']),
      maxHr: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}max_hr']),
      steps: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}steps']),
      source: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}source'])!,
      priority: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}priority'])!,
      externalId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}external_id']),
      syncedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}synced_at']),
    );
  }

  @override
  $ActivitySessionsTable createAlias(String alias) {
    return $ActivitySessionsTable(attachedDatabase, alias);
  }
}

class ActivitySessionRow extends DataClass
    implements Insertable<ActivitySessionRow> {
  final String id;
  final String? sport;
  final DateTime startUtc;
  final DateTime endUtc;
  final double? activeKcal;
  final double? avgHr;
  final double? maxHr;
  final int? steps;
  final String source;
  final int priority;
  final String? externalId;
  final DateTime? syncedAt;
  const ActivitySessionRow(
      {required this.id,
      this.sport,
      required this.startUtc,
      required this.endUtc,
      this.activeKcal,
      this.avgHr,
      this.maxHr,
      this.steps,
      required this.source,
      required this.priority,
      this.externalId,
      this.syncedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    if (!nullToAbsent || sport != null) {
      map['sport'] = Variable<String>(sport);
    }
    map['start_utc'] = Variable<DateTime>(startUtc);
    map['end_utc'] = Variable<DateTime>(endUtc);
    if (!nullToAbsent || activeKcal != null) {
      map['active_kcal'] = Variable<double>(activeKcal);
    }
    if (!nullToAbsent || avgHr != null) {
      map['avg_hr'] = Variable<double>(avgHr);
    }
    if (!nullToAbsent || maxHr != null) {
      map['max_hr'] = Variable<double>(maxHr);
    }
    if (!nullToAbsent || steps != null) {
      map['steps'] = Variable<int>(steps);
    }
    map['source'] = Variable<String>(source);
    map['priority'] = Variable<int>(priority);
    if (!nullToAbsent || externalId != null) {
      map['external_id'] = Variable<String>(externalId);
    }
    if (!nullToAbsent || syncedAt != null) {
      map['synced_at'] = Variable<DateTime>(syncedAt);
    }
    return map;
  }

  ActivitySessionsCompanion toCompanion(bool nullToAbsent) {
    return ActivitySessionsCompanion(
      id: Value(id),
      sport:
          sport == null && nullToAbsent ? const Value.absent() : Value(sport),
      startUtc: Value(startUtc),
      endUtc: Value(endUtc),
      activeKcal: activeKcal == null && nullToAbsent
          ? const Value.absent()
          : Value(activeKcal),
      avgHr:
          avgHr == null && nullToAbsent ? const Value.absent() : Value(avgHr),
      maxHr:
          maxHr == null && nullToAbsent ? const Value.absent() : Value(maxHr),
      steps:
          steps == null && nullToAbsent ? const Value.absent() : Value(steps),
      source: Value(source),
      priority: Value(priority),
      externalId: externalId == null && nullToAbsent
          ? const Value.absent()
          : Value(externalId),
      syncedAt: syncedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(syncedAt),
    );
  }

  factory ActivitySessionRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ActivitySessionRow(
      id: serializer.fromJson<String>(json['id']),
      sport: serializer.fromJson<String?>(json['sport']),
      startUtc: serializer.fromJson<DateTime>(json['startUtc']),
      endUtc: serializer.fromJson<DateTime>(json['endUtc']),
      activeKcal: serializer.fromJson<double?>(json['activeKcal']),
      avgHr: serializer.fromJson<double?>(json['avgHr']),
      maxHr: serializer.fromJson<double?>(json['maxHr']),
      steps: serializer.fromJson<int?>(json['steps']),
      source: serializer.fromJson<String>(json['source']),
      priority: serializer.fromJson<int>(json['priority']),
      externalId: serializer.fromJson<String?>(json['externalId']),
      syncedAt: serializer.fromJson<DateTime?>(json['syncedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'sport': serializer.toJson<String?>(sport),
      'startUtc': serializer.toJson<DateTime>(startUtc),
      'endUtc': serializer.toJson<DateTime>(endUtc),
      'activeKcal': serializer.toJson<double?>(activeKcal),
      'avgHr': serializer.toJson<double?>(avgHr),
      'maxHr': serializer.toJson<double?>(maxHr),
      'steps': serializer.toJson<int?>(steps),
      'source': serializer.toJson<String>(source),
      'priority': serializer.toJson<int>(priority),
      'externalId': serializer.toJson<String?>(externalId),
      'syncedAt': serializer.toJson<DateTime?>(syncedAt),
    };
  }

  ActivitySessionRow copyWith(
          {String? id,
          Value<String?> sport = const Value.absent(),
          DateTime? startUtc,
          DateTime? endUtc,
          Value<double?> activeKcal = const Value.absent(),
          Value<double?> avgHr = const Value.absent(),
          Value<double?> maxHr = const Value.absent(),
          Value<int?> steps = const Value.absent(),
          String? source,
          int? priority,
          Value<String?> externalId = const Value.absent(),
          Value<DateTime?> syncedAt = const Value.absent()}) =>
      ActivitySessionRow(
        id: id ?? this.id,
        sport: sport.present ? sport.value : this.sport,
        startUtc: startUtc ?? this.startUtc,
        endUtc: endUtc ?? this.endUtc,
        activeKcal: activeKcal.present ? activeKcal.value : this.activeKcal,
        avgHr: avgHr.present ? avgHr.value : this.avgHr,
        maxHr: maxHr.present ? maxHr.value : this.maxHr,
        steps: steps.present ? steps.value : this.steps,
        source: source ?? this.source,
        priority: priority ?? this.priority,
        externalId: externalId.present ? externalId.value : this.externalId,
        syncedAt: syncedAt.present ? syncedAt.value : this.syncedAt,
      );
  ActivitySessionRow copyWithCompanion(ActivitySessionsCompanion data) {
    return ActivitySessionRow(
      id: data.id.present ? data.id.value : this.id,
      sport: data.sport.present ? data.sport.value : this.sport,
      startUtc: data.startUtc.present ? data.startUtc.value : this.startUtc,
      endUtc: data.endUtc.present ? data.endUtc.value : this.endUtc,
      activeKcal:
          data.activeKcal.present ? data.activeKcal.value : this.activeKcal,
      avgHr: data.avgHr.present ? data.avgHr.value : this.avgHr,
      maxHr: data.maxHr.present ? data.maxHr.value : this.maxHr,
      steps: data.steps.present ? data.steps.value : this.steps,
      source: data.source.present ? data.source.value : this.source,
      priority: data.priority.present ? data.priority.value : this.priority,
      externalId:
          data.externalId.present ? data.externalId.value : this.externalId,
      syncedAt: data.syncedAt.present ? data.syncedAt.value : this.syncedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ActivitySessionRow(')
          ..write('id: $id, ')
          ..write('sport: $sport, ')
          ..write('startUtc: $startUtc, ')
          ..write('endUtc: $endUtc, ')
          ..write('activeKcal: $activeKcal, ')
          ..write('avgHr: $avgHr, ')
          ..write('maxHr: $maxHr, ')
          ..write('steps: $steps, ')
          ..write('source: $source, ')
          ..write('priority: $priority, ')
          ..write('externalId: $externalId, ')
          ..write('syncedAt: $syncedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, sport, startUtc, endUtc, activeKcal,
      avgHr, maxHr, steps, source, priority, externalId, syncedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ActivitySessionRow &&
          other.id == this.id &&
          other.sport == this.sport &&
          other.startUtc == this.startUtc &&
          other.endUtc == this.endUtc &&
          other.activeKcal == this.activeKcal &&
          other.avgHr == this.avgHr &&
          other.maxHr == this.maxHr &&
          other.steps == this.steps &&
          other.source == this.source &&
          other.priority == this.priority &&
          other.externalId == this.externalId &&
          other.syncedAt == this.syncedAt);
}

class ActivitySessionsCompanion extends UpdateCompanion<ActivitySessionRow> {
  final Value<String> id;
  final Value<String?> sport;
  final Value<DateTime> startUtc;
  final Value<DateTime> endUtc;
  final Value<double?> activeKcal;
  final Value<double?> avgHr;
  final Value<double?> maxHr;
  final Value<int?> steps;
  final Value<String> source;
  final Value<int> priority;
  final Value<String?> externalId;
  final Value<DateTime?> syncedAt;
  final Value<int> rowid;
  const ActivitySessionsCompanion({
    this.id = const Value.absent(),
    this.sport = const Value.absent(),
    this.startUtc = const Value.absent(),
    this.endUtc = const Value.absent(),
    this.activeKcal = const Value.absent(),
    this.avgHr = const Value.absent(),
    this.maxHr = const Value.absent(),
    this.steps = const Value.absent(),
    this.source = const Value.absent(),
    this.priority = const Value.absent(),
    this.externalId = const Value.absent(),
    this.syncedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ActivitySessionsCompanion.insert({
    required String id,
    this.sport = const Value.absent(),
    required DateTime startUtc,
    required DateTime endUtc,
    this.activeKcal = const Value.absent(),
    this.avgHr = const Value.absent(),
    this.maxHr = const Value.absent(),
    this.steps = const Value.absent(),
    required String source,
    required int priority,
    this.externalId = const Value.absent(),
    this.syncedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        startUtc = Value(startUtc),
        endUtc = Value(endUtc),
        source = Value(source),
        priority = Value(priority);
  static Insertable<ActivitySessionRow> custom({
    Expression<String>? id,
    Expression<String>? sport,
    Expression<DateTime>? startUtc,
    Expression<DateTime>? endUtc,
    Expression<double>? activeKcal,
    Expression<double>? avgHr,
    Expression<double>? maxHr,
    Expression<int>? steps,
    Expression<String>? source,
    Expression<int>? priority,
    Expression<String>? externalId,
    Expression<DateTime>? syncedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (sport != null) 'sport': sport,
      if (startUtc != null) 'start_utc': startUtc,
      if (endUtc != null) 'end_utc': endUtc,
      if (activeKcal != null) 'active_kcal': activeKcal,
      if (avgHr != null) 'avg_hr': avgHr,
      if (maxHr != null) 'max_hr': maxHr,
      if (steps != null) 'steps': steps,
      if (source != null) 'source': source,
      if (priority != null) 'priority': priority,
      if (externalId != null) 'external_id': externalId,
      if (syncedAt != null) 'synced_at': syncedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ActivitySessionsCompanion copyWith(
      {Value<String>? id,
      Value<String?>? sport,
      Value<DateTime>? startUtc,
      Value<DateTime>? endUtc,
      Value<double?>? activeKcal,
      Value<double?>? avgHr,
      Value<double?>? maxHr,
      Value<int?>? steps,
      Value<String>? source,
      Value<int>? priority,
      Value<String?>? externalId,
      Value<DateTime?>? syncedAt,
      Value<int>? rowid}) {
    return ActivitySessionsCompanion(
      id: id ?? this.id,
      sport: sport ?? this.sport,
      startUtc: startUtc ?? this.startUtc,
      endUtc: endUtc ?? this.endUtc,
      activeKcal: activeKcal ?? this.activeKcal,
      avgHr: avgHr ?? this.avgHr,
      maxHr: maxHr ?? this.maxHr,
      steps: steps ?? this.steps,
      source: source ?? this.source,
      priority: priority ?? this.priority,
      externalId: externalId ?? this.externalId,
      syncedAt: syncedAt ?? this.syncedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (sport.present) {
      map['sport'] = Variable<String>(sport.value);
    }
    if (startUtc.present) {
      map['start_utc'] = Variable<DateTime>(startUtc.value);
    }
    if (endUtc.present) {
      map['end_utc'] = Variable<DateTime>(endUtc.value);
    }
    if (activeKcal.present) {
      map['active_kcal'] = Variable<double>(activeKcal.value);
    }
    if (avgHr.present) {
      map['avg_hr'] = Variable<double>(avgHr.value);
    }
    if (maxHr.present) {
      map['max_hr'] = Variable<double>(maxHr.value);
    }
    if (steps.present) {
      map['steps'] = Variable<int>(steps.value);
    }
    if (source.present) {
      map['source'] = Variable<String>(source.value);
    }
    if (priority.present) {
      map['priority'] = Variable<int>(priority.value);
    }
    if (externalId.present) {
      map['external_id'] = Variable<String>(externalId.value);
    }
    if (syncedAt.present) {
      map['synced_at'] = Variable<DateTime>(syncedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ActivitySessionsCompanion(')
          ..write('id: $id, ')
          ..write('sport: $sport, ')
          ..write('startUtc: $startUtc, ')
          ..write('endUtc: $endUtc, ')
          ..write('activeKcal: $activeKcal, ')
          ..write('avgHr: $avgHr, ')
          ..write('maxHr: $maxHr, ')
          ..write('steps: $steps, ')
          ..write('source: $source, ')
          ..write('priority: $priority, ')
          ..write('externalId: $externalId, ')
          ..write('syncedAt: $syncedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $StrengthWorkoutsTable extends StrengthWorkouts
    with TableInfo<$StrengthWorkoutsTable, StrengthWorkoutRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $StrengthWorkoutsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _startedAtMeta =
      const VerificationMeta('startedAt');
  @override
  late final GeneratedColumn<DateTime> startedAt = GeneratedColumn<DateTime>(
      'started_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _endedAtMeta =
      const VerificationMeta('endedAt');
  @override
  late final GeneratedColumn<DateTime> endedAt = GeneratedColumn<DateTime>(
      'ended_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _bodyWeightKgAtTimeMeta =
      const VerificationMeta('bodyWeightKgAtTime');
  @override
  late final GeneratedColumn<double> bodyWeightKgAtTime =
      GeneratedColumn<double>('body_weight_kg_at_time', aliasedName, false,
          type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _exercisesJsonMeta =
      const VerificationMeta('exercisesJson');
  @override
  late final GeneratedColumn<String> exercisesJson = GeneratedColumn<String>(
      'exercises_json', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _fallbackKcalMeta =
      const VerificationMeta('fallbackKcal');
  @override
  late final GeneratedColumn<double> fallbackKcal = GeneratedColumn<double>(
      'fallback_kcal', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _finalKcalMeta =
      const VerificationMeta('finalKcal');
  @override
  late final GeneratedColumn<double> finalKcal = GeneratedColumn<double>(
      'final_kcal', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _methodMeta = const VerificationMeta('method');
  @override
  late final GeneratedColumn<String> method = GeneratedColumn<String>(
      'method', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('fallback'));
  static const VerificationMeta _syncedAtMeta =
      const VerificationMeta('syncedAt');
  @override
  late final GeneratedColumn<DateTime> syncedAt = GeneratedColumn<DateTime>(
      'synced_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        startedAt,
        endedAt,
        bodyWeightKgAtTime,
        exercisesJson,
        fallbackKcal,
        finalKcal,
        method,
        syncedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'strength_workouts';
  @override
  VerificationContext validateIntegrity(Insertable<StrengthWorkoutRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('started_at')) {
      context.handle(_startedAtMeta,
          startedAt.isAcceptableOrUnknown(data['started_at']!, _startedAtMeta));
    } else if (isInserting) {
      context.missing(_startedAtMeta);
    }
    if (data.containsKey('ended_at')) {
      context.handle(_endedAtMeta,
          endedAt.isAcceptableOrUnknown(data['ended_at']!, _endedAtMeta));
    } else if (isInserting) {
      context.missing(_endedAtMeta);
    }
    if (data.containsKey('body_weight_kg_at_time')) {
      context.handle(
          _bodyWeightKgAtTimeMeta,
          bodyWeightKgAtTime.isAcceptableOrUnknown(
              data['body_weight_kg_at_time']!, _bodyWeightKgAtTimeMeta));
    } else if (isInserting) {
      context.missing(_bodyWeightKgAtTimeMeta);
    }
    if (data.containsKey('exercises_json')) {
      context.handle(
          _exercisesJsonMeta,
          exercisesJson.isAcceptableOrUnknown(
              data['exercises_json']!, _exercisesJsonMeta));
    } else if (isInserting) {
      context.missing(_exercisesJsonMeta);
    }
    if (data.containsKey('fallback_kcal')) {
      context.handle(
          _fallbackKcalMeta,
          fallbackKcal.isAcceptableOrUnknown(
              data['fallback_kcal']!, _fallbackKcalMeta));
    } else if (isInserting) {
      context.missing(_fallbackKcalMeta);
    }
    if (data.containsKey('final_kcal')) {
      context.handle(_finalKcalMeta,
          finalKcal.isAcceptableOrUnknown(data['final_kcal']!, _finalKcalMeta));
    } else if (isInserting) {
      context.missing(_finalKcalMeta);
    }
    if (data.containsKey('method')) {
      context.handle(_methodMeta,
          method.isAcceptableOrUnknown(data['method']!, _methodMeta));
    }
    if (data.containsKey('synced_at')) {
      context.handle(_syncedAtMeta,
          syncedAt.isAcceptableOrUnknown(data['synced_at']!, _syncedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  StrengthWorkoutRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return StrengthWorkoutRow(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      startedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}started_at'])!,
      endedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}ended_at'])!,
      bodyWeightKgAtTime: attachedDatabase.typeMapping.read(DriftSqlType.double,
          data['${effectivePrefix}body_weight_kg_at_time'])!,
      exercisesJson: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}exercises_json'])!,
      fallbackKcal: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}fallback_kcal'])!,
      finalKcal: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}final_kcal'])!,
      method: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}method'])!,
      syncedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}synced_at']),
    );
  }

  @override
  $StrengthWorkoutsTable createAlias(String alias) {
    return $StrengthWorkoutsTable(attachedDatabase, alias);
  }
}

class StrengthWorkoutRow extends DataClass
    implements Insertable<StrengthWorkoutRow> {
  final String id;
  final DateTime startedAt;
  final DateTime endedAt;
  final double bodyWeightKgAtTime;
  final String exercisesJson;
  final double fallbackKcal;
  final double finalKcal;
  final String method;
  final DateTime? syncedAt;
  const StrengthWorkoutRow(
      {required this.id,
      required this.startedAt,
      required this.endedAt,
      required this.bodyWeightKgAtTime,
      required this.exercisesJson,
      required this.fallbackKcal,
      required this.finalKcal,
      required this.method,
      this.syncedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['started_at'] = Variable<DateTime>(startedAt);
    map['ended_at'] = Variable<DateTime>(endedAt);
    map['body_weight_kg_at_time'] = Variable<double>(bodyWeightKgAtTime);
    map['exercises_json'] = Variable<String>(exercisesJson);
    map['fallback_kcal'] = Variable<double>(fallbackKcal);
    map['final_kcal'] = Variable<double>(finalKcal);
    map['method'] = Variable<String>(method);
    if (!nullToAbsent || syncedAt != null) {
      map['synced_at'] = Variable<DateTime>(syncedAt);
    }
    return map;
  }

  StrengthWorkoutsCompanion toCompanion(bool nullToAbsent) {
    return StrengthWorkoutsCompanion(
      id: Value(id),
      startedAt: Value(startedAt),
      endedAt: Value(endedAt),
      bodyWeightKgAtTime: Value(bodyWeightKgAtTime),
      exercisesJson: Value(exercisesJson),
      fallbackKcal: Value(fallbackKcal),
      finalKcal: Value(finalKcal),
      method: Value(method),
      syncedAt: syncedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(syncedAt),
    );
  }

  factory StrengthWorkoutRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return StrengthWorkoutRow(
      id: serializer.fromJson<String>(json['id']),
      startedAt: serializer.fromJson<DateTime>(json['startedAt']),
      endedAt: serializer.fromJson<DateTime>(json['endedAt']),
      bodyWeightKgAtTime:
          serializer.fromJson<double>(json['bodyWeightKgAtTime']),
      exercisesJson: serializer.fromJson<String>(json['exercisesJson']),
      fallbackKcal: serializer.fromJson<double>(json['fallbackKcal']),
      finalKcal: serializer.fromJson<double>(json['finalKcal']),
      method: serializer.fromJson<String>(json['method']),
      syncedAt: serializer.fromJson<DateTime?>(json['syncedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'startedAt': serializer.toJson<DateTime>(startedAt),
      'endedAt': serializer.toJson<DateTime>(endedAt),
      'bodyWeightKgAtTime': serializer.toJson<double>(bodyWeightKgAtTime),
      'exercisesJson': serializer.toJson<String>(exercisesJson),
      'fallbackKcal': serializer.toJson<double>(fallbackKcal),
      'finalKcal': serializer.toJson<double>(finalKcal),
      'method': serializer.toJson<String>(method),
      'syncedAt': serializer.toJson<DateTime?>(syncedAt),
    };
  }

  StrengthWorkoutRow copyWith(
          {String? id,
          DateTime? startedAt,
          DateTime? endedAt,
          double? bodyWeightKgAtTime,
          String? exercisesJson,
          double? fallbackKcal,
          double? finalKcal,
          String? method,
          Value<DateTime?> syncedAt = const Value.absent()}) =>
      StrengthWorkoutRow(
        id: id ?? this.id,
        startedAt: startedAt ?? this.startedAt,
        endedAt: endedAt ?? this.endedAt,
        bodyWeightKgAtTime: bodyWeightKgAtTime ?? this.bodyWeightKgAtTime,
        exercisesJson: exercisesJson ?? this.exercisesJson,
        fallbackKcal: fallbackKcal ?? this.fallbackKcal,
        finalKcal: finalKcal ?? this.finalKcal,
        method: method ?? this.method,
        syncedAt: syncedAt.present ? syncedAt.value : this.syncedAt,
      );
  StrengthWorkoutRow copyWithCompanion(StrengthWorkoutsCompanion data) {
    return StrengthWorkoutRow(
      id: data.id.present ? data.id.value : this.id,
      startedAt: data.startedAt.present ? data.startedAt.value : this.startedAt,
      endedAt: data.endedAt.present ? data.endedAt.value : this.endedAt,
      bodyWeightKgAtTime: data.bodyWeightKgAtTime.present
          ? data.bodyWeightKgAtTime.value
          : this.bodyWeightKgAtTime,
      exercisesJson: data.exercisesJson.present
          ? data.exercisesJson.value
          : this.exercisesJson,
      fallbackKcal: data.fallbackKcal.present
          ? data.fallbackKcal.value
          : this.fallbackKcal,
      finalKcal: data.finalKcal.present ? data.finalKcal.value : this.finalKcal,
      method: data.method.present ? data.method.value : this.method,
      syncedAt: data.syncedAt.present ? data.syncedAt.value : this.syncedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('StrengthWorkoutRow(')
          ..write('id: $id, ')
          ..write('startedAt: $startedAt, ')
          ..write('endedAt: $endedAt, ')
          ..write('bodyWeightKgAtTime: $bodyWeightKgAtTime, ')
          ..write('exercisesJson: $exercisesJson, ')
          ..write('fallbackKcal: $fallbackKcal, ')
          ..write('finalKcal: $finalKcal, ')
          ..write('method: $method, ')
          ..write('syncedAt: $syncedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, startedAt, endedAt, bodyWeightKgAtTime,
      exercisesJson, fallbackKcal, finalKcal, method, syncedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is StrengthWorkoutRow &&
          other.id == this.id &&
          other.startedAt == this.startedAt &&
          other.endedAt == this.endedAt &&
          other.bodyWeightKgAtTime == this.bodyWeightKgAtTime &&
          other.exercisesJson == this.exercisesJson &&
          other.fallbackKcal == this.fallbackKcal &&
          other.finalKcal == this.finalKcal &&
          other.method == this.method &&
          other.syncedAt == this.syncedAt);
}

class StrengthWorkoutsCompanion extends UpdateCompanion<StrengthWorkoutRow> {
  final Value<String> id;
  final Value<DateTime> startedAt;
  final Value<DateTime> endedAt;
  final Value<double> bodyWeightKgAtTime;
  final Value<String> exercisesJson;
  final Value<double> fallbackKcal;
  final Value<double> finalKcal;
  final Value<String> method;
  final Value<DateTime?> syncedAt;
  final Value<int> rowid;
  const StrengthWorkoutsCompanion({
    this.id = const Value.absent(),
    this.startedAt = const Value.absent(),
    this.endedAt = const Value.absent(),
    this.bodyWeightKgAtTime = const Value.absent(),
    this.exercisesJson = const Value.absent(),
    this.fallbackKcal = const Value.absent(),
    this.finalKcal = const Value.absent(),
    this.method = const Value.absent(),
    this.syncedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  StrengthWorkoutsCompanion.insert({
    required String id,
    required DateTime startedAt,
    required DateTime endedAt,
    required double bodyWeightKgAtTime,
    required String exercisesJson,
    required double fallbackKcal,
    required double finalKcal,
    this.method = const Value.absent(),
    this.syncedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        startedAt = Value(startedAt),
        endedAt = Value(endedAt),
        bodyWeightKgAtTime = Value(bodyWeightKgAtTime),
        exercisesJson = Value(exercisesJson),
        fallbackKcal = Value(fallbackKcal),
        finalKcal = Value(finalKcal);
  static Insertable<StrengthWorkoutRow> custom({
    Expression<String>? id,
    Expression<DateTime>? startedAt,
    Expression<DateTime>? endedAt,
    Expression<double>? bodyWeightKgAtTime,
    Expression<String>? exercisesJson,
    Expression<double>? fallbackKcal,
    Expression<double>? finalKcal,
    Expression<String>? method,
    Expression<DateTime>? syncedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (startedAt != null) 'started_at': startedAt,
      if (endedAt != null) 'ended_at': endedAt,
      if (bodyWeightKgAtTime != null)
        'body_weight_kg_at_time': bodyWeightKgAtTime,
      if (exercisesJson != null) 'exercises_json': exercisesJson,
      if (fallbackKcal != null) 'fallback_kcal': fallbackKcal,
      if (finalKcal != null) 'final_kcal': finalKcal,
      if (method != null) 'method': method,
      if (syncedAt != null) 'synced_at': syncedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  StrengthWorkoutsCompanion copyWith(
      {Value<String>? id,
      Value<DateTime>? startedAt,
      Value<DateTime>? endedAt,
      Value<double>? bodyWeightKgAtTime,
      Value<String>? exercisesJson,
      Value<double>? fallbackKcal,
      Value<double>? finalKcal,
      Value<String>? method,
      Value<DateTime?>? syncedAt,
      Value<int>? rowid}) {
    return StrengthWorkoutsCompanion(
      id: id ?? this.id,
      startedAt: startedAt ?? this.startedAt,
      endedAt: endedAt ?? this.endedAt,
      bodyWeightKgAtTime: bodyWeightKgAtTime ?? this.bodyWeightKgAtTime,
      exercisesJson: exercisesJson ?? this.exercisesJson,
      fallbackKcal: fallbackKcal ?? this.fallbackKcal,
      finalKcal: finalKcal ?? this.finalKcal,
      method: method ?? this.method,
      syncedAt: syncedAt ?? this.syncedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (startedAt.present) {
      map['started_at'] = Variable<DateTime>(startedAt.value);
    }
    if (endedAt.present) {
      map['ended_at'] = Variable<DateTime>(endedAt.value);
    }
    if (bodyWeightKgAtTime.present) {
      map['body_weight_kg_at_time'] =
          Variable<double>(bodyWeightKgAtTime.value);
    }
    if (exercisesJson.present) {
      map['exercises_json'] = Variable<String>(exercisesJson.value);
    }
    if (fallbackKcal.present) {
      map['fallback_kcal'] = Variable<double>(fallbackKcal.value);
    }
    if (finalKcal.present) {
      map['final_kcal'] = Variable<double>(finalKcal.value);
    }
    if (method.present) {
      map['method'] = Variable<String>(method.value);
    }
    if (syncedAt.present) {
      map['synced_at'] = Variable<DateTime>(syncedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('StrengthWorkoutsCompanion(')
          ..write('id: $id, ')
          ..write('startedAt: $startedAt, ')
          ..write('endedAt: $endedAt, ')
          ..write('bodyWeightKgAtTime: $bodyWeightKgAtTime, ')
          ..write('exercisesJson: $exercisesJson, ')
          ..write('fallbackKcal: $fallbackKcal, ')
          ..write('finalKcal: $finalKcal, ')
          ..write('method: $method, ')
          ..write('syncedAt: $syncedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $WeightEntriesTable extends WeightEntries
    with TableInfo<$WeightEntriesTable, WeightEntryRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $WeightEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _recordedAtMeta =
      const VerificationMeta('recordedAt');
  @override
  late final GeneratedColumn<DateTime> recordedAt = GeneratedColumn<DateTime>(
      'recorded_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _kgMeta = const VerificationMeta('kg');
  @override
  late final GeneratedColumn<double> kg = GeneratedColumn<double>(
      'kg', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _sourceMeta = const VerificationMeta('source');
  @override
  late final GeneratedColumn<String> source = GeneratedColumn<String>(
      'source', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('manual'));
  static const VerificationMeta _syncedAtMeta =
      const VerificationMeta('syncedAt');
  @override
  late final GeneratedColumn<DateTime> syncedAt = GeneratedColumn<DateTime>(
      'synced_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [id, recordedAt, kg, source, syncedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'weight_entries';
  @override
  VerificationContext validateIntegrity(Insertable<WeightEntryRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('recorded_at')) {
      context.handle(
          _recordedAtMeta,
          recordedAt.isAcceptableOrUnknown(
              data['recorded_at']!, _recordedAtMeta));
    } else if (isInserting) {
      context.missing(_recordedAtMeta);
    }
    if (data.containsKey('kg')) {
      context.handle(_kgMeta, kg.isAcceptableOrUnknown(data['kg']!, _kgMeta));
    } else if (isInserting) {
      context.missing(_kgMeta);
    }
    if (data.containsKey('source')) {
      context.handle(_sourceMeta,
          source.isAcceptableOrUnknown(data['source']!, _sourceMeta));
    }
    if (data.containsKey('synced_at')) {
      context.handle(_syncedAtMeta,
          syncedAt.isAcceptableOrUnknown(data['synced_at']!, _syncedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  WeightEntryRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return WeightEntryRow(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      recordedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}recorded_at'])!,
      kg: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}kg'])!,
      source: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}source'])!,
      syncedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}synced_at']),
    );
  }

  @override
  $WeightEntriesTable createAlias(String alias) {
    return $WeightEntriesTable(attachedDatabase, alias);
  }
}

class WeightEntryRow extends DataClass implements Insertable<WeightEntryRow> {
  final int id;
  final DateTime recordedAt;
  final double kg;
  final String source;
  final DateTime? syncedAt;
  const WeightEntryRow(
      {required this.id,
      required this.recordedAt,
      required this.kg,
      required this.source,
      this.syncedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['recorded_at'] = Variable<DateTime>(recordedAt);
    map['kg'] = Variable<double>(kg);
    map['source'] = Variable<String>(source);
    if (!nullToAbsent || syncedAt != null) {
      map['synced_at'] = Variable<DateTime>(syncedAt);
    }
    return map;
  }

  WeightEntriesCompanion toCompanion(bool nullToAbsent) {
    return WeightEntriesCompanion(
      id: Value(id),
      recordedAt: Value(recordedAt),
      kg: Value(kg),
      source: Value(source),
      syncedAt: syncedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(syncedAt),
    );
  }

  factory WeightEntryRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return WeightEntryRow(
      id: serializer.fromJson<int>(json['id']),
      recordedAt: serializer.fromJson<DateTime>(json['recordedAt']),
      kg: serializer.fromJson<double>(json['kg']),
      source: serializer.fromJson<String>(json['source']),
      syncedAt: serializer.fromJson<DateTime?>(json['syncedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'recordedAt': serializer.toJson<DateTime>(recordedAt),
      'kg': serializer.toJson<double>(kg),
      'source': serializer.toJson<String>(source),
      'syncedAt': serializer.toJson<DateTime?>(syncedAt),
    };
  }

  WeightEntryRow copyWith(
          {int? id,
          DateTime? recordedAt,
          double? kg,
          String? source,
          Value<DateTime?> syncedAt = const Value.absent()}) =>
      WeightEntryRow(
        id: id ?? this.id,
        recordedAt: recordedAt ?? this.recordedAt,
        kg: kg ?? this.kg,
        source: source ?? this.source,
        syncedAt: syncedAt.present ? syncedAt.value : this.syncedAt,
      );
  WeightEntryRow copyWithCompanion(WeightEntriesCompanion data) {
    return WeightEntryRow(
      id: data.id.present ? data.id.value : this.id,
      recordedAt:
          data.recordedAt.present ? data.recordedAt.value : this.recordedAt,
      kg: data.kg.present ? data.kg.value : this.kg,
      source: data.source.present ? data.source.value : this.source,
      syncedAt: data.syncedAt.present ? data.syncedAt.value : this.syncedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('WeightEntryRow(')
          ..write('id: $id, ')
          ..write('recordedAt: $recordedAt, ')
          ..write('kg: $kg, ')
          ..write('source: $source, ')
          ..write('syncedAt: $syncedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, recordedAt, kg, source, syncedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is WeightEntryRow &&
          other.id == this.id &&
          other.recordedAt == this.recordedAt &&
          other.kg == this.kg &&
          other.source == this.source &&
          other.syncedAt == this.syncedAt);
}

class WeightEntriesCompanion extends UpdateCompanion<WeightEntryRow> {
  final Value<int> id;
  final Value<DateTime> recordedAt;
  final Value<double> kg;
  final Value<String> source;
  final Value<DateTime?> syncedAt;
  const WeightEntriesCompanion({
    this.id = const Value.absent(),
    this.recordedAt = const Value.absent(),
    this.kg = const Value.absent(),
    this.source = const Value.absent(),
    this.syncedAt = const Value.absent(),
  });
  WeightEntriesCompanion.insert({
    this.id = const Value.absent(),
    required DateTime recordedAt,
    required double kg,
    this.source = const Value.absent(),
    this.syncedAt = const Value.absent(),
  })  : recordedAt = Value(recordedAt),
        kg = Value(kg);
  static Insertable<WeightEntryRow> custom({
    Expression<int>? id,
    Expression<DateTime>? recordedAt,
    Expression<double>? kg,
    Expression<String>? source,
    Expression<DateTime>? syncedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (recordedAt != null) 'recorded_at': recordedAt,
      if (kg != null) 'kg': kg,
      if (source != null) 'source': source,
      if (syncedAt != null) 'synced_at': syncedAt,
    });
  }

  WeightEntriesCompanion copyWith(
      {Value<int>? id,
      Value<DateTime>? recordedAt,
      Value<double>? kg,
      Value<String>? source,
      Value<DateTime?>? syncedAt}) {
    return WeightEntriesCompanion(
      id: id ?? this.id,
      recordedAt: recordedAt ?? this.recordedAt,
      kg: kg ?? this.kg,
      source: source ?? this.source,
      syncedAt: syncedAt ?? this.syncedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (recordedAt.present) {
      map['recorded_at'] = Variable<DateTime>(recordedAt.value);
    }
    if (kg.present) {
      map['kg'] = Variable<double>(kg.value);
    }
    if (source.present) {
      map['source'] = Variable<String>(source.value);
    }
    if (syncedAt.present) {
      map['synced_at'] = Variable<DateTime>(syncedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('WeightEntriesCompanion(')
          ..write('id: $id, ')
          ..write('recordedAt: $recordedAt, ')
          ..write('kg: $kg, ')
          ..write('source: $source, ')
          ..write('syncedAt: $syncedAt')
          ..write(')'))
        .toString();
  }
}

class $NutritionEntriesTable extends NutritionEntries
    with TableInfo<$NutritionEntriesTable, NutritionEntryRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $NutritionEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _recordedAtMeta =
      const VerificationMeta('recordedAt');
  @override
  late final GeneratedColumn<DateTime> recordedAt = GeneratedColumn<DateTime>(
      'recorded_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _kcalMeta = const VerificationMeta('kcal');
  @override
  late final GeneratedColumn<double> kcal = GeneratedColumn<double>(
      'kcal', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _proteinGMeta =
      const VerificationMeta('proteinG');
  @override
  late final GeneratedColumn<double> proteinG = GeneratedColumn<double>(
      'protein_g', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _carbsGMeta = const VerificationMeta('carbsG');
  @override
  late final GeneratedColumn<double> carbsG = GeneratedColumn<double>(
      'carbs_g', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _fatGMeta = const VerificationMeta('fatG');
  @override
  late final GeneratedColumn<double> fatG = GeneratedColumn<double>(
      'fat_g', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _mealMeta = const VerificationMeta('meal');
  @override
  late final GeneratedColumn<String> meal = GeneratedColumn<String>(
      'meal', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _sourceMeta = const VerificationMeta('source');
  @override
  late final GeneratedColumn<String> source = GeneratedColumn<String>(
      'source', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('eter'));
  static const VerificationMeta _metadataJsonMeta =
      const VerificationMeta('metadataJson');
  @override
  late final GeneratedColumn<String> metadataJson = GeneratedColumn<String>(
      'metadata_json', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('{}'));
  static const VerificationMeta _confirmedMeta =
      const VerificationMeta('confirmed');
  @override
  late final GeneratedColumn<bool> confirmed = GeneratedColumn<bool>(
      'confirmed', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("confirmed" IN (0, 1))'),
      defaultValue: const Constant(true));
  static const VerificationMeta _syncedAtMeta =
      const VerificationMeta('syncedAt');
  @override
  late final GeneratedColumn<DateTime> syncedAt = GeneratedColumn<DateTime>(
      'synced_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        recordedAt,
        kcal,
        proteinG,
        carbsG,
        fatG,
        meal,
        source,
        metadataJson,
        confirmed,
        syncedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'nutrition_entries';
  @override
  VerificationContext validateIntegrity(Insertable<NutritionEntryRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('recorded_at')) {
      context.handle(
          _recordedAtMeta,
          recordedAt.isAcceptableOrUnknown(
              data['recorded_at']!, _recordedAtMeta));
    } else if (isInserting) {
      context.missing(_recordedAtMeta);
    }
    if (data.containsKey('kcal')) {
      context.handle(
          _kcalMeta, kcal.isAcceptableOrUnknown(data['kcal']!, _kcalMeta));
    } else if (isInserting) {
      context.missing(_kcalMeta);
    }
    if (data.containsKey('protein_g')) {
      context.handle(_proteinGMeta,
          proteinG.isAcceptableOrUnknown(data['protein_g']!, _proteinGMeta));
    }
    if (data.containsKey('carbs_g')) {
      context.handle(_carbsGMeta,
          carbsG.isAcceptableOrUnknown(data['carbs_g']!, _carbsGMeta));
    }
    if (data.containsKey('fat_g')) {
      context.handle(
          _fatGMeta, fatG.isAcceptableOrUnknown(data['fat_g']!, _fatGMeta));
    }
    if (data.containsKey('meal')) {
      context.handle(
          _mealMeta, meal.isAcceptableOrUnknown(data['meal']!, _mealMeta));
    } else if (isInserting) {
      context.missing(_mealMeta);
    }
    if (data.containsKey('source')) {
      context.handle(_sourceMeta,
          source.isAcceptableOrUnknown(data['source']!, _sourceMeta));
    }
    if (data.containsKey('metadata_json')) {
      context.handle(
          _metadataJsonMeta,
          metadataJson.isAcceptableOrUnknown(
              data['metadata_json']!, _metadataJsonMeta));
    }
    if (data.containsKey('confirmed')) {
      context.handle(_confirmedMeta,
          confirmed.isAcceptableOrUnknown(data['confirmed']!, _confirmedMeta));
    }
    if (data.containsKey('synced_at')) {
      context.handle(_syncedAtMeta,
          syncedAt.isAcceptableOrUnknown(data['synced_at']!, _syncedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  NutritionEntryRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return NutritionEntryRow(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      recordedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}recorded_at'])!,
      kcal: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}kcal'])!,
      proteinG: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}protein_g']),
      carbsG: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}carbs_g']),
      fatG: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}fat_g']),
      meal: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}meal'])!,
      source: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}source'])!,
      metadataJson: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}metadata_json'])!,
      confirmed: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}confirmed'])!,
      syncedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}synced_at']),
    );
  }

  @override
  $NutritionEntriesTable createAlias(String alias) {
    return $NutritionEntriesTable(attachedDatabase, alias);
  }
}

class NutritionEntryRow extends DataClass
    implements Insertable<NutritionEntryRow> {
  final int id;
  final DateTime recordedAt;
  final double kcal;
  final double? proteinG;
  final double? carbsG;
  final double? fatG;
  final String meal;
  final String source;

  /// Carries `journalEntryId` when this row was derived from a journal entry,
  /// which is what makes per-item correction and undo possible.
  final String metadataJson;

  /// An estimate the user has not yet confirmed. The brief is explicit that AI
  /// food estimates "remain editable and require confirmation before being
  /// saved" -- unconfirmed rows must not count toward any total.
  final bool confirmed;
  final DateTime? syncedAt;
  const NutritionEntryRow(
      {required this.id,
      required this.recordedAt,
      required this.kcal,
      this.proteinG,
      this.carbsG,
      this.fatG,
      required this.meal,
      required this.source,
      required this.metadataJson,
      required this.confirmed,
      this.syncedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['recorded_at'] = Variable<DateTime>(recordedAt);
    map['kcal'] = Variable<double>(kcal);
    if (!nullToAbsent || proteinG != null) {
      map['protein_g'] = Variable<double>(proteinG);
    }
    if (!nullToAbsent || carbsG != null) {
      map['carbs_g'] = Variable<double>(carbsG);
    }
    if (!nullToAbsent || fatG != null) {
      map['fat_g'] = Variable<double>(fatG);
    }
    map['meal'] = Variable<String>(meal);
    map['source'] = Variable<String>(source);
    map['metadata_json'] = Variable<String>(metadataJson);
    map['confirmed'] = Variable<bool>(confirmed);
    if (!nullToAbsent || syncedAt != null) {
      map['synced_at'] = Variable<DateTime>(syncedAt);
    }
    return map;
  }

  NutritionEntriesCompanion toCompanion(bool nullToAbsent) {
    return NutritionEntriesCompanion(
      id: Value(id),
      recordedAt: Value(recordedAt),
      kcal: Value(kcal),
      proteinG: proteinG == null && nullToAbsent
          ? const Value.absent()
          : Value(proteinG),
      carbsG:
          carbsG == null && nullToAbsent ? const Value.absent() : Value(carbsG),
      fatG: fatG == null && nullToAbsent ? const Value.absent() : Value(fatG),
      meal: Value(meal),
      source: Value(source),
      metadataJson: Value(metadataJson),
      confirmed: Value(confirmed),
      syncedAt: syncedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(syncedAt),
    );
  }

  factory NutritionEntryRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return NutritionEntryRow(
      id: serializer.fromJson<int>(json['id']),
      recordedAt: serializer.fromJson<DateTime>(json['recordedAt']),
      kcal: serializer.fromJson<double>(json['kcal']),
      proteinG: serializer.fromJson<double?>(json['proteinG']),
      carbsG: serializer.fromJson<double?>(json['carbsG']),
      fatG: serializer.fromJson<double?>(json['fatG']),
      meal: serializer.fromJson<String>(json['meal']),
      source: serializer.fromJson<String>(json['source']),
      metadataJson: serializer.fromJson<String>(json['metadataJson']),
      confirmed: serializer.fromJson<bool>(json['confirmed']),
      syncedAt: serializer.fromJson<DateTime?>(json['syncedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'recordedAt': serializer.toJson<DateTime>(recordedAt),
      'kcal': serializer.toJson<double>(kcal),
      'proteinG': serializer.toJson<double?>(proteinG),
      'carbsG': serializer.toJson<double?>(carbsG),
      'fatG': serializer.toJson<double?>(fatG),
      'meal': serializer.toJson<String>(meal),
      'source': serializer.toJson<String>(source),
      'metadataJson': serializer.toJson<String>(metadataJson),
      'confirmed': serializer.toJson<bool>(confirmed),
      'syncedAt': serializer.toJson<DateTime?>(syncedAt),
    };
  }

  NutritionEntryRow copyWith(
          {int? id,
          DateTime? recordedAt,
          double? kcal,
          Value<double?> proteinG = const Value.absent(),
          Value<double?> carbsG = const Value.absent(),
          Value<double?> fatG = const Value.absent(),
          String? meal,
          String? source,
          String? metadataJson,
          bool? confirmed,
          Value<DateTime?> syncedAt = const Value.absent()}) =>
      NutritionEntryRow(
        id: id ?? this.id,
        recordedAt: recordedAt ?? this.recordedAt,
        kcal: kcal ?? this.kcal,
        proteinG: proteinG.present ? proteinG.value : this.proteinG,
        carbsG: carbsG.present ? carbsG.value : this.carbsG,
        fatG: fatG.present ? fatG.value : this.fatG,
        meal: meal ?? this.meal,
        source: source ?? this.source,
        metadataJson: metadataJson ?? this.metadataJson,
        confirmed: confirmed ?? this.confirmed,
        syncedAt: syncedAt.present ? syncedAt.value : this.syncedAt,
      );
  NutritionEntryRow copyWithCompanion(NutritionEntriesCompanion data) {
    return NutritionEntryRow(
      id: data.id.present ? data.id.value : this.id,
      recordedAt:
          data.recordedAt.present ? data.recordedAt.value : this.recordedAt,
      kcal: data.kcal.present ? data.kcal.value : this.kcal,
      proteinG: data.proteinG.present ? data.proteinG.value : this.proteinG,
      carbsG: data.carbsG.present ? data.carbsG.value : this.carbsG,
      fatG: data.fatG.present ? data.fatG.value : this.fatG,
      meal: data.meal.present ? data.meal.value : this.meal,
      source: data.source.present ? data.source.value : this.source,
      metadataJson: data.metadataJson.present
          ? data.metadataJson.value
          : this.metadataJson,
      confirmed: data.confirmed.present ? data.confirmed.value : this.confirmed,
      syncedAt: data.syncedAt.present ? data.syncedAt.value : this.syncedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('NutritionEntryRow(')
          ..write('id: $id, ')
          ..write('recordedAt: $recordedAt, ')
          ..write('kcal: $kcal, ')
          ..write('proteinG: $proteinG, ')
          ..write('carbsG: $carbsG, ')
          ..write('fatG: $fatG, ')
          ..write('meal: $meal, ')
          ..write('source: $source, ')
          ..write('metadataJson: $metadataJson, ')
          ..write('confirmed: $confirmed, ')
          ..write('syncedAt: $syncedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, recordedAt, kcal, proteinG, carbsG, fatG,
      meal, source, metadataJson, confirmed, syncedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is NutritionEntryRow &&
          other.id == this.id &&
          other.recordedAt == this.recordedAt &&
          other.kcal == this.kcal &&
          other.proteinG == this.proteinG &&
          other.carbsG == this.carbsG &&
          other.fatG == this.fatG &&
          other.meal == this.meal &&
          other.source == this.source &&
          other.metadataJson == this.metadataJson &&
          other.confirmed == this.confirmed &&
          other.syncedAt == this.syncedAt);
}

class NutritionEntriesCompanion extends UpdateCompanion<NutritionEntryRow> {
  final Value<int> id;
  final Value<DateTime> recordedAt;
  final Value<double> kcal;
  final Value<double?> proteinG;
  final Value<double?> carbsG;
  final Value<double?> fatG;
  final Value<String> meal;
  final Value<String> source;
  final Value<String> metadataJson;
  final Value<bool> confirmed;
  final Value<DateTime?> syncedAt;
  const NutritionEntriesCompanion({
    this.id = const Value.absent(),
    this.recordedAt = const Value.absent(),
    this.kcal = const Value.absent(),
    this.proteinG = const Value.absent(),
    this.carbsG = const Value.absent(),
    this.fatG = const Value.absent(),
    this.meal = const Value.absent(),
    this.source = const Value.absent(),
    this.metadataJson = const Value.absent(),
    this.confirmed = const Value.absent(),
    this.syncedAt = const Value.absent(),
  });
  NutritionEntriesCompanion.insert({
    this.id = const Value.absent(),
    required DateTime recordedAt,
    required double kcal,
    this.proteinG = const Value.absent(),
    this.carbsG = const Value.absent(),
    this.fatG = const Value.absent(),
    required String meal,
    this.source = const Value.absent(),
    this.metadataJson = const Value.absent(),
    this.confirmed = const Value.absent(),
    this.syncedAt = const Value.absent(),
  })  : recordedAt = Value(recordedAt),
        kcal = Value(kcal),
        meal = Value(meal);
  static Insertable<NutritionEntryRow> custom({
    Expression<int>? id,
    Expression<DateTime>? recordedAt,
    Expression<double>? kcal,
    Expression<double>? proteinG,
    Expression<double>? carbsG,
    Expression<double>? fatG,
    Expression<String>? meal,
    Expression<String>? source,
    Expression<String>? metadataJson,
    Expression<bool>? confirmed,
    Expression<DateTime>? syncedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (recordedAt != null) 'recorded_at': recordedAt,
      if (kcal != null) 'kcal': kcal,
      if (proteinG != null) 'protein_g': proteinG,
      if (carbsG != null) 'carbs_g': carbsG,
      if (fatG != null) 'fat_g': fatG,
      if (meal != null) 'meal': meal,
      if (source != null) 'source': source,
      if (metadataJson != null) 'metadata_json': metadataJson,
      if (confirmed != null) 'confirmed': confirmed,
      if (syncedAt != null) 'synced_at': syncedAt,
    });
  }

  NutritionEntriesCompanion copyWith(
      {Value<int>? id,
      Value<DateTime>? recordedAt,
      Value<double>? kcal,
      Value<double?>? proteinG,
      Value<double?>? carbsG,
      Value<double?>? fatG,
      Value<String>? meal,
      Value<String>? source,
      Value<String>? metadataJson,
      Value<bool>? confirmed,
      Value<DateTime?>? syncedAt}) {
    return NutritionEntriesCompanion(
      id: id ?? this.id,
      recordedAt: recordedAt ?? this.recordedAt,
      kcal: kcal ?? this.kcal,
      proteinG: proteinG ?? this.proteinG,
      carbsG: carbsG ?? this.carbsG,
      fatG: fatG ?? this.fatG,
      meal: meal ?? this.meal,
      source: source ?? this.source,
      metadataJson: metadataJson ?? this.metadataJson,
      confirmed: confirmed ?? this.confirmed,
      syncedAt: syncedAt ?? this.syncedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (recordedAt.present) {
      map['recorded_at'] = Variable<DateTime>(recordedAt.value);
    }
    if (kcal.present) {
      map['kcal'] = Variable<double>(kcal.value);
    }
    if (proteinG.present) {
      map['protein_g'] = Variable<double>(proteinG.value);
    }
    if (carbsG.present) {
      map['carbs_g'] = Variable<double>(carbsG.value);
    }
    if (fatG.present) {
      map['fat_g'] = Variable<double>(fatG.value);
    }
    if (meal.present) {
      map['meal'] = Variable<String>(meal.value);
    }
    if (source.present) {
      map['source'] = Variable<String>(source.value);
    }
    if (metadataJson.present) {
      map['metadata_json'] = Variable<String>(metadataJson.value);
    }
    if (confirmed.present) {
      map['confirmed'] = Variable<bool>(confirmed.value);
    }
    if (syncedAt.present) {
      map['synced_at'] = Variable<DateTime>(syncedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('NutritionEntriesCompanion(')
          ..write('id: $id, ')
          ..write('recordedAt: $recordedAt, ')
          ..write('kcal: $kcal, ')
          ..write('proteinG: $proteinG, ')
          ..write('carbsG: $carbsG, ')
          ..write('fatG: $fatG, ')
          ..write('meal: $meal, ')
          ..write('source: $source, ')
          ..write('metadataJson: $metadataJson, ')
          ..write('confirmed: $confirmed, ')
          ..write('syncedAt: $syncedAt')
          ..write(')'))
        .toString();
  }
}

class $LiveSessionsTable extends LiveSessions
    with TableInfo<$LiveSessionsTable, LiveSessionRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LiveSessionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _startedAtMeta =
      const VerificationMeta('startedAt');
  @override
  late final GeneratedColumn<DateTime> startedAt = GeneratedColumn<DateTime>(
      'started_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _endedAtMeta =
      const VerificationMeta('endedAt');
  @override
  late final GeneratedColumn<DateTime> endedAt = GeneratedColumn<DateTime>(
      'ended_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _sourceIdMeta =
      const VerificationMeta('sourceId');
  @override
  late final GeneratedColumn<String> sourceId = GeneratedColumn<String>(
      'source_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _hrSeriesJsonMeta =
      const VerificationMeta('hrSeriesJson');
  @override
  late final GeneratedColumn<String> hrSeriesJson = GeneratedColumn<String>(
      'hr_series_json', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _finalKcalMeta =
      const VerificationMeta('finalKcal');
  @override
  late final GeneratedColumn<double> finalKcal = GeneratedColumn<double>(
      'final_kcal', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _syncedAtMeta =
      const VerificationMeta('syncedAt');
  @override
  late final GeneratedColumn<DateTime> syncedAt = GeneratedColumn<DateTime>(
      'synced_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns =>
      [id, startedAt, endedAt, sourceId, hrSeriesJson, finalKcal, syncedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'live_sessions';
  @override
  VerificationContext validateIntegrity(Insertable<LiveSessionRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('started_at')) {
      context.handle(_startedAtMeta,
          startedAt.isAcceptableOrUnknown(data['started_at']!, _startedAtMeta));
    } else if (isInserting) {
      context.missing(_startedAtMeta);
    }
    if (data.containsKey('ended_at')) {
      context.handle(_endedAtMeta,
          endedAt.isAcceptableOrUnknown(data['ended_at']!, _endedAtMeta));
    } else if (isInserting) {
      context.missing(_endedAtMeta);
    }
    if (data.containsKey('source_id')) {
      context.handle(_sourceIdMeta,
          sourceId.isAcceptableOrUnknown(data['source_id']!, _sourceIdMeta));
    } else if (isInserting) {
      context.missing(_sourceIdMeta);
    }
    if (data.containsKey('hr_series_json')) {
      context.handle(
          _hrSeriesJsonMeta,
          hrSeriesJson.isAcceptableOrUnknown(
              data['hr_series_json']!, _hrSeriesJsonMeta));
    } else if (isInserting) {
      context.missing(_hrSeriesJsonMeta);
    }
    if (data.containsKey('final_kcal')) {
      context.handle(_finalKcalMeta,
          finalKcal.isAcceptableOrUnknown(data['final_kcal']!, _finalKcalMeta));
    } else if (isInserting) {
      context.missing(_finalKcalMeta);
    }
    if (data.containsKey('synced_at')) {
      context.handle(_syncedAtMeta,
          syncedAt.isAcceptableOrUnknown(data['synced_at']!, _syncedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LiveSessionRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LiveSessionRow(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      startedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}started_at'])!,
      endedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}ended_at'])!,
      sourceId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}source_id'])!,
      hrSeriesJson: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}hr_series_json'])!,
      finalKcal: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}final_kcal'])!,
      syncedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}synced_at']),
    );
  }

  @override
  $LiveSessionsTable createAlias(String alias) {
    return $LiveSessionsTable(attachedDatabase, alias);
  }
}

class LiveSessionRow extends DataClass implements Insertable<LiveSessionRow> {
  final String id;
  final DateTime startedAt;
  final DateTime endedAt;
  final String sourceId;
  final String hrSeriesJson;
  final double finalKcal;
  final DateTime? syncedAt;
  const LiveSessionRow(
      {required this.id,
      required this.startedAt,
      required this.endedAt,
      required this.sourceId,
      required this.hrSeriesJson,
      required this.finalKcal,
      this.syncedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['started_at'] = Variable<DateTime>(startedAt);
    map['ended_at'] = Variable<DateTime>(endedAt);
    map['source_id'] = Variable<String>(sourceId);
    map['hr_series_json'] = Variable<String>(hrSeriesJson);
    map['final_kcal'] = Variable<double>(finalKcal);
    if (!nullToAbsent || syncedAt != null) {
      map['synced_at'] = Variable<DateTime>(syncedAt);
    }
    return map;
  }

  LiveSessionsCompanion toCompanion(bool nullToAbsent) {
    return LiveSessionsCompanion(
      id: Value(id),
      startedAt: Value(startedAt),
      endedAt: Value(endedAt),
      sourceId: Value(sourceId),
      hrSeriesJson: Value(hrSeriesJson),
      finalKcal: Value(finalKcal),
      syncedAt: syncedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(syncedAt),
    );
  }

  factory LiveSessionRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LiveSessionRow(
      id: serializer.fromJson<String>(json['id']),
      startedAt: serializer.fromJson<DateTime>(json['startedAt']),
      endedAt: serializer.fromJson<DateTime>(json['endedAt']),
      sourceId: serializer.fromJson<String>(json['sourceId']),
      hrSeriesJson: serializer.fromJson<String>(json['hrSeriesJson']),
      finalKcal: serializer.fromJson<double>(json['finalKcal']),
      syncedAt: serializer.fromJson<DateTime?>(json['syncedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'startedAt': serializer.toJson<DateTime>(startedAt),
      'endedAt': serializer.toJson<DateTime>(endedAt),
      'sourceId': serializer.toJson<String>(sourceId),
      'hrSeriesJson': serializer.toJson<String>(hrSeriesJson),
      'finalKcal': serializer.toJson<double>(finalKcal),
      'syncedAt': serializer.toJson<DateTime?>(syncedAt),
    };
  }

  LiveSessionRow copyWith(
          {String? id,
          DateTime? startedAt,
          DateTime? endedAt,
          String? sourceId,
          String? hrSeriesJson,
          double? finalKcal,
          Value<DateTime?> syncedAt = const Value.absent()}) =>
      LiveSessionRow(
        id: id ?? this.id,
        startedAt: startedAt ?? this.startedAt,
        endedAt: endedAt ?? this.endedAt,
        sourceId: sourceId ?? this.sourceId,
        hrSeriesJson: hrSeriesJson ?? this.hrSeriesJson,
        finalKcal: finalKcal ?? this.finalKcal,
        syncedAt: syncedAt.present ? syncedAt.value : this.syncedAt,
      );
  LiveSessionRow copyWithCompanion(LiveSessionsCompanion data) {
    return LiveSessionRow(
      id: data.id.present ? data.id.value : this.id,
      startedAt: data.startedAt.present ? data.startedAt.value : this.startedAt,
      endedAt: data.endedAt.present ? data.endedAt.value : this.endedAt,
      sourceId: data.sourceId.present ? data.sourceId.value : this.sourceId,
      hrSeriesJson: data.hrSeriesJson.present
          ? data.hrSeriesJson.value
          : this.hrSeriesJson,
      finalKcal: data.finalKcal.present ? data.finalKcal.value : this.finalKcal,
      syncedAt: data.syncedAt.present ? data.syncedAt.value : this.syncedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LiveSessionRow(')
          ..write('id: $id, ')
          ..write('startedAt: $startedAt, ')
          ..write('endedAt: $endedAt, ')
          ..write('sourceId: $sourceId, ')
          ..write('hrSeriesJson: $hrSeriesJson, ')
          ..write('finalKcal: $finalKcal, ')
          ..write('syncedAt: $syncedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id, startedAt, endedAt, sourceId, hrSeriesJson, finalKcal, syncedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LiveSessionRow &&
          other.id == this.id &&
          other.startedAt == this.startedAt &&
          other.endedAt == this.endedAt &&
          other.sourceId == this.sourceId &&
          other.hrSeriesJson == this.hrSeriesJson &&
          other.finalKcal == this.finalKcal &&
          other.syncedAt == this.syncedAt);
}

class LiveSessionsCompanion extends UpdateCompanion<LiveSessionRow> {
  final Value<String> id;
  final Value<DateTime> startedAt;
  final Value<DateTime> endedAt;
  final Value<String> sourceId;
  final Value<String> hrSeriesJson;
  final Value<double> finalKcal;
  final Value<DateTime?> syncedAt;
  final Value<int> rowid;
  const LiveSessionsCompanion({
    this.id = const Value.absent(),
    this.startedAt = const Value.absent(),
    this.endedAt = const Value.absent(),
    this.sourceId = const Value.absent(),
    this.hrSeriesJson = const Value.absent(),
    this.finalKcal = const Value.absent(),
    this.syncedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LiveSessionsCompanion.insert({
    required String id,
    required DateTime startedAt,
    required DateTime endedAt,
    required String sourceId,
    required String hrSeriesJson,
    required double finalKcal,
    this.syncedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        startedAt = Value(startedAt),
        endedAt = Value(endedAt),
        sourceId = Value(sourceId),
        hrSeriesJson = Value(hrSeriesJson),
        finalKcal = Value(finalKcal);
  static Insertable<LiveSessionRow> custom({
    Expression<String>? id,
    Expression<DateTime>? startedAt,
    Expression<DateTime>? endedAt,
    Expression<String>? sourceId,
    Expression<String>? hrSeriesJson,
    Expression<double>? finalKcal,
    Expression<DateTime>? syncedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (startedAt != null) 'started_at': startedAt,
      if (endedAt != null) 'ended_at': endedAt,
      if (sourceId != null) 'source_id': sourceId,
      if (hrSeriesJson != null) 'hr_series_json': hrSeriesJson,
      if (finalKcal != null) 'final_kcal': finalKcal,
      if (syncedAt != null) 'synced_at': syncedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LiveSessionsCompanion copyWith(
      {Value<String>? id,
      Value<DateTime>? startedAt,
      Value<DateTime>? endedAt,
      Value<String>? sourceId,
      Value<String>? hrSeriesJson,
      Value<double>? finalKcal,
      Value<DateTime?>? syncedAt,
      Value<int>? rowid}) {
    return LiveSessionsCompanion(
      id: id ?? this.id,
      startedAt: startedAt ?? this.startedAt,
      endedAt: endedAt ?? this.endedAt,
      sourceId: sourceId ?? this.sourceId,
      hrSeriesJson: hrSeriesJson ?? this.hrSeriesJson,
      finalKcal: finalKcal ?? this.finalKcal,
      syncedAt: syncedAt ?? this.syncedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (startedAt.present) {
      map['started_at'] = Variable<DateTime>(startedAt.value);
    }
    if (endedAt.present) {
      map['ended_at'] = Variable<DateTime>(endedAt.value);
    }
    if (sourceId.present) {
      map['source_id'] = Variable<String>(sourceId.value);
    }
    if (hrSeriesJson.present) {
      map['hr_series_json'] = Variable<String>(hrSeriesJson.value);
    }
    if (finalKcal.present) {
      map['final_kcal'] = Variable<double>(finalKcal.value);
    }
    if (syncedAt.present) {
      map['synced_at'] = Variable<DateTime>(syncedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LiveSessionsCompanion(')
          ..write('id: $id, ')
          ..write('startedAt: $startedAt, ')
          ..write('endedAt: $endedAt, ')
          ..write('sourceId: $sourceId, ')
          ..write('hrSeriesJson: $hrSeriesJson, ')
          ..write('finalKcal: $finalKcal, ')
          ..write('syncedAt: $syncedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $RememberedSensorsTable extends RememberedSensors
    with TableInfo<$RememberedSensorsTable, RememberedSensorRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RememberedSensorsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _deviceIdMeta =
      const VerificationMeta('deviceId');
  @override
  late final GeneratedColumn<String> deviceId = GeneratedColumn<String>(
      'device_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _pairedMeta = const VerificationMeta('paired');
  @override
  late final GeneratedColumn<bool> paired = GeneratedColumn<bool>(
      'paired', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("paired" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _lastConnectedMeta =
      const VerificationMeta('lastConnected');
  @override
  late final GeneratedColumn<DateTime> lastConnected =
      GeneratedColumn<DateTime>('last_connected', aliasedName, true,
          type: DriftSqlType.dateTime, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [deviceId, name, paired, lastConnected];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'remembered_sensors';
  @override
  VerificationContext validateIntegrity(
      Insertable<RememberedSensorRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('device_id')) {
      context.handle(_deviceIdMeta,
          deviceId.isAcceptableOrUnknown(data['device_id']!, _deviceIdMeta));
    } else if (isInserting) {
      context.missing(_deviceIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('paired')) {
      context.handle(_pairedMeta,
          paired.isAcceptableOrUnknown(data['paired']!, _pairedMeta));
    }
    if (data.containsKey('last_connected')) {
      context.handle(
          _lastConnectedMeta,
          lastConnected.isAcceptableOrUnknown(
              data['last_connected']!, _lastConnectedMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {deviceId};
  @override
  RememberedSensorRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return RememberedSensorRow(
      deviceId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}device_id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      paired: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}paired'])!,
      lastConnected: attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime, data['${effectivePrefix}last_connected']),
    );
  }

  @override
  $RememberedSensorsTable createAlias(String alias) {
    return $RememberedSensorsTable(attachedDatabase, alias);
  }
}

class RememberedSensorRow extends DataClass
    implements Insertable<RememberedSensorRow> {
  final String deviceId;
  final String name;
  final bool paired;
  final DateTime? lastConnected;
  const RememberedSensorRow(
      {required this.deviceId,
      required this.name,
      required this.paired,
      this.lastConnected});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['device_id'] = Variable<String>(deviceId);
    map['name'] = Variable<String>(name);
    map['paired'] = Variable<bool>(paired);
    if (!nullToAbsent || lastConnected != null) {
      map['last_connected'] = Variable<DateTime>(lastConnected);
    }
    return map;
  }

  RememberedSensorsCompanion toCompanion(bool nullToAbsent) {
    return RememberedSensorsCompanion(
      deviceId: Value(deviceId),
      name: Value(name),
      paired: Value(paired),
      lastConnected: lastConnected == null && nullToAbsent
          ? const Value.absent()
          : Value(lastConnected),
    );
  }

  factory RememberedSensorRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return RememberedSensorRow(
      deviceId: serializer.fromJson<String>(json['deviceId']),
      name: serializer.fromJson<String>(json['name']),
      paired: serializer.fromJson<bool>(json['paired']),
      lastConnected: serializer.fromJson<DateTime?>(json['lastConnected']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'deviceId': serializer.toJson<String>(deviceId),
      'name': serializer.toJson<String>(name),
      'paired': serializer.toJson<bool>(paired),
      'lastConnected': serializer.toJson<DateTime?>(lastConnected),
    };
  }

  RememberedSensorRow copyWith(
          {String? deviceId,
          String? name,
          bool? paired,
          Value<DateTime?> lastConnected = const Value.absent()}) =>
      RememberedSensorRow(
        deviceId: deviceId ?? this.deviceId,
        name: name ?? this.name,
        paired: paired ?? this.paired,
        lastConnected:
            lastConnected.present ? lastConnected.value : this.lastConnected,
      );
  RememberedSensorRow copyWithCompanion(RememberedSensorsCompanion data) {
    return RememberedSensorRow(
      deviceId: data.deviceId.present ? data.deviceId.value : this.deviceId,
      name: data.name.present ? data.name.value : this.name,
      paired: data.paired.present ? data.paired.value : this.paired,
      lastConnected: data.lastConnected.present
          ? data.lastConnected.value
          : this.lastConnected,
    );
  }

  @override
  String toString() {
    return (StringBuffer('RememberedSensorRow(')
          ..write('deviceId: $deviceId, ')
          ..write('name: $name, ')
          ..write('paired: $paired, ')
          ..write('lastConnected: $lastConnected')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(deviceId, name, paired, lastConnected);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RememberedSensorRow &&
          other.deviceId == this.deviceId &&
          other.name == this.name &&
          other.paired == this.paired &&
          other.lastConnected == this.lastConnected);
}

class RememberedSensorsCompanion extends UpdateCompanion<RememberedSensorRow> {
  final Value<String> deviceId;
  final Value<String> name;
  final Value<bool> paired;
  final Value<DateTime?> lastConnected;
  final Value<int> rowid;
  const RememberedSensorsCompanion({
    this.deviceId = const Value.absent(),
    this.name = const Value.absent(),
    this.paired = const Value.absent(),
    this.lastConnected = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  RememberedSensorsCompanion.insert({
    required String deviceId,
    required String name,
    this.paired = const Value.absent(),
    this.lastConnected = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : deviceId = Value(deviceId),
        name = Value(name);
  static Insertable<RememberedSensorRow> custom({
    Expression<String>? deviceId,
    Expression<String>? name,
    Expression<bool>? paired,
    Expression<DateTime>? lastConnected,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (deviceId != null) 'device_id': deviceId,
      if (name != null) 'name': name,
      if (paired != null) 'paired': paired,
      if (lastConnected != null) 'last_connected': lastConnected,
      if (rowid != null) 'rowid': rowid,
    });
  }

  RememberedSensorsCompanion copyWith(
      {Value<String>? deviceId,
      Value<String>? name,
      Value<bool>? paired,
      Value<DateTime?>? lastConnected,
      Value<int>? rowid}) {
    return RememberedSensorsCompanion(
      deviceId: deviceId ?? this.deviceId,
      name: name ?? this.name,
      paired: paired ?? this.paired,
      lastConnected: lastConnected ?? this.lastConnected,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (deviceId.present) {
      map['device_id'] = Variable<String>(deviceId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (paired.present) {
      map['paired'] = Variable<bool>(paired.value);
    }
    if (lastConnected.present) {
      map['last_connected'] = Variable<DateTime>(lastConnected.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RememberedSensorsCompanion(')
          ..write('deviceId: $deviceId, ')
          ..write('name: $name, ')
          ..write('paired: $paired, ')
          ..write('lastConnected: $lastConnected, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LifestyleEntriesTable extends LifestyleEntries
    with TableInfo<$LifestyleEntriesTable, LifestyleEntryRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LifestyleEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _recordedAtMeta =
      const VerificationMeta('recordedAt');
  @override
  late final GeneratedColumn<DateTime> recordedAt = GeneratedColumn<DateTime>(
      'recorded_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _kindMeta = const VerificationMeta('kind');
  @override
  late final GeneratedColumn<String> kind = GeneratedColumn<String>(
      'kind', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<double> value = GeneratedColumn<double>(
      'value', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _durationMinutesMeta =
      const VerificationMeta('durationMinutes');
  @override
  late final GeneratedColumn<double> durationMinutes = GeneratedColumn<double>(
      'duration_minutes', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
      'note', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _sourceMeta = const VerificationMeta('source');
  @override
  late final GeneratedColumn<String> source = GeneratedColumn<String>(
      'source', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('self-report'));
  static const VerificationMeta _syncedAtMeta =
      const VerificationMeta('syncedAt');
  @override
  late final GeneratedColumn<DateTime> syncedAt = GeneratedColumn<DateTime>(
      'synced_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns =>
      [id, recordedAt, kind, value, durationMinutes, note, source, syncedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'lifestyle_entries';
  @override
  VerificationContext validateIntegrity(Insertable<LifestyleEntryRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('recorded_at')) {
      context.handle(
          _recordedAtMeta,
          recordedAt.isAcceptableOrUnknown(
              data['recorded_at']!, _recordedAtMeta));
    } else if (isInserting) {
      context.missing(_recordedAtMeta);
    }
    if (data.containsKey('kind')) {
      context.handle(
          _kindMeta, kind.isAcceptableOrUnknown(data['kind']!, _kindMeta));
    } else if (isInserting) {
      context.missing(_kindMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
          _valueMeta, value.isAcceptableOrUnknown(data['value']!, _valueMeta));
    }
    if (data.containsKey('duration_minutes')) {
      context.handle(
          _durationMinutesMeta,
          durationMinutes.isAcceptableOrUnknown(
              data['duration_minutes']!, _durationMinutesMeta));
    }
    if (data.containsKey('note')) {
      context.handle(
          _noteMeta, note.isAcceptableOrUnknown(data['note']!, _noteMeta));
    }
    if (data.containsKey('source')) {
      context.handle(_sourceMeta,
          source.isAcceptableOrUnknown(data['source']!, _sourceMeta));
    }
    if (data.containsKey('synced_at')) {
      context.handle(_syncedAtMeta,
          syncedAt.isAcceptableOrUnknown(data['synced_at']!, _syncedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LifestyleEntryRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LifestyleEntryRow(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      recordedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}recorded_at'])!,
      kind: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}kind'])!,
      value: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}value']),
      durationMinutes: attachedDatabase.typeMapping.read(
          DriftSqlType.double, data['${effectivePrefix}duration_minutes']),
      note: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}note']),
      source: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}source'])!,
      syncedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}synced_at']),
    );
  }

  @override
  $LifestyleEntriesTable createAlias(String alias) {
    return $LifestyleEntriesTable(attachedDatabase, alias);
  }
}

class LifestyleEntryRow extends DataClass
    implements Insertable<LifestyleEntryRow> {
  final int id;
  final DateTime recordedAt;

  /// `mood` | `stress` | `recovery` | `sleep` | `meditation` | `breathwork`.
  final String kind;
  final double? value;
  final double? durationMinutes;
  final String? note;
  final String source;
  final DateTime? syncedAt;
  const LifestyleEntryRow(
      {required this.id,
      required this.recordedAt,
      required this.kind,
      this.value,
      this.durationMinutes,
      this.note,
      required this.source,
      this.syncedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['recorded_at'] = Variable<DateTime>(recordedAt);
    map['kind'] = Variable<String>(kind);
    if (!nullToAbsent || value != null) {
      map['value'] = Variable<double>(value);
    }
    if (!nullToAbsent || durationMinutes != null) {
      map['duration_minutes'] = Variable<double>(durationMinutes);
    }
    if (!nullToAbsent || note != null) {
      map['note'] = Variable<String>(note);
    }
    map['source'] = Variable<String>(source);
    if (!nullToAbsent || syncedAt != null) {
      map['synced_at'] = Variable<DateTime>(syncedAt);
    }
    return map;
  }

  LifestyleEntriesCompanion toCompanion(bool nullToAbsent) {
    return LifestyleEntriesCompanion(
      id: Value(id),
      recordedAt: Value(recordedAt),
      kind: Value(kind),
      value:
          value == null && nullToAbsent ? const Value.absent() : Value(value),
      durationMinutes: durationMinutes == null && nullToAbsent
          ? const Value.absent()
          : Value(durationMinutes),
      note: note == null && nullToAbsent ? const Value.absent() : Value(note),
      source: Value(source),
      syncedAt: syncedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(syncedAt),
    );
  }

  factory LifestyleEntryRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LifestyleEntryRow(
      id: serializer.fromJson<int>(json['id']),
      recordedAt: serializer.fromJson<DateTime>(json['recordedAt']),
      kind: serializer.fromJson<String>(json['kind']),
      value: serializer.fromJson<double?>(json['value']),
      durationMinutes: serializer.fromJson<double?>(json['durationMinutes']),
      note: serializer.fromJson<String?>(json['note']),
      source: serializer.fromJson<String>(json['source']),
      syncedAt: serializer.fromJson<DateTime?>(json['syncedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'recordedAt': serializer.toJson<DateTime>(recordedAt),
      'kind': serializer.toJson<String>(kind),
      'value': serializer.toJson<double?>(value),
      'durationMinutes': serializer.toJson<double?>(durationMinutes),
      'note': serializer.toJson<String?>(note),
      'source': serializer.toJson<String>(source),
      'syncedAt': serializer.toJson<DateTime?>(syncedAt),
    };
  }

  LifestyleEntryRow copyWith(
          {int? id,
          DateTime? recordedAt,
          String? kind,
          Value<double?> value = const Value.absent(),
          Value<double?> durationMinutes = const Value.absent(),
          Value<String?> note = const Value.absent(),
          String? source,
          Value<DateTime?> syncedAt = const Value.absent()}) =>
      LifestyleEntryRow(
        id: id ?? this.id,
        recordedAt: recordedAt ?? this.recordedAt,
        kind: kind ?? this.kind,
        value: value.present ? value.value : this.value,
        durationMinutes: durationMinutes.present
            ? durationMinutes.value
            : this.durationMinutes,
        note: note.present ? note.value : this.note,
        source: source ?? this.source,
        syncedAt: syncedAt.present ? syncedAt.value : this.syncedAt,
      );
  LifestyleEntryRow copyWithCompanion(LifestyleEntriesCompanion data) {
    return LifestyleEntryRow(
      id: data.id.present ? data.id.value : this.id,
      recordedAt:
          data.recordedAt.present ? data.recordedAt.value : this.recordedAt,
      kind: data.kind.present ? data.kind.value : this.kind,
      value: data.value.present ? data.value.value : this.value,
      durationMinutes: data.durationMinutes.present
          ? data.durationMinutes.value
          : this.durationMinutes,
      note: data.note.present ? data.note.value : this.note,
      source: data.source.present ? data.source.value : this.source,
      syncedAt: data.syncedAt.present ? data.syncedAt.value : this.syncedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LifestyleEntryRow(')
          ..write('id: $id, ')
          ..write('recordedAt: $recordedAt, ')
          ..write('kind: $kind, ')
          ..write('value: $value, ')
          ..write('durationMinutes: $durationMinutes, ')
          ..write('note: $note, ')
          ..write('source: $source, ')
          ..write('syncedAt: $syncedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id, recordedAt, kind, value, durationMinutes, note, source, syncedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LifestyleEntryRow &&
          other.id == this.id &&
          other.recordedAt == this.recordedAt &&
          other.kind == this.kind &&
          other.value == this.value &&
          other.durationMinutes == this.durationMinutes &&
          other.note == this.note &&
          other.source == this.source &&
          other.syncedAt == this.syncedAt);
}

class LifestyleEntriesCompanion extends UpdateCompanion<LifestyleEntryRow> {
  final Value<int> id;
  final Value<DateTime> recordedAt;
  final Value<String> kind;
  final Value<double?> value;
  final Value<double?> durationMinutes;
  final Value<String?> note;
  final Value<String> source;
  final Value<DateTime?> syncedAt;
  const LifestyleEntriesCompanion({
    this.id = const Value.absent(),
    this.recordedAt = const Value.absent(),
    this.kind = const Value.absent(),
    this.value = const Value.absent(),
    this.durationMinutes = const Value.absent(),
    this.note = const Value.absent(),
    this.source = const Value.absent(),
    this.syncedAt = const Value.absent(),
  });
  LifestyleEntriesCompanion.insert({
    this.id = const Value.absent(),
    required DateTime recordedAt,
    required String kind,
    this.value = const Value.absent(),
    this.durationMinutes = const Value.absent(),
    this.note = const Value.absent(),
    this.source = const Value.absent(),
    this.syncedAt = const Value.absent(),
  })  : recordedAt = Value(recordedAt),
        kind = Value(kind);
  static Insertable<LifestyleEntryRow> custom({
    Expression<int>? id,
    Expression<DateTime>? recordedAt,
    Expression<String>? kind,
    Expression<double>? value,
    Expression<double>? durationMinutes,
    Expression<String>? note,
    Expression<String>? source,
    Expression<DateTime>? syncedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (recordedAt != null) 'recorded_at': recordedAt,
      if (kind != null) 'kind': kind,
      if (value != null) 'value': value,
      if (durationMinutes != null) 'duration_minutes': durationMinutes,
      if (note != null) 'note': note,
      if (source != null) 'source': source,
      if (syncedAt != null) 'synced_at': syncedAt,
    });
  }

  LifestyleEntriesCompanion copyWith(
      {Value<int>? id,
      Value<DateTime>? recordedAt,
      Value<String>? kind,
      Value<double?>? value,
      Value<double?>? durationMinutes,
      Value<String?>? note,
      Value<String>? source,
      Value<DateTime?>? syncedAt}) {
    return LifestyleEntriesCompanion(
      id: id ?? this.id,
      recordedAt: recordedAt ?? this.recordedAt,
      kind: kind ?? this.kind,
      value: value ?? this.value,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      note: note ?? this.note,
      source: source ?? this.source,
      syncedAt: syncedAt ?? this.syncedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (recordedAt.present) {
      map['recorded_at'] = Variable<DateTime>(recordedAt.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(kind.value);
    }
    if (value.present) {
      map['value'] = Variable<double>(value.value);
    }
    if (durationMinutes.present) {
      map['duration_minutes'] = Variable<double>(durationMinutes.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (source.present) {
      map['source'] = Variable<String>(source.value);
    }
    if (syncedAt.present) {
      map['synced_at'] = Variable<DateTime>(syncedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LifestyleEntriesCompanion(')
          ..write('id: $id, ')
          ..write('recordedAt: $recordedAt, ')
          ..write('kind: $kind, ')
          ..write('value: $value, ')
          ..write('durationMinutes: $durationMinutes, ')
          ..write('note: $note, ')
          ..write('source: $source, ')
          ..write('syncedAt: $syncedAt')
          ..write(')'))
        .toString();
  }
}

class $JournalEntriesTable extends JournalEntries
    with TableInfo<$JournalEntriesTable, JournalEntryRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $JournalEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _entryTextMeta =
      const VerificationMeta('entryText');
  @override
  late final GeneratedColumn<String> entryText = GeneratedColumn<String>(
      'text', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _sourceMeta = const VerificationMeta('source');
  @override
  late final GeneratedColumn<String> source = GeneratedColumn<String>(
      'source', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('typed'));
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
      'status', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('pending'));
  static const VerificationMeta _extractionJsonMeta =
      const VerificationMeta('extractionJson');
  @override
  late final GeneratedColumn<String> extractionJson = GeneratedColumn<String>(
      'extraction_json', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _modelMeta = const VerificationMeta('model');
  @override
  late final GeneratedColumn<String> model = GeneratedColumn<String>(
      'model', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _appliedAtMeta =
      const VerificationMeta('appliedAt');
  @override
  late final GeneratedColumn<DateTime> appliedAt = GeneratedColumn<DateTime>(
      'applied_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _excludedFromAiMeta =
      const VerificationMeta('excludedFromAi');
  @override
  late final GeneratedColumn<bool> excludedFromAi = GeneratedColumn<bool>(
      'excluded_from_ai', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("excluded_from_ai" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _syncedAtMeta =
      const VerificationMeta('syncedAt');
  @override
  late final GeneratedColumn<DateTime> syncedAt = GeneratedColumn<DateTime>(
      'synced_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        createdAt,
        entryText,
        source,
        status,
        extractionJson,
        model,
        appliedAt,
        excludedFromAi,
        syncedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'journal_entries';
  @override
  VerificationContext validateIntegrity(Insertable<JournalEntryRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('text')) {
      context.handle(_entryTextMeta,
          entryText.isAcceptableOrUnknown(data['text']!, _entryTextMeta));
    } else if (isInserting) {
      context.missing(_entryTextMeta);
    }
    if (data.containsKey('source')) {
      context.handle(_sourceMeta,
          source.isAcceptableOrUnknown(data['source']!, _sourceMeta));
    }
    if (data.containsKey('status')) {
      context.handle(_statusMeta,
          status.isAcceptableOrUnknown(data['status']!, _statusMeta));
    }
    if (data.containsKey('extraction_json')) {
      context.handle(
          _extractionJsonMeta,
          extractionJson.isAcceptableOrUnknown(
              data['extraction_json']!, _extractionJsonMeta));
    }
    if (data.containsKey('model')) {
      context.handle(
          _modelMeta, model.isAcceptableOrUnknown(data['model']!, _modelMeta));
    }
    if (data.containsKey('applied_at')) {
      context.handle(_appliedAtMeta,
          appliedAt.isAcceptableOrUnknown(data['applied_at']!, _appliedAtMeta));
    }
    if (data.containsKey('excluded_from_ai')) {
      context.handle(
          _excludedFromAiMeta,
          excludedFromAi.isAcceptableOrUnknown(
              data['excluded_from_ai']!, _excludedFromAiMeta));
    }
    if (data.containsKey('synced_at')) {
      context.handle(_syncedAtMeta,
          syncedAt.isAcceptableOrUnknown(data['synced_at']!, _syncedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  JournalEntryRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return JournalEntryRow(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      entryText: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}text'])!,
      source: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}source'])!,
      status: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}status'])!,
      extractionJson: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}extraction_json']),
      model: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}model']),
      appliedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}applied_at']),
      excludedFromAi: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}excluded_from_ai'])!,
      syncedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}synced_at']),
    );
  }

  @override
  $JournalEntriesTable createAlias(String alias) {
    return $JournalEntriesTable(attachedDatabase, alias);
  }
}

class JournalEntryRow extends DataClass implements Insertable<JournalEntryRow> {
  final int id;
  final DateTime createdAt;

  /// `text` is also Drift's column builder, so the Dart getter differs. The
  /// persisted column stays exactly `text`.
  final String entryText;

  /// `typed` | `spoken`. Spoken entries carry transcription error the user may
  /// want to fix.
  final String source;

  /// `pending` | `classified` | `needsDetail` | `failed` | `discarded`.
  final String status;
  final String? extractionJson;
  final String? model;

  /// Set once the derived rows exist, so a retry cannot double-log the same
  /// meal into NutritionEntries.
  final DateTime? appliedAt;

  /// The user has excluded this entry from AI processing. Guidance must not
  /// see it, in prose or in summary. Classification is still allowed, because
  /// that is what the user explicitly asked for when they wrote it.
  final bool excludedFromAi;
  final DateTime? syncedAt;
  const JournalEntryRow(
      {required this.id,
      required this.createdAt,
      required this.entryText,
      required this.source,
      required this.status,
      this.extractionJson,
      this.model,
      this.appliedAt,
      required this.excludedFromAi,
      this.syncedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['text'] = Variable<String>(entryText);
    map['source'] = Variable<String>(source);
    map['status'] = Variable<String>(status);
    if (!nullToAbsent || extractionJson != null) {
      map['extraction_json'] = Variable<String>(extractionJson);
    }
    if (!nullToAbsent || model != null) {
      map['model'] = Variable<String>(model);
    }
    if (!nullToAbsent || appliedAt != null) {
      map['applied_at'] = Variable<DateTime>(appliedAt);
    }
    map['excluded_from_ai'] = Variable<bool>(excludedFromAi);
    if (!nullToAbsent || syncedAt != null) {
      map['synced_at'] = Variable<DateTime>(syncedAt);
    }
    return map;
  }

  JournalEntriesCompanion toCompanion(bool nullToAbsent) {
    return JournalEntriesCompanion(
      id: Value(id),
      createdAt: Value(createdAt),
      entryText: Value(entryText),
      source: Value(source),
      status: Value(status),
      extractionJson: extractionJson == null && nullToAbsent
          ? const Value.absent()
          : Value(extractionJson),
      model:
          model == null && nullToAbsent ? const Value.absent() : Value(model),
      appliedAt: appliedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(appliedAt),
      excludedFromAi: Value(excludedFromAi),
      syncedAt: syncedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(syncedAt),
    );
  }

  factory JournalEntryRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return JournalEntryRow(
      id: serializer.fromJson<int>(json['id']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      entryText: serializer.fromJson<String>(json['entryText']),
      source: serializer.fromJson<String>(json['source']),
      status: serializer.fromJson<String>(json['status']),
      extractionJson: serializer.fromJson<String?>(json['extractionJson']),
      model: serializer.fromJson<String?>(json['model']),
      appliedAt: serializer.fromJson<DateTime?>(json['appliedAt']),
      excludedFromAi: serializer.fromJson<bool>(json['excludedFromAi']),
      syncedAt: serializer.fromJson<DateTime?>(json['syncedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'entryText': serializer.toJson<String>(entryText),
      'source': serializer.toJson<String>(source),
      'status': serializer.toJson<String>(status),
      'extractionJson': serializer.toJson<String?>(extractionJson),
      'model': serializer.toJson<String?>(model),
      'appliedAt': serializer.toJson<DateTime?>(appliedAt),
      'excludedFromAi': serializer.toJson<bool>(excludedFromAi),
      'syncedAt': serializer.toJson<DateTime?>(syncedAt),
    };
  }

  JournalEntryRow copyWith(
          {int? id,
          DateTime? createdAt,
          String? entryText,
          String? source,
          String? status,
          Value<String?> extractionJson = const Value.absent(),
          Value<String?> model = const Value.absent(),
          Value<DateTime?> appliedAt = const Value.absent(),
          bool? excludedFromAi,
          Value<DateTime?> syncedAt = const Value.absent()}) =>
      JournalEntryRow(
        id: id ?? this.id,
        createdAt: createdAt ?? this.createdAt,
        entryText: entryText ?? this.entryText,
        source: source ?? this.source,
        status: status ?? this.status,
        extractionJson:
            extractionJson.present ? extractionJson.value : this.extractionJson,
        model: model.present ? model.value : this.model,
        appliedAt: appliedAt.present ? appliedAt.value : this.appliedAt,
        excludedFromAi: excludedFromAi ?? this.excludedFromAi,
        syncedAt: syncedAt.present ? syncedAt.value : this.syncedAt,
      );
  JournalEntryRow copyWithCompanion(JournalEntriesCompanion data) {
    return JournalEntryRow(
      id: data.id.present ? data.id.value : this.id,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      entryText: data.entryText.present ? data.entryText.value : this.entryText,
      source: data.source.present ? data.source.value : this.source,
      status: data.status.present ? data.status.value : this.status,
      extractionJson: data.extractionJson.present
          ? data.extractionJson.value
          : this.extractionJson,
      model: data.model.present ? data.model.value : this.model,
      appliedAt: data.appliedAt.present ? data.appliedAt.value : this.appliedAt,
      excludedFromAi: data.excludedFromAi.present
          ? data.excludedFromAi.value
          : this.excludedFromAi,
      syncedAt: data.syncedAt.present ? data.syncedAt.value : this.syncedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('JournalEntryRow(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('entryText: $entryText, ')
          ..write('source: $source, ')
          ..write('status: $status, ')
          ..write('extractionJson: $extractionJson, ')
          ..write('model: $model, ')
          ..write('appliedAt: $appliedAt, ')
          ..write('excludedFromAi: $excludedFromAi, ')
          ..write('syncedAt: $syncedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, createdAt, entryText, source, status,
      extractionJson, model, appliedAt, excludedFromAi, syncedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is JournalEntryRow &&
          other.id == this.id &&
          other.createdAt == this.createdAt &&
          other.entryText == this.entryText &&
          other.source == this.source &&
          other.status == this.status &&
          other.extractionJson == this.extractionJson &&
          other.model == this.model &&
          other.appliedAt == this.appliedAt &&
          other.excludedFromAi == this.excludedFromAi &&
          other.syncedAt == this.syncedAt);
}

class JournalEntriesCompanion extends UpdateCompanion<JournalEntryRow> {
  final Value<int> id;
  final Value<DateTime> createdAt;
  final Value<String> entryText;
  final Value<String> source;
  final Value<String> status;
  final Value<String?> extractionJson;
  final Value<String?> model;
  final Value<DateTime?> appliedAt;
  final Value<bool> excludedFromAi;
  final Value<DateTime?> syncedAt;
  const JournalEntriesCompanion({
    this.id = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.entryText = const Value.absent(),
    this.source = const Value.absent(),
    this.status = const Value.absent(),
    this.extractionJson = const Value.absent(),
    this.model = const Value.absent(),
    this.appliedAt = const Value.absent(),
    this.excludedFromAi = const Value.absent(),
    this.syncedAt = const Value.absent(),
  });
  JournalEntriesCompanion.insert({
    this.id = const Value.absent(),
    required DateTime createdAt,
    required String entryText,
    this.source = const Value.absent(),
    this.status = const Value.absent(),
    this.extractionJson = const Value.absent(),
    this.model = const Value.absent(),
    this.appliedAt = const Value.absent(),
    this.excludedFromAi = const Value.absent(),
    this.syncedAt = const Value.absent(),
  })  : createdAt = Value(createdAt),
        entryText = Value(entryText);
  static Insertable<JournalEntryRow> custom({
    Expression<int>? id,
    Expression<DateTime>? createdAt,
    Expression<String>? entryText,
    Expression<String>? source,
    Expression<String>? status,
    Expression<String>? extractionJson,
    Expression<String>? model,
    Expression<DateTime>? appliedAt,
    Expression<bool>? excludedFromAi,
    Expression<DateTime>? syncedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (createdAt != null) 'created_at': createdAt,
      if (entryText != null) 'text': entryText,
      if (source != null) 'source': source,
      if (status != null) 'status': status,
      if (extractionJson != null) 'extraction_json': extractionJson,
      if (model != null) 'model': model,
      if (appliedAt != null) 'applied_at': appliedAt,
      if (excludedFromAi != null) 'excluded_from_ai': excludedFromAi,
      if (syncedAt != null) 'synced_at': syncedAt,
    });
  }

  JournalEntriesCompanion copyWith(
      {Value<int>? id,
      Value<DateTime>? createdAt,
      Value<String>? entryText,
      Value<String>? source,
      Value<String>? status,
      Value<String?>? extractionJson,
      Value<String?>? model,
      Value<DateTime?>? appliedAt,
      Value<bool>? excludedFromAi,
      Value<DateTime?>? syncedAt}) {
    return JournalEntriesCompanion(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      entryText: entryText ?? this.entryText,
      source: source ?? this.source,
      status: status ?? this.status,
      extractionJson: extractionJson ?? this.extractionJson,
      model: model ?? this.model,
      appliedAt: appliedAt ?? this.appliedAt,
      excludedFromAi: excludedFromAi ?? this.excludedFromAi,
      syncedAt: syncedAt ?? this.syncedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (entryText.present) {
      map['text'] = Variable<String>(entryText.value);
    }
    if (source.present) {
      map['source'] = Variable<String>(source.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (extractionJson.present) {
      map['extraction_json'] = Variable<String>(extractionJson.value);
    }
    if (model.present) {
      map['model'] = Variable<String>(model.value);
    }
    if (appliedAt.present) {
      map['applied_at'] = Variable<DateTime>(appliedAt.value);
    }
    if (excludedFromAi.present) {
      map['excluded_from_ai'] = Variable<bool>(excludedFromAi.value);
    }
    if (syncedAt.present) {
      map['synced_at'] = Variable<DateTime>(syncedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('JournalEntriesCompanion(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('entryText: $entryText, ')
          ..write('source: $source, ')
          ..write('status: $status, ')
          ..write('extractionJson: $extractionJson, ')
          ..write('model: $model, ')
          ..write('appliedAt: $appliedAt, ')
          ..write('excludedFromAi: $excludedFromAi, ')
          ..write('syncedAt: $syncedAt')
          ..write(')'))
        .toString();
  }
}

class $GuidanceHistoryTable extends GuidanceHistory
    with TableInfo<$GuidanceHistoryTable, GuidanceHistoryRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $GuidanceHistoryTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<String> date = GeneratedColumn<String>(
      'date', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _dimensionMeta =
      const VerificationMeta('dimension');
  @override
  late final GeneratedColumn<String> dimension = GeneratedColumn<String>(
      'dimension', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _generatedAtMeta =
      const VerificationMeta('generatedAt');
  @override
  late final GeneratedColumn<DateTime> generatedAt = GeneratedColumn<DateTime>(
      'generated_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _contentJsonMeta =
      const VerificationMeta('contentJson');
  @override
  late final GeneratedColumn<String> contentJson = GeneratedColumn<String>(
      'content_json', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _evidenceJsonMeta =
      const VerificationMeta('evidenceJson');
  @override
  late final GeneratedColumn<String> evidenceJson = GeneratedColumn<String>(
      'evidence_json', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _contextFingerprintMeta =
      const VerificationMeta('contextFingerprint');
  @override
  late final GeneratedColumn<String> contextFingerprint =
      GeneratedColumn<String>('context_fingerprint', aliasedName, false,
          type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _sourceMeta = const VerificationMeta('source');
  @override
  late final GeneratedColumn<String> source = GeneratedColumn<String>(
      'source', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _syncedAtMeta =
      const VerificationMeta('syncedAt');
  @override
  late final GeneratedColumn<DateTime> syncedAt = GeneratedColumn<DateTime>(
      'synced_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        date,
        dimension,
        generatedAt,
        contentJson,
        evidenceJson,
        contextFingerprint,
        source,
        syncedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'guidance_history';
  @override
  VerificationContext validateIntegrity(Insertable<GuidanceHistoryRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('date')) {
      context.handle(
          _dateMeta, date.isAcceptableOrUnknown(data['date']!, _dateMeta));
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('dimension')) {
      context.handle(_dimensionMeta,
          dimension.isAcceptableOrUnknown(data['dimension']!, _dimensionMeta));
    } else if (isInserting) {
      context.missing(_dimensionMeta);
    }
    if (data.containsKey('generated_at')) {
      context.handle(
          _generatedAtMeta,
          generatedAt.isAcceptableOrUnknown(
              data['generated_at']!, _generatedAtMeta));
    } else if (isInserting) {
      context.missing(_generatedAtMeta);
    }
    if (data.containsKey('content_json')) {
      context.handle(
          _contentJsonMeta,
          contentJson.isAcceptableOrUnknown(
              data['content_json']!, _contentJsonMeta));
    } else if (isInserting) {
      context.missing(_contentJsonMeta);
    }
    if (data.containsKey('evidence_json')) {
      context.handle(
          _evidenceJsonMeta,
          evidenceJson.isAcceptableOrUnknown(
              data['evidence_json']!, _evidenceJsonMeta));
    }
    if (data.containsKey('context_fingerprint')) {
      context.handle(
          _contextFingerprintMeta,
          contextFingerprint.isAcceptableOrUnknown(
              data['context_fingerprint']!, _contextFingerprintMeta));
    } else if (isInserting) {
      context.missing(_contextFingerprintMeta);
    }
    if (data.containsKey('source')) {
      context.handle(_sourceMeta,
          source.isAcceptableOrUnknown(data['source']!, _sourceMeta));
    } else if (isInserting) {
      context.missing(_sourceMeta);
    }
    if (data.containsKey('synced_at')) {
      context.handle(_syncedAtMeta,
          syncedAt.isAcceptableOrUnknown(data['synced_at']!, _syncedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  GuidanceHistoryRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return GuidanceHistoryRow(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      date: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}date'])!,
      dimension: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}dimension'])!,
      generatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}generated_at'])!,
      contentJson: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}content_json'])!,
      evidenceJson: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}evidence_json']),
      contextFingerprint: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}context_fingerprint'])!,
      source: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}source'])!,
      syncedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}synced_at']),
    );
  }

  @override
  $GuidanceHistoryTable createAlias(String alias) {
    return $GuidanceHistoryTable(attachedDatabase, alias);
  }
}

class GuidanceHistoryRow extends DataClass
    implements Insertable<GuidanceHistoryRow> {
  final int id;

  /// Local `yyyy-MM-dd`.
  final String date;

  /// `synthesis` | `health` | `mind` | `spirit`. The collapsed surface renders
  /// the synthesis; expanding shows the three dimensions.
  final String dimension;
  final DateTime generatedAt;
  final String contentJson;

  /// The receipts behind any claim resting on data: n, window, coefficient.
  /// Null when the passage made no empirical claim.
  final String? evidenceJson;

  /// Detects whether the inputs actually changed, so a recomposition is only
  /// requested when there is something new to say.
  final String contextFingerprint;

  /// The model, or `local` for the offline composition. The surface tells the
  /// user which they are reading.
  final String source;
  final DateTime? syncedAt;
  const GuidanceHistoryRow(
      {required this.id,
      required this.date,
      required this.dimension,
      required this.generatedAt,
      required this.contentJson,
      this.evidenceJson,
      required this.contextFingerprint,
      required this.source,
      this.syncedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['date'] = Variable<String>(date);
    map['dimension'] = Variable<String>(dimension);
    map['generated_at'] = Variable<DateTime>(generatedAt);
    map['content_json'] = Variable<String>(contentJson);
    if (!nullToAbsent || evidenceJson != null) {
      map['evidence_json'] = Variable<String>(evidenceJson);
    }
    map['context_fingerprint'] = Variable<String>(contextFingerprint);
    map['source'] = Variable<String>(source);
    if (!nullToAbsent || syncedAt != null) {
      map['synced_at'] = Variable<DateTime>(syncedAt);
    }
    return map;
  }

  GuidanceHistoryCompanion toCompanion(bool nullToAbsent) {
    return GuidanceHistoryCompanion(
      id: Value(id),
      date: Value(date),
      dimension: Value(dimension),
      generatedAt: Value(generatedAt),
      contentJson: Value(contentJson),
      evidenceJson: evidenceJson == null && nullToAbsent
          ? const Value.absent()
          : Value(evidenceJson),
      contextFingerprint: Value(contextFingerprint),
      source: Value(source),
      syncedAt: syncedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(syncedAt),
    );
  }

  factory GuidanceHistoryRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return GuidanceHistoryRow(
      id: serializer.fromJson<int>(json['id']),
      date: serializer.fromJson<String>(json['date']),
      dimension: serializer.fromJson<String>(json['dimension']),
      generatedAt: serializer.fromJson<DateTime>(json['generatedAt']),
      contentJson: serializer.fromJson<String>(json['contentJson']),
      evidenceJson: serializer.fromJson<String?>(json['evidenceJson']),
      contextFingerprint:
          serializer.fromJson<String>(json['contextFingerprint']),
      source: serializer.fromJson<String>(json['source']),
      syncedAt: serializer.fromJson<DateTime?>(json['syncedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'date': serializer.toJson<String>(date),
      'dimension': serializer.toJson<String>(dimension),
      'generatedAt': serializer.toJson<DateTime>(generatedAt),
      'contentJson': serializer.toJson<String>(contentJson),
      'evidenceJson': serializer.toJson<String?>(evidenceJson),
      'contextFingerprint': serializer.toJson<String>(contextFingerprint),
      'source': serializer.toJson<String>(source),
      'syncedAt': serializer.toJson<DateTime?>(syncedAt),
    };
  }

  GuidanceHistoryRow copyWith(
          {int? id,
          String? date,
          String? dimension,
          DateTime? generatedAt,
          String? contentJson,
          Value<String?> evidenceJson = const Value.absent(),
          String? contextFingerprint,
          String? source,
          Value<DateTime?> syncedAt = const Value.absent()}) =>
      GuidanceHistoryRow(
        id: id ?? this.id,
        date: date ?? this.date,
        dimension: dimension ?? this.dimension,
        generatedAt: generatedAt ?? this.generatedAt,
        contentJson: contentJson ?? this.contentJson,
        evidenceJson:
            evidenceJson.present ? evidenceJson.value : this.evidenceJson,
        contextFingerprint: contextFingerprint ?? this.contextFingerprint,
        source: source ?? this.source,
        syncedAt: syncedAt.present ? syncedAt.value : this.syncedAt,
      );
  GuidanceHistoryRow copyWithCompanion(GuidanceHistoryCompanion data) {
    return GuidanceHistoryRow(
      id: data.id.present ? data.id.value : this.id,
      date: data.date.present ? data.date.value : this.date,
      dimension: data.dimension.present ? data.dimension.value : this.dimension,
      generatedAt:
          data.generatedAt.present ? data.generatedAt.value : this.generatedAt,
      contentJson:
          data.contentJson.present ? data.contentJson.value : this.contentJson,
      evidenceJson: data.evidenceJson.present
          ? data.evidenceJson.value
          : this.evidenceJson,
      contextFingerprint: data.contextFingerprint.present
          ? data.contextFingerprint.value
          : this.contextFingerprint,
      source: data.source.present ? data.source.value : this.source,
      syncedAt: data.syncedAt.present ? data.syncedAt.value : this.syncedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('GuidanceHistoryRow(')
          ..write('id: $id, ')
          ..write('date: $date, ')
          ..write('dimension: $dimension, ')
          ..write('generatedAt: $generatedAt, ')
          ..write('contentJson: $contentJson, ')
          ..write('evidenceJson: $evidenceJson, ')
          ..write('contextFingerprint: $contextFingerprint, ')
          ..write('source: $source, ')
          ..write('syncedAt: $syncedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, date, dimension, generatedAt, contentJson,
      evidenceJson, contextFingerprint, source, syncedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is GuidanceHistoryRow &&
          other.id == this.id &&
          other.date == this.date &&
          other.dimension == this.dimension &&
          other.generatedAt == this.generatedAt &&
          other.contentJson == this.contentJson &&
          other.evidenceJson == this.evidenceJson &&
          other.contextFingerprint == this.contextFingerprint &&
          other.source == this.source &&
          other.syncedAt == this.syncedAt);
}

class GuidanceHistoryCompanion extends UpdateCompanion<GuidanceHistoryRow> {
  final Value<int> id;
  final Value<String> date;
  final Value<String> dimension;
  final Value<DateTime> generatedAt;
  final Value<String> contentJson;
  final Value<String?> evidenceJson;
  final Value<String> contextFingerprint;
  final Value<String> source;
  final Value<DateTime?> syncedAt;
  const GuidanceHistoryCompanion({
    this.id = const Value.absent(),
    this.date = const Value.absent(),
    this.dimension = const Value.absent(),
    this.generatedAt = const Value.absent(),
    this.contentJson = const Value.absent(),
    this.evidenceJson = const Value.absent(),
    this.contextFingerprint = const Value.absent(),
    this.source = const Value.absent(),
    this.syncedAt = const Value.absent(),
  });
  GuidanceHistoryCompanion.insert({
    this.id = const Value.absent(),
    required String date,
    required String dimension,
    required DateTime generatedAt,
    required String contentJson,
    this.evidenceJson = const Value.absent(),
    required String contextFingerprint,
    required String source,
    this.syncedAt = const Value.absent(),
  })  : date = Value(date),
        dimension = Value(dimension),
        generatedAt = Value(generatedAt),
        contentJson = Value(contentJson),
        contextFingerprint = Value(contextFingerprint),
        source = Value(source);
  static Insertable<GuidanceHistoryRow> custom({
    Expression<int>? id,
    Expression<String>? date,
    Expression<String>? dimension,
    Expression<DateTime>? generatedAt,
    Expression<String>? contentJson,
    Expression<String>? evidenceJson,
    Expression<String>? contextFingerprint,
    Expression<String>? source,
    Expression<DateTime>? syncedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (date != null) 'date': date,
      if (dimension != null) 'dimension': dimension,
      if (generatedAt != null) 'generated_at': generatedAt,
      if (contentJson != null) 'content_json': contentJson,
      if (evidenceJson != null) 'evidence_json': evidenceJson,
      if (contextFingerprint != null) 'context_fingerprint': contextFingerprint,
      if (source != null) 'source': source,
      if (syncedAt != null) 'synced_at': syncedAt,
    });
  }

  GuidanceHistoryCompanion copyWith(
      {Value<int>? id,
      Value<String>? date,
      Value<String>? dimension,
      Value<DateTime>? generatedAt,
      Value<String>? contentJson,
      Value<String?>? evidenceJson,
      Value<String>? contextFingerprint,
      Value<String>? source,
      Value<DateTime?>? syncedAt}) {
    return GuidanceHistoryCompanion(
      id: id ?? this.id,
      date: date ?? this.date,
      dimension: dimension ?? this.dimension,
      generatedAt: generatedAt ?? this.generatedAt,
      contentJson: contentJson ?? this.contentJson,
      evidenceJson: evidenceJson ?? this.evidenceJson,
      contextFingerprint: contextFingerprint ?? this.contextFingerprint,
      source: source ?? this.source,
      syncedAt: syncedAt ?? this.syncedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (date.present) {
      map['date'] = Variable<String>(date.value);
    }
    if (dimension.present) {
      map['dimension'] = Variable<String>(dimension.value);
    }
    if (generatedAt.present) {
      map['generated_at'] = Variable<DateTime>(generatedAt.value);
    }
    if (contentJson.present) {
      map['content_json'] = Variable<String>(contentJson.value);
    }
    if (evidenceJson.present) {
      map['evidence_json'] = Variable<String>(evidenceJson.value);
    }
    if (contextFingerprint.present) {
      map['context_fingerprint'] = Variable<String>(contextFingerprint.value);
    }
    if (source.present) {
      map['source'] = Variable<String>(source.value);
    }
    if (syncedAt.present) {
      map['synced_at'] = Variable<DateTime>(syncedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('GuidanceHistoryCompanion(')
          ..write('id: $id, ')
          ..write('date: $date, ')
          ..write('dimension: $dimension, ')
          ..write('generatedAt: $generatedAt, ')
          ..write('contentJson: $contentJson, ')
          ..write('evidenceJson: $evidenceJson, ')
          ..write('contextFingerprint: $contextFingerprint, ')
          ..write('source: $source, ')
          ..write('syncedAt: $syncedAt')
          ..write(')'))
        .toString();
  }
}

class $VesselReadingsTable extends VesselReadings
    with TableInfo<$VesselReadingsTable, VesselReadingRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $VesselReadingsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _inputHashMeta =
      const VerificationMeta('inputHash');
  @override
  late final GeneratedColumn<String> inputHash = GeneratedColumn<String>(
      'input_hash', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _positionKeyMeta =
      const VerificationMeta('positionKey');
  @override
  late final GeneratedColumn<String> positionKey = GeneratedColumn<String>(
      'position_key', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _contentJsonMeta =
      const VerificationMeta('contentJson');
  @override
  late final GeneratedColumn<String> contentJson = GeneratedColumn<String>(
      'content_json', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _modelMeta = const VerificationMeta('model');
  @override
  late final GeneratedColumn<String> model = GeneratedColumn<String>(
      'model', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _syncedAtMeta =
      const VerificationMeta('syncedAt');
  @override
  late final GeneratedColumn<DateTime> syncedAt = GeneratedColumn<DateTime>(
      'synced_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns =>
      [inputHash, positionKey, createdAt, contentJson, model, syncedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'vessel_readings';
  @override
  VerificationContext validateIntegrity(Insertable<VesselReadingRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('input_hash')) {
      context.handle(_inputHashMeta,
          inputHash.isAcceptableOrUnknown(data['input_hash']!, _inputHashMeta));
    } else if (isInserting) {
      context.missing(_inputHashMeta);
    }
    if (data.containsKey('position_key')) {
      context.handle(
          _positionKeyMeta,
          positionKey.isAcceptableOrUnknown(
              data['position_key']!, _positionKeyMeta));
    } else if (isInserting) {
      context.missing(_positionKeyMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('content_json')) {
      context.handle(
          _contentJsonMeta,
          contentJson.isAcceptableOrUnknown(
              data['content_json']!, _contentJsonMeta));
    } else if (isInserting) {
      context.missing(_contentJsonMeta);
    }
    if (data.containsKey('model')) {
      context.handle(
          _modelMeta, model.isAcceptableOrUnknown(data['model']!, _modelMeta));
    } else if (isInserting) {
      context.missing(_modelMeta);
    }
    if (data.containsKey('synced_at')) {
      context.handle(_syncedAtMeta,
          syncedAt.isAcceptableOrUnknown(data['synced_at']!, _syncedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {inputHash, positionKey};
  @override
  VesselReadingRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return VesselReadingRow(
      inputHash: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}input_hash'])!,
      positionKey: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}position_key'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      contentJson: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}content_json'])!,
      model: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}model'])!,
      syncedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}synced_at']),
    );
  }

  @override
  $VesselReadingsTable createAlias(String alias) {
    return $VesselReadingsTable(attachedDatabase, alias);
  }
}

class VesselReadingRow extends DataClass
    implements Insertable<VesselReadingRow> {
  final String inputHash;

  /// `lifePath` | `sun` | `moon` | `ascendant` | `house.7` | `card.strength`.
  final String positionKey;
  final DateTime createdAt;
  final String contentJson;
  final String model;
  final DateTime? syncedAt;
  const VesselReadingRow(
      {required this.inputHash,
      required this.positionKey,
      required this.createdAt,
      required this.contentJson,
      required this.model,
      this.syncedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['input_hash'] = Variable<String>(inputHash);
    map['position_key'] = Variable<String>(positionKey);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['content_json'] = Variable<String>(contentJson);
    map['model'] = Variable<String>(model);
    if (!nullToAbsent || syncedAt != null) {
      map['synced_at'] = Variable<DateTime>(syncedAt);
    }
    return map;
  }

  VesselReadingsCompanion toCompanion(bool nullToAbsent) {
    return VesselReadingsCompanion(
      inputHash: Value(inputHash),
      positionKey: Value(positionKey),
      createdAt: Value(createdAt),
      contentJson: Value(contentJson),
      model: Value(model),
      syncedAt: syncedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(syncedAt),
    );
  }

  factory VesselReadingRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return VesselReadingRow(
      inputHash: serializer.fromJson<String>(json['inputHash']),
      positionKey: serializer.fromJson<String>(json['positionKey']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      contentJson: serializer.fromJson<String>(json['contentJson']),
      model: serializer.fromJson<String>(json['model']),
      syncedAt: serializer.fromJson<DateTime?>(json['syncedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'inputHash': serializer.toJson<String>(inputHash),
      'positionKey': serializer.toJson<String>(positionKey),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'contentJson': serializer.toJson<String>(contentJson),
      'model': serializer.toJson<String>(model),
      'syncedAt': serializer.toJson<DateTime?>(syncedAt),
    };
  }

  VesselReadingRow copyWith(
          {String? inputHash,
          String? positionKey,
          DateTime? createdAt,
          String? contentJson,
          String? model,
          Value<DateTime?> syncedAt = const Value.absent()}) =>
      VesselReadingRow(
        inputHash: inputHash ?? this.inputHash,
        positionKey: positionKey ?? this.positionKey,
        createdAt: createdAt ?? this.createdAt,
        contentJson: contentJson ?? this.contentJson,
        model: model ?? this.model,
        syncedAt: syncedAt.present ? syncedAt.value : this.syncedAt,
      );
  VesselReadingRow copyWithCompanion(VesselReadingsCompanion data) {
    return VesselReadingRow(
      inputHash: data.inputHash.present ? data.inputHash.value : this.inputHash,
      positionKey:
          data.positionKey.present ? data.positionKey.value : this.positionKey,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      contentJson:
          data.contentJson.present ? data.contentJson.value : this.contentJson,
      model: data.model.present ? data.model.value : this.model,
      syncedAt: data.syncedAt.present ? data.syncedAt.value : this.syncedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('VesselReadingRow(')
          ..write('inputHash: $inputHash, ')
          ..write('positionKey: $positionKey, ')
          ..write('createdAt: $createdAt, ')
          ..write('contentJson: $contentJson, ')
          ..write('model: $model, ')
          ..write('syncedAt: $syncedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      inputHash, positionKey, createdAt, contentJson, model, syncedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is VesselReadingRow &&
          other.inputHash == this.inputHash &&
          other.positionKey == this.positionKey &&
          other.createdAt == this.createdAt &&
          other.contentJson == this.contentJson &&
          other.model == this.model &&
          other.syncedAt == this.syncedAt);
}

class VesselReadingsCompanion extends UpdateCompanion<VesselReadingRow> {
  final Value<String> inputHash;
  final Value<String> positionKey;
  final Value<DateTime> createdAt;
  final Value<String> contentJson;
  final Value<String> model;
  final Value<DateTime?> syncedAt;
  final Value<int> rowid;
  const VesselReadingsCompanion({
    this.inputHash = const Value.absent(),
    this.positionKey = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.contentJson = const Value.absent(),
    this.model = const Value.absent(),
    this.syncedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  VesselReadingsCompanion.insert({
    required String inputHash,
    required String positionKey,
    required DateTime createdAt,
    required String contentJson,
    required String model,
    this.syncedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : inputHash = Value(inputHash),
        positionKey = Value(positionKey),
        createdAt = Value(createdAt),
        contentJson = Value(contentJson),
        model = Value(model);
  static Insertable<VesselReadingRow> custom({
    Expression<String>? inputHash,
    Expression<String>? positionKey,
    Expression<DateTime>? createdAt,
    Expression<String>? contentJson,
    Expression<String>? model,
    Expression<DateTime>? syncedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (inputHash != null) 'input_hash': inputHash,
      if (positionKey != null) 'position_key': positionKey,
      if (createdAt != null) 'created_at': createdAt,
      if (contentJson != null) 'content_json': contentJson,
      if (model != null) 'model': model,
      if (syncedAt != null) 'synced_at': syncedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  VesselReadingsCompanion copyWith(
      {Value<String>? inputHash,
      Value<String>? positionKey,
      Value<DateTime>? createdAt,
      Value<String>? contentJson,
      Value<String>? model,
      Value<DateTime?>? syncedAt,
      Value<int>? rowid}) {
    return VesselReadingsCompanion(
      inputHash: inputHash ?? this.inputHash,
      positionKey: positionKey ?? this.positionKey,
      createdAt: createdAt ?? this.createdAt,
      contentJson: contentJson ?? this.contentJson,
      model: model ?? this.model,
      syncedAt: syncedAt ?? this.syncedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (inputHash.present) {
      map['input_hash'] = Variable<String>(inputHash.value);
    }
    if (positionKey.present) {
      map['position_key'] = Variable<String>(positionKey.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (contentJson.present) {
      map['content_json'] = Variable<String>(contentJson.value);
    }
    if (model.present) {
      map['model'] = Variable<String>(model.value);
    }
    if (syncedAt.present) {
      map['synced_at'] = Variable<DateTime>(syncedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('VesselReadingsCompanion(')
          ..write('inputHash: $inputHash, ')
          ..write('positionKey: $positionKey, ')
          ..write('createdAt: $createdAt, ')
          ..write('contentJson: $contentJson, ')
          ..write('model: $model, ')
          ..write('syncedAt: $syncedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $DailyCardsTable extends DailyCards
    with TableInfo<$DailyCardsTable, DailyCardRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DailyCardsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<String> date = GeneratedColumn<String>(
      'date', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _arcanaSlugMeta =
      const VerificationMeta('arcanaSlug');
  @override
  late final GeneratedColumn<String> arcanaSlug = GeneratedColumn<String>(
      'arcana_slug', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _reasonMeta = const VerificationMeta('reason');
  @override
  late final GeneratedColumn<String> reason = GeneratedColumn<String>(
      'reason', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _sourceJsonMeta =
      const VerificationMeta('sourceJson');
  @override
  late final GeneratedColumn<String> sourceJson = GeneratedColumn<String>(
      'source_json', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('{}'));
  static const VerificationMeta _syncedAtMeta =
      const VerificationMeta('syncedAt');
  @override
  late final GeneratedColumn<DateTime> syncedAt = GeneratedColumn<DateTime>(
      'synced_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns =>
      [date, arcanaSlug, reason, sourceJson, syncedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'daily_cards';
  @override
  VerificationContext validateIntegrity(Insertable<DailyCardRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('date')) {
      context.handle(
          _dateMeta, date.isAcceptableOrUnknown(data['date']!, _dateMeta));
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('arcana_slug')) {
      context.handle(
          _arcanaSlugMeta,
          arcanaSlug.isAcceptableOrUnknown(
              data['arcana_slug']!, _arcanaSlugMeta));
    } else if (isInserting) {
      context.missing(_arcanaSlugMeta);
    }
    if (data.containsKey('reason')) {
      context.handle(_reasonMeta,
          reason.isAcceptableOrUnknown(data['reason']!, _reasonMeta));
    } else if (isInserting) {
      context.missing(_reasonMeta);
    }
    if (data.containsKey('source_json')) {
      context.handle(
          _sourceJsonMeta,
          sourceJson.isAcceptableOrUnknown(
              data['source_json']!, _sourceJsonMeta));
    }
    if (data.containsKey('synced_at')) {
      context.handle(_syncedAtMeta,
          syncedAt.isAcceptableOrUnknown(data['synced_at']!, _syncedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {date};
  @override
  DailyCardRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DailyCardRow(
      date: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}date'])!,
      arcanaSlug: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}arcana_slug'])!,
      reason: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}reason'])!,
      sourceJson: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}source_json'])!,
      syncedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}synced_at']),
    );
  }

  @override
  $DailyCardsTable createAlias(String alias) {
    return $DailyCardsTable(attachedDatabase, alias);
  }
}

class DailyCardRow extends DataClass implements Insertable<DailyCardRow> {
  final String date;
  final String arcanaSlug;

  /// Why this card, in the app's own words. Shown when the user asks.
  final String reason;

  /// The inputs the selection weighed: transits, personal year, recent
  /// signals, previous cards. Inspectable, per the brief's requirement that
  /// personalization be structured rather than opaque.
  final String sourceJson;
  final DateTime? syncedAt;
  const DailyCardRow(
      {required this.date,
      required this.arcanaSlug,
      required this.reason,
      required this.sourceJson,
      this.syncedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['date'] = Variable<String>(date);
    map['arcana_slug'] = Variable<String>(arcanaSlug);
    map['reason'] = Variable<String>(reason);
    map['source_json'] = Variable<String>(sourceJson);
    if (!nullToAbsent || syncedAt != null) {
      map['synced_at'] = Variable<DateTime>(syncedAt);
    }
    return map;
  }

  DailyCardsCompanion toCompanion(bool nullToAbsent) {
    return DailyCardsCompanion(
      date: Value(date),
      arcanaSlug: Value(arcanaSlug),
      reason: Value(reason),
      sourceJson: Value(sourceJson),
      syncedAt: syncedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(syncedAt),
    );
  }

  factory DailyCardRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DailyCardRow(
      date: serializer.fromJson<String>(json['date']),
      arcanaSlug: serializer.fromJson<String>(json['arcanaSlug']),
      reason: serializer.fromJson<String>(json['reason']),
      sourceJson: serializer.fromJson<String>(json['sourceJson']),
      syncedAt: serializer.fromJson<DateTime?>(json['syncedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'date': serializer.toJson<String>(date),
      'arcanaSlug': serializer.toJson<String>(arcanaSlug),
      'reason': serializer.toJson<String>(reason),
      'sourceJson': serializer.toJson<String>(sourceJson),
      'syncedAt': serializer.toJson<DateTime?>(syncedAt),
    };
  }

  DailyCardRow copyWith(
          {String? date,
          String? arcanaSlug,
          String? reason,
          String? sourceJson,
          Value<DateTime?> syncedAt = const Value.absent()}) =>
      DailyCardRow(
        date: date ?? this.date,
        arcanaSlug: arcanaSlug ?? this.arcanaSlug,
        reason: reason ?? this.reason,
        sourceJson: sourceJson ?? this.sourceJson,
        syncedAt: syncedAt.present ? syncedAt.value : this.syncedAt,
      );
  DailyCardRow copyWithCompanion(DailyCardsCompanion data) {
    return DailyCardRow(
      date: data.date.present ? data.date.value : this.date,
      arcanaSlug:
          data.arcanaSlug.present ? data.arcanaSlug.value : this.arcanaSlug,
      reason: data.reason.present ? data.reason.value : this.reason,
      sourceJson:
          data.sourceJson.present ? data.sourceJson.value : this.sourceJson,
      syncedAt: data.syncedAt.present ? data.syncedAt.value : this.syncedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DailyCardRow(')
          ..write('date: $date, ')
          ..write('arcanaSlug: $arcanaSlug, ')
          ..write('reason: $reason, ')
          ..write('sourceJson: $sourceJson, ')
          ..write('syncedAt: $syncedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(date, arcanaSlug, reason, sourceJson, syncedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DailyCardRow &&
          other.date == this.date &&
          other.arcanaSlug == this.arcanaSlug &&
          other.reason == this.reason &&
          other.sourceJson == this.sourceJson &&
          other.syncedAt == this.syncedAt);
}

class DailyCardsCompanion extends UpdateCompanion<DailyCardRow> {
  final Value<String> date;
  final Value<String> arcanaSlug;
  final Value<String> reason;
  final Value<String> sourceJson;
  final Value<DateTime?> syncedAt;
  final Value<int> rowid;
  const DailyCardsCompanion({
    this.date = const Value.absent(),
    this.arcanaSlug = const Value.absent(),
    this.reason = const Value.absent(),
    this.sourceJson = const Value.absent(),
    this.syncedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DailyCardsCompanion.insert({
    required String date,
    required String arcanaSlug,
    required String reason,
    this.sourceJson = const Value.absent(),
    this.syncedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : date = Value(date),
        arcanaSlug = Value(arcanaSlug),
        reason = Value(reason);
  static Insertable<DailyCardRow> custom({
    Expression<String>? date,
    Expression<String>? arcanaSlug,
    Expression<String>? reason,
    Expression<String>? sourceJson,
    Expression<DateTime>? syncedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (date != null) 'date': date,
      if (arcanaSlug != null) 'arcana_slug': arcanaSlug,
      if (reason != null) 'reason': reason,
      if (sourceJson != null) 'source_json': sourceJson,
      if (syncedAt != null) 'synced_at': syncedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DailyCardsCompanion copyWith(
      {Value<String>? date,
      Value<String>? arcanaSlug,
      Value<String>? reason,
      Value<String>? sourceJson,
      Value<DateTime?>? syncedAt,
      Value<int>? rowid}) {
    return DailyCardsCompanion(
      date: date ?? this.date,
      arcanaSlug: arcanaSlug ?? this.arcanaSlug,
      reason: reason ?? this.reason,
      sourceJson: sourceJson ?? this.sourceJson,
      syncedAt: syncedAt ?? this.syncedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (date.present) {
      map['date'] = Variable<String>(date.value);
    }
    if (arcanaSlug.present) {
      map['arcana_slug'] = Variable<String>(arcanaSlug.value);
    }
    if (reason.present) {
      map['reason'] = Variable<String>(reason.value);
    }
    if (sourceJson.present) {
      map['source_json'] = Variable<String>(sourceJson.value);
    }
    if (syncedAt.present) {
      map['synced_at'] = Variable<DateTime>(syncedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DailyCardsCompanion(')
          ..write('date: $date, ')
          ..write('arcanaSlug: $arcanaSlug, ')
          ..write('reason: $reason, ')
          ..write('sourceJson: $sourceJson, ')
          ..write('syncedAt: $syncedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PatternCandidatesTable extends PatternCandidates
    with TableInfo<$PatternCandidatesTable, PatternCandidateRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PatternCandidatesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
      'key', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _computedAtMeta =
      const VerificationMeta('computedAt');
  @override
  late final GeneratedColumn<DateTime> computedAt = GeneratedColumn<DateTime>(
      'computed_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _summaryMeta =
      const VerificationMeta('summary');
  @override
  late final GeneratedColumn<String> summary = GeneratedColumn<String>(
      'summary', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _evidenceJsonMeta =
      const VerificationMeta('evidenceJson');
  @override
  late final GeneratedColumn<String> evidenceJson = GeneratedColumn<String>(
      'evidence_json', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _confidenceMeta =
      const VerificationMeta('confidence');
  @override
  late final GeneratedColumn<double> confidence = GeneratedColumn<double>(
      'confidence', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
      'status', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('active'));
  @override
  List<GeneratedColumn> get $columns =>
      [key, computedAt, summary, evidenceJson, confidence, status];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'pattern_candidates';
  @override
  VerificationContext validateIntegrity(
      Insertable<PatternCandidateRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(
          _keyMeta, key.isAcceptableOrUnknown(data['key']!, _keyMeta));
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('computed_at')) {
      context.handle(
          _computedAtMeta,
          computedAt.isAcceptableOrUnknown(
              data['computed_at']!, _computedAtMeta));
    } else if (isInserting) {
      context.missing(_computedAtMeta);
    }
    if (data.containsKey('summary')) {
      context.handle(_summaryMeta,
          summary.isAcceptableOrUnknown(data['summary']!, _summaryMeta));
    } else if (isInserting) {
      context.missing(_summaryMeta);
    }
    if (data.containsKey('evidence_json')) {
      context.handle(
          _evidenceJsonMeta,
          evidenceJson.isAcceptableOrUnknown(
              data['evidence_json']!, _evidenceJsonMeta));
    } else if (isInserting) {
      context.missing(_evidenceJsonMeta);
    }
    if (data.containsKey('confidence')) {
      context.handle(
          _confidenceMeta,
          confidence.isAcceptableOrUnknown(
              data['confidence']!, _confidenceMeta));
    } else if (isInserting) {
      context.missing(_confidenceMeta);
    }
    if (data.containsKey('status')) {
      context.handle(_statusMeta,
          status.isAcceptableOrUnknown(data['status']!, _statusMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  PatternCandidateRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PatternCandidateRow(
      key: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}key'])!,
      computedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}computed_at'])!,
      summary: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}summary'])!,
      evidenceJson: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}evidence_json'])!,
      confidence: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}confidence'])!,
      status: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}status'])!,
    );
  }

  @override
  $PatternCandidatesTable createAlias(String alias) {
    return $PatternCandidatesTable(attachedDatabase, alias);
  }
}

class PatternCandidateRow extends DataClass
    implements Insertable<PatternCandidateRow> {
  final String key;
  final DateTime computedAt;
  final String summary;
  final String evidenceJson;
  final double confidence;

  /// `active` | `dismissed`. A dismissed pattern must not reach the model.
  final String status;
  const PatternCandidateRow(
      {required this.key,
      required this.computedAt,
      required this.summary,
      required this.evidenceJson,
      required this.confidence,
      required this.status});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['computed_at'] = Variable<DateTime>(computedAt);
    map['summary'] = Variable<String>(summary);
    map['evidence_json'] = Variable<String>(evidenceJson);
    map['confidence'] = Variable<double>(confidence);
    map['status'] = Variable<String>(status);
    return map;
  }

  PatternCandidatesCompanion toCompanion(bool nullToAbsent) {
    return PatternCandidatesCompanion(
      key: Value(key),
      computedAt: Value(computedAt),
      summary: Value(summary),
      evidenceJson: Value(evidenceJson),
      confidence: Value(confidence),
      status: Value(status),
    );
  }

  factory PatternCandidateRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PatternCandidateRow(
      key: serializer.fromJson<String>(json['key']),
      computedAt: serializer.fromJson<DateTime>(json['computedAt']),
      summary: serializer.fromJson<String>(json['summary']),
      evidenceJson: serializer.fromJson<String>(json['evidenceJson']),
      confidence: serializer.fromJson<double>(json['confidence']),
      status: serializer.fromJson<String>(json['status']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'computedAt': serializer.toJson<DateTime>(computedAt),
      'summary': serializer.toJson<String>(summary),
      'evidenceJson': serializer.toJson<String>(evidenceJson),
      'confidence': serializer.toJson<double>(confidence),
      'status': serializer.toJson<String>(status),
    };
  }

  PatternCandidateRow copyWith(
          {String? key,
          DateTime? computedAt,
          String? summary,
          String? evidenceJson,
          double? confidence,
          String? status}) =>
      PatternCandidateRow(
        key: key ?? this.key,
        computedAt: computedAt ?? this.computedAt,
        summary: summary ?? this.summary,
        evidenceJson: evidenceJson ?? this.evidenceJson,
        confidence: confidence ?? this.confidence,
        status: status ?? this.status,
      );
  PatternCandidateRow copyWithCompanion(PatternCandidatesCompanion data) {
    return PatternCandidateRow(
      key: data.key.present ? data.key.value : this.key,
      computedAt:
          data.computedAt.present ? data.computedAt.value : this.computedAt,
      summary: data.summary.present ? data.summary.value : this.summary,
      evidenceJson: data.evidenceJson.present
          ? data.evidenceJson.value
          : this.evidenceJson,
      confidence:
          data.confidence.present ? data.confidence.value : this.confidence,
      status: data.status.present ? data.status.value : this.status,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PatternCandidateRow(')
          ..write('key: $key, ')
          ..write('computedAt: $computedAt, ')
          ..write('summary: $summary, ')
          ..write('evidenceJson: $evidenceJson, ')
          ..write('confidence: $confidence, ')
          ..write('status: $status')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(key, computedAt, summary, evidenceJson, confidence, status);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PatternCandidateRow &&
          other.key == this.key &&
          other.computedAt == this.computedAt &&
          other.summary == this.summary &&
          other.evidenceJson == this.evidenceJson &&
          other.confidence == this.confidence &&
          other.status == this.status);
}

class PatternCandidatesCompanion extends UpdateCompanion<PatternCandidateRow> {
  final Value<String> key;
  final Value<DateTime> computedAt;
  final Value<String> summary;
  final Value<String> evidenceJson;
  final Value<double> confidence;
  final Value<String> status;
  final Value<int> rowid;
  const PatternCandidatesCompanion({
    this.key = const Value.absent(),
    this.computedAt = const Value.absent(),
    this.summary = const Value.absent(),
    this.evidenceJson = const Value.absent(),
    this.confidence = const Value.absent(),
    this.status = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PatternCandidatesCompanion.insert({
    required String key,
    required DateTime computedAt,
    required String summary,
    required String evidenceJson,
    required double confidence,
    this.status = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : key = Value(key),
        computedAt = Value(computedAt),
        summary = Value(summary),
        evidenceJson = Value(evidenceJson),
        confidence = Value(confidence);
  static Insertable<PatternCandidateRow> custom({
    Expression<String>? key,
    Expression<DateTime>? computedAt,
    Expression<String>? summary,
    Expression<String>? evidenceJson,
    Expression<double>? confidence,
    Expression<String>? status,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (computedAt != null) 'computed_at': computedAt,
      if (summary != null) 'summary': summary,
      if (evidenceJson != null) 'evidence_json': evidenceJson,
      if (confidence != null) 'confidence': confidence,
      if (status != null) 'status': status,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PatternCandidatesCompanion copyWith(
      {Value<String>? key,
      Value<DateTime>? computedAt,
      Value<String>? summary,
      Value<String>? evidenceJson,
      Value<double>? confidence,
      Value<String>? status,
      Value<int>? rowid}) {
    return PatternCandidatesCompanion(
      key: key ?? this.key,
      computedAt: computedAt ?? this.computedAt,
      summary: summary ?? this.summary,
      evidenceJson: evidenceJson ?? this.evidenceJson,
      confidence: confidence ?? this.confidence,
      status: status ?? this.status,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (computedAt.present) {
      map['computed_at'] = Variable<DateTime>(computedAt.value);
    }
    if (summary.present) {
      map['summary'] = Variable<String>(summary.value);
    }
    if (evidenceJson.present) {
      map['evidence_json'] = Variable<String>(evidenceJson.value);
    }
    if (confidence.present) {
      map['confidence'] = Variable<double>(confidence.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PatternCandidatesCompanion(')
          ..write('key: $key, ')
          ..write('computedAt: $computedAt, ')
          ..write('summary: $summary, ')
          ..write('evidenceJson: $evidenceJson, ')
          ..write('confidence: $confidence, ')
          ..write('status: $status, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $RetrospectivesTable extends Retrospectives
    with TableInfo<$RetrospectivesTable, RetrospectiveRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RetrospectivesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _kindMeta = const VerificationMeta('kind');
  @override
  late final GeneratedColumn<String> kind = GeneratedColumn<String>(
      'kind', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _periodStartMeta =
      const VerificationMeta('periodStart');
  @override
  late final GeneratedColumn<String> periodStart = GeneratedColumn<String>(
      'period_start', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _periodEndMeta =
      const VerificationMeta('periodEnd');
  @override
  late final GeneratedColumn<String> periodEnd = GeneratedColumn<String>(
      'period_end', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _generatedAtMeta =
      const VerificationMeta('generatedAt');
  @override
  late final GeneratedColumn<DateTime> generatedAt = GeneratedColumn<DateTime>(
      'generated_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _contentJsonMeta =
      const VerificationMeta('contentJson');
  @override
  late final GeneratedColumn<String> contentJson = GeneratedColumn<String>(
      'content_json', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _evidenceJsonMeta =
      const VerificationMeta('evidenceJson');
  @override
  late final GeneratedColumn<String> evidenceJson = GeneratedColumn<String>(
      'evidence_json', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _modelMeta = const VerificationMeta('model');
  @override
  late final GeneratedColumn<String> model = GeneratedColumn<String>(
      'model', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _syncedAtMeta =
      const VerificationMeta('syncedAt');
  @override
  late final GeneratedColumn<DateTime> syncedAt = GeneratedColumn<DateTime>(
      'synced_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        kind,
        periodStart,
        periodEnd,
        generatedAt,
        contentJson,
        evidenceJson,
        model,
        syncedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'retrospectives';
  @override
  VerificationContext validateIntegrity(Insertable<RetrospectiveRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('kind')) {
      context.handle(
          _kindMeta, kind.isAcceptableOrUnknown(data['kind']!, _kindMeta));
    } else if (isInserting) {
      context.missing(_kindMeta);
    }
    if (data.containsKey('period_start')) {
      context.handle(
          _periodStartMeta,
          periodStart.isAcceptableOrUnknown(
              data['period_start']!, _periodStartMeta));
    } else if (isInserting) {
      context.missing(_periodStartMeta);
    }
    if (data.containsKey('period_end')) {
      context.handle(_periodEndMeta,
          periodEnd.isAcceptableOrUnknown(data['period_end']!, _periodEndMeta));
    } else if (isInserting) {
      context.missing(_periodEndMeta);
    }
    if (data.containsKey('generated_at')) {
      context.handle(
          _generatedAtMeta,
          generatedAt.isAcceptableOrUnknown(
              data['generated_at']!, _generatedAtMeta));
    } else if (isInserting) {
      context.missing(_generatedAtMeta);
    }
    if (data.containsKey('content_json')) {
      context.handle(
          _contentJsonMeta,
          contentJson.isAcceptableOrUnknown(
              data['content_json']!, _contentJsonMeta));
    } else if (isInserting) {
      context.missing(_contentJsonMeta);
    }
    if (data.containsKey('evidence_json')) {
      context.handle(
          _evidenceJsonMeta,
          evidenceJson.isAcceptableOrUnknown(
              data['evidence_json']!, _evidenceJsonMeta));
    }
    if (data.containsKey('model')) {
      context.handle(
          _modelMeta, model.isAcceptableOrUnknown(data['model']!, _modelMeta));
    } else if (isInserting) {
      context.missing(_modelMeta);
    }
    if (data.containsKey('synced_at')) {
      context.handle(_syncedAtMeta,
          syncedAt.isAcceptableOrUnknown(data['synced_at']!, _syncedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  RetrospectiveRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return RetrospectiveRow(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      kind: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}kind'])!,
      periodStart: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}period_start'])!,
      periodEnd: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}period_end'])!,
      generatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}generated_at'])!,
      contentJson: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}content_json'])!,
      evidenceJson: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}evidence_json']),
      model: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}model'])!,
      syncedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}synced_at']),
    );
  }

  @override
  $RetrospectivesTable createAlias(String alias) {
    return $RetrospectivesTable(attachedDatabase, alias);
  }
}

class RetrospectiveRow extends DataClass
    implements Insertable<RetrospectiveRow> {
  final String id;

  /// `weekly` | `monthly` | `biannual`.
  final String kind;
  final String periodStart;
  final String periodEnd;
  final DateTime generatedAt;
  final String contentJson;
  final String? evidenceJson;
  final String model;
  final DateTime? syncedAt;
  const RetrospectiveRow(
      {required this.id,
      required this.kind,
      required this.periodStart,
      required this.periodEnd,
      required this.generatedAt,
      required this.contentJson,
      this.evidenceJson,
      required this.model,
      this.syncedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['kind'] = Variable<String>(kind);
    map['period_start'] = Variable<String>(periodStart);
    map['period_end'] = Variable<String>(periodEnd);
    map['generated_at'] = Variable<DateTime>(generatedAt);
    map['content_json'] = Variable<String>(contentJson);
    if (!nullToAbsent || evidenceJson != null) {
      map['evidence_json'] = Variable<String>(evidenceJson);
    }
    map['model'] = Variable<String>(model);
    if (!nullToAbsent || syncedAt != null) {
      map['synced_at'] = Variable<DateTime>(syncedAt);
    }
    return map;
  }

  RetrospectivesCompanion toCompanion(bool nullToAbsent) {
    return RetrospectivesCompanion(
      id: Value(id),
      kind: Value(kind),
      periodStart: Value(periodStart),
      periodEnd: Value(periodEnd),
      generatedAt: Value(generatedAt),
      contentJson: Value(contentJson),
      evidenceJson: evidenceJson == null && nullToAbsent
          ? const Value.absent()
          : Value(evidenceJson),
      model: Value(model),
      syncedAt: syncedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(syncedAt),
    );
  }

  factory RetrospectiveRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return RetrospectiveRow(
      id: serializer.fromJson<String>(json['id']),
      kind: serializer.fromJson<String>(json['kind']),
      periodStart: serializer.fromJson<String>(json['periodStart']),
      periodEnd: serializer.fromJson<String>(json['periodEnd']),
      generatedAt: serializer.fromJson<DateTime>(json['generatedAt']),
      contentJson: serializer.fromJson<String>(json['contentJson']),
      evidenceJson: serializer.fromJson<String?>(json['evidenceJson']),
      model: serializer.fromJson<String>(json['model']),
      syncedAt: serializer.fromJson<DateTime?>(json['syncedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'kind': serializer.toJson<String>(kind),
      'periodStart': serializer.toJson<String>(periodStart),
      'periodEnd': serializer.toJson<String>(periodEnd),
      'generatedAt': serializer.toJson<DateTime>(generatedAt),
      'contentJson': serializer.toJson<String>(contentJson),
      'evidenceJson': serializer.toJson<String?>(evidenceJson),
      'model': serializer.toJson<String>(model),
      'syncedAt': serializer.toJson<DateTime?>(syncedAt),
    };
  }

  RetrospectiveRow copyWith(
          {String? id,
          String? kind,
          String? periodStart,
          String? periodEnd,
          DateTime? generatedAt,
          String? contentJson,
          Value<String?> evidenceJson = const Value.absent(),
          String? model,
          Value<DateTime?> syncedAt = const Value.absent()}) =>
      RetrospectiveRow(
        id: id ?? this.id,
        kind: kind ?? this.kind,
        periodStart: periodStart ?? this.periodStart,
        periodEnd: periodEnd ?? this.periodEnd,
        generatedAt: generatedAt ?? this.generatedAt,
        contentJson: contentJson ?? this.contentJson,
        evidenceJson:
            evidenceJson.present ? evidenceJson.value : this.evidenceJson,
        model: model ?? this.model,
        syncedAt: syncedAt.present ? syncedAt.value : this.syncedAt,
      );
  RetrospectiveRow copyWithCompanion(RetrospectivesCompanion data) {
    return RetrospectiveRow(
      id: data.id.present ? data.id.value : this.id,
      kind: data.kind.present ? data.kind.value : this.kind,
      periodStart:
          data.periodStart.present ? data.periodStart.value : this.periodStart,
      periodEnd: data.periodEnd.present ? data.periodEnd.value : this.periodEnd,
      generatedAt:
          data.generatedAt.present ? data.generatedAt.value : this.generatedAt,
      contentJson:
          data.contentJson.present ? data.contentJson.value : this.contentJson,
      evidenceJson: data.evidenceJson.present
          ? data.evidenceJson.value
          : this.evidenceJson,
      model: data.model.present ? data.model.value : this.model,
      syncedAt: data.syncedAt.present ? data.syncedAt.value : this.syncedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('RetrospectiveRow(')
          ..write('id: $id, ')
          ..write('kind: $kind, ')
          ..write('periodStart: $periodStart, ')
          ..write('periodEnd: $periodEnd, ')
          ..write('generatedAt: $generatedAt, ')
          ..write('contentJson: $contentJson, ')
          ..write('evidenceJson: $evidenceJson, ')
          ..write('model: $model, ')
          ..write('syncedAt: $syncedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, kind, periodStart, periodEnd, generatedAt,
      contentJson, evidenceJson, model, syncedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RetrospectiveRow &&
          other.id == this.id &&
          other.kind == this.kind &&
          other.periodStart == this.periodStart &&
          other.periodEnd == this.periodEnd &&
          other.generatedAt == this.generatedAt &&
          other.contentJson == this.contentJson &&
          other.evidenceJson == this.evidenceJson &&
          other.model == this.model &&
          other.syncedAt == this.syncedAt);
}

class RetrospectivesCompanion extends UpdateCompanion<RetrospectiveRow> {
  final Value<String> id;
  final Value<String> kind;
  final Value<String> periodStart;
  final Value<String> periodEnd;
  final Value<DateTime> generatedAt;
  final Value<String> contentJson;
  final Value<String?> evidenceJson;
  final Value<String> model;
  final Value<DateTime?> syncedAt;
  final Value<int> rowid;
  const RetrospectivesCompanion({
    this.id = const Value.absent(),
    this.kind = const Value.absent(),
    this.periodStart = const Value.absent(),
    this.periodEnd = const Value.absent(),
    this.generatedAt = const Value.absent(),
    this.contentJson = const Value.absent(),
    this.evidenceJson = const Value.absent(),
    this.model = const Value.absent(),
    this.syncedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  RetrospectivesCompanion.insert({
    required String id,
    required String kind,
    required String periodStart,
    required String periodEnd,
    required DateTime generatedAt,
    required String contentJson,
    this.evidenceJson = const Value.absent(),
    required String model,
    this.syncedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        kind = Value(kind),
        periodStart = Value(periodStart),
        periodEnd = Value(periodEnd),
        generatedAt = Value(generatedAt),
        contentJson = Value(contentJson),
        model = Value(model);
  static Insertable<RetrospectiveRow> custom({
    Expression<String>? id,
    Expression<String>? kind,
    Expression<String>? periodStart,
    Expression<String>? periodEnd,
    Expression<DateTime>? generatedAt,
    Expression<String>? contentJson,
    Expression<String>? evidenceJson,
    Expression<String>? model,
    Expression<DateTime>? syncedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (kind != null) 'kind': kind,
      if (periodStart != null) 'period_start': periodStart,
      if (periodEnd != null) 'period_end': periodEnd,
      if (generatedAt != null) 'generated_at': generatedAt,
      if (contentJson != null) 'content_json': contentJson,
      if (evidenceJson != null) 'evidence_json': evidenceJson,
      if (model != null) 'model': model,
      if (syncedAt != null) 'synced_at': syncedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  RetrospectivesCompanion copyWith(
      {Value<String>? id,
      Value<String>? kind,
      Value<String>? periodStart,
      Value<String>? periodEnd,
      Value<DateTime>? generatedAt,
      Value<String>? contentJson,
      Value<String?>? evidenceJson,
      Value<String>? model,
      Value<DateTime?>? syncedAt,
      Value<int>? rowid}) {
    return RetrospectivesCompanion(
      id: id ?? this.id,
      kind: kind ?? this.kind,
      periodStart: periodStart ?? this.periodStart,
      periodEnd: periodEnd ?? this.periodEnd,
      generatedAt: generatedAt ?? this.generatedAt,
      contentJson: contentJson ?? this.contentJson,
      evidenceJson: evidenceJson ?? this.evidenceJson,
      model: model ?? this.model,
      syncedAt: syncedAt ?? this.syncedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(kind.value);
    }
    if (periodStart.present) {
      map['period_start'] = Variable<String>(periodStart.value);
    }
    if (periodEnd.present) {
      map['period_end'] = Variable<String>(periodEnd.value);
    }
    if (generatedAt.present) {
      map['generated_at'] = Variable<DateTime>(generatedAt.value);
    }
    if (contentJson.present) {
      map['content_json'] = Variable<String>(contentJson.value);
    }
    if (evidenceJson.present) {
      map['evidence_json'] = Variable<String>(evidenceJson.value);
    }
    if (model.present) {
      map['model'] = Variable<String>(model.value);
    }
    if (syncedAt.present) {
      map['synced_at'] = Variable<DateTime>(syncedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RetrospectivesCompanion(')
          ..write('id: $id, ')
          ..write('kind: $kind, ')
          ..write('periodStart: $periodStart, ')
          ..write('periodEnd: $periodEnd, ')
          ..write('generatedAt: $generatedAt, ')
          ..write('contentJson: $contentJson, ')
          ..write('evidenceJson: $evidenceJson, ')
          ..write('model: $model, ')
          ..write('syncedAt: $syncedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $IntakeAnswersTable extends IntakeAnswers
    with TableInfo<$IntakeAnswersTable, IntakeAnswerRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $IntakeAnswersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
      'key', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
      'value', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _tierMeta = const VerificationMeta('tier');
  @override
  late final GeneratedColumn<String> tier = GeneratedColumn<String>(
      'tier', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('optional'));
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _syncedAtMeta =
      const VerificationMeta('syncedAt');
  @override
  late final GeneratedColumn<DateTime> syncedAt = GeneratedColumn<DateTime>(
      'synced_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [key, value, tier, updatedAt, syncedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'intake_answers';
  @override
  VerificationContext validateIntegrity(Insertable<IntakeAnswerRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(
          _keyMeta, key.isAcceptableOrUnknown(data['key']!, _keyMeta));
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
          _valueMeta, value.isAcceptableOrUnknown(data['value']!, _valueMeta));
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    if (data.containsKey('tier')) {
      context.handle(
          _tierMeta, tier.isAcceptableOrUnknown(data['tier']!, _tierMeta));
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('synced_at')) {
      context.handle(_syncedAtMeta,
          syncedAt.isAcceptableOrUnknown(data['synced_at']!, _syncedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  IntakeAnswerRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return IntakeAnswerRow(
      key: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}key'])!,
      value: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}value'])!,
      tier: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}tier'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
      syncedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}synced_at']),
    );
  }

  @override
  $IntakeAnswersTable createAlias(String alias) {
    return $IntakeAnswersTable(attachedDatabase, alias);
  }
}

class IntakeAnswerRow extends DataClass implements Insertable<IntakeAnswerRow> {
  final String key;
  final String value;

  /// `essential` | `valuable` | `optional`. Mirrors the onboarding grading, so
  /// the prompt builder can weight what it includes and the Sanctum can show
  /// the user what they chose to give.
  final String tier;
  final DateTime updatedAt;
  final DateTime? syncedAt;
  const IntakeAnswerRow(
      {required this.key,
      required this.value,
      required this.tier,
      required this.updatedAt,
      this.syncedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['value'] = Variable<String>(value);
    map['tier'] = Variable<String>(tier);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || syncedAt != null) {
      map['synced_at'] = Variable<DateTime>(syncedAt);
    }
    return map;
  }

  IntakeAnswersCompanion toCompanion(bool nullToAbsent) {
    return IntakeAnswersCompanion(
      key: Value(key),
      value: Value(value),
      tier: Value(tier),
      updatedAt: Value(updatedAt),
      syncedAt: syncedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(syncedAt),
    );
  }

  factory IntakeAnswerRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return IntakeAnswerRow(
      key: serializer.fromJson<String>(json['key']),
      value: serializer.fromJson<String>(json['value']),
      tier: serializer.fromJson<String>(json['tier']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      syncedAt: serializer.fromJson<DateTime?>(json['syncedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'value': serializer.toJson<String>(value),
      'tier': serializer.toJson<String>(tier),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'syncedAt': serializer.toJson<DateTime?>(syncedAt),
    };
  }

  IntakeAnswerRow copyWith(
          {String? key,
          String? value,
          String? tier,
          DateTime? updatedAt,
          Value<DateTime?> syncedAt = const Value.absent()}) =>
      IntakeAnswerRow(
        key: key ?? this.key,
        value: value ?? this.value,
        tier: tier ?? this.tier,
        updatedAt: updatedAt ?? this.updatedAt,
        syncedAt: syncedAt.present ? syncedAt.value : this.syncedAt,
      );
  IntakeAnswerRow copyWithCompanion(IntakeAnswersCompanion data) {
    return IntakeAnswerRow(
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
      tier: data.tier.present ? data.tier.value : this.tier,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      syncedAt: data.syncedAt.present ? data.syncedAt.value : this.syncedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('IntakeAnswerRow(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('tier: $tier, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('syncedAt: $syncedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, value, tier, updatedAt, syncedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is IntakeAnswerRow &&
          other.key == this.key &&
          other.value == this.value &&
          other.tier == this.tier &&
          other.updatedAt == this.updatedAt &&
          other.syncedAt == this.syncedAt);
}

class IntakeAnswersCompanion extends UpdateCompanion<IntakeAnswerRow> {
  final Value<String> key;
  final Value<String> value;
  final Value<String> tier;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> syncedAt;
  final Value<int> rowid;
  const IntakeAnswersCompanion({
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.tier = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.syncedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  IntakeAnswersCompanion.insert({
    required String key,
    required String value,
    this.tier = const Value.absent(),
    required DateTime updatedAt,
    this.syncedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : key = Value(key),
        value = Value(value),
        updatedAt = Value(updatedAt);
  static Insertable<IntakeAnswerRow> custom({
    Expression<String>? key,
    Expression<String>? value,
    Expression<String>? tier,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? syncedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (value != null) 'value': value,
      if (tier != null) 'tier': tier,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (syncedAt != null) 'synced_at': syncedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  IntakeAnswersCompanion copyWith(
      {Value<String>? key,
      Value<String>? value,
      Value<String>? tier,
      Value<DateTime>? updatedAt,
      Value<DateTime?>? syncedAt,
      Value<int>? rowid}) {
    return IntakeAnswersCompanion(
      key: key ?? this.key,
      value: value ?? this.value,
      tier: tier ?? this.tier,
      updatedAt: updatedAt ?? this.updatedAt,
      syncedAt: syncedAt ?? this.syncedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
    }
    if (tier.present) {
      map['tier'] = Variable<String>(tier.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (syncedAt.present) {
      map['synced_at'] = Variable<DateTime>(syncedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('IntakeAnswersCompanion(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('tier: $tier, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('syncedAt: $syncedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $JournalDayStoriesTable extends JournalDayStories
    with TableInfo<$JournalDayStoriesTable, JournalDayStoryRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $JournalDayStoriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<String> date = GeneratedColumn<String>(
      'date', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _generatedAtMeta =
      const VerificationMeta('generatedAt');
  @override
  late final GeneratedColumn<DateTime> generatedAt = GeneratedColumn<DateTime>(
      'generated_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _storyMeta = const VerificationMeta('story');
  @override
  late final GeneratedColumn<String> story = GeneratedColumn<String>(
      'story', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _digestJsonMeta =
      const VerificationMeta('digestJson');
  @override
  late final GeneratedColumn<String> digestJson = GeneratedColumn<String>(
      'digest_json', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('{}'));
  static const VerificationMeta _entryCountMeta =
      const VerificationMeta('entryCount');
  @override
  late final GeneratedColumn<int> entryCount = GeneratedColumn<int>(
      'entry_count', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _sourceFingerprintMeta =
      const VerificationMeta('sourceFingerprint');
  @override
  late final GeneratedColumn<String> sourceFingerprint =
      GeneratedColumn<String>('source_fingerprint', aliasedName, false,
          type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _modelMeta = const VerificationMeta('model');
  @override
  late final GeneratedColumn<String> model = GeneratedColumn<String>(
      'model', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('provider'));
  static const VerificationMeta _syncedAtMeta =
      const VerificationMeta('syncedAt');
  @override
  late final GeneratedColumn<DateTime> syncedAt = GeneratedColumn<DateTime>(
      'synced_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        date,
        generatedAt,
        story,
        digestJson,
        entryCount,
        sourceFingerprint,
        model,
        syncedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'journal_day_stories';
  @override
  VerificationContext validateIntegrity(Insertable<JournalDayStoryRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('date')) {
      context.handle(
          _dateMeta, date.isAcceptableOrUnknown(data['date']!, _dateMeta));
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('generated_at')) {
      context.handle(
          _generatedAtMeta,
          generatedAt.isAcceptableOrUnknown(
              data['generated_at']!, _generatedAtMeta));
    } else if (isInserting) {
      context.missing(_generatedAtMeta);
    }
    if (data.containsKey('story')) {
      context.handle(
          _storyMeta, story.isAcceptableOrUnknown(data['story']!, _storyMeta));
    } else if (isInserting) {
      context.missing(_storyMeta);
    }
    if (data.containsKey('digest_json')) {
      context.handle(
          _digestJsonMeta,
          digestJson.isAcceptableOrUnknown(
              data['digest_json']!, _digestJsonMeta));
    }
    if (data.containsKey('entry_count')) {
      context.handle(
          _entryCountMeta,
          entryCount.isAcceptableOrUnknown(
              data['entry_count']!, _entryCountMeta));
    }
    if (data.containsKey('source_fingerprint')) {
      context.handle(
          _sourceFingerprintMeta,
          sourceFingerprint.isAcceptableOrUnknown(
              data['source_fingerprint']!, _sourceFingerprintMeta));
    } else if (isInserting) {
      context.missing(_sourceFingerprintMeta);
    }
    if (data.containsKey('model')) {
      context.handle(
          _modelMeta, model.isAcceptableOrUnknown(data['model']!, _modelMeta));
    }
    if (data.containsKey('synced_at')) {
      context.handle(_syncedAtMeta,
          syncedAt.isAcceptableOrUnknown(data['synced_at']!, _syncedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {date};
  @override
  JournalDayStoryRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return JournalDayStoryRow(
      date: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}date'])!,
      generatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}generated_at'])!,
      story: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}story'])!,
      digestJson: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}digest_json'])!,
      entryCount: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}entry_count'])!,
      sourceFingerprint: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}source_fingerprint'])!,
      model: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}model'])!,
      syncedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}synced_at']),
    );
  }

  @override
  $JournalDayStoriesTable createAlias(String alias) {
    return $JournalDayStoriesTable(attachedDatabase, alias);
  }
}

class JournalDayStoryRow extends DataClass
    implements Insertable<JournalDayStoryRow> {
  /// Local `YYYY-MM-DD`.
  final String date;
  final DateTime generatedAt;
  final String story;
  final String digestJson;
  final int entryCount;

  /// Hash of the prose this was derived from. An unchanged fingerprint means
  /// the story is current and no provider call is needed.
  final String sourceFingerprint;
  final String model;
  final DateTime? syncedAt;
  const JournalDayStoryRow(
      {required this.date,
      required this.generatedAt,
      required this.story,
      required this.digestJson,
      required this.entryCount,
      required this.sourceFingerprint,
      required this.model,
      this.syncedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['date'] = Variable<String>(date);
    map['generated_at'] = Variable<DateTime>(generatedAt);
    map['story'] = Variable<String>(story);
    map['digest_json'] = Variable<String>(digestJson);
    map['entry_count'] = Variable<int>(entryCount);
    map['source_fingerprint'] = Variable<String>(sourceFingerprint);
    map['model'] = Variable<String>(model);
    if (!nullToAbsent || syncedAt != null) {
      map['synced_at'] = Variable<DateTime>(syncedAt);
    }
    return map;
  }

  JournalDayStoriesCompanion toCompanion(bool nullToAbsent) {
    return JournalDayStoriesCompanion(
      date: Value(date),
      generatedAt: Value(generatedAt),
      story: Value(story),
      digestJson: Value(digestJson),
      entryCount: Value(entryCount),
      sourceFingerprint: Value(sourceFingerprint),
      model: Value(model),
      syncedAt: syncedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(syncedAt),
    );
  }

  factory JournalDayStoryRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return JournalDayStoryRow(
      date: serializer.fromJson<String>(json['date']),
      generatedAt: serializer.fromJson<DateTime>(json['generatedAt']),
      story: serializer.fromJson<String>(json['story']),
      digestJson: serializer.fromJson<String>(json['digestJson']),
      entryCount: serializer.fromJson<int>(json['entryCount']),
      sourceFingerprint: serializer.fromJson<String>(json['sourceFingerprint']),
      model: serializer.fromJson<String>(json['model']),
      syncedAt: serializer.fromJson<DateTime?>(json['syncedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'date': serializer.toJson<String>(date),
      'generatedAt': serializer.toJson<DateTime>(generatedAt),
      'story': serializer.toJson<String>(story),
      'digestJson': serializer.toJson<String>(digestJson),
      'entryCount': serializer.toJson<int>(entryCount),
      'sourceFingerprint': serializer.toJson<String>(sourceFingerprint),
      'model': serializer.toJson<String>(model),
      'syncedAt': serializer.toJson<DateTime?>(syncedAt),
    };
  }

  JournalDayStoryRow copyWith(
          {String? date,
          DateTime? generatedAt,
          String? story,
          String? digestJson,
          int? entryCount,
          String? sourceFingerprint,
          String? model,
          Value<DateTime?> syncedAt = const Value.absent()}) =>
      JournalDayStoryRow(
        date: date ?? this.date,
        generatedAt: generatedAt ?? this.generatedAt,
        story: story ?? this.story,
        digestJson: digestJson ?? this.digestJson,
        entryCount: entryCount ?? this.entryCount,
        sourceFingerprint: sourceFingerprint ?? this.sourceFingerprint,
        model: model ?? this.model,
        syncedAt: syncedAt.present ? syncedAt.value : this.syncedAt,
      );
  JournalDayStoryRow copyWithCompanion(JournalDayStoriesCompanion data) {
    return JournalDayStoryRow(
      date: data.date.present ? data.date.value : this.date,
      generatedAt:
          data.generatedAt.present ? data.generatedAt.value : this.generatedAt,
      story: data.story.present ? data.story.value : this.story,
      digestJson:
          data.digestJson.present ? data.digestJson.value : this.digestJson,
      entryCount:
          data.entryCount.present ? data.entryCount.value : this.entryCount,
      sourceFingerprint: data.sourceFingerprint.present
          ? data.sourceFingerprint.value
          : this.sourceFingerprint,
      model: data.model.present ? data.model.value : this.model,
      syncedAt: data.syncedAt.present ? data.syncedAt.value : this.syncedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('JournalDayStoryRow(')
          ..write('date: $date, ')
          ..write('generatedAt: $generatedAt, ')
          ..write('story: $story, ')
          ..write('digestJson: $digestJson, ')
          ..write('entryCount: $entryCount, ')
          ..write('sourceFingerprint: $sourceFingerprint, ')
          ..write('model: $model, ')
          ..write('syncedAt: $syncedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(date, generatedAt, story, digestJson,
      entryCount, sourceFingerprint, model, syncedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is JournalDayStoryRow &&
          other.date == this.date &&
          other.generatedAt == this.generatedAt &&
          other.story == this.story &&
          other.digestJson == this.digestJson &&
          other.entryCount == this.entryCount &&
          other.sourceFingerprint == this.sourceFingerprint &&
          other.model == this.model &&
          other.syncedAt == this.syncedAt);
}

class JournalDayStoriesCompanion extends UpdateCompanion<JournalDayStoryRow> {
  final Value<String> date;
  final Value<DateTime> generatedAt;
  final Value<String> story;
  final Value<String> digestJson;
  final Value<int> entryCount;
  final Value<String> sourceFingerprint;
  final Value<String> model;
  final Value<DateTime?> syncedAt;
  final Value<int> rowid;
  const JournalDayStoriesCompanion({
    this.date = const Value.absent(),
    this.generatedAt = const Value.absent(),
    this.story = const Value.absent(),
    this.digestJson = const Value.absent(),
    this.entryCount = const Value.absent(),
    this.sourceFingerprint = const Value.absent(),
    this.model = const Value.absent(),
    this.syncedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  JournalDayStoriesCompanion.insert({
    required String date,
    required DateTime generatedAt,
    required String story,
    this.digestJson = const Value.absent(),
    this.entryCount = const Value.absent(),
    required String sourceFingerprint,
    this.model = const Value.absent(),
    this.syncedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : date = Value(date),
        generatedAt = Value(generatedAt),
        story = Value(story),
        sourceFingerprint = Value(sourceFingerprint);
  static Insertable<JournalDayStoryRow> custom({
    Expression<String>? date,
    Expression<DateTime>? generatedAt,
    Expression<String>? story,
    Expression<String>? digestJson,
    Expression<int>? entryCount,
    Expression<String>? sourceFingerprint,
    Expression<String>? model,
    Expression<DateTime>? syncedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (date != null) 'date': date,
      if (generatedAt != null) 'generated_at': generatedAt,
      if (story != null) 'story': story,
      if (digestJson != null) 'digest_json': digestJson,
      if (entryCount != null) 'entry_count': entryCount,
      if (sourceFingerprint != null) 'source_fingerprint': sourceFingerprint,
      if (model != null) 'model': model,
      if (syncedAt != null) 'synced_at': syncedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  JournalDayStoriesCompanion copyWith(
      {Value<String>? date,
      Value<DateTime>? generatedAt,
      Value<String>? story,
      Value<String>? digestJson,
      Value<int>? entryCount,
      Value<String>? sourceFingerprint,
      Value<String>? model,
      Value<DateTime?>? syncedAt,
      Value<int>? rowid}) {
    return JournalDayStoriesCompanion(
      date: date ?? this.date,
      generatedAt: generatedAt ?? this.generatedAt,
      story: story ?? this.story,
      digestJson: digestJson ?? this.digestJson,
      entryCount: entryCount ?? this.entryCount,
      sourceFingerprint: sourceFingerprint ?? this.sourceFingerprint,
      model: model ?? this.model,
      syncedAt: syncedAt ?? this.syncedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (date.present) {
      map['date'] = Variable<String>(date.value);
    }
    if (generatedAt.present) {
      map['generated_at'] = Variable<DateTime>(generatedAt.value);
    }
    if (story.present) {
      map['story'] = Variable<String>(story.value);
    }
    if (digestJson.present) {
      map['digest_json'] = Variable<String>(digestJson.value);
    }
    if (entryCount.present) {
      map['entry_count'] = Variable<int>(entryCount.value);
    }
    if (sourceFingerprint.present) {
      map['source_fingerprint'] = Variable<String>(sourceFingerprint.value);
    }
    if (model.present) {
      map['model'] = Variable<String>(model.value);
    }
    if (syncedAt.present) {
      map['synced_at'] = Variable<DateTime>(syncedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('JournalDayStoriesCompanion(')
          ..write('date: $date, ')
          ..write('generatedAt: $generatedAt, ')
          ..write('story: $story, ')
          ..write('digestJson: $digestJson, ')
          ..write('entryCount: $entryCount, ')
          ..write('sourceFingerprint: $sourceFingerprint, ')
          ..write('model: $model, ')
          ..write('syncedAt: $syncedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $TransitReadingsTable extends TransitReadings
    with TableInfo<$TransitReadingsTable, TransitReadingRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TransitReadingsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<String> date = GeneratedColumn<String>(
      'date', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _inputHashMeta =
      const VerificationMeta('inputHash');
  @override
  late final GeneratedColumn<String> inputHash = GeneratedColumn<String>(
      'input_hash', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _generatedAtMeta =
      const VerificationMeta('generatedAt');
  @override
  late final GeneratedColumn<DateTime> generatedAt = GeneratedColumn<DateTime>(
      'generated_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _contactsJsonMeta =
      const VerificationMeta('contactsJson');
  @override
  late final GeneratedColumn<String> contactsJson = GeneratedColumn<String>(
      'contacts_json', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _passageMeta =
      const VerificationMeta('passage');
  @override
  late final GeneratedColumn<String> passage = GeneratedColumn<String>(
      'passage', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _modelMeta = const VerificationMeta('model');
  @override
  late final GeneratedColumn<String> model = GeneratedColumn<String>(
      'model', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('provider'));
  static const VerificationMeta _syncedAtMeta =
      const VerificationMeta('syncedAt');
  @override
  late final GeneratedColumn<DateTime> syncedAt = GeneratedColumn<DateTime>(
      'synced_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns =>
      [date, inputHash, generatedAt, contactsJson, passage, model, syncedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'transit_readings';
  @override
  VerificationContext validateIntegrity(Insertable<TransitReadingRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('date')) {
      context.handle(
          _dateMeta, date.isAcceptableOrUnknown(data['date']!, _dateMeta));
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('input_hash')) {
      context.handle(_inputHashMeta,
          inputHash.isAcceptableOrUnknown(data['input_hash']!, _inputHashMeta));
    } else if (isInserting) {
      context.missing(_inputHashMeta);
    }
    if (data.containsKey('generated_at')) {
      context.handle(
          _generatedAtMeta,
          generatedAt.isAcceptableOrUnknown(
              data['generated_at']!, _generatedAtMeta));
    } else if (isInserting) {
      context.missing(_generatedAtMeta);
    }
    if (data.containsKey('contacts_json')) {
      context.handle(
          _contactsJsonMeta,
          contactsJson.isAcceptableOrUnknown(
              data['contacts_json']!, _contactsJsonMeta));
    } else if (isInserting) {
      context.missing(_contactsJsonMeta);
    }
    if (data.containsKey('passage')) {
      context.handle(_passageMeta,
          passage.isAcceptableOrUnknown(data['passage']!, _passageMeta));
    } else if (isInserting) {
      context.missing(_passageMeta);
    }
    if (data.containsKey('model')) {
      context.handle(
          _modelMeta, model.isAcceptableOrUnknown(data['model']!, _modelMeta));
    }
    if (data.containsKey('synced_at')) {
      context.handle(_syncedAtMeta,
          syncedAt.isAcceptableOrUnknown(data['synced_at']!, _syncedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {date, inputHash};
  @override
  TransitReadingRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TransitReadingRow(
      date: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}date'])!,
      inputHash: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}input_hash'])!,
      generatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}generated_at'])!,
      contactsJson: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}contacts_json'])!,
      passage: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}passage'])!,
      model: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}model'])!,
      syncedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}synced_at']),
    );
  }

  @override
  $TransitReadingsTable createAlias(String alias) {
    return $TransitReadingsTable(attachedDatabase, alias);
  }
}

class TransitReadingRow extends DataClass
    implements Insertable<TransitReadingRow> {
  final String date;

  /// The same local chart hash the Vessel's readings use.
  final String inputHash;
  final DateTime generatedAt;

  /// The computed contacts, kept so a reading can be inspected against what it
  /// was written from.
  final String contactsJson;
  final String passage;
  final String model;
  final DateTime? syncedAt;
  const TransitReadingRow(
      {required this.date,
      required this.inputHash,
      required this.generatedAt,
      required this.contactsJson,
      required this.passage,
      required this.model,
      this.syncedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['date'] = Variable<String>(date);
    map['input_hash'] = Variable<String>(inputHash);
    map['generated_at'] = Variable<DateTime>(generatedAt);
    map['contacts_json'] = Variable<String>(contactsJson);
    map['passage'] = Variable<String>(passage);
    map['model'] = Variable<String>(model);
    if (!nullToAbsent || syncedAt != null) {
      map['synced_at'] = Variable<DateTime>(syncedAt);
    }
    return map;
  }

  TransitReadingsCompanion toCompanion(bool nullToAbsent) {
    return TransitReadingsCompanion(
      date: Value(date),
      inputHash: Value(inputHash),
      generatedAt: Value(generatedAt),
      contactsJson: Value(contactsJson),
      passage: Value(passage),
      model: Value(model),
      syncedAt: syncedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(syncedAt),
    );
  }

  factory TransitReadingRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TransitReadingRow(
      date: serializer.fromJson<String>(json['date']),
      inputHash: serializer.fromJson<String>(json['inputHash']),
      generatedAt: serializer.fromJson<DateTime>(json['generatedAt']),
      contactsJson: serializer.fromJson<String>(json['contactsJson']),
      passage: serializer.fromJson<String>(json['passage']),
      model: serializer.fromJson<String>(json['model']),
      syncedAt: serializer.fromJson<DateTime?>(json['syncedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'date': serializer.toJson<String>(date),
      'inputHash': serializer.toJson<String>(inputHash),
      'generatedAt': serializer.toJson<DateTime>(generatedAt),
      'contactsJson': serializer.toJson<String>(contactsJson),
      'passage': serializer.toJson<String>(passage),
      'model': serializer.toJson<String>(model),
      'syncedAt': serializer.toJson<DateTime?>(syncedAt),
    };
  }

  TransitReadingRow copyWith(
          {String? date,
          String? inputHash,
          DateTime? generatedAt,
          String? contactsJson,
          String? passage,
          String? model,
          Value<DateTime?> syncedAt = const Value.absent()}) =>
      TransitReadingRow(
        date: date ?? this.date,
        inputHash: inputHash ?? this.inputHash,
        generatedAt: generatedAt ?? this.generatedAt,
        contactsJson: contactsJson ?? this.contactsJson,
        passage: passage ?? this.passage,
        model: model ?? this.model,
        syncedAt: syncedAt.present ? syncedAt.value : this.syncedAt,
      );
  TransitReadingRow copyWithCompanion(TransitReadingsCompanion data) {
    return TransitReadingRow(
      date: data.date.present ? data.date.value : this.date,
      inputHash: data.inputHash.present ? data.inputHash.value : this.inputHash,
      generatedAt:
          data.generatedAt.present ? data.generatedAt.value : this.generatedAt,
      contactsJson: data.contactsJson.present
          ? data.contactsJson.value
          : this.contactsJson,
      passage: data.passage.present ? data.passage.value : this.passage,
      model: data.model.present ? data.model.value : this.model,
      syncedAt: data.syncedAt.present ? data.syncedAt.value : this.syncedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TransitReadingRow(')
          ..write('date: $date, ')
          ..write('inputHash: $inputHash, ')
          ..write('generatedAt: $generatedAt, ')
          ..write('contactsJson: $contactsJson, ')
          ..write('passage: $passage, ')
          ..write('model: $model, ')
          ..write('syncedAt: $syncedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      date, inputHash, generatedAt, contactsJson, passage, model, syncedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TransitReadingRow &&
          other.date == this.date &&
          other.inputHash == this.inputHash &&
          other.generatedAt == this.generatedAt &&
          other.contactsJson == this.contactsJson &&
          other.passage == this.passage &&
          other.model == this.model &&
          other.syncedAt == this.syncedAt);
}

class TransitReadingsCompanion extends UpdateCompanion<TransitReadingRow> {
  final Value<String> date;
  final Value<String> inputHash;
  final Value<DateTime> generatedAt;
  final Value<String> contactsJson;
  final Value<String> passage;
  final Value<String> model;
  final Value<DateTime?> syncedAt;
  final Value<int> rowid;
  const TransitReadingsCompanion({
    this.date = const Value.absent(),
    this.inputHash = const Value.absent(),
    this.generatedAt = const Value.absent(),
    this.contactsJson = const Value.absent(),
    this.passage = const Value.absent(),
    this.model = const Value.absent(),
    this.syncedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TransitReadingsCompanion.insert({
    required String date,
    required String inputHash,
    required DateTime generatedAt,
    required String contactsJson,
    required String passage,
    this.model = const Value.absent(),
    this.syncedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : date = Value(date),
        inputHash = Value(inputHash),
        generatedAt = Value(generatedAt),
        contactsJson = Value(contactsJson),
        passage = Value(passage);
  static Insertable<TransitReadingRow> custom({
    Expression<String>? date,
    Expression<String>? inputHash,
    Expression<DateTime>? generatedAt,
    Expression<String>? contactsJson,
    Expression<String>? passage,
    Expression<String>? model,
    Expression<DateTime>? syncedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (date != null) 'date': date,
      if (inputHash != null) 'input_hash': inputHash,
      if (generatedAt != null) 'generated_at': generatedAt,
      if (contactsJson != null) 'contacts_json': contactsJson,
      if (passage != null) 'passage': passage,
      if (model != null) 'model': model,
      if (syncedAt != null) 'synced_at': syncedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TransitReadingsCompanion copyWith(
      {Value<String>? date,
      Value<String>? inputHash,
      Value<DateTime>? generatedAt,
      Value<String>? contactsJson,
      Value<String>? passage,
      Value<String>? model,
      Value<DateTime?>? syncedAt,
      Value<int>? rowid}) {
    return TransitReadingsCompanion(
      date: date ?? this.date,
      inputHash: inputHash ?? this.inputHash,
      generatedAt: generatedAt ?? this.generatedAt,
      contactsJson: contactsJson ?? this.contactsJson,
      passage: passage ?? this.passage,
      model: model ?? this.model,
      syncedAt: syncedAt ?? this.syncedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (date.present) {
      map['date'] = Variable<String>(date.value);
    }
    if (inputHash.present) {
      map['input_hash'] = Variable<String>(inputHash.value);
    }
    if (generatedAt.present) {
      map['generated_at'] = Variable<DateTime>(generatedAt.value);
    }
    if (contactsJson.present) {
      map['contacts_json'] = Variable<String>(contactsJson.value);
    }
    if (passage.present) {
      map['passage'] = Variable<String>(passage.value);
    }
    if (model.present) {
      map['model'] = Variable<String>(model.value);
    }
    if (syncedAt.present) {
      map['synced_at'] = Variable<DateTime>(syncedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TransitReadingsCompanion(')
          ..write('date: $date, ')
          ..write('inputHash: $inputHash, ')
          ..write('generatedAt: $generatedAt, ')
          ..write('contactsJson: $contactsJson, ')
          ..write('passage: $passage, ')
          ..write('model: $model, ')
          ..write('syncedAt: $syncedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $ProfilesTable profiles = $ProfilesTable(this);
  late final $DaySummariesTable daySummaries = $DaySummariesTable(this);
  late final $RawBucketsTable rawBuckets = $RawBucketsTable(this);
  late final $MinuteBucketsTable minuteBuckets = $MinuteBucketsTable(this);
  late final $IntegrationsTable integrations = $IntegrationsTable(this);
  late final $SleepSegmentsTable sleepSegments = $SleepSegmentsTable(this);
  late final $DailyVitalsTable dailyVitals = $DailyVitalsTable(this);
  late final $ActivitySessionsTable activitySessions =
      $ActivitySessionsTable(this);
  late final $StrengthWorkoutsTable strengthWorkouts =
      $StrengthWorkoutsTable(this);
  late final $WeightEntriesTable weightEntries = $WeightEntriesTable(this);
  late final $NutritionEntriesTable nutritionEntries =
      $NutritionEntriesTable(this);
  late final $LiveSessionsTable liveSessions = $LiveSessionsTable(this);
  late final $RememberedSensorsTable rememberedSensors =
      $RememberedSensorsTable(this);
  late final $LifestyleEntriesTable lifestyleEntries =
      $LifestyleEntriesTable(this);
  late final $JournalEntriesTable journalEntries = $JournalEntriesTable(this);
  late final $GuidanceHistoryTable guidanceHistory =
      $GuidanceHistoryTable(this);
  late final $VesselReadingsTable vesselReadings = $VesselReadingsTable(this);
  late final $DailyCardsTable dailyCards = $DailyCardsTable(this);
  late final $PatternCandidatesTable patternCandidates =
      $PatternCandidatesTable(this);
  late final $RetrospectivesTable retrospectives = $RetrospectivesTable(this);
  late final $IntakeAnswersTable intakeAnswers = $IntakeAnswersTable(this);
  late final $JournalDayStoriesTable journalDayStories =
      $JournalDayStoriesTable(this);
  late final $TransitReadingsTable transitReadings =
      $TransitReadingsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
        profiles,
        daySummaries,
        rawBuckets,
        minuteBuckets,
        integrations,
        sleepSegments,
        dailyVitals,
        activitySessions,
        strengthWorkouts,
        weightEntries,
        nutritionEntries,
        liveSessions,
        rememberedSensors,
        lifestyleEntries,
        journalEntries,
        guidanceHistory,
        vesselReadings,
        dailyCards,
        patternCandidates,
        retrospectives,
        intakeAnswers,
        journalDayStories,
        transitReadings
      ];
}

typedef $$ProfilesTableCreateCompanionBuilder = ProfilesCompanion Function({
  Value<int> id,
  required DateTime dob,
  required String sex,
  required double weightKg,
  Value<double?> heightCm,
  Value<double?> bodyFatPercent,
  required String units,
  Value<String?> firstName,
  Value<bool> hapticsEnabled,
  Value<String> guidanceMode,
  Value<String> startSurface,
  Value<int?> birthTimeMinutes,
  Value<String> birthTimePrecision,
  Value<int?> birthUtcOffsetMinutes,
  Value<String?> birthPlace,
  Value<double?> birthLatitude,
  Value<double?> birthLongitude,
  Value<DateTime?> aiConsentAt,
  Value<DateTime?> journalAiConsentAt,
  Value<DateTime?> crashReportConsentAt,
  Value<DateTime?> cloudSyncConsentAt,
  Value<DateTime?> journalCloudSyncConsentAt,
  Value<String> connectedSourcesJson,
  Value<DateTime?> syncedAt,
});
typedef $$ProfilesTableUpdateCompanionBuilder = ProfilesCompanion Function({
  Value<int> id,
  Value<DateTime> dob,
  Value<String> sex,
  Value<double> weightKg,
  Value<double?> heightCm,
  Value<double?> bodyFatPercent,
  Value<String> units,
  Value<String?> firstName,
  Value<bool> hapticsEnabled,
  Value<String> guidanceMode,
  Value<String> startSurface,
  Value<int?> birthTimeMinutes,
  Value<String> birthTimePrecision,
  Value<int?> birthUtcOffsetMinutes,
  Value<String?> birthPlace,
  Value<double?> birthLatitude,
  Value<double?> birthLongitude,
  Value<DateTime?> aiConsentAt,
  Value<DateTime?> journalAiConsentAt,
  Value<DateTime?> crashReportConsentAt,
  Value<DateTime?> cloudSyncConsentAt,
  Value<DateTime?> journalCloudSyncConsentAt,
  Value<String> connectedSourcesJson,
  Value<DateTime?> syncedAt,
});

class $$ProfilesTableFilterComposer
    extends Composer<_$AppDatabase, $ProfilesTable> {
  $$ProfilesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get dob => $composableBuilder(
      column: $table.dob, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get sex => $composableBuilder(
      column: $table.sex, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get weightKg => $composableBuilder(
      column: $table.weightKg, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get heightCm => $composableBuilder(
      column: $table.heightCm, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get bodyFatPercent => $composableBuilder(
      column: $table.bodyFatPercent,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get units => $composableBuilder(
      column: $table.units, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get firstName => $composableBuilder(
      column: $table.firstName, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get hapticsEnabled => $composableBuilder(
      column: $table.hapticsEnabled,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get guidanceMode => $composableBuilder(
      column: $table.guidanceMode, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get startSurface => $composableBuilder(
      column: $table.startSurface, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get birthTimeMinutes => $composableBuilder(
      column: $table.birthTimeMinutes,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get birthTimePrecision => $composableBuilder(
      column: $table.birthTimePrecision,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get birthUtcOffsetMinutes => $composableBuilder(
      column: $table.birthUtcOffsetMinutes,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get birthPlace => $composableBuilder(
      column: $table.birthPlace, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get birthLatitude => $composableBuilder(
      column: $table.birthLatitude, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get birthLongitude => $composableBuilder(
      column: $table.birthLongitude,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get aiConsentAt => $composableBuilder(
      column: $table.aiConsentAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get journalAiConsentAt => $composableBuilder(
      column: $table.journalAiConsentAt,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get crashReportConsentAt => $composableBuilder(
      column: $table.crashReportConsentAt,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get cloudSyncConsentAt => $composableBuilder(
      column: $table.cloudSyncConsentAt,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get journalCloudSyncConsentAt => $composableBuilder(
      column: $table.journalCloudSyncConsentAt,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get connectedSourcesJson => $composableBuilder(
      column: $table.connectedSourcesJson,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get syncedAt => $composableBuilder(
      column: $table.syncedAt, builder: (column) => ColumnFilters(column));
}

class $$ProfilesTableOrderingComposer
    extends Composer<_$AppDatabase, $ProfilesTable> {
  $$ProfilesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get dob => $composableBuilder(
      column: $table.dob, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get sex => $composableBuilder(
      column: $table.sex, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get weightKg => $composableBuilder(
      column: $table.weightKg, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get heightCm => $composableBuilder(
      column: $table.heightCm, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get bodyFatPercent => $composableBuilder(
      column: $table.bodyFatPercent,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get units => $composableBuilder(
      column: $table.units, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get firstName => $composableBuilder(
      column: $table.firstName, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get hapticsEnabled => $composableBuilder(
      column: $table.hapticsEnabled,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get guidanceMode => $composableBuilder(
      column: $table.guidanceMode,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get startSurface => $composableBuilder(
      column: $table.startSurface,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get birthTimeMinutes => $composableBuilder(
      column: $table.birthTimeMinutes,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get birthTimePrecision => $composableBuilder(
      column: $table.birthTimePrecision,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get birthUtcOffsetMinutes => $composableBuilder(
      column: $table.birthUtcOffsetMinutes,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get birthPlace => $composableBuilder(
      column: $table.birthPlace, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get birthLatitude => $composableBuilder(
      column: $table.birthLatitude,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get birthLongitude => $composableBuilder(
      column: $table.birthLongitude,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get aiConsentAt => $composableBuilder(
      column: $table.aiConsentAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get journalAiConsentAt => $composableBuilder(
      column: $table.journalAiConsentAt,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get crashReportConsentAt => $composableBuilder(
      column: $table.crashReportConsentAt,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get cloudSyncConsentAt => $composableBuilder(
      column: $table.cloudSyncConsentAt,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get journalCloudSyncConsentAt => $composableBuilder(
      column: $table.journalCloudSyncConsentAt,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get connectedSourcesJson => $composableBuilder(
      column: $table.connectedSourcesJson,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get syncedAt => $composableBuilder(
      column: $table.syncedAt, builder: (column) => ColumnOrderings(column));
}

class $$ProfilesTableAnnotationComposer
    extends Composer<_$AppDatabase, $ProfilesTable> {
  $$ProfilesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get dob =>
      $composableBuilder(column: $table.dob, builder: (column) => column);

  GeneratedColumn<String> get sex =>
      $composableBuilder(column: $table.sex, builder: (column) => column);

  GeneratedColumn<double> get weightKg =>
      $composableBuilder(column: $table.weightKg, builder: (column) => column);

  GeneratedColumn<double> get heightCm =>
      $composableBuilder(column: $table.heightCm, builder: (column) => column);

  GeneratedColumn<double> get bodyFatPercent => $composableBuilder(
      column: $table.bodyFatPercent, builder: (column) => column);

  GeneratedColumn<String> get units =>
      $composableBuilder(column: $table.units, builder: (column) => column);

  GeneratedColumn<String> get firstName =>
      $composableBuilder(column: $table.firstName, builder: (column) => column);

  GeneratedColumn<bool> get hapticsEnabled => $composableBuilder(
      column: $table.hapticsEnabled, builder: (column) => column);

  GeneratedColumn<String> get guidanceMode => $composableBuilder(
      column: $table.guidanceMode, builder: (column) => column);

  GeneratedColumn<String> get startSurface => $composableBuilder(
      column: $table.startSurface, builder: (column) => column);

  GeneratedColumn<int> get birthTimeMinutes => $composableBuilder(
      column: $table.birthTimeMinutes, builder: (column) => column);

  GeneratedColumn<String> get birthTimePrecision => $composableBuilder(
      column: $table.birthTimePrecision, builder: (column) => column);

  GeneratedColumn<int> get birthUtcOffsetMinutes => $composableBuilder(
      column: $table.birthUtcOffsetMinutes, builder: (column) => column);

  GeneratedColumn<String> get birthPlace => $composableBuilder(
      column: $table.birthPlace, builder: (column) => column);

  GeneratedColumn<double> get birthLatitude => $composableBuilder(
      column: $table.birthLatitude, builder: (column) => column);

  GeneratedColumn<double> get birthLongitude => $composableBuilder(
      column: $table.birthLongitude, builder: (column) => column);

  GeneratedColumn<DateTime> get aiConsentAt => $composableBuilder(
      column: $table.aiConsentAt, builder: (column) => column);

  GeneratedColumn<DateTime> get journalAiConsentAt => $composableBuilder(
      column: $table.journalAiConsentAt, builder: (column) => column);

  GeneratedColumn<DateTime> get crashReportConsentAt => $composableBuilder(
      column: $table.crashReportConsentAt, builder: (column) => column);

  GeneratedColumn<DateTime> get cloudSyncConsentAt => $composableBuilder(
      column: $table.cloudSyncConsentAt, builder: (column) => column);

  GeneratedColumn<DateTime> get journalCloudSyncConsentAt => $composableBuilder(
      column: $table.journalCloudSyncConsentAt, builder: (column) => column);

  GeneratedColumn<String> get connectedSourcesJson => $composableBuilder(
      column: $table.connectedSourcesJson, builder: (column) => column);

  GeneratedColumn<DateTime> get syncedAt =>
      $composableBuilder(column: $table.syncedAt, builder: (column) => column);
}

class $$ProfilesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $ProfilesTable,
    ProfileRow,
    $$ProfilesTableFilterComposer,
    $$ProfilesTableOrderingComposer,
    $$ProfilesTableAnnotationComposer,
    $$ProfilesTableCreateCompanionBuilder,
    $$ProfilesTableUpdateCompanionBuilder,
    (ProfileRow, BaseReferences<_$AppDatabase, $ProfilesTable, ProfileRow>),
    ProfileRow,
    PrefetchHooks Function()> {
  $$ProfilesTableTableManager(_$AppDatabase db, $ProfilesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ProfilesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ProfilesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ProfilesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<DateTime> dob = const Value.absent(),
            Value<String> sex = const Value.absent(),
            Value<double> weightKg = const Value.absent(),
            Value<double?> heightCm = const Value.absent(),
            Value<double?> bodyFatPercent = const Value.absent(),
            Value<String> units = const Value.absent(),
            Value<String?> firstName = const Value.absent(),
            Value<bool> hapticsEnabled = const Value.absent(),
            Value<String> guidanceMode = const Value.absent(),
            Value<String> startSurface = const Value.absent(),
            Value<int?> birthTimeMinutes = const Value.absent(),
            Value<String> birthTimePrecision = const Value.absent(),
            Value<int?> birthUtcOffsetMinutes = const Value.absent(),
            Value<String?> birthPlace = const Value.absent(),
            Value<double?> birthLatitude = const Value.absent(),
            Value<double?> birthLongitude = const Value.absent(),
            Value<DateTime?> aiConsentAt = const Value.absent(),
            Value<DateTime?> journalAiConsentAt = const Value.absent(),
            Value<DateTime?> crashReportConsentAt = const Value.absent(),
            Value<DateTime?> cloudSyncConsentAt = const Value.absent(),
            Value<DateTime?> journalCloudSyncConsentAt = const Value.absent(),
            Value<String> connectedSourcesJson = const Value.absent(),
            Value<DateTime?> syncedAt = const Value.absent(),
          }) =>
              ProfilesCompanion(
            id: id,
            dob: dob,
            sex: sex,
            weightKg: weightKg,
            heightCm: heightCm,
            bodyFatPercent: bodyFatPercent,
            units: units,
            firstName: firstName,
            hapticsEnabled: hapticsEnabled,
            guidanceMode: guidanceMode,
            startSurface: startSurface,
            birthTimeMinutes: birthTimeMinutes,
            birthTimePrecision: birthTimePrecision,
            birthUtcOffsetMinutes: birthUtcOffsetMinutes,
            birthPlace: birthPlace,
            birthLatitude: birthLatitude,
            birthLongitude: birthLongitude,
            aiConsentAt: aiConsentAt,
            journalAiConsentAt: journalAiConsentAt,
            crashReportConsentAt: crashReportConsentAt,
            cloudSyncConsentAt: cloudSyncConsentAt,
            journalCloudSyncConsentAt: journalCloudSyncConsentAt,
            connectedSourcesJson: connectedSourcesJson,
            syncedAt: syncedAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required DateTime dob,
            required String sex,
            required double weightKg,
            Value<double?> heightCm = const Value.absent(),
            Value<double?> bodyFatPercent = const Value.absent(),
            required String units,
            Value<String?> firstName = const Value.absent(),
            Value<bool> hapticsEnabled = const Value.absent(),
            Value<String> guidanceMode = const Value.absent(),
            Value<String> startSurface = const Value.absent(),
            Value<int?> birthTimeMinutes = const Value.absent(),
            Value<String> birthTimePrecision = const Value.absent(),
            Value<int?> birthUtcOffsetMinutes = const Value.absent(),
            Value<String?> birthPlace = const Value.absent(),
            Value<double?> birthLatitude = const Value.absent(),
            Value<double?> birthLongitude = const Value.absent(),
            Value<DateTime?> aiConsentAt = const Value.absent(),
            Value<DateTime?> journalAiConsentAt = const Value.absent(),
            Value<DateTime?> crashReportConsentAt = const Value.absent(),
            Value<DateTime?> cloudSyncConsentAt = const Value.absent(),
            Value<DateTime?> journalCloudSyncConsentAt = const Value.absent(),
            Value<String> connectedSourcesJson = const Value.absent(),
            Value<DateTime?> syncedAt = const Value.absent(),
          }) =>
              ProfilesCompanion.insert(
            id: id,
            dob: dob,
            sex: sex,
            weightKg: weightKg,
            heightCm: heightCm,
            bodyFatPercent: bodyFatPercent,
            units: units,
            firstName: firstName,
            hapticsEnabled: hapticsEnabled,
            guidanceMode: guidanceMode,
            startSurface: startSurface,
            birthTimeMinutes: birthTimeMinutes,
            birthTimePrecision: birthTimePrecision,
            birthUtcOffsetMinutes: birthUtcOffsetMinutes,
            birthPlace: birthPlace,
            birthLatitude: birthLatitude,
            birthLongitude: birthLongitude,
            aiConsentAt: aiConsentAt,
            journalAiConsentAt: journalAiConsentAt,
            crashReportConsentAt: crashReportConsentAt,
            cloudSyncConsentAt: cloudSyncConsentAt,
            journalCloudSyncConsentAt: journalCloudSyncConsentAt,
            connectedSourcesJson: connectedSourcesJson,
            syncedAt: syncedAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$ProfilesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $ProfilesTable,
    ProfileRow,
    $$ProfilesTableFilterComposer,
    $$ProfilesTableOrderingComposer,
    $$ProfilesTableAnnotationComposer,
    $$ProfilesTableCreateCompanionBuilder,
    $$ProfilesTableUpdateCompanionBuilder,
    (ProfileRow, BaseReferences<_$AppDatabase, $ProfilesTable, ProfileRow>),
    ProfileRow,
    PrefetchHooks Function()>;
typedef $$DaySummariesTableCreateCompanionBuilder = DaySummariesCompanion
    Function({
  required String date,
  Value<double> activeKcal,
  Value<double> basalKcal,
  Value<double?> intakeKcal,
  Value<int> steps,
  Value<int> sessionsCount,
  Value<bool> recalibrated,
  Value<DateTime?> syncedAt,
  Value<int> rowid,
});
typedef $$DaySummariesTableUpdateCompanionBuilder = DaySummariesCompanion
    Function({
  Value<String> date,
  Value<double> activeKcal,
  Value<double> basalKcal,
  Value<double?> intakeKcal,
  Value<int> steps,
  Value<int> sessionsCount,
  Value<bool> recalibrated,
  Value<DateTime?> syncedAt,
  Value<int> rowid,
});

class $$DaySummariesTableFilterComposer
    extends Composer<_$AppDatabase, $DaySummariesTable> {
  $$DaySummariesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get date => $composableBuilder(
      column: $table.date, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get activeKcal => $composableBuilder(
      column: $table.activeKcal, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get basalKcal => $composableBuilder(
      column: $table.basalKcal, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get intakeKcal => $composableBuilder(
      column: $table.intakeKcal, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get steps => $composableBuilder(
      column: $table.steps, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get sessionsCount => $composableBuilder(
      column: $table.sessionsCount, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get recalibrated => $composableBuilder(
      column: $table.recalibrated, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get syncedAt => $composableBuilder(
      column: $table.syncedAt, builder: (column) => ColumnFilters(column));
}

class $$DaySummariesTableOrderingComposer
    extends Composer<_$AppDatabase, $DaySummariesTable> {
  $$DaySummariesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get date => $composableBuilder(
      column: $table.date, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get activeKcal => $composableBuilder(
      column: $table.activeKcal, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get basalKcal => $composableBuilder(
      column: $table.basalKcal, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get intakeKcal => $composableBuilder(
      column: $table.intakeKcal, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get steps => $composableBuilder(
      column: $table.steps, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get sessionsCount => $composableBuilder(
      column: $table.sessionsCount,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get recalibrated => $composableBuilder(
      column: $table.recalibrated,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get syncedAt => $composableBuilder(
      column: $table.syncedAt, builder: (column) => ColumnOrderings(column));
}

class $$DaySummariesTableAnnotationComposer
    extends Composer<_$AppDatabase, $DaySummariesTable> {
  $$DaySummariesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumn<double> get activeKcal => $composableBuilder(
      column: $table.activeKcal, builder: (column) => column);

  GeneratedColumn<double> get basalKcal =>
      $composableBuilder(column: $table.basalKcal, builder: (column) => column);

  GeneratedColumn<double> get intakeKcal => $composableBuilder(
      column: $table.intakeKcal, builder: (column) => column);

  GeneratedColumn<int> get steps =>
      $composableBuilder(column: $table.steps, builder: (column) => column);

  GeneratedColumn<int> get sessionsCount => $composableBuilder(
      column: $table.sessionsCount, builder: (column) => column);

  GeneratedColumn<bool> get recalibrated => $composableBuilder(
      column: $table.recalibrated, builder: (column) => column);

  GeneratedColumn<DateTime> get syncedAt =>
      $composableBuilder(column: $table.syncedAt, builder: (column) => column);
}

class $$DaySummariesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $DaySummariesTable,
    DaySummaryRow,
    $$DaySummariesTableFilterComposer,
    $$DaySummariesTableOrderingComposer,
    $$DaySummariesTableAnnotationComposer,
    $$DaySummariesTableCreateCompanionBuilder,
    $$DaySummariesTableUpdateCompanionBuilder,
    (
      DaySummaryRow,
      BaseReferences<_$AppDatabase, $DaySummariesTable, DaySummaryRow>
    ),
    DaySummaryRow,
    PrefetchHooks Function()> {
  $$DaySummariesTableTableManager(_$AppDatabase db, $DaySummariesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DaySummariesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DaySummariesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DaySummariesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> date = const Value.absent(),
            Value<double> activeKcal = const Value.absent(),
            Value<double> basalKcal = const Value.absent(),
            Value<double?> intakeKcal = const Value.absent(),
            Value<int> steps = const Value.absent(),
            Value<int> sessionsCount = const Value.absent(),
            Value<bool> recalibrated = const Value.absent(),
            Value<DateTime?> syncedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              DaySummariesCompanion(
            date: date,
            activeKcal: activeKcal,
            basalKcal: basalKcal,
            intakeKcal: intakeKcal,
            steps: steps,
            sessionsCount: sessionsCount,
            recalibrated: recalibrated,
            syncedAt: syncedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String date,
            Value<double> activeKcal = const Value.absent(),
            Value<double> basalKcal = const Value.absent(),
            Value<double?> intakeKcal = const Value.absent(),
            Value<int> steps = const Value.absent(),
            Value<int> sessionsCount = const Value.absent(),
            Value<bool> recalibrated = const Value.absent(),
            Value<DateTime?> syncedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              DaySummariesCompanion.insert(
            date: date,
            activeKcal: activeKcal,
            basalKcal: basalKcal,
            intakeKcal: intakeKcal,
            steps: steps,
            sessionsCount: sessionsCount,
            recalibrated: recalibrated,
            syncedAt: syncedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$DaySummariesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $DaySummariesTable,
    DaySummaryRow,
    $$DaySummariesTableFilterComposer,
    $$DaySummariesTableOrderingComposer,
    $$DaySummariesTableAnnotationComposer,
    $$DaySummariesTableCreateCompanionBuilder,
    $$DaySummariesTableUpdateCompanionBuilder,
    (
      DaySummaryRow,
      BaseReferences<_$AppDatabase, $DaySummariesTable, DaySummaryRow>
    ),
    DaySummaryRow,
    PrefetchHooks Function()>;
typedef $$RawBucketsTableCreateCompanionBuilder = RawBucketsCompanion Function({
  required DateTime minuteUtc,
  required String source,
  required double activeKcal,
  Value<int?> steps,
  Value<double?> avgHr,
  Value<int> hrSampleCount,
  required int priority,
  Value<String?> externalId,
  Value<int> rowid,
});
typedef $$RawBucketsTableUpdateCompanionBuilder = RawBucketsCompanion Function({
  Value<DateTime> minuteUtc,
  Value<String> source,
  Value<double> activeKcal,
  Value<int?> steps,
  Value<double?> avgHr,
  Value<int> hrSampleCount,
  Value<int> priority,
  Value<String?> externalId,
  Value<int> rowid,
});

class $$RawBucketsTableFilterComposer
    extends Composer<_$AppDatabase, $RawBucketsTable> {
  $$RawBucketsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<DateTime> get minuteUtc => $composableBuilder(
      column: $table.minuteUtc, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get source => $composableBuilder(
      column: $table.source, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get activeKcal => $composableBuilder(
      column: $table.activeKcal, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get steps => $composableBuilder(
      column: $table.steps, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get avgHr => $composableBuilder(
      column: $table.avgHr, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get hrSampleCount => $composableBuilder(
      column: $table.hrSampleCount, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get priority => $composableBuilder(
      column: $table.priority, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get externalId => $composableBuilder(
      column: $table.externalId, builder: (column) => ColumnFilters(column));
}

class $$RawBucketsTableOrderingComposer
    extends Composer<_$AppDatabase, $RawBucketsTable> {
  $$RawBucketsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<DateTime> get minuteUtc => $composableBuilder(
      column: $table.minuteUtc, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get source => $composableBuilder(
      column: $table.source, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get activeKcal => $composableBuilder(
      column: $table.activeKcal, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get steps => $composableBuilder(
      column: $table.steps, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get avgHr => $composableBuilder(
      column: $table.avgHr, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get hrSampleCount => $composableBuilder(
      column: $table.hrSampleCount,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get priority => $composableBuilder(
      column: $table.priority, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get externalId => $composableBuilder(
      column: $table.externalId, builder: (column) => ColumnOrderings(column));
}

class $$RawBucketsTableAnnotationComposer
    extends Composer<_$AppDatabase, $RawBucketsTable> {
  $$RawBucketsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<DateTime> get minuteUtc =>
      $composableBuilder(column: $table.minuteUtc, builder: (column) => column);

  GeneratedColumn<String> get source =>
      $composableBuilder(column: $table.source, builder: (column) => column);

  GeneratedColumn<double> get activeKcal => $composableBuilder(
      column: $table.activeKcal, builder: (column) => column);

  GeneratedColumn<int> get steps =>
      $composableBuilder(column: $table.steps, builder: (column) => column);

  GeneratedColumn<double> get avgHr =>
      $composableBuilder(column: $table.avgHr, builder: (column) => column);

  GeneratedColumn<int> get hrSampleCount => $composableBuilder(
      column: $table.hrSampleCount, builder: (column) => column);

  GeneratedColumn<int> get priority =>
      $composableBuilder(column: $table.priority, builder: (column) => column);

  GeneratedColumn<String> get externalId => $composableBuilder(
      column: $table.externalId, builder: (column) => column);
}

class $$RawBucketsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $RawBucketsTable,
    RawBucketRow,
    $$RawBucketsTableFilterComposer,
    $$RawBucketsTableOrderingComposer,
    $$RawBucketsTableAnnotationComposer,
    $$RawBucketsTableCreateCompanionBuilder,
    $$RawBucketsTableUpdateCompanionBuilder,
    (
      RawBucketRow,
      BaseReferences<_$AppDatabase, $RawBucketsTable, RawBucketRow>
    ),
    RawBucketRow,
    PrefetchHooks Function()> {
  $$RawBucketsTableTableManager(_$AppDatabase db, $RawBucketsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$RawBucketsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$RawBucketsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$RawBucketsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<DateTime> minuteUtc = const Value.absent(),
            Value<String> source = const Value.absent(),
            Value<double> activeKcal = const Value.absent(),
            Value<int?> steps = const Value.absent(),
            Value<double?> avgHr = const Value.absent(),
            Value<int> hrSampleCount = const Value.absent(),
            Value<int> priority = const Value.absent(),
            Value<String?> externalId = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              RawBucketsCompanion(
            minuteUtc: minuteUtc,
            source: source,
            activeKcal: activeKcal,
            steps: steps,
            avgHr: avgHr,
            hrSampleCount: hrSampleCount,
            priority: priority,
            externalId: externalId,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required DateTime minuteUtc,
            required String source,
            required double activeKcal,
            Value<int?> steps = const Value.absent(),
            Value<double?> avgHr = const Value.absent(),
            Value<int> hrSampleCount = const Value.absent(),
            required int priority,
            Value<String?> externalId = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              RawBucketsCompanion.insert(
            minuteUtc: minuteUtc,
            source: source,
            activeKcal: activeKcal,
            steps: steps,
            avgHr: avgHr,
            hrSampleCount: hrSampleCount,
            priority: priority,
            externalId: externalId,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$RawBucketsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $RawBucketsTable,
    RawBucketRow,
    $$RawBucketsTableFilterComposer,
    $$RawBucketsTableOrderingComposer,
    $$RawBucketsTableAnnotationComposer,
    $$RawBucketsTableCreateCompanionBuilder,
    $$RawBucketsTableUpdateCompanionBuilder,
    (
      RawBucketRow,
      BaseReferences<_$AppDatabase, $RawBucketsTable, RawBucketRow>
    ),
    RawBucketRow,
    PrefetchHooks Function()>;
typedef $$MinuteBucketsTableCreateCompanionBuilder = MinuteBucketsCompanion
    Function({
  required DateTime minuteUtc,
  required double activeKcal,
  Value<int?> steps,
  Value<double?> avgHr,
  required String winningSource,
  required String provenance,
  Value<int> rowid,
});
typedef $$MinuteBucketsTableUpdateCompanionBuilder = MinuteBucketsCompanion
    Function({
  Value<DateTime> minuteUtc,
  Value<double> activeKcal,
  Value<int?> steps,
  Value<double?> avgHr,
  Value<String> winningSource,
  Value<String> provenance,
  Value<int> rowid,
});

class $$MinuteBucketsTableFilterComposer
    extends Composer<_$AppDatabase, $MinuteBucketsTable> {
  $$MinuteBucketsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<DateTime> get minuteUtc => $composableBuilder(
      column: $table.minuteUtc, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get activeKcal => $composableBuilder(
      column: $table.activeKcal, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get steps => $composableBuilder(
      column: $table.steps, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get avgHr => $composableBuilder(
      column: $table.avgHr, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get winningSource => $composableBuilder(
      column: $table.winningSource, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get provenance => $composableBuilder(
      column: $table.provenance, builder: (column) => ColumnFilters(column));
}

class $$MinuteBucketsTableOrderingComposer
    extends Composer<_$AppDatabase, $MinuteBucketsTable> {
  $$MinuteBucketsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<DateTime> get minuteUtc => $composableBuilder(
      column: $table.minuteUtc, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get activeKcal => $composableBuilder(
      column: $table.activeKcal, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get steps => $composableBuilder(
      column: $table.steps, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get avgHr => $composableBuilder(
      column: $table.avgHr, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get winningSource => $composableBuilder(
      column: $table.winningSource,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get provenance => $composableBuilder(
      column: $table.provenance, builder: (column) => ColumnOrderings(column));
}

class $$MinuteBucketsTableAnnotationComposer
    extends Composer<_$AppDatabase, $MinuteBucketsTable> {
  $$MinuteBucketsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<DateTime> get minuteUtc =>
      $composableBuilder(column: $table.minuteUtc, builder: (column) => column);

  GeneratedColumn<double> get activeKcal => $composableBuilder(
      column: $table.activeKcal, builder: (column) => column);

  GeneratedColumn<int> get steps =>
      $composableBuilder(column: $table.steps, builder: (column) => column);

  GeneratedColumn<double> get avgHr =>
      $composableBuilder(column: $table.avgHr, builder: (column) => column);

  GeneratedColumn<String> get winningSource => $composableBuilder(
      column: $table.winningSource, builder: (column) => column);

  GeneratedColumn<String> get provenance => $composableBuilder(
      column: $table.provenance, builder: (column) => column);
}

class $$MinuteBucketsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $MinuteBucketsTable,
    MinuteBucketRow,
    $$MinuteBucketsTableFilterComposer,
    $$MinuteBucketsTableOrderingComposer,
    $$MinuteBucketsTableAnnotationComposer,
    $$MinuteBucketsTableCreateCompanionBuilder,
    $$MinuteBucketsTableUpdateCompanionBuilder,
    (
      MinuteBucketRow,
      BaseReferences<_$AppDatabase, $MinuteBucketsTable, MinuteBucketRow>
    ),
    MinuteBucketRow,
    PrefetchHooks Function()> {
  $$MinuteBucketsTableTableManager(_$AppDatabase db, $MinuteBucketsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MinuteBucketsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MinuteBucketsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MinuteBucketsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<DateTime> minuteUtc = const Value.absent(),
            Value<double> activeKcal = const Value.absent(),
            Value<int?> steps = const Value.absent(),
            Value<double?> avgHr = const Value.absent(),
            Value<String> winningSource = const Value.absent(),
            Value<String> provenance = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              MinuteBucketsCompanion(
            minuteUtc: minuteUtc,
            activeKcal: activeKcal,
            steps: steps,
            avgHr: avgHr,
            winningSource: winningSource,
            provenance: provenance,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required DateTime minuteUtc,
            required double activeKcal,
            Value<int?> steps = const Value.absent(),
            Value<double?> avgHr = const Value.absent(),
            required String winningSource,
            required String provenance,
            Value<int> rowid = const Value.absent(),
          }) =>
              MinuteBucketsCompanion.insert(
            minuteUtc: minuteUtc,
            activeKcal: activeKcal,
            steps: steps,
            avgHr: avgHr,
            winningSource: winningSource,
            provenance: provenance,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$MinuteBucketsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $MinuteBucketsTable,
    MinuteBucketRow,
    $$MinuteBucketsTableFilterComposer,
    $$MinuteBucketsTableOrderingComposer,
    $$MinuteBucketsTableAnnotationComposer,
    $$MinuteBucketsTableCreateCompanionBuilder,
    $$MinuteBucketsTableUpdateCompanionBuilder,
    (
      MinuteBucketRow,
      BaseReferences<_$AppDatabase, $MinuteBucketsTable, MinuteBucketRow>
    ),
    MinuteBucketRow,
    PrefetchHooks Function()>;
typedef $$IntegrationsTableCreateCompanionBuilder = IntegrationsCompanion
    Function({
  required String vendor,
  required String status,
  Value<DateTime?> lastAttempt,
  Value<DateTime?> lastSync,
  Value<String?> changesToken,
  Value<int> recordsToday,
  Value<String> diagnosticsJson,
  Value<String?> lastError,
  Value<int> rowid,
});
typedef $$IntegrationsTableUpdateCompanionBuilder = IntegrationsCompanion
    Function({
  Value<String> vendor,
  Value<String> status,
  Value<DateTime?> lastAttempt,
  Value<DateTime?> lastSync,
  Value<String?> changesToken,
  Value<int> recordsToday,
  Value<String> diagnosticsJson,
  Value<String?> lastError,
  Value<int> rowid,
});

class $$IntegrationsTableFilterComposer
    extends Composer<_$AppDatabase, $IntegrationsTable> {
  $$IntegrationsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get vendor => $composableBuilder(
      column: $table.vendor, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get lastAttempt => $composableBuilder(
      column: $table.lastAttempt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get lastSync => $composableBuilder(
      column: $table.lastSync, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get changesToken => $composableBuilder(
      column: $table.changesToken, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get recordsToday => $composableBuilder(
      column: $table.recordsToday, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get diagnosticsJson => $composableBuilder(
      column: $table.diagnosticsJson,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get lastError => $composableBuilder(
      column: $table.lastError, builder: (column) => ColumnFilters(column));
}

class $$IntegrationsTableOrderingComposer
    extends Composer<_$AppDatabase, $IntegrationsTable> {
  $$IntegrationsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get vendor => $composableBuilder(
      column: $table.vendor, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get lastAttempt => $composableBuilder(
      column: $table.lastAttempt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get lastSync => $composableBuilder(
      column: $table.lastSync, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get changesToken => $composableBuilder(
      column: $table.changesToken,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get recordsToday => $composableBuilder(
      column: $table.recordsToday,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get diagnosticsJson => $composableBuilder(
      column: $table.diagnosticsJson,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get lastError => $composableBuilder(
      column: $table.lastError, builder: (column) => ColumnOrderings(column));
}

class $$IntegrationsTableAnnotationComposer
    extends Composer<_$AppDatabase, $IntegrationsTable> {
  $$IntegrationsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get vendor =>
      $composableBuilder(column: $table.vendor, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<DateTime> get lastAttempt => $composableBuilder(
      column: $table.lastAttempt, builder: (column) => column);

  GeneratedColumn<DateTime> get lastSync =>
      $composableBuilder(column: $table.lastSync, builder: (column) => column);

  GeneratedColumn<String> get changesToken => $composableBuilder(
      column: $table.changesToken, builder: (column) => column);

  GeneratedColumn<int> get recordsToday => $composableBuilder(
      column: $table.recordsToday, builder: (column) => column);

  GeneratedColumn<String> get diagnosticsJson => $composableBuilder(
      column: $table.diagnosticsJson, builder: (column) => column);

  GeneratedColumn<String> get lastError =>
      $composableBuilder(column: $table.lastError, builder: (column) => column);
}

class $$IntegrationsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $IntegrationsTable,
    IntegrationRow,
    $$IntegrationsTableFilterComposer,
    $$IntegrationsTableOrderingComposer,
    $$IntegrationsTableAnnotationComposer,
    $$IntegrationsTableCreateCompanionBuilder,
    $$IntegrationsTableUpdateCompanionBuilder,
    (
      IntegrationRow,
      BaseReferences<_$AppDatabase, $IntegrationsTable, IntegrationRow>
    ),
    IntegrationRow,
    PrefetchHooks Function()> {
  $$IntegrationsTableTableManager(_$AppDatabase db, $IntegrationsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$IntegrationsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$IntegrationsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$IntegrationsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> vendor = const Value.absent(),
            Value<String> status = const Value.absent(),
            Value<DateTime?> lastAttempt = const Value.absent(),
            Value<DateTime?> lastSync = const Value.absent(),
            Value<String?> changesToken = const Value.absent(),
            Value<int> recordsToday = const Value.absent(),
            Value<String> diagnosticsJson = const Value.absent(),
            Value<String?> lastError = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              IntegrationsCompanion(
            vendor: vendor,
            status: status,
            lastAttempt: lastAttempt,
            lastSync: lastSync,
            changesToken: changesToken,
            recordsToday: recordsToday,
            diagnosticsJson: diagnosticsJson,
            lastError: lastError,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String vendor,
            required String status,
            Value<DateTime?> lastAttempt = const Value.absent(),
            Value<DateTime?> lastSync = const Value.absent(),
            Value<String?> changesToken = const Value.absent(),
            Value<int> recordsToday = const Value.absent(),
            Value<String> diagnosticsJson = const Value.absent(),
            Value<String?> lastError = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              IntegrationsCompanion.insert(
            vendor: vendor,
            status: status,
            lastAttempt: lastAttempt,
            lastSync: lastSync,
            changesToken: changesToken,
            recordsToday: recordsToday,
            diagnosticsJson: diagnosticsJson,
            lastError: lastError,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$IntegrationsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $IntegrationsTable,
    IntegrationRow,
    $$IntegrationsTableFilterComposer,
    $$IntegrationsTableOrderingComposer,
    $$IntegrationsTableAnnotationComposer,
    $$IntegrationsTableCreateCompanionBuilder,
    $$IntegrationsTableUpdateCompanionBuilder,
    (
      IntegrationRow,
      BaseReferences<_$AppDatabase, $IntegrationsTable, IntegrationRow>
    ),
    IntegrationRow,
    PrefetchHooks Function()>;
typedef $$SleepSegmentsTableCreateCompanionBuilder = SleepSegmentsCompanion
    Function({
  Value<int> id,
  required DateTime startUtc,
  required DateTime endUtc,
  required String stage,
  required String source,
  required int priority,
  required String nightOf,
  Value<String?> externalId,
  Value<DateTime?> syncedAt,
});
typedef $$SleepSegmentsTableUpdateCompanionBuilder = SleepSegmentsCompanion
    Function({
  Value<int> id,
  Value<DateTime> startUtc,
  Value<DateTime> endUtc,
  Value<String> stage,
  Value<String> source,
  Value<int> priority,
  Value<String> nightOf,
  Value<String?> externalId,
  Value<DateTime?> syncedAt,
});

class $$SleepSegmentsTableFilterComposer
    extends Composer<_$AppDatabase, $SleepSegmentsTable> {
  $$SleepSegmentsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get startUtc => $composableBuilder(
      column: $table.startUtc, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get endUtc => $composableBuilder(
      column: $table.endUtc, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get stage => $composableBuilder(
      column: $table.stage, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get source => $composableBuilder(
      column: $table.source, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get priority => $composableBuilder(
      column: $table.priority, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get nightOf => $composableBuilder(
      column: $table.nightOf, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get externalId => $composableBuilder(
      column: $table.externalId, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get syncedAt => $composableBuilder(
      column: $table.syncedAt, builder: (column) => ColumnFilters(column));
}

class $$SleepSegmentsTableOrderingComposer
    extends Composer<_$AppDatabase, $SleepSegmentsTable> {
  $$SleepSegmentsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get startUtc => $composableBuilder(
      column: $table.startUtc, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get endUtc => $composableBuilder(
      column: $table.endUtc, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get stage => $composableBuilder(
      column: $table.stage, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get source => $composableBuilder(
      column: $table.source, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get priority => $composableBuilder(
      column: $table.priority, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get nightOf => $composableBuilder(
      column: $table.nightOf, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get externalId => $composableBuilder(
      column: $table.externalId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get syncedAt => $composableBuilder(
      column: $table.syncedAt, builder: (column) => ColumnOrderings(column));
}

class $$SleepSegmentsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SleepSegmentsTable> {
  $$SleepSegmentsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get startUtc =>
      $composableBuilder(column: $table.startUtc, builder: (column) => column);

  GeneratedColumn<DateTime> get endUtc =>
      $composableBuilder(column: $table.endUtc, builder: (column) => column);

  GeneratedColumn<String> get stage =>
      $composableBuilder(column: $table.stage, builder: (column) => column);

  GeneratedColumn<String> get source =>
      $composableBuilder(column: $table.source, builder: (column) => column);

  GeneratedColumn<int> get priority =>
      $composableBuilder(column: $table.priority, builder: (column) => column);

  GeneratedColumn<String> get nightOf =>
      $composableBuilder(column: $table.nightOf, builder: (column) => column);

  GeneratedColumn<String> get externalId => $composableBuilder(
      column: $table.externalId, builder: (column) => column);

  GeneratedColumn<DateTime> get syncedAt =>
      $composableBuilder(column: $table.syncedAt, builder: (column) => column);
}

class $$SleepSegmentsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $SleepSegmentsTable,
    SleepSegmentRow,
    $$SleepSegmentsTableFilterComposer,
    $$SleepSegmentsTableOrderingComposer,
    $$SleepSegmentsTableAnnotationComposer,
    $$SleepSegmentsTableCreateCompanionBuilder,
    $$SleepSegmentsTableUpdateCompanionBuilder,
    (
      SleepSegmentRow,
      BaseReferences<_$AppDatabase, $SleepSegmentsTable, SleepSegmentRow>
    ),
    SleepSegmentRow,
    PrefetchHooks Function()> {
  $$SleepSegmentsTableTableManager(_$AppDatabase db, $SleepSegmentsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SleepSegmentsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SleepSegmentsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SleepSegmentsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<DateTime> startUtc = const Value.absent(),
            Value<DateTime> endUtc = const Value.absent(),
            Value<String> stage = const Value.absent(),
            Value<String> source = const Value.absent(),
            Value<int> priority = const Value.absent(),
            Value<String> nightOf = const Value.absent(),
            Value<String?> externalId = const Value.absent(),
            Value<DateTime?> syncedAt = const Value.absent(),
          }) =>
              SleepSegmentsCompanion(
            id: id,
            startUtc: startUtc,
            endUtc: endUtc,
            stage: stage,
            source: source,
            priority: priority,
            nightOf: nightOf,
            externalId: externalId,
            syncedAt: syncedAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required DateTime startUtc,
            required DateTime endUtc,
            required String stage,
            required String source,
            required int priority,
            required String nightOf,
            Value<String?> externalId = const Value.absent(),
            Value<DateTime?> syncedAt = const Value.absent(),
          }) =>
              SleepSegmentsCompanion.insert(
            id: id,
            startUtc: startUtc,
            endUtc: endUtc,
            stage: stage,
            source: source,
            priority: priority,
            nightOf: nightOf,
            externalId: externalId,
            syncedAt: syncedAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$SleepSegmentsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $SleepSegmentsTable,
    SleepSegmentRow,
    $$SleepSegmentsTableFilterComposer,
    $$SleepSegmentsTableOrderingComposer,
    $$SleepSegmentsTableAnnotationComposer,
    $$SleepSegmentsTableCreateCompanionBuilder,
    $$SleepSegmentsTableUpdateCompanionBuilder,
    (
      SleepSegmentRow,
      BaseReferences<_$AppDatabase, $SleepSegmentsTable, SleepSegmentRow>
    ),
    SleepSegmentRow,
    PrefetchHooks Function()>;
typedef $$DailyVitalsTableCreateCompanionBuilder = DailyVitalsCompanion
    Function({
  required String date,
  Value<double?> restingHr,
  Value<double?> hrvMs,
  Value<double?> respiratoryRate,
  Value<double?> bodyTemperatureDelta,
  Value<double?> sleepScore,
  Value<double?> readinessScore,
  required String source,
  Value<DateTime?> syncedAt,
  Value<int> rowid,
});
typedef $$DailyVitalsTableUpdateCompanionBuilder = DailyVitalsCompanion
    Function({
  Value<String> date,
  Value<double?> restingHr,
  Value<double?> hrvMs,
  Value<double?> respiratoryRate,
  Value<double?> bodyTemperatureDelta,
  Value<double?> sleepScore,
  Value<double?> readinessScore,
  Value<String> source,
  Value<DateTime?> syncedAt,
  Value<int> rowid,
});

class $$DailyVitalsTableFilterComposer
    extends Composer<_$AppDatabase, $DailyVitalsTable> {
  $$DailyVitalsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get date => $composableBuilder(
      column: $table.date, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get restingHr => $composableBuilder(
      column: $table.restingHr, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get hrvMs => $composableBuilder(
      column: $table.hrvMs, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get respiratoryRate => $composableBuilder(
      column: $table.respiratoryRate,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get bodyTemperatureDelta => $composableBuilder(
      column: $table.bodyTemperatureDelta,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get sleepScore => $composableBuilder(
      column: $table.sleepScore, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get readinessScore => $composableBuilder(
      column: $table.readinessScore,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get source => $composableBuilder(
      column: $table.source, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get syncedAt => $composableBuilder(
      column: $table.syncedAt, builder: (column) => ColumnFilters(column));
}

class $$DailyVitalsTableOrderingComposer
    extends Composer<_$AppDatabase, $DailyVitalsTable> {
  $$DailyVitalsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get date => $composableBuilder(
      column: $table.date, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get restingHr => $composableBuilder(
      column: $table.restingHr, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get hrvMs => $composableBuilder(
      column: $table.hrvMs, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get respiratoryRate => $composableBuilder(
      column: $table.respiratoryRate,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get bodyTemperatureDelta => $composableBuilder(
      column: $table.bodyTemperatureDelta,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get sleepScore => $composableBuilder(
      column: $table.sleepScore, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get readinessScore => $composableBuilder(
      column: $table.readinessScore,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get source => $composableBuilder(
      column: $table.source, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get syncedAt => $composableBuilder(
      column: $table.syncedAt, builder: (column) => ColumnOrderings(column));
}

class $$DailyVitalsTableAnnotationComposer
    extends Composer<_$AppDatabase, $DailyVitalsTable> {
  $$DailyVitalsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumn<double> get restingHr =>
      $composableBuilder(column: $table.restingHr, builder: (column) => column);

  GeneratedColumn<double> get hrvMs =>
      $composableBuilder(column: $table.hrvMs, builder: (column) => column);

  GeneratedColumn<double> get respiratoryRate => $composableBuilder(
      column: $table.respiratoryRate, builder: (column) => column);

  GeneratedColumn<double> get bodyTemperatureDelta => $composableBuilder(
      column: $table.bodyTemperatureDelta, builder: (column) => column);

  GeneratedColumn<double> get sleepScore => $composableBuilder(
      column: $table.sleepScore, builder: (column) => column);

  GeneratedColumn<double> get readinessScore => $composableBuilder(
      column: $table.readinessScore, builder: (column) => column);

  GeneratedColumn<String> get source =>
      $composableBuilder(column: $table.source, builder: (column) => column);

  GeneratedColumn<DateTime> get syncedAt =>
      $composableBuilder(column: $table.syncedAt, builder: (column) => column);
}

class $$DailyVitalsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $DailyVitalsTable,
    DailyVitalsRow,
    $$DailyVitalsTableFilterComposer,
    $$DailyVitalsTableOrderingComposer,
    $$DailyVitalsTableAnnotationComposer,
    $$DailyVitalsTableCreateCompanionBuilder,
    $$DailyVitalsTableUpdateCompanionBuilder,
    (
      DailyVitalsRow,
      BaseReferences<_$AppDatabase, $DailyVitalsTable, DailyVitalsRow>
    ),
    DailyVitalsRow,
    PrefetchHooks Function()> {
  $$DailyVitalsTableTableManager(_$AppDatabase db, $DailyVitalsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DailyVitalsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DailyVitalsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DailyVitalsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> date = const Value.absent(),
            Value<double?> restingHr = const Value.absent(),
            Value<double?> hrvMs = const Value.absent(),
            Value<double?> respiratoryRate = const Value.absent(),
            Value<double?> bodyTemperatureDelta = const Value.absent(),
            Value<double?> sleepScore = const Value.absent(),
            Value<double?> readinessScore = const Value.absent(),
            Value<String> source = const Value.absent(),
            Value<DateTime?> syncedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              DailyVitalsCompanion(
            date: date,
            restingHr: restingHr,
            hrvMs: hrvMs,
            respiratoryRate: respiratoryRate,
            bodyTemperatureDelta: bodyTemperatureDelta,
            sleepScore: sleepScore,
            readinessScore: readinessScore,
            source: source,
            syncedAt: syncedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String date,
            Value<double?> restingHr = const Value.absent(),
            Value<double?> hrvMs = const Value.absent(),
            Value<double?> respiratoryRate = const Value.absent(),
            Value<double?> bodyTemperatureDelta = const Value.absent(),
            Value<double?> sleepScore = const Value.absent(),
            Value<double?> readinessScore = const Value.absent(),
            required String source,
            Value<DateTime?> syncedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              DailyVitalsCompanion.insert(
            date: date,
            restingHr: restingHr,
            hrvMs: hrvMs,
            respiratoryRate: respiratoryRate,
            bodyTemperatureDelta: bodyTemperatureDelta,
            sleepScore: sleepScore,
            readinessScore: readinessScore,
            source: source,
            syncedAt: syncedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$DailyVitalsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $DailyVitalsTable,
    DailyVitalsRow,
    $$DailyVitalsTableFilterComposer,
    $$DailyVitalsTableOrderingComposer,
    $$DailyVitalsTableAnnotationComposer,
    $$DailyVitalsTableCreateCompanionBuilder,
    $$DailyVitalsTableUpdateCompanionBuilder,
    (
      DailyVitalsRow,
      BaseReferences<_$AppDatabase, $DailyVitalsTable, DailyVitalsRow>
    ),
    DailyVitalsRow,
    PrefetchHooks Function()>;
typedef $$ActivitySessionsTableCreateCompanionBuilder
    = ActivitySessionsCompanion Function({
  required String id,
  Value<String?> sport,
  required DateTime startUtc,
  required DateTime endUtc,
  Value<double?> activeKcal,
  Value<double?> avgHr,
  Value<double?> maxHr,
  Value<int?> steps,
  required String source,
  required int priority,
  Value<String?> externalId,
  Value<DateTime?> syncedAt,
  Value<int> rowid,
});
typedef $$ActivitySessionsTableUpdateCompanionBuilder
    = ActivitySessionsCompanion Function({
  Value<String> id,
  Value<String?> sport,
  Value<DateTime> startUtc,
  Value<DateTime> endUtc,
  Value<double?> activeKcal,
  Value<double?> avgHr,
  Value<double?> maxHr,
  Value<int?> steps,
  Value<String> source,
  Value<int> priority,
  Value<String?> externalId,
  Value<DateTime?> syncedAt,
  Value<int> rowid,
});

class $$ActivitySessionsTableFilterComposer
    extends Composer<_$AppDatabase, $ActivitySessionsTable> {
  $$ActivitySessionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get sport => $composableBuilder(
      column: $table.sport, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get startUtc => $composableBuilder(
      column: $table.startUtc, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get endUtc => $composableBuilder(
      column: $table.endUtc, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get activeKcal => $composableBuilder(
      column: $table.activeKcal, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get avgHr => $composableBuilder(
      column: $table.avgHr, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get maxHr => $composableBuilder(
      column: $table.maxHr, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get steps => $composableBuilder(
      column: $table.steps, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get source => $composableBuilder(
      column: $table.source, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get priority => $composableBuilder(
      column: $table.priority, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get externalId => $composableBuilder(
      column: $table.externalId, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get syncedAt => $composableBuilder(
      column: $table.syncedAt, builder: (column) => ColumnFilters(column));
}

class $$ActivitySessionsTableOrderingComposer
    extends Composer<_$AppDatabase, $ActivitySessionsTable> {
  $$ActivitySessionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get sport => $composableBuilder(
      column: $table.sport, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get startUtc => $composableBuilder(
      column: $table.startUtc, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get endUtc => $composableBuilder(
      column: $table.endUtc, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get activeKcal => $composableBuilder(
      column: $table.activeKcal, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get avgHr => $composableBuilder(
      column: $table.avgHr, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get maxHr => $composableBuilder(
      column: $table.maxHr, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get steps => $composableBuilder(
      column: $table.steps, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get source => $composableBuilder(
      column: $table.source, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get priority => $composableBuilder(
      column: $table.priority, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get externalId => $composableBuilder(
      column: $table.externalId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get syncedAt => $composableBuilder(
      column: $table.syncedAt, builder: (column) => ColumnOrderings(column));
}

class $$ActivitySessionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ActivitySessionsTable> {
  $$ActivitySessionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get sport =>
      $composableBuilder(column: $table.sport, builder: (column) => column);

  GeneratedColumn<DateTime> get startUtc =>
      $composableBuilder(column: $table.startUtc, builder: (column) => column);

  GeneratedColumn<DateTime> get endUtc =>
      $composableBuilder(column: $table.endUtc, builder: (column) => column);

  GeneratedColumn<double> get activeKcal => $composableBuilder(
      column: $table.activeKcal, builder: (column) => column);

  GeneratedColumn<double> get avgHr =>
      $composableBuilder(column: $table.avgHr, builder: (column) => column);

  GeneratedColumn<double> get maxHr =>
      $composableBuilder(column: $table.maxHr, builder: (column) => column);

  GeneratedColumn<int> get steps =>
      $composableBuilder(column: $table.steps, builder: (column) => column);

  GeneratedColumn<String> get source =>
      $composableBuilder(column: $table.source, builder: (column) => column);

  GeneratedColumn<int> get priority =>
      $composableBuilder(column: $table.priority, builder: (column) => column);

  GeneratedColumn<String> get externalId => $composableBuilder(
      column: $table.externalId, builder: (column) => column);

  GeneratedColumn<DateTime> get syncedAt =>
      $composableBuilder(column: $table.syncedAt, builder: (column) => column);
}

class $$ActivitySessionsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $ActivitySessionsTable,
    ActivitySessionRow,
    $$ActivitySessionsTableFilterComposer,
    $$ActivitySessionsTableOrderingComposer,
    $$ActivitySessionsTableAnnotationComposer,
    $$ActivitySessionsTableCreateCompanionBuilder,
    $$ActivitySessionsTableUpdateCompanionBuilder,
    (
      ActivitySessionRow,
      BaseReferences<_$AppDatabase, $ActivitySessionsTable, ActivitySessionRow>
    ),
    ActivitySessionRow,
    PrefetchHooks Function()> {
  $$ActivitySessionsTableTableManager(
      _$AppDatabase db, $ActivitySessionsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ActivitySessionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ActivitySessionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ActivitySessionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String?> sport = const Value.absent(),
            Value<DateTime> startUtc = const Value.absent(),
            Value<DateTime> endUtc = const Value.absent(),
            Value<double?> activeKcal = const Value.absent(),
            Value<double?> avgHr = const Value.absent(),
            Value<double?> maxHr = const Value.absent(),
            Value<int?> steps = const Value.absent(),
            Value<String> source = const Value.absent(),
            Value<int> priority = const Value.absent(),
            Value<String?> externalId = const Value.absent(),
            Value<DateTime?> syncedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              ActivitySessionsCompanion(
            id: id,
            sport: sport,
            startUtc: startUtc,
            endUtc: endUtc,
            activeKcal: activeKcal,
            avgHr: avgHr,
            maxHr: maxHr,
            steps: steps,
            source: source,
            priority: priority,
            externalId: externalId,
            syncedAt: syncedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            Value<String?> sport = const Value.absent(),
            required DateTime startUtc,
            required DateTime endUtc,
            Value<double?> activeKcal = const Value.absent(),
            Value<double?> avgHr = const Value.absent(),
            Value<double?> maxHr = const Value.absent(),
            Value<int?> steps = const Value.absent(),
            required String source,
            required int priority,
            Value<String?> externalId = const Value.absent(),
            Value<DateTime?> syncedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              ActivitySessionsCompanion.insert(
            id: id,
            sport: sport,
            startUtc: startUtc,
            endUtc: endUtc,
            activeKcal: activeKcal,
            avgHr: avgHr,
            maxHr: maxHr,
            steps: steps,
            source: source,
            priority: priority,
            externalId: externalId,
            syncedAt: syncedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$ActivitySessionsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $ActivitySessionsTable,
    ActivitySessionRow,
    $$ActivitySessionsTableFilterComposer,
    $$ActivitySessionsTableOrderingComposer,
    $$ActivitySessionsTableAnnotationComposer,
    $$ActivitySessionsTableCreateCompanionBuilder,
    $$ActivitySessionsTableUpdateCompanionBuilder,
    (
      ActivitySessionRow,
      BaseReferences<_$AppDatabase, $ActivitySessionsTable, ActivitySessionRow>
    ),
    ActivitySessionRow,
    PrefetchHooks Function()>;
typedef $$StrengthWorkoutsTableCreateCompanionBuilder
    = StrengthWorkoutsCompanion Function({
  required String id,
  required DateTime startedAt,
  required DateTime endedAt,
  required double bodyWeightKgAtTime,
  required String exercisesJson,
  required double fallbackKcal,
  required double finalKcal,
  Value<String> method,
  Value<DateTime?> syncedAt,
  Value<int> rowid,
});
typedef $$StrengthWorkoutsTableUpdateCompanionBuilder
    = StrengthWorkoutsCompanion Function({
  Value<String> id,
  Value<DateTime> startedAt,
  Value<DateTime> endedAt,
  Value<double> bodyWeightKgAtTime,
  Value<String> exercisesJson,
  Value<double> fallbackKcal,
  Value<double> finalKcal,
  Value<String> method,
  Value<DateTime?> syncedAt,
  Value<int> rowid,
});

class $$StrengthWorkoutsTableFilterComposer
    extends Composer<_$AppDatabase, $StrengthWorkoutsTable> {
  $$StrengthWorkoutsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get startedAt => $composableBuilder(
      column: $table.startedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get endedAt => $composableBuilder(
      column: $table.endedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get bodyWeightKgAtTime => $composableBuilder(
      column: $table.bodyWeightKgAtTime,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get exercisesJson => $composableBuilder(
      column: $table.exercisesJson, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get fallbackKcal => $composableBuilder(
      column: $table.fallbackKcal, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get finalKcal => $composableBuilder(
      column: $table.finalKcal, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get method => $composableBuilder(
      column: $table.method, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get syncedAt => $composableBuilder(
      column: $table.syncedAt, builder: (column) => ColumnFilters(column));
}

class $$StrengthWorkoutsTableOrderingComposer
    extends Composer<_$AppDatabase, $StrengthWorkoutsTable> {
  $$StrengthWorkoutsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get startedAt => $composableBuilder(
      column: $table.startedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get endedAt => $composableBuilder(
      column: $table.endedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get bodyWeightKgAtTime => $composableBuilder(
      column: $table.bodyWeightKgAtTime,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get exercisesJson => $composableBuilder(
      column: $table.exercisesJson,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get fallbackKcal => $composableBuilder(
      column: $table.fallbackKcal,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get finalKcal => $composableBuilder(
      column: $table.finalKcal, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get method => $composableBuilder(
      column: $table.method, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get syncedAt => $composableBuilder(
      column: $table.syncedAt, builder: (column) => ColumnOrderings(column));
}

class $$StrengthWorkoutsTableAnnotationComposer
    extends Composer<_$AppDatabase, $StrengthWorkoutsTable> {
  $$StrengthWorkoutsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get startedAt =>
      $composableBuilder(column: $table.startedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get endedAt =>
      $composableBuilder(column: $table.endedAt, builder: (column) => column);

  GeneratedColumn<double> get bodyWeightKgAtTime => $composableBuilder(
      column: $table.bodyWeightKgAtTime, builder: (column) => column);

  GeneratedColumn<String> get exercisesJson => $composableBuilder(
      column: $table.exercisesJson, builder: (column) => column);

  GeneratedColumn<double> get fallbackKcal => $composableBuilder(
      column: $table.fallbackKcal, builder: (column) => column);

  GeneratedColumn<double> get finalKcal =>
      $composableBuilder(column: $table.finalKcal, builder: (column) => column);

  GeneratedColumn<String> get method =>
      $composableBuilder(column: $table.method, builder: (column) => column);

  GeneratedColumn<DateTime> get syncedAt =>
      $composableBuilder(column: $table.syncedAt, builder: (column) => column);
}

class $$StrengthWorkoutsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $StrengthWorkoutsTable,
    StrengthWorkoutRow,
    $$StrengthWorkoutsTableFilterComposer,
    $$StrengthWorkoutsTableOrderingComposer,
    $$StrengthWorkoutsTableAnnotationComposer,
    $$StrengthWorkoutsTableCreateCompanionBuilder,
    $$StrengthWorkoutsTableUpdateCompanionBuilder,
    (
      StrengthWorkoutRow,
      BaseReferences<_$AppDatabase, $StrengthWorkoutsTable, StrengthWorkoutRow>
    ),
    StrengthWorkoutRow,
    PrefetchHooks Function()> {
  $$StrengthWorkoutsTableTableManager(
      _$AppDatabase db, $StrengthWorkoutsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$StrengthWorkoutsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$StrengthWorkoutsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$StrengthWorkoutsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<DateTime> startedAt = const Value.absent(),
            Value<DateTime> endedAt = const Value.absent(),
            Value<double> bodyWeightKgAtTime = const Value.absent(),
            Value<String> exercisesJson = const Value.absent(),
            Value<double> fallbackKcal = const Value.absent(),
            Value<double> finalKcal = const Value.absent(),
            Value<String> method = const Value.absent(),
            Value<DateTime?> syncedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              StrengthWorkoutsCompanion(
            id: id,
            startedAt: startedAt,
            endedAt: endedAt,
            bodyWeightKgAtTime: bodyWeightKgAtTime,
            exercisesJson: exercisesJson,
            fallbackKcal: fallbackKcal,
            finalKcal: finalKcal,
            method: method,
            syncedAt: syncedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required DateTime startedAt,
            required DateTime endedAt,
            required double bodyWeightKgAtTime,
            required String exercisesJson,
            required double fallbackKcal,
            required double finalKcal,
            Value<String> method = const Value.absent(),
            Value<DateTime?> syncedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              StrengthWorkoutsCompanion.insert(
            id: id,
            startedAt: startedAt,
            endedAt: endedAt,
            bodyWeightKgAtTime: bodyWeightKgAtTime,
            exercisesJson: exercisesJson,
            fallbackKcal: fallbackKcal,
            finalKcal: finalKcal,
            method: method,
            syncedAt: syncedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$StrengthWorkoutsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $StrengthWorkoutsTable,
    StrengthWorkoutRow,
    $$StrengthWorkoutsTableFilterComposer,
    $$StrengthWorkoutsTableOrderingComposer,
    $$StrengthWorkoutsTableAnnotationComposer,
    $$StrengthWorkoutsTableCreateCompanionBuilder,
    $$StrengthWorkoutsTableUpdateCompanionBuilder,
    (
      StrengthWorkoutRow,
      BaseReferences<_$AppDatabase, $StrengthWorkoutsTable, StrengthWorkoutRow>
    ),
    StrengthWorkoutRow,
    PrefetchHooks Function()>;
typedef $$WeightEntriesTableCreateCompanionBuilder = WeightEntriesCompanion
    Function({
  Value<int> id,
  required DateTime recordedAt,
  required double kg,
  Value<String> source,
  Value<DateTime?> syncedAt,
});
typedef $$WeightEntriesTableUpdateCompanionBuilder = WeightEntriesCompanion
    Function({
  Value<int> id,
  Value<DateTime> recordedAt,
  Value<double> kg,
  Value<String> source,
  Value<DateTime?> syncedAt,
});

class $$WeightEntriesTableFilterComposer
    extends Composer<_$AppDatabase, $WeightEntriesTable> {
  $$WeightEntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get recordedAt => $composableBuilder(
      column: $table.recordedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get kg => $composableBuilder(
      column: $table.kg, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get source => $composableBuilder(
      column: $table.source, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get syncedAt => $composableBuilder(
      column: $table.syncedAt, builder: (column) => ColumnFilters(column));
}

class $$WeightEntriesTableOrderingComposer
    extends Composer<_$AppDatabase, $WeightEntriesTable> {
  $$WeightEntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get recordedAt => $composableBuilder(
      column: $table.recordedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get kg => $composableBuilder(
      column: $table.kg, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get source => $composableBuilder(
      column: $table.source, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get syncedAt => $composableBuilder(
      column: $table.syncedAt, builder: (column) => ColumnOrderings(column));
}

class $$WeightEntriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $WeightEntriesTable> {
  $$WeightEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get recordedAt => $composableBuilder(
      column: $table.recordedAt, builder: (column) => column);

  GeneratedColumn<double> get kg =>
      $composableBuilder(column: $table.kg, builder: (column) => column);

  GeneratedColumn<String> get source =>
      $composableBuilder(column: $table.source, builder: (column) => column);

  GeneratedColumn<DateTime> get syncedAt =>
      $composableBuilder(column: $table.syncedAt, builder: (column) => column);
}

class $$WeightEntriesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $WeightEntriesTable,
    WeightEntryRow,
    $$WeightEntriesTableFilterComposer,
    $$WeightEntriesTableOrderingComposer,
    $$WeightEntriesTableAnnotationComposer,
    $$WeightEntriesTableCreateCompanionBuilder,
    $$WeightEntriesTableUpdateCompanionBuilder,
    (
      WeightEntryRow,
      BaseReferences<_$AppDatabase, $WeightEntriesTable, WeightEntryRow>
    ),
    WeightEntryRow,
    PrefetchHooks Function()> {
  $$WeightEntriesTableTableManager(_$AppDatabase db, $WeightEntriesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$WeightEntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$WeightEntriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$WeightEntriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<DateTime> recordedAt = const Value.absent(),
            Value<double> kg = const Value.absent(),
            Value<String> source = const Value.absent(),
            Value<DateTime?> syncedAt = const Value.absent(),
          }) =>
              WeightEntriesCompanion(
            id: id,
            recordedAt: recordedAt,
            kg: kg,
            source: source,
            syncedAt: syncedAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required DateTime recordedAt,
            required double kg,
            Value<String> source = const Value.absent(),
            Value<DateTime?> syncedAt = const Value.absent(),
          }) =>
              WeightEntriesCompanion.insert(
            id: id,
            recordedAt: recordedAt,
            kg: kg,
            source: source,
            syncedAt: syncedAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$WeightEntriesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $WeightEntriesTable,
    WeightEntryRow,
    $$WeightEntriesTableFilterComposer,
    $$WeightEntriesTableOrderingComposer,
    $$WeightEntriesTableAnnotationComposer,
    $$WeightEntriesTableCreateCompanionBuilder,
    $$WeightEntriesTableUpdateCompanionBuilder,
    (
      WeightEntryRow,
      BaseReferences<_$AppDatabase, $WeightEntriesTable, WeightEntryRow>
    ),
    WeightEntryRow,
    PrefetchHooks Function()>;
typedef $$NutritionEntriesTableCreateCompanionBuilder
    = NutritionEntriesCompanion Function({
  Value<int> id,
  required DateTime recordedAt,
  required double kcal,
  Value<double?> proteinG,
  Value<double?> carbsG,
  Value<double?> fatG,
  required String meal,
  Value<String> source,
  Value<String> metadataJson,
  Value<bool> confirmed,
  Value<DateTime?> syncedAt,
});
typedef $$NutritionEntriesTableUpdateCompanionBuilder
    = NutritionEntriesCompanion Function({
  Value<int> id,
  Value<DateTime> recordedAt,
  Value<double> kcal,
  Value<double?> proteinG,
  Value<double?> carbsG,
  Value<double?> fatG,
  Value<String> meal,
  Value<String> source,
  Value<String> metadataJson,
  Value<bool> confirmed,
  Value<DateTime?> syncedAt,
});

class $$NutritionEntriesTableFilterComposer
    extends Composer<_$AppDatabase, $NutritionEntriesTable> {
  $$NutritionEntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get recordedAt => $composableBuilder(
      column: $table.recordedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get kcal => $composableBuilder(
      column: $table.kcal, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get proteinG => $composableBuilder(
      column: $table.proteinG, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get carbsG => $composableBuilder(
      column: $table.carbsG, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get fatG => $composableBuilder(
      column: $table.fatG, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get meal => $composableBuilder(
      column: $table.meal, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get source => $composableBuilder(
      column: $table.source, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get metadataJson => $composableBuilder(
      column: $table.metadataJson, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get confirmed => $composableBuilder(
      column: $table.confirmed, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get syncedAt => $composableBuilder(
      column: $table.syncedAt, builder: (column) => ColumnFilters(column));
}

class $$NutritionEntriesTableOrderingComposer
    extends Composer<_$AppDatabase, $NutritionEntriesTable> {
  $$NutritionEntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get recordedAt => $composableBuilder(
      column: $table.recordedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get kcal => $composableBuilder(
      column: $table.kcal, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get proteinG => $composableBuilder(
      column: $table.proteinG, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get carbsG => $composableBuilder(
      column: $table.carbsG, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get fatG => $composableBuilder(
      column: $table.fatG, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get meal => $composableBuilder(
      column: $table.meal, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get source => $composableBuilder(
      column: $table.source, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get metadataJson => $composableBuilder(
      column: $table.metadataJson,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get confirmed => $composableBuilder(
      column: $table.confirmed, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get syncedAt => $composableBuilder(
      column: $table.syncedAt, builder: (column) => ColumnOrderings(column));
}

class $$NutritionEntriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $NutritionEntriesTable> {
  $$NutritionEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get recordedAt => $composableBuilder(
      column: $table.recordedAt, builder: (column) => column);

  GeneratedColumn<double> get kcal =>
      $composableBuilder(column: $table.kcal, builder: (column) => column);

  GeneratedColumn<double> get proteinG =>
      $composableBuilder(column: $table.proteinG, builder: (column) => column);

  GeneratedColumn<double> get carbsG =>
      $composableBuilder(column: $table.carbsG, builder: (column) => column);

  GeneratedColumn<double> get fatG =>
      $composableBuilder(column: $table.fatG, builder: (column) => column);

  GeneratedColumn<String> get meal =>
      $composableBuilder(column: $table.meal, builder: (column) => column);

  GeneratedColumn<String> get source =>
      $composableBuilder(column: $table.source, builder: (column) => column);

  GeneratedColumn<String> get metadataJson => $composableBuilder(
      column: $table.metadataJson, builder: (column) => column);

  GeneratedColumn<bool> get confirmed =>
      $composableBuilder(column: $table.confirmed, builder: (column) => column);

  GeneratedColumn<DateTime> get syncedAt =>
      $composableBuilder(column: $table.syncedAt, builder: (column) => column);
}

class $$NutritionEntriesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $NutritionEntriesTable,
    NutritionEntryRow,
    $$NutritionEntriesTableFilterComposer,
    $$NutritionEntriesTableOrderingComposer,
    $$NutritionEntriesTableAnnotationComposer,
    $$NutritionEntriesTableCreateCompanionBuilder,
    $$NutritionEntriesTableUpdateCompanionBuilder,
    (
      NutritionEntryRow,
      BaseReferences<_$AppDatabase, $NutritionEntriesTable, NutritionEntryRow>
    ),
    NutritionEntryRow,
    PrefetchHooks Function()> {
  $$NutritionEntriesTableTableManager(
      _$AppDatabase db, $NutritionEntriesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$NutritionEntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$NutritionEntriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$NutritionEntriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<DateTime> recordedAt = const Value.absent(),
            Value<double> kcal = const Value.absent(),
            Value<double?> proteinG = const Value.absent(),
            Value<double?> carbsG = const Value.absent(),
            Value<double?> fatG = const Value.absent(),
            Value<String> meal = const Value.absent(),
            Value<String> source = const Value.absent(),
            Value<String> metadataJson = const Value.absent(),
            Value<bool> confirmed = const Value.absent(),
            Value<DateTime?> syncedAt = const Value.absent(),
          }) =>
              NutritionEntriesCompanion(
            id: id,
            recordedAt: recordedAt,
            kcal: kcal,
            proteinG: proteinG,
            carbsG: carbsG,
            fatG: fatG,
            meal: meal,
            source: source,
            metadataJson: metadataJson,
            confirmed: confirmed,
            syncedAt: syncedAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required DateTime recordedAt,
            required double kcal,
            Value<double?> proteinG = const Value.absent(),
            Value<double?> carbsG = const Value.absent(),
            Value<double?> fatG = const Value.absent(),
            required String meal,
            Value<String> source = const Value.absent(),
            Value<String> metadataJson = const Value.absent(),
            Value<bool> confirmed = const Value.absent(),
            Value<DateTime?> syncedAt = const Value.absent(),
          }) =>
              NutritionEntriesCompanion.insert(
            id: id,
            recordedAt: recordedAt,
            kcal: kcal,
            proteinG: proteinG,
            carbsG: carbsG,
            fatG: fatG,
            meal: meal,
            source: source,
            metadataJson: metadataJson,
            confirmed: confirmed,
            syncedAt: syncedAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$NutritionEntriesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $NutritionEntriesTable,
    NutritionEntryRow,
    $$NutritionEntriesTableFilterComposer,
    $$NutritionEntriesTableOrderingComposer,
    $$NutritionEntriesTableAnnotationComposer,
    $$NutritionEntriesTableCreateCompanionBuilder,
    $$NutritionEntriesTableUpdateCompanionBuilder,
    (
      NutritionEntryRow,
      BaseReferences<_$AppDatabase, $NutritionEntriesTable, NutritionEntryRow>
    ),
    NutritionEntryRow,
    PrefetchHooks Function()>;
typedef $$LiveSessionsTableCreateCompanionBuilder = LiveSessionsCompanion
    Function({
  required String id,
  required DateTime startedAt,
  required DateTime endedAt,
  required String sourceId,
  required String hrSeriesJson,
  required double finalKcal,
  Value<DateTime?> syncedAt,
  Value<int> rowid,
});
typedef $$LiveSessionsTableUpdateCompanionBuilder = LiveSessionsCompanion
    Function({
  Value<String> id,
  Value<DateTime> startedAt,
  Value<DateTime> endedAt,
  Value<String> sourceId,
  Value<String> hrSeriesJson,
  Value<double> finalKcal,
  Value<DateTime?> syncedAt,
  Value<int> rowid,
});

class $$LiveSessionsTableFilterComposer
    extends Composer<_$AppDatabase, $LiveSessionsTable> {
  $$LiveSessionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get startedAt => $composableBuilder(
      column: $table.startedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get endedAt => $composableBuilder(
      column: $table.endedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get sourceId => $composableBuilder(
      column: $table.sourceId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get hrSeriesJson => $composableBuilder(
      column: $table.hrSeriesJson, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get finalKcal => $composableBuilder(
      column: $table.finalKcal, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get syncedAt => $composableBuilder(
      column: $table.syncedAt, builder: (column) => ColumnFilters(column));
}

class $$LiveSessionsTableOrderingComposer
    extends Composer<_$AppDatabase, $LiveSessionsTable> {
  $$LiveSessionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get startedAt => $composableBuilder(
      column: $table.startedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get endedAt => $composableBuilder(
      column: $table.endedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get sourceId => $composableBuilder(
      column: $table.sourceId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get hrSeriesJson => $composableBuilder(
      column: $table.hrSeriesJson,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get finalKcal => $composableBuilder(
      column: $table.finalKcal, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get syncedAt => $composableBuilder(
      column: $table.syncedAt, builder: (column) => ColumnOrderings(column));
}

class $$LiveSessionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $LiveSessionsTable> {
  $$LiveSessionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get startedAt =>
      $composableBuilder(column: $table.startedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get endedAt =>
      $composableBuilder(column: $table.endedAt, builder: (column) => column);

  GeneratedColumn<String> get sourceId =>
      $composableBuilder(column: $table.sourceId, builder: (column) => column);

  GeneratedColumn<String> get hrSeriesJson => $composableBuilder(
      column: $table.hrSeriesJson, builder: (column) => column);

  GeneratedColumn<double> get finalKcal =>
      $composableBuilder(column: $table.finalKcal, builder: (column) => column);

  GeneratedColumn<DateTime> get syncedAt =>
      $composableBuilder(column: $table.syncedAt, builder: (column) => column);
}

class $$LiveSessionsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $LiveSessionsTable,
    LiveSessionRow,
    $$LiveSessionsTableFilterComposer,
    $$LiveSessionsTableOrderingComposer,
    $$LiveSessionsTableAnnotationComposer,
    $$LiveSessionsTableCreateCompanionBuilder,
    $$LiveSessionsTableUpdateCompanionBuilder,
    (
      LiveSessionRow,
      BaseReferences<_$AppDatabase, $LiveSessionsTable, LiveSessionRow>
    ),
    LiveSessionRow,
    PrefetchHooks Function()> {
  $$LiveSessionsTableTableManager(_$AppDatabase db, $LiveSessionsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LiveSessionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LiveSessionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LiveSessionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<DateTime> startedAt = const Value.absent(),
            Value<DateTime> endedAt = const Value.absent(),
            Value<String> sourceId = const Value.absent(),
            Value<String> hrSeriesJson = const Value.absent(),
            Value<double> finalKcal = const Value.absent(),
            Value<DateTime?> syncedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              LiveSessionsCompanion(
            id: id,
            startedAt: startedAt,
            endedAt: endedAt,
            sourceId: sourceId,
            hrSeriesJson: hrSeriesJson,
            finalKcal: finalKcal,
            syncedAt: syncedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required DateTime startedAt,
            required DateTime endedAt,
            required String sourceId,
            required String hrSeriesJson,
            required double finalKcal,
            Value<DateTime?> syncedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              LiveSessionsCompanion.insert(
            id: id,
            startedAt: startedAt,
            endedAt: endedAt,
            sourceId: sourceId,
            hrSeriesJson: hrSeriesJson,
            finalKcal: finalKcal,
            syncedAt: syncedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$LiveSessionsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $LiveSessionsTable,
    LiveSessionRow,
    $$LiveSessionsTableFilterComposer,
    $$LiveSessionsTableOrderingComposer,
    $$LiveSessionsTableAnnotationComposer,
    $$LiveSessionsTableCreateCompanionBuilder,
    $$LiveSessionsTableUpdateCompanionBuilder,
    (
      LiveSessionRow,
      BaseReferences<_$AppDatabase, $LiveSessionsTable, LiveSessionRow>
    ),
    LiveSessionRow,
    PrefetchHooks Function()>;
typedef $$RememberedSensorsTableCreateCompanionBuilder
    = RememberedSensorsCompanion Function({
  required String deviceId,
  required String name,
  Value<bool> paired,
  Value<DateTime?> lastConnected,
  Value<int> rowid,
});
typedef $$RememberedSensorsTableUpdateCompanionBuilder
    = RememberedSensorsCompanion Function({
  Value<String> deviceId,
  Value<String> name,
  Value<bool> paired,
  Value<DateTime?> lastConnected,
  Value<int> rowid,
});

class $$RememberedSensorsTableFilterComposer
    extends Composer<_$AppDatabase, $RememberedSensorsTable> {
  $$RememberedSensorsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get deviceId => $composableBuilder(
      column: $table.deviceId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get paired => $composableBuilder(
      column: $table.paired, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get lastConnected => $composableBuilder(
      column: $table.lastConnected, builder: (column) => ColumnFilters(column));
}

class $$RememberedSensorsTableOrderingComposer
    extends Composer<_$AppDatabase, $RememberedSensorsTable> {
  $$RememberedSensorsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get deviceId => $composableBuilder(
      column: $table.deviceId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get paired => $composableBuilder(
      column: $table.paired, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get lastConnected => $composableBuilder(
      column: $table.lastConnected,
      builder: (column) => ColumnOrderings(column));
}

class $$RememberedSensorsTableAnnotationComposer
    extends Composer<_$AppDatabase, $RememberedSensorsTable> {
  $$RememberedSensorsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get deviceId =>
      $composableBuilder(column: $table.deviceId, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<bool> get paired =>
      $composableBuilder(column: $table.paired, builder: (column) => column);

  GeneratedColumn<DateTime> get lastConnected => $composableBuilder(
      column: $table.lastConnected, builder: (column) => column);
}

class $$RememberedSensorsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $RememberedSensorsTable,
    RememberedSensorRow,
    $$RememberedSensorsTableFilterComposer,
    $$RememberedSensorsTableOrderingComposer,
    $$RememberedSensorsTableAnnotationComposer,
    $$RememberedSensorsTableCreateCompanionBuilder,
    $$RememberedSensorsTableUpdateCompanionBuilder,
    (
      RememberedSensorRow,
      BaseReferences<_$AppDatabase, $RememberedSensorsTable,
          RememberedSensorRow>
    ),
    RememberedSensorRow,
    PrefetchHooks Function()> {
  $$RememberedSensorsTableTableManager(
      _$AppDatabase db, $RememberedSensorsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$RememberedSensorsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$RememberedSensorsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$RememberedSensorsTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> deviceId = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<bool> paired = const Value.absent(),
            Value<DateTime?> lastConnected = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              RememberedSensorsCompanion(
            deviceId: deviceId,
            name: name,
            paired: paired,
            lastConnected: lastConnected,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String deviceId,
            required String name,
            Value<bool> paired = const Value.absent(),
            Value<DateTime?> lastConnected = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              RememberedSensorsCompanion.insert(
            deviceId: deviceId,
            name: name,
            paired: paired,
            lastConnected: lastConnected,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$RememberedSensorsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $RememberedSensorsTable,
    RememberedSensorRow,
    $$RememberedSensorsTableFilterComposer,
    $$RememberedSensorsTableOrderingComposer,
    $$RememberedSensorsTableAnnotationComposer,
    $$RememberedSensorsTableCreateCompanionBuilder,
    $$RememberedSensorsTableUpdateCompanionBuilder,
    (
      RememberedSensorRow,
      BaseReferences<_$AppDatabase, $RememberedSensorsTable,
          RememberedSensorRow>
    ),
    RememberedSensorRow,
    PrefetchHooks Function()>;
typedef $$LifestyleEntriesTableCreateCompanionBuilder
    = LifestyleEntriesCompanion Function({
  Value<int> id,
  required DateTime recordedAt,
  required String kind,
  Value<double?> value,
  Value<double?> durationMinutes,
  Value<String?> note,
  Value<String> source,
  Value<DateTime?> syncedAt,
});
typedef $$LifestyleEntriesTableUpdateCompanionBuilder
    = LifestyleEntriesCompanion Function({
  Value<int> id,
  Value<DateTime> recordedAt,
  Value<String> kind,
  Value<double?> value,
  Value<double?> durationMinutes,
  Value<String?> note,
  Value<String> source,
  Value<DateTime?> syncedAt,
});

class $$LifestyleEntriesTableFilterComposer
    extends Composer<_$AppDatabase, $LifestyleEntriesTable> {
  $$LifestyleEntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get recordedAt => $composableBuilder(
      column: $table.recordedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get kind => $composableBuilder(
      column: $table.kind, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get value => $composableBuilder(
      column: $table.value, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get durationMinutes => $composableBuilder(
      column: $table.durationMinutes,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get note => $composableBuilder(
      column: $table.note, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get source => $composableBuilder(
      column: $table.source, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get syncedAt => $composableBuilder(
      column: $table.syncedAt, builder: (column) => ColumnFilters(column));
}

class $$LifestyleEntriesTableOrderingComposer
    extends Composer<_$AppDatabase, $LifestyleEntriesTable> {
  $$LifestyleEntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get recordedAt => $composableBuilder(
      column: $table.recordedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get kind => $composableBuilder(
      column: $table.kind, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get value => $composableBuilder(
      column: $table.value, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get durationMinutes => $composableBuilder(
      column: $table.durationMinutes,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get note => $composableBuilder(
      column: $table.note, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get source => $composableBuilder(
      column: $table.source, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get syncedAt => $composableBuilder(
      column: $table.syncedAt, builder: (column) => ColumnOrderings(column));
}

class $$LifestyleEntriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $LifestyleEntriesTable> {
  $$LifestyleEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get recordedAt => $composableBuilder(
      column: $table.recordedAt, builder: (column) => column);

  GeneratedColumn<String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<double> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);

  GeneratedColumn<double> get durationMinutes => $composableBuilder(
      column: $table.durationMinutes, builder: (column) => column);

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<String> get source =>
      $composableBuilder(column: $table.source, builder: (column) => column);

  GeneratedColumn<DateTime> get syncedAt =>
      $composableBuilder(column: $table.syncedAt, builder: (column) => column);
}

class $$LifestyleEntriesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $LifestyleEntriesTable,
    LifestyleEntryRow,
    $$LifestyleEntriesTableFilterComposer,
    $$LifestyleEntriesTableOrderingComposer,
    $$LifestyleEntriesTableAnnotationComposer,
    $$LifestyleEntriesTableCreateCompanionBuilder,
    $$LifestyleEntriesTableUpdateCompanionBuilder,
    (
      LifestyleEntryRow,
      BaseReferences<_$AppDatabase, $LifestyleEntriesTable, LifestyleEntryRow>
    ),
    LifestyleEntryRow,
    PrefetchHooks Function()> {
  $$LifestyleEntriesTableTableManager(
      _$AppDatabase db, $LifestyleEntriesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LifestyleEntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LifestyleEntriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LifestyleEntriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<DateTime> recordedAt = const Value.absent(),
            Value<String> kind = const Value.absent(),
            Value<double?> value = const Value.absent(),
            Value<double?> durationMinutes = const Value.absent(),
            Value<String?> note = const Value.absent(),
            Value<String> source = const Value.absent(),
            Value<DateTime?> syncedAt = const Value.absent(),
          }) =>
              LifestyleEntriesCompanion(
            id: id,
            recordedAt: recordedAt,
            kind: kind,
            value: value,
            durationMinutes: durationMinutes,
            note: note,
            source: source,
            syncedAt: syncedAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required DateTime recordedAt,
            required String kind,
            Value<double?> value = const Value.absent(),
            Value<double?> durationMinutes = const Value.absent(),
            Value<String?> note = const Value.absent(),
            Value<String> source = const Value.absent(),
            Value<DateTime?> syncedAt = const Value.absent(),
          }) =>
              LifestyleEntriesCompanion.insert(
            id: id,
            recordedAt: recordedAt,
            kind: kind,
            value: value,
            durationMinutes: durationMinutes,
            note: note,
            source: source,
            syncedAt: syncedAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$LifestyleEntriesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $LifestyleEntriesTable,
    LifestyleEntryRow,
    $$LifestyleEntriesTableFilterComposer,
    $$LifestyleEntriesTableOrderingComposer,
    $$LifestyleEntriesTableAnnotationComposer,
    $$LifestyleEntriesTableCreateCompanionBuilder,
    $$LifestyleEntriesTableUpdateCompanionBuilder,
    (
      LifestyleEntryRow,
      BaseReferences<_$AppDatabase, $LifestyleEntriesTable, LifestyleEntryRow>
    ),
    LifestyleEntryRow,
    PrefetchHooks Function()>;
typedef $$JournalEntriesTableCreateCompanionBuilder = JournalEntriesCompanion
    Function({
  Value<int> id,
  required DateTime createdAt,
  required String entryText,
  Value<String> source,
  Value<String> status,
  Value<String?> extractionJson,
  Value<String?> model,
  Value<DateTime?> appliedAt,
  Value<bool> excludedFromAi,
  Value<DateTime?> syncedAt,
});
typedef $$JournalEntriesTableUpdateCompanionBuilder = JournalEntriesCompanion
    Function({
  Value<int> id,
  Value<DateTime> createdAt,
  Value<String> entryText,
  Value<String> source,
  Value<String> status,
  Value<String?> extractionJson,
  Value<String?> model,
  Value<DateTime?> appliedAt,
  Value<bool> excludedFromAi,
  Value<DateTime?> syncedAt,
});

class $$JournalEntriesTableFilterComposer
    extends Composer<_$AppDatabase, $JournalEntriesTable> {
  $$JournalEntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get entryText => $composableBuilder(
      column: $table.entryText, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get source => $composableBuilder(
      column: $table.source, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get extractionJson => $composableBuilder(
      column: $table.extractionJson,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get model => $composableBuilder(
      column: $table.model, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get appliedAt => $composableBuilder(
      column: $table.appliedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get excludedFromAi => $composableBuilder(
      column: $table.excludedFromAi,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get syncedAt => $composableBuilder(
      column: $table.syncedAt, builder: (column) => ColumnFilters(column));
}

class $$JournalEntriesTableOrderingComposer
    extends Composer<_$AppDatabase, $JournalEntriesTable> {
  $$JournalEntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get entryText => $composableBuilder(
      column: $table.entryText, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get source => $composableBuilder(
      column: $table.source, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get extractionJson => $composableBuilder(
      column: $table.extractionJson,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get model => $composableBuilder(
      column: $table.model, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get appliedAt => $composableBuilder(
      column: $table.appliedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get excludedFromAi => $composableBuilder(
      column: $table.excludedFromAi,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get syncedAt => $composableBuilder(
      column: $table.syncedAt, builder: (column) => ColumnOrderings(column));
}

class $$JournalEntriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $JournalEntriesTable> {
  $$JournalEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<String> get entryText =>
      $composableBuilder(column: $table.entryText, builder: (column) => column);

  GeneratedColumn<String> get source =>
      $composableBuilder(column: $table.source, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get extractionJson => $composableBuilder(
      column: $table.extractionJson, builder: (column) => column);

  GeneratedColumn<String> get model =>
      $composableBuilder(column: $table.model, builder: (column) => column);

  GeneratedColumn<DateTime> get appliedAt =>
      $composableBuilder(column: $table.appliedAt, builder: (column) => column);

  GeneratedColumn<bool> get excludedFromAi => $composableBuilder(
      column: $table.excludedFromAi, builder: (column) => column);

  GeneratedColumn<DateTime> get syncedAt =>
      $composableBuilder(column: $table.syncedAt, builder: (column) => column);
}

class $$JournalEntriesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $JournalEntriesTable,
    JournalEntryRow,
    $$JournalEntriesTableFilterComposer,
    $$JournalEntriesTableOrderingComposer,
    $$JournalEntriesTableAnnotationComposer,
    $$JournalEntriesTableCreateCompanionBuilder,
    $$JournalEntriesTableUpdateCompanionBuilder,
    (
      JournalEntryRow,
      BaseReferences<_$AppDatabase, $JournalEntriesTable, JournalEntryRow>
    ),
    JournalEntryRow,
    PrefetchHooks Function()> {
  $$JournalEntriesTableTableManager(
      _$AppDatabase db, $JournalEntriesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$JournalEntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$JournalEntriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$JournalEntriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<String> entryText = const Value.absent(),
            Value<String> source = const Value.absent(),
            Value<String> status = const Value.absent(),
            Value<String?> extractionJson = const Value.absent(),
            Value<String?> model = const Value.absent(),
            Value<DateTime?> appliedAt = const Value.absent(),
            Value<bool> excludedFromAi = const Value.absent(),
            Value<DateTime?> syncedAt = const Value.absent(),
          }) =>
              JournalEntriesCompanion(
            id: id,
            createdAt: createdAt,
            entryText: entryText,
            source: source,
            status: status,
            extractionJson: extractionJson,
            model: model,
            appliedAt: appliedAt,
            excludedFromAi: excludedFromAi,
            syncedAt: syncedAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required DateTime createdAt,
            required String entryText,
            Value<String> source = const Value.absent(),
            Value<String> status = const Value.absent(),
            Value<String?> extractionJson = const Value.absent(),
            Value<String?> model = const Value.absent(),
            Value<DateTime?> appliedAt = const Value.absent(),
            Value<bool> excludedFromAi = const Value.absent(),
            Value<DateTime?> syncedAt = const Value.absent(),
          }) =>
              JournalEntriesCompanion.insert(
            id: id,
            createdAt: createdAt,
            entryText: entryText,
            source: source,
            status: status,
            extractionJson: extractionJson,
            model: model,
            appliedAt: appliedAt,
            excludedFromAi: excludedFromAi,
            syncedAt: syncedAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$JournalEntriesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $JournalEntriesTable,
    JournalEntryRow,
    $$JournalEntriesTableFilterComposer,
    $$JournalEntriesTableOrderingComposer,
    $$JournalEntriesTableAnnotationComposer,
    $$JournalEntriesTableCreateCompanionBuilder,
    $$JournalEntriesTableUpdateCompanionBuilder,
    (
      JournalEntryRow,
      BaseReferences<_$AppDatabase, $JournalEntriesTable, JournalEntryRow>
    ),
    JournalEntryRow,
    PrefetchHooks Function()>;
typedef $$GuidanceHistoryTableCreateCompanionBuilder = GuidanceHistoryCompanion
    Function({
  Value<int> id,
  required String date,
  required String dimension,
  required DateTime generatedAt,
  required String contentJson,
  Value<String?> evidenceJson,
  required String contextFingerprint,
  required String source,
  Value<DateTime?> syncedAt,
});
typedef $$GuidanceHistoryTableUpdateCompanionBuilder = GuidanceHistoryCompanion
    Function({
  Value<int> id,
  Value<String> date,
  Value<String> dimension,
  Value<DateTime> generatedAt,
  Value<String> contentJson,
  Value<String?> evidenceJson,
  Value<String> contextFingerprint,
  Value<String> source,
  Value<DateTime?> syncedAt,
});

class $$GuidanceHistoryTableFilterComposer
    extends Composer<_$AppDatabase, $GuidanceHistoryTable> {
  $$GuidanceHistoryTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get date => $composableBuilder(
      column: $table.date, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get dimension => $composableBuilder(
      column: $table.dimension, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get generatedAt => $composableBuilder(
      column: $table.generatedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get contentJson => $composableBuilder(
      column: $table.contentJson, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get evidenceJson => $composableBuilder(
      column: $table.evidenceJson, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get contextFingerprint => $composableBuilder(
      column: $table.contextFingerprint,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get source => $composableBuilder(
      column: $table.source, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get syncedAt => $composableBuilder(
      column: $table.syncedAt, builder: (column) => ColumnFilters(column));
}

class $$GuidanceHistoryTableOrderingComposer
    extends Composer<_$AppDatabase, $GuidanceHistoryTable> {
  $$GuidanceHistoryTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get date => $composableBuilder(
      column: $table.date, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get dimension => $composableBuilder(
      column: $table.dimension, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get generatedAt => $composableBuilder(
      column: $table.generatedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get contentJson => $composableBuilder(
      column: $table.contentJson, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get evidenceJson => $composableBuilder(
      column: $table.evidenceJson,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get contextFingerprint => $composableBuilder(
      column: $table.contextFingerprint,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get source => $composableBuilder(
      column: $table.source, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get syncedAt => $composableBuilder(
      column: $table.syncedAt, builder: (column) => ColumnOrderings(column));
}

class $$GuidanceHistoryTableAnnotationComposer
    extends Composer<_$AppDatabase, $GuidanceHistoryTable> {
  $$GuidanceHistoryTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumn<String> get dimension =>
      $composableBuilder(column: $table.dimension, builder: (column) => column);

  GeneratedColumn<DateTime> get generatedAt => $composableBuilder(
      column: $table.generatedAt, builder: (column) => column);

  GeneratedColumn<String> get contentJson => $composableBuilder(
      column: $table.contentJson, builder: (column) => column);

  GeneratedColumn<String> get evidenceJson => $composableBuilder(
      column: $table.evidenceJson, builder: (column) => column);

  GeneratedColumn<String> get contextFingerprint => $composableBuilder(
      column: $table.contextFingerprint, builder: (column) => column);

  GeneratedColumn<String> get source =>
      $composableBuilder(column: $table.source, builder: (column) => column);

  GeneratedColumn<DateTime> get syncedAt =>
      $composableBuilder(column: $table.syncedAt, builder: (column) => column);
}

class $$GuidanceHistoryTableTableManager extends RootTableManager<
    _$AppDatabase,
    $GuidanceHistoryTable,
    GuidanceHistoryRow,
    $$GuidanceHistoryTableFilterComposer,
    $$GuidanceHistoryTableOrderingComposer,
    $$GuidanceHistoryTableAnnotationComposer,
    $$GuidanceHistoryTableCreateCompanionBuilder,
    $$GuidanceHistoryTableUpdateCompanionBuilder,
    (
      GuidanceHistoryRow,
      BaseReferences<_$AppDatabase, $GuidanceHistoryTable, GuidanceHistoryRow>
    ),
    GuidanceHistoryRow,
    PrefetchHooks Function()> {
  $$GuidanceHistoryTableTableManager(
      _$AppDatabase db, $GuidanceHistoryTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$GuidanceHistoryTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$GuidanceHistoryTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$GuidanceHistoryTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> date = const Value.absent(),
            Value<String> dimension = const Value.absent(),
            Value<DateTime> generatedAt = const Value.absent(),
            Value<String> contentJson = const Value.absent(),
            Value<String?> evidenceJson = const Value.absent(),
            Value<String> contextFingerprint = const Value.absent(),
            Value<String> source = const Value.absent(),
            Value<DateTime?> syncedAt = const Value.absent(),
          }) =>
              GuidanceHistoryCompanion(
            id: id,
            date: date,
            dimension: dimension,
            generatedAt: generatedAt,
            contentJson: contentJson,
            evidenceJson: evidenceJson,
            contextFingerprint: contextFingerprint,
            source: source,
            syncedAt: syncedAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String date,
            required String dimension,
            required DateTime generatedAt,
            required String contentJson,
            Value<String?> evidenceJson = const Value.absent(),
            required String contextFingerprint,
            required String source,
            Value<DateTime?> syncedAt = const Value.absent(),
          }) =>
              GuidanceHistoryCompanion.insert(
            id: id,
            date: date,
            dimension: dimension,
            generatedAt: generatedAt,
            contentJson: contentJson,
            evidenceJson: evidenceJson,
            contextFingerprint: contextFingerprint,
            source: source,
            syncedAt: syncedAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$GuidanceHistoryTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $GuidanceHistoryTable,
    GuidanceHistoryRow,
    $$GuidanceHistoryTableFilterComposer,
    $$GuidanceHistoryTableOrderingComposer,
    $$GuidanceHistoryTableAnnotationComposer,
    $$GuidanceHistoryTableCreateCompanionBuilder,
    $$GuidanceHistoryTableUpdateCompanionBuilder,
    (
      GuidanceHistoryRow,
      BaseReferences<_$AppDatabase, $GuidanceHistoryTable, GuidanceHistoryRow>
    ),
    GuidanceHistoryRow,
    PrefetchHooks Function()>;
typedef $$VesselReadingsTableCreateCompanionBuilder = VesselReadingsCompanion
    Function({
  required String inputHash,
  required String positionKey,
  required DateTime createdAt,
  required String contentJson,
  required String model,
  Value<DateTime?> syncedAt,
  Value<int> rowid,
});
typedef $$VesselReadingsTableUpdateCompanionBuilder = VesselReadingsCompanion
    Function({
  Value<String> inputHash,
  Value<String> positionKey,
  Value<DateTime> createdAt,
  Value<String> contentJson,
  Value<String> model,
  Value<DateTime?> syncedAt,
  Value<int> rowid,
});

class $$VesselReadingsTableFilterComposer
    extends Composer<_$AppDatabase, $VesselReadingsTable> {
  $$VesselReadingsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get inputHash => $composableBuilder(
      column: $table.inputHash, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get positionKey => $composableBuilder(
      column: $table.positionKey, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get contentJson => $composableBuilder(
      column: $table.contentJson, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get model => $composableBuilder(
      column: $table.model, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get syncedAt => $composableBuilder(
      column: $table.syncedAt, builder: (column) => ColumnFilters(column));
}

class $$VesselReadingsTableOrderingComposer
    extends Composer<_$AppDatabase, $VesselReadingsTable> {
  $$VesselReadingsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get inputHash => $composableBuilder(
      column: $table.inputHash, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get positionKey => $composableBuilder(
      column: $table.positionKey, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get contentJson => $composableBuilder(
      column: $table.contentJson, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get model => $composableBuilder(
      column: $table.model, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get syncedAt => $composableBuilder(
      column: $table.syncedAt, builder: (column) => ColumnOrderings(column));
}

class $$VesselReadingsTableAnnotationComposer
    extends Composer<_$AppDatabase, $VesselReadingsTable> {
  $$VesselReadingsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get inputHash =>
      $composableBuilder(column: $table.inputHash, builder: (column) => column);

  GeneratedColumn<String> get positionKey => $composableBuilder(
      column: $table.positionKey, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<String> get contentJson => $composableBuilder(
      column: $table.contentJson, builder: (column) => column);

  GeneratedColumn<String> get model =>
      $composableBuilder(column: $table.model, builder: (column) => column);

  GeneratedColumn<DateTime> get syncedAt =>
      $composableBuilder(column: $table.syncedAt, builder: (column) => column);
}

class $$VesselReadingsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $VesselReadingsTable,
    VesselReadingRow,
    $$VesselReadingsTableFilterComposer,
    $$VesselReadingsTableOrderingComposer,
    $$VesselReadingsTableAnnotationComposer,
    $$VesselReadingsTableCreateCompanionBuilder,
    $$VesselReadingsTableUpdateCompanionBuilder,
    (
      VesselReadingRow,
      BaseReferences<_$AppDatabase, $VesselReadingsTable, VesselReadingRow>
    ),
    VesselReadingRow,
    PrefetchHooks Function()> {
  $$VesselReadingsTableTableManager(
      _$AppDatabase db, $VesselReadingsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$VesselReadingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$VesselReadingsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$VesselReadingsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> inputHash = const Value.absent(),
            Value<String> positionKey = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<String> contentJson = const Value.absent(),
            Value<String> model = const Value.absent(),
            Value<DateTime?> syncedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              VesselReadingsCompanion(
            inputHash: inputHash,
            positionKey: positionKey,
            createdAt: createdAt,
            contentJson: contentJson,
            model: model,
            syncedAt: syncedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String inputHash,
            required String positionKey,
            required DateTime createdAt,
            required String contentJson,
            required String model,
            Value<DateTime?> syncedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              VesselReadingsCompanion.insert(
            inputHash: inputHash,
            positionKey: positionKey,
            createdAt: createdAt,
            contentJson: contentJson,
            model: model,
            syncedAt: syncedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$VesselReadingsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $VesselReadingsTable,
    VesselReadingRow,
    $$VesselReadingsTableFilterComposer,
    $$VesselReadingsTableOrderingComposer,
    $$VesselReadingsTableAnnotationComposer,
    $$VesselReadingsTableCreateCompanionBuilder,
    $$VesselReadingsTableUpdateCompanionBuilder,
    (
      VesselReadingRow,
      BaseReferences<_$AppDatabase, $VesselReadingsTable, VesselReadingRow>
    ),
    VesselReadingRow,
    PrefetchHooks Function()>;
typedef $$DailyCardsTableCreateCompanionBuilder = DailyCardsCompanion Function({
  required String date,
  required String arcanaSlug,
  required String reason,
  Value<String> sourceJson,
  Value<DateTime?> syncedAt,
  Value<int> rowid,
});
typedef $$DailyCardsTableUpdateCompanionBuilder = DailyCardsCompanion Function({
  Value<String> date,
  Value<String> arcanaSlug,
  Value<String> reason,
  Value<String> sourceJson,
  Value<DateTime?> syncedAt,
  Value<int> rowid,
});

class $$DailyCardsTableFilterComposer
    extends Composer<_$AppDatabase, $DailyCardsTable> {
  $$DailyCardsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get date => $composableBuilder(
      column: $table.date, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get arcanaSlug => $composableBuilder(
      column: $table.arcanaSlug, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get reason => $composableBuilder(
      column: $table.reason, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get sourceJson => $composableBuilder(
      column: $table.sourceJson, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get syncedAt => $composableBuilder(
      column: $table.syncedAt, builder: (column) => ColumnFilters(column));
}

class $$DailyCardsTableOrderingComposer
    extends Composer<_$AppDatabase, $DailyCardsTable> {
  $$DailyCardsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get date => $composableBuilder(
      column: $table.date, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get arcanaSlug => $composableBuilder(
      column: $table.arcanaSlug, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get reason => $composableBuilder(
      column: $table.reason, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get sourceJson => $composableBuilder(
      column: $table.sourceJson, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get syncedAt => $composableBuilder(
      column: $table.syncedAt, builder: (column) => ColumnOrderings(column));
}

class $$DailyCardsTableAnnotationComposer
    extends Composer<_$AppDatabase, $DailyCardsTable> {
  $$DailyCardsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumn<String> get arcanaSlug => $composableBuilder(
      column: $table.arcanaSlug, builder: (column) => column);

  GeneratedColumn<String> get reason =>
      $composableBuilder(column: $table.reason, builder: (column) => column);

  GeneratedColumn<String> get sourceJson => $composableBuilder(
      column: $table.sourceJson, builder: (column) => column);

  GeneratedColumn<DateTime> get syncedAt =>
      $composableBuilder(column: $table.syncedAt, builder: (column) => column);
}

class $$DailyCardsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $DailyCardsTable,
    DailyCardRow,
    $$DailyCardsTableFilterComposer,
    $$DailyCardsTableOrderingComposer,
    $$DailyCardsTableAnnotationComposer,
    $$DailyCardsTableCreateCompanionBuilder,
    $$DailyCardsTableUpdateCompanionBuilder,
    (
      DailyCardRow,
      BaseReferences<_$AppDatabase, $DailyCardsTable, DailyCardRow>
    ),
    DailyCardRow,
    PrefetchHooks Function()> {
  $$DailyCardsTableTableManager(_$AppDatabase db, $DailyCardsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DailyCardsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DailyCardsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DailyCardsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> date = const Value.absent(),
            Value<String> arcanaSlug = const Value.absent(),
            Value<String> reason = const Value.absent(),
            Value<String> sourceJson = const Value.absent(),
            Value<DateTime?> syncedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              DailyCardsCompanion(
            date: date,
            arcanaSlug: arcanaSlug,
            reason: reason,
            sourceJson: sourceJson,
            syncedAt: syncedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String date,
            required String arcanaSlug,
            required String reason,
            Value<String> sourceJson = const Value.absent(),
            Value<DateTime?> syncedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              DailyCardsCompanion.insert(
            date: date,
            arcanaSlug: arcanaSlug,
            reason: reason,
            sourceJson: sourceJson,
            syncedAt: syncedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$DailyCardsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $DailyCardsTable,
    DailyCardRow,
    $$DailyCardsTableFilterComposer,
    $$DailyCardsTableOrderingComposer,
    $$DailyCardsTableAnnotationComposer,
    $$DailyCardsTableCreateCompanionBuilder,
    $$DailyCardsTableUpdateCompanionBuilder,
    (
      DailyCardRow,
      BaseReferences<_$AppDatabase, $DailyCardsTable, DailyCardRow>
    ),
    DailyCardRow,
    PrefetchHooks Function()>;
typedef $$PatternCandidatesTableCreateCompanionBuilder
    = PatternCandidatesCompanion Function({
  required String key,
  required DateTime computedAt,
  required String summary,
  required String evidenceJson,
  required double confidence,
  Value<String> status,
  Value<int> rowid,
});
typedef $$PatternCandidatesTableUpdateCompanionBuilder
    = PatternCandidatesCompanion Function({
  Value<String> key,
  Value<DateTime> computedAt,
  Value<String> summary,
  Value<String> evidenceJson,
  Value<double> confidence,
  Value<String> status,
  Value<int> rowid,
});

class $$PatternCandidatesTableFilterComposer
    extends Composer<_$AppDatabase, $PatternCandidatesTable> {
  $$PatternCandidatesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get key => $composableBuilder(
      column: $table.key, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get computedAt => $composableBuilder(
      column: $table.computedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get summary => $composableBuilder(
      column: $table.summary, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get evidenceJson => $composableBuilder(
      column: $table.evidenceJson, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get confidence => $composableBuilder(
      column: $table.confidence, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnFilters(column));
}

class $$PatternCandidatesTableOrderingComposer
    extends Composer<_$AppDatabase, $PatternCandidatesTable> {
  $$PatternCandidatesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get key => $composableBuilder(
      column: $table.key, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get computedAt => $composableBuilder(
      column: $table.computedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get summary => $composableBuilder(
      column: $table.summary, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get evidenceJson => $composableBuilder(
      column: $table.evidenceJson,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get confidence => $composableBuilder(
      column: $table.confidence, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnOrderings(column));
}

class $$PatternCandidatesTableAnnotationComposer
    extends Composer<_$AppDatabase, $PatternCandidatesTable> {
  $$PatternCandidatesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<DateTime> get computedAt => $composableBuilder(
      column: $table.computedAt, builder: (column) => column);

  GeneratedColumn<String> get summary =>
      $composableBuilder(column: $table.summary, builder: (column) => column);

  GeneratedColumn<String> get evidenceJson => $composableBuilder(
      column: $table.evidenceJson, builder: (column) => column);

  GeneratedColumn<double> get confidence => $composableBuilder(
      column: $table.confidence, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);
}

class $$PatternCandidatesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $PatternCandidatesTable,
    PatternCandidateRow,
    $$PatternCandidatesTableFilterComposer,
    $$PatternCandidatesTableOrderingComposer,
    $$PatternCandidatesTableAnnotationComposer,
    $$PatternCandidatesTableCreateCompanionBuilder,
    $$PatternCandidatesTableUpdateCompanionBuilder,
    (
      PatternCandidateRow,
      BaseReferences<_$AppDatabase, $PatternCandidatesTable,
          PatternCandidateRow>
    ),
    PatternCandidateRow,
    PrefetchHooks Function()> {
  $$PatternCandidatesTableTableManager(
      _$AppDatabase db, $PatternCandidatesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PatternCandidatesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PatternCandidatesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PatternCandidatesTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> key = const Value.absent(),
            Value<DateTime> computedAt = const Value.absent(),
            Value<String> summary = const Value.absent(),
            Value<String> evidenceJson = const Value.absent(),
            Value<double> confidence = const Value.absent(),
            Value<String> status = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              PatternCandidatesCompanion(
            key: key,
            computedAt: computedAt,
            summary: summary,
            evidenceJson: evidenceJson,
            confidence: confidence,
            status: status,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String key,
            required DateTime computedAt,
            required String summary,
            required String evidenceJson,
            required double confidence,
            Value<String> status = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              PatternCandidatesCompanion.insert(
            key: key,
            computedAt: computedAt,
            summary: summary,
            evidenceJson: evidenceJson,
            confidence: confidence,
            status: status,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$PatternCandidatesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $PatternCandidatesTable,
    PatternCandidateRow,
    $$PatternCandidatesTableFilterComposer,
    $$PatternCandidatesTableOrderingComposer,
    $$PatternCandidatesTableAnnotationComposer,
    $$PatternCandidatesTableCreateCompanionBuilder,
    $$PatternCandidatesTableUpdateCompanionBuilder,
    (
      PatternCandidateRow,
      BaseReferences<_$AppDatabase, $PatternCandidatesTable,
          PatternCandidateRow>
    ),
    PatternCandidateRow,
    PrefetchHooks Function()>;
typedef $$RetrospectivesTableCreateCompanionBuilder = RetrospectivesCompanion
    Function({
  required String id,
  required String kind,
  required String periodStart,
  required String periodEnd,
  required DateTime generatedAt,
  required String contentJson,
  Value<String?> evidenceJson,
  required String model,
  Value<DateTime?> syncedAt,
  Value<int> rowid,
});
typedef $$RetrospectivesTableUpdateCompanionBuilder = RetrospectivesCompanion
    Function({
  Value<String> id,
  Value<String> kind,
  Value<String> periodStart,
  Value<String> periodEnd,
  Value<DateTime> generatedAt,
  Value<String> contentJson,
  Value<String?> evidenceJson,
  Value<String> model,
  Value<DateTime?> syncedAt,
  Value<int> rowid,
});

class $$RetrospectivesTableFilterComposer
    extends Composer<_$AppDatabase, $RetrospectivesTable> {
  $$RetrospectivesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get kind => $composableBuilder(
      column: $table.kind, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get periodStart => $composableBuilder(
      column: $table.periodStart, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get periodEnd => $composableBuilder(
      column: $table.periodEnd, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get generatedAt => $composableBuilder(
      column: $table.generatedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get contentJson => $composableBuilder(
      column: $table.contentJson, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get evidenceJson => $composableBuilder(
      column: $table.evidenceJson, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get model => $composableBuilder(
      column: $table.model, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get syncedAt => $composableBuilder(
      column: $table.syncedAt, builder: (column) => ColumnFilters(column));
}

class $$RetrospectivesTableOrderingComposer
    extends Composer<_$AppDatabase, $RetrospectivesTable> {
  $$RetrospectivesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get kind => $composableBuilder(
      column: $table.kind, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get periodStart => $composableBuilder(
      column: $table.periodStart, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get periodEnd => $composableBuilder(
      column: $table.periodEnd, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get generatedAt => $composableBuilder(
      column: $table.generatedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get contentJson => $composableBuilder(
      column: $table.contentJson, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get evidenceJson => $composableBuilder(
      column: $table.evidenceJson,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get model => $composableBuilder(
      column: $table.model, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get syncedAt => $composableBuilder(
      column: $table.syncedAt, builder: (column) => ColumnOrderings(column));
}

class $$RetrospectivesTableAnnotationComposer
    extends Composer<_$AppDatabase, $RetrospectivesTable> {
  $$RetrospectivesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<String> get periodStart => $composableBuilder(
      column: $table.periodStart, builder: (column) => column);

  GeneratedColumn<String> get periodEnd =>
      $composableBuilder(column: $table.periodEnd, builder: (column) => column);

  GeneratedColumn<DateTime> get generatedAt => $composableBuilder(
      column: $table.generatedAt, builder: (column) => column);

  GeneratedColumn<String> get contentJson => $composableBuilder(
      column: $table.contentJson, builder: (column) => column);

  GeneratedColumn<String> get evidenceJson => $composableBuilder(
      column: $table.evidenceJson, builder: (column) => column);

  GeneratedColumn<String> get model =>
      $composableBuilder(column: $table.model, builder: (column) => column);

  GeneratedColumn<DateTime> get syncedAt =>
      $composableBuilder(column: $table.syncedAt, builder: (column) => column);
}

class $$RetrospectivesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $RetrospectivesTable,
    RetrospectiveRow,
    $$RetrospectivesTableFilterComposer,
    $$RetrospectivesTableOrderingComposer,
    $$RetrospectivesTableAnnotationComposer,
    $$RetrospectivesTableCreateCompanionBuilder,
    $$RetrospectivesTableUpdateCompanionBuilder,
    (
      RetrospectiveRow,
      BaseReferences<_$AppDatabase, $RetrospectivesTable, RetrospectiveRow>
    ),
    RetrospectiveRow,
    PrefetchHooks Function()> {
  $$RetrospectivesTableTableManager(
      _$AppDatabase db, $RetrospectivesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$RetrospectivesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$RetrospectivesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$RetrospectivesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> kind = const Value.absent(),
            Value<String> periodStart = const Value.absent(),
            Value<String> periodEnd = const Value.absent(),
            Value<DateTime> generatedAt = const Value.absent(),
            Value<String> contentJson = const Value.absent(),
            Value<String?> evidenceJson = const Value.absent(),
            Value<String> model = const Value.absent(),
            Value<DateTime?> syncedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              RetrospectivesCompanion(
            id: id,
            kind: kind,
            periodStart: periodStart,
            periodEnd: periodEnd,
            generatedAt: generatedAt,
            contentJson: contentJson,
            evidenceJson: evidenceJson,
            model: model,
            syncedAt: syncedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String kind,
            required String periodStart,
            required String periodEnd,
            required DateTime generatedAt,
            required String contentJson,
            Value<String?> evidenceJson = const Value.absent(),
            required String model,
            Value<DateTime?> syncedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              RetrospectivesCompanion.insert(
            id: id,
            kind: kind,
            periodStart: periodStart,
            periodEnd: periodEnd,
            generatedAt: generatedAt,
            contentJson: contentJson,
            evidenceJson: evidenceJson,
            model: model,
            syncedAt: syncedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$RetrospectivesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $RetrospectivesTable,
    RetrospectiveRow,
    $$RetrospectivesTableFilterComposer,
    $$RetrospectivesTableOrderingComposer,
    $$RetrospectivesTableAnnotationComposer,
    $$RetrospectivesTableCreateCompanionBuilder,
    $$RetrospectivesTableUpdateCompanionBuilder,
    (
      RetrospectiveRow,
      BaseReferences<_$AppDatabase, $RetrospectivesTable, RetrospectiveRow>
    ),
    RetrospectiveRow,
    PrefetchHooks Function()>;
typedef $$IntakeAnswersTableCreateCompanionBuilder = IntakeAnswersCompanion
    Function({
  required String key,
  required String value,
  Value<String> tier,
  required DateTime updatedAt,
  Value<DateTime?> syncedAt,
  Value<int> rowid,
});
typedef $$IntakeAnswersTableUpdateCompanionBuilder = IntakeAnswersCompanion
    Function({
  Value<String> key,
  Value<String> value,
  Value<String> tier,
  Value<DateTime> updatedAt,
  Value<DateTime?> syncedAt,
  Value<int> rowid,
});

class $$IntakeAnswersTableFilterComposer
    extends Composer<_$AppDatabase, $IntakeAnswersTable> {
  $$IntakeAnswersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get key => $composableBuilder(
      column: $table.key, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get value => $composableBuilder(
      column: $table.value, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get tier => $composableBuilder(
      column: $table.tier, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get syncedAt => $composableBuilder(
      column: $table.syncedAt, builder: (column) => ColumnFilters(column));
}

class $$IntakeAnswersTableOrderingComposer
    extends Composer<_$AppDatabase, $IntakeAnswersTable> {
  $$IntakeAnswersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get key => $composableBuilder(
      column: $table.key, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get value => $composableBuilder(
      column: $table.value, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get tier => $composableBuilder(
      column: $table.tier, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get syncedAt => $composableBuilder(
      column: $table.syncedAt, builder: (column) => ColumnOrderings(column));
}

class $$IntakeAnswersTableAnnotationComposer
    extends Composer<_$AppDatabase, $IntakeAnswersTable> {
  $$IntakeAnswersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);

  GeneratedColumn<String> get tier =>
      $composableBuilder(column: $table.tier, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get syncedAt =>
      $composableBuilder(column: $table.syncedAt, builder: (column) => column);
}

class $$IntakeAnswersTableTableManager extends RootTableManager<
    _$AppDatabase,
    $IntakeAnswersTable,
    IntakeAnswerRow,
    $$IntakeAnswersTableFilterComposer,
    $$IntakeAnswersTableOrderingComposer,
    $$IntakeAnswersTableAnnotationComposer,
    $$IntakeAnswersTableCreateCompanionBuilder,
    $$IntakeAnswersTableUpdateCompanionBuilder,
    (
      IntakeAnswerRow,
      BaseReferences<_$AppDatabase, $IntakeAnswersTable, IntakeAnswerRow>
    ),
    IntakeAnswerRow,
    PrefetchHooks Function()> {
  $$IntakeAnswersTableTableManager(_$AppDatabase db, $IntakeAnswersTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$IntakeAnswersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$IntakeAnswersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$IntakeAnswersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> key = const Value.absent(),
            Value<String> value = const Value.absent(),
            Value<String> tier = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<DateTime?> syncedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              IntakeAnswersCompanion(
            key: key,
            value: value,
            tier: tier,
            updatedAt: updatedAt,
            syncedAt: syncedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String key,
            required String value,
            Value<String> tier = const Value.absent(),
            required DateTime updatedAt,
            Value<DateTime?> syncedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              IntakeAnswersCompanion.insert(
            key: key,
            value: value,
            tier: tier,
            updatedAt: updatedAt,
            syncedAt: syncedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$IntakeAnswersTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $IntakeAnswersTable,
    IntakeAnswerRow,
    $$IntakeAnswersTableFilterComposer,
    $$IntakeAnswersTableOrderingComposer,
    $$IntakeAnswersTableAnnotationComposer,
    $$IntakeAnswersTableCreateCompanionBuilder,
    $$IntakeAnswersTableUpdateCompanionBuilder,
    (
      IntakeAnswerRow,
      BaseReferences<_$AppDatabase, $IntakeAnswersTable, IntakeAnswerRow>
    ),
    IntakeAnswerRow,
    PrefetchHooks Function()>;
typedef $$JournalDayStoriesTableCreateCompanionBuilder
    = JournalDayStoriesCompanion Function({
  required String date,
  required DateTime generatedAt,
  required String story,
  Value<String> digestJson,
  Value<int> entryCount,
  required String sourceFingerprint,
  Value<String> model,
  Value<DateTime?> syncedAt,
  Value<int> rowid,
});
typedef $$JournalDayStoriesTableUpdateCompanionBuilder
    = JournalDayStoriesCompanion Function({
  Value<String> date,
  Value<DateTime> generatedAt,
  Value<String> story,
  Value<String> digestJson,
  Value<int> entryCount,
  Value<String> sourceFingerprint,
  Value<String> model,
  Value<DateTime?> syncedAt,
  Value<int> rowid,
});

class $$JournalDayStoriesTableFilterComposer
    extends Composer<_$AppDatabase, $JournalDayStoriesTable> {
  $$JournalDayStoriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get date => $composableBuilder(
      column: $table.date, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get generatedAt => $composableBuilder(
      column: $table.generatedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get story => $composableBuilder(
      column: $table.story, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get digestJson => $composableBuilder(
      column: $table.digestJson, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get entryCount => $composableBuilder(
      column: $table.entryCount, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get sourceFingerprint => $composableBuilder(
      column: $table.sourceFingerprint,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get model => $composableBuilder(
      column: $table.model, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get syncedAt => $composableBuilder(
      column: $table.syncedAt, builder: (column) => ColumnFilters(column));
}

class $$JournalDayStoriesTableOrderingComposer
    extends Composer<_$AppDatabase, $JournalDayStoriesTable> {
  $$JournalDayStoriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get date => $composableBuilder(
      column: $table.date, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get generatedAt => $composableBuilder(
      column: $table.generatedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get story => $composableBuilder(
      column: $table.story, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get digestJson => $composableBuilder(
      column: $table.digestJson, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get entryCount => $composableBuilder(
      column: $table.entryCount, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get sourceFingerprint => $composableBuilder(
      column: $table.sourceFingerprint,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get model => $composableBuilder(
      column: $table.model, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get syncedAt => $composableBuilder(
      column: $table.syncedAt, builder: (column) => ColumnOrderings(column));
}

class $$JournalDayStoriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $JournalDayStoriesTable> {
  $$JournalDayStoriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumn<DateTime> get generatedAt => $composableBuilder(
      column: $table.generatedAt, builder: (column) => column);

  GeneratedColumn<String> get story =>
      $composableBuilder(column: $table.story, builder: (column) => column);

  GeneratedColumn<String> get digestJson => $composableBuilder(
      column: $table.digestJson, builder: (column) => column);

  GeneratedColumn<int> get entryCount => $composableBuilder(
      column: $table.entryCount, builder: (column) => column);

  GeneratedColumn<String> get sourceFingerprint => $composableBuilder(
      column: $table.sourceFingerprint, builder: (column) => column);

  GeneratedColumn<String> get model =>
      $composableBuilder(column: $table.model, builder: (column) => column);

  GeneratedColumn<DateTime> get syncedAt =>
      $composableBuilder(column: $table.syncedAt, builder: (column) => column);
}

class $$JournalDayStoriesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $JournalDayStoriesTable,
    JournalDayStoryRow,
    $$JournalDayStoriesTableFilterComposer,
    $$JournalDayStoriesTableOrderingComposer,
    $$JournalDayStoriesTableAnnotationComposer,
    $$JournalDayStoriesTableCreateCompanionBuilder,
    $$JournalDayStoriesTableUpdateCompanionBuilder,
    (
      JournalDayStoryRow,
      BaseReferences<_$AppDatabase, $JournalDayStoriesTable, JournalDayStoryRow>
    ),
    JournalDayStoryRow,
    PrefetchHooks Function()> {
  $$JournalDayStoriesTableTableManager(
      _$AppDatabase db, $JournalDayStoriesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$JournalDayStoriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$JournalDayStoriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$JournalDayStoriesTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> date = const Value.absent(),
            Value<DateTime> generatedAt = const Value.absent(),
            Value<String> story = const Value.absent(),
            Value<String> digestJson = const Value.absent(),
            Value<int> entryCount = const Value.absent(),
            Value<String> sourceFingerprint = const Value.absent(),
            Value<String> model = const Value.absent(),
            Value<DateTime?> syncedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              JournalDayStoriesCompanion(
            date: date,
            generatedAt: generatedAt,
            story: story,
            digestJson: digestJson,
            entryCount: entryCount,
            sourceFingerprint: sourceFingerprint,
            model: model,
            syncedAt: syncedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String date,
            required DateTime generatedAt,
            required String story,
            Value<String> digestJson = const Value.absent(),
            Value<int> entryCount = const Value.absent(),
            required String sourceFingerprint,
            Value<String> model = const Value.absent(),
            Value<DateTime?> syncedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              JournalDayStoriesCompanion.insert(
            date: date,
            generatedAt: generatedAt,
            story: story,
            digestJson: digestJson,
            entryCount: entryCount,
            sourceFingerprint: sourceFingerprint,
            model: model,
            syncedAt: syncedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$JournalDayStoriesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $JournalDayStoriesTable,
    JournalDayStoryRow,
    $$JournalDayStoriesTableFilterComposer,
    $$JournalDayStoriesTableOrderingComposer,
    $$JournalDayStoriesTableAnnotationComposer,
    $$JournalDayStoriesTableCreateCompanionBuilder,
    $$JournalDayStoriesTableUpdateCompanionBuilder,
    (
      JournalDayStoryRow,
      BaseReferences<_$AppDatabase, $JournalDayStoriesTable, JournalDayStoryRow>
    ),
    JournalDayStoryRow,
    PrefetchHooks Function()>;
typedef $$TransitReadingsTableCreateCompanionBuilder = TransitReadingsCompanion
    Function({
  required String date,
  required String inputHash,
  required DateTime generatedAt,
  required String contactsJson,
  required String passage,
  Value<String> model,
  Value<DateTime?> syncedAt,
  Value<int> rowid,
});
typedef $$TransitReadingsTableUpdateCompanionBuilder = TransitReadingsCompanion
    Function({
  Value<String> date,
  Value<String> inputHash,
  Value<DateTime> generatedAt,
  Value<String> contactsJson,
  Value<String> passage,
  Value<String> model,
  Value<DateTime?> syncedAt,
  Value<int> rowid,
});

class $$TransitReadingsTableFilterComposer
    extends Composer<_$AppDatabase, $TransitReadingsTable> {
  $$TransitReadingsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get date => $composableBuilder(
      column: $table.date, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get inputHash => $composableBuilder(
      column: $table.inputHash, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get generatedAt => $composableBuilder(
      column: $table.generatedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get contactsJson => $composableBuilder(
      column: $table.contactsJson, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get passage => $composableBuilder(
      column: $table.passage, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get model => $composableBuilder(
      column: $table.model, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get syncedAt => $composableBuilder(
      column: $table.syncedAt, builder: (column) => ColumnFilters(column));
}

class $$TransitReadingsTableOrderingComposer
    extends Composer<_$AppDatabase, $TransitReadingsTable> {
  $$TransitReadingsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get date => $composableBuilder(
      column: $table.date, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get inputHash => $composableBuilder(
      column: $table.inputHash, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get generatedAt => $composableBuilder(
      column: $table.generatedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get contactsJson => $composableBuilder(
      column: $table.contactsJson,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get passage => $composableBuilder(
      column: $table.passage, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get model => $composableBuilder(
      column: $table.model, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get syncedAt => $composableBuilder(
      column: $table.syncedAt, builder: (column) => ColumnOrderings(column));
}

class $$TransitReadingsTableAnnotationComposer
    extends Composer<_$AppDatabase, $TransitReadingsTable> {
  $$TransitReadingsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumn<String> get inputHash =>
      $composableBuilder(column: $table.inputHash, builder: (column) => column);

  GeneratedColumn<DateTime> get generatedAt => $composableBuilder(
      column: $table.generatedAt, builder: (column) => column);

  GeneratedColumn<String> get contactsJson => $composableBuilder(
      column: $table.contactsJson, builder: (column) => column);

  GeneratedColumn<String> get passage =>
      $composableBuilder(column: $table.passage, builder: (column) => column);

  GeneratedColumn<String> get model =>
      $composableBuilder(column: $table.model, builder: (column) => column);

  GeneratedColumn<DateTime> get syncedAt =>
      $composableBuilder(column: $table.syncedAt, builder: (column) => column);
}

class $$TransitReadingsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $TransitReadingsTable,
    TransitReadingRow,
    $$TransitReadingsTableFilterComposer,
    $$TransitReadingsTableOrderingComposer,
    $$TransitReadingsTableAnnotationComposer,
    $$TransitReadingsTableCreateCompanionBuilder,
    $$TransitReadingsTableUpdateCompanionBuilder,
    (
      TransitReadingRow,
      BaseReferences<_$AppDatabase, $TransitReadingsTable, TransitReadingRow>
    ),
    TransitReadingRow,
    PrefetchHooks Function()> {
  $$TransitReadingsTableTableManager(
      _$AppDatabase db, $TransitReadingsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TransitReadingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TransitReadingsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TransitReadingsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> date = const Value.absent(),
            Value<String> inputHash = const Value.absent(),
            Value<DateTime> generatedAt = const Value.absent(),
            Value<String> contactsJson = const Value.absent(),
            Value<String> passage = const Value.absent(),
            Value<String> model = const Value.absent(),
            Value<DateTime?> syncedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              TransitReadingsCompanion(
            date: date,
            inputHash: inputHash,
            generatedAt: generatedAt,
            contactsJson: contactsJson,
            passage: passage,
            model: model,
            syncedAt: syncedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String date,
            required String inputHash,
            required DateTime generatedAt,
            required String contactsJson,
            required String passage,
            Value<String> model = const Value.absent(),
            Value<DateTime?> syncedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              TransitReadingsCompanion.insert(
            date: date,
            inputHash: inputHash,
            generatedAt: generatedAt,
            contactsJson: contactsJson,
            passage: passage,
            model: model,
            syncedAt: syncedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$TransitReadingsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $TransitReadingsTable,
    TransitReadingRow,
    $$TransitReadingsTableFilterComposer,
    $$TransitReadingsTableOrderingComposer,
    $$TransitReadingsTableAnnotationComposer,
    $$TransitReadingsTableCreateCompanionBuilder,
    $$TransitReadingsTableUpdateCompanionBuilder,
    (
      TransitReadingRow,
      BaseReferences<_$AppDatabase, $TransitReadingsTable, TransitReadingRow>
    ),
    TransitReadingRow,
    PrefetchHooks Function()>;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$ProfilesTableTableManager get profiles =>
      $$ProfilesTableTableManager(_db, _db.profiles);
  $$DaySummariesTableTableManager get daySummaries =>
      $$DaySummariesTableTableManager(_db, _db.daySummaries);
  $$RawBucketsTableTableManager get rawBuckets =>
      $$RawBucketsTableTableManager(_db, _db.rawBuckets);
  $$MinuteBucketsTableTableManager get minuteBuckets =>
      $$MinuteBucketsTableTableManager(_db, _db.minuteBuckets);
  $$IntegrationsTableTableManager get integrations =>
      $$IntegrationsTableTableManager(_db, _db.integrations);
  $$SleepSegmentsTableTableManager get sleepSegments =>
      $$SleepSegmentsTableTableManager(_db, _db.sleepSegments);
  $$DailyVitalsTableTableManager get dailyVitals =>
      $$DailyVitalsTableTableManager(_db, _db.dailyVitals);
  $$ActivitySessionsTableTableManager get activitySessions =>
      $$ActivitySessionsTableTableManager(_db, _db.activitySessions);
  $$StrengthWorkoutsTableTableManager get strengthWorkouts =>
      $$StrengthWorkoutsTableTableManager(_db, _db.strengthWorkouts);
  $$WeightEntriesTableTableManager get weightEntries =>
      $$WeightEntriesTableTableManager(_db, _db.weightEntries);
  $$NutritionEntriesTableTableManager get nutritionEntries =>
      $$NutritionEntriesTableTableManager(_db, _db.nutritionEntries);
  $$LiveSessionsTableTableManager get liveSessions =>
      $$LiveSessionsTableTableManager(_db, _db.liveSessions);
  $$RememberedSensorsTableTableManager get rememberedSensors =>
      $$RememberedSensorsTableTableManager(_db, _db.rememberedSensors);
  $$LifestyleEntriesTableTableManager get lifestyleEntries =>
      $$LifestyleEntriesTableTableManager(_db, _db.lifestyleEntries);
  $$JournalEntriesTableTableManager get journalEntries =>
      $$JournalEntriesTableTableManager(_db, _db.journalEntries);
  $$GuidanceHistoryTableTableManager get guidanceHistory =>
      $$GuidanceHistoryTableTableManager(_db, _db.guidanceHistory);
  $$VesselReadingsTableTableManager get vesselReadings =>
      $$VesselReadingsTableTableManager(_db, _db.vesselReadings);
  $$DailyCardsTableTableManager get dailyCards =>
      $$DailyCardsTableTableManager(_db, _db.dailyCards);
  $$PatternCandidatesTableTableManager get patternCandidates =>
      $$PatternCandidatesTableTableManager(_db, _db.patternCandidates);
  $$RetrospectivesTableTableManager get retrospectives =>
      $$RetrospectivesTableTableManager(_db, _db.retrospectives);
  $$IntakeAnswersTableTableManager get intakeAnswers =>
      $$IntakeAnswersTableTableManager(_db, _db.intakeAnswers);
  $$JournalDayStoriesTableTableManager get journalDayStories =>
      $$JournalDayStoriesTableTableManager(_db, _db.journalDayStories);
  $$TransitReadingsTableTableManager get transitReadings =>
      $$TransitReadingsTableTableManager(_db, _db.transitReadings);
}
