import 'ephemeris.dart';
import 'vedic_math.dart';

class TransitEffect {
  final String effect;
  final String type;
  const TransitEffect(this.effect, this.type);
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
      1: TransitEffect('Challenging — health, mental stress, delays', 'difficult'),
      2: TransitEffect('Financial pressure, family tensions, speech issues', 'difficult'),
      3: TransitEffect('Gains, courage, brother relations improve', 'good'),
      4: TransitEffect('Domestic troubles, mental unrest, property issues', 'difficult'),
      5: TransitEffect('Obstacles in education, children, investments', 'difficult'),
      6: TransitEffect('Victory over enemies, health improves, debt clearance', 'good'),
      7: TransitEffect('Partnership issues, marital stress, travel', 'difficult'),
      8: TransitEffect('Health concerns, sudden events, obstacles', 'difficult'),
      9: TransitEffect('Father health, fortune dips, spiritual inclination', 'difficult'),
      10: TransitEffect('Hard work rewarded, career challenges then success', 'mixed'),
      11: TransitEffect('Good gains, elder sibling help, ambitions fulfilled', 'good'),
      12: TransitEffect('Expenses rise, foreign travel, spiritual retreat', 'mixed'),
    },
    'jupiter': {
      1: TransitEffect('Excellent — wisdom, health, new beginnings, prosperity', 'good'),
      2: TransitEffect('Wealth gains, family happiness, good food', 'good'),
      3: TransitEffect('Short travels, courage, sibling cooperation', 'mixed'),
      4: TransitEffect('Property gains, mother happy, vehicle, domestic peace', 'good'),
      5: TransitEffect('Intelligence, children, investments, creative success', 'good'),
      6: TransitEffect('Health issues, enemies rise, debt concerns', 'difficult'),
      7: TransitEffect('Marriage, partnership, legal matters improve', 'good'),
      8: TransitEffect('Spiritual growth, research, hidden matters', 'mixed'),
      9: TransitEffect('Exceptional luck, pilgrimage, higher education, father blessed', 'good'),
      10: TransitEffect('Career peak, recognition, promotions, authority', 'good'),
      11: TransitEffect('Financial gains, goals achieved, social recognition', 'good'),
      12: TransitEffect('Spirituality, foreign travel, moksha, expenses for good cause', 'mixed'),
    },
    'mars': {
      1: TransitEffect('Energy high, aggressive, accidents possible, health watch', 'mixed'),
      2: TransitEffect('Financial decisions, family disputes, impulsive spending', 'mixed'),
      3: TransitEffect('Courage, siblings help, short travels, good for athletes', 'good'),
      4: TransitEffect('Domestic conflicts, property disputes, mother health', 'difficult'),
      5: TransitEffect('Children issues, love affairs, speculative risks', 'difficult'),
      6: TransitEffect('Victory over enemies, health improvement, competitive success', 'good'),
      7: TransitEffect('Partnership conflicts, travel, marital tensions', 'difficult'),
      8: TransitEffect('Accidents, surgery possible, inheritance disputes', 'difficult'),
      9: TransitEffect('Long travel, father issues, religious disputes', 'mixed'),
      10: TransitEffect('Career drive, leadership, ambitious actions', 'good'),
      11: TransitEffect('Financial gains, goals met, social circle expands', 'good'),
      12: TransitEffect('Hidden expenses, foreign travel, spiritual pursuits', 'mixed'),
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

  static TransitEffect effectFor(String planet, int houseFromMoon) {
    final specific = transitEffects[planet]?[houseFromMoon];
    if (specific != null) return specific;
    final good = favourableFromMoon[planet]?.contains(houseFromMoon) ?? false;
    return good
        ? TransitEffect('Favourable — ${_goodTheme[planet] ?? 'positive results'}', 'good')
        : TransitEffect('Unfavourable — ${_badTheme[planet] ?? 'challenges'}', 'difficult');
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
          aspectOnNatal = 'Conjunct';
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
            aspectOnNatal = 'Aspects';
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
