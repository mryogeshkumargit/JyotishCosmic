import 'package:flutter/material.dart';

class Rashi {
  final int id;
  final String name;
  final String hindi;
  final String lord;
  final String element;
  final String symbol;
  final String quality;

  const Rashi(this.id, this.name, this.hindi, this.lord, this.element, this.symbol, this.quality);
}

class Nakshatra {
  final int id;
  final String name;
  final String hindi;
  final String lord;
  final String deity;
  final String symbol;
  final String gana;
  final String nadi;
  final String lucky;
  final String description;

  const Nakshatra(this.id, this.name, this.hindi, this.lord, this.deity, this.symbol, this.gana, this.nadi, this.lucky, this.description);
}

class Planet {
  final String name;
  final String hindi;
  final String symbol;
  final Color color;
  final int exalt;
  final int debi;
  final List<int> ownSigns;

  const Planet(this.name, this.hindi, this.symbol, this.color, this.exalt, this.debi, this.ownSigns);
}

class VargaDef {
  final String key;
  final int div;
  final String name;
  final String hindi;
  final String purpose;

  const VargaDef(this.key, this.div, this.name, this.hindi, this.purpose);
}

class VedicMath {
  static const List<Rashi> rashis = [
    Rashi(0, 'Aries', 'मेष', 'mars', 'Fire', '♈', 'Cardinal'),
    Rashi(1, 'Taurus', 'वृषभ', 'venus', 'Earth', '♉', 'Fixed'),
    Rashi(2, 'Gemini', 'मिथुन', 'mercury', 'Air', '♊', 'Mutable'),
    Rashi(3, 'Cancer', 'कर्क', 'moon', 'Water', '♋', 'Cardinal'),
    Rashi(4, 'Leo', 'सिंह', 'sun', 'Fire', '♌', 'Fixed'),
    Rashi(5, 'Virgo', 'कन्या', 'mercury', 'Earth', '♍', 'Mutable'),
    Rashi(6, 'Libra', 'तुला', 'venus', 'Air', '♎', 'Cardinal'),
    Rashi(7, 'Scorpio', 'वृश्चिक', 'mars', 'Water', '♏', 'Fixed'),
    Rashi(8, 'Sagittarius', 'धनु', 'jupiter', 'Fire', '♐', 'Mutable'),
    Rashi(9, 'Capricorn', 'मकर', 'saturn', 'Earth', '♑', 'Cardinal'),
    Rashi(10, 'Aquarius', 'कुम्भ', 'saturn', 'Air', '♒', 'Fixed'),
    Rashi(11, 'Pisces', 'मीन', 'jupiter', 'Water', '♓', 'Mutable'),
  ];

  static const List<Nakshatra> nakshatras = [
    Nakshatra(0, 'Ashwini', 'अश्विनी', 'ketu', 'Ashwini Kumars', 'Horse Head', 'Deva', 'Vata', '1,10,19', 'Pioneers, energetic, quick-witted, impulsive, lovers of travel and medicine.'),
    Nakshatra(1, 'Bharani', 'भरणी', 'venus', 'Yama', 'Yoni', 'Manava', 'Pitta', '9,18,27', 'Extreme, passionate, determined, relates to birth and death, creative and artistic.'),
    Nakshatra(2, 'Krittika', 'कृत्तिका', 'sun', 'Agni', 'Razor / Flame', 'Rakshasa', 'Kapha', '3,12,21', 'Sharp, cutting, fiery, ambitious, protective, highly motivated by goals and truth.'),
    Nakshatra(3, 'Rohini', 'रोहिणी', 'moon', 'Brahma', 'Cart / Chariot', 'Manava', 'Kapha', '2,11,20', 'Charming, romantic, materialistic, highly productive, loves agriculture and beauty.'),
    Nakshatra(4, 'Mrigashira', 'मृगशिरा', 'mars', 'Soma', 'Deer Head', 'Deva', 'Pitta', '5,14,23', 'Searching, inquisitive, gentle, loves collecting information, restless mind.'),
    Nakshatra(5, 'Ardra', 'आर्द्रा', 'rahu', 'Rudra', 'Teardrop', 'Manava', 'Vata', '6,15,24', 'Transformative, stormy, sharp, destructive of the old to create the new, intellectual.'),
    Nakshatra(6, 'Punarvasu', 'पुनर्वसु', 'jupiter', 'Aditi', 'Quiver of Arrows', 'Deva', 'Vata', '3,12,21', 'Return of the light, renewing, forgiving, loves home, philosophical and content.'),
    Nakshatra(7, 'Pushya', 'पुष्य', 'saturn', 'Brihaspati', 'Lotus / Udder', 'Deva', 'Pitta', '1,10,19', 'Nourishing, caring, spiritual, strictly follows dharma, traditional, loves teaching.'),
    Nakshatra(8, 'Ashlesha', 'आश्लेषा', 'mercury', 'Nagas', 'Serpent', 'Rakshasa', 'Kapha', '7,16,25', 'Mystical, intense, psychological, penetrating intellect, can be manipulative but highly protective.'),
    Nakshatra(9, 'Magha', 'मघा', 'ketu', 'Pitris', 'Royal Throne', 'Rakshasa', 'Kapha', '1,10,19', 'Kingly, proud, traditional, respects ancestors, demands respect, authoritative.'),
    Nakshatra(10, 'Purva Phalguni', 'पूर्वफाल्गुनी', 'venus', 'Bhaga', 'Bed / Couch (front)', 'Manava', 'Pitta', '9,18,27', 'Relaxed, enjoyment-oriented, romantic, charismatic, loves socializing and luxury.'),
    Nakshatra(11, 'Uttara Phalguni', 'उत्तरफाल्गुनी', 'sun', 'Aryaman', 'Bed / Couch (back)', 'Manava', 'Vata', '3,12,21', 'Responsible, patronizing, friendly, values contracts and marriages, reliable leader.'),
    Nakshatra(12, 'Hasta', 'हस्त', 'moon', 'Savitar', 'Hand / Fist', 'Deva', 'Vata', '2,11,20', 'Skilled with hands, detail-oriented, witty, good at healing or magic, grasping.'),
    Nakshatra(13, 'Chitra', 'चित्रा', 'mars', 'Vishwakarma', 'Bright Jewel', 'Rakshasa', 'Pitta', '5,14,23', 'Architects, designers, lovers of magic and illusion, dynamic, creating beauty from chaos.'),
    Nakshatra(14, 'Swati', 'स्वाति', 'rahu', 'Vayu', 'Coral / Sword', 'Deva', 'Kapha', '6,15,24', 'Independent, business-minded, flexible like the wind, diplomatic, loves freedom.'),
    Nakshatra(15, 'Vishakha', 'विशाखा', 'jupiter', 'Indra-Agni', 'Triumphal Arch', 'Rakshasa', 'Kapha', '3,12,21', 'Goal-oriented, triumphant, competitive, unyielding focus, driven by purpose.'),
    Nakshatra(16, 'Anuradha', 'अनुराधा', 'saturn', 'Mitra', 'Lotus / Staff', 'Deva', 'Pitta', '1,10,19', 'Friendly, cooperative, loves travel, scientific mind, dedicated to a higher cause.'),
    Nakshatra(17, 'Jyeshtha', 'ज्येष्ठा', 'mercury', 'Indra', 'Earring / Amulet', 'Rakshasa', 'Vata', '7,16,25', 'Eldest, senior, protective of the weak, handles power struggles, investigative.'),
    Nakshatra(18, 'Mula', 'मूल', 'ketu', 'Nirriti', 'Bunch of Roots', 'Rakshasa', 'Vata', '1,10,19', 'Getting to the root of things, destructive to illusions, researchers, intense, unyielding.'),
    Nakshatra(19, 'Purva Ashadha', 'पूर्वाषाढ़ा', 'venus', 'Apas', 'Fan / Basket', 'Manava', 'Pitta', '9,18,27', 'Invincible, proud, loves water, deeply emotional, confident, inspiring others.'),
    Nakshatra(20, 'Uttara Ashadha', 'उत्तराषाढ़ा', 'sun', 'Vishvadevas', 'Elephant Tusk', 'Manava', 'Kapha', '3,12,21', 'Unchallenged victory, righteous, highly committed, enduring, universally respected.'),
    Nakshatra(21, 'Shravana', 'श्रवण', 'moon', 'Vishnu', 'Ear / 3 Footprints', 'Deva', 'Kapha', '2,11,20', 'Listening, learning, oral traditions, receptive, quiet, connected to sound and knowledge.'),
    Nakshatra(22, 'Dhanishtha', 'धनिष्ठा', 'mars', 'Ashta Vasus', 'Drum / Flute', 'Rakshasa', 'Pitta', '5,14,23', 'Wealthy, musical, rhythmic, loves organizing, brilliant, excellent timing.'),
    Nakshatra(23, 'Shatabhisha', 'शतभिषा', 'rahu', 'Varuna', 'Flower / Circle', 'Rakshasa', 'Vata', '6,15,24', '100 healers, secretive, astronomical, loves boundaries and solitude, highly observant.'),
    Nakshatra(24, 'Purva Bhadrapada', 'पूर्वभाद्रपदा', 'jupiter', 'Aja Ekapada', 'Sword / Twin Faces', 'Manava', 'Vata', '3,12,21', 'Fiery, eccentric, visionary, interested in the dark or occult, deeply philosophical.'),
    Nakshatra(25, 'Uttara Bhadrapada', 'उत्तरभाद्रपदा', 'saturn', 'Ahir Budhyana', 'Serpent in Water', 'Manava', 'Pitta', '1,10,19', 'Deeply wise, compassionate, patient, connected to the deep unconscious, protective.'),
    Nakshatra(26, 'Revati', 'रेवती', 'mercury', 'Pushan', 'Fish / Drum', 'Deva', 'Kapha', '7,16,25', 'Nurturing, loves animals, final journey, wealthy, empathetic, bringing things to completion.'),
  ];

  static const Map<String, Planet> planets = {
    'sun': Planet('Sun', 'सूर्य', '☉', Color(0xFFF5C842), 0, 6, [4]),
    'moon': Planet('Moon', 'चन्द्र', '☽', Color(0xFFC4D4E0), 1, 7, [3]),
    'mars': Planet('Mars', 'मंगल', '♂', Color(0xFFE55B4D), 9, 3, [0, 7]),
    'mercury': Planet('Mercury', 'बुध', '☿', Color(0xFF4DB86E), 5, 11, [2, 5]),
    'jupiter': Planet('Jupiter', 'गुरु', '♃', Color(0xFFF7A94B), 3, 9, [8, 11]),
    'venus': Planet('Venus', 'शुक्र', '♀', Color(0xFFFF91C8), 11, 5, [1, 6]),
    'saturn': Planet('Saturn', 'शनि', '♄', Color(0xFF9B8FC5), 6, 0, [9, 10]),
    'rahu': Planet('Rahu', 'राहु', '☊', Color(0xFFC8B79A), 2, 8, []),
    'ketu': Planet('Ketu', 'केतु', '☋', Color(0xFF9AB5C8), 8, 2, []),
  };

  static const Map<String, int> dashaYears = {
    'ketu': 7, 'venus': 20, 'sun': 6, 'moon': 10, 'mars': 7,
    'rahu': 18, 'jupiter': 16, 'saturn': 19, 'mercury': 17
  };

  static const List<String> dashaOrder = [
    'ketu', 'venus', 'sun', 'moon', 'mars', 'rahu', 'jupiter', 'saturn', 'mercury'
  ];

  static const List<String> nakshatraLord = [
    'ketu', 'venus', 'sun', 'moon', 'mars', 'rahu', 'jupiter', 'saturn', 'mercury',
    'ketu', 'venus', 'sun', 'moon', 'mars', 'rahu', 'jupiter', 'saturn', 'mercury',
    'ketu', 'venus', 'sun', 'moon', 'mars', 'rahu', 'jupiter', 'saturn', 'mercury',
  ];

  static const List<VargaDef> vargaDefs = [
    VargaDef('D1', 1, 'Rasi', 'राशि', 'Overall self'),
    VargaDef('D2', 2, 'Hora', 'होरा', 'Wealth'),
    VargaDef('D3', 3, 'Drekkana', 'द्रेष्काण', 'Siblings & courage'),
    VargaDef('D4', 4, 'Chaturthamsa', 'चतुर्थांश', 'Property & assets'),
    VargaDef('D7', 7, 'Saptamsa', 'सप्तमांश', 'Children'),
    VargaDef('D9', 9, 'Navamsa', 'नवमांश', 'Marriage & dharma'),
    VargaDef('D10', 10, 'Dasamsa', 'दशमांश', 'Career'),
    VargaDef('D12', 12, 'Dwadasamsa', 'द्वादशांश', 'Parents'),
    VargaDef('D16', 16, 'Shodasamsa', 'षोडशांश', 'Vehicles & luxury'),
    VargaDef('D20', 20, 'Vimsamsa', 'विंशांश', 'Spirituality'),
    VargaDef('D24', 24, 'Chaturvimsamsa', 'चतुर्विंशांश', 'Education'),
    VargaDef('D27', 27, 'Bhamsa', 'भांश', 'Strength'),
    VargaDef('D30', 30, 'Trimsamsa', 'त्रिंशांश', 'Evils & misfortune'),
    VargaDef('D40', 40, 'Khavedamsa', 'खवेदांश', 'Auspiciousness'),
    VargaDef('D45', 45, 'Akshavedamsa', 'अक्षवेदांश', 'All matters'),
    VargaDef('D60', 60, 'Shashtiamsa', 'षष्टिांश', 'Past karma'),
  ];

  static double norm360(double d) {
    double x = d % 360;
    return x < 0 ? x + 360 : x;
  }

  static int rashiIndex(double sid) => (norm360(sid) / 30).floor();
  static int nakshatraIndex(double sid) => (norm360(sid) / (360 / 27)).floor();
  static int pada(double sid) => ((norm360(sid) % (360 / 27)) / (360 / 108)).floor() + 1;
  static double degInRashi(double sid) => norm360(sid) % 30;
  static int houseOf(int pRashi, int lagnaRashi) => ((pRashi - lagnaRashi + 12) % 12) + 1;

  static String dignityOf(String name, int rashi) {
    final p = planets[name];
    if (p == null) return 'neutral';
    if (p.exalt == rashi) return 'exalted';
    if (p.debi == rashi) return 'debilitated';
    if (p.ownSigns.contains(rashi)) return 'own';
    return 'neutral';
  }

  static int vargaRashi(double sid, String key, int div) {
    int ri = rashiIndex(sid);
    double pos = degInRashi(sid);
    int part = (pos / (30 / div)).floor();

    if (key == 'D1') return ri;
    if (key == 'D2') return (ri % 2 == 0) ? (part == 0 ? 4 : 3) : (part == 0 ? 3 : 4);
    if (key == 'D3') return (ri + part * 4) % 12;
    if (key == 'D4') return (ri + part * 3) % 12;
    if (key == 'D7') return ((ri % 2 == 0 ? ri : ri + 6) + part) % 12;
    if (key == 'D9') {
      final starts = {'Fire': 0, 'Earth': 9, 'Air': 6, 'Water': 3};
      return (starts[rashis[ri].element]! + part) % 12;
    }
    if (key == 'D10') return ((ri % 2 == 0 ? ri : ri + 8) + part) % 12;
    if (key == 'D12') return (ri + part) % 12;
    if (key == 'D16') return ((ri % 3) * 4 + part) % 12;
    if (key == 'D20') return ((ri % 3 == 0 ? 0 : ri % 3 == 1 ? 8 : 4) + part) % 12;
    if (key == 'D24') return ((ri % 2 == 0 ? 4 : 3) + part) % 12;
    if (key == 'D27') return ((ri % 4) * 3 + part) % 12;
    if (key == 'D30') {
      if (ri % 2 == 0) {
        if (pos <= 5) return 0;
        if (pos <= 10) return 10;
        if (pos <= 18) return 8;
        if (pos <= 25) return 2;
        return 6;
      } else {
        if (pos <= 5) return 1;
        if (pos <= 12) return 5;
        if (pos <= 20) return 11;
        if (pos <= 25) return 9;
        return 7;
      }
    }
    if (key == 'D40') return ((ri % 2 == 0 ? 0 : 6) + part) % 12;
    if (key == 'D45') return ((ri % 3) * 4 + part) % 12;
    if (key == 'D60') return (ri + part) % 12;

    return ((ri * div + part) % 12);
  }

  static String jdToDate(double jd) {
    int z = (jd + 0.5).floor();
    int a = z < 2299161 ? z : (() {
      int aa = ((z - 1867216.25) / 36524.25).floor();
      return z + 1 + aa - (aa / 4).floor();
    })();
    int b = a + 1524;
    int c = ((b - 122.1) / 365.25).floor();
    int d = (365.25 * c).floor();
    int e = ((b - d) / 30.6001).floor();
    int day = b - d - (30.6001 * e).floor();
    int month = e < 14 ? e - 1 : e - 13;
    int year = month > 2 ? c - 4716 : c - 4715;
    const m = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return "$day ${m[month - 1]} $year";
  }
}

class DashaPeriod {
  final String lord;
  final double years;
  final double startJD;
  final double endJD;
  final String startDate;
  final String endDate;
  final List<DashaPeriod> subPeriods;

  DashaPeriod(this.lord, this.years, this.startJD, this.endJD, this.startDate, this.endDate, {this.subPeriods = const []});
}

class DashaCalculations {
  final List<DashaPeriod> mahadashas;
  
  DashaCalculations(this.mahadashas);

  static DashaCalculations compute(double birthJD, double moonSid) {
    int ni = VedicMath.nakshatraIndex(moonSid);
    String startLord = VedicMath.nakshatraLord[ni];
    double frac = (VedicMath.norm360(moonSid) % (360 / 27)) / (360 / 27);
    double remainingYears = (1 - frac) * VedicMath.dashaYears[startLord]!;

    List<DashaPeriod> dashas = [];
    int si = VedicMath.dashaOrder.indexOf(startLord);
    double curMahaJD = birthJD;
    
    // Calculate first partial Mahadasha
    dashas.add(_buildMahadasha(startLord, remainingYears, curMahaJD, isFirst: true, totalYears: VedicMath.dashaYears[startLord]!.toDouble(), fracElapsed: frac));
    curMahaJD += remainingYears * 365.25;

    for (int i = 1; i < 9; i++) {
      String lord = VedicMath.dashaOrder[(si + i) % 9];
      double yrs = VedicMath.dashaYears[lord]!.toDouble();
      dashas.add(_buildMahadasha(lord, yrs, curMahaJD, isFirst: false, totalYears: yrs, fracElapsed: 0.0));
      curMahaJD += yrs * 365.25;
    }

    return DashaCalculations(dashas);
  }

  static DashaPeriod _buildMahadasha(String lord, double durationYears, double startJD, {required bool isFirst, required double totalYears, required double fracElapsed}) {
    List<DashaPeriod> antardashas = [];
    int startIndex = VedicMath.dashaOrder.indexOf(lord);
    double curAntarJD = startJD;

    for (int i = 0; i < 9; i++) {
      String antarLord = VedicMath.dashaOrder[(startIndex + i) % 9];
      double antarTotalYrs = (totalYears * VedicMath.dashaYears[antarLord]!) / 120.0;
      
      // If it's the first partial mahadasha, some antardashas are already over
      double antarRemainingYrs = antarTotalYrs;
      if (isFirst) {
        double mahaYearsElapsed = totalYears * fracElapsed;
        // Check if this antardasha is fully in the past
        double previousAntarSum = 0;
        for (int j = 0; j <= i; j++) {
           previousAntarSum += (totalYears * VedicMath.dashaYears[VedicMath.dashaOrder[(startIndex + j) % 9]]!) / 120.0;
        }
        double thisAntarStartElapsed = previousAntarSum - antarTotalYrs;
        
        if (mahaYearsElapsed >= previousAntarSum) {
          continue; // completely elapsed
        } else if (mahaYearsElapsed > thisAntarStartElapsed) {
          antarRemainingYrs = previousAntarSum - mahaYearsElapsed; // partially elapsed
        }
      }

      antardashas.add(_buildAntardasha(antarLord, antarRemainingYrs, curAntarJD, antarTotalYrs));
      curAntarJD += antarRemainingYrs * 365.25;
    }

    return DashaPeriod(
      lord, 
      durationYears, 
      startJD, 
      startJD + durationYears * 365.25, 
      VedicMath.jdToDate(startJD), 
      VedicMath.jdToDate(startJD + durationYears * 365.25),
      subPeriods: antardashas
    );
  }

  static DashaPeriod _buildAntardasha(String lord, double durationYears, double startJD, double totalYears) {
    List<DashaPeriod> pratyantardashas = [];
    int startIndex = VedicMath.dashaOrder.indexOf(lord);
    double curPratJD = startJD;
    
    // We don't partial-slice Pratyantar for simplicity, just divide durationYears proportionally
    for (int i = 0; i < 9; i++) {
      String pratLord = VedicMath.dashaOrder[(startIndex + i) % 9];
      double pratYrs = (durationYears * VedicMath.dashaYears[pratLord]!) / 120.0;
      
      pratyantardashas.add(DashaPeriod(
        pratLord,
        pratYrs,
        curPratJD,
        curPratJD + pratYrs * 365.25,
        VedicMath.jdToDate(curPratJD),
        VedicMath.jdToDate(curPratJD + pratYrs * 365.25)
      ));
      curPratJD += pratYrs * 365.25;
    }

    return DashaPeriod(
      lord,
      durationYears,
      startJD,
      startJD + durationYears * 365.25,
      VedicMath.jdToDate(startJD),
      VedicMath.jdToDate(startJD + durationYears * 365.25),
      subPeriods: pratyantardashas
    );
  }
}
