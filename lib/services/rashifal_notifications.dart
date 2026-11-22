import 'dart:async';
import 'dart:convert';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

import '../core/database.dart';
import '../core/l10n.dart';
import '../core/rashifal/rashifal_models.dart';
import '../providers/settings_provider.dart';
import 'location_service.dart';
import 'rashifal_service.dart';

/// What a tapped Rashifal notification opens.
class RashifalPayload {
  final int profileId;
  final String dateKey;
  const RashifalPayload(this.profileId, this.dateKey);

  String encode() => jsonEncode({'type': 'rashifal', 'profileId': profileId, 'date': dateKey});

  static RashifalPayload? decode(String? s) {
    if (s == null) return null;
    try {
      final j = jsonDecode(s);
      if (j is Map && j['type'] == 'rashifal' && j['profileId'] is num && j['date'] is String) {
        return RashifalPayload((j['profileId'] as num).toInt(), j['date'] as String);
      }
    } catch (_) {}
    return null;
  }
}

/// One notification to schedule.
class PlannedNotification {
  final DateTime when;
  final RashifalPayload payload;
  final String title;
  final String body;
  const PlannedNotification(this.when, this.payload, this.title, this.body);
}

/// Daily Rashifal notifications (Android and iOS).
///
/// The text of each morning notification depends only on the Kundali, the
/// date and the place, so the next [horizonDays] notifications are computed
/// on the device and handed to the OS alarm scheduler. They appear on time
/// without network access and without the app running, and survive reboots
/// (boot receiver). The schedule is refreshed whenever the app starts or the
/// preferences, profiles or language change.
class RashifalNotifications {
  static const int horizonDays = 14;
  static const int _baseId = 7000;
  static const String channelId = 'daily_rashifal';

  static final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  static bool _initialized = false;
  static final StreamController<RashifalPayload> _taps = StreamController.broadcast();

  /// Payloads of notifications tapped while the app runs.
  static Stream<RashifalPayload> get taps => _taps.stream;

  static bool get supported => !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  /// Initializes the plugin; returns the payload if the app was launched by a tap.
  static Future<RashifalPayload?> init() async {
    if (!supported) return null;
    try {
      if (!_initialized) {
        await _plugin.initialize(
          settings: const InitializationSettings(
            android: AndroidInitializationSettings('@mipmap/ic_launcher'),
            iOS: DarwinInitializationSettings(requestAlertPermission: false, requestBadgePermission: false, requestSoundPermission: false),
          ),
          onDidReceiveNotificationResponse: (r) {
            final p = RashifalPayload.decode(r.payload);
            if (p != null) _taps.add(p);
          },
        );
        _initialized = true;
      }
      final launch = await _plugin.getNotificationAppLaunchDetails();
      if (launch?.didNotificationLaunchApp ?? false) return RashifalPayload.decode(launch!.notificationResponse?.payload);
    } catch (e) {
      debugPrint('Notifications unavailable: $e');
    }
    return null;
  }

  static AndroidFlutterLocalNotificationsPlugin? get _android => _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

  /// Asks for the notification permission (Android 13+, iOS). True when granted.
  static Future<bool> requestPermission() async {
    if (!supported) return false;
    try {
      if (Platform.isAndroid) return await _android?.requestNotificationsPermission() ?? false;
      return await _plugin.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()?.requestPermissions(alert: true, badge: true, sound: true) ?? false;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> notificationsEnabled() async {
    if (!supported) return false;
    try {
      if (Platform.isAndroid) return await _android?.areNotificationsEnabled() ?? false;
      final p = await _plugin.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()?.checkPermissions();
      return p?.isEnabled ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Exact alarms deliver at the chosen minute; without them Android may
  /// delay an inexact alarm by some minutes to save battery.
  static Future<bool> canScheduleExact() async {
    if (!supported || !Platform.isAndroid) return true;
    try {
      return await _android?.canScheduleExactNotifications() ?? false;
    } catch (_) {
      return false;
    }
  }

  static Future<void> requestExact() async {
    if (!supported || !Platform.isAndroid) return;
    try {
      await _android?.requestExactAlarmsPermission();
    } catch (_) {}
  }

  static NotificationDetails _details(String body) => NotificationDetails(
    android: AndroidNotificationDetails(
      channelId,
      tr('Daily Rashifal', 'दैनिक राशिफल'),
      channelDescription: tr('Morning horoscope from your Kundali', 'आपकी कुंडली से सुबह का राशिफल'),
      importance: Importance.high,
      priority: Priority.high,
      styleInformation: BigTextStyleInformation(body),
      category: AndroidNotificationCategory.reminder,
    ),
    iOS: const DarwinNotificationDetails(),
  );

  /// Shows a notification immediately (used for the "test" button).
  static Future<void> showNow(PlannedNotification n) async {
    if (!supported) return;
    await _plugin.show(id: _baseId - 1, title: n.title, body: n.body, notificationDetails: _details(n.body), payload: n.payload.encode());
  }

  /// Replaces all scheduled Rashifal notifications with [plan]. Returns how many were scheduled.
  static Future<int> schedule(List<PlannedNotification> plan) async {
    if (!supported) return 0;
    LocationService.ensureTimeZones();
    for (int i = 0; i <= horizonDays + 1; i++) {
      await _plugin.cancel(id: _baseId + i);
    }
    final exact = await canScheduleExact();
    int n = 0;
    for (final (i, p) in plan.indexed) {
      if (i > horizonDays) break;
      await _plugin.zonedSchedule(
        id: _baseId + i,
        title: p.title,
        body: p.body,
        scheduledDate: tz.TZDateTime.from(p.when.toUtc(), tz.UTC),
        notificationDetails: _details(p.body),
        androidScheduleMode: exact ? AndroidScheduleMode.exactAllowWhileIdle : AndroidScheduleMode.inexactAllowWhileIdle,
        payload: p.payload.encode(),
      );
      n++;
    }
    return n;
  }

  static Future<List<PendingNotificationRequest>> pending() async {
    if (!supported) return const [];
    try {
      return (await _plugin.pendingNotificationRequests()).where((r) => r.id >= _baseId).toList();
    } catch (_) {
      return const [];
    }
  }

  /// Profile used for notifications: the chosen one, else the first.
  static Profile? profileFor(RashifalPrefs prefs, List<Profile> profiles) {
    if (profiles.isEmpty) return null;
    for (final p in profiles) {
      if (p.id == prefs.profileId) return p;
    }
    return profiles.first;
  }

  /// The upcoming notifications for [prefs] (pure planning, no plugin calls).
  static Future<List<PlannedNotification>> plan(RashifalPrefs prefs, List<Profile> profiles, RashifalService service, {DateTime? now}) async {
    final profile = profileFor(prefs, profiles);
    if (!prefs.enabled || profile == null || prefs.weekdays.isEmpty) return const [];
    final t0 = now ?? DateTime.now();
    final out = <PlannedNotification>[];
    for (int i = 0; i <= horizonDays && out.length < horizonDays; i++) {
      final day = DateTime(t0.year, t0.month, t0.day + i);
      final when = DateTime(day.year, day.month, day.day, prefs.hour, prefs.minute);
      if (!when.isAfter(t0) || !prefs.weekdays.contains(day.weekday)) continue;
      final (l1, l2) = await service.notificationLines(profile, day, prefs);
      out.add(PlannedNotification(when, RashifalPayload(profile.id, dateKeyOf(day)), '${tr('Daily Rashifal', 'दैनिक राशिफल')} · ${profile.name}', '$l1\n$l2'));
    }
    return out;
  }

  /// Plans and schedules; returns the number of notifications scheduled.
  static Future<int> reschedule(RashifalPrefs prefs, List<Profile> profiles, RashifalService service) async {
    if (!supported) return 0;
    try {
      final p = await plan(prefs, profiles, service);
      return await schedule(p);
    } catch (e) {
      debugPrint('Could not schedule Rashifal notifications: $e');
      return 0;
    }
  }
}
