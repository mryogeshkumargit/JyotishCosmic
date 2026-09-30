import 'ephemeris.dart';
import 'doshas_math.dart';

class RemedyResult {
  final String title;
  final String description;
  final String type; // 'gemstone', 'mantra', 'charity', 'dosha'
  final String planetOrDosha;

  RemedyResult({
    required this.title,
    required this.description,
    required this.type,
    required this.planetOrDosha,
  });
}

class RemediesMath {
  static final Map<int, String> _signLords = {
    1: 'mars', 2: 'venus', 3: 'mercury', 4: 'moon',
    5: 'sun', 6: 'mercury', 7: 'venus', 8: 'mars',
    9: 'jupiter', 10: 'saturn', 11: 'saturn', 12: 'jupiter'
  };

  static final Map<String, Map<String, String>> _planetRemedies = {
    'sun': {
      'gem': 'Ruby (Manik)',
      'gem_desc': 'Wear in Gold on the ring finger on Sunday morning.',
      'mantra': 'Om Hraam Hreem Hraum Sah Suryaya Namah',
      'charity': 'Donate wheat, jaggery, and copper on Sundays.'
    },
    'moon': {
      'gem': 'Pearl (Moti)',
      'gem_desc': 'Wear in Silver on the little finger on Monday evening.',
      'mantra': 'Om Shraam Shreem Shraum Sah Chandraya Namah',
      'charity': 'Donate milk, rice, and white clothes on Mondays.'
    },
    'mars': {
      'gem': 'Red Coral (Moonga)',
      'gem_desc': 'Wear in Gold or Copper on the ring finger on Tuesday morning.',
      'mantra': 'Om Kraam Kreem Kraum Sah Bhaumaya Namah',
      'charity': 'Donate red lentils (masoor dal) and jaggery on Tuesdays.'
    },
    'mercury': {
      'gem': 'Emerald (Panna)',
      'gem_desc': 'Wear in Gold or Silver on the little finger on Wednesday morning.',
      'mantra': 'Om Braam Breem Braum Sah Budhaya Namah',
      'charity': 'Donate green moong dal and green clothes on Wednesdays.'
    },
    'jupiter': {
      'gem': 'Yellow Sapphire (Pukhraj)',
      'gem_desc': 'Wear in Gold on the index finger on Thursday morning.',
      'mantra': 'Om Graam Greem Graum Sah Gurave Namah',
      'charity': 'Donate chana dal, turmeric, and yellow clothes on Thursdays.'
    },
    'venus': {
      'gem': 'Diamond (Heera) or White Sapphire',
      'gem_desc': 'Wear in Gold or Platinum on the middle or little finger on Friday morning.',
      'mantra': 'Om Draam Dreem Draum Sah Shukraya Namah',
      'charity': 'Donate sugar, rice, and white sweets to young girls on Fridays.'
    },
    'saturn': {
      'gem': 'Blue Sapphire (Neelam)',
      'gem_desc': 'Wear in Silver or Panchadhatu on the middle finger on Saturday evening.',
      'mantra': 'Om Praam Preem Praum Sah Shanaishcharaya Namah',
      'charity': 'Donate mustard oil, black sesame seeds, and black clothes on Saturdays.'
    },
  };

  static List<RemedyResult> compute(ChartData chart) {
    List<RemedyResult> remedies = [];
    int ascendantSign = chart.lagnaRashi + 1; // 1-based (1 = Aries) for _signLords
    final int lagnaRashi = chart.lagnaRashi; // 0-based for dosha calculations
    final String lagnaLord = _signLords[ascendantSign]!;

    // 1. Gemstones for Functional Benefics (Lords of 1, 5, 9 houses)
    List<int> beneficHouses = [1, 5, 9];
    Set<String> beneficPlanets = {};

    for (int house in beneficHouses) {
      int sign = ((ascendantSign + house - 2) % 12) + 1;
      String lord = _signLords[sign]!;
      beneficPlanets.add(lord);
    }

    for (String planet in beneficPlanets) {
      if (_planetRemedies.containsKey(planet)) {
        remedies.add(RemedyResult(
          title: _planetRemedies[planet]!['gem']!,
          description: _planetRemedies[planet]!['gem_desc']!,
          type: 'gemstone',
          planetOrDosha: planet,
        ));
      }
    }

    // 2. Pacification for Functional Malefics (Lords of 3, 6, 8, 12 houses)
    List<int> maleficHouses = [3, 6, 8, 12];
    Set<String> maleficPlanets = {};

    for (int house in maleficHouses) {
      int sign = ((ascendantSign + house - 2) % 12) + 1;
      String lord = _signLords[sign]!;
      // A planet can own both a benefic and a malefic house (e.g. Venus for Gemini
      // Ascendant owns the 5th and 12th). Planets that also own a trine (including
      // the Lagna lord) are treated as benefic and are not pacified.
      if (lord != lagnaLord && !beneficPlanets.contains(lord)) {
        maleficPlanets.add(lord);
      }
    }

    // Add Rahu and Ketu to pacification as natural malefics always needing pacification in most general charts
    maleficPlanets.addAll(['rahu', 'ketu']);

    Map<String, Map<String, String>> rahuKetuRemedies = {
      'rahu': {
        'mantra': 'Om Bhraam Bhreem Bhraum Sah Rahave Namah',
        'charity': 'Donate black/blue clothes, mustard, and feed black dogs on Saturdays.'
      },
      'ketu': {
        'mantra': 'Om Sraam Sreem Sraum Sah Ketave Namah',
        'charity': 'Donate black and white blankets, and feed stray dogs on Tuesdays.'
      }
    };

    for (String planet in maleficPlanets) {
      if (_planetRemedies.containsKey(planet)) {
        String mantra = _planetRemedies[planet]!['mantra']!;
        String charity = _planetRemedies[planet]!['charity']!;
        remedies.add(RemedyResult(
          title: '${planet[0].toUpperCase()}${planet.substring(1)} Pacification',
          description: 'Mantra: $mantra\nCharity: $charity',
          type: 'charity',
          planetOrDosha: planet,
        ));
      } else if (rahuKetuRemedies.containsKey(planet)) {
        String mantra = rahuKetuRemedies[planet]!['mantra']!;
        String charity = rahuKetuRemedies[planet]!['charity']!;
         remedies.add(RemedyResult(
          title: '${planet[0].toUpperCase()}${planet.substring(1)} Pacification',
          description: 'Mantra: $mantra\nCharity: $charity',
          type: 'charity',
          planetOrDosha: planet,
        ));
      }
    }

    // 3. Dosha Remedies
    List<DoshaResult> presentDoshas = [];
    
    var manglik = DoshasMath.computeManglik(chart.planetLongitudes, lagnaRashi);
    if (manglik != null && manglik.present) presentDoshas.add(manglik);

    var kaalsarp = DoshasMath.computeKaalSarp(chart.planetLongitudes, lagnaRashi);
    if (kaalsarp != null && kaalsarp.present) presentDoshas.add(kaalsarp);

    if (chart.planetLongitudes.containsKey('moon')) {
      // Sade Sati depends on the *current* (transit) Saturn relative to the natal Moon.
      int moonRashi = (chart.planetLongitudes['moon']! / 30).floor();
      int saturnRashi = (Ephemeris.siderealLongitude('saturn', Ephemeris.nowJd()) / 30).floor();
      var sadesati = DoshasMath.computeSadesati(moonRashi, saturnRashi);
      if (sadesati.present) presentDoshas.add(sadesati);
    }

    var pitru = DoshasMath.computePitruDosha(chart.planetLongitudes, lagnaRashi);
    if (pitru.present) presentDoshas.add(pitru);

    var grahan = DoshasMath.computeGrahanDosha(chart.planetLongitudes);
    if (grahan.present) presentDoshas.add(grahan);

    var guruChandal = DoshasMath.computeGuruChandalDosha(chart.planetLongitudes);
    if (guruChandal.present) presentDoshas.add(guruChandal);

    var kemadruma = DoshasMath.computeKemadrumaDosha(chart.planetLongitudes);
    if (kemadruma.present) presentDoshas.add(kemadruma);

    for (var dosha in presentDoshas) {
      String doshaRemedy = dosha.remedies.join('\n• ');
      if (doshaRemedy.isNotEmpty) doshaRemedy = '• $doshaRemedy';

      remedies.add(RemedyResult(
        title: '${dosha.name} Remedy',
        description: doshaRemedy,
        type: 'dosha',
        planetOrDosha: dosha.name,
      ));
    }

    return remedies;
  }
}
