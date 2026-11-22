import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../core/l10n.dart';
import '../core/rashifal/rashifal_models.dart';
import '../services/rashifal_notifications.dart';
import '../services/rashifal_repository.dart';
import '../services/rashifal_service.dart';
import 'database_provider.dart';
import 'profile_provider.dart';
import 'settings_provider.dart';

final rashifalRepositoryProvider = Provider<RashifalRepository>((ref) => RashifalRepository(ref.watch(databaseProvider)));

final rashifalServiceProvider = Provider<RashifalService>((ref) => RashifalService(ref.watch(rashifalRepositoryProvider)));

/// Keeps the scheduled morning notifications in step with the preferences,
/// the profiles, the language and the calculation conventions.
final rashifalSchedulerProvider = Provider<RashifalScheduler>((ref) {
  final s = RashifalScheduler(ref);
  ref.onDispose(s.dispose);
  return s;
});

class RashifalScheduler {
  final Ref ref;
  Timer? _debounce;
  String? _lastSignature;

  /// Number of notifications scheduled by the last run (null before the first).
  int? lastScheduled;

  RashifalScheduler(this.ref) {
    ref.listen(profileListProvider, (_, _) => scheduleSoon());
    ref.listen(settingsProvider, (_, _) => scheduleSoon());
  }

  void scheduleSoon({Duration delay = const Duration(seconds: 2)}) {
    _debounce?.cancel();
    _debounce = Timer(delay, () => run());
  }

  /// Reschedules now when anything that affects the notification text changed
  /// (or always with [force]).
  Future<int> run({bool force = false}) async {
    if (!RashifalNotifications.supported) return 0;
    await ref.read(settingsProvider.notifier).loaded;
    final profiles = ref.read(profileListProvider).value;
    if (profiles == null) return lastScheduled ?? 0;
    final s = ref.read(settingsProvider);
    final today = DateTime.now();
    final signature = [
      s.rashifal.hashCode,
      L10n.lang,
      s.calc.ayanamsa,
      s.calc.trueNode,
      s.calc.dashaYearDays,
      '${today.year}-${today.month}-${today.day}',
      for (final p in profiles) '${p.id}:${p.updatedAt.millisecondsSinceEpoch}',
    ].join('|');
    if (!force && signature == _lastSignature) return lastScheduled ?? 0;
    _lastSignature = signature;
    if (s.rashifal.enabled && profiles.isNotEmpty) await _askPermissionOnce();
    lastScheduled = await RashifalNotifications.reschedule(s.rashifal, profiles, ref.read(rashifalServiceProvider));
    return lastScheduled!;
  }

  /// Asks for the notification permission (Android 13+, iOS) the first time
  /// there is something to notify, and never again: later changes go
  /// through the Daily Rashifal settings screen.
  Future<void> _askPermissionOnce() async {
    const storage = FlutterSecureStorage();
    const key = 'rashifalPermissionAsked';
    try {
      if (await storage.read(key: key) != null) return;
      await storage.write(key: key, value: '1');
    } catch (_) {
      return;
    }
    if (!await RashifalNotifications.notificationsEnabled()) await RashifalNotifications.requestPermission();
  }

  void dispose() => _debounce?.cancel();
}

/// Today's report of the notification Kundali, for the dashboard card.
/// Opening it saves the day, so the history fills in as the app is used.
final todayRashifalProvider = FutureProvider.autoDispose<DailyRashifalReport?>((ref) async {
  final profiles = await ref.watch(profileListProvider.future);
  final prefs = ref.watch(settingsProvider.select((s) => s.rashifal));
  ref.watch(settingsProvider.select((s) => s.appLanguage));
  final profile = RashifalNotifications.profileFor(prefs, profiles);
  if (profile == null) return null;
  // Refresh when a saved day changes (e.g. after an AI analysis).
  final sub = ref.read(rashifalRepositoryProvider).changes().listen((_) => ref.invalidateSelf());
  ref.onDispose(sub.cancel);
  try {
    return await ref.read(rashifalServiceProvider).open(profile, DateTime.now(), prefs);
  } catch (_) {
    return null;
  }
});
