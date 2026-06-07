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
  static BarshphalData compute(ChartData natalChart, int birthYear, int currentYear, double lat, double lon) {
    int age = currentYear - birthYear;
    if (age < 0) age = 0;

    double natalSun = natalChart.planetLongitudes['sun']!;
    double natalJD = natalChart.jd;

    // Estimate Solar Return JD
    double approxJD = natalJD + age * 365.242199;
    
    // Binary Search to find the exact Solar Return JD
    double lowJD = approxJD - 2.0;
    double highJD = approxJD + 2.0;
    double srJD = approxJD;

    for (int i = 0; i < 40; i++) {
      double midJD = (lowJD + highJD) / 2;
      double T = (midJD - 2451545.0) / 36525;
      double ayan = Ephemeris.lahiriAyanamsa(midJD);
      double currentSun = VedicMath.norm360(Ephemeris.sunLongitude(T) - ayan);

      double diff = currentSun - natalSun;
      if (diff > 180) diff -= 360;
      if (diff < -180) diff += 360;

      if (diff > 0) {
        highJD = midJD;
      } else {
        lowJD = midJD;
      }
      srJD = midJD;
      if (diff.abs() < 0.00001) break;
    }

    // Compute the Solar Return Chart
    // Reverse JD to year, month, day, hour. This is a bit complex but we can approximate or use jd directly for ascendant.
    double T_sr = (srJD - 2451545.0) / 36525;
    double ayan_sr = Ephemeris.lahiriAyanamsa(srJD);
    double ascTrop = Ephemeris.ascendant(srJD, lat, lon);
    double ascSid = VedicMath.norm360(ascTrop - ayan_sr);
    int yearLagnaRashi = (ascSid / 30).floor();

    Map<String, double> srPlanets = {};
    for (var pName in ['sun', 'moon', 'mars', 'mercury', 'jupiter', 'venus', 'saturn']) {
      double trop = pName == 'sun' ? Ephemeris.sunLongitude(T_sr) : (pName == 'moon' ? Ephemeris.moonLongitude(T_sr) : Ephemeris.sunLongitude(T_sr)); 
      // Need proper geocentric coords for the rest. We'll use a hack or recreate computeChart from JD.
      // Since computeChart takes Y,M,D,H,M, it's easier to just compute JD->Date.
    }

    // Convert JD to Date exactly
    int z = (srJD + 0.5).floor();
    double f = (srJD + 0.5) - z;
    int a = z < 2299161 ? z : (() {
      int aa = ((z - 1867216.25) / 36524.25).floor();
      return z + 1 + aa - (aa / 4).floor();
    })();
    int b = a + 1524;
    int c = ((b - 122.1) / 365.25).floor();
    int d = (365.25 * c).floor();
    int e = ((b - d) / 30.6001).floor();
    int day = b - d - (30.6001 * e).floor();
    int month = e < 14 ? e - 1 : e - 13;
    int year = month > 2 ? c - 4716 : c - 4715;

    double fractionalDay = f;
    double hours = fractionalDay * 24;
    int h = hours.floor();
    double minutes = (hours - h) * 60;
    int m = minutes.floor();

    // Use UTC offset 0 for JD -> UTC Chart
    ChartData srChart = Ephemeris.computeChart(year, month, day, h.toDouble(), m.toDouble(), lat, lon, 0);

    // Recalculate year lagna from standard chart
    yearLagnaRashi = (srChart.ascendantSidereal / 30).floor();

    // Muntha = (Natal Lagna + Age) % 12
    int natalLagna = (natalChart.ascendantSidereal / 30).floor();
    int muntha = (natalLagna + age) % 12;

    return BarshphalData(
      age: age,
      solarReturnJD: srJD,
      solarReturnDate: "\$year-\$month-\$day \$h:\$m UTC",
      munthaRashi: muntha,
      munthaRashiData: VedicMath.rashis[muntha],
      munthaLord: VedicMath.planets[VedicMath.rashis[muntha].lord]!,
      yearLagnaRashi: yearLagnaRashi,
      yearLagnaData: VedicMath.rashis[yearLagnaRashi],
      yearLagnaLord: VedicMath.planets[VedicMath.rashis[yearLagnaRashi].lord]!,
      varshaphalChart: srChart,
    );
  }
}
