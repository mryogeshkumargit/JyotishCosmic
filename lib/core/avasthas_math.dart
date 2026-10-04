import 'l10n.dart';
import 'ephemeris.dart';
import 'vedic_math.dart';
import 'planetary_dignity.dart';

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

    final Map<String, int> rashis = {
      for (final e in chart.planetLongitudes.entries) e.key: VedicMath.rashiIndex(e.value)
    };

    chart.planetLongitudes.forEach((pName, sidereal) {
      if (!VedicMath.planets.containsKey(pName)) return;

      int ri = VedicMath.rashiIndex(sidereal);
      double deg = VedicMath.degInRashi(sidereal);
      
      bool isOdd = (ri % 2 == 0); // ri 0 is Aries (Odd), ri 1 is Taurus (Even)

      String baladi;
      if (deg < 6) {
        baladi = isOdd ? tr('Infant (Baala)', 'बाल') : tr('Dead (Mrita)', 'मृत');
      } else if (deg < 12) {
        baladi = isOdd ? tr('Youth (Kumara)', 'कुमार') : tr('Old (Vriddha)', 'वृद्ध');
      } else if (deg < 18) {
        baladi = tr('Adult (Yuva)', 'युवा');
      } else if (deg < 24) {
        baladi = isOdd ? tr('Old (Vriddha)', 'वृद्ध') : tr('Youth (Kumara)', 'कुमार');
      } else {
        baladi = isOdd ? tr('Dead (Mrita)', 'मृत') : tr('Infant (Baala)', 'बाल');
      }

      // Jagradadi: awake in own/exaltation/moolatrikona, dreaming in a friendly or
      // neutral sign, sleeping in an enemy's sign or debilitation.
      final String dignity = PlanetaryDignity.getAdvancedDignity(pName, ri, rashis);
      String jagradadi;
      if (dignity == 'Exalted' || dignity == 'Own Sign' || dignity == 'Moolatrikona') {
        jagradadi = tr('Awake (Jagrata)', 'जाग्रत');
      } else if (dignity == 'Debilitated' || dignity.contains('Enemy')) {
        jagradadi = tr('Sleeping (Sushupti)', 'सुषुप्त');
      } else {
        jagradadi = tr('Dreaming (Swapna)', 'स्वप्न');
      }

      result.add(AvasthaData(pName, VedicMath.planets[pName]!, deg, ri, baladi, jagradadi));
    });

    return result;
  }
}
