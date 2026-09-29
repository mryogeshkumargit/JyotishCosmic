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

/// Gochara (transit) results counted from the natal Moon sign.
class TransitMath {
  /// Classical favourable houses from the natal Moon for each graha (Phaladeepika / BPHS).
  static const Map<String, List<int>> favourableHouses = {
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

  static const Map<String, Map<int, String>> transitTexts = {
    'saturn': {
      1: 'Janma Shani — health, mental stress and delays; part of Sade Sati',
      2: 'Financial pressure, family tensions; last phase of Sade Sati',
      3: 'Gains, courage and success through effort',
      4: 'Domestic worries, property issues (Kantaka Shani)',
      5: 'Obstacles in education, children and investments',
      6: 'Victory over enemies, improving health, debts cleared',
      7: 'Partnership strain, travel, marital stress',
      8: 'Ashtama Shani — health concerns, sudden setbacks',
      9: 'Fortune fluctuates, father\'s health, spiritual turn',
      10: 'Heavy workload and career pressure; rewards come slowly',
      11: 'Good gains, ambitions fulfilled, support from elders',
      12: 'Expenses rise, foreign travel; first phase of Sade Sati',
    },
    'jupiter': {
      1: 'Restlessness, relocation or changes in position',
      2: 'Wealth gains, family happiness, good food',
      3: 'Obstacles in work, change of place',
      4: 'Domestic worries, strained relations with relatives',
      5: 'Children, intelligence, creative and investment success',
      6: 'Health issues and trouble from rivals',
      7: 'Marriage, partnership and comforts improve',
      8: 'Delays, fatigue, hidden troubles',
      9: 'Fortune, pilgrimage, higher learning, blessings of elders',
      10: 'Career fluctuation, loss of position or reputation strain',
      11: 'Financial gains, goals achieved, recognition',
      12: 'Expenses, travel, spiritual inclination',
    },
    'mars': {
      1: 'Anger, accidents possible, watch health',
      2: 'Disputes in family, impulsive spending',
      3: 'Courage, success over rivals, gains through effort',
      4: 'Domestic conflicts, property disputes',
      5: 'Concerns about children, speculative losses',
      6: 'Victory over enemies, health improves',
      7: 'Partnership conflicts, marital tension',
      8: 'Accidents, surgery or injury risk',
      9: 'Setbacks in fortune, disputes with elders',
      10: 'Obstacles at work, heavy exertion',
      11: 'Financial gains, goals met',
      12: 'Hidden expenses, loss through haste',
    },
  };

  static String _genericText(String planet, int house, bool good) {
    final name = VedicMath.planets[planet]!.name;
    return good
        ? '$name transiting the ${_ord(house)} from Moon — generally supportive'
        : '$name transiting the ${_ord(house)} from Moon — needs care';
  }

  static String _ord(int n) {
    if (n % 100 >= 11 && n % 100 <= 13) return '${n}th';
    switch (n % 10) {
      case 1:
        return '${n}st';
      case 2:
        return '${n}nd';
      case 3:
        return '${n}rd';
    }
    return '${n}th';
  }

  static List<TransitResult> compute(ChartData birthChart, double utcOffset, {ChartData? transitChart}) {
    final now = transitChart ?? Ephemeris.currentChart(utcOffset: utcOffset);

    final moonRashi = VedicMath.rashiIndex(birthChart.planetLongitudes['moon'] ?? 0);
    final lagnaRashi = birthChart.lagnaRashi;
    final transits = <TransitResult>[];

    now.planetLongitudes.forEach((pName, sidereal) {
      if (!VedicMath.planets.containsKey(pName)) return;

      final transRashi = VedicMath.rashiIndex(sidereal);
      final natalRashi = birthChart.planetLongitudes.containsKey(pName)
          ? VedicMath.rashiIndex(birthChart.planetLongitudes[pName]!)
          : null;

      final hFromMoon = VedicMath.houseOf(transRashi, moonRashi);
      final hFromLagna = VedicMath.houseOf(transRashi, lagnaRashi);

      String? aspectOnNatal;
      if (natalRashi != null) {
        if (transRashi == natalRashi) {
          aspectOnNatal = 'Conjunct';
        } else {
          final houseFromTrans = (natalRashi - transRashi + 12) % 12 + 1;
          final aspects = houseFromTrans == 7 ||
              (pName == 'mars' && (houseFromTrans == 4 || houseFromTrans == 8)) ||
              (pName == 'jupiter' && (houseFromTrans == 5 || houseFromTrans == 9)) ||
              (pName == 'saturn' && (houseFromTrans == 3 || houseFromTrans == 10));
          if (aspects) aspectOnNatal = 'Aspects';
        }
      }

      final good = favourableHouses[pName]?.contains(hFromMoon) ?? false;
      final text = transitTexts[pName]?[hFromMoon] ?? _genericText(pName, hFromMoon, good);

      transits.add(TransitResult(
        planet: pName,
        planetData: VedicMath.planets[pName]!,
        transitRashi: transRashi,
        rashiData: VedicMath.rashis[transRashi],
        natalRashi: natalRashi,
        houseFromMoon: hFromMoon,
        houseFromLagna: hFromLagna,
        aspectOnNatal: aspectOnNatal,
        effect: text,
        effectType: good ? 'good' : 'difficult',
        sid: sidereal,
        retrograde: now.isRetrograde(pName),
      ));
    });

    return transits;
  }
}
