/// Calculation conventions where Jyotisha traditions differ (Volume 4 §25).
///
/// Every engine that depends on one of these choices takes a [CalcConfig] and
/// reports the values it used, so two users with different settings can see
/// why their results differ.
enum NodeAspectRule {
  /// Rahu and Ketu cast no aspects.
  none,

  /// Only the 7th-house aspect.
  seventh,

  /// 5th, 7th and 9th (the convention used elsewhere in this app).
  fiveSevenNine,
}

enum WarRule {
  /// The planet with the more northern ecliptic latitude wins (Surya Siddhanta; BPHS).
  northernLatitude,

  /// Venus wins whether north or south; otherwise the more northern planet wins (Brihat Samhita).
  venusAlwaysWins,
}

class CalcConfig {
  static const String engineVersion = '6.0.0';
  static const String ruleSetVersion = 'jyotisha-rules-1.0.0';

  final NodeAspectRule nodeAspects;
  final WarRule warRule;

  /// Maximum separation (degrees) for Graha Yuddha.
  final double warOrb;

  /// Separation (degrees) below which a conjunction is called "close".
  final double closeConjunctionOrb;

  /// Fraction of the combustion orb inside which a planet is "deeply" combust.
  final double deepCombustionFraction;

  /// A planet is stationary when |speed| is below this fraction of its mean motion.
  final double stationaryFraction;

  /// Degrees around a Bhava-sandhi (equal houses from the ascendant) treated as weak.
  final double sandhiOrb;

  /// Sidereal mode code (see Ephemeris.ayanamsaModes).
  final String ayanamsa;

  /// True (osculating) instead of mean lunar node.
  final bool trueNode;

  /// Days per Vimshottari year.
  final double dashaYearDays;

  /// Jaimini Chara Karaka scheme: 7 (Sun-Saturn) or 8 (including Rahu).
  final int karakaScheme;

  /// Orb (degrees) for degree-exact transit triggers.
  final double transitOrb;

  const CalcConfig({
    this.nodeAspects = NodeAspectRule.fiveSevenNine,
    this.warRule = WarRule.northernLatitude,
    this.warOrb = 1.0,
    this.closeConjunctionOrb = 5.0,
    this.deepCombustionFraction = 0.5,
    this.stationaryFraction = 0.1,
    this.sandhiOrb = 1.0,
    this.ayanamsa = 'LAHIRI',
    this.trueNode = false,
    this.dashaYearDays = 365.25,
    this.karakaScheme = 8,
    this.transitOrb = 2.0,
  });

  static const CalcConfig defaults = CalcConfig();

  /// Working combustion orbs (degrees from the Sun) and retrograde variants.
  static const Map<String, double> combustionOrbs = {
    'moon': 12, 'mars': 17, 'mercury': 14, 'jupiter': 11, 'venus': 10, 'saturn': 15,
  };
  static const Map<String, double> retrogradeCombustionOrbs = {'mercury': 12, 'venus': 8};

  CalcConfig copyWith({
    NodeAspectRule? nodeAspects,
    WarRule? warRule,
    double? warOrb,
    double? closeConjunctionOrb,
    double? deepCombustionFraction,
    double? stationaryFraction,
    double? sandhiOrb,
    String? ayanamsa,
    bool? trueNode,
    double? dashaYearDays,
    int? karakaScheme,
    double? transitOrb,
  }) =>
      CalcConfig(
        nodeAspects: nodeAspects ?? this.nodeAspects,
        warRule: warRule ?? this.warRule,
        warOrb: warOrb ?? this.warOrb,
        closeConjunctionOrb: closeConjunctionOrb ?? this.closeConjunctionOrb,
        deepCombustionFraction: deepCombustionFraction ?? this.deepCombustionFraction,
        stationaryFraction: stationaryFraction ?? this.stationaryFraction,
        sandhiOrb: sandhiOrb ?? this.sandhiOrb,
        ayanamsa: ayanamsa ?? this.ayanamsa,
        trueNode: trueNode ?? this.trueNode,
        dashaYearDays: dashaYearDays ?? this.dashaYearDays,
        karakaScheme: karakaScheme ?? this.karakaScheme,
        transitOrb: transitOrb ?? this.transitOrb,
      );

  String get nodeAspectLabel => switch (nodeAspects) {
        NodeAspectRule.none => 'Rahu/Ketu cast no aspect',
        NodeAspectRule.seventh => 'Rahu/Ketu aspect the 7th only',
        NodeAspectRule.fiveSevenNine => 'Rahu/Ketu aspect the 5th, 7th and 9th',
      };

  String get warRuleLabel => switch (warRule) {
        WarRule.northernLatitude => 'More northern latitude wins (Surya Siddhanta / BPHS)',
        WarRule.venusAlwaysWins => 'Venus always wins, otherwise northern latitude (Brihat Samhita)',
      };

  /// Rule versions for the audit log.
  Map<String, String> get ruleVersions => {
        'engine_version': engineVersion,
        'rule_set_version': ruleSetVersion,
        'zodiac': 'SIDEREAL',
        'ayanamsha_code': ayanamsa,
        'node_mode': trueNode ? 'TRUE_NODE' : 'MEAN_NODE',
        'dasha_system': 'VIMSHOTTARI',
        'dasha_year_basis': dashaYearDays.toString(),
        'chara_karaka_scheme': '$karakaScheme karakas${karakaScheme == 8 ? ' (Rahu counted from the end of its sign)' : ''}',
        'transit_trigger_orb': '${transitOrb.toStringAsFixed(1)}°',
        'aspect_school': 'Parashari graha drishti (7th all; Mars 4/8, Jupiter 5/9, Saturn 3/10); sputa drishti per BPHS',
        'node_aspects': nodeAspectLabel,
        'combustion_orb_table': 'Moon 12, Mars 17, Mercury 14 (12 retro), Jupiter 11, Venus 10 (8 retro), Saturn 15; deep = ${(deepCombustionFraction * 100).round()}% of orb',
        'planetary_war_rule': '$warRuleLabel; orb ${warOrb.toStringAsFixed(1)}°; Mars, Mercury, Jupiter, Venus, Saturn',
        'close_conjunction_orb': '${closeConjunctionOrb.toStringAsFixed(1)}°',
        'varga_school': 'Parashari Shodashavarga (BPHS)',
        'house_system': 'Whole-sign houses; Bhava-sandhi from equal houses on the ascendant degree (±${sandhiOrb.toStringAsFixed(1)}°)',
        'stationary_tolerance': '${(stationaryFraction * 100).round()}% of mean daily motion',
      };
}
