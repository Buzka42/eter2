/// The half of the evening invitation that needs a phone.
///
/// [EveningInvitation] decides *whether and when*, purely and testably.
/// This decides nothing: it reads consent, asks that question, and hands the
/// answer to the platform. The split exists because the rule is the part worth
/// testing and the platform call is the part that cannot be.
library;

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';

import '../clock.dart';
import '../db/app_database.dart';
import '../i18n/language.dart';
import '../i18n/strings.dart';
import '../symbolic/solar.dart';
import 'evening_invitation.dart';

/// What actually posts a notification. An interface so the scheduler can be
/// exercised without a platform channel.
abstract interface class InvitationSink {
  /// Asks the OS for permission. False means the person said no, or the
  /// platform refused — either way, nothing is scheduled and nothing is
  /// retried. Eter asks once.
  Future<bool> requestPermission();

  /// Replaces any pending invitation with one at [at], local time.
  Future<void> scheduleAt(DateTime at, {required String title,
      required String body});

  /// Removes any pending invitation. Called the moment consent is withdrawn,
  /// so revoking is immediate rather than taking effect after the next one
  /// fires.
  Future<void> cancel();
}

class EveningInvitationScheduler {
  const EveningInvitationScheduler({
    required this.database,
    required this.sink,
  });

  final AppDatabase database;
  final InvitationSink sink;

  /// Brings the pending invitation into line with consent and today's record.
  ///
  /// Safe and cheap to call on every launch and every Journal save, which is
  /// how it stays correct without a background job: there is no scheduler in
  /// this product, so the app's own comings and goings are the only clock it
  /// has.
  ///
  /// Consent is re-read here rather than passed in — every path in Eter
  /// re-reads it, and a cached flag would outlive a revocation.
  Future<InvitationDecision> sync({required DateTime now}) async {
    final profile = await database.loadProfile();
    final consented = profile?.eveningInvitationConsentAt != null;
    if (!consented) {
      await sink.cancel();
      return const InvitationDecision.refused(InvitationRefusal.notConsented);
    }

    final (dayStart, dayEnd) = eterDayBounds(now);
    final today = await database.loadJournalForRange(dayStart, dayEnd);
    final wroteToday = today.any((entry) => entry.entryText.trim().isNotEmpty);

    // The same coordinates the register turns on. If the register is falling
    // back to the clock because the device has demonstrably moved, so does
    // this — one horizon, not two.
    final place = registerCoordinates(
      homeLatitude: profile?.homeLatitude,
      homeLongitude: profile?.homeLongitude,
      birthLatitude: profile?.birthLatitude,
      birthLongitude: profile?.birthLongitude,
      utcOffset: now.timeZoneOffset,
    );

    final decision = EveningInvitation.nextAt(
      now: now,
      consented: true,
      wroteToday: wroteToday,
      latitude: place?.latitude,
      longitude: place?.longitude,
    );

    if (decision.at case final at?) {
      final strings = EterStrings.forLanguage(
        AppLanguage.forProfile(profile?.language),
      );
      await sink.scheduleAt(
        at,
        title: strings.invitationTitle,
        body: strings.invitationBody,
      );
    }
    return decision;
  }

  /// Grants consent, having first asked the OS. Returns false when the
  /// permission was refused, in which case nothing is stored — a consent flag
  /// that outlives a denied permission is a lie in the Sanctum.
  Future<bool> grant({required DateTime now}) async {
    if (!await sink.requestPermission()) return false;
    await database.setEveningInvitationConsent(now);
    await sync(now: now);
    return true;
  }

  Future<void> revoke() async {
    await database.setEveningInvitationConsent(null);
    await sink.cancel();
  }
}

/// The real sink. Everything platform-specific in the feature is here.
class LocalNotificationSink implements InvitationSink {
  LocalNotificationSink([FlutterLocalNotificationsPlugin? plugin])
      : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;
  bool _ready = false;

  /// One id, forever. There is exactly one invitation pending at any moment,
  /// and scheduling a new one must replace the old rather than stack.
  static const _id = 1;

  static const _android = AndroidNotificationDetails(
    'eter.invitation',
    'Evening invitation',
    channelDescription: 'One quiet invitation to write, at sunset.',
    importance: Importance.low,
    priority: Priority.low,
    playSound: false,
    enableVibration: false,
  );

  Future<void> _ensureReady() async {
    if (_ready) return;
    tz_data.initializeTimeZones();
    final zone = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(zone.identifier));
    await _plugin.initialize(
      settings: const InitializationSettings(
        // Not the launcher icon. Android draws the small icon as an alpha
        // mask and tints it, so a full-colour adaptive icon arrives as a
        // white blob. `ic_notification` is the mark reduced to what survives
        // at 24dp — see the comment in the drawable.
        android: AndroidInitializationSettings('@drawable/ic_notification'),
        iOS: DarwinInitializationSettings(
          // Asked for explicitly in [requestPermission], not on first launch.
          // Eter does not open with a permission dialog for something that is
          // off by default.
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      ),
    );
    _ready = true;
  }

  @override
  Future<bool> requestPermission() async {
    await _ensureReady();
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) {
      return await android.requestNotificationsPermission() ?? false;
    }
    final ios = _plugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    if (ios != null) {
      return await ios.requestPermissions(alert: true, badge: false, sound: false) ??
          false;
    }
    return false;
  }

  @override
  Future<void> scheduleAt(
    DateTime at, {
    required String title,
    required String body,
  }) async {
    await _ensureReady();
    await _plugin.zonedSchedule(
      id: _id,
      title: title,
      body: body,
      scheduledDate: tz.TZDateTime.from(at, tz.local),
      notificationDetails: const NotificationDetails(
        android: _android,
        iOS: DarwinNotificationDetails(presentSound: false),
      ),
      // Inexact on purpose. An exact alarm needs a permission Android treats
      // as a serious request, and an invitation that arrives at 20:34 instead
      // of 20:30 is the same invitation.
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
    );
  }

  @override
  Future<void> cancel() async {
    await _ensureReady();
    await _plugin.cancel(id: _id);
  }
}
