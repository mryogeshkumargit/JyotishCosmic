import 'vedic_math.dart';

class Aspect {
  final String aspectingPlanet;
  final int aspectedHouse; // 1-based index (1-12)
  final String type; // 'full', 'special'

  Aspect(this.aspectingPlanet, this.aspectedHouse, this.type);
}

class PlanetaryAspects {
  /// Returns a map where key is the aspecting planet and value is a list of houses (1-12, from Lagna) it aspects.
  static Map<String, List<int>> calculateAllAspects(Map<String, int> planetRashis, int lagnaRashi) {
    Map<String, List<int>> aspects = {};

    planetRashis.forEach((planet, rashiIndex) {
      int planetHouse = VedicMath.houseOf(rashiIndex, lagnaRashi);
      List<int> aspectedHouses = [];

      // Every planet aspects the 7th house from itself
      aspectedHouses.add(_addHouses(planetHouse, 7));

      // Special Aspects
      if (planet == 'mars') {
        aspectedHouses.add(_addHouses(planetHouse, 4));
        aspectedHouses.add(_addHouses(planetHouse, 8));
      } else if (planet == 'jupiter') {
        aspectedHouses.add(_addHouses(planetHouse, 5));
        aspectedHouses.add(_addHouses(planetHouse, 9));
      } else if (planet == 'saturn') {
        aspectedHouses.add(_addHouses(planetHouse, 3));
        aspectedHouses.add(_addHouses(planetHouse, 10));
      } else if (planet == 'rahu' || planet == 'ketu') {
        aspectedHouses.add(_addHouses(planetHouse, 5));
        aspectedHouses.add(_addHouses(planetHouse, 9));
      }

      aspects[planet] = aspectedHouses.toSet().toList(); // Remove duplicates if any
    });

    return aspects;
  }

  /// Helper to add offset to a house and wrap around 1-12
  static int _addHouses(int startHouse, int offset) {
    return ((startHouse - 1 + offset - 1) % 12) + 1;
  }

  /// Checks if planetA aspects planetB
  static bool isAspecting(String aspectingPlanet, String aspectedPlanet, Map<String, int> planetRashis, int lagnaRashi) {
    if (!planetRashis.containsKey(aspectingPlanet) || !planetRashis.containsKey(aspectedPlanet)) return false;

    var aspects = calculateAllAspects(planetRashis, lagnaRashi);
    int targetHouse = VedicMath.houseOf(planetRashis[aspectedPlanet]!, lagnaRashi);

    return aspects[aspectingPlanet]?.contains(targetHouse) ?? false;
  }

  /// Checks if two planets aspect each other mutually
  static bool hasMutualAspect(String planetA, String planetB, Map<String, int> planetRashis, int lagnaRashi) {
    return isAspecting(planetA, planetB, planetRashis, lagnaRashi) &&
           isAspecting(planetB, planetA, planetRashis, lagnaRashi);
  }

  /// Gets all planets aspecting a specific house
  static List<String> getPlanetsAspectingHouse(int targetHouse, Map<String, int> planetRashis, int lagnaRashi) {
    var aspects = calculateAllAspects(planetRashis, lagnaRashi);
    List<String> aspectingPlanets = [];

    aspects.forEach((planet, houses) {
      if (houses.contains(targetHouse)) {
        aspectingPlanets.add(planet);
      }
    });

    return aspectingPlanets;
  }
}
