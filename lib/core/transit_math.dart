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

  static List<TransitResult> compute(ChartData birthChart, double utcOffset) {
    final now = DateTime.now().toUtc();
    final hour = now.hour + now.minute / 60.0;
    
    final nowJD = Ephemeris.julianDay(now.year, now.month, now.day, hour, 0, 0);
    final nowT = (nowJD - 2451545) / 36525;
    final ayan = Ephemeris.lahiriAyanamsa(nowJD);

    Map<String, double> transitPositions = {};
    for (var pName in ['sun', 'moon', 'mars', 'mercury', 'jupiter', 'venus', 'saturn']) {
      double trop;
      if (pName == 'sun') {
        trop = Ephemeris.sunLongitude(nowT);
      } else if (pName == 'moon') {
        trop = Ephemeris.moonLongitude(nowT);
      } else {
        final ch = Ephemeris.computeChart(now.year, now.month, now.day, hour, 0, 28.6, 77.2, 0); // using utc time
        trop = ch.planetLongitudes[pName]! + ayan; // Because computeChart returns sidereal, we hack back or just use its sidereal. Wait, computeChart uses JD internally. 
        // Actually computeChart returns sidereal directly! We don't need `trop` logic!
      }
    }

    // It is simpler to just generate a transit chart for the current time!
    ChartData transitChart = Ephemeris.computeChart(now.year, now.month, now.day, now.hour.toDouble(), now.minute.toDouble(), 28.6, 77.2, 0); // UTC time for transit doesn't depend on location for planetary longitude.

    int moonRashi = VedicMath.rashiIndex(birthChart.planetLongitudes['moon'] ?? 0);
    int lagnaRashi = (birthChart.ascendantSidereal / 30).floor();

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

      TransitEffect? effectData = transitEffects[pName]?[hFromMoon];
      
      transits.add(TransitResult(
        planet: pName,
        planetData: VedicMath.planets[pName]!,
        transitRashi: transRashi,
        rashiData: VedicMath.rashis[transRashi],
        natalRashi: natalRashi,
        houseFromMoon: hFromMoon,
        houseFromLagna: hFromLagna,
        aspectOnNatal: aspectOnNatal,
        effect: effectData?.effect ?? '${VedicMath.planets[pName]!.name} in ${VedicMath.rashis[transRashi].name}',
        effectType: effectData?.type ?? 'neutral',
        sid: sidereal,
      ));
    });

    return transits;
  }
}
