import 'ephemeris.dart';
import 'vedic_math.dart';

class LalKitabPlanet {
  final String planet;
  final Planet planetData;
  final int natalHouse;
  final int kalpurushRashi;
  final Rashi rashiData;
  final bool isSleeping;
  final String remedy;

  LalKitabPlanet(this.planet, this.planetData, this.natalHouse, this.kalpurushRashi, this.rashiData, this.isSleeping, this.remedy);
}

class LalKitabMath {
  static List<LalKitabPlanet> compute(ChartData chart) {
    int lagnaRashi = (chart.ascendantSidereal / 30).floor();
    List<LalKitabPlanet> result = [];

    chart.planetLongitudes.forEach((pName, sidereal) {
      if (!VedicMath.planets.containsKey(pName)) return;

      int pRashi = VedicMath.rashiIndex(sidereal);
      int house = VedicMath.houseOf(pRashi, lagnaRashi);

      // Kalpurush Rashi: Aries is 0, so house 1 is Aries (0), house 2 is Taurus (1), etc.
      int kalpurushRashi = house - 1; 

      // Lal Kitab basic sleeping rule: Planets in houses 7 to 12 are considered sleeping
      // unless aspected by a planet from 1-6 (we simplify to just 7-12 being asleep initially).
      bool isSleeping = house >= 7;

      String remedy = _getRemedy(pName, house);

      result.add(LalKitabPlanet(
        pName,
        VedicMath.planets[pName]!,
        house,
        kalpurushRashi,
        VedicMath.rashis[kalpurushRashi],
        isSleeping,
        remedy
      ));
    });

    return result;
  }

  static String _getRemedy(String planet, int house) {
    // Simplified generic remedies map. In a real Lal Kitab app, this is heavily contextual.
    final remedies = {
      'sun': {
        1: 'Do not eat beef or pork. Recite Aditya Hridaya Stotra.',
        2: 'Donate coconut, mustard oil, or almonds at a religious place.',
        8: 'Throw copper coins in a flowing river.'
      },
      'moon': {
        6: 'Offer milk in a crematorium or hospital.',
        11: 'Distribute milk to children or temple priests.',
        12: 'Wear silver. Do not drink milk at night.'
      },
      'mars': {
        4: 'Brush teeth with a datum. Do not keep tandoor in house.',
        8: 'Bury jaggery or honey in a crematorium.',
        12: 'Eat sweets before starting any new work.'
      },
      'mercury': {
        3: 'Clean your teeth with alum (phitkari).',
        8: 'Keep a silver square piece with you.',
        12: 'Wear a steel ring in the middle finger.'
      },
      'jupiter': {
        7: 'Never offer clothes to anyone as a gift.',
        10: 'Clean your nose before beginning any work.',
        11: 'Wear a gold ring or yellow thread.'
      },
      'venus': {
        6: 'Keep your spouse happy. Do not wear torn clothes.',
        8: 'Throw a blue flower in a gutter continuously for 43 days.',
        9: 'Bury a silver piece under a neem tree.'
      },
      'saturn': {
        1: 'Avoid consuming alcohol and non-veg food.',
        5: 'Keep almonds in a dark room.',
        8: 'Keep a square piece of silver with you.'
      },
      'rahu': {
        1: 'Wear silver on the neck. Throw barley in running water.',
        5: 'Keep an elephant toy made of solid silver.',
        8: 'Keep fennel seeds (saunf) under your pillow.'
      },
      'ketu': {
        3: 'Apply saffron tilak on the forehead.',
        6: 'Wear a gold ring in the left hand.',
        8: 'Donate a black and white blanket.'
      }
    };

    return remedies[planet]?[house] ?? 'Maintain good moral character and respect elders.';
  }
}
