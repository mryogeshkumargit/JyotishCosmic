import 'vedic_math.dart';
import 'planetary_aspects.dart';

class YogaResult {
  final String category;
  final String name;
  final String hindi;
  final bool formed;
  final String strength;
  final String description;
  final List<String> planets;

  YogaResult({
    required this.category,
    required this.name,
    required this.hindi,
    required this.formed,
    this.strength = 'Moderate',
    required this.description,
    this.planets = const [],
  });
}

class YogasMath {
  static bool isKendra(int h) => [1, 4, 7, 10].contains(h);
  static bool isTrikona(int h) => [1, 5, 9].contains(h);
  static bool isDusthana(int h) => [6, 8, 12].contains(h);
  static bool isExalted(String p, int r) => VedicMath.planets[p]?.exalt == r;
  static bool isOwn(String p, int r) => VedicMath.planets[p]?.ownSigns.contains(r) ?? false;
  static String lord(int lagnaRashi, int hNum) => VedicMath.rashis[(lagnaRashi + hNum - 1) % 12].lord;

  static List<YogaResult> computeAllYogas(Map<String, double> longs, int lagnaRashi) {
    List<YogaResult> results = [];
    results.addAll(_panchaMahapurusha(longs, lagnaRashi));
    results.addAll(_rajaYogas(longs, lagnaRashi));
    results.addAll(_dhanaYogas(longs, lagnaRashi));
    results.addAll(_lunarYogas(longs, lagnaRashi));
    return results;
  }

  static List<YogaResult> _panchaMahapurusha(Map<String, double> longs, int lagnaRashi) {
    List<YogaResult> yogas = [];
    final pData = [
      {'p': 'mars', 'y': 'Ruchaka', 'h': 'रुचक', 'd': 'Courage, leadership, military success, physical strength'},
      {'p': 'mercury', 'y': 'Bhadra', 'h': 'भद्र', 'd': 'Intelligence, eloquence, business success, learning'},
      {'p': 'jupiter', 'y': 'Hamsa', 'h': 'हंस', 'd': 'Wisdom, spirituality, prosperity, royal honors'},
      {'p': 'venus', 'y': 'Malavya', 'h': 'मालव्य', 'd': 'Beauty, luxury, artistic talent, marital happiness'},
      {'p': 'saturn', 'y': 'Sasa', 'h': 'शश', 'd': 'Discipline, authority, masses, servants, land ownership'},
    ];

    for (var d in pData) {
      String p = d['p']!;
      if (!longs.containsKey(p)) continue;
      
      int r = VedicMath.rashiIndex(longs[p]!);
      int h = VedicMath.houseOf(r, lagnaRashi);
      bool exalt = isExalted(p, r);
      bool own = isOwn(p, r);
      bool kendra = isKendra(h);
      
      if ((exalt || own) && kendra) {
        yogas.add(YogaResult(
          category: 'Pancha Mahapurusha',
          name: '${d['y']} Yoga',
          hindi: '${d['h']} योग',
          formed: true,
          strength: exalt ? 'Strong (Exalted)' : 'Moderate (Own)',
          description: d['d']!,
          planets: [p],
        ));
      }
    }
    return yogas;
  }

  static List<YogaResult> _rajaYogas(Map<String, double> longs, int lagnaRashi) {
    List<YogaResult> yogas = [];
    
    // Gajakesari
    if (longs.containsKey('jupiter') && longs.containsKey('moon')) {
      int jR = VedicMath.rashiIndex(longs['jupiter']!);
      int mR = VedicMath.rashiIndex(longs['moon']!);
      if (isKendra(VedicMath.houseOf(jR, mR))) {
        yogas.add(YogaResult(
          category: 'Raja Yoga',
          name: 'Gajakesari Yoga',
          hindi: 'गजकेसरी योग',
          formed: true,
          strength: 'Strong',
          description: 'Jupiter in kendra from Moon — fame, intelligence, prosperity, longevity',
          planets: ['jupiter', 'moon'],
        ));
      }
    }

    // Budha-Aditya
    if (longs.containsKey('sun') && longs.containsKey('mercury')) {
      if (VedicMath.rashiIndex(longs['sun']!) == VedicMath.rashiIndex(longs['mercury']!)) {
        yogas.add(YogaResult(
          category: 'Raja Yoga',
          name: 'Budha-Aditya Yoga',
          hindi: 'बुध-आदित्य योग',
          formed: true,
          strength: 'Moderate',
          description: 'Sun & Mercury conjunct — sharp intellect, administrative success, fame',
          planets: ['sun', 'mercury'],
        ));
      }
    }
    // Proper Raj Yoga (Kendra + Trikona lords conjunct)
    List<int> kendras = [1, 4, 7, 10];
    List<int> trikonas = [1, 5, 9];
    
    Map<String, int> planetRashis = {};
    longs.forEach((p, sid) => planetRashis[p] = VedicMath.rashiIndex(sid));

    for (int k in kendras) {
      for (int t in trikonas) {
        if (k == t) continue; // Same lord doesn't form this specific yoga by itself
        String lk = lord(lagnaRashi, k);
        String lt = lord(lagnaRashi, t);
        
        if (longs.containsKey(lk) && longs.containsKey(lt)) {
          int rK = planetRashis[lk]!;
          int rT = planetRashis[lt]!;
          
          bool isConjunct = (rK == rT);
          bool hasMutualAspect = PlanetaryAspects.hasMutualAspect(lk, lt, planetRashis, lagnaRashi);

          if (isConjunct || hasMutualAspect) {
            String type = isConjunct ? 'conjunct' : 'in mutual aspect';
            yogas.add(YogaResult(
              category: 'Raja Yoga',
              name: 'Kendra-Trikona Raj Yoga',
              hindi: 'केन्द्र-त्रिकोण राज योग',
              formed: true,
              strength: isConjunct ? 'Very Strong' : 'Strong',
              description: 'Lords of $k and $t house are $type. Brings success, power, and fame.',
              planets: [lk, lt],
            ));
          }
        }
      }
    }
    
    return yogas;
  }

  static List<YogaResult> _lunarYogas(Map<String, double> longs, int lagnaRashi) {
    List<YogaResult> yogas = [];
    if (!longs.containsKey('moon')) return yogas;

    int mR = VedicMath.rashiIndex(longs['moon']!);
    int secondFromMoon = (mR + 1) % 12;
    int twelfthFromMoon = (mR + 11) % 12;

    List<String> planetsIn2nd = [];
    List<String> planetsIn12th = [];
    
    List<String> truePlanets = ['mars', 'mercury', 'jupiter', 'venus', 'saturn']; // Excluding Sun, Rahu, Ketu for these

    longs.forEach((p, sid) {
      if (!truePlanets.contains(p)) return;
      int r = VedicMath.rashiIndex(sid);
      if (r == secondFromMoon) planetsIn2nd.add(p);
      if (r == twelfthFromMoon) planetsIn12th.add(p);
    });

    if (planetsIn2nd.isNotEmpty && planetsIn12th.isNotEmpty) {
      yogas.add(YogaResult(
        category: 'Lunar Yoga',
        name: 'Durudhara Yoga',
        hindi: 'दुरुधरा योग',
        formed: true,
        strength: 'Moderate',
        description: 'Planets in both 2nd and 12th from Moon. Enjoys comforts, wealth, and loyal followers.',
        planets: [...planetsIn2nd, ...planetsIn12th],
      ));
    } else if (planetsIn2nd.isNotEmpty) {
      yogas.add(YogaResult(
        category: 'Lunar Yoga',
        name: 'Sunapha Yoga',
        hindi: 'सुनफा योग',
        formed: true,
        strength: 'Moderate',
        description: 'Planets in 2nd from Moon. Intelligent, wealthy, and successful by self-effort.',
        planets: planetsIn2nd,
      ));
    } else if (planetsIn12th.isNotEmpty) {
      yogas.add(YogaResult(
        category: 'Lunar Yoga',
        name: 'Anapha Yoga',
        hindi: 'अनफा योग',
        formed: true,
        strength: 'Moderate',
        description: 'Planets in 12th from Moon. Healthy, well-mannered, and enjoys worldly pleasures.',
        planets: planetsIn12th,
      ));
    } else {
      yogas.add(YogaResult(
        category: 'Lunar Yoga',
        name: 'Kemadruma Yoga',
        hindi: 'केमद्रुम योग',
        formed: true,
        strength: 'Negative',
        description: 'No planets on either side of the Moon. Struggles, poverty, and mental restlessness.',
        planets: ['moon'],
      ));
    }

    return yogas;
  }

  static List<YogaResult> _dhanaYogas(Map<String, double> longs, int lagnaRashi) {
    List<YogaResult> yogas = [];
    
    String l2 = lord(lagnaRashi, 2);
    String l11 = lord(lagnaRashi, 11);
    
    if (longs.containsKey(l2) && longs.containsKey(l11)) {
      int r2 = VedicMath.rashiIndex(longs[l2]!);
      int r11 = VedicMath.rashiIndex(longs[l11]!);
      
      if (r2 == r11) {
        yogas.add(YogaResult(
          category: 'Dhana Yoga',
          name: 'Dhana Yoga',
          hindi: 'धन योग',
          formed: true,
          strength: 'Strong',
          description: 'Lords of 2nd & 11th conjunct — significant wealth accumulation',
          planets: [l2, l11],
        ));
      }
    }
    return yogas;
  }
}
