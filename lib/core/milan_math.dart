import 'vedic_math.dart';

class MilanResult {
  final double varna;    // Max 1
  final double vashya;   // Max 2
  final double tara;     // Max 3
  final double yoni;     // Max 4
  final double maitri;   // Max 5
  final double gana;     // Max 6
  final double bhakoot;  // Max 7
  final double nadi;     // Max 8
  final double total;    // Max 36

  MilanResult({
    required this.varna, required this.vashya, required this.tara, required this.yoni,
    required this.maitri, required this.gana, required this.bhakoot, required this.nadi,
  }) : total = varna + vashya + tara + yoni + maitri + gana + bhakoot + nadi;

  bool get hasNadiDosha => nadi == 0;
  bool get hasBhakootDosha => bhakoot == 0;
}

/// Ashtakoot Guna Milan (36 points), table driven.
class MilanMath {
  /// Evaluates the 36-point Ashtakoot Guna Milan between a boy and a girl
  /// from their sidereal Moon longitudes.
  static MilanResult calculateMilan(double boyMoonSid, double girlMoonSid) {
    final int boyRashi = VedicMath.rashiIndex(boyMoonSid);
    final int girlRashi = VedicMath.rashiIndex(girlMoonSid);
    final int boyNak = VedicMath.nakshatraIndex(boyMoonSid);
    final int girlNak = VedicMath.nakshatraIndex(girlMoonSid);

    return MilanResult(
      varna: varnaScore(boyRashi, girlRashi),
      vashya: vashyaScore(vashyaGroup(boyMoonSid), vashyaGroup(girlMoonSid)),
      tara: taraScore(boyNak, girlNak),
      yoni: yoniScore(boyNak, girlNak),
      maitri: maitriScore(boyRashi, girlRashi),
      gana: ganaScore(boyNak, girlNak),
      bhakoot: bhakootScore(boyRashi, girlRashi),
      nadi: nadiScore(boyNak, girlNak),
    );
  }

  // 1. Varna (max 1): Brahmin 3 (water), Kshatriya 2 (fire), Vaishya 1 (earth), Shudra 0 (air).
  static int varnaOf(int rashi) => const [2, 1, 0, 3, 2, 1, 0, 3, 2, 1, 0, 3][rashi];

  static double varnaScore(int bRashi, int gRashi) => varnaOf(bRashi) >= varnaOf(gRashi) ? 1.0 : 0.0;

  // 2. Vashya (max 2). Groups: 0 Chatushpada, 1 Manava (Dwipada), 2 Jalachara, 3 Vanachara, 4 Keeta.
  // Sagittarius: first half Manava, second half Chatushpada.
  // Capricorn: first half Chatushpada, second half Jalachara.
  static int vashyaGroup(double moonSid) {
    final int r = VedicMath.rashiIndex(moonSid);
    final double deg = VedicMath.degInRashi(moonSid);
    switch (r) {
      case 0: case 1: return 0;
      case 2: case 5: case 6: case 10: return 1;
      case 3: case 11: return 2;
      case 4: return 3;
      case 7: return 4;
      case 8: return deg < 15 ? 1 : 0;
      case 9: return deg < 15 ? 0 : 2;
    }
    return 1;
  }

  static const List<List<double>> _vashyaTable = [
    // Girl:  Chat  Manv  Jala  Vana  Keet     (rows = boy)
    [2.0, 1.0, 1.0, 0.5, 1.0], // Chatushpada
    [1.0, 2.0, 0.5, 0.0, 1.0], // Manava
    [1.0, 0.5, 2.0, 1.0, 1.0], // Jalachara
    [0.5, 0.0, 1.0, 2.0, 0.0], // Vanachara
    [1.0, 1.0, 1.0, 0.0, 2.0], // Keeta
  ];

  static double vashyaScore(int boyGroup, int girlGroup) => _vashyaTable[boyGroup][girlGroup];

  // 3. Tara (max 3): count both ways; remainders 3, 5, 7 (of 9) are inauspicious.
  static double taraScore(int bNak, int gNak) {
    int tara(int from, int to) {
      final int count = (to - from + 27) % 27 + 1;
      final int rem = count % 9;
      return rem == 0 ? 9 : rem;
    }

    double score = 0;
    if (![3, 5, 7].contains(tara(gNak, bNak))) score += 1.5;
    if (![3, 5, 7].contains(tara(bNak, gNak))) score += 1.5;
    return score;
  }

  // 4. Yoni (max 4).
  // Animals: 0 Horse, 1 Elephant, 2 Sheep, 3 Serpent, 4 Dog, 5 Cat, 6 Rat, 7 Cow,
  //          8 Buffalo, 9 Tiger, 10 Deer, 11 Monkey, 12 Mongoose, 13 Lion.
  static const List<int> yoniOfNakshatra = [
    0, 1, 2, 3, 3, 4, 5, 2, 5, // Ashwini .. Ashlesha
    6, 6, 7, 8, 9, 8, 9, 10, 10, // Magha .. Jyeshtha
    4, 11, 12, 11, 13, 0, 13, 7, 1, // Mula .. Revati
  ];

  static const List<String> yoniNames = [
    'Horse', 'Elephant', 'Sheep', 'Serpent', 'Dog', 'Cat', 'Rat', 'Cow',
    'Buffalo', 'Tiger', 'Deer', 'Monkey', 'Mongoose', 'Lion',
  ];

  static const List<List<int>> _yoniTable = [
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

  static double yoniScore(int bNak, int gNak) =>
      _yoniTable[yoniOfNakshatra[bNak]][yoniOfNakshatra[gNak]].toDouble();

  // 5. Graha Maitri (max 5), from the natural relationship of the Moon-sign lords.
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

  /// 2 = friend, 1 = neutral, 0 = enemy.
  static int _relation(String a, String b) {
    if (_friends[a]!.contains(b)) return 2;
    if (_enemies[a]!.contains(b)) return 0;
    return 1;
  }

  static double maitriScore(int bRashi, int gRashi) {
    final String bL = VedicMath.rashis[bRashi].lord;
    final String gL = VedicMath.rashis[gRashi].lord;
    if (bL == gL) return 5.0;
    final int a = _relation(bL, gL);
    final int b = _relation(gL, bL);
    final int hi = a > b ? a : b;
    final int lo = a > b ? b : a;
    if (hi == 2 && lo == 2) return 5.0; // friend - friend
    if (hi == 2 && lo == 1) return 4.0; // friend - neutral
    if (hi == 1 && lo == 1) return 3.0; // neutral - neutral
    if (hi == 2 && lo == 0) return 1.0; // friend - enemy
    if (hi == 1 && lo == 0) return 0.5; // neutral - enemy
    return 0.0; // enemy - enemy
  }

  // 6. Gana (max 6). 0 Deva, 1 Manushya, 2 Rakshasa.
  static int ganaOf(int nak) {
    switch (VedicMath.nakshatras[nak].gana) {
      case 'Deva': return 0;
      case 'Rakshasa': return 2;
      default: return 1;
    }
  }

  static const List<List<double>> _ganaTable = [
    // Girl: Deva Manushya Rakshasa   (rows = boy)
    [6, 6, 1],
    [5, 6, 0],
    [1, 0, 6],
  ];

  static double ganaScore(int bNak, int gNak) => _ganaTable[ganaOf(bNak)][ganaOf(gNak)];

  // 7. Bhakoot (max 7): 2/12, 5/9 and 6/8 relationships score 0.
  static double bhakootScore(int bRashi, int gRashi) {
    final int diff = (gRashi - bRashi + 12) % 12;
    if (diff == 1 || diff == 11) return 0.0; // 2/12
    if (diff == 4 || diff == 8) return 0.0; // 5/9
    if (diff == 5 || diff == 7) return 0.0; // 6/8
    return 7.0;
  }

  // 8. Nadi (max 8): same Nadi scores 0.
  static String nadiOf(int nak) => VedicMath.nakshatras[nak].nadi;

  static double nadiScore(int bNak, int gNak) => nadiOf(bNak) == nadiOf(gNak) ? 0.0 : 8.0;
}
