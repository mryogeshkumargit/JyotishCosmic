import 'dart:math' as math;

class ChartData {
  final Map<int, List<String>> housePlanets;
  final Map<String, double> planetLongitudes;
  final double ascendantSidereal;
  final double jd;

  ChartData(this.housePlanets, this.planetLongitudes, this.ascendantSidereal, this.jd);
}

class Ephemeris {
  // Julian Day
  static double julianDay(int year, int month, int day, [double hour = 12, double minute = 0, double second = 0]) {
    if (month <= 2) {
      year -= 1;
      month += 12;
    }
    final int A = (year / 100).floor();
    final int B = 2 - A + (A / 4).floor();
    return (365.25 * (year + 4716)).floor() +
        (30.6001 * (month + 1)).floor() +
        day +
        B -
        1524.5 +
        (hour + minute / 60 + second / 3600) / 24;
  }

  static double _toRad(double d) => d * math.pi / 180;
  static double _toDeg(double r) => r * 180 / math.pi;
  static double _norm360(double d) {
    double x = d % 360;
    return x < 0 ? x + 360 : x;
  }

  // Lahiri Ayanamsa
  static double lahiriAyanamsa(double jd) {
    final double T = (jd - 2451545.0) / 36525;
    return _norm360(23.85064 + 1.39675 * T + 0.000139 * T * T);
  }

  // Kepler solver
  static double _keplerSolve(double mRad, double e) {
    double E = mRad;
    for (int i = 0; i < 12; i++) {
      double dE = (mRad - E + e * math.sin(E)) / (1 - e * math.cos(E));
      E += dE;
      if (dE.abs() < 1e-9) break;
    }
    return E;
  }

  // Sun
  static double sunLongitude(double T) {
    double l0 = _norm360(280.46646 + 36000.76983 * T + 3.032e-4 * T * T);
    double m = _norm360(357.52911 + 35999.05029 * T - 1.537e-4 * T * T);
    double mR = _toRad(m);
    double C = (1.914602 - 0.004817 * T - 1.4e-5 * T * T) * math.sin(mR) +
        (0.019993 - 1.01e-4 * T) * math.sin(2 * mR) +
        2.89e-4 * math.sin(3 * mR);
    double om = _norm360(125.04 - 1934.136 * T);
    return _norm360(l0 + C - 0.00569 - 0.00478 * math.sin(_toRad(om)));
  }

  static double sunDistance(double T) {
    double m = _toRad(_norm360(357.52911 + 35999.05029 * T));
    double e = 0.016708634 - 4.2037e-5 * T;
    double E = _keplerSolve(m, e);
    return 1.000001018 * (1 - e * math.cos(E));
  }

  // Moon
  static double moonLongitude(double T) {
    double lp = _norm360(218.3164477 + 481267.88123421 * T - 0.0015786 * T * T + T * T * T / 538841);
    double d = _norm360(297.8501921 + 445267.1114034 * T - 0.0018819 * T * T + T * T * T / 545868);
    double m = _norm360(357.5291092 + 35999.0502909 * T - 0.0001536 * T * T);
    double mp = _norm360(134.9633964 + 477198.8675055 * T + 0.0087414 * T * T + T * T * T / 69699);
    double f = _norm360(93.2720950 + 483202.0175233 * T - 0.0036539 * T * T);
    double dr = _toRad(d), mr = _toRad(m), mpr = _toRad(mp), fr = _toRad(f);
    double e = 1 - 0.002516 * T - 0.0000074 * T * T;

    const terms = [
      [0, 0, 1, 0, 6288774], [2, 0, -1, 0, 1274027], [2, 0, 0, 0, 658314], [0, 0, 2, 0, 213618],
      [0, 1, 0, 0, -185116], [0, 0, 0, 2, -114332], [2, 0, -2, 0, 58793], [2, -1, -1, 0, 57066],
      [2, 0, 1, 0, 53322], [2, -1, 0, 0, 45758], [0, 1, -1, 0, -40923], [1, 0, 0, 0, -34720],
      [0, 1, 1, 0, -30383], [2, 0, 0, -2, 15327], [0, 0, 1, 2, -12528], [0, 0, 1, -2, 10980],
      [4, 0, -1, 0, 10675], [0, 0, 3, 0, 10034], [4, 0, -2, 0, 8548], [2, 1, -1, 0, -7888],
      [2, 1, 0, 0, -6766], [1, 0, -1, 0, -5163], [1, 1, 0, 0, 4987], [2, -1, 1, 0, 4036],
      [2, 0, 2, 0, 3994], [4, 0, 0, 0, 3861], [2, 0, -3, 0, 3665], [0, 1, -2, 0, -2689],
      [2, -1, -2, 0, 2390], [1, 0, 1, 0, -2348], [2, -2, 0, 0, 2236], [0, 1, 2, 0, -2120],
      [0, 2, 0, 0, -2069], [2, -2, -1, 0, 2048], [2, 0, 1, -2, -1773], [2, 0, 0, 2, -1595],
      [4, -1, -1, 0, 1215], [0, 0, 2, 2, -1110], [3, 0, -1, 0, -892], [2, 1, 1, 0, -810],
    ];

    double sl = 0;
    for (var term in terms) {
      double arg = term[0] * dr + term[1] * mr + term[2] * mpr + term[3] * fr;
      double c = term[4] * math.sin(arg);
      if (term[1].abs() == 1) c *= e;
      if (term[1].abs() == 2) c *= e * e;
      sl += c;
    }
    return _norm360(lp + sl / 1e6);
  }

  // Planets via orbital elements
  static const Map<String, List<double>> _elements = {
    'mercury': [252.250906, 149472.6746358, 0.20563069, -2.52e-5, 7.004986, -5.99e-3, 48.330893, -1.2543e-1, 77.456119, 1.5886e-1, 0.387098],
    'venus': [181.979801, 58517.815676, 0.00677323, -4.938e-5, 3.394662, -8.568e-4, 76.679920, -2.7801e-1, 131.563703, 4.8746e-3, 0.723330],
    'mars': [355.433275, 19140.299331, 0.09341233, 1.19e-5, 1.849726, -6.011e-4, 49.558093, -1.0203e0, 336.060234, 4.4390e-1, 1.523679],
    'jupiter': [34.351484, 3034.905675, 0.04839266, -1.29e-4, 1.303270, -1.987e-3, 100.464441, 1.7688e-1, 14.331309, 2.1555e-1, 5.202603],
    'saturn': [50.077444, 1222.113849, 0.05415060, -3.68e-4, 2.488878, 2.552e-3, 113.665524, -2.567e-1, 93.057136, 5.665e-1, 9.536676],
  };

  static Map<String, double> _getHelioCoords(double T, List<double> el) {
    double l = _norm360(el[0] + el[1] * T);
    double e = el[2] + el[3] * T;
    double w = _norm360(el[8] + el[9] * T);
    double m = _norm360(l - w);
    double E = _keplerSolve(_toRad(m), e);
    double v = _toDeg(2 * math.atan2(math.sqrt(1 + e) * math.sin(E / 2), math.sqrt(1 - e) * math.cos(E / 2)));
    double pLong = _norm360(v + w);
    double pDist = el[10] * (1 - e * math.cos(E));
    return {'pLong': pLong, 'pDist': pDist};
  }

  static double _helioToGeo(double pLong, double pDist, double sLong, double sDist) {
    double dp = _toRad(pLong - sLong);
    double x = pDist * math.cos(dp) + sDist;
    double y = pDist * math.sin(dp);
    return _norm360(_toDeg(math.atan2(y, x)) + sLong);
  }

  static double _getGeoLong(String name, double T) {
    if (name == 'sun') return sunLongitude(T);
    if (name == 'moon') return moonLongitude(T);

    final el = _elements[name]!;
    final sLong = sunLongitude(T);
    final sDist = sunDistance(T);
    final helio = _getHelioCoords(T, el);

    return _helioToGeo(helio['pLong']!, helio['pDist']!, sLong, sDist);
  }

  // Rahu
  static double rahuLongitude(double T) {
    double n = _norm360(125.0445479 - 1934.1362608 * T + 0.0020754 * T * T + T * T * T / 467441);
    double d = _toRad(_norm360(297.8501921 + 445267.1114034 * T));
    double m = _toRad(_norm360(357.5291092 + 35999.0502909 * T));
    double mp = _toRad(_norm360(134.9633964 + 477198.8675055 * T));
    double f = _toRad(_norm360(93.2720950 + 483202.0175233 * T));
    n += -1.4979 * math.sin(2 * (d - f)) -
        0.1500 * math.sin(m) -
        0.1226 * math.sin(2 * d) +
        0.1176 * math.sin(2 * f) -
        0.0801 * math.sin(2 * (mp - f));
    return _norm360(n);
  }

  // Ascendant
  static double ascendant(double jd, double lat, double lon) {
    double T = (jd - 2451545.0) / 36525;
    double gmst = _norm360(280.46061837 + 360.98564736629 * (jd - 2451545) + 0.000387933 * T * T);
    double lst = _norm360(gmst + lon);
    double ramc = _toRad(lst);
    double eps = _toRad(23.4392911 - 0.013004 * T);
    double latR = _toRad(lat);

    double num = math.cos(ramc);
    double den = -math.sin(ramc) * math.cos(eps) - math.tan(latR) * math.sin(eps);

    return _norm360(_toDeg(math.atan2(num, den)));
  }

  // Generate house map directly for KundliChart
  static ChartData computeChart(
      int year, int month, int day, double hour, double minute, double lat, double lon, double utcOffset) {
    
    double utcH = hour - utcOffset;
    double jd = julianDay(year, month, day, utcH, minute, 0);
    double T = (jd - 2451545.0) / 36525;
    double ayan = lahiriAyanamsa(jd);

    // Calculate Ascendant (Lagna)
    double ascTrop = ascendant(jd, lat, lon);
    double ascSid = _norm360(ascTrop - ayan);
    int lagnaSign = (ascSid / 30).floor() + 1; // 1=Aries, 2=Taurus...

    // Calculate Planets
    final List<String> planNames = ['sun', 'moon', 'mars', 'mercury', 'jupiter', 'venus', 'saturn'];
    final Map<String, double> siderealLongs = {};

    for (var name in planNames) {
      double tropical = _getGeoLong(name, T);
      siderealLongs[name] = _norm360(tropical - ayan);
    }

    // Rahu and Ketu
    double rahuTrop = rahuLongitude(T);
    siderealLongs['rahu'] = _norm360(rahuTrop - ayan);
    siderealLongs['ketu'] = _norm360(rahuTrop - ayan + 180);

    // Map to 12 Houses
    Map<int, List<String>> housePlanets = {};
    for (int i = 1; i <= 12; i++) {
      housePlanets[i] = [];
    }

    final Map<String, String> planetDisplayNames = {
      'sun': 'Su', 'moon': 'Mo', 'mars': 'Ma', 'mercury': 'Me',
      'jupiter': 'Ju', 'venus': 'Ve', 'saturn': 'Sa',
      'rahu': 'Ra', 'ketu': 'Ke'
    };

    siderealLongs.forEach((name, longitude) {
      int planetSign = (longitude / 30).floor() + 1;
      // Formula: House = (PlanetSign - LagnaSign + 12) % 12 + 1
      int house = (planetSign - lagnaSign + 12) % 12 + 1;
      housePlanets[house]!.add(planetDisplayNames[name]!);
    });

    return ChartData(housePlanets, siderealLongs, ascSid, jd);
  }
}
