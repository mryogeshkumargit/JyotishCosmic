import 'vedic_math.dart';
import 'planetary_aspects.dart';

class DoshaResult {
  final String name;
  final String hindi;

  /// The defining condition of the dosha is met.
  final bool present;

  /// The dosha is present but neutralised by a classical exception.
  final bool cancelled;
  final String severity;
  final List<String> exceptions;
  final List<String> conditions;
  final String description;
  final List<String> remedies;

  DoshaResult({
    required this.name,
    required this.hindi,
    required this.present,
    this.cancelled = false,
    this.severity = '',
    this.exceptions = const [],
    this.conditions = const [],
    required this.description,
    required this.remedies,
  });

  /// Present and not cancelled.
  bool get isActive => present && !cancelled;
}

/// Dosha checks on a sidereal chart. [lagnaRashi] is always 0-based (0 = Aries).
class DoshasMath {
  static int _r(double sid) => VedicMath.rashiIndex(sid);

  static DoshaResult? computeManglik(Map<String, double> longs, int lagnaRashi) {
    if (!longs.containsKey('mars')) return null;
    final marsRashi = _r(longs['mars']!);
    const mangHouses = [1, 2, 4, 7, 8, 12];

    final fromLagna = VedicMath.houseOf(marsRashi, lagnaRashi);
    final fromMoon = longs.containsKey('moon') ? VedicMath.houseOf(marsRashi, _r(longs['moon']!)) : null;
    final fromVenus = longs.containsKey('venus') ? VedicMath.houseOf(marsRashi, _r(longs['venus']!)) : null;

    final conditions = <String>[];
    if (mangHouses.contains(fromLagna)) conditions.add('Mars in house $fromLagna from Lagna');
    if (fromMoon != null && mangHouses.contains(fromMoon)) conditions.add('Mars in house $fromMoon from Moon');
    if (fromVenus != null && mangHouses.contains(fromVenus)) conditions.add('Mars in house $fromVenus from Venus');

    final exceptions = <String>[];
    if (marsRashi == 0 || marsRashi == 7) exceptions.add('Mars in its own sign (${VedicMath.rashis[marsRashi].name})');
    if (marsRashi == 9) exceptions.add('Mars exalted in Capricorn');
    if (longs.containsKey('jupiter')) {
      final jupRashi = _r(longs['jupiter']!);
      if (jupRashi == marsRashi) exceptions.add('Jupiter conjunct Mars');
      final rashis = {for (final e in longs.entries) e.key: _r(e.value)};
      if (PlanetaryAspects.isAspecting('jupiter', 'mars', rashis, lagnaRashi) && jupRashi != marsRashi) {
        exceptions.add('Jupiter aspects Mars');
      }
    }
    // Mars in Leo/Aquarius in houses 1/7 or Mars in 2nd in Gemini/Virgo (common Parashari exceptions).
    if ((marsRashi == 4 || marsRashi == 10) && (fromLagna == 1 || fromLagna == 7)) {
      exceptions.add('Mars in Leo/Aquarius in the ${fromLagna == 1 ? '1st' : '7th'} house');
    }
    if (fromLagna == 2 && (marsRashi == 2 || marsRashi == 5)) {
      exceptions.add('Mars in the 2nd house in Gemini/Virgo');
    }

    final count = conditions.length;
    final present = count > 0;
    return DoshaResult(
      name: 'Manglik Dosha',
      hindi: 'मांगलिक दोष',
      present: present,
      cancelled: present && exceptions.isNotEmpty,
      severity: !present ? '' : (count == 3 ? 'High' : count == 2 ? 'Medium' : 'Low'),
      conditions: conditions,
      exceptions: exceptions,
      description: 'Mars in the 1st, 2nd, 4th, 7th, 8th or 12th house (from Lagna, Moon or Venus) — can affect marital harmony.',
      remedies: [
        'Worship Hanuman on Tuesdays',
        'Recite Mangal Stotra daily',
        'Kumbh Vivah before marriage (traditional)',
        'Donate red lentils on Tuesdays',
        'Consult an astrologer before wearing Red Coral',
      ],
    );
  }

  static const List<String> kaalSarpTypes = [
    'Anant', 'Kulik', 'Vasuki', 'Shankhapal', 'Padma', 'Mahapadma',
    'Takshak', 'Karkotak', 'Shankhachood', 'Ghatak', 'Vishdhar', 'Sheshnag',
  ];

  /// Kaal Sarp: all seven planets hemmed on one side of the Rahu–Ketu axis.
  /// The type is named after Rahu's house from the Lagna.
  static DoshaResult? computeKaalSarp(Map<String, double> longs, [int? lagnaRashi]) {
    if (!longs.containsKey('rahu')) return null;
    final rahu = longs['rahu']!;
    const planets7 = ['sun', 'moon', 'mars', 'mercury', 'jupiter', 'venus', 'saturn'];
    int ahead = 0, behind = 0;
    for (final p in planets7) {
      if (!longs.containsKey(p)) continue;
      // Measure each planet's distance from Rahu, going forward through the zodiac.
      if (VedicMath.norm360(longs[p]! - rahu) < 180) {
        ahead++;
      } else {
        behind++;
      }
    }
    final present = ahead == 0 || behind == 0;
    final conditions = <String>[];
    if (present) {
      // Planets from Ketu to Rahu (i.e. none between Rahu and Ketu) is often called Kaal Amrit.
      conditions.add(ahead == 0 ? 'All planets from Ketu to Rahu (Kaal Amrit direction)' : 'All planets from Rahu to Ketu');
      if (lagnaRashi != null) {
        final h = VedicMath.houseOf(_r(rahu), lagnaRashi);
        conditions.add('Type: ${kaalSarpTypes[h - 1]} (Rahu in house $h)');
      }
    }
    return DoshaResult(
      name: 'Kaal Sarp Dosha',
      hindi: 'काल सर्प दोष',
      present: present,
      conditions: conditions,
      description: 'All seven planets hemmed between Rahu and Ketu — recurring obstacles and delays.',
      remedies: [
        'Shiva worship on Mondays',
        'Kaal Sarp Shanti puja (e.g. at Trimbakeshwar)',
        'Maha Mrityunjaya Mantra 108×',
        'Donate food on Saturdays',
      ],
    );
  }

  /// Sade Sati (Saturn in the 12th, 1st or 2nd from the natal Moon) and Dhaiya (4th/8th).
  /// [saturnRashi] must be the *current* (transit) sign of Saturn.
  static DoshaResult computeSadesati(int moonRashi, int saturnRashi) {
    final h = VedicMath.houseOf(saturnRashi, moonRashi);
    String? phase;
    if (h == 12) phase = 'Rising (1st phase) — Saturn in the 12th from Moon';
    if (h == 1) phase = 'Peak (2nd phase) — Saturn over the Moon sign';
    if (h == 2) phase = 'Setting (3rd phase) — Saturn in the 2nd from Moon';
    final dhaiya = h == 4 || h == 8;
    return DoshaResult(
      name: 'Shani Sade Sati',
      hindi: 'शनि साढ़े साती',
      present: phase != null,
      conditions: [
        if (phase != null) phase,
        if (dhaiya) 'Shani Dhaiya (Kantaka Shani) — Saturn in the ${h}th from Moon',
      ],
      description: 'Saturn transiting the 12th, 1st and 2nd from the natal Moon sign — about 7½ years of tests and transformation.',
      remedies: [
        'Shani worship on Saturdays',
        'Chant "Om Sham Shanicharaya Namah" 108×',
        'Light a mustard-oil lamp under a peepal tree on Saturdays',
        'Donate black sesame and cloth on Saturdays',
      ],
    );
  }

  static DoshaResult computePitruDosha(Map<String, double> longs, int lagnaRashi) {
    final cond = <String>[];
    bool conj(String a, String b) =>
        longs.containsKey(a) && longs.containsKey(b) && _r(longs[a]!) == _r(longs[b]!);
    int? house(String p) => longs.containsKey(p) ? VedicMath.houseOf(_r(longs[p]!), lagnaRashi) : null;

    if (conj('sun', 'rahu')) cond.add('Sun conjunct Rahu');
    if (conj('sun', 'ketu')) cond.add('Sun conjunct Ketu');
    if (conj('sun', 'saturn')) cond.add('Sun conjunct Saturn');
    if (house('rahu') == 9) cond.add('Rahu in the 9th house');
    if (house('ketu') == 9) cond.add('Ketu in the 9th house');
    final ninthLord = VedicMath.rashis[(lagnaRashi + 8) % 12].lord;
    if (conj(ninthLord, 'rahu') && ninthLord != 'rahu') cond.add('9th lord conjunct Rahu');

    return DoshaResult(
      name: 'Pitru Dosha',
      hindi: 'पितृ दोष',
      present: cond.isNotEmpty,
      severity: cond.isEmpty ? '' : (cond.length >= 2 ? 'Medium' : 'Low'),
      conditions: cond,
      description: 'Affliction of the Sun or the 9th house by Rahu, Ketu or Saturn — ancestral karma affecting prosperity and lineage.',
      remedies: [
        'Pitru Tarpan on Amavasya',
        'Shraddh during Pitru Paksha',
        'Feed crows and cows on Amavasya',
        'Chant "Om Pitrubhyo Namah" 108×',
      ],
    );
  }

  /// Grahan dosha: Sun or Moon in the same sign as Rahu or Ketu (orb shown for context).
  static DoshaResult computeGrahanDosha(Map<String, double> longs) {
    final cond = <String>[];
    for (final lum in ['sun', 'moon']) {
      for (final node in ['rahu', 'ketu']) {
        if (!longs.containsKey(lum) || !longs.containsKey(node)) continue;
        if (_r(longs[lum]!) == _r(longs[node]!)) {
          final orb = VedicMath.angularDistance(longs[lum]!, longs[node]!);
          cond.add('${_cap(lum)} conjunct ${_cap(node)} (${orb.toStringAsFixed(1)}° apart)');
        }
      }
    }
    return DoshaResult(
      name: 'Grahan Dosha',
      hindi: 'ग्रहण दोष',
      present: cond.isNotEmpty,
      conditions: cond,
      description: 'Sun or Moon conjunct Rahu/Ketu — "eclipse" affliction affecting clarity and confidence.',
      remedies: ['Surya / Chandra mantra recitation', 'Charity on eclipse days', 'Grahan Shanti Homa'],
    );
  }

  static DoshaResult computeGuruChandalDosha(Map<String, double> longs) {
    final cond = <String>[];
    if (longs.containsKey('jupiter')) {
      for (final node in ['rahu', 'ketu']) {
        if (longs.containsKey(node) && _r(longs['jupiter']!) == _r(longs[node]!)) {
          cond.add('Jupiter conjunct ${_cap(node)}');
        }
      }
    }
    return DoshaResult(
      name: 'Guru Chandal Dosha',
      hindi: 'गुरु चांडाल दोष',
      present: cond.isNotEmpty,
      conditions: cond,
      description: 'Jupiter conjunct Rahu or Ketu — confusion in values and friction with teachers and elders.',
      remedies: ['Respect teachers and elders', 'Worship Lord Vishnu / Brihaspati', 'Donate yellow items on Thursdays'],
    );
  }

  /// Kemadruma: no planet (other than Sun, Rahu, Ketu) in the 2nd or 12th from the Moon.
  /// Cancelled when a planet is conjunct the Moon or occupies a kendra from the Lagna or Moon.
  static DoshaResult computeKemadrumaDosha(Map<String, double> longs, [int? lagnaRashi]) {
    if (!longs.containsKey('moon')) {
      return DoshaResult(name: 'Kemadruma Dosha', hindi: 'केमद्रुम दोष', present: false, description: '', remedies: []);
    }
    final moon = _r(longs['moon']!);
    const five = ['mars', 'mercury', 'jupiter', 'venus', 'saturn'];
    bool flanked = false;
    final exceptions = <String>[];
    for (final p in five) {
      if (!longs.containsKey(p)) continue;
      final h = VedicMath.houseOf(_r(longs[p]!), moon);
      if (h == 2 || h == 12) flanked = true;
      if (h == 1) exceptions.add('${_cap(p)} conjunct the Moon');
      if ([4, 7, 10].contains(h)) exceptions.add('${_cap(p)} in a kendra from the Moon');
      if (lagnaRashi != null && [1, 4, 7, 10].contains(VedicMath.houseOf(_r(longs[p]!), lagnaRashi))) {
        exceptions.add('${_cap(p)} in a kendra from the Lagna');
      }
    }
    final present = !flanked;
    return DoshaResult(
      name: 'Kemadruma Dosha',
      hindi: 'केमद्रुम दोष',
      present: present,
      cancelled: present && exceptions.isNotEmpty,
      exceptions: present ? exceptions.toSet().toList() : const [],
      description: 'No planets on either side of the Moon — loneliness, mental unrest and struggle.',
      remedies: ['Worship Lord Shiva', 'Offer milk on a Shivling on Mondays', 'Chant Chandra mantra on Mondays'],
    );
  }

  static String _cap(String s) => s[0].toUpperCase() + s.substring(1);
}
