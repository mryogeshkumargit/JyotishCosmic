import 'vedic_math.dart';
import 'planetary_dignity.dart';

class DoshaResult {
  final String name;
  final String hindi;
  final bool present;
  final String severity;
  final List<String> exceptions;
  final List<String> conditions;
  final String description;
  final List<String> remedies;

  DoshaResult({
    required this.name,
    required this.hindi,
    required this.present,
    this.severity = '',
    this.exceptions = const [],
    this.conditions = const [],
    required this.description,
    required this.remedies,
  });
}

class DoshasMath {
  static DoshaResult? computeManglik(Map<String, double> planetLongitudes, int lagnaRashi) {
    if (!planetLongitudes.containsKey('mars')) return null;
    int marsRashi = VedicMath.rashiIndex(planetLongitudes['mars']!);
    int? moonRashi = planetLongitudes.containsKey('moon') ? VedicMath.rashiIndex(planetLongitudes['moon']!) : null;
    int? venusRashi = planetLongitudes.containsKey('venus') ? VedicMath.rashiIndex(planetLongitudes['venus']!) : null;
    
    List<int> mangHouses = [1, 2, 4, 7, 8, 12];
    int fl = VedicMath.houseOf(marsRashi, lagnaRashi);
    int? fm = moonRashi != null ? VedicMath.houseOf(marsRashi, moonRashi) : null;
    int? fv = venusRashi != null ? VedicMath.houseOf(marsRashi, venusRashi) : null;
    
    bool dl = mangHouses.contains(fl);
    bool dm = fm != null && mangHouses.contains(fm);
    bool dv = fv != null && mangHouses.contains(fv);
    
    List<String> exceptions = [];
    
    // Check advanced dignity
    Map<String, int> planetRashis = {};
    planetLongitudes.forEach((p, sid) => planetRashis[p] = VedicMath.rashiIndex(sid));
    String dignity = PlanetaryDignity.getAdvancedDignity('mars', marsRashi, planetRashis);
    
    if (dignity == 'Exalted') exceptions.add('Mars is Exalted (cancelled/reduced)');
    if (dignity == 'Own Sign' || dignity == 'Moolatrikona') exceptions.add('Mars is in its own sign (cancelled/reduced)');
    
    if (planetLongitudes.containsKey('jupiter')) {
      int jupRashi = VedicMath.rashiIndex(planetLongitudes['jupiter']!);
      if (jupRashi == marsRashi) exceptions.add('Jupiter conjunct Mars');
      if (VedicMath.houseOf(jupRashi, lagnaRashi) == 1) exceptions.add('Jupiter in Lagna');
    }

    int severityCount = [dl, dm, dv].where((e) => e).length;
    String severity = severityCount == 3 ? 'High' : severityCount == 2 ? 'Medium' : severityCount == 1 ? 'Low' : '';
    
    return DoshaResult(
      name: 'Manglik Dosha',
      hindi: 'मांगलिक दोष',
      present: (dl || dm || dv) && exceptions.isEmpty,
      severity: severity,
      exceptions: exceptions,
      conditions: [
        if (dl) 'Mars in house $fl from Lagna',
        if (dm) 'Mars in house $fm from Moon',
        if (dv) 'Mars in house $fv from Venus',
      ],
      description: 'Mars in 1st, 2nd, 4th, 7th, 8th or 12th house (from Lagna, Moon or Venus) — can affect marital harmony.',
      remedies: ['Worship Hanuman on Tuesdays', 'Recite Mangal Stotra daily', 'Red Coral gemstone (consult astrologer)', 'Kumbh Vivah before marriage', 'Donate red lentils on Tuesdays'],
    );
  }

  static DoshaResult? computeKaalSarp(Map<String, double> longs, int lagnaRashi) {
    if (!longs.containsKey('rahu') || !longs.containsKey('ketu')) return null;
    double rd = longs['rahu']!;
    List<String> planets7 = ['sun', 'moon', 'mars', 'mercury', 'jupiter', 'venus', 'saturn'];
    List<String> between = [];
    List<String> outside = [];
    
    for (var p in planets7) {
      if (!longs.containsKey(p)) continue;
      double pd = longs[p]!;
      if (VedicMath.norm360(pd - rd) < 180) {
        between.add(p);
      } else {
        outside.add(p);
      }
    }
    
    List<String> types = ['Anant', 'Kulik', 'Vasuki', 'Shankhapal', 'Padma', 'Mahapadma', 'Takshak', 'Karkotak', 'Shankhachood', 'Ghatak', 'Vishdhar', 'Sheshnaag'];
    // The type is named after Rahu's house from the Lagna (Anant = 1st ... Sheshnaag = 12th).
    int rahuHouse = VedicMath.houseOf(VedicMath.rashiIndex(rd), lagnaRashi);
    
    return DoshaResult(
      name: 'Kaal Sarp Dosha',
      hindi: 'काल सर्प दोष',
      present: outside.isEmpty || between.isEmpty,
      conditions: ['Type: ${types[rahuHouse - 1]} (Rahu in house $rahuHouse)'],
      description: 'All 7 planets between Rahu & Ketu — challenges in progress, recurring obstacles.',
      remedies: ['Shiva worship on Mondays', 'Kaal Sarp Shanti puja at Trimbakeshwar', 'Maha Mrityunjaya Mantra 108×', 'Silver bangle on left wrist', 'Donate food on Saturdays'],
    );
  }

  static DoshaResult computeSadesati(int moonRashi, int saturnRashi) {
    int prev = (moonRashi - 1 + 12) % 12;
    int next = (moonRashi + 1) % 12;
    String? phase;
    if (saturnRashi == prev) {
      phase = 'Rising (1st Phase)';
    } else if (saturnRashi == moonRashi) {
      phase = 'Peak (2nd Phase)';
    } else if (saturnRashi == next) {
      phase = 'Setting (3rd Phase)';
    }
    
    return DoshaResult(
      name: 'Shani Sadesati',
      hindi: 'शनि साढ़े साती',
      present: phase != null,
      conditions: phase != null ? [phase] : [],
      description: 'Saturn transiting 12th, 1st, 2nd from Moon sign — 7.5 years of tests and transformation.',
      remedies: ['Shani worship Saturdays', 'Chant "Om Sham Shanicharaya Namah" 108×', 'Mustard oil lamp under peepal Saturdays', 'Donate black sesame & cloth Saturdays', 'Feed crows & birds'],
    );
  }

  static DoshaResult computePitruDosha(Map<String, double> longs, int lagnaRashi) {
    List<String> conditions = [];
    if (longs.containsKey('sun') && longs.containsKey('rahu')) {
      if (VedicMath.rashiIndex(longs['sun']!) == VedicMath.rashiIndex(longs['rahu']!)) conditions.add('Sun conjunct Rahu');
      if (VedicMath.houseOf(VedicMath.rashiIndex(longs['sun']!), lagnaRashi) == 9) conditions.add('Sun in 9th house');
    }
    if (longs.containsKey('sun') && longs.containsKey('saturn')) {
      if (VedicMath.rashiIndex(longs['sun']!) == VedicMath.rashiIndex(longs['saturn']!)) conditions.add('Sun conjunct Saturn');
    }
    if (longs.containsKey('moon') && longs.containsKey('rahu')) {
      if (VedicMath.rashiIndex(longs['moon']!) == VedicMath.rashiIndex(longs['rahu']!)) conditions.add('Moon conjunct Rahu');
      if (VedicMath.houseOf(VedicMath.rashiIndex(longs['moon']!), lagnaRashi) == 9) conditions.add('Moon in 9th house');
    }
    
    return DoshaResult(
      name: 'Pitru Dosha',
      hindi: 'पितृ दोष',
      present: conditions.length >= 2,
      conditions: conditions,
      description: 'Unfulfilled ancestral karma affecting family prosperity and lineage.',
      remedies: ['Pitru Tarpan on Amavasya', 'Shradh during Pitru Paksha', 'Feed crows/cows on Amavasya', 'Narayan Nagbali puja', 'Chant "Om Pitrubhyo Namah" 108×'],
    );
  }

  static double _separation(double a, double b) {
    final d = VedicMath.norm360(a - b);
    return d > 180 ? 360 - d : d;
  }

  static DoshaResult computeGrahanDosha(Map<String, double> longs) {
    List<String> cond = [];
    bool near(String a, String b) => longs.containsKey(a) && longs.containsKey(b) && _separation(longs[a]!, longs[b]!) < 10;
    if (near('sun', 'rahu')) cond.add('Sun within 10° of Rahu (Solar Eclipse energy)');
    if (near('moon', 'rahu')) cond.add('Moon within 10° of Rahu (Lunar Eclipse energy)');
    if (near('sun', 'ketu')) cond.add('Sun within 10° of Ketu');
    if (near('moon', 'ketu')) cond.add('Moon within 10° of Ketu');

    return DoshaResult(
      name: 'Grahan Dosha',
      hindi: 'ग्रहण दोष',
      present: cond.isNotEmpty,
      conditions: cond,
      description: 'Sun or Moon closely conjunct Rahu/Ketu — eclipse energy at birth affecting mental clarity.',
      remedies: ['Surya/Chandra Mantra recitation', 'Donate at temples on eclipse days', 'Grahan Shanti Homa'],
    );
  }

  static DoshaResult computeGuruChandalDosha(Map<String, double> longs) {
    bool present = false;
    List<String> cond = [];
    if (longs.containsKey('jupiter') && longs.containsKey('rahu')) {
      if (VedicMath.rashiIndex(longs['jupiter']!) == VedicMath.rashiIndex(longs['rahu']!)) {
        present = true;
        cond.add('Jupiter conjunct Rahu');
      }
    }
    if (longs.containsKey('jupiter') && longs.containsKey('ketu')) {
      if (VedicMath.rashiIndex(longs['jupiter']!) == VedicMath.rashiIndex(longs['ketu']!)) {
        present = true;
        cond.add('Jupiter conjunct Ketu');
      }
    }

    return DoshaResult(
      name: 'Guru Chandal Dosha',
      hindi: 'गुरु चांडाल दोष',
      present: present,
      conditions: cond,
      description: 'Jupiter conjunct Rahu/Ketu. Creates confusion in values, morals, and clashes with teachers/elders.',
      remedies: ['Respect teachers and elders', 'Worship Lord Vishnu / Brihaspati', 'Donate yellow items on Thursdays'],
    );
  }

  /// Kemadruma: no planet (other than Sun, Rahu, Ketu) in the 2nd or 12th from the Moon.
  /// Cancelled when a planet is conjunct the Moon or in a kendra from the Moon.
  static DoshaResult computeKemadrumaDosha(Map<String, double> longs) {
    if (!longs.containsKey('moon')) {
      return DoshaResult(name: 'Kemadruma Dosha', hindi: 'केमद्रुम दोष', present: false, description: '', remedies: []);
    }

    final int moonRashi = VedicMath.rashiIndex(longs['moon']!);
    const List<String> truePlanets = ['mars', 'mercury', 'jupiter', 'venus', 'saturn'];

    bool adjacent = false;
    final List<String> cancellations = [];
    for (final p in truePlanets) {
      if (!longs.containsKey(p)) continue;
      final int h = VedicMath.houseOf(VedicMath.rashiIndex(longs[p]!), moonRashi);
      if (h == 2 || h == 12) adjacent = true;
      if (h == 1) cancellations.add('${VedicMath.planets[p]!.name} conjunct Moon');
      if (h == 4 || h == 7 || h == 10) cancellations.add('${VedicMath.planets[p]!.name} in kendra from Moon');
    }

    final bool formed = !adjacent;
    return DoshaResult(
      name: 'Kemadruma Dosha',
      hindi: 'केमद्रुम दोष',
      present: formed && cancellations.isEmpty,
      exceptions: formed ? cancellations : const [],
      description: 'Moon without planets on either side. Brings loneliness, mental unrest, and struggles.',
      remedies: ['Worship Lord Shiva daily', 'Offer milk on Shivling', 'Keep a silver piece or square with you'],
    );
  }
}
