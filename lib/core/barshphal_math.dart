import 'ephemeris.dart';
import 'vedic_math.dart';

class BarshphalData {
  final int age;
  final double solarReturnJD;
  final String solarReturnDate;
  final int munthaRashi;
  final Rashi munthaRashiData;
  final Planet munthaLord;
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
    required this.yearLagnaRashi,
    required this.yearLagnaData,
    required this.yearLagnaLord,
    required this.varshaphalChart,
  });
}

class BarshphalMath {
  /// Sidereal year length in days, used to seed the solar-return search.
  static const double siderealYear = 365.256363;

  /// Completed years of life at [jd] (the age whose Varsha is running).
  static int currentAge(ChartData natal, [double? jd]) {
    final double now = jd ?? Ephemeris.nowJd();
    int age = ((now - natal.jd) / siderealYear).floor();
    if (age < 0) return 0;
    // Adjust across the boundary using the exact solar return.
    if (solarReturnJd(natal, age + 1) <= now) age += 1;
    if (age > 0 && solarReturnJd(natal, age) > now) age -= 1;
    return age;
  }

  /// Exact moment the sidereal Sun returns to its natal longitude for [age].
  static double solarReturnJd(ChartData natal, int age) {
    final double natalSun = natal.planetLongitudes['sun']!;
    return Ephemeris.findSunLongitude(natalSun, natal.jd + age * siderealYear);
  }

  /// Varshaphal (annual chart) for the year starting at [age] completed years,
  /// cast for the given place (defaults to the birth place).
  static BarshphalData compute(ChartData natalChart, int age, {double? lat, double? lon, double? utcOffset}) {
    if (age < 0) age = 0;
    final double placeLat = lat ?? natalChart.lat;
    final double placeLon = lon ?? natalChart.lon;
    final double offset = utcOffset ?? natalChart.utcOffset;

    final double srJD = solarReturnJd(natalChart, age);
    final ChartData srChart = Ephemeris.computeChartForJd(srJD, placeLat, placeLon, utcOffset: offset);
    final int yearLagnaRashi = srChart.lagnaRashi;

    // Muntha advances one sign per completed year from the natal Lagna.
    final int muntha = (natalChart.lagnaRashi + age) % 12;

    final local = Ephemeris.jdToUtc(srJD).add(Duration(minutes: (offset * 60).round()));
    String two(int v) => v.toString().padLeft(2, '0');
    final String offsetLabel = 'UTC${offset >= 0 ? '+' : '-'}${_formatOffset(offset.abs())}';

    return BarshphalData(
      age: age,
      solarReturnJD: srJD,
      solarReturnDate: '${local.year}-${two(local.month)}-${two(local.day)} ${two(local.hour)}:${two(local.minute)} ($offsetLabel)',
      munthaRashi: muntha,
      munthaRashiData: VedicMath.rashis[muntha],
      munthaLord: VedicMath.planets[VedicMath.rashis[muntha].lord]!,
      yearLagnaRashi: yearLagnaRashi,
      yearLagnaData: VedicMath.rashis[yearLagnaRashi],
      yearLagnaLord: VedicMath.planets[VedicMath.rashis[yearLagnaRashi].lord]!,
      varshaphalChart: srChart,
    );
  }

  static String _formatOffset(double hours) {
    final int mins = (hours * 60).round();
    return '${mins ~/ 60}:${(mins % 60).toString().padLeft(2, '0')}';
  }
}
