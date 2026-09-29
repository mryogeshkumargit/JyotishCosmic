import 'ephemeris.dart';
import 'vedic_math.dart';

class AvasthaData {
  final String planet;
  final Planet planetData;
  final double degreeInRashi;
  final int rashiIndex;
  final String baladi;
  final String jagradadi;

  AvasthaData(this.planet, this.planetData, this.degreeInRashi, this.rashiIndex, this.baladi, this.jagradadi);
}

class AvasthasMath {
  static List<AvasthaData> compute(ChartData chart) {
    List<AvasthaData> result = [];

    // Awake = own/exalted, Dreaming = friend/neutral sign, Sleeping = enemy sign/debilitated.
    final Map<String, List<String>> enemies = {
      'sun': ['venus', 'saturn'],
      'moon': [],
      'mars': ['mercury'],
      'mercury': ['moon'],
      'jupiter': ['mercury', 'venus'],
      'venus': ['sun', 'moon'],
      'saturn': ['sun', 'moon', 'mars'],
    };

    chart.planetLongitudes.forEach((pName, sidereal) {
      if (!VedicMath.planets.containsKey(pName)) return;

      int ri = VedicMath.rashiIndex(sidereal);
      double deg = VedicMath.degInRashi(sidereal);
      
      bool isOdd = (ri % 2 == 0); // ri 0 is Aries (Odd), ri 1 is Taurus (Even)

      String baladi;
      if (deg < 6) {
        baladi = isOdd ? 'Infant (Baala)' : 'Dead (Mrita)';
      } else if (deg < 12) {
        baladi = isOdd ? 'Youth (Kumara)' : 'Old (Vriddha)';
      } else if (deg < 18) {
        baladi = 'Adult (Yuva)';
      } else if (deg < 24) {
        baladi = isOdd ? 'Old (Vriddha)' : 'Youth (Kumara)';
      } else {
        baladi = isOdd ? 'Dead (Mrita)' : 'Infant (Baala)';
      }

      String dignity = VedicMath.dignityOf(pName, ri);
      String jagradadi = 'Dreaming (Swapna)'; // Default
      if (dignity == 'own' || dignity == 'exalted') {
        jagradadi = 'Awake (Jagrata)';
      } else if (dignity == 'debilitated') {
        jagradadi = 'Sleeping (Sushupti)';
      } else {
        String lord = VedicMath.rashis[ri].lord;
        if (enemies[pName]?.contains(lord) ?? false) {
          jagradadi = 'Sleeping (Sushupti)';
        }
      }

      result.add(AvasthaData(pName, VedicMath.planets[pName]!, deg, ri, baladi, jagradadi));
    });

    return result;
  }
}
