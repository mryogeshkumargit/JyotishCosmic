import 'ephemeris.dart';
import 'l10n.dart';
import 'vedic_math.dart';

class TransitEffect {
  final String _en;
  final String _hi;
  final String type;
  const TransitEffect(this._en, this._hi, this.type);

  String get effect => tr(_en, _hi);
}

class TransitResult {
  final String planet;
  final Planet planetData;
  final int transitRashi;
  final Rashi rashiData;
  final int? natalRashi;
  final int houseFromMoon;
  final int houseFromLagna;
  final String? aspectOnNatal;
  final String effect;
  final String effectType;
  final double sid;
  final bool retrograde;

  TransitResult({
    required this.planet,
    required this.planetData,
    required this.transitRashi,
    required this.rashiData,
    this.natalRashi,
    required this.houseFromMoon,
    required this.houseFromLagna,
    this.aspectOnNatal,
    required this.effect,
    required this.effectType,
    required this.sid,
    this.retrograde = false,
  });
}

class TransitMath {
  static const Map<String, Map<int, TransitEffect>> transitEffects = {
    'saturn': {
      1: TransitEffect('Challenging — health, mental stress, delays', 'चुनौतीपूर्ण — स्वास्थ्य, मानसिक तनाव, देरी', 'difficult'),
      2: TransitEffect('Financial pressure, family tensions, speech issues', 'आर्थिक दबाव, पारिवारिक तनाव, वाणी से समस्या', 'difficult'),
      3: TransitEffect('Gains, courage, brother relations improve', 'लाभ, साहस, भाई-बहनों से संबंध सुधरते हैं', 'good'),
      4: TransitEffect('Domestic troubles, mental unrest, property issues', 'घरेलू परेशानियाँ, मानसिक अशांति, संपत्ति के मामले', 'difficult'),
      5: TransitEffect('Obstacles in education, children, investments', 'शिक्षा, संतान और निवेश में बाधाएँ', 'difficult'),
      6: TransitEffect('Victory over enemies, health improves, debt clearance', 'शत्रुओं पर विजय, स्वास्थ्य में सुधार, कर्ज़ से मुक्ति', 'good'),
      7: TransitEffect('Partnership issues, marital stress, travel', 'साझेदारी में समस्या, वैवाहिक तनाव, यात्रा', 'difficult'),
      8: TransitEffect('Health concerns, sudden events, obstacles', 'स्वास्थ्य की चिंता, अचानक घटनाएँ, बाधाएँ', 'difficult'),
      9: TransitEffect('Father health, fortune dips, spiritual inclination', 'पिता का स्वास्थ्य, भाग्य में कमी, आध्यात्मिक रुझान', 'difficult'),
      10: TransitEffect('Hard work rewarded, career challenges then success', 'मेहनत का फल, करियर में पहले चुनौती फिर सफलता', 'mixed'),
      11: TransitEffect('Good gains, elder sibling help, ambitions fulfilled', 'अच्छा लाभ, बड़े भाई-बहन की मदद, महत्वाकांक्षाएँ पूरी', 'good'),
      12: TransitEffect('Expenses rise, foreign travel, spiritual retreat', 'खर्च बढ़ते हैं, विदेश यात्रा, आध्यात्मिक एकांत', 'mixed'),
    },
    'jupiter': {
      1: TransitEffect('Excellent — wisdom, health, new beginnings, prosperity', 'उत्तम — ज्ञान, स्वास्थ्य, नई शुरुआत, समृद्धि', 'good'),
      2: TransitEffect('Wealth gains, family happiness, good food', 'धन लाभ, पारिवारिक सुख, अच्छा भोजन', 'good'),
      3: TransitEffect('Short travels, courage, sibling cooperation', 'छोटी यात्राएँ, साहस, भाई-बहनों का सहयोग', 'mixed'),
      4: TransitEffect('Property gains, mother happy, vehicle, domestic peace', 'संपत्ति लाभ, माता प्रसन्न, वाहन, घरेलू शांति', 'good'),
      5: TransitEffect('Intelligence, children, investments, creative success', 'बुद्धि, संतान, निवेश, रचनात्मक सफलता', 'good'),
      6: TransitEffect('Health issues, enemies rise, debt concerns', 'स्वास्थ्य समस्याएँ, शत्रु बढ़ते हैं, कर्ज़ की चिंता', 'difficult'),
      7: TransitEffect('Marriage, partnership, legal matters improve', 'विवाह, साझेदारी, कानूनी मामलों में सुधार', 'good'),
      8: TransitEffect('Spiritual growth, research, hidden matters', 'आध्यात्मिक उन्नति, शोध, छिपे विषय', 'mixed'),
      9: TransitEffect('Exceptional luck, pilgrimage, higher education, father blessed', 'असाधारण भाग्य, तीर्थयात्रा, उच्च शिक्षा, पिता को सुख', 'good'),
      10: TransitEffect('Career peak, recognition, promotions, authority', 'करियर का शिखर, पहचान, पदोन्नति, अधिकार', 'good'),
      11: TransitEffect('Financial gains, goals achieved, social recognition', 'आर्थिक लाभ, लक्ष्य प्राप्त, सामाजिक मान', 'good'),
      12: TransitEffect('Spirituality, foreign travel, moksha, expenses for good cause', 'आध्यात्मिकता, विदेश यात्रा, मोक्ष, शुभ कार्यों पर खर्च', 'mixed'),
    },
    'mars': {
      1: TransitEffect('Energy high, aggressive, accidents possible, health watch', 'ऊर्जा अधिक, आक्रामकता, दुर्घटना संभव, स्वास्थ्य पर ध्यान', 'mixed'),
      2: TransitEffect('Financial decisions, family disputes, impulsive spending', 'आर्थिक निर्णय, पारिवारिक विवाद, आवेग में खर्च', 'mixed'),
      3: TransitEffect('Courage, siblings help, short travels, good for athletes', 'साहस, भाई-बहनों की मदद, छोटी यात्राएँ, खिलाड़ियों के लिए अच्छा', 'good'),
      4: TransitEffect('Domestic conflicts, property disputes, mother health', 'घरेलू कलह, संपत्ति विवाद, माता का स्वास्थ्य', 'difficult'),
      5: TransitEffect('Children issues, love affairs, speculative risks', 'संतान संबंधी समस्या, प्रेम संबंध, सट्टे में जोखिम', 'difficult'),
      6: TransitEffect('Victory over enemies, health improvement, competitive success', 'शत्रुओं पर विजय, स्वास्थ्य सुधार, प्रतियोगिता में सफलता', 'good'),
      7: TransitEffect('Partnership conflicts, travel, marital tensions', 'साझेदारी में टकराव, यात्रा, वैवाहिक तनाव', 'difficult'),
      8: TransitEffect('Accidents, surgery possible, inheritance disputes', 'दुर्घटना, शल्य चिकित्सा संभव, विरासत के विवाद', 'difficult'),
      9: TransitEffect('Long travel, father issues, religious disputes', 'लंबी यात्रा, पिता से समस्या, धार्मिक विवाद', 'mixed'),
      10: TransitEffect('Career drive, leadership, ambitious actions', 'करियर में जोश, नेतृत्व, महत्वाकांक्षी कार्य', 'good'),
      11: TransitEffect('Financial gains, goals met, social circle expands', 'आर्थिक लाभ, लक्ष्य पूरे, सामाजिक दायरा बढ़ता है', 'good'),
      12: TransitEffect('Hidden expenses, foreign travel, spiritual pursuits', 'छिपे खर्च, विदेश यात्रा, आध्यात्मिक कार्य', 'mixed'),
    },
  };

  /// Houses from the natal Moon where each graha's transit is classically favourable (Gochara).
  static const Map<String, List<int>> favourableFromMoon = {
    'sun': [3, 6, 10, 11],
    'moon': [1, 3, 6, 7, 10, 11],
    'mars': [3, 6, 11],
    'mercury': [2, 4, 6, 8, 10, 11],
    'jupiter': [2, 5, 7, 9, 11],
    'venus': [1, 2, 3, 4, 5, 8, 9, 11, 12],
    'saturn': [3, 6, 11],
    'rahu': [3, 6, 11],
    'ketu': [3, 6, 11],
  };

  static const Map<String, String> _goodTheme = {
    'sun': 'recognition, authority and vitality',
    'moon': 'peace of mind, comfort and support',
    'mercury': 'communication, trade and learning',
    'venus': 'comforts, relationships and enjoyment',
    'rahu': 'unexpected gains and ambition',
    'ketu': 'spiritual insight and victory over obstacles',
  };

  static const Map<String, String> _badTheme = {
    'sun': 'fatigue, friction with authority and expenses',
    'moon': 'emotional fluctuation and restlessness',
    'mercury': 'miscommunication and nervous stress',
    'venus': 'relationship strain and indulgence',
    'rahu': 'confusion, anxiety and deception',
    'ketu': 'detachment, losses and health niggles',
  };

  static const Map<String, String> _goodThemeHi = {
    'sun': 'पहचान, अधिकार और जीवनशक्ति',
    'moon': 'मन की शांति, सुख और सहारा',
    'mercury': 'संवाद, व्यापार और विद्या',
    'venus': 'सुख-सुविधा, संबंध और आनंद',
    'rahu': 'अप्रत्याशित लाभ और महत्वाकांक्षा',
    'ketu': 'आध्यात्मिक अंतर्दृष्टि और बाधाओं पर विजय',
  };
  static const Map<String, String> _badThemeHi = {
    'sun': 'थकान, अधिकारियों से खटपट और खर्च',
    'moon': 'भावनात्मक उतार-चढ़ाव और बेचैनी',
    'mercury': 'गलतफ़हमी और मानसिक तनाव',
    'venus': 'संबंधों में खिंचाव और अति-भोग',
    'rahu': 'भ्रम, चिंता और धोखा',
    'ketu': 'वैराग्य, हानि और छोटी स्वास्थ्य समस्याएँ',
  };

  static TransitEffect effectFor(String planet, int houseFromMoon) {
    final specific = transitEffects[planet]?[houseFromMoon];
    if (specific != null) return specific;
    final good = favourableFromMoon[planet]?.contains(houseFromMoon) ?? false;
    return good
        ? TransitEffect('Favourable — ${_goodTheme[planet] ?? 'positive results'}', 'शुभ — ${_goodThemeHi[planet] ?? 'अच्छे परिणाम'}', 'good')
        : TransitEffect('Unfavourable — ${_badTheme[planet] ?? 'challenges'}', 'अशुभ — ${_badThemeHi[planet] ?? 'चुनौतियाँ'}', 'difficult');
  }

  static List<TransitResult> compute(ChartData birthChart, [double? atJd]) {
    // Planetary longitudes are geocentric, so the place only matters for the ascendant.
    final ChartData transitChart = Ephemeris.computeChartForJd(atJd ?? Ephemeris.nowJd(), 0, 0);

    int moonRashi = VedicMath.rashiIndex(birthChart.planetLongitudes['moon'] ?? 0);
    int lagnaRashi = birthChart.lagnaRashi;

    List<TransitResult> transits = [];

    transitChart.planetLongitudes.forEach((pName, sidereal) {
      if (!VedicMath.planets.containsKey(pName)) return;

      int transRashi = VedicMath.rashiIndex(sidereal);
      int? natalRashi = birthChart.planetLongitudes.containsKey(pName) 
          ? VedicMath.rashiIndex(birthChart.planetLongitudes[pName]!) 
          : null;

      int hFromMoon = VedicMath.houseOf(transRashi, moonRashi);
      int hFromLagna = VedicMath.houseOf(transRashi, lagnaRashi);

      String? aspectOnNatal;
      if (natalRashi != null) {
        if (transRashi == natalRashi) {
          aspectOnNatal = tr('Conjunct', 'युति');
        } else {
          int houseFromTrans = (natalRashi - transRashi + 12) % 12 + 1;
          bool aspects = false;
          if (houseFromTrans == 7) {
            aspects = true; // All planets aspect 7th
          } else if (pName == 'mars' && (houseFromTrans == 4 || houseFromTrans == 8)) {
            aspects = true;
          } else if (pName == 'jupiter' && (houseFromTrans == 5 || houseFromTrans == 9)) {
            aspects = true;
          } else if (pName == 'saturn' && (houseFromTrans == 3 || houseFromTrans == 10)) {
            aspects = true;
          }
          if (aspects) {
            aspectOnNatal = tr('Aspects', 'दृष्टि');
          }
        }
      }

      final TransitEffect effectData = effectFor(pName, hFromMoon);

      transits.add(TransitResult(
        planet: pName,
        planetData: VedicMath.planets[pName]!,
        transitRashi: transRashi,
        rashiData: VedicMath.rashis[transRashi],
        natalRashi: natalRashi,
        houseFromMoon: hFromMoon,
        houseFromLagna: hFromLagna,
        aspectOnNatal: aspectOnNatal,
        effect: effectData.effect,
        effectType: effectData.type,
        sid: sidereal,
        retrograde: transitChart.isRetrograde(pName),
      ));
    });

    return transits;
  }
}
