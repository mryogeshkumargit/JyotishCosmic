import 'package:sweph/sweph.dart';

/// Result of a sidereal chart computation.
class ChartData {
  /// House number (1-12, whole-sign from Lagna) -> planet abbreviations.
  final Map<int, List<String>> housePlanets;

  /// Sidereal longitudes (0-360) keyed by lowercase planet name.
  final Map<String, double> planetLongitudes;

  /// Daily motion in longitude (degrees/day). Negative means retrograde.
  final Map<String, double> planetSpeeds;

  /// Sidereal ascendant (0-360).
  final double ascendantSidereal;

  /// Julian day number in Universal Time.
  final double jd;

  /// Ayanamsa used to derive the sidereal positions.
  final double ayanamsa;

  final double lat;
  final double lon;
  final double utcOffset;

  /// Ecliptic latitude (degrees, north positive) of each body.
  final Map<String, double> planetLatitudes;

  /// Tropical declination (degrees, north positive) of each body.
  final Map<String, double> declinations;

  /// Sidereal heliocentric longitude of the planets (not Sun, Moon or nodes).
  final Map<String, double> heliocentricLongitudes;

  /// Sidereal Midheaven (10th cusp, MC).
  final double? midheaven;

  ChartData(
    this.housePlanets,
    this.planetLongitudes,
    this.ascendantSidereal,
    this.jd, {
    this.planetSpeeds = const {},
    this.ayanamsa = 0,
    this.lat = 0,
    this.lon = 0,
    this.utcOffset = 0,
    this.planetLatitudes = const {},
    this.declinations = const {},
    this.heliocentricLongitudes = const {},
    this.midheaven,
  });

  /// 0-based sign index of the ascendant (0 = Aries).
  int get lagnaRashi => (ascendantSidereal / 30).floor() % 12;

  /// Rahu/Ketu are always retrograde in mean motion, so they are excluded.
  bool isRetrograde(String planet) =>
      planet != 'rahu' && planet != 'ketu' && (planetSpeeds[planet] ?? 0) < 0;
}

enum Ayanamsa { lahiri, krishnamurti }

/// Swiss Ephemeris backed astronomical engine.
///
/// All positions come from the Swiss Ephemeris (`sweph` package) using the
/// bundled `sepl_18.se1` / `semo_18.se1` files (1800-2400 CE). Outside that
/// range Swiss Ephemeris transparently falls back to its built-in Moshier
/// ephemeris, so calculations never need a network connection.
class Ephemeris {
  static bool _initialized = false;
  static bool get isInitialized => _initialized;

  /// Bundled ephemeris files shipped with the sweph package.
  static const List<String> bundledEpheAssets = [
    'packages/sweph/assets/ephe/sepl_18.se1',
    'packages/sweph/assets/ephe/semo_18.se1',
    'packages/sweph/assets/ephe/seleapsec.txt',
  ];

  /// Must be awaited once before any calculation.
  static Future<void> init({
    required AssetLoader assetLoader,
    required String epheFilesPath,
    List<String> epheAssets = bundledEpheAssets,
    String? modulePath,
  }) async {
    if (_initialized) return;
    await Sweph.init(
      modulePath: modulePath,
      epheAssets: epheAssets,
      assetLoader: assetLoader,
      epheFilesPath: epheFilesPath,
    );
    _initialized = true;
  }

  static const Map<String, HeavenlyBody> _bodies = {
    'sun': HeavenlyBody.SE_SUN,
    'moon': HeavenlyBody.SE_MOON,
    'mars': HeavenlyBody.SE_MARS,
    'mercury': HeavenlyBody.SE_MERCURY,
    'jupiter': HeavenlyBody.SE_JUPITER,
    'venus': HeavenlyBody.SE_VENUS,
    'saturn': HeavenlyBody.SE_SATURN,
  };

  static const List<String> planetOrder = [
    'sun', 'moon', 'mars', 'mercury', 'jupiter', 'venus', 'saturn', 'rahu', 'ketu'
  ];

  static const Map<String, String> planetAbbreviations = {
    'sun': 'Su', 'moon': 'Mo', 'mars': 'Ma', 'mercury': 'Me',
    'jupiter': 'Ju', 'venus': 'Ve', 'saturn': 'Sa',
    'rahu': 'Ra', 'ketu': 'Ke'
  };

  static final SwephFlag _siderealFlags =
      SwephFlag.SEFLG_SWIEPH | SwephFlag.SEFLG_SPEED | SwephFlag.SEFLG_SIDEREAL;
  static final SwephFlag _equatorialFlags = SwephFlag.SEFLG_SWIEPH | SwephFlag.SEFLG_EQUATORIAL;
  static final SwephFlag _helioFlags = SwephFlag.SEFLG_SWIEPH | SwephFlag.SEFLG_HELCTR | SwephFlag.SEFLG_SIDEREAL;

  /// Description of the astronomical conventions, for audit logs.
  static const String ephemerisLabel = 'Swiss Ephemeris (sweph 2.10.3), sepl_18/semo_18 files, Moshier fallback';

  /// Sidereal mode used for "Lahiri" charts (configurable in Settings).
  static String ayanamsaCode = 'LAHIRI';

  /// Use the true (osculating) node instead of the mean node for Rahu/Ketu.
  static bool trueNode = false;

  static const Map<String, (SiderealMode, String)> ayanamsaModes = {
    'LAHIRI': (SiderealMode.SE_SIDM_LAHIRI, 'Lahiri (Chitrapaksha, Swiss Ephemeris default)'),
    'LAHIRI_ICRC': (SiderealMode.SE_SIDM_LAHIRI_ICRC, 'Lahiri ICRC (Indian Calendar Reform Committee)'),
    'LAHIRI_1940': (SiderealMode.SE_SIDM_LAHIRI_1940, 'Lahiri 1940'),
    'TRUE_CHITRA': (SiderealMode.SE_SIDM_TRUE_CITRA, 'True Chitrapaksha (Spica at 180°)'),
    'RAMAN': (SiderealMode.SE_SIDM_RAMAN, 'B. V. Raman'),
    'YUKTESHWAR': (SiderealMode.SE_SIDM_YUKTESHWAR, 'Sri Yukteshwar'),
  };

  /// Applies the calculation conventions chosen in Settings.
  static void configure({String? ayanamsa, bool? trueNode}) {
    if (ayanamsa != null && ayanamsaModes.containsKey(ayanamsa)) ayanamsaCode = ayanamsa;
    if (trueNode != null) Ephemeris.trueNode = trueNode;
  }

  static String get nodeModel => trueNode ? 'True (osculating) lunar node' : 'Mean lunar node';
  static String get ayanamsaLabel => '${ayanamsaModes[ayanamsaCode]!.$2}; Krishnamurti for KP';
  static HeavenlyBody get _nodeBody => trueNode ? HeavenlyBody.SE_TRUE_NODE : HeavenlyBody.SE_MEAN_NODE;

  static double _norm360(double d) {
    final x = d % 360;
    return x < 0 ? x + 360 : x;
  }

  /// Julian day (Gregorian calendar). Hours outside 0-24 are allowed, which
  /// makes it convenient to pass `localHour - utcOffset` directly.
  static double julianDay(int year, int month, int day, [double hour = 12, double minute = 0, double second = 0]) {
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

  /// Julian day (UT) for a local wall-clock time at the given UTC offset.
  static double julianDayFromLocal(DateTime local, double utcOffset) {
    return julianDay(local.year, local.month, local.day,
        local.hour - utcOffset, local.minute.toDouble(), local.second.toDouble());
  }

  static double nowJd() {
    final now = DateTime.now().toUtc();
    return julianDay(now.year, now.month, now.day, now.hour.toDouble(), now.minute.toDouble(), now.second.toDouble());
  }

  /// Converts a Julian day to a UTC [DateTime].
  static DateTime jdToUtc(double jd) {
    final ms = ((jd - 2440587.5) * 86400000).round();
    return DateTime.fromMillisecondsSinceEpoch(ms, isUtc: true);
  }

  static void _setAyanamsa(Ayanamsa mode) {
    Sweph.swe_set_sid_mode(
      mode == Ayanamsa.krishnamurti ? SiderealMode.SE_SIDM_KRISHNAMURTI : ayanamsaModes[ayanamsaCode]!.$1,
    );
  }

  static double ayanamsaValue(double jdUt, [Ayanamsa mode = Ayanamsa.lahiri]) {
    _setAyanamsa(mode);
    return Sweph.swe_get_ayanamsa_ex_ut(jdUt, SwephFlag.SEFLG_SWIEPH);
  }

  /// Sidereal longitude and speed of a planet (including 'rahu'/'ketu').
  static (double, double) siderealPosition(String planet, double jdUt, [Ayanamsa mode = Ayanamsa.lahiri]) {
    _setAyanamsa(mode);
    if (planet == 'rahu' || planet == 'ketu') {
      final node = Sweph.swe_calc_ut(jdUt, _nodeBody, _siderealFlags);
      final lon = planet == 'rahu' ? node.longitude : _norm360(node.longitude + 180);
      return (lon, node.speedInLongitude);
    }
    final body = _bodies[planet];
    if (body == null) throw ArgumentError('Unknown planet $planet');
    final pos = Sweph.swe_calc_ut(jdUt, body, _siderealFlags);
    return (_norm360(pos.longitude), pos.speedInLongitude);
  }

  /// Ecliptic latitude of a body (degrees). Mean nodes have zero latitude.
  static double eclipticLatitude(String planet, double jdUt) {
    final body = _bodies[planet];
    if (body == null) return 0;
    return Sweph.swe_calc_ut(jdUt, body, _siderealFlags).latitude;
  }

  /// Tropical declination of a body (degrees).
  static double declination(String planet, double jdUt) {
    if (planet == 'rahu' || planet == 'ketu') {
      final node = Sweph.swe_calc_ut(jdUt, _nodeBody, _equatorialFlags);
      return planet == 'rahu' ? node.latitude : -node.latitude;
    }
    final body = _bodies[planet];
    if (body == null) return 0;
    return Sweph.swe_calc_ut(jdUt, body, _equatorialFlags).latitude;
  }

  /// Sidereal heliocentric longitude of a planet (Mars to Saturn, Mercury, Venus).
  static double? heliocentricLongitude(String planet, double jdUt, [Ayanamsa mode = Ayanamsa.lahiri]) {
    if (planet == 'sun' || planet == 'moon' || planet == 'rahu' || planet == 'ketu') return null;
    final body = _bodies[planet];
    if (body == null) return null;
    _setAyanamsa(mode);
    return _norm360(Sweph.swe_calc_ut(jdUt, body, _helioFlags).longitude);
  }

  /// Sidereal Midheaven (MC).
  static double midheavenLongitude(double jdUt, double lat, double lon, [Ayanamsa mode = Ayanamsa.lahiri]) {
    _setAyanamsa(mode);
    final houses = Sweph.swe_houses_ex(jdUt, SwephFlag.SEFLG_SIDEREAL, lat, lon, Hsys.E);
    return _norm360(houses.ascmc[1]);
  }

  static double siderealLongitude(String planet, double jdUt, [Ayanamsa mode = Ayanamsa.lahiri]) =>
      siderealPosition(planet, jdUt, mode).$1;

  /// Sidereal ascendant for the given moment and place.
  static double ascendant(double jdUt, double lat, double lon, [Ayanamsa mode = Ayanamsa.lahiri]) {
    _setAyanamsa(mode);
    final houses = Sweph.swe_houses_ex(jdUt, SwephFlag.SEFLG_SIDEREAL, lat, lon, Hsys.E);
    return _norm360(houses.ascmc[0]);
  }

  /// Sidereal Placidus cusps. Index 1..12 hold cusps 1..12 (index 0 unused).
  /// Swiss Ephemeris falls back to Porphyry near the poles where Placidus is undefined.
  static List<double> placidusCusps(double jdUt, double lat, double lon, [Ayanamsa mode = Ayanamsa.krishnamurti]) {
    _setAyanamsa(mode);
    final houses = Sweph.swe_houses_ex(jdUt, SwephFlag.SEFLG_SIDEREAL, lat, lon, Hsys.P);
    return [0.0, ...houses.cusps.sublist(1, 13).map(_norm360)];
  }

  /// Birth chart for a local date/time with a fixed UTC offset (hours).
  static ChartData computeChart(
      int year, int month, int day, double hour, double minute, double lat, double lon, double utcOffset,
      [Ayanamsa mode = Ayanamsa.lahiri]) {
    final jd = julianDay(year, month, day, hour - utcOffset, minute, 0);
    return computeChartForJd(jd, lat, lon, utcOffset: utcOffset, mode: mode);
  }

  static ChartData computeChartForJd(double jdUt, double lat, double lon,
      {double utcOffset = 0, Ayanamsa mode = Ayanamsa.lahiri}) {
    final Map<String, double> longs = {};
    final Map<String, double> speeds = {};
    for (final name in planetOrder) {
      final (l, s) = siderealPosition(name, jdUt, mode);
      longs[name] = l;
      speeds[name] = s;
    }

    final ascSid = ascendant(jdUt, lat, lon, mode);
    final lagnaSign = (ascSid / 30).floor();
    final lats = {for (final n in planetOrder) n: eclipticLatitude(n, jdUt)};
    final decls = {for (final n in planetOrder) n: declination(n, jdUt)};
    final helio = <String, double>{
      for (final n in planetOrder) n: ?heliocentricLongitude(n, jdUt, mode),
    };
    final mc = midheavenLongitude(jdUt, lat, lon, mode);

    final Map<int, List<String>> housePlanets = {for (int i = 1; i <= 12; i++) i: []};
    longs.forEach((name, longitude) {
      final planetSign = (longitude / 30).floor();
      final house = (planetSign - lagnaSign + 12) % 12 + 1;
      housePlanets[house]!.add(planetAbbreviations[name]!);
    });

    return ChartData(
      housePlanets,
      longs,
      ascSid,
      jdUt,
      planetSpeeds: speeds,
      ayanamsa: ayanamsaValue(jdUt, mode),
      lat: lat,
      lon: lon,
      utcOffset: utcOffset,
      planetLatitudes: lats,
      declinations: decls,
      heliocentricLongitudes: helio,
      midheaven: mc,
    );
  }

  /// Next sunrise (UT Julian day) after [jdUt]; null in polar day/night.
  static double? nextSunrise(double jdUt, double lat, double lon) => _riseSet(jdUt, lat, lon, RiseSetTransitFlag.SE_CALC_RISE);

  /// Next sunset (UT Julian day) after [jdUt]; null in polar day/night.
  static double? nextSunset(double jdUt, double lat, double lon) => _riseSet(jdUt, lat, lon, RiseSetTransitFlag.SE_CALC_SET);

  /// Next upper meridian transit of the Sun (local apparent noon) after [jdUt].
  static double? nextSunTransit(double jdUt, double lat, double lon) => _riseSet(jdUt, lat, lon, RiseSetTransitFlag.SE_CALC_MTRANSIT);

  static double? _riseSet(double jdUt, double lat, double lon, RiseSetTransitFlag flag) {
    try {
      return Sweph.swe_rise_trans(
        jdUt,
        HeavenlyBody.SE_SUN,
        SwephFlag.SEFLG_SWIEPH,
        flag,
        GeoPosition(lon, lat, 0),
        1013.25,
        15,
      );
    } catch (_) {
      return null;
    }
  }

  /// Finds the moment near [approxJd] when the sidereal Sun reaches [targetLongitude].
  static double findSunLongitude(double targetLongitude, double approxJd, [Ayanamsa mode = Ayanamsa.lahiri]) {
    double jd = approxJd;
    for (int i = 0; i < 20; i++) {
      final (lon, speed) = siderealPosition('sun', jd, mode);
      double diff = targetLongitude - lon;
      if (diff > 180) diff -= 360;
      if (diff < -180) diff += 360;
      if (diff.abs() < 1e-7) break;
      jd += diff / (speed == 0 ? 0.9856 : speed);
    }
    return jd;
  }
}
