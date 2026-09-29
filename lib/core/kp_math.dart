import 'package:sweph/sweph.dart' show Hsys;

import 'astro_engine.dart';
import 'ephemeris.dart';
import 'vedic_math.dart';

class KPPlanetData {
  final String planet;
  final double longitude;
  final String rashi;
  final String signLord;
  final String nakshatraLord;
  final String subLord;
  final String subSubLord;
  final bool retrograde;
  final int house; // Placidus house occupied (1..12)

  KPPlanetData(this.planet, this.longitude, this.rashi, this.nakshatraLord, this.subLord,
      {this.signLord = '', this.subSubLord = '', this.retrograde = false, this.house = 0});
}

class KPCuspData {
  final int cuspNumber;
  final double longitude;
  final String rashi;
  final String signLord;
  final String nakshatraLord;
  final String subLord;
  final String subSubLord;

  KPCuspData(this.cuspNumber, this.longitude, this.rashi, this.nakshatraLord, this.subLord,
      {this.signLord = '', this.subSubLord = ''});
}

/// Krishnamurti Paddhati: Placidus cusps and planets with the KP (Krishnamurti) ayanamsa.
class KPMath {
  static const double _nakSpan = 40.0 / 3.0; // 13°20'

  /// Star lord, sub lord and sub-sub lord for a sidereal longitude.
  static List<String> lordsOf(double sidereal) {
    final lon = VedicMath.norm360(sidereal);
    final nakIdx = (lon / _nakSpan).floor() % 27;
    final starLord = VedicMath.nakshatraLord[nakIdx];
    final offset = lon - nakIdx * _nakSpan;

    // Walk through the 9 subs of the nakshatra, each proportional to its Vimshottari years.
    String sub = starLord;
    double subStart = 0, subSpan = 0;
    final si = VedicMath.dashaOrder.indexOf(starLord);
    for (int i = 0; i < 9; i++) {
      final lord = VedicMath.dashaOrder[(si + i) % 9];
      final span = _nakSpan * VedicMath.dashaYears[lord]! / 120.0;
      if (offset < subStart + span || i == 8) {
        sub = lord;
        subSpan = span;
        break;
      }
      subStart += span;
    }

    // Sub-sub: the same division applied within the sub.
    String subSub = sub;
    final inSub = offset - subStart;
    double ssStart = 0;
    final ssi = VedicMath.dashaOrder.indexOf(sub);
    for (int i = 0; i < 9; i++) {
      final lord = VedicMath.dashaOrder[(ssi + i) % 9];
      final span = subSpan * VedicMath.dashaYears[lord]! / 120.0;
      if (inSub < ssStart + span || i == 8) {
        subSub = lord;
        break;
      }
      ssStart += span;
    }
    return [starLord, sub, subSub];
  }

  static String calculateSubLord(double sidereal) => lordsOf(sidereal)[1];

  /// Placidus cusps (index 1..12) with the KP ayanamsa.
  static List<double> placidusCusps(double jd, double lat, double lon) {
    return AstroEngine.withAyanamsa(AyanamsaSystem.krishnamurti, () {
      return AstroEngine.houses(jd, lat, lon, system: Hsys.P).cusps;
    });
  }

  /// House (1..12) in which [lon] falls given Placidus [cusps] (index 1..12).
  static int houseOf(double lon, List<double> cusps) {
    for (int h = 1; h <= 12; h++) {
      final start = cusps[h];
      final end = cusps[h == 12 ? 1 : h + 1];
      final span = VedicMath.norm360(end - start);
      if (VedicMath.norm360(lon - start) < span) return h;
    }
    return 1;
  }

  static Map<String, KPPlanetData> computeKPPlanets(ChartData chart) {
    final cusps = placidusCusps(chart.jd, chart.lat, chart.lon);
    final positions = AstroEngine.withAyanamsa(
        AyanamsaSystem.krishnamurti, () => AstroEngine.allPlanets(chart.jd));
    final result = <String, KPPlanetData>{};
    positions.forEach((name, pos) {
      final l = lordsOf(pos.longitude);
      final ri = VedicMath.rashiIndex(pos.longitude);
      result[name] = KPPlanetData(
        name,
        pos.longitude,
        VedicMath.rashis[ri].name,
        l[0],
        l[1],
        signLord: VedicMath.rashis[ri].lord,
        subSubLord: l[2],
        retrograde: pos.isRetrograde,
        house: houseOf(pos.longitude, cusps),
      );
    });
    return result;
  }

  static List<KPCuspData> computeKPCusps(double jd, double lat, double lon, [double? unusedAyanamsa]) {
    final cusps = placidusCusps(jd, lat, lon);
    final result = <KPCuspData>[];
    for (int i = 1; i <= 12; i++) {
      final c = cusps[i];
      final ri = VedicMath.rashiIndex(c);
      final l = lordsOf(c);
      result.add(KPCuspData(i, c, VedicMath.rashis[ri].name, l[0], l[1],
          signLord: VedicMath.rashis[ri].lord, subSubLord: l[2]));
    }
    return result;
  }

  /// Four-level KP significators of each house:
  /// A: planets in the star of occupants, B: occupants, C: planets in the star of the cusp's
  /// sign lord, D: the sign lord itself. Returned as house -> ordered unique planet list.
  static Map<int, List<String>> houseSignificators(Map<String, KPPlanetData> planets, List<KPCuspData> cusps) {
    final result = <int, List<String>>{};
    for (int h = 1; h <= 12; h++) {
      final occupants = [for (final p in planets.values) if (p.house == h) p.planet];
      final lord = cusps[h - 1].signLord;
      final inStarOfOccupants = [
        for (final p in planets.values) if (occupants.contains(p.nakshatraLord)) p.planet
      ];
      final inStarOfLord = [for (final p in planets.values) if (p.nakshatraLord == lord) p.planet];
      final ordered = <String>[];
      for (final p in [...inStarOfOccupants, ...occupants, ...inStarOfLord, lord]) {
        if (!ordered.contains(p)) ordered.add(p);
      }
      result[h] = ordered;
    }
    return result;
  }

  /// Ruling planets at [jd] for a place: ascendant sign/star lords, Moon sign/star lords and
  /// the day lord.
  static Map<String, String> rulingPlanets(double jd, double lat, double lon, double utcOffset) {
    return AstroEngine.withAyanamsa(AyanamsaSystem.krishnamurti, () {
      final asc = AstroEngine.houses(jd, lat, lon, system: Hsys.P).ascendant;
      final moon = AstroEngine.planet(jd, 'moon').longitude;
      final local = Ephemeris.jdToDateTime(jd + utcOffset / 24.0);
      const dayLords = ['sun', 'moon', 'mars', 'mercury', 'jupiter', 'venus', 'saturn'];
      return {
        'Ascendant sign lord': VedicMath.rashis[VedicMath.rashiIndex(asc)].lord,
        'Ascendant star lord': lordsOf(asc)[0],
        'Moon sign lord': VedicMath.rashis[VedicMath.rashiIndex(moon)].lord,
        'Moon star lord': lordsOf(moon)[0],
        'Day lord': dayLords[local.weekday % 7],
      };
    });
  }
}
