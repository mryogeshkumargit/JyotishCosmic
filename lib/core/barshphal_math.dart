import 'astro_engine.dart';
import 'ephemeris.dart';
import 'vedic_math.dart';

class BarshphalData {
  /// Completed years of age at the start of this Varsha (solar year).
  final int age;
  final double solarReturnJD; // UT
  final String solarReturnDate; // local time
  final int munthaRashi;
  final Rashi munthaRashiData;
  final Planet munthaLord;
  final int munthaHouse; // house of Muntha from the Varsha Lagna
  final int yearLagnaRashi;
  final Rashi yearLagnaData;
  final Planet yearLagnaLord;
  final ChartData varshaphalChart;

  BarshphalData({
    required this.age,
    required this.solarReturnJD,
    required this.solarReturnDate,
    required this.munthaRashi,
    required this.munthaRashiData,
    required this.munthaLord,
    required this.munthaHouse,
    required this.yearLagnaRashi,
    required this.yearLagnaData,
    required this.yearLagnaLord,
    required this.varshaphalChart,
  });
}

/// Tajika Varshaphal (annual chart) from the sidereal solar return.
class BarshphalMath {
  static const double _tropicalYear = 365.2422;

  /// Exact moment the sidereal Sun returns to its natal longitude, near [approxJd].
  static double solarReturnNear(double natalSun, double approxJd) {
    double sunAt(double jd) => AstroEngine.planet(jd, 'sun').longitude;
    return AstroEngine.findAngle(approxJd - 3, natalSun, sunAt, rate: 0.9856);
  }

  /// Varshaphal for the solar year that contains [atJd] (UT). Defaults to now.
  /// [lat]/[lon] are the place where the native lives (traditionally the birth place is also used).
  static BarshphalData compute(ChartData natal, int birthYear, int currentYear, double lat, double lon,
      {double? atJd, double? utcOffset}) {
    final natalSun = natal.planetLongitudes['sun']!;
    final target = atJd ?? Ephemeris.nowJD();
    final offset = utcOffset ?? natal.utcOffset;

    // Completed years since birth, measured by solar returns (not calendar years).
    int age = ((target - natal.jd) / _tropicalYear).floor();
    if (age < 0) age = 0;
    double sr = solarReturnNear(natalSun, natal.jd + age * _tropicalYear);
    if (sr > target && age > 0) {
      age -= 1;
      sr = solarReturnNear(natalSun, natal.jd + age * _tropicalYear);
    } else {
      final next = solarReturnNear(natalSun, natal.jd + (age + 1) * _tropicalYear);
      if (next <= target) {
        age += 1;
        sr = next;
      }
    }
    if (age == 0) sr = natal.jd;

    final chart = Ephemeris.computeChartForJD(sr, lat, lon, utcOffset: offset);
    final yearLagna = chart.lagnaRashi;

    // Muntha progresses one sign per year from the natal Lagna.
    final muntha = (natal.lagnaRashi + age) % 12;

    return BarshphalData(
      age: age,
      solarReturnJD: sr,
      solarReturnDate: _format(sr, offset),
      munthaRashi: muntha,
      munthaRashiData: VedicMath.rashis[muntha],
      munthaLord: VedicMath.planets[VedicMath.rashis[muntha].lord]!,
      munthaHouse: VedicMath.houseOf(muntha, yearLagna),
      yearLagnaRashi: yearLagna,
      yearLagnaData: VedicMath.rashis[yearLagna],
      yearLagnaLord: VedicMath.planets[VedicMath.rashis[yearLagna].lord]!,
      varshaphalChart: chart,
    );
  }

  static String _format(double jdUt, double offset) {
    final dt = Ephemeris.jdToDateTime(jdUt + offset / 24.0);
    const m = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final hh = dt.hour.toString().padLeft(2, '0');
    final mm = dt.minute.toString().padLeft(2, '0');
    final sign = offset >= 0 ? '+' : '-';
    final oh = offset.abs().floor();
    final om = ((offset.abs() - oh) * 60).round().toString().padLeft(2, '0');
    return '${dt.day} ${m[dt.month - 1]} ${dt.year}, $hh:$mm (UTC$sign$oh:$om)';
  }
}
