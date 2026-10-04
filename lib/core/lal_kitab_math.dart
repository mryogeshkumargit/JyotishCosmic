import 'ephemeris.dart';
import 'l10n.dart';
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
        1: tr('Do not eat beef or pork. Recite Aditya Hridaya Stotra.', 'गोमांस या सूअर का मांस न खाएँ। आदित्य हृदय स्तोत्र का पाठ करें।'),
        2: tr('Donate coconut, mustard oil, or almonds at a religious place.', 'धार्मिक स्थान पर नारियल, सरसों का तेल या बादाम दान करें।'),
        8: tr('Throw copper coins in a flowing river.', 'बहती नदी में तांबे के सिक्के प्रवाहित करें।')
      },
      'moon': {
        6: tr('Offer milk in a crematorium or hospital.', 'श्मशान या अस्पताल में दूध अर्पित करें।'),
        11: tr('Distribute milk to children or temple priests.', 'बच्चों या मंदिर के पुजारियों को दूध बाँटें।'),
        12: tr('Wear silver. Do not drink milk at night.', 'चांदी पहनें। रात को दूध न पिएँ।')
      },
      'mars': {
        4: tr('Brush teeth with a datum. Do not keep tandoor in house.', 'दातुन से दाँत साफ़ करें। घर में तंदूर न रखें।'),
        8: tr('Bury jaggery or honey in a crematorium.', 'श्मशान में गुड़ या शहद दबाएँ।'),
        12: tr('Eat sweets before starting any new work.', 'कोई भी नया काम शुरू करने से पहले मीठा खाएँ।')
      },
      'mercury': {
        3: tr('Clean your teeth with alum (phitkari).', 'फिटकरी से दाँत साफ़ करें।'),
        8: tr('Keep a silver square piece with you.', 'अपने पास चांदी का चौकोर टुकड़ा रखें।'),
        12: tr('Wear a steel ring in the middle finger.', 'मध्यमा उंगली में स्टील की अंगूठी पहनें।')
      },
      'jupiter': {
        7: tr('Never offer clothes to anyone as a gift.', 'किसी को उपहार में कपड़े कभी न दें।'),
        10: tr('Clean your nose before beginning any work.', 'कोई भी काम शुरू करने से पहले नाक साफ़ करें।'),
        11: tr('Wear a gold ring or yellow thread.', 'सोने की अंगूठी या पीला धागा पहनें।')
      },
      'venus': {
        6: tr('Keep your spouse happy. Do not wear torn clothes.', 'जीवनसाथी को प्रसन्न रखें। फटे कपड़े न पहनें।'),
        8: tr('Throw a blue flower in a gutter continuously for 43 days.', 'लगातार 43 दिन नाली में नीला फूल डालें।'),
        9: tr('Bury a silver piece under a neem tree.', 'नीम के पेड़ के नीचे चांदी का टुकड़ा दबाएँ।')
      },
      'saturn': {
        1: tr('Avoid consuming alcohol and non-veg food.', 'शराब और मांसाहार से बचें।'),
        5: tr('Keep almonds in a dark room.', 'अँधेरे कमरे में बादाम रखें।'),
        8: tr('Keep a square piece of silver with you.', 'अपने पास चांदी का चौकोर टुकड़ा रखें।')
      },
      'rahu': {
        1: tr('Wear silver on the neck. Throw barley in running water.', 'गले में चांदी पहनें। बहते पानी में जौ प्रवाहित करें।'),
        5: tr('Keep an elephant toy made of solid silver.', 'ठोस चांदी का हाथी रखें।'),
        8: tr('Keep fennel seeds (saunf) under your pillow.', 'तकिए के नीचे सौंफ रखें।')
      },
      'ketu': {
        3: tr('Apply saffron tilak on the forehead.', 'माथे पर केसर का तिलक लगाएँ।'),
        6: tr('Wear a gold ring in the left hand.', 'बाएँ हाथ में सोने की अंगूठी पहनें।'),
        8: tr('Donate a black and white blanket.', 'काला-सफ़ेद कंबल दान करें।')
      }
    };

    return remedies[planet]?[house] ?? tr('Maintain good moral character and respect elders.', 'अच्छा नैतिक आचरण रखें और बड़ों का सम्मान करें।');
  }
}
