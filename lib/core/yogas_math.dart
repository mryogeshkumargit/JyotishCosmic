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

/// Classical yoga detection on a sidereal chart (whole-sign houses, 0-based [lagnaRashi]).
class YogasMath {
  static bool isKendra(int h) => const [1, 4, 7, 10].contains(h);
  static bool isTrikona(int h) => const [1, 5, 9].contains(h);
  static bool isDusthana(int h) => const [6, 8, 12].contains(h);
  static bool isExalted(String p, int r) => VedicMath.planets[p]?.exalt == r;
  static bool isDebilitated(String p, int r) => VedicMath.planets[p]?.debi == r;
  static bool isOwn(String p, int r) => VedicMath.planets[p]?.ownSigns.contains(r) ?? false;

  /// Lord of the [hNum]th house (1-based) for a 0-based [lagnaRashi].
  static String lord(int lagnaRashi, int hNum) => VedicMath.rashis[(lagnaRashi + hNum - 1) % 12].lord;

  static const List<String> _seven = ['sun', 'moon', 'mars', 'mercury', 'jupiter', 'venus', 'saturn'];
  static const List<String> _naturalBenefics = ['jupiter', 'venus', 'mercury'];

  static List<YogaResult> computeAllYogas(Map<String, double> longs, int lagnaRashi) {
    final rashis = {for (final e in longs.entries) e.key: VedicMath.rashiIndex(e.value)};
    final results = <YogaResult>[];
    results.addAll(_panchaMahapurusha(rashis, lagnaRashi));
    results.addAll(_rajaYogas(longs, rashis, lagnaRashi));
    results.addAll(_dhanaYogas(rashis, lagnaRashi));
    results.addAll(_lunarYogas(rashis, lagnaRashi));
    results.addAll(_solarYogas(rashis));
    results.addAll(_otherYogas(rashis, lagnaRashi));
    return results;
  }

  static int _house(Map<String, int> rashis, String p, int lagnaRashi) =>
      VedicMath.houseOf(rashis[p]!, lagnaRashi);

  static String _name(String p) => VedicMath.planets[p]?.name ?? p;

  // ---------------------------------------------------------------------------

  static List<YogaResult> _panchaMahapurusha(Map<String, int> rashis, int lagnaRashi) {
    final yogas = <YogaResult>[];
    const data = [
      ['mars', 'Ruchaka', 'रुचक', 'Courage, leadership, military success, physical strength'],
      ['mercury', 'Bhadra', 'भद्र', 'Intelligence, eloquence, business success, learning'],
      ['jupiter', 'Hamsa', 'हंस', 'Wisdom, spirituality, prosperity, royal honours'],
      ['venus', 'Malavya', 'मालव्य', 'Beauty, luxury, artistic talent, marital happiness'],
      ['saturn', 'Sasa', 'शश', 'Discipline, authority over masses, land and property'],
    ];
    for (final d in data) {
      final p = d[0];
      if (!rashis.containsKey(p)) continue;
      final r = rashis[p]!;
      final fromLagna = isKendra(VedicMath.houseOf(r, lagnaRashi));
      final fromMoon = rashis.containsKey('moon') && isKendra(VedicMath.houseOf(r, rashis['moon']!));
      if ((isExalted(p, r) || isOwn(p, r)) && (fromLagna || fromMoon)) {
        yogas.add(YogaResult(
          category: 'Pancha Mahapurusha',
          name: '${d[1]} Yoga',
          hindi: '${d[2]} योग',
          formed: true,
          strength: '${isExalted(p, r) ? 'Strong (exalted)' : 'Moderate (own sign)'}'
              '${fromLagna ? '' : ' — from Moon only'}',
          description: d[3],
          planets: [p],
        ));
      }
    }
    return yogas;
  }

  static List<YogaResult> _rajaYogas(Map<String, double> longs, Map<String, int> rashis, int lagnaRashi) {
    final yogas = <YogaResult>[];

    // Gajakesari: Jupiter in a kendra from the Moon.
    if (rashis.containsKey('jupiter') && rashis.containsKey('moon')) {
      final h = VedicMath.houseOf(rashis['jupiter']!, rashis['moon']!);
      if (isKendra(h)) {
        final weak = isDebilitated('jupiter', rashis['jupiter']!);
        yogas.add(YogaResult(
          category: 'Raja Yoga',
          name: 'Gajakesari Yoga',
          hindi: 'गजकेसरी योग',
          formed: true,
          strength: weak ? 'Weak (Jupiter debilitated)' : 'Strong',
          description: 'Jupiter in a kendra from the Moon — fame, intelligence, prosperity and lasting reputation.',
          planets: ['jupiter', 'moon'],
        ));
      }
    }

    // Budha-Aditya: Sun and Mercury in the same sign.
    if (rashis.containsKey('sun') && rashis.containsKey('mercury') && rashis['sun'] == rashis['mercury']) {
      final orb = VedicMath.angularDistance(longs['sun']!, longs['mercury']!);
      yogas.add(YogaResult(
        category: 'Raja Yoga',
        name: 'Budha-Aditya Yoga',
        hindi: 'बुध-आदित्य योग',
        formed: true,
        strength: orb < 10 ? 'Moderate (Mercury may be combust)' : 'Moderate',
        description: 'Sun and Mercury together — sharp intellect, administrative ability, recognition.',
        planets: ['sun', 'mercury'],
      ));
    }

    // Yogakaraka: one planet lording both a kendra (4/7/10) and a trikona (5/9).
    final lagnaLord = lord(lagnaRashi, 1);
    for (final p in _seven) {
      if (p == lagnaLord) continue;
      final owns = [for (int h = 1; h <= 12; h++) if (lord(lagnaRashi, h) == p) h];
      if (owns.any((h) => [4, 7, 10].contains(h)) && owns.any((h) => [5, 9].contains(h))) {
        yogas.add(YogaResult(
          category: 'Raja Yoga',
          name: 'Yogakaraka ${_name(p)}',
          hindi: 'योगकारक',
          formed: true,
          strength: 'Strong',
          description: '${_name(p)} rules houses ${owns.join(' & ')} (a kendra and a trikona) — its periods bring rise and success.',
          planets: [p],
        ));
      }
    }

    // Kendra–Trikona Raja Yoga: lords of a kendra and a trikona conjunct or in mutual aspect.
    final seen = <String>{};
    for (final k in [1, 4, 7, 10]) {
      for (final t in [5, 9]) {
        final lk = lord(lagnaRashi, k);
        final lt = lord(lagnaRashi, t);
        if (lk == lt) continue; // handled as Yogakaraka
        if (!rashis.containsKey(lk) || !rashis.containsKey(lt)) continue;
        final key = ([lk, lt]..sort()).join('-');
        if (seen.contains(key)) continue;
        final conjunct = rashis[lk] == rashis[lt];
        final mutual = !conjunct && PlanetaryAspects.hasMutualAspect(lk, lt, rashis, lagnaRashi);
        if (conjunct || mutual) {
          seen.add(key);
          yogas.add(YogaResult(
            category: 'Raja Yoga',
            name: 'Kendra-Trikona Raja Yoga',
            hindi: 'केन्द्र-त्रिकोण राज योग',
            formed: true,
            strength: conjunct ? 'Very Strong' : 'Strong',
            description: 'Lord of house $k (${_name(lk)}) and lord of house $t (${_name(lt)}) are '
                '${conjunct ? 'conjunct' : 'in mutual aspect'} — power, status and success.',
            planets: [lk, lt],
          ));
        }
      }
    }

    // Viparita Raja Yoga: lords of 6, 8, 12 placed in 6, 8 or 12.
    const names = {6: 'Harsha', 8: 'Sarala', 12: 'Vimala'};
    for (final h in [6, 8, 12]) {
      final l = lord(lagnaRashi, h);
      if (!rashis.containsKey(l)) continue;
      final placed = _house(rashis, l, lagnaRashi);
      if (isDusthana(placed)) {
        yogas.add(YogaResult(
          category: 'Viparita Raja Yoga',
          name: '${names[h]} Yoga',
          hindi: 'विपरीत राज योग',
          formed: true,
          strength: 'Moderate',
          description: 'Lord of house $h (${_name(l)}) in house $placed — success that arises out of adversity.',
          planets: [l],
        ));
      }
    }

    // Neecha Bhanga Raja Yoga (basic rules).
    for (final p in _seven) {
      if (!rashis.containsKey(p)) continue;
      final r = rashis[p]!;
      if (!isDebilitated(p, r)) continue;
      final reasons = <String>[];
      final dispositor = VedicMath.rashis[r].lord;
      final exaltLordSign = VedicMath.planets[p]!.exalt;
      final exaltLord = VedicMath.rashis[exaltLordSign].lord;
      for (final c in {dispositor, exaltLord}) {
        if (!rashis.containsKey(c)) continue;
        if (isKendra(_house(rashis, c, lagnaRashi))) reasons.add('${_name(c)} in a kendra from Lagna');
        if (rashis.containsKey('moon') && isKendra(VedicMath.houseOf(rashis[c]!, rashis['moon']!))) {
          reasons.add('${_name(c)} in a kendra from Moon');
        }
      }
      if (reasons.isNotEmpty) {
        yogas.add(YogaResult(
          category: 'Raja Yoga',
          name: 'Neecha Bhanga Raja Yoga',
          hindi: 'नीचभंग राज योग',
          formed: true,
          strength: 'Moderate',
          description: 'Debilitation of ${_name(p)} is cancelled (${reasons.toSet().join('; ')}) — early struggle turning into success.',
          planets: [p],
        ));
      }
    }
    return yogas;
  }

  static List<YogaResult> _dhanaYogas(Map<String, int> rashis, int lagnaRashi) {
    final yogas = <YogaResult>[];
    final wealth = {2, 11};
    final fortune = {1, 5, 9};
    final seen = <String>{};
    for (final a in wealth) {
      for (final b in {...wealth, ...fortune}) {
        if (a == b) continue;
        final la = lord(lagnaRashi, a), lb = lord(lagnaRashi, b);
        if (la == lb || !rashis.containsKey(la) || !rashis.containsKey(lb)) continue;
        if (rashis[la] != rashis[lb]) continue;
        final key = ([la, lb]..sort()).join('-');
        if (!seen.add(key)) continue;
        yogas.add(YogaResult(
          category: 'Dhana Yoga',
          name: 'Dhana Yoga',
          hindi: 'धन योग',
          formed: true,
          strength: 'Strong',
          description: 'Lords of houses $a and $b (${_name(la)} & ${_name(lb)}) conjunct — accumulation of wealth.',
          planets: [la, lb],
        ));
      }
    }

    // Lakshmi Yoga (simplified): 9th lord in own/exalted sign in a kendra or trikona, Lagna lord strong.
    final l9 = lord(lagnaRashi, 9), l1 = lord(lagnaRashi, 1);
    if (rashis.containsKey(l9) && rashis.containsKey(l1)) {
      final r9 = rashis[l9]!;
      final h9 = VedicMath.houseOf(r9, lagnaRashi);
      final l1Strong = isOwn(l1, rashis[l1]!) || isExalted(l1, rashis[l1]!) ||
          isKendra(VedicMath.houseOf(rashis[l1]!, lagnaRashi));
      if ((isOwn(l9, r9) || isExalted(l9, r9)) && (isKendra(h9) || isTrikona(h9)) && l1Strong) {
        yogas.add(YogaResult(
          category: 'Dhana Yoga',
          name: 'Lakshmi Yoga',
          hindi: 'लक्ष्मी योग',
          formed: true,
          strength: 'Strong',
          description: 'Strong 9th lord (${_name(l9)}) in a kendra/trikona with a strong Lagna lord — wealth, grace and fortune.',
          planets: [l9, l1],
        ));
      }
    }
    return yogas;
  }

  static List<YogaResult> _lunarYogas(Map<String, int> rashis, int lagnaRashi) {
    final yogas = <YogaResult>[];
    if (!rashis.containsKey('moon')) return yogas;
    final m = rashis['moon']!;
    const five = ['mars', 'mercury', 'jupiter', 'venus', 'saturn'];
    final in2 = [for (final p in five) if (rashis[p] == (m + 1) % 12) p];
    final in12 = [for (final p in five) if (rashis[p] == (m + 11) % 12) p];

    if (in2.isNotEmpty && in12.isNotEmpty) {
      yogas.add(YogaResult(category: 'Lunar Yoga', name: 'Durudhara Yoga', hindi: 'दुरुधरा योग', formed: true,
          description: 'Planets on both sides of the Moon — comforts, wealth and loyal support.', planets: [...in2, ...in12]));
    } else if (in2.isNotEmpty) {
      yogas.add(YogaResult(category: 'Lunar Yoga', name: 'Sunapha Yoga', hindi: 'सुनफा योग', formed: true,
          description: 'Planets in the 2nd from the Moon — self-earned wealth and intelligence.', planets: in2));
    } else if (in12.isNotEmpty) {
      yogas.add(YogaResult(category: 'Lunar Yoga', name: 'Anapha Yoga', hindi: 'अनफा योग', formed: true,
          description: 'Planets in the 12th from the Moon — good health, manners and enjoyment.', planets: in12));
    } else {
      // Kemadruma is cancelled by a planet with the Moon or in a kendra from Lagna/Moon.
      final cancel = five.any((p) =>
          rashis.containsKey(p) &&
          (rashis[p] == m ||
              isKendra(VedicMath.houseOf(rashis[p]!, m)) ||
              isKendra(VedicMath.houseOf(rashis[p]!, lagnaRashi))));
      yogas.add(YogaResult(
        category: 'Lunar Yoga',
        name: 'Kemadruma Yoga',
        hindi: 'केमद्रुम योग',
        formed: true,
        strength: cancel ? 'Cancelled' : 'Negative',
        description: 'No planets on either side of the Moon — struggles and restlessness'
            '${cancel ? ' (cancelled by planets in kendras / with the Moon)' : ''}.',
        planets: ['moon'],
      ));
    }

    // Chandra-Mangala: Moon and Mars together.
    if (rashis.containsKey('mars') && rashis['mars'] == m) {
      yogas.add(YogaResult(category: 'Lunar Yoga', name: 'Chandra-Mangala Yoga', hindi: 'चन्द्र-मंगल योग', formed: true,
          description: 'Moon with Mars — enterprise and earning power, sometimes through bold means.', planets: ['moon', 'mars']));
    }

    // Adhi Yoga: natural benefics in the 6th, 7th and/or 8th from the Moon.
    final adhi = [
      for (final p in _naturalBenefics)
        if (rashis.containsKey(p) && [6, 7, 8].contains(VedicMath.houseOf(rashis[p]!, m))) p
    ];
    if (adhi.length >= 2) {
      yogas.add(YogaResult(category: 'Lunar Yoga', name: 'Adhi Yoga', hindi: 'अधि योग', formed: true,
          strength: adhi.length == 3 ? 'Strong' : 'Moderate',
          description: 'Benefics in the 6th/7th/8th from the Moon — leadership, comfort and victory over rivals.', planets: adhi));
    }
    return yogas;
  }

  static List<YogaResult> _solarYogas(Map<String, int> rashis) {
    final yogas = <YogaResult>[];
    if (!rashis.containsKey('sun')) return yogas;
    final s = rashis['sun']!;
    const five = ['mars', 'mercury', 'jupiter', 'venus', 'saturn'];
    final in2 = [for (final p in five) if (rashis[p] == (s + 1) % 12) p];
    final in12 = [for (final p in five) if (rashis[p] == (s + 11) % 12) p];
    if (in2.isNotEmpty && in12.isNotEmpty) {
      yogas.add(YogaResult(category: 'Solar Yoga', name: 'Ubhayachari Yoga', hindi: 'उभयचरी योग', formed: true,
          description: 'Planets on both sides of the Sun — eloquence, balance and status.', planets: [...in2, ...in12]));
    } else if (in2.isNotEmpty) {
      yogas.add(YogaResult(category: 'Solar Yoga', name: 'Vesi Yoga', hindi: 'वेशि योग', formed: true,
          description: 'Planets in the 2nd from the Sun — truthful, balanced and prosperous.', planets: in2));
    } else if (in12.isNotEmpty) {
      yogas.add(YogaResult(category: 'Solar Yoga', name: 'Vasi Yoga', hindi: 'वासि योग', formed: true,
          description: 'Planets in the 12th from the Sun — charitable, skilful and happy.', planets: in12));
    }
    return yogas;
  }

  static List<YogaResult> _otherYogas(Map<String, int> rashis, int lagnaRashi) {
    final yogas = <YogaResult>[];

    // Amala Yoga: a natural benefic in the 10th from Lagna or Moon.
    for (final p in _naturalBenefics) {
      if (!rashis.containsKey(p)) continue;
      final fromL = _house(rashis, p, lagnaRashi) == 10;
      final fromM = rashis.containsKey('moon') && VedicMath.houseOf(rashis[p]!, rashis['moon']!) == 10;
      if (fromL || fromM) {
        yogas.add(YogaResult(category: 'Other Yoga', name: 'Amala Yoga', hindi: 'अमल योग', formed: true,
            description: '${_name(p)} in the 10th from ${fromL ? 'Lagna' : 'Moon'} — spotless reputation and ethical conduct.',
            planets: [p]));
        break;
      }
    }

    // Parivartana (sign exchange) between two planets.
    final seen = <String>{};
    for (final a in _seven) {
      for (final b in _seven) {
        if (a == b || !rashis.containsKey(a) || !rashis.containsKey(b)) continue;
        if (VedicMath.rashis[rashis[a]!].lord == b && VedicMath.rashis[rashis[b]!].lord == a) {
          final key = ([a, b]..sort()).join('-');
          if (!seen.add(key)) continue;
          final ha = _house(rashis, a, lagnaRashi), hb = _house(rashis, b, lagnaRashi);
          final dusthana = isDusthana(ha) || isDusthana(hb);
          yogas.add(YogaResult(
            category: 'Parivartana Yoga',
            name: dusthana ? 'Dainya Parivartana' : 'Parivartana Yoga',
            hindi: 'परिवर्तन योग',
            formed: true,
            strength: dusthana ? 'Mixed' : 'Strong',
            description: '${_name(a)} (house $ha) and ${_name(b)} (house $hb) exchange signs — the two houses support each other.',
            planets: [a, b],
          ));
        }
      }
    }

    // Guru-Mangala: Jupiter with Mars, or in mutual 7th.
    if (rashis.containsKey('jupiter') && rashis.containsKey('mars')) {
      final h = VedicMath.houseOf(rashis['mars']!, rashis['jupiter']!);
      if (h == 1 || h == 7) {
        yogas.add(YogaResult(category: 'Other Yoga', name: 'Guru-Mangala Yoga', hindi: 'गुरु-मंगल योग', formed: true,
            description: 'Jupiter and Mars ${h == 1 ? 'together' : 'in mutual aspect'} — righteous energy and success in endeavours.',
            planets: ['jupiter', 'mars']));
      }
    }
    return yogas;
  }
}
