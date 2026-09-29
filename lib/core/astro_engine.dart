import 'dart:math' as math;

import 'package:sweph/sweph.dart';

/// Ayanamsa systems supported by the app.
enum AyanamsaSystem { lahiri, krishnamurti, raman }

/// Which lunar node Rahu is computed from.
enum NodeType { mean, trueNode }

/// A sidereal position of one graha (or node) with its daily motion.
class PlanetPosition {
  final String name;
  final double longitude; // sidereal, 0..360
  final double latitude;
  final double distance; // AU
  final double speed; // degrees per day (negative => retrograde)

  const PlanetPosition({
    required this.name,
    required this.longitude,
    required this.latitude,
    required this.distance,
    required this.speed,
  });

  /// Rahu and Ketu are conventionally always retrograde; for other grahas use actual motion.
  bool get isRetrograde => name == 'rahu' || name == 'ketu' ? true : speed < 0;
}

/// Houses/angles for a moment and place (sidereal).
class HouseData {
  final double ascendant;
  final double mc;
  final List<double> cusps; // index 1..12, index 0 unused

  const HouseData(this.ascendant, this.mc, this.cusps);
}

/// Thin, synchronous wrapper around Swiss Ephemeris (via the `sweph` package).
///
/// [init] must be awaited once (from `main()`) before any calculation.
/// All times are Julian Days in Universal Time (UT).
class AstroEngine {
  AstroEngine._();

  static bool _ready = false;
  static bool get isReady => _ready;

  static AyanamsaSystem _ayanamsa = AyanamsaSystem.lahiri;
  static NodeType nodeType = NodeType.trueNode;

  /// Ephemeris files bundled by the sweph package (valid 1800–2400 CE).
  static const List<String> bundledEpheAssets = [
    'packages/sweph/assets/ephe/sepl_18.se1',
    'packages/sweph/assets/ephe/semo_18.se1',
  ];

  static const List<String> grahas = [
    'sun', 'moon', 'mars', 'mercury', 'jupiter', 'venus', 'saturn', 'rahu', 'ketu'
  ];

  static const Map<String, HeavenlyBody> _bodies = {
    'sun': HeavenlyBody.SE_SUN,
    'moon': HeavenlyBody.SE_MOON,
    'mars': HeavenlyBody.SE_MARS,
    'mercury': HeavenlyBody.SE_MERCURY,
    'jupiter': HeavenlyBody.SE_JUPITER,
    'venus': HeavenlyBody.SE_VENUS,
    'saturn': HeavenlyBody.SE_SATURN,
  };

  /// Initialises the native library and copies ephemeris files.
  ///
  /// [assetLoader] loads bundled files (use rootBundle in the app; a file loader in tests).
  /// [epheFilesPath] is where the ephemeris files are stored on disk.
  static Future<void> init({
    AssetLoader? assetLoader,
    String? epheFilesPath,
    String? modulePath,
    List<String> epheAssets = bundledEpheAssets,
  }) async {
    if (_ready) return;
    await Sweph.init(
      modulePath: modulePath,
      epheAssets: assetLoader != null ? epheAssets : const [],
      assetLoader: assetLoader,
      epheFilesPath: epheFilesPath,
    );
    setAyanamsa(AyanamsaSystem.lahiri);
    _ready = true;
  }

  static AyanamsaSystem get ayanamsa => _ayanamsa;

  static void setAyanamsa(AyanamsaSystem system) {
    _ayanamsa = system;
    Sweph.swe_set_sid_mode(_sidMode(system));
  }

  static SiderealMode _sidMode(AyanamsaSystem s) {
    switch (s) {
      case AyanamsaSystem.krishnamurti:
        return SiderealMode.SE_SIDM_KRISHNAMURTI;
      case AyanamsaSystem.raman:
        return SiderealMode.SE_SIDM_RAMAN;
      case AyanamsaSystem.lahiri:
        return SiderealMode.SE_SIDM_LAHIRI;
    }
  }

  /// Runs [body] with a temporary ayanamsa, restoring the previous one afterwards.
  static T withAyanamsa<T>(AyanamsaSystem system, T Function() body) {
    final previous = _ayanamsa;
    if (system == previous) return body();
    setAyanamsa(system);
    try {
      return body();
    } finally {
      setAyanamsa(previous);
    }
  }

  static SwephFlag get _siderealFlags =>
      SwephFlag.SEFLG_SWIEPH | SwephFlag.SEFLG_SPEED | SwephFlag.SEFLG_SIDEREAL;

  static SwephFlag get _tropicalFlags => SwephFlag.SEFLG_SWIEPH | SwephFlag.SEFLG_SPEED;

  // ---------------------------------------------------------------------------
  // Time helpers
  // ---------------------------------------------------------------------------

  /// Julian Day (UT) for a local civil date/time at [utcOffsetHours].
  static double julianDayUT(int year, int month, int day, double hour, double minute,
      [double second = 0, double utcOffsetHours = 0]) {
    final h = hour + minute / 60.0 + second / 3600.0 - utcOffsetHours;
    return Sweph.swe_julday(year, month, day, h, CalendarType.SE_GREG_CAL);
  }

  /// Converts a UT Julian Day to a UTC DateTime.
  static DateTime toUtcDateTime(double jdUt) => Sweph.swe_revjul(jdUt, CalendarType.SE_GREG_CAL);

  // ---------------------------------------------------------------------------
  // Positions
  // ---------------------------------------------------------------------------

  static double ayanamsaValue(double jdUt) =>
      Sweph.swe_get_ayanamsa_ex_ut(jdUt, SwephFlag.SEFLG_SWIEPH);

  /// Sidereal position of a graha (including 'rahu' and 'ketu').
  static PlanetPosition planet(double jdUt, String name) {
    if (name == 'rahu' || name == 'ketu') {
      final node = Sweph.swe_calc_ut(
        jdUt,
        nodeType == NodeType.trueNode ? HeavenlyBody.SE_TRUE_NODE : HeavenlyBody.SE_MEAN_NODE,
        _siderealFlags,
      );
      final lon = name == 'rahu' ? node.longitude : norm360(node.longitude + 180);
      return PlanetPosition(
        name: name,
        longitude: lon,
        latitude: name == 'rahu' ? node.latitude : -node.latitude,
        distance: node.distance,
        speed: node.speedInLongitude,
      );
    }
    final body = _bodies[name];
    if (body == null) throw ArgumentError('Unknown graha: $name');
    final c = Sweph.swe_calc_ut(jdUt, body, _siderealFlags);
    return PlanetPosition(
      name: name,
      longitude: norm360(c.longitude),
      latitude: c.latitude,
      distance: c.distance,
      speed: c.speedInLongitude,
    );
  }

  /// All nine grahas at [jdUt].
  static Map<String, PlanetPosition> allPlanets(double jdUt) =>
      {for (final g in grahas) g: planet(jdUt, g)};

  /// Tropical (sayana) longitude of Sun or Moon – used for elongation searches.
  static double tropicalLongitude(double jdUt, String name) {
    final body = _bodies[name]!;
    return norm360(Sweph.swe_calc_ut(jdUt, body, _tropicalFlags).longitude);
  }

  /// Sidereal ascendant, MC and house cusps. [system] defaults to whole-sign.
  static HouseData houses(double jdUt, double lat, double lon, {Hsys system = Hsys.W}) {
    final h = Sweph.swe_houses_ex(jdUt, SwephFlag.SEFLG_SIDEREAL, lat, lon, system);
    final cusps = List<double>.generate(13, (i) => i == 0 ? 0.0 : norm360(h.cusps[i]));
    return HouseData(norm360(h.ascmc[0]), norm360(h.ascmc[1]), cusps);
  }

  // ---------------------------------------------------------------------------
  // Sun rise / set
  // ---------------------------------------------------------------------------

  /// Next sunrise (UT JD) after [jdUt]. Uses the visible upper limb with standard refraction,
  /// which is what most published Indian panchangs use. Returns null in polar day/night.
  static double? nextSunrise(double jdUt, double lat, double lon, {double altitude = 0}) {
    return Sweph.swe_rise_trans(
      jdUt,
      HeavenlyBody.SE_SUN,
      SwephFlag.SEFLG_SWIEPH,
      RiseSetTransitFlag.SE_CALC_RISE,
      GeoPosition(lon, lat, altitude),
      1013.25,
      15,
    );
  }

  /// Next sunset (UT JD) after [jdUt].
  static double? nextSunset(double jdUt, double lat, double lon, {double altitude = 0}) {
    return Sweph.swe_rise_trans(
      jdUt,
      HeavenlyBody.SE_SUN,
      SwephFlag.SEFLG_SWIEPH,
      RiseSetTransitFlag.SE_CALC_SET,
      GeoPosition(lon, lat, altitude),
      1013.25,
      15,
    );
  }

  /// Next moonrise / moonset after [jdUt].
  static double? nextMoonrise(double jdUt, double lat, double lon) => Sweph.swe_rise_trans(
      jdUt, HeavenlyBody.SE_MOON, SwephFlag.SEFLG_SWIEPH, RiseSetTransitFlag.SE_CALC_RISE,
      GeoPosition(lon, lat, 0), 1013.25, 15);

  static double? nextMoonset(double jdUt, double lat, double lon) => Sweph.swe_rise_trans(
      jdUt, HeavenlyBody.SE_MOON, SwephFlag.SEFLG_SWIEPH, RiseSetTransitFlag.SE_CALC_SET,
      GeoPosition(lon, lat, 0), 1013.25, 15);

  // ---------------------------------------------------------------------------
  // Root finding
  // ---------------------------------------------------------------------------

  /// Finds the first moment at or after [startJd] when [angleAt] (degrees, any range)
  /// reaches [target] (mod 360). [rate] is an approximate positive rate in deg/day used
  /// for the first guess; the search then refines with the secant method.
  static double findAngle(double startJd, double target, double Function(double jd) angleAt,
      {required double rate, int maxIter = 30}) {
    double diffAt(double jd) {
      var d = norm360(target - angleAt(jd));
      if (d > 180) d -= 360; // signed distance to target, -180..180
      return d;
    }

    // First guess: how far ahead the target is at the current rate.
    final ahead = norm360(target - angleAt(startJd));
    double jd0 = startJd;
    double jd1 = startJd + ahead / rate;
    double f0 = ahead; // positive: target still ahead
    double f1 = diffAt(jd1);
    for (int i = 0; i < maxIter; i++) {
      if (f1.abs() < 1e-7) break;
      final denom = f1 - f0;
      if (denom.abs() < 1e-12) break;
      final jd2 = jd1 - f1 * (jd1 - jd0) / denom;
      jd0 = jd1;
      f0 = f1;
      jd1 = jd2;
      f1 = diffAt(jd1);
    }
    return jd1;
  }

  static double norm360(double d) {
    final x = d % 360;
    return x < 0 ? x + 360 : x;
  }

  /// Signed smallest angular difference a-b in (-180, 180].
  static double angleDiff(double a, double b) {
    var d = norm360(a - b);
    if (d > 180) d -= 360;
    return d;
  }

  static double degToRad(double d) => d * math.pi / 180;
}
