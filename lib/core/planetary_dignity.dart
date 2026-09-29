import 'vedic_math.dart';

enum Relationship {
  greatFriend,
  friend,
  neutral,
  enemy,
  greatEnemy,
}

class PlanetaryDignity {
  // Natural Relationships (Naisargika Maitri)
  // Maps a planet to its relationships with other planets
  static const Map<String, Map<String, Relationship>> naturalRelationships = {
    'sun': {
      'moon': Relationship.friend, 'mars': Relationship.friend, 'jupiter': Relationship.friend,
      'mercury': Relationship.neutral,
      'venus': Relationship.enemy, 'saturn': Relationship.enemy, 'rahu': Relationship.enemy, 'ketu': Relationship.enemy,
    },
    'moon': {
      'sun': Relationship.friend, 'mercury': Relationship.friend,
      'mars': Relationship.neutral, 'jupiter': Relationship.neutral, 'venus': Relationship.neutral, 'saturn': Relationship.neutral,
      'rahu': Relationship.enemy, 'ketu': Relationship.enemy,
    },
    'mars': {
      'sun': Relationship.friend, 'moon': Relationship.friend, 'jupiter': Relationship.friend,
      'venus': Relationship.neutral, 'saturn': Relationship.neutral,
      'mercury': Relationship.enemy, 'rahu': Relationship.enemy, 'ketu': Relationship.enemy,
    },
    'mercury': {
      'sun': Relationship.friend, 'venus': Relationship.friend,
      'mars': Relationship.neutral, 'jupiter': Relationship.neutral, 'saturn': Relationship.neutral,
      'moon': Relationship.enemy, 'rahu': Relationship.neutral, 'ketu': Relationship.neutral,
    },
    'jupiter': {
      'sun': Relationship.friend, 'moon': Relationship.friend, 'mars': Relationship.friend,
      'saturn': Relationship.neutral, 'rahu': Relationship.neutral, 'ketu': Relationship.neutral,
      'mercury': Relationship.enemy, 'venus': Relationship.enemy,
    },
    'venus': {
      'mercury': Relationship.friend, 'saturn': Relationship.friend,
      'mars': Relationship.neutral, 'jupiter': Relationship.neutral,
      'sun': Relationship.enemy, 'moon': Relationship.enemy, 'rahu': Relationship.friend, 'ketu': Relationship.friend,
    },
    'saturn': {
      'mercury': Relationship.friend, 'venus': Relationship.friend,
      'jupiter': Relationship.neutral,
      'sun': Relationship.enemy, 'moon': Relationship.enemy, 'mars': Relationship.enemy, 'rahu': Relationship.friend, 'ketu': Relationship.friend,
    },
    // Rahu and Ketu natural relationships are often treated similarly to Saturn or Mars
    'rahu': {
      'venus': Relationship.friend, 'saturn': Relationship.friend,
      'mercury': Relationship.neutral, 'jupiter': Relationship.neutral,
      'sun': Relationship.enemy, 'moon': Relationship.enemy, 'mars': Relationship.enemy, 'ketu': Relationship.enemy,
    },
    'ketu': {
      'mars': Relationship.friend, 'venus': Relationship.friend,
      'mercury': Relationship.neutral, 'jupiter': Relationship.neutral, 'saturn': Relationship.neutral,
      'sun': Relationship.enemy, 'moon': Relationship.enemy, 'rahu': Relationship.enemy,
    },
  };

  /// Returns the natural relationship of 'planetA' towards 'planetB'.
  static Relationship getNaturalRelationship(String planetA, String planetB) {
    if (planetA == planetB) return Relationship.neutral; // Self
    return naturalRelationships[planetA]?[planetB] ?? Relationship.neutral;
  }

  /// Calculates the temporal relationship (Tatkalika Maitri)
  /// Planets in the 2nd, 3rd, 4th, 10th, 11th, and 12th houses from a planet are its temporary friends.
  /// Planets in the 1st, 5th, 6th, 7th, 8th, and 9th houses are temporary enemies.
  static Relationship getTemporalRelationship(int rashiA, int rashiB) {
    if (rashiA == rashiB) return Relationship.enemy; // Same house (1st)
    int distance = ((rashiB - rashiA + 12) % 12) + 1; // 1-based house distance
    if ([2, 3, 4, 10, 11, 12].contains(distance)) {
      return Relationship.friend;
    } else {
      return Relationship.enemy;
    }
  }

  /// Calculates the compound relationship (Panchadha Maitri)
  static Relationship getCompoundRelationship(String planetA, int rashiA, String planetB, int rashiB) {
    if (planetA == planetB) return Relationship.neutral;

    Relationship natural = getNaturalRelationship(planetA, planetB);
    Relationship temporal = getTemporalRelationship(rashiA, rashiB);

    if (natural == Relationship.friend && temporal == Relationship.friend) {
      return Relationship.greatFriend;
    } else if ((natural == Relationship.friend && temporal == Relationship.enemy) ||
               (natural == Relationship.enemy && temporal == Relationship.friend)) {
      return Relationship.neutral;
    } else if (natural == Relationship.neutral && temporal == Relationship.friend) {
      return Relationship.friend;
    } else if (natural == Relationship.neutral && temporal == Relationship.enemy) {
      return Relationship.enemy;
    } else if (natural == Relationship.enemy && temporal == Relationship.enemy) {
      return Relationship.greatEnemy;
    }
    
    return Relationship.neutral;
  }

  // Moolatrikona signs and degree ranges [sign, fromDeg, toDeg).
  static const Map<String, int> moolatrikonaSigns = {
    'sun': 4, // Leo 0-20
    'moon': 1, // Taurus 3-30
    'mars': 0, // Aries 0-12
    'mercury': 5, // Virgo 15-20
    'jupiter': 8, // Sagittarius 0-10
    'venus': 6, // Libra 0-15
    'saturn': 10, // Aquarius 0-20
  };

  static const Map<String, List<double>> moolatrikonaRange = {
    'sun': [0, 20],
    'moon': [3, 30],
    'mars': [0, 12],
    'mercury': [15, 20],
    'jupiter': [0, 10],
    'venus': [0, 15],
    'saturn': [0, 20],
  };

  /// Dignity from sign placement (and degree, when given) plus compound relationship with
  /// the sign's lord. [allPlanetRashis] are 0-based sign indices of all planets.
  static String getAdvancedDignity(String planet, int rashiIndex, Map<String, int> allPlanetRashis,
      {double? degree}) {
    final p = VedicMath.planets[planet];
    if (p == null) return 'Neutral';

    // Signs where exaltation overlaps other dignities are resolved by degree.
    if (degree != null) {
      if (planet == 'moon' && rashiIndex == 1) return degree < 3 ? 'Exalted' : 'Moolatrikona';
      if (planet == 'mercury' && rashiIndex == 5) {
        if (degree < 15) return 'Exalted';
        if (degree < 20) return 'Moolatrikona';
        return 'Own Sign';
      }
    }

    if (p.exalt == rashiIndex) return 'Exalted';
    if (p.debi == rashiIndex) return 'Debilitated';

    if (moolatrikonaSigns[planet] == rashiIndex) {
      final range = moolatrikonaRange[planet]!;
      if (degree == null || (degree >= range[0] && degree < range[1])) return 'Moolatrikona';
      return 'Own Sign';
    }

    if (p.ownSigns.contains(rashiIndex)) return 'Own Sign';

    final dispositor = VedicMath.rashis[rashiIndex].lord;
    if (dispositor == planet) return 'Own Sign';

    if (allPlanetRashis.containsKey(dispositor)) {
      final dispositorRashi = allPlanetRashis[dispositor]!;
      final compoundRel = getCompoundRelationship(planet, rashiIndex, dispositor, dispositorRashi);
      switch (compoundRel) {
        case Relationship.greatFriend:
          return 'Great Friend\'s Sign';
        case Relationship.friend:
          return 'Friend\'s Sign';
        case Relationship.neutral:
          return 'Neutral Sign';
        case Relationship.enemy:
          return 'Enemy\'s Sign';
        case Relationship.greatEnemy:
          return 'Great Enemy\'s Sign';
      }
    }

    final naturalRel = getNaturalRelationship(planet, dispositor);
    if (naturalRel == Relationship.friend) return 'Friend\'s Sign';
    if (naturalRel == Relationship.enemy) return 'Enemy\'s Sign';
    return 'Neutral Sign';
  }
}
