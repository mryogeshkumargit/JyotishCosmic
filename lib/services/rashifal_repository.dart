import 'dart:convert';

import 'package:drift/drift.dart';

import '../core/database.dart';
import '../core/rashifal/rashifal_models.dart';

/// List entry of a saved daily Rashifal (no report JSON is decoded).
class RashifalSummary {
  final int id;
  final int profileId;
  final String profileName;
  final String dateKey;
  final String lang;
  final int score;
  final DayRating rating;
  final String headline;
  final bool hasAi;
  final bool favourite;
  final DateTime updatedAt;

  const RashifalSummary({
    required this.id,
    required this.profileId,
    required this.profileName,
    required this.dateKey,
    required this.lang,
    required this.score,
    required this.rating,
    required this.headline,
    required this.hasAi,
    required this.favourite,
    required this.updatedAt,
  });
}

/// Storage of daily Rashifal reports in the local SQLite database.
///
/// Built for a long history: lists read only the small summary columns and
/// are paged, lookups use the (profile, date, language) unique index, and
/// the report JSON is decoded only when one day is opened.
class RashifalRepository {
  final AppDatabase db;
  RashifalRepository(this.db);

  $DailyRashifalsTable get _t => db.dailyRashifals;

  /// Inserts or updates the report of its profile, date and language.
  /// [aiRaw] is kept unless a new one is given; the favourite flag is kept.
  Future<int> save(DailyRashifalReport r, {String? aiRaw}) async {
    final row = DailyRashifalsCompanion.insert(
      profileId: r.profileId,
      profileName: r.profileName,
      dateKey: r.dateKey,
      lang: Value(r.lang),
      score: r.score,
      rating: r.rating.name,
      headline: r.headline,
      reportJson: jsonEncode(r.toJson()),
      hasAi: Value(r.hasAi),
      aiModel: Value(r.aiModel),
      aiRaw: aiRaw == null ? const Value.absent() : Value(aiRaw),
    );
    return db
        .into(_t)
        .insert(
          row,
          onConflict: DoUpdate(
            (_) => row.copyWith(updatedAt: Value(DateTime.now()), createdAt: const Value.absent()),
            target: [_t.profileId, _t.dateKey, _t.lang],
          ),
        );
  }

  DailyRashifalReport? _decode(DailyRashifalRow? row) {
    if (row == null) return null;
    try {
      return DailyRashifalReport.fromJson(jsonDecode(row.reportJson) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  Future<DailyRashifalReport?> load(int profileId, String dateKey, String lang) async =>
      _decode(await (db.select(_t)..where((t) => t.profileId.equals(profileId) & t.dateKey.equals(dateKey) & t.lang.equals(lang))).getSingleOrNull());

  Future<DailyRashifalReport?> loadById(int id) async => _decode(await (db.select(_t)..where((t) => t.id.equals(id))).getSingleOrNull());

  Future<DailyRashifalRow?> rowById(int id) => (db.select(_t)..where((t) => t.id.equals(id))).getSingleOrNull();

  Expression<bool> _filter({int? profileId, bool favouritesOnly = false, String? from, String? to}) {
    Expression<bool> e = const Constant(true);
    if (profileId != null) e = e & _t.profileId.equals(profileId);
    if (favouritesOnly) e = e & _t.favourite.equals(true);
    if (from != null) e = e & _t.dateKey.isBiggerOrEqualValue(from);
    if (to != null) e = e & _t.dateKey.isSmallerOrEqualValue(to);
    return e;
  }

  /// One page of saved reports, newest date first.
  Future<List<RashifalSummary>> page({int? profileId, bool favouritesOnly = false, String? from, String? to, int limit = 30, int offset = 0}) async {
    final q = db.selectOnly(_t)
      ..addColumns([_t.id, _t.profileId, _t.profileName, _t.dateKey, _t.lang, _t.score, _t.rating, _t.headline, _t.hasAi, _t.favourite, _t.updatedAt])
      ..where(_filter(profileId: profileId, favouritesOnly: favouritesOnly, from: from, to: to))
      ..orderBy([OrderingTerm.desc(_t.dateKey), OrderingTerm.desc(_t.updatedAt)])
      ..limit(limit, offset: offset);
    final rows = await q.get();
    return [
      for (final r in rows)
        RashifalSummary(
          id: r.read(_t.id)!,
          profileId: r.read(_t.profileId)!,
          profileName: r.read(_t.profileName)!,
          dateKey: r.read(_t.dateKey)!,
          lang: r.read(_t.lang)!,
          score: r.read(_t.score)!,
          rating: DayRating.parse(r.read(_t.rating)),
          headline: r.read(_t.headline)!,
          hasAi: r.read(_t.hasAi)!,
          favourite: r.read(_t.favourite)!,
          updatedAt: r.read(_t.updatedAt)!,
        ),
    ];
  }

  Future<int> count({int? profileId, bool favouritesOnly = false}) async {
    final c = _t.id.count();
    final q = db.selectOnly(_t)
      ..addColumns([c])
      ..where(_filter(profileId: profileId, favouritesOnly: favouritesOnly));
    return (await q.getSingle()).read(c) ?? 0;
  }

  /// Emits whenever saved reports change (for live history lists).
  Stream<void> changes() => db.tableUpdates(TableUpdateQuery.onTable(_t));

  Future<void> setFavourite(int id, bool value) => (db.update(_t)..where((t) => t.id.equals(id))).write(DailyRashifalsCompanion(favourite: Value(value)));

  Future<void> delete(int id) => (db.delete(_t)..where((t) => t.id.equals(id))).go();

  Future<int> deleteForProfile(int profileId) => (db.delete(_t)..where((t) => t.profileId.equals(profileId))).go();

  Future<int> deleteAll() => db.delete(_t).go();

  /// Deletes non-favourite reports older than [beforeDateKey]; returns the count.
  Future<int> deleteOlderThan(String beforeDateKey) => (db.delete(_t)..where((t) => t.dateKey.isSmallerThanValue(beforeDateKey) & t.favourite.equals(false))).go();
}
