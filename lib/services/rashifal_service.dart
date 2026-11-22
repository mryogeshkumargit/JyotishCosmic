import '../core/database.dart';
import '../core/ephemeris.dart';
import '../core/l10n.dart';
import '../core/profile_chart.dart';
import '../core/rashifal/rashifal_ai.dart';
import '../core/rashifal/rashifal_engine.dart';
import '../core/rashifal/rashifal_models.dart';
import '../core/vedic_math.dart';
import '../providers/settings_provider.dart';
import 'rashifal_repository.dart';

/// Opens, computes, AI-enriches and saves daily Rashifal reports.
class RashifalService {
  final RashifalRepository repo;
  RashifalService(this.repo);

  final Map<String, RashifalNatal> _natal = {};

  /// Natal context of [p], cached while the profile and conventions are unchanged.
  RashifalNatal natalFor(Profile p) {
    final key =
        '${p.id}|${p.updatedAt.millisecondsSinceEpoch}|${p.dob.millisecondsSinceEpoch}|${p.lat}|${p.lon}|${p.timezone}|'
        '${Ephemeris.ayanamsaCode}|${Ephemeris.trueNode}|${DashaCalculations.yearDays}';
    if (_natal.length > 12) _natal.clear();
    return _natal[key] ??= RashifalNatal.fromChart(p.computeChart(), profileId: p.id, name: p.name, gender: p.gender);
  }

  /// The place chosen in the Rashifal settings, or else the birth place.
  static RashifalPlace placeFor(RashifalPrefs prefs, Profile p) => prefs.hasPlace
      ? RashifalPlace(name: prefs.placeName!, lat: prefs.lat!, lon: prefs.lon!, tzName: prefs.tzName, fallbackOffset: p.timezone)
      : RashifalPlace(name: p.pob, lat: p.lat, lon: p.lon, tzName: p.tzName, fallbackOffset: p.timezone);

  RashifalComputation compute(Profile p, DateTime date, RashifalPrefs prefs, {bool full = true}) =>
      RashifalEngine.compute(natalFor(p), DateTime(date.year, date.month, date.day), placeFor(prefs, p), full: full);

  /// The saved report of [date] in the current language, or a newly computed
  /// (and saved) one. [recompute] replaces the saved report.
  Future<DailyRashifalReport> open(Profile p, DateTime date, RashifalPrefs prefs, {bool recompute = false}) async {
    if (!recompute) {
      final saved = await repo.load(p.id, dateKeyOf(date), L10n.lang);
      if (saved != null) return saved;
    }
    final report = compute(p, date, prefs).report;
    await repo.save(report);
    return report;
  }

  /// Runs the AI interpretation of [date] and saves it with the raw answer.
  Future<DailyRashifalReport> runAi(SettingsState settings, Profile p, DateTime date, {void Function(int chars)? onProgress}) async {
    final c = compute(p, date, settings.rashifal);
    final (report, raw) = await RashifalAi.enrich(settings, natalFor(p), c, onProgress: onProgress);
    await repo.save(report, aiRaw: raw);
    return report;
  }

  /// Notification lines for [date]: the saved report's (AI ones included) or
  /// a quick on-device computation.
  Future<(String, String)> notificationLines(Profile p, DateTime date, RashifalPrefs prefs) async {
    final saved = await repo.load(p.id, dateKeyOf(date), L10n.lang);
    final r = saved ?? compute(p, date, prefs, full: false).report;
    return (r.notificationLine1, r.notificationLine2);
  }
}
