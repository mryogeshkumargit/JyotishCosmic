import 'dart:convert' show utf8;
import 'dart:io' show gzip;

import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:flutter/services.dart' show rootBundle;
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

class LocationResult {
  final String displayName;
  final double lat;
  final double lon;

  /// IANA time zone identifier (e.g. `Asia/Kolkata`), when known.
  final String? tzName;

  LocationResult({required this.displayName, required this.lat, required this.lon, this.tzName});
}

class _City {
  final String name;
  final String key;
  final String admin1;
  final String country;
  final double lat;
  final double lon;
  final String tzName;

  _City(this.name, this.key, this.admin1, this.country, this.lat, this.lon, this.tzName);

  String get displayName => [name, if (admin1.isNotEmpty && admin1 != name) admin1, country].join(', ');
}

/// Fully offline place search backed by a bundled GeoNames extract
/// (`assets/cities.tsv.gz`, CC-BY 4.0) plus the IANA time zone database.
class LocationService {
  static List<_City>? _cities;
  static Future<void>? _loading;
  static bool _tzInitialized = false;

  static void ensureTimeZones() {
    if (_tzInitialized) return;
    tzdata.initializeTimeZones();
    _tzInitialized = true;
  }

  static Future<void> _load() async {
    final bytes = (await rootBundle.load('assets/cities.tsv.gz')).buffer.asUint8List();
    _cities = _parseCityTable(utf8.decode(gzip.decode(bytes)));
  }

  static List<_City> _parseCityTable(String text) {
    final lines = text.split('\n');
    List<String> tzs = [];
    final Map<String, String> countries = {};
    final result = <_City>[];
    for (final line in lines) {
      if (line.isEmpty) continue;
      final parts = line.split('\t');
      if (parts[0] == '#tz') {
        tzs = parts.sublist(1);
        continue;
      }
      if (parts[0] == '#cc') {
        for (final entry in parts.sublist(1)) {
          final i = entry.indexOf('=');
          countries[entry.substring(0, i)] = entry.substring(i + 1);
        }
        continue;
      }
      if (parts.length < 6) continue;
      final name = parts[0];
      result.add(_City(
        name,
        normalize(name),
        parts[1],
        countries[parts[2]] ?? parts[2],
        double.parse(parts[3]),
        double.parse(parts[4]),
        tzs[int.parse(parts[5])],
      ));
    }
    return result;
  }

  /// Replaces the city table with [text] (same TSV format as the asset).
  @visibleForTesting
  static void loadTableForTest(String text) => _cities = _parseCityTable(text);

  /// Lower-cases and strips common Latin diacritics so "Sao" matches "São".
  static String normalize(String s) {
    const from = 'àáâãäåāăąçćčďèéêëēėęěğìíîïīįıłñńňòóôõöøōőřśşšţťùúûüūůűųýÿžźż';
    const to = 'aaaaaaaaacccdeeeeeeeegiiiiiiilnnnooooooooorsssttuuuuuuuuyyzzz';
    final lower = s.toLowerCase();
    final buf = StringBuffer();
    for (final ch in lower.split('')) {
      final i = from.indexOf(ch);
      buf.write(i >= 0 ? to[i] : ch);
    }
    return buf.toString();
  }

  /// Searches the offline city list. Results are ordered by population
  /// (the bundled table is pre-sorted), prefix matches first.
  Future<List<LocationResult>> searchCity(String query, {int limit = 8}) async {
    final q = normalize(query.trim());
    if (q.length < 2) return [];
    if (_cities == null) {
      _loading ??= _load();
      await _loading;
    }
    final prefix = <_City>[];
    final contains = <_City>[];
    for (final c in _cities!) {
      if (c.key.startsWith(q)) {
        prefix.add(c);
        if (prefix.length >= limit) break;
      } else if (contains.length < limit && c.key.contains(q)) {
        contains.add(c);
      }
    }
    return [...prefix, ...contains]
        .take(limit)
        .map((c) => LocationResult(displayName: c.displayName, lat: c.lat, lon: c.lon, tzName: c.tzName))
        .toList();
  }

  /// UTC offset in hours for a local wall-clock time in the given IANA zone,
  /// taking historical rules and daylight saving time into account.
  static double? utcOffsetFor(String? tzName, DateTime wallClock) {
    if (tzName == null || tzName.isEmpty) return null;
    ensureTimeZones();
    try {
      final loc = tz.getLocation(tzName);
      final t = tz.TZDateTime(loc, wallClock.year, wallClock.month, wallClock.day, wallClock.hour, wallClock.minute);
      return t.timeZoneOffset.inMinutes / 60.0;
    } catch (_) {
      return null;
    }
  }

  /// Current UTC offset (hours) in the given IANA zone.
  static double? currentUtcOffset(String? tzName) {
    if (tzName == null || tzName.isEmpty) return null;
    ensureTimeZones();
    try {
      return tz.TZDateTime.now(tz.getLocation(tzName)).timeZoneOffset.inMinutes / 60.0;
    } catch (_) {
      return null;
    }
  }
}
