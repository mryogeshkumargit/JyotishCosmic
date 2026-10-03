import 'calc_config.dart';
import 'ephemeris.dart';
import 'precision_math.dart';
import 'vedic_math.dart';
import 'yogas_math.dart';

/// One record of the Conjunction Database (Volumes 2 and 3): a cluster of
/// 2-7 classical planets in a given Bhava and Rashi.
///
/// The 17,280 records (120 clusters x 12 Bhavas x 12 Rashis) are generated
/// from the dictionaries below exactly as the database volumes define them,
/// so they are computed on demand instead of being stored.
class ConjunctionRecord {
  final String recordId;
  final String clusterId;
  final List<String> planets;
  final int bhava;
  final int rashi;
  final int derivedLagna;

  const ConjunctionRecord(this.recordId, this.clusterId, this.planets, this.bhava, this.rashi, this.derivedLagna);

  int get size => planets.length;
  String get dispositor => VedicMath.rashis[rashi].lord;
  String get element => ConjunctionDb.element(rashi);
  String get modality => ConjunctionDb.modality(rashi);
  List<(String, String)> get pairs => ConjunctionDb.pairsOf(planets);
  String get sourceTier => ConjunctionDb.sourceTier(size);
  String get directSource => ConjunctionDb.directSource(size);
  String get clusterLabel => planets.map(ConjunctionDb.planetName).join(' + ');

  /// Houses owned by each planet for the derived (whole-sign) Lagna.
  Map<String, List<int>> get functionalLordship => {for (final p in planets) p: ConjunctionDb.housesOwned(p, derivedLagna)};

  String get functionalLordshipText => planets
      .map((p) => '${ConjunctionDb.planetName(p)}: ${functionalLordship[p]!.join(',')} '
          '(${functionalLordship[p]!.map((h) => ConjunctionDb.houseClass[h]).join('; ')})')
      .join(' | ');

  String get pairwiseText => pairs.map((p) => '${ConjunctionDb.planetName(p.$1)}-${ConjunctionDb.planetName(p.$2)}').join('; ');

  String get coreThemes => planets.map((p) => ConjunctionDb.planetThemes[p]!).join('; ');

  String get bhavaInteraction => 'The cluster concentrates its combined planetary significations into the ${ConjunctionDb.bhavaNames[bhava - 1]} domain.';

  String get rashiInteraction => 'The ${VedicMath.rashis[rashi].name} environment modifies expression through '
      '${element.toLowerCase()} element, ${modality.toLowerCase()} modality, and ${ConjunctionDb.planetName(dispositor)} as dispositor.';

  static const String interpretiveRule =
      'Do not read this record in isolation. First check any exact classical multi-planet rule for the cluster; then integrate '
      'the pairwise rules; then apply Lagna lordship, dignity, dispositor, aspects, strength, Vargas and timing.';

  /// Volume 2 pair texts for this placement (pair x Bhava, pair x Rashi, pair x Lagna).
  List<({String id, String pair, String bhava, String rashi, String lagna})> pairTexts() => [
        for (final (a, b) in pairs)
          (
            id: ConjunctionDb.pairId(a, b),
            pair: '${ConjunctionDb.planetName(a)}–${ConjunctionDb.planetName(b)}',
            bhava: ConjunctionDb.pairBhavaText(a, b, bhava),
            rashi: ConjunctionDb.pairRashiText(a, b, rashi),
            lagna: ConjunctionDb.pairLagnaText(a, b, derivedLagna),
          ),
      ];

  Map<String, Object?> toJson() => {
        'record_id': recordId,
        'cluster_id': clusterId,
        'cluster_size': size,
        'planets': planets.map(ConjunctionDb.planetName).toList(),
        'bhava': bhava,
        'rashi': VedicMath.rashis[rashi].name,
        'dispositor': ConjunctionDb.planetName(dispositor),
        'derived_lagna': VedicMath.rashis[derivedLagna].name,
        'element': element,
        'modality': modality,
        'pairwise': pairs.map((p) => '${ConjunctionDb.planetName(p.$1)}-${ConjunctionDb.planetName(p.$2)}').toList(),
        'functional_lordship': {for (final e in functionalLordship.entries) ConjunctionDb.planetName(e.key): e.value},
        'source_tier': sourceTier,
        'synthesis': {
          'bhava_theme': ConjunctionDb.bhavaDomains[bhava - 1],
          'sign_modifier': '$element/$modality/${ConjunctionDb.planetName(dispositor)} dispositor',
        },
      };
}

class ConjunctionDb {
  /// Canonical planet order (Volume 3 §4).
  static const List<String> classical = ['sun', 'moon', 'mars', 'mercury', 'jupiter', 'venus', 'saturn'];

  static const Map<String, String> planetThemes = {
    'sun': 'identity, authority, vitality, status',
    'moon': 'mind, emotion, nourishment, adaptability',
    'mars': 'action, courage, initiative, conflict',
    'mercury': 'intellect, speech, analysis, commerce',
    'jupiter': 'wisdom, learning, expansion, counsel',
    'venus': 'relationships, pleasure, art, values',
    'saturn': 'discipline, duty, delay, structure, endurance',
  };

  /// Base interaction of the 21 canonical pairs (Volume 2 §2), keyed "a-b" in canonical order.
  static const Map<String, String> pairThemes = {
    'sun-moon': 'will/identity + mind/feeling',
    'sun-mars': 'authority + action/courage',
    'sun-mercury': 'authority + intellect/communication',
    'sun-jupiter': 'authority + wisdom/learning',
    'sun-venus': 'authority + aesthetics/relationships',
    'sun-saturn': 'authority + duty/structure',
    'moon-mars': 'emotion + action/enterprise',
    'moon-mercury': 'mind + intellect/communication',
    'moon-jupiter': 'mind + wisdom/nurturing',
    'moon-venus': 'mind + pleasure/aesthetics',
    'moon-saturn': 'mind + restraint/duty',
    'mars-mercury': 'action + intellect/strategy',
    'mars-jupiter': 'action + wisdom/leadership',
    'mars-venus': 'action + desire/creativity',
    'mars-saturn': 'force + restraint/endurance',
    'mercury-jupiter': 'intellect + wisdom/synthesis',
    'mercury-venus': 'intellect + aesthetics/commerce',
    'mercury-saturn': 'intellect + structure/systems',
    'jupiter-venus': 'wisdom + pleasure/values',
    'jupiter-saturn': 'expansion + structure',
    'venus-saturn': 'pleasure + discipline/craft',
  };

  static const List<String> bhavaNames = [
    'Tanu', 'Dhana', 'Sahaja', 'Sukha', 'Putra', 'Ari', 'Yuvati', 'Randhra', 'Dharma', 'Karma', 'Labha', 'Vyaya',
  ];

  /// Bhava domains (Volume 3 §7).
  static const List<String> bhavaDomains = [
    'identity, body, temperament, self-direction',
    'speech, family, resources, food, values',
    'courage, skills, communication, initiative, younger siblings',
    'home, mother, property, vehicles, education, inner security',
    'intelligence, creativity, children, learning, speculation',
    'service, competition, debts, enemies, routines, health',
    'marriage, partnerships, contracts, clients, public interaction',
    'transformation, longevity, inheritance, joint resources, research',
    'fortune, father, guru, higher learning, ethics, pilgrimage',
    'profession, authority, reputation, visible action',
    'gains, networks, income, elder siblings, ambitions',
    'expenditure, foreign places, retreat, sleep, release, privacy',
  ];

  /// Bhava domains as worded in Volume 2 §4.
  static const List<String> bhavaDomainsV2 = [
    'identity, body, temperament, self-direction',
    'speech, family, accumulated resources, food and values',
    'courage, skills, communication, initiative and younger siblings',
    'home, mother, property, vehicles, education and inner security',
    'intelligence, creativity, children, learning and speculation',
    'service, competition, debts, enemies, routines and health',
    'marriage, partnerships, contracts, clients and public interaction',
    'transformation, longevity, inheritance, joint resources and research',
    'fortune, father/guru, higher learning, ethics and pilgrimage',
    'profession, authority, reputation and visible action',
    'gains, networks, income channels, elder siblings and ambitions',
    'expenditure, foreign places, retreat, sleep, release and privacy',
  ];

  static const Map<int, String> houseClass = {
    1: 'Kendra/Trikona/Lagna', 2: 'Maraka', 3: 'Upachaya', 4: 'Kendra', 5: 'Trikona', 6: 'Upachaya/Dusthana',
    7: 'Kendra/Maraka', 8: 'Dusthana', 9: 'Trikona', 10: 'Kendra/Upachaya', 11: 'Upachaya', 12: 'Dusthana',
  };

  static const List<String> _rashiAbbr = ['ARI', 'TAU', 'GEM', 'CAN', 'LEO', 'VIR', 'LIB', 'SCO', 'SAG', 'CAP', 'AQU', 'PIS'];
  static const Map<int, String> _prefix = {2: 'P', 3: 'T', 4: 'Q', 5: 'F', 6: 'S', 7: 'H'};

  static String planetName(String p) => VedicMath.planets[p]?.name ?? VedicMath.capitalize(p);
  static String element(int rashi) => VedicMath.rashis[rashi].element;
  static String modality(int rashi) => const ['Movable', 'Fixed', 'Dual'][rashi % 3];

  static List<String> canonical(Iterable<String> ps) => classical.where(ps.contains).toList();

  static List<(String, String)> pairsOf(List<String> ps) {
    final c = canonical(ps);
    return [
      for (int i = 0; i < c.length; i++)
        for (int j = i + 1; j < c.length; j++) (c[i], c[j]),
    ];
  }

  static String pairTheme(String a, String b) {
    final c = canonical([a, b]);
    return pairThemes['${c[0]}-${c[1]}']!;
  }

  static String pairId(String a, String b) => clusterIdOf([a, b]);

  static List<int> housesOwned(String p, int lagna) => [
        for (int h = 1; h <= 12; h++)
          if (VedicMath.rashis[(lagna + h - 1) % 12].lord == p) h,
      ];

  /// Volume 2 §5: pair x Bhava interpretation.
  static String pairBhavaText(String a, String b, int bhava) =>
      '${pairTheme(a, b)} expressed through ${bhavaDomainsV2[bhava - 1]}. Judge the house lord, Karaka, sign and dispositor before final synthesis.';

  /// Volume 2 §7: pair x Rashi interpretation.
  static String pairRashiText(String a, String b, int rashi) =>
      '${pairTheme(a, b)} operating through ${element(rashi).toLowerCase()} ${modality(rashi).toLowerCase()} '
      '${VedicMath.rashis[rashi].name} symbolism; ${planetName(VedicMath.rashis[rashi].lord)} is the dispositor.';

  /// Volume 2 §9: pair x Lagna functional-lordship question.
  static String pairLagnaText(String a, String b, int lagna) =>
      '${lordshipSentence(a, b, lagna)} Combine these house significations with the house occupied by the conjunction.';

  static String lordshipSentence(String a, String b, int lagna) =>
      '${planetName(a)} owns ${housesOwned(a, lagna).join(',')}; ${planetName(b)} owns ${housesOwned(b, lagna).join(',')}.';

  static String sourceTier(int size) => switch (size) {
        2 => 'CLASSICAL-DIRECT + SYSTEMATIC-SYNTHESIS',
        7 => 'CLASSICAL-PAIRWISE + SYSTEMATIC-SYNTHESIS',
        _ => 'CLASSICAL-DIRECT-WHERE-SOURCE-EXACT; OTHERWISE CLASSICAL-PAIRWISE + SYSTEMATIC-SYNTHESIS',
      };

  static String directSource(int size) => switch (size) {
        2 => 'Phaladeepika 18.1-5; Brihat Jataka 14.1-5',
        3 => 'Saravali ch. 16 (three-planet conjunctions); pairwise per Phaladeepika 18.5',
        4 => 'Saravali ch. 17; Jataka Parijata 8.23; pairwise per Phaladeepika 18.5',
        5 => 'Saravali ch. 18; Jataka Parijata 8.26; pairwise per Phaladeepika 18.5',
        6 => 'Saravali ch. 19; pairwise per Phaladeepika 18.5',
        _ => 'No classical verse for the seven-planet cluster; synthesis of the 21 pairs (Phaladeepika 18.5)',
      };

  /// The 120 clusters in catalogue order (P01-P21, T01-T35, Q01-Q35, F01-F21, S01-S07, H01).
  static final List<(String, List<String>)> clusters = () {
    final out = <(String, List<String>)>[];
    for (int size = 2; size <= 7; size++) {
      int n = 0;
      void rec(int start, List<String> acc) {
        if (acc.length == size) {
          n++;
          out.add(('${_prefix[size]}${n.toString().padLeft(2, '0')}', List.unmodifiable(acc)));
          return;
        }
        for (int i = start; i < classical.length; i++) {
          rec(i + 1, [...acc, classical[i]]);
        }
      }

      rec(0, []);
    }
    return List<(String, List<String>)>.unmodifiable(out);
  }();

  static String clusterIdOf(Iterable<String> ps) {
    final c = canonical(ps);
    return clusters.firstWhere((e) => e.$2.length == c.length && e.$2.every(c.contains)).$1;
  }

  static List<String> planetsOf(String clusterId) => clusters.firstWhere((e) => e.$1 == clusterId).$2;

  /// Record for a cluster placed in [bhava] (1-12) and [rashi] (0-11).
  static ConjunctionRecord record(String clusterId, int bhava, int rashi) {
    final planets = planetsOf(clusterId);
    final lagna = (rashi - (bhava - 1) + 12) % 12;
    final id = 'V3-$clusterId-B${bhava.toString().padLeft(2, '0')}-${_rashiAbbr[rashi]}';
    return ConjunctionRecord(id, clusterId, planets, bhava, rashi, lagna);
  }

  static const int totalRecords = 120 * 12 * 12;

  // ---------------------------------------------------------------------------
  // Chart analysis
  // ---------------------------------------------------------------------------

  /// Every conjunction of classical planets in [chart], with the degree layer.
  static List<ChartConjunction> find(ChartData chart, {CalcConfig cfg = CalcConfig.defaults, double? atJd}) {
    final bySign = <int, List<String>>{};
    for (final p in classical) {
      final l = chart.planetLongitudes[p];
      if (l != null) bySign.putIfAbsent(VedicMath.rashiIndex(l), () => []).add(p);
    }
    final yogas = YogasMath.forChart(chart).where((y) => y.formed).toList();
    final running = _running(chart, atJd);
    final out = <ChartConjunction>[];
    for (final e in bySign.entries) {
      if (e.value.length < 2) continue;
      final members = canonical(e.value);
      final rec = record(clusterIdOf(members), VedicMath.houseOf(e.key, chart.lagnaRashi), e.key);
      final nodes = ['rahu', 'ketu'].where((n) => chart.planetLongitudes[n] != null && VedicMath.rashiIndex(chart.planetLongitudes[n]!) == e.key).toList();
      out.add(ChartConjunction(chart, rec, nodes, cfg, yogas, running));
    }
    out.sort((a, b) => b.record.size.compareTo(a.record.size));
    return out;
  }

  /// Rahu/Ketu associations (Volume 2 §15, Volume 4 §15): node with the planets in its sign.
  static List<NodeAssociation> nodeAssociations(ChartData chart, {CalcConfig cfg = CalcConfig.defaults}) {
    final out = <NodeAssociation>[];
    for (final node in ['rahu', 'ketu']) {
      final l = chart.planetLongitudes[node];
      if (l == null) continue;
      final r = VedicMath.rashiIndex(l);
      final with_ = classical.where((p) => chart.planetLongitudes[p] != null && VedicMath.rashiIndex(chart.planetLongitudes[p]!) == r).toList();
      out.add(NodeAssociation(chart, node, with_, cfg));
    }
    return out;
  }

  static List<String> _running(ChartData chart, double? atJd) {
    final moon = chart.planetLongitudes['moon'];
    if (moon == null) return const [];
    return DashaCalculations.compute(chart.jd, moon, utcOffset: chart.utcOffset).runningAt(atJd ?? Ephemeris.nowJd()).map((d) => d.lord).toList();
  }
}

/// A Daśā period that activates a conjunction (Volume 4 §19, Volume 2 §18).
class DashaActivation {
  final String level; // Mahadasha, Antardasha
  final String lord;
  final String mahaLord;
  final String start;
  final String end;
  final double startJd;
  final String reason;
  const DashaActivation(this.level, this.lord, this.mahaLord, this.start, this.end, this.startJd, this.reason);
}

/// A conjunction found in a chart: database record + degree graph + timing.
class ChartConjunction {
  final ChartData chart;
  final ConjunctionRecord record;
  final List<String> nodes;
  final CalcConfig cfg;
  final List<YogaResult> _formedYogas;

  /// Running [Maha, Antar, Pratyantar] lords.
  final List<String> runningLords;

  ChartConjunction(this.chart, this.record, this.nodes, this.cfg, this._formedYogas, this.runningLords);

  late final List<PairEdge> edges = PrecisionMath.edges(chart, record.planets, cfg);
  late final ClusterMetrics metrics = PrecisionMath.metrics(chart, record.planets, cfg);
  late final Map<String, GrahaRecord> grahas = {for (final p in record.planets) p: PrecisionMath.record(chart, p, cfg)};
  late final GrahaRecord dispositorRecord = PrecisionMath.record(chart, record.dispositor, cfg);

  PairEdge? get closestPair => edges.isEmpty ? null : (List.of(edges)..sort((a, b) => a.separation.compareTo(b.separation))).first;

  /// The planet with the strongest sign dignity (ties: the one closest to the cluster centre).
  String get dominantPlanet {
    int rank(String d) => switch (d) {
          'Exalted' => 6,
          'Moolatrikona' => 5,
          'Own Sign' => 4,
          final x when x.contains('Great Friend') => 3,
          final x when x.contains('Friend') => 2,
          final x when x.contains('Neutral') => 1,
          'Debilitated' => -2,
          _ => 0,
        };
    final ps = List.of(record.planets)..sort((a, b) => rank(grahas[b]!.dignity).compareTo(rank(grahas[a]!.dignity)));
    return ps.first;
  }

  /// Named yogas whose planets all sit in this cluster and that the yoga engine confirms.
  List<YogaResult> get namedYogas => _formedYogas
      .where((y) => y.planets.isNotEmpty && y.planets.toSet().difference({...record.planets, ...nodes}).isEmpty && y.planets.length >= 2)
      .toList();

  /// Running periods that activate the cluster.
  List<String> get activeNow {
    final out = <String>[];
    const levels = ['Mahadasha', 'Antardasha', 'Pratyantardasha'];
    for (int i = 0; i < runningLords.length; i++) {
      final l = runningLords[i];
      if (record.planets.contains(l)) out.add('${levels[i]} lord ${ConjunctionDb.planetName(l)} is a member of the cluster');
      if (l == record.dispositor && !record.planets.contains(l)) out.add('${levels[i]} lord ${ConjunctionDb.planetName(l)} is the dispositor');
      if (nodes.contains(l)) out.add('${levels[i]} lord ${ConjunctionDb.planetName(l)} is a node joined with the cluster');
      final h = record.bhava;
      if (VedicMath.rashis[(chart.lagnaRashi + h - 1) % 12].lord == l && !record.planets.contains(l) && l != record.dispositor) {
        out.add('${levels[i]} lord ${ConjunctionDb.planetName(l)} owns the occupied house');
      }
    }
    return out;
  }

  /// Upcoming Mahadasha/Antardasha periods ruled by a cluster member or its dispositor.
  List<DashaActivation> upcoming({int limit = 8, double? fromJd}) {
    final moon = chart.planetLongitudes['moon'];
    if (moon == null) return const [];
    final now = fromJd ?? Ephemeris.nowJd();
    final dashas = DashaCalculations.compute(chart.jd, moon, utcOffset: chart.utcOffset);
    final out = <DashaActivation>[];
    for (final md in dashas.mahadashas) {
      for (final ad in md.subPeriods) {
        if (ad.endJD < now) continue;
        final mdIn = record.planets.contains(md.lord), adIn = record.planets.contains(ad.lord);
        if (!mdIn && !adIn && ad.lord != record.dispositor) continue;
        final reason = mdIn && adIn
            ? 'Both Mahadasha and Antardasha lords are in the cluster'
            : (adIn ? 'Antardasha lord in the cluster' : (mdIn ? 'Mahadasha lord in the cluster' : 'Antardasha of the dispositor'));
        out.add(DashaActivation('Antardasha', ad.lord, md.lord, ad.startDate, ad.endDate, ad.startJD, reason));
        if (out.length >= limit) return out;
      }
    }
    return out;
  }
}

class NodeAssociation {
  final ChartData chart;
  final String node;
  final List<String> planets;
  final CalcConfig cfg;
  NodeAssociation(this.chart, this.node, this.planets, this.cfg);

  late final GrahaRecord graha = PrecisionMath.record(chart, node, cfg);
  late final List<PairEdge> edges = [for (final p in planets) PrecisionMath.edge(chart, node, p, cfg)];

  String get dispositor => graha.dispositor;
  String get nodePairType => node == 'rahu' ? 'Rahu-graha' : 'Ketu-graha';

  /// Phaladeepika: a node in a Kendra or Trikona joined with a Trikona or Kendra lord can give Raja Yoga.
  List<String> get contextualRole {
    final out = <String>[];
    final h = graha.house;
    final lagna = chart.lagnaRashi;
    String lordOf(int house) => VedicMath.rashis[(lagna + house - 1) % 12].lord;
    final kendraLords = {lordOf(1), lordOf(4), lordOf(7), lordOf(10)};
    final trikonaLords = {lordOf(1), lordOf(5), lordOf(9)};
    if (YogasMath.isKendra(h) && planets.any(trikonaLords.contains)) {
      out.add('In a Kendra with a Trikona lord (${ConjunctionDb.planetName(planets.firstWhere(trikonaLords.contains))}): can act as a Raja Yoga giver.');
    }
    if (YogasMath.isTrikona(h) && planets.any(kendraLords.contains)) {
      out.add('In a Trikona with a Kendra lord (${ConjunctionDb.planetName(planets.firstWhere(kendraLords.contains))}): can act as a Raja Yoga giver.');
    }
    if (YogasMath.isDusthana(h)) out.add('In a dusthana (house $h).');
    out.add('Results follow its dispositor ${ConjunctionDb.planetName(dispositor)} (house ${PrecisionMath.record(chart, dispositor, cfg).house}) '
        'and nakshatra lord ${ConjunctionDb.planetName(graha.nakshatraLord)}.');
    return out;
  }
}
