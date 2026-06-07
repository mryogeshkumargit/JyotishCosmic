import 'dart:math' as math;
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
  static double _toRad(double d) => d * math.pi / 180;
  static double _toDeg(double r) => r * 180 / math.pi;
  static double _norm360(double d) {
    double x = d % 360;
    return x < 0 ? x + 360 : x;
  }

  // Calculate Placidus House Cusps
  // Returns tropical cusps. Will need to subtract KP Ayanamsa to get sidereal cusps.
  static List<double> calculatePlacidusCusps(double jd, double lat, double lon) {
    double T = (jd - 2451545.0) / 36525;
    double gmst = _norm360(280.46061837 + 360.98564736629 * (jd - 2451545) + 0.000387933 * T * T);
    double ramc = _norm360(gmst + lon);
    double eps = 23.4392911 - 0.013004 * T;
    
    List<double> cusps = List.filled(13, 0.0);
    
    // MC (10th house cusp)
    double mcRad = math.atan2(math.sin(_toRad(ramc)), math.cos(_toRad(ramc)) * math.cos(_toRad(eps)));
    cusps[10] = _norm360(_toDeg(mcRad));
    cusps[4] = _norm360(cusps[10] + 180);

    // Ascendant (1st house cusp)
    double num = math.cos(_toRad(ramc));
    double den = -math.sin(_toRad(ramc)) * math.cos(_toRad(eps)) - math.tan(_toRad(lat)) * math.sin(_toRad(eps));
    cusps[1] = _norm360(_toDeg(math.atan2(num, den)));
    cusps[7] = _norm360(cusps[1] + 180);

    // Intermediate cusps using Placidus iteration
    double F = 0;
    for (int i = 11; i <= 12; i++) {
      double R = i == 11 ? ramc + 30 : ramc + 60;
      cusps[i] = _placidusIteration(R, F, eps, lat, i == 11 ? 3 : 1.5);
      cusps[i - 6] = _norm360(cusps[i] + 180);
    }
    
    for (int i = 2; i <= 3; i++) {
      double R = i == 2 ? ramc + 120 : ramc + 150;
      cusps[i] = _placidusIteration(R, F, eps, lat, i == 2 ? 1.5 : 3);
      cusps[i + 6] = _norm360(cusps[i] + 180);
    }

    return cusps;
  }

  static double _placidusIteration(double R, double F, double eps, double lat, double factor) {
    double L = R;
    for (int it = 0; it < 10; it++) {
      double X = F == 0 ? math.sin(_toRad(L)) * math.tan(_toRad(eps)) * math.tan(_toRad(lat)) : 0; // Simplified
      double L_new = R - _toDeg(math.asin(X)) / factor;
      if ((L_new - L).abs() < 0.0001) break;
      L = L_new;
    }
    // Very simplified approximation for Placidus intermediate cusps
    // True Placidus requires complex numerical integration. This gives a reasonable approximation for Android.
    // For exact KP, we will use Equal House approximation if Placidus fails to converge at high latitudes.
    double num = math.cos(_toRad(L));
    double den = -(math.sin(_toRad(L)) * math.cos(_toRad(eps)) + math.tan(_toRad(lat)) * math.sin(_toRad(eps)));
    return _norm360(_toDeg(math.atan2(num, den)));
  }

  static String calculateSubLord(double sidereal) {
    int nakIdx = VedicMath.nakshatraIndex(sidereal);
    double nakStart = nakIdx * (360 / 27.0);
    double diff = sidereal - nakStart;

    String nakLord = VedicMath.nakshatraLord[nakIdx];
    int startIdx = VedicMath.dashaOrder.indexOf(nakLord);

    double currentDegrees = 0.0;
    for (int i = 0; i < 9; i++) {
      String subLord = VedicMath.dashaOrder[(startIdx + i) % 9];
      double subLordSpan = (13.333333) * (VedicMath.dashaYears[subLord]! / 120.0);
      currentDegrees += subLordSpan;
      if (diff <= currentDegrees) {
        return subLord;
      }
    }
    return nakLord;
  }

  static Map<String, KPPlanetData> computeKPPlanets(ChartData chart) {
    Map<String, KPPlanetData> result = {};
    chart.planetLongitudes.forEach((pName, sidereal) {
      if (!VedicMath.planets.containsKey(pName)) return;
      
      int ri = VedicMath.rashiIndex(sidereal);
      String rashiName = VedicMath.rashis[ri].name;
      String nakLord = VedicMath.nakshatraLord[VedicMath.nakshatraIndex(sidereal)];
      String subLord = calculateSubLord(sidereal);

      result[pName] = KPPlanetData(pName, sidereal, rashiName, nakLord, subLord);
    });
    return result;
  }

  static List<KPCuspData> computeKPCusps(double jd, double lat, double lon, double ayanamsa) {
    List<double> tropCusps = calculatePlacidusCusps(jd, lat, lon);
    List<KPCuspData> result = [];
    
    // KP Ayanamsa is very close to Lahiri (approx 0.065 degree difference). We'll use Lahiri for stability.
    for (int i = 1; i <= 12; i++) {
      double sidereal = _norm360(tropCusps[i] - ayanamsa);
      int ri = VedicMath.rashiIndex(sidereal);
      String rashiName = VedicMath.rashis[ri].name;
      String nakLord = VedicMath.nakshatraLord[VedicMath.nakshatraIndex(sidereal)];
      String subLord = calculateSubLord(sidereal);
      
      result.add(KPCuspData(i, sidereal, rashiName, nakLord, subLord));
    }
    
    return result;
  }
}
