import 'ephemeris.dart';
import 'vedic_math.dart';
import 'doshas_math.dart';

/// Notes about doshas found while matching (Nadi, Bhakoot, Manglik ...).
class MilanDosha {
  final String name;
  final bool present;
  final bool cancelled;
  final String detail;
  const MilanDosha(this.name, {required this.present, this.cancelled = false, this.detail = ''});
}

class MilanResult {
  final double varna; // Max 1
  final double vashya; // Max 2
  final double tara; // Max 3
  final double yoni; // Max 4
  final double maitri; // Max 5
  final double gana; // Max 6
  final double bhakoot; // Max 7
  final double nadi; // Max 8
  final double total; // Max 36

  /// Descriptive attributes for display, e.g. {'boyYoni': 'Horse', ...}.
  final Map<String, String> details;
  final List<MilanDosha> doshas;

  MilanResult({
    required this.varna,
    required this.vashya,
    required this.tara,
    required this.yoni,
    required this.maitri,
    required this.gana,
    required this.bhakoot,
    required this.nadi,
    this.details = const {},
    this.doshas = const [],
  }) : total = varna + vashya + tara + yoni + maitri + gana + bhakoot + nadi;

  /// Common verdict bands used by most panchangs.
  String get verdict {
    if (total < 18) return 'Not recommended';
    if (total < 25) return 'Average match';
    if (total < 33) return 'Good match';
    return 'Excellent match';
  }
}

/// Ashtakoot (36-guna) matching from the Moon positions of the boy and the girl.
///
/// Tables follow the common North-Indian convention (as used by most published panchangs).
/// Points are never silently "restored" for dosha cancellations; cancellations are reported
/// in [MilanResult.doshas] so the user can see both the raw score and the exceptions.
class MilanMath {
  // ---------------------------------------------------------------- Varna
  static const List<String> varnaNames = ['Shudra', 'Vaishya', 'Kshatriya', 'Brahmin'];

  /// 3 = Brahmin (water signs), 2 = Kshatriya (fire), 1 = Vaishya (earth), 0 = Shudra (air).
  static int varnaOf(int rashi) {
    if ([3, 7, 11].contains(rashi)) return 3;
    if ([0, 4, 8].contains(rashi)) return 2;
    if ([1, 5, 9].contains(rashi)) return 1;
    return 0;
  }

  static double varnaPoints(int boyRashi, int girlRashi) =>
      varnaOf(boyRashi) >= varnaOf(girlRashi) ? 1.0 : 0.0;

  // ---------------------------------------------------------------- Vashya
  static const List<String> vashyaNames = ['Chatushpada', 'Manava', 'Jalachara', 'Vanachara', 'Keeta'];

  /// Vashya group from sidereal Moon longitude. Sagittarius and Capricorn are split at 15°.
  static int vashyaOf(double moonSid) {
    final r = VedicMath.rashiIndex(moonSid);
    final d = VedicMath.degInRashi(moonSid);
    switch (r) {
      case 0: // Aries
      case 1: // Taurus
        return 0;
      case 2: // Gemini
      case 5: // Virgo
      case 6: // Libra
      case 10: // Aquarius
        return 1;
      case 3: // Cancer
      case 11: // Pisces
        return 2;
      case 4: // Leo
        return 3;
      case 7: // Scorpio
        return 4;
      case 8: // Sagittarius: first half human, second half quadruped
        return d < 15 ? 1 : 0;
      case 9: // Capricorn: first half quadruped, second half aquatic
        return d < 15 ? 0 : 2;
    }
    return 1;
  }

  /// Rows: boy's vashya, columns: girl's vashya.
  static const List<List<double>> vashyaTable = [
    //  Cha  Man  Jal  Van  Kee
    [2.0, 1.0, 1.0, 0.5, 1.0], // Chatushpada
    [1.0, 2.0, 0.5, 0.0, 1.0], // Manava
    [1.0, 0.5, 2.0, 1.0, 1.0], // Jalachara
    [0.0, 0.0, 1.0, 2.0, 0.0], // Vanachara
    [1.0, 1.0, 1.0, 0.0, 2.0], // Keeta
  ];

  // ---------------------------------------------------------------- Tara
  static const List<String> taraNames = [
    'Janma', 'Sampat', 'Vipat', 'Kshema', 'Pratyari', 'Sadhaka', 'Vadha', 'Mitra', 'Ati-Mitra'
  ];

  /// Tara (1..9) counted from [fromNak] to [toNak].
  static int taraOf(int fromNak, int toNak) {
    final count = (toNak - fromNak + 27) % 27 + 1;
    final t = count % 9;
    return t == 0 ? 9 : t;
  }

  static double taraPoints(int boyNak, int girlNak) {
    // Vipat (3), Pratyari (5) and Vadha (7) are inauspicious.
    bool good(int t) => ![3, 5, 7].contains(t);
    final a = good(taraOf(girlNak, boyNak));
    final b = good(taraOf(boyNak, girlNak));
    return (a ? 1.5 : 0) + (b ? 1.5 : 0);
  }

  // ---------------------------------------------------------------- Yoni
  static const List<String> yoniAnimals = [
    'Horse', 'Elephant', 'Sheep', 'Serpent', 'Dog', 'Cat', 'Rat',
    'Cow', 'Buffalo', 'Tiger', 'Deer', 'Monkey', 'Mongoose', 'Lion',
  ];

  /// Yoni animal index for each of the 27 nakshatras.
  static const List<int> yoniOfNakshatra = [
    0, // Ashwini - Horse
    1, // Bharani - Elephant
    2, // Krittika - Sheep
    3, // Rohini - Serpent
    3, // Mrigashira - Serpent
    4, // Ardra - Dog
    5, // Punarvasu - Cat
    2, // Pushya - Sheep
    5, // Ashlesha - Cat
    6, // Magha - Rat
    6, // Purva Phalguni - Rat
    7, // Uttara Phalguni - Cow
    8, // Hasta - Buffalo
    9, // Chitra - Tiger
    8, // Swati - Buffalo
    9, // Vishakha - Tiger
    10, // Anuradha - Deer
    10, // Jyeshtha - Deer
    4, // Mula - Dog
    11, // Purva Ashadha - Monkey
    12, // Uttara Ashadha - Mongoose
    11, // Shravana - Monkey
    13, // Dhanishtha - Lion
    0, // Shatabhisha - Horse
    13, // Purva Bhadrapada - Lion
    7, // Uttara Bhadrapada - Cow
    1, // Revati - Elephant
  ];

  /// Standard 14x14 Yoni compatibility table (symmetric).
  static const List<List<double>> yoniTable = [
    // Ho El Sh Se Do Ca Ra Co Bu Ti De Mo Mg Li
    [4, 2, 2, 3, 2, 2, 2, 1, 0, 1, 3, 3, 2, 1], // Horse
    [2, 4, 3, 3, 2, 2, 2, 2, 3, 1, 2, 3, 2, 0], // Elephant
    [2, 3, 4, 2, 1, 2, 1, 3, 3, 1, 2, 0, 3, 1], // Sheep
    [3, 3, 2, 4, 2, 1, 1, 1, 1, 2, 2, 2, 0, 2], // Serpent
    [2, 2, 1, 2, 4, 2, 1, 2, 2, 1, 0, 2, 1, 1], // Dog
    [2, 2, 2, 1, 2, 4, 0, 2, 2, 1, 3, 3, 2, 1], // Cat
    [2, 2, 1, 1, 1, 0, 4, 2, 2, 2, 2, 2, 1, 2], // Rat
    [1, 2, 3, 1, 2, 2, 2, 4, 3, 0, 3, 2, 2, 1], // Cow
    [0, 3, 3, 1, 2, 2, 2, 3, 4, 1, 2, 2, 2, 1], // Buffalo
    [1, 1, 1, 2, 1, 1, 2, 0, 1, 4, 1, 1, 2, 1], // Tiger
    [3, 2, 2, 2, 0, 3, 2, 3, 2, 1, 4, 2, 2, 1], // Deer
    [3, 3, 0, 2, 2, 3, 2, 2, 2, 1, 2, 4, 3, 2], // Monkey
    [2, 2, 3, 0, 1, 2, 1, 2, 2, 2, 2, 3, 4, 2], // Mongoose
    [1, 0, 1, 2, 1, 1, 2, 1, 1, 1, 1, 2, 2, 4], // Lion
  ];

  // ---------------------------------------------------------------- Graha Maitri
  static const Map<String, List<String>> _friends = {
    'sun': ['moon', 'mars', 'jupiter'],
    'moon': ['sun', 'mercury'],
    'mars': ['sun', 'moon', 'jupiter'],
    'mercury': ['sun', 'venus'],
    'jupiter': ['sun', 'moon', 'mars'],
    'venus': ['mercury', 'saturn'],
    'saturn': ['mercury', 'venus'],
  };
  static const Map<String, List<String>> _enemies = {
    'sun': ['venus', 'saturn'],
    'moon': [],
    'mars': ['mercury'],
    'mercury': ['moon'],
    'jupiter': ['mercury', 'venus'],
    'venus': ['sun', 'moon'],
    'saturn': ['sun', 'moon', 'mars'],
  };

  /// 2 = friend, 1 = neutral, 0 = enemy (natural relationship of [a] towards [b]).
  static int relation(String a, String b) {
    if (a == b) return 2;
    if (_friends[a]!.contains(b)) return 2;
    if (_enemies[a]!.contains(b)) return 0;
    return 1;
  }

  static double maitriPoints(int boyRashi, int girlRashi) {
    final bl = VedicMath.rashis[boyRashi].lord;
    final gl = VedicMath.rashis[girlRashi].lord;
    if (bl == gl) return 5;
    final a = relation(bl, gl);
    final b = relation(gl, bl);
    final pair = [a, b]..sort();
    // [enemy/neutral/friend] combinations
    if (pair[0] == 2 && pair[1] == 2) return 5; // friend-friend
    if (pair[0] == 1 && pair[1] == 2) return 4; // neutral-friend
    if (pair[0] == 1 && pair[1] == 1) return 3; // neutral-neutral
    if (pair[0] == 0 && pair[1] == 2) return 1; // enemy-friend
    if (pair[0] == 0 && pair[1] == 1) return 0.5; // enemy-neutral
    return 0; // enemy-enemy
  }

  // ---------------------------------------------------------------- Gana
  static const List<String> ganaNames = ['Deva', 'Manushya', 'Rakshasa'];

  static int ganaOf(int nak) {
    switch (VedicMath.nakshatras[nak].gana) {
      case 'Deva':
        return 0;
      case 'Manava':
        return 1;
      default:
        return 2;
    }
  }

  /// Rows: boy's gana, columns: girl's gana.
  static const List<List<double>> ganaTable = [
    // Deva Manu Raks
    [6, 6, 1], // Deva
    [5, 6, 0], // Manushya
    [1, 0, 6], // Rakshasa
  ];

  // ---------------------------------------------------------------- Bhakoot
  static double bhakootPoints(int boyRashi, int girlRashi) {
    final d = (girlRashi - boyRashi + 12) % 12 + 1; // position of girl's sign from boy's
    // Inauspicious pairs: 2/12, 5/9, 6/8
    if ([2, 12, 5, 9, 6, 8].contains(d)) return 0;
    return 7;
  }

  // ---------------------------------------------------------------- Nadi
  static const List<String> nadiNames = ['Adi (Vata)', 'Madhya (Pitta)', 'Antya (Kapha)'];

  static int nadiOf(int nak) {
    switch (VedicMath.nakshatras[nak].nadi) {
      case 'Vata':
        return 0;
      case 'Pitta':
        return 1;
      default:
        return 2;
    }
  }

  // ---------------------------------------------------------------- Matching

  /// Ashtakoot matching using only the two Moon longitudes (sidereal).
  static MilanResult calculateMilan(double boyMoonSid, double girlMoonSid) {
    final bR = VedicMath.rashiIndex(boyMoonSid);
    final gR = VedicMath.rashiIndex(girlMoonSid);
    final bN = VedicMath.nakshatraIndex(boyMoonSid);
    final gN = VedicMath.nakshatraIndex(girlMoonSid);
    final bP = VedicMath.pada(boyMoonSid);
    final gP = VedicMath.pada(girlMoonSid);

    final bV = vashyaOf(boyMoonSid), gV = vashyaOf(girlMoonSid);
    final bY = yoniOfNakshatra[bN], gY = yoniOfNakshatra[gN];
    final bG = ganaOf(bN), gG = ganaOf(gN);
    final bNadi = nadiOf(bN), gNadi = nadiOf(gN);

    final bhakoot = bhakootPoints(bR, gR);
    final nadi = bNadi == gNadi ? 0.0 : 8.0;

    final doshas = <MilanDosha>[];

    // Nadi dosha and its classical exceptions.
    if (nadi == 0) {
      String? why;
      if (bR == gR && bN != gN) {
        why = 'Same Moon sign but different nakshatras';
      } else if (bN == gN && bR != gR) {
        why = 'Same nakshatra but different Moon signs';
      } else if (bN == gN && bP != gP) {
        why = 'Same nakshatra but different padas';
      } else if (bR != gR && VedicMath.rashis[bR].lord == VedicMath.rashis[gR].lord) {
        why = 'Different Moon signs ruled by the same planet';
      }
      doshas.add(MilanDosha('Nadi Dosha',
          present: true,
          cancelled: why != null,
          detail: why ?? 'Both belong to ${nadiNames[bNadi]} nadi'));
    }

    // Bhakoot dosha and its exceptions.
    if (bhakoot == 0) {
      final bl = VedicMath.rashis[bR].lord, gl = VedicMath.rashis[gR].lord;
      String? why;
      if (bl == gl) {
        why = 'Moon-sign lords are the same planet';
      } else if (relation(bl, gl) == 2 && relation(gl, bl) == 2) {
        why = 'Moon-sign lords are mutual friends';
      } else if (nadi == 8 && taraPoints(bN, gN) == 3) {
        why = 'Nadi and Tara are both favourable';
      }
      final d = (gR - bR + 12) % 12 + 1;
      final pair = [d, 14 - d]..sort();
      doshas.add(MilanDosha('Bhakoot Dosha',
          present: true,
          cancelled: why != null,
          detail: why ?? 'Moon signs are in ${pair[0]}/${pair[1]} relation'));
    }

    return MilanResult(
      varna: varnaPoints(bR, gR),
      vashya: vashyaTable[bV][gV],
      tara: taraPoints(bN, gN),
      yoni: yoniTable[bY][gY],
      maitri: maitriPoints(bR, gR),
      gana: ganaTable[bG][gG],
      bhakoot: bhakoot,
      nadi: nadi,
      details: {
        'boyRashi': VedicMath.rashis[bR].name,
        'girlRashi': VedicMath.rashis[gR].name,
        'boyNakshatra': '${VedicMath.nakshatras[bN].name} ($bP)',
        'girlNakshatra': '${VedicMath.nakshatras[gN].name} ($gP)',
        'boyVarna': varnaNames[varnaOf(bR)],
        'girlVarna': varnaNames[varnaOf(gR)],
        'boyVashya': vashyaNames[bV],
        'girlVashya': vashyaNames[gV],
        'boyYoni': yoniAnimals[bY],
        'girlYoni': yoniAnimals[gY],
        'boyGana': ganaNames[bG],
        'girlGana': ganaNames[gG],
        'boyNadi': nadiNames[bNadi],
        'girlNadi': nadiNames[gNadi],
        'boyLord': VedicMath.planets[VedicMath.rashis[bR].lord]!.name,
        'girlLord': VedicMath.planets[VedicMath.rashis[gR].lord]!.name,
      },
      doshas: doshas,
    );
  }

  /// Full matching from two charts, adding the Manglik comparison.
  static MilanResult calculateFromCharts(ChartData boy, ChartData girl) {
    final base = calculateMilan(boy.planetLongitudes['moon']!, girl.planetLongitudes['moon']!);
    final bm = DoshasMath.computeManglik(boy.planetLongitudes, boy.lagnaRashi);
    final gm = DoshasMath.computeManglik(girl.planetLongitudes, girl.lagnaRashi);
    final boyManglik = bm != null && bm.present && !bm.cancelled;
    final girlManglik = gm != null && gm.present && !gm.cancelled;

    final doshas = [...base.doshas];
    if (boyManglik || girlManglik) {
      final both = boyManglik && girlManglik;
      doshas.add(MilanDosha('Manglik Dosha',
          present: true,
          cancelled: both,
          detail: both
              ? 'Both are Manglik, so the dosha is considered neutralised'
              : '${boyManglik ? 'Boy' : 'Girl'} is Manglik, the other is not'));
    }

    return MilanResult(
      varna: base.varna,
      vashya: base.vashya,
      tara: base.tara,
      yoni: base.yoni,
      maitri: base.maitri,
      gana: base.gana,
      bhakoot: base.bhakoot,
      nadi: base.nadi,
      details: {
        ...base.details,
        'boyManglik': boyManglik ? 'Yes' : 'No',
        'girlManglik': girlManglik ? 'Yes' : 'No',
      },
      doshas: doshas,
    );
  }
}
