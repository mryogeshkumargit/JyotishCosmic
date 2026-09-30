import 'ephemeris.dart';
import 'vedic_math.dart';

class KPPlanetData {
  final String planet;
  final double longitude;
  final String rashi;
  final String nakshatraLord;
  final String subLord;

  KPPlanetData(this.planet, this.longitude, this.rashi, this.nakshatraLord, this.subLord);
}

class KPCuspData {
  final int cuspNumber;
  final double longitude;
  final String rashi;
  final String nakshatraLord;
  final String subLord;

  KPCuspData(this.cuspNumber, this.longitude, this.rashi, this.nakshatraLord, this.subLord);
}

class KPMath {
  static const double _nakSpan = 360 / 27.0;

  /// Sub-lord (Vimshottari proportion within the nakshatra) of a sidereal longitude.
  static String calculateSubLord(double sidereal) {
    final int nakIdx = VedicMath.nakshatraIndex(sidereal);
    final double diff = VedicMath.norm360(sidereal) - nakIdx * _nakSpan;

    final String nakLord = VedicMath.nakshatraLord[nakIdx];
    final int startIdx = VedicMath.dashaOrder.indexOf(nakLord);

    double currentDegrees = 0.0;
    for (int i = 0; i < 9; i++) {
      final String subLord = VedicMath.dashaOrder[(startIdx + i) % 9];
      currentDegrees += _nakSpan * VedicMath.dashaYears[subLord]! / 120.0;
      if (diff < currentDegrees) return subLord;
    }
    return VedicMath.dashaOrder[(startIdx + 8) % 9];
  }

  /// Planets recomputed with the Krishnamurti ayanamsa, as used in KP.
  static Map<String, KPPlanetData> computeKPPlanets(ChartData chart) {
    final ChartData kpChart = Ephemeris.computeChartForJd(chart.jd, chart.lat, chart.lon,
        utcOffset: chart.utcOffset, mode: Ayanamsa.krishnamurti);
    final Map<String, KPPlanetData> result = {};
    kpChart.planetLongitudes.forEach((pName, sidereal) {
      if (!VedicMath.planets.containsKey(pName)) return;
      final int ri = VedicMath.rashiIndex(sidereal);
      final String nakLord = VedicMath.nakshatraLord[VedicMath.nakshatraIndex(sidereal)];
      result[pName] = KPPlanetData(pName, sidereal, VedicMath.rashis[ri].name, nakLord, calculateSubLord(sidereal));
    });
    return result;
  }

  /// Placidus cusps (Krishnamurti ayanamsa) with star and sub lords.
  static List<KPCuspData> computeKPCusps(double jd, double lat, double lon) {
    final List<double> cusps = Ephemeris.placidusCusps(jd, lat, lon, Ayanamsa.krishnamurti);
    final List<KPCuspData> result = [];
    for (int i = 1; i <= 12; i++) {
      final double sidereal = cusps[i];
      final int ri = VedicMath.rashiIndex(sidereal);
      final String nakLord = VedicMath.nakshatraLord[VedicMath.nakshatraIndex(sidereal)];
      result.add(KPCuspData(i, sidereal, VedicMath.rashis[ri].name, nakLord, calculateSubLord(sidereal)));
    }
    return result;
  }
}
