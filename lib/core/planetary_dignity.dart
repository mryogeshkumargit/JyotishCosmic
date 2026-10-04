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

  // Moolatrikona Signs
  static const Map<String, int> moolatrikonaSigns = {
    'sun': 4, // Leo
    'moon': 1, // Taurus
    'mars': 0, // Aries
    'mercury': 5, // Virgo
    'jupiter': 8, // Sagittarius
    'venus': 6, // Libra
    'saturn': 10, // Aquarius
  };

  /// Moolatrikona degree ranges within the sign (Volume 4 §8; BPHS).
  static const Map<String, (double, double)> moolatrikonaRanges = {
    'sun': (0, 20), 'moon': (3, 30), 'mars': (0, 12), 'mercury': (15, 20),
    'jupiter': (0, 10), 'venus': (0, 15), 'saturn': (0, 20),
  };

  /// Deep exaltation points (sidereal longitude); debilitation is 180° away.
  static const Map<String, double> deepExaltation = {
    'sun': 10, 'moon': 33, 'mars': 298, 'mercury': 165, 'jupiter': 95, 'venus': 357, 'saturn': 200,
  };

  /// Returns a rich dignity string for the planet based on its sign placement and relations.
  ///
  /// When [degree] (0-30 within the sign) is given, the degree ranges apply:
  /// the Moon is exalted in Taurus 0-3° and Moolatrikona after; Mercury is
  /// exalted in Virgo 0-15°, Moolatrikona 15-20° and in its own sign after;
  /// each Moolatrikona sign is "own sign" outside its Moolatrikona range.
  static String getAdvancedDignity(String planet, int rashiIndex, Map<String, int> allPlanetRashis, {double? degree}) {
    final p = VedicMath.planets[planet];
    if (p == null) return 'Neutral';
    final mt = moolatrikonaSigns[planet];
    final range = moolatrikonaRanges[planet];

    if (degree != null && mt == rashiIndex && range != null) {
      // Exaltation and Moolatrikona share a sign for the Moon and Mercury.
      if (p.exalt == rashiIndex && degree < range.$1) return 'Exalted';
      if (degree >= range.$1 && degree < range.$2) return 'Moolatrikona';
      return 'Own Sign';
    }

    // 1. Exaltation / Debilitation
    if (p.exalt == rashiIndex) return 'Exalted';
    if (p.debi == rashiIndex) return 'Debilitated';

    // 2. Moolatrikona
    if (mt == rashiIndex) return 'Moolatrikona';

    // 3. Own Sign
    if (p.ownSigns.contains(rashiIndex)) return 'Own Sign';

    // 4. Determine relationship with the dispositor (lord of the current rashi)
    String dispositor = VedicMath.rashis[rashiIndex].lord;
    if (dispositor == planet) return 'Own Sign'; // Fallback just in case

    if (allPlanetRashis.containsKey(dispositor)) {
      int dispositorRashi = allPlanetRashis[dispositor]!;
      Relationship compoundRel = getCompoundRelationship(planet, rashiIndex, dispositor, dispositorRashi);
      
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

    // If dispositor position is somehow missing (shouldn't happen for the 7 classical planets)
    Relationship naturalRel = getNaturalRelationship(planet, dispositor);
    if (naturalRel == Relationship.friend) return 'Friend\'s Sign';
    if (naturalRel == Relationship.enemy) return 'Enemy\'s Sign';
    return 'Neutral Sign';
  }
}
