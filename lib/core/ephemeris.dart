import 'astro_engine.dart';

export 'astro_engine.dart' show PlanetPosition, AyanamsaSystem, NodeType;

/// A computed sidereal chart (Lahiri by default, whole-sign houses).
class ChartData {
  /// House number (1..12, whole-sign from Lagna) -> planet abbreviations.
  final Map<int, List<String>> housePlanets;

  /// Sidereal longitude of each graha, keyed by lower-case name ('sun' .. 'ketu').
  final Map<String, double> planetLongitudes;

  /// Sidereal ascendant (Lagna) longitude.
  final double ascendantSidereal;

  /// Julian Day of the moment in Universal Time.
  final double jd;

  /// Full positions with speed / retrograde state.
  final Map<String, PlanetPosition> planets;

  /// Sidereal Midheaven (MC).
  final double mcSidereal;

  /// Ayanamsa value used, in degrees.
  final double ayanamsa;

  final double lat;
  final double lon;

  /// Offset of local civil time from UTC, in hours (e.g. 5.5 for IST).
  final double utcOffset;

  ChartData(
    this.housePlanets,
    this.planetLongitudes,
    this.ascendantSidereal,
    this.jd, {
    Map<String, PlanetPosition>? planets,
    this.mcSidereal = 0,
    this.ayanamsa = 0,
    this.lat = 0,
    this.lon = 0,
    this.utcOffset = 0,
  }) : planets = planets ?? const {};

  int get lagnaRashi => (ascendantSidereal / 30).floor() % 12;

  bool isRetrograde(String planet) => planets[planet]?.isRetrograde ?? false;

  /// Local civil date-time of this chart.
  DateTime get localDateTime =>
      Ephemeris.jdToDateTime(jd).add(Duration(minutes: (utcOffset * 60).round()));
}

class Ephemeris {
  static const Map<String, String> abbreviations = {
    'sun': 'Su', 'moon': 'Mo', 'mars': 'Ma', 'mercury': 'Me',
    'jupiter': 'Ju', 'venus': 'Ve', 'saturn': 'Sa', 'rahu': 'Ra', 'ketu': 'Ke',
  };

  /// Julian Day for a Gregorian calendar date/time given in UT (pure Dart, no native call).
  static double julianDay(int year, int month, int day,
      [double hour = 12, double minute = 0, double second = 0]) {
    if (month <= 2) {
      year -= 1;
      month += 12;
    }
    final int a = (year / 100).floor();
    final int b = 2 - a + (a / 4).floor();
    return (365.25 * (year + 4716)).floor() +
        (30.6001 * (month + 1)).floor() +
        day +
        b -
        1524.5 +
        (hour + minute / 60 + second / 3600) / 24;
  }

  /// Julian Day (UT) of "now".
  static double nowJD() {
    final now = DateTime.now().toUtc();
    return julianDay(now.year, now.month, now.day, now.hour.toDouble(), now.minute.toDouble(),
        now.second.toDouble());
  }

  /// UTC DateTime for a Julian Day (pure Dart).
  static DateTime jdToDateTime(double jd) {
    final z = (jd + 0.5).floor();
    final f = (jd + 0.5) - z;
    int a = z;
    if (z >= 2299161) {
      final alpha = ((z - 1867216.25) / 36524.25).floor();
      a = z + 1 + alpha - (alpha / 4).floor();
    }
    final b = a + 1524;
    final c = ((b - 122.1) / 365.25).floor();
    final d = (365.25 * c).floor();
    final e = ((b - d) / 30.6001).floor();
    final day = b - d - (30.6001 * e).floor();
    final month = e < 14 ? e - 1 : e - 13;
    final year = month > 2 ? c - 4716 : c - 4715;
    final ms = (f * 86400000).round();
    return DateTime.utc(year, month, day).add(Duration(milliseconds: ms));
  }

  /// Computes a sidereal birth chart from a local civil date/time.
  static ChartData computeChart(int year, int month, int day, double hour, double minute,
      double lat, double lon, double utcOffset) {
    final jd = AstroEngine.julianDayUT(year, month, day, hour, minute, 0, utcOffset);
    return computeChartForJD(jd, lat, lon, utcOffset: utcOffset);
  }

  /// Computes a sidereal chart for a UT Julian Day.
  static ChartData computeChartForJD(double jd, double lat, double lon, {double utcOffset = 0}) {
    final planets = AstroEngine.allPlanets(jd);
    final houses = AstroEngine.houses(jd, lat, lon);
    final asc = houses.ascendant;
    final lagnaSign = (asc / 30).floor();

    final housePlanets = <int, List<String>>{for (int i = 1; i <= 12; i++) i: <String>[]};
    final longitudes = <String, double>{};
    for (final name in AstroEngine.grahas) {
      final lon0 = planets[name]!.longitude;
      longitudes[name] = lon0;
      final sign = (lon0 / 30).floor();
      final house = (sign - lagnaSign + 12) % 12 + 1;
      housePlanets[house]!.add(abbreviations[name]!);
    }

    return ChartData(
      housePlanets,
      longitudes,
      asc,
      jd,
      planets: planets,
      mcSidereal: houses.mc,
      ayanamsa: AstroEngine.ayanamsaValue(jd),
      lat: lat,
      lon: lon,
      utcOffset: utcOffset,
    );
  }

  /// Current planetary positions (for transits).
  static ChartData currentChart({double lat = 0, double lon = 0, double utcOffset = 0}) =>
      computeChartForJD(nowJD(), lat, lon, utcOffset: utcOffset);
}
