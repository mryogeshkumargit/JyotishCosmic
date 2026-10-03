/// Rule and source registries (Master Knowledge Base v1.0.0; Volume 6 §18-20,
/// §58-59, §104-105).
///
/// SRC01-SRC11 and R001-R015 are taken from the Master Knowledge Base. Entries
/// marked [appAddition] were added for engines the app implements beyond that
/// package. Sources are reference records: the app does not hold verified
/// verse text, so no rule quotes scripture.
class KnowledgeSource {
  final String id;
  final String name;
  final String locator;
  final String description;
  final String classification;
  final bool appAddition;
  const KnowledgeSource(this.id, this.name, this.locator, this.description,
      {this.classification = 'DIRECT_CLASSICAL', this.appAddition = false});

  String get verificationState => 'REFERENCE_RECORD';
}

class KnowledgeRule {
  final String id;
  final String name;
  final String classification;
  final String condition;
  final List<String> sourceIds;
  final int priority;
  final bool appAddition;
  const KnowledgeRule(this.id, this.name, this.classification, this.condition, this.sourceIds,
      {this.priority = 50, this.appAddition = false});
}

/// External repositories referenced by the Master KB as integration sources.
class ExternalReference {
  final String id;
  final String name;
  final String url;
  final String role;
  const ExternalReference(this.id, this.name, this.url, this.role);
}

class KnowledgeRegistry {
  static const String version = '1.0.0';

  static const List<KnowledgeSource> sources = [
    KnowledgeSource('SRC01', 'Phaladeepika', 'Ch. 15', 'Bhava analysis using lord, occupants, aspects, strength and Dasha'),
    KnowledgeSource('SRC02', 'Phaladeepika', 'Ch. 18', 'Planetary conjunctions, including multi-planet combinations'),
    KnowledgeSource('SRC03', 'Phaladeepika', 'Ch. 19-20', 'Dasha and Bhukti interpretation'),
    KnowledgeSource('SRC04', 'Phaladeepika', 'Ch. 20', 'Bhava-lord Dasha/Bhukti results and activation'),
    KnowledgeSource('SRC05', 'Phaladeepika', 'Ch. 15/18', 'Strength, placement and conjunction modifiers'),
    KnowledgeSource('SRC06', 'Phaladeepika', 'transit material', 'Transit activation and Ashtakavarga context'),
    KnowledgeSource('SRC07', 'BPHS', 'Ch. 36', 'Yoga Karakas / Ascendant-specific functional lordship'),
    KnowledgeSource('SRC08', 'BPHS', 'Dasha chapters', 'Dasha results and relationships of house lords'),
    KnowledgeSource('SRC09', 'BPHS', 'Ch. 72', 'Ashtakavarga results'),
    KnowledgeSource('SRC10', 'Brihat Jataka', 'Ch. 14', 'Combination of planets'),
    KnowledgeSource('SRC11', 'Brihat Samhita', 'Ch. 17', 'Planetary conjunctions / Graha Yuddha'),
    KnowledgeSource('SRC12', 'BPHS', 'Yoga chapters (Nabhasa, Chandra, Surya, Raja, Dhana, Daridra, Mahapurusha)', 'Named yoga formation rules', appAddition: true),
    KnowledgeSource('SRC13', 'Phaladeepika', 'Ch. 6-7', 'Yogas, Neecha Bhanga and Raja Yogas', appAddition: true),
    KnowledgeSource('SRC14', 'BPHS', 'Strength chapter (Shadbala, Bhava Bala)', 'Six-fold planetary strength and house strength', appAddition: true),
    KnowledgeSource('SRC15', 'Phaladeepika', 'Ch. 4', 'Six-fold strength, retrogression, planetary war, divisional strength', appAddition: true),
    KnowledgeSource('SRC16', 'Jaimini Upadesa Sutras; BPHS', 'Chara Karaka and Arudha chapters', 'Chara Karakas, Arudha Padas and Upapada', appAddition: true),
    KnowledgeSource('SRC17', 'Saravali', 'Ch. 16-19', 'Three- to six-planet conjunctions', appAddition: true),
    KnowledgeSource('SRC18', 'Jataka Parijata', 'Ch. 8', 'Planetary conjunctions, including 8.23 and 8.26', appAddition: true),
    KnowledgeSource('SRC19', 'Brihat Jataka', 'Ch. 12, 15', 'Nabhasa and Pravrajya yogas', appAddition: true),
    KnowledgeSource('ENG01', 'Conjunction Database Volume 6', '§91, §94', 'Timing-window intersection and birth-time sensitivity',
        classification: 'ENGINEERING_HEURISTIC', appAddition: true),
  ];

  static const List<KnowledgeRule> rules = [
    KnowledgeRule('R001', 'Bhava-lord chain', 'CLASSICAL_DERIVED',
        'Evaluate Bhava -> Bhavesha -> sign -> dispositor -> house -> strength before event synthesis', ['SRC01', 'SRC08'], priority: 90),
    KnowledgeRule('R002', 'Conjunction pair synthesis', 'CLASSICAL_DERIVED',
        'Interpret each conjunction through planet meanings, house placement, sign, dignity, aspects and strength', ['SRC02', 'SRC10'], priority: 80),
    KnowledgeRule('R003', 'Multi-planet graph synthesis', 'SYSTEMATIC_SYNTHESIS',
        'For a cluster, preserve pairwise edges and add cluster-level synthesis; do not collapse it to one pair', ['SRC02'], priority: 80),
    KnowledgeRule('R004', 'Dasha activation', 'CLASSICAL_DERIVED',
        'Use Mahadasha/Antardasha lord relationships, placement and house ownership to activate natal promise', ['SRC03', 'SRC04', 'SRC08'], priority: 50),
    KnowledgeRule('R005', 'Transit confirmation', 'CLASSICAL_DERIVED',
        'Use transit of relevant Dasha/Bhava lords and supporting transit factors as timing confirmation', ['SRC06'], priority: 40),
    KnowledgeRule('R006', 'Ashtakavarga confirmation', 'CLASSICAL_DERIVED',
        'Use Ashtakavarga as a supporting transit/house-strength layer, not as a replacement for natal promise', ['SRC09'], priority: 40),
    KnowledgeRule('R007', 'Varga confirmation', 'SYSTEMATIC_SYNTHESIS',
        'Use relevant Vargas as domain-specific confirmation/modification of the D1 promise', ['SRC01'], priority: 60),
    KnowledgeRule('R008', 'Degree-sensitive conjunction', 'SYSTEMATIC_SYNTHESIS',
        'Use exact separation, applying/separating state and planetary states to modify conjunction strength', ['SRC02'], priority: 80),
    KnowledgeRule('R009', 'Combustion modifier', 'CLASSICAL_DERIVED',
        'Record combustion as a planetary-state modifier before final synthesis', ['SRC05'], priority: 60),
    KnowledgeRule('R010', 'Graha Yuddha modifier', 'CLASSICAL_DERIVED',
        'Record applicable planetary-war conditions and use them as a modifier', ['SRC11'], priority: 60),
    KnowledgeRule('R011', 'Dignity modifier', 'CLASSICAL_DERIVED',
        'Record exaltation/debilitation/Mulatrikona/own/friendly/neutral/enemy contexts as strength modifiers', ['SRC05'], priority: 60),
    KnowledgeRule('R012', 'Functional lordship', 'CLASSICAL_DERIVED',
        'Reinterpret planets by Lagna-specific house ownership before prediction synthesis', ['SRC07'], priority: 90),
    KnowledgeRule('R013', 'Evidence separation', 'ENGINEERING_HEURISTIC',
        'Every conclusion must retain its evidence class and source/rule trace', [], priority: 20),
    KnowledgeRule('R014', 'Prediction dependency graph', 'ENGINEERING_HEURISTIC',
        'Prediction requires linked natal promise, strength, activation and confirmation dependencies', [], priority: 30),
    KnowledgeRule('R015', 'Conflict resolution', 'SYSTEMATIC_SYNTHESIS',
        'When signals conflict, preserve both supporting and opposing evidence rather than forcing a binary result', [], priority: 30),
    KnowledgeRule('R016', 'Named yoga formation and cancellation', 'CLASSICAL_DERIVED',
        'Detect named yogas by their exact formation rule, then apply cancellation and strength modifiers', ['SRC12', 'SRC13', 'SRC19'],
        priority: 70, appAddition: true),
    KnowledgeRule('R017', 'Shadbala', 'CLASSICAL_DERIVED', 'Six-fold planetary strength against the BPHS minimum', ['SRC14', 'SRC15'],
        priority: 60, appAddition: true),
    KnowledgeRule('R018', 'Bhava Bala', 'CLASSICAL_DERIVED', 'House strength from its lord, direction, aspects and occupants', ['SRC14'],
        priority: 60, appAddition: true),
    KnowledgeRule('R019', 'Chara Karakas', 'CONFIGURABLE_TRADITION',
        'Rank planets by degree within the sign (7- or 8-karaka scheme) to find Atmakaraka ... Darakaraka', ['SRC16'],
        priority: 60, appAddition: true),
    KnowledgeRule('R020', 'Arudha and Upapada', 'CLASSICAL_DERIVED',
        'Arudha of a house: as far from its lord as the lord is from the house (10th from it if it falls in the house or the 7th)', ['SRC16'],
        priority: 60, appAddition: true),
    KnowledgeRule('R021', 'Degree-exact transit trigger', 'SYSTEMATIC_SYNTHESIS',
        'A slow planet reaching an exact Parashari aspect point (or conjunction) of a natal factor within the configured orb', ['SRC06'],
        priority: 40, appAddition: true),
    KnowledgeRule('R022', 'Timing-window intersection', 'ENGINEERING_HEURISTIC',
        'Intersect Dasha windows with transit triggers on the same domain factors; the result is a window, not a date', ['ENG01'],
        priority: 30, appAddition: true),
    KnowledgeRule('R023', 'Birth-time sensitivity', 'ENGINEERING_HEURISTIC',
        'Recompute at nearby birth times and report which factors are stable and which change', ['ENG01'],
        priority: 100, appAddition: true),
    KnowledgeRule('R024', 'Varga repetition of a conjunction', 'SYSTEMATIC_SYNTHESIS',
        'A conjunction repeated in D9 or the domain Varga is more significant than an isolated D1 conjunction', ['SRC02', 'SRC15'],
        priority: 60, appAddition: true),
    KnowledgeRule('R025', 'Bhava-sandhi', 'CLASSICAL_DERIVED', 'A planet near a Bhava-sandhi loses effectiveness', ['SRC01'],
        priority: 60, appAddition: true),
    KnowledgeRule('R026', 'Karaka condition', 'CLASSICAL_DERIVED', 'Judge a Bhava together with its natural significator', ['SRC01'],
        priority: 70, appAddition: true),
    KnowledgeRule('R027', 'Direct multi-planet rule', 'DIRECT_CLASSICAL',
        'Consult the exact three- to six-planet conjunction verse before pairwise synthesis (text not held in the app)', ['SRC17', 'SRC18'],
        priority: 80, appAddition: true),
    KnowledgeRule('R028', 'Malefics in Upachaya', 'CLASSICAL_DERIVED', 'Natural malefics in the 3rd, 6th, 10th and 11th give good results', ['SRC01'],
        priority: 70, appAddition: true),
    KnowledgeRule('R029', 'Occupants and aspects of a Bhava', 'CLASSICAL_DERIVED',
        'Benefic occupation or aspect supports a Bhava; malefic occupation or aspect afflicts it', ['SRC01'],
        priority: 70, appAddition: true),
    KnowledgeRule('R030', 'Mahadasha-Antardasha relationship', 'CLASSICAL_DERIVED',
        'An Antardasha lord 6/8/12 from the Mahadasha lord obstructs; Kendra/Trikona positions support', ['SRC08'],
        priority: 50, appAddition: true),
  ];

  static const List<ExternalReference> external = [
    ExternalReference('EXT-JC', 'Jyotisha Corpus', 'https://github.com/maximally0/jyotisha-corpus', 'classical source/rule ingestion'),
    ExternalReference('EXT-SD', 'Sanskrit Documents — Jyotisha', 'https://sanskritdocuments.org/iast/jyotisha/', 'primary Sanskrit text layer'),
    ExternalReference('EXT-HORA', 'Hora', 'https://github.com/amitpandeygit/hora', 'astronomical/calculation reference'),
    ExternalReference('EXT-PJH', 'PyJHora', 'https://github.com/naturalstupid/PyJHora', 'secondary calculation reference'),
    ExternalReference('EXT-AB', 'Astrobot / Jyotish AI', 'https://github.com/imshivraj101/astrobot', 'architecture reference'),
  ];

  static KnowledgeRule rule(String id) => rules.firstWhere((r) => r.id == id);
  static KnowledgeSource source(String id) => sources.firstWhere((s) => s.id == id);

  static String sourceLabel(String id) {
    final s = source(id);
    return '${s.name} ${s.locator}';
  }

  /// Maps an evidence rule locator to its registry rule.
  static String ruleIdFor(String locator) {
    final l = locator.toLowerCase();
    if (l.contains('viparita') || l.contains('yoga') || l.contains('phaladeepika ch. 6') || l.contains('brihat jataka') || l.contains('bphs (')) return 'R016';
    if (l.contains('bhava-lord placement') || l.contains('lord chain')) return 'R001';
    if (l.contains('upachaya')) return 'R028';
    if (l.contains('bhava analysis') || l.contains('graha drishti')) return 'R029';
    if (l.contains('repetition')) return 'R024';
    if (l.contains('conjunction db')) return 'R003';
    if (l.contains('karaka layer')) return 'R026';
    if (l.contains('chara karaka')) return 'R019';
    if (l.contains('upapada') || l.contains('arudha')) return 'R020';
    if (l.contains('shadbala')) return 'R017';
    if (l.contains('bhava bala')) return 'R018';
    if (l.contains('combustion')) return 'R009';
    if (l.contains('sandhi')) return 'R025';
    if (l.contains('war') || l.contains('yuddha') || l.contains('latitude')) return 'R010';
    if (l.contains('vargottama') || l.contains('dignity') || l.contains('ch. 4')) return 'R011';
    if (l.contains('antardasha relationship')) return 'R030';
    if (l.contains('trigger')) return 'R021';
    if (l.contains('window')) return 'R022';
    if (l.contains('sensitivity')) return 'R023';
    if (l.contains('transit')) return 'R005';
    if (l.contains('ashtakavarga')) return 'R006';
    if (l.contains('shodashavarga') || l.contains('varga')) return 'R007';
    if (l.contains('dasha') || l.contains('daśā')) return 'R004';
    return 'R013';
  }

  /// Rule coverage report (Volume 6 §105).
  static Map<String, int> coverage() {
    final ids = {for (final s in sources) s.id};
    return {
      'total_rules': rules.length,
      'enabled_rules': rules.length,
      'rules_without_source': rules.where((r) => r.sourceIds.isEmpty).length,
      'direct_classical_without_source': rules.where((r) => r.classification == 'DIRECT_CLASSICAL' && r.sourceIds.isEmpty).length,
      'orphan_source_references': rules.expand((r) => r.sourceIds).where((s) => !ids.contains(s)).length,
      'sources': sources.length,
    };
  }
}
