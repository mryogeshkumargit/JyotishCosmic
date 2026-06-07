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
}

class MilanMath {
  /// Evaluates the 36-point Ashtakoot Guna Milan between a boy and a girl.
  /// Requires exact sideral Moon longitudes.
  static MilanResult calculateMilan(double boyMoonSid, double girlMoonSid) {
    int boyRashi = VedicMath.rashiIndex(boyMoonSid);
    int girlRashi = VedicMath.rashiIndex(girlMoonSid);
    
    int boyNak = VedicMath.nakshatraIndex(boyMoonSid);
    int girlNak = VedicMath.nakshatraIndex(girlMoonSid);

    return MilanResult(
      varna: _calcVarna(boyRashi, girlRashi),
      vashya: _calcVashya(boyRashi, girlRashi),
      tara: _calcTara(boyNak, girlNak),
      yoni: _calcYoni(boyNak, girlNak),
      maitri: _calcMaitri(boyRashi, girlRashi),
      gana: _calcGana(boyNak, girlNak),
      bhakoot: _calcBhakoot(boyRashi, girlRashi),
      nadi: _calcNadi(boyNak, girlNak),
    );
  }

  // 1. Varna (Max 1)
  // Brahmins (3), Kshatriyas (2), Vaishyas (1), Shudras (0)
  static double _calcVarna(int bRashi, int gRashi) {
    int getVarna(int r) {
      if ([3, 7, 11].contains(r)) return 3; // Brahmin (Cancer, Scorpio, Pisces)
      if ([0, 4, 8].contains(r)) return 2;  // Kshatriya (Aries, Leo, Sag)
      if ([1, 5, 9].contains(r)) return 1;  // Vaishya (Taurus, Virgo, Cap)
      return 0;                             // Shudra (Gemini, Libra, Aqua)
    }
    return getVarna(bRashi) >= getVarna(gRashi) ? 1.0 : 0.0;
  }

  // 2. Vashya (Max 2)
  static double _calcVashya(int bRashi, int gRashi) {
    // 0: Chatushpada, 1: Manava, 2: Jalchar, 3: Vanachar, 4: Keeta
    int getVashyaGroup(int r) {
      if ([0, 1, 8, 9].contains(r)) return 0;
      if ([2, 5, 6, 10].contains(r)) return 1;
      if ([3, 11].contains(r)) return 2;
      if (r == 4) return 3;
      return 4; // 7 (Scorpio)
    }
    int bV = getVashyaGroup(bRashi);
    int gV = getVashyaGroup(gRashi);
    
    if (bV == gV) return 2.0;
    
    // Enemy matrix (simplified friendly/neutral/enemy)
    // Manava and Jalchar are friendly (1)
    if ((bV == 1 && gV == 2) || (bV == 2 && gV == 1)) return 1.0;
    // Chatushpada and Vanachar are friendly (1)
    if ((bV == 0 && gV == 3) || (bV == 3 && gV == 0)) return 1.0;
    // Chatushpada and Keeta are neutral (0.5)
    if ((bV == 0 && gV == 4) || (bV == 4 && gV == 0)) return 0.5;
    
    return 0.0;
  }

  // 3. Tara (Max 3)
  static double _calcTara(int bNak, int gNak) {
    int bToG = (gNak - bNak + 27) % 27 + 1;
    int gToB = (bNak - gNak + 27) % 27 + 1;
    
    double score = 0;
    int bTara = bToG % 9;
    int gTara = gToB % 9;
    
    if (![3, 5, 7].contains(bTara == 0 ? 9 : bTara)) score += 1.5;
    if (![3, 5, 7].contains(gTara == 0 ? 9 : gTara)) score += 1.5;
    
    return score;
  }

  // 4. Yoni (Max 4)
  static double _calcYoni(int bNak, int gNak) {
    // 14 Yoni Animals mapped by Nakshatra (0 to 13)
    final List<int> yoniMap = [
      0, 1, 2, 3, 3, 4, 5, 2, 5, 6, 6, 7, 8, 9, 9, 10, 10, 4, 11, 11, 12, 12, 13, 13, 14, 14, 1
    ];
    int bY = yoniMap[bNak];
    int gY = yoniMap[gNak];
    
    if (bY == gY) return 4.0;
    
    // Hostile pairs: Ashwa-Mahisha, Gaja-Simha, Mesha-Vanara, Sarpa-Nakula, Shwana-Mriga, Marjala-Mushaka, Gau-Vyaghra
    List<List<int>> enemies = [[0,8], [1,13], [2,11], [3,12], [4,10], [5,6], [7,9]];
    for (var pair in enemies) {
      if ((bY == pair[0] && gY == pair[1]) || (bY == pair[1] && gY == pair[0])) return 0.0;
    }
    
    // Average default fallback
    return 2.0; 
  }

  // 5. Graha Maitri (Max 5)
  static double _calcMaitri(int bRashi, int gRashi) {
    List<String> lords = ['mars', 'venus', 'mercury', 'moon', 'sun', 'mercury', 'venus', 'mars', 'jupiter', 'saturn', 'saturn', 'jupiter'];
    String bL = lords[bRashi];
    String gL = lords[gRashi];
    
    if (bL == gL) return 5.0;
    
    Map<String, List<String>> friends = {
      'sun': ['moon', 'mars', 'jupiter'],
      'moon': ['sun', 'mercury'],
      'mars': ['sun', 'moon', 'jupiter'],
      'mercury': ['sun', 'venus'],
      'jupiter': ['sun', 'moon', 'mars'],
      'venus': ['mercury', 'saturn'],
      'saturn': ['mercury', 'venus'],
    };
    
    bool bLikesG = friends[bL]?.contains(gL) ?? false;
    bool gLikesB = friends[gL]?.contains(bL) ?? false;
    
    if (bLikesG && gLikesB) return 4.0; // Friendly
    if (bLikesG || gLikesB) return 3.0; // One friend, one neutral
    return 1.0; // Neutral/Enemy
  }

  // 6. Gana (Max 6)
  static double _calcGana(int bNak, int gNak) {
    int getGana(int n) {
      // 0: Deva, 1: Manava, 2: Rakshasa
      if ([0, 4, 6, 7, 12, 14, 16, 21, 26].contains(n)) return 0;
      if ([1, 2, 3, 5, 10, 11, 19, 20, 24].contains(n)) return 1;
      return 2; // Rakshasa
    }
    int bG = getGana(bNak);
    int gG = getGana(gNak);
    
    if (bG == gG) return 6.0;
    if (bG == 0 && gG == 1) return 6.0; // Boy Deva, Girl Manava
    if (bG == 1 && gG == 0) return 5.0; // Boy Manava, Girl Deva
    if (bG == 2 && gG == 0) return 1.0; // Boy Rakshasa, Girl Deva
    if (bG == 2 && gG == 1) return 0.0; // Boy Rakshasa, Girl Manava
    if (bG == 0 && gG == 2) return 1.0; // Boy Deva, Girl Rakshasa
    if (bG == 1 && gG == 2) return 0.0; // Boy Manava, Girl Rakshasa
    return 0.0;
  }

  // 7. Bhakoot (Max 7)
  static double _calcBhakoot(int bRashi, int gRashi) {
    if (bRashi == gRashi) return 7.0;
    int diff = (gRashi - bRashi + 12) % 12; // 0-11
    
    // Inauspicious combinations: 6/8, 5/9, 2/12
    if (diff == 1 || diff == 11) return 0.0; // 2/12
    if (diff == 4 || diff == 8) return 0.0;  // 5/9
    if (diff == 5 || diff == 7) return 0.0;  // 6/8
    
    // Auspicious combinations: 1/7, 3/11, 4/10
    return 7.0;
  }

  // 8. Nadi (Max 8)
  static double _calcNadi(int bNak, int gNak) {
    int getNadi(int n) {
      // 0: Adi/Vata, 1: Madhya/Pitta, 2: Antya/Kapha
      // Forward, backward, forward cycle
      int pos = n % 9;
      if ([0, 5, 6].contains(pos)) return 0;
      if ([1, 4, 7].contains(pos)) return 1;
      return 2;
    }
    
    int bN = getNadi(bNak);
    int gN = getNadi(gNak);
    
    return bN == gN ? 0.0 : 8.0;
  }
}
