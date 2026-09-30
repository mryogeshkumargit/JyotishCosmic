import 'dart:math';
import 'package:dio/dio.dart';
import 'package:drift/drift.dart';
import '../core/database.dart';

class SyncException implements Exception {
  final String message;
  final bool unauthorized;
  SyncException(this.message, {this.unauthorized = false});
  @override
  String toString() => message;
}

class SyncResult {
  final int pushed;
  final int pulled;
  final int deleted;
  final List<String> errors;
  const SyncResult({this.pushed = 0, this.pulled = 0, this.deleted = 0, this.errors = const []});

  String get summary {
    final parts = ['$pushed uploaded', '$pulled new from cloud', if (deleted > 0) '$deleted deleted'];
    return errors.isEmpty ? parts.join(', ') : '${parts.join(', ')} • ${errors.length} error(s)';
  }
}

/// Two-way sync of profiles between the local database and the Jyotish Cosmic
/// cloud backend (Cloudflare). Local data is always the primary copy: the app
/// keeps working offline and sync only runs when the user is signed in.
///
/// API (JSON, bearer token):
///   GET    /api/profiles          -> list of profiles (or {"profiles": [...]})
///   PUT    /api/profiles/{id}     -> update (falls back to POST when unsupported)
///   POST   /api/profiles          -> create/upsert, returns {"id": ...}
///   DELETE /api/profiles/{id}
class SyncService {
  final Dio _api;
  final AppDatabase _db;

  SyncService(this._api, this._db);

  static final Random _random = Random.secure();

  /// Random UUID v4 used as the cloud id of a profile.
  static String newCloudId() {
    final b = List<int>.generate(16, (_) => _random.nextInt(256));
    b[6] = (b[6] & 0x0f) | 0x40;
    b[8] = (b[8] & 0x3f) | 0x80;
    final h = b.map((x) => x.toRadixString(16).padLeft(2, '0')).join();
    return '${h.substring(0, 8)}-${h.substring(8, 12)}-${h.substring(12, 16)}-${h.substring(16, 20)}-${h.substring(20)}';
  }

  /// Birth time as a zone-less ISO string of the wall clock ("1990-06-15T14:30:00.000"),
  /// the same format earlier app versions uploaded.
  static String wallClockIso(DateTime dob) => dob.toUtc().toIso8601String().replaceAll('Z', '');

  /// Parses a server birth time, keeping its wall-clock components.
  static DateTime parseWallClock(String s) {
    final p = DateTime.parse(s);
    return DateTime.utc(p.year, p.month, p.day, p.hour, p.minute, p.second);
  }

  static Map<String, dynamic> toJson(Profile p, String cloudId) => {
        'id': cloudId,
        'name': p.name,
        'dob': wallClockIso(p.dob),
        'pob': p.pob,
        'lat': p.lat,
        'lon': p.lon,
        'timezone': p.timezone,
        'tzName': p.tzName,
        'gender': p.gender,
        'aiInterpretation': p.aiInterpretation,
        'updatedAt': p.updatedAt.toUtc().toIso8601String(),
      };

  static dynamic _field(Map rp, String camel, String snake) => rp[camel] ?? rp[snake];

  static double? _double(dynamic v) => v == null ? null : double.tryParse(v.toString());

  SyncException _error(DioException e, String action) {
    final status = e.response?.statusCode;
    if (status == 401 || status == 403) {
      return SyncException('Session expired. Please sign in again.', unauthorized: true);
    }
    if (status != null) return SyncException('$action failed (HTTP $status)');
    return SyncException('$action failed: cannot reach the sync server');
  }

  /// Uploads local changes, sends pending deletions, then downloads remote profiles.
  Future<SyncResult> sync() async {
    final errors = <String>[];
    final deleted = await _pushDeletions(errors);
    final pushed = await _pushChanges(errors);
    final pulled = await _pull();
    return SyncResult(pushed: pushed, pulled: pulled, deleted: deleted, errors: errors);
  }

  Future<int> _pushDeletions(List<String> errors) async {
    int count = 0;
    for (final d in await _db.select(_db.pendingDeletions).get()) {
      try {
        await _api.delete('/api/profiles/${Uri.encodeComponent(d.cloudId)}');
        await (_db.delete(_db.pendingDeletions)..where((t) => t.cloudId.equals(d.cloudId))).go();
        count++;
      } on DioException catch (e) {
        if (e.response?.statusCode == 404) {
          // Already gone on the server.
          await (_db.delete(_db.pendingDeletions)..where((t) => t.cloudId.equals(d.cloudId))).go();
        } else {
          final err = _error(e, 'Delete');
          if (err.unauthorized) throw err;
          // Keep the tombstone: it is retried next time and stops the profile reappearing.
          errors.add(err.message);
        }
      }
    }
    return count;
  }

  Future<String?> _upload(Profile p) async {
    final id = p.cloudflareId ?? newCloudId();
    final body = toJson(p, id);
    Response response;
    if (p.cloudflareId != null) {
      try {
        response = await _api.put('/api/profiles/${Uri.encodeComponent(id)}', data: body);
        return _idFrom(response.data) ?? id;
      } on DioException catch (e) {
        final status = e.response?.statusCode;
        // 404: not on the server any more; 405/501: server only supports POST upserts.
        if (status != 404 && status != 405 && status != 501) rethrow;
      }
    }
    response = await _api.post('/api/profiles', data: body);
    return _idFrom(response.data) ?? id;
  }

  static String? _idFrom(dynamic data) {
    if (data is Map && data['id'] != null && data['id'].toString().isNotEmpty) return data['id'].toString();
    if (data is Map && data['profile'] is Map) return _idFrom(data['profile']);
    return null;
  }

  Future<int> _pushChanges(List<String> errors) async {
    int count = 0;
    final dirty = await (_db.select(_db.profiles)..where((t) => t.needsSync.equals(true))).get();
    for (final p in dirty) {
      try {
        final cloudId = await _upload(p);
        // Only clear the dirty flag if the row was not edited during the upload.
        await (_db.update(_db.profiles)..where((t) => t.id.equals(p.id) & t.updatedAt.equals(p.updatedAt))).write(
          ProfilesCompanion(cloudflareId: Value(cloudId), needsSync: const Value(false)),
        );
        await (_db.update(_db.profiles)..where((t) => t.id.equals(p.id))).write(ProfilesCompanion(cloudflareId: Value(cloudId)));
        count++;
      } on DioException catch (e) {
        final err = _error(e, 'Upload of ${p.name}');
        if (err.unauthorized) throw err;
        errors.add(err.message);
      }
    }
    return count;
  }

  Future<int> _pull() async {
    final Response response;
    try {
      response = await _api.get('/api/profiles');
    } on DioException catch (e) {
      throw _error(e, 'Download');
    }
    final data = response.data;
    final List remote = data is List ? data : (data is Map && data['profiles'] is List ? data['profiles'] : const []);

    final tombstones = (await _db.select(_db.pendingDeletions).get()).map((d) => d.cloudId).toSet();
    int count = 0;
    for (final item in remote) {
      if (item is! Map || item['id'] == null) continue;
      final rid = item['id'].toString();
      if (tombstones.contains(rid)) continue;

      final dobRaw = item['dob'];
      final name = item['name']?.toString();
      if (dobRaw == null || name == null) continue;
      DateTime dob;
      try {
        dob = parseWallClock(dobRaw.toString());
      } catch (_) {
        continue;
      }

      final existing = await (_db.select(_db.profiles)..where((t) => t.cloudflareId.equals(rid))).getSingleOrNull();
      final tz = _double(item['timezone']);
      final tzName = _field(item, 'tzName', 'tz_name')?.toString();
      final gender = item['gender']?.toString();
      final ai = _field(item, 'aiInterpretation', 'ai_interpretation')?.toString();

      if (existing == null) {
        await _db.into(_db.profiles).insert(ProfilesCompanion.insert(
          name: name,
          dob: dob,
          pob: item['pob']?.toString() ?? '',
          lat: _double(item['lat']) ?? 0.0,
          lon: _double(item['lon']) ?? 0.0,
          timezone: Value(tz ?? 5.5),
          tzName: Value(tzName),
          gender: Value(gender),
          aiInterpretation: Value(ai),
          cloudflareId: Value(rid),
          needsSync: const Value(false),
        ));
        count++;
      } else if (!existing.needsSync) {
        // Local copy has no unsent edits, so the server copy wins. Fields the
        // server does not store keep their local values.
        await (_db.update(_db.profiles)..where((t) => t.id.equals(existing.id))).write(ProfilesCompanion(
          name: Value(name),
          dob: Value(dob),
          pob: Value(item['pob']?.toString() ?? existing.pob),
          lat: Value(_double(item['lat']) ?? existing.lat),
          lon: Value(_double(item['lon']) ?? existing.lon),
          timezone: Value(tz ?? existing.timezone),
          tzName: Value(tzName ?? existing.tzName),
          gender: Value(gender ?? existing.gender),
          aiInterpretation: Value(ai ?? existing.aiInterpretation),
        ));
      }
      // Otherwise local edits win and are uploaded on the next sync.
    }
    return count;
  }
}
