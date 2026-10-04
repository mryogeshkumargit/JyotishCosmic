import 'ashtakavarga_math.dart';
import 'calc_config.dart';
import 'conjunction_db.dart';
import 'ephemeris.dart';
import 'jaimini_math.dart';
import 'knowledge_registry.dart';
import 'l10n.dart';
import 'plain/interpret.dart';
import 'precision_math.dart';
import 'shadbala_math.dart';
import 'timing_math.dart';
import 'vedic_math.dart';
import 'yogas_math.dart';

/// Evidence layers (Volume 5 §17).
enum EvidenceLayer {
  natal('A', 'Natal promise', 'जन्म कुंडली का वादा'),
  strength('B', 'Strength', 'बल'),
  dasha('C', 'Daśā activation', 'दशा सक्रियता'),
  transit('D', 'Transit confirmation', 'गोचर पुष्टि'),
  varga('E', 'Varga confirmation', 'वर्ग पुष्टि'),
  ashtakavarga('F', 'Ashtakavarga support', 'अष्टकवर्ग सहारा');

  final String level;
  final String _en;
  final String _hi;
  const EvidenceLayer(this.level, this._en, this._hi);

  String get label => tr(_en, _hi);
}

enum Polarity { support, obstruction, neutral }

/// Technical evidence states (Volume 5 §18) - not guaranteed-event labels.
enum PredictionStatus {
  natalPromisePresent('NATAL_PROMISE_PRESENT', 'Natal chart contains relevant indicators', 'जन्म कुंडली में संबंधित संकेत हैं'),
  natalPromiseWeak('NATAL_PROMISE_WEAK', 'Indication exists but support is limited', 'संकेत है पर सहारा सीमित है'),
  natalContradiction('NATAL_CONTRADICTION', 'Significant opposing natal indicators', 'जन्म कुंडली में प्रबल विरोधी संकेत'),
  timingActive('TIMING_ACTIVE', 'Current Daśā activates relevant factors', 'वर्तमान दशा संबंधित कारकों को सक्रिय करती है'),
  transitConfirmed('TRANSIT_CONFIRMED', 'Transit independently activates the domain', 'गोचर स्वतंत्र रूप से क्षेत्र को सक्रिय करता है'),
  vargaConfirmed('VARGA_CONFIRMED', 'Relevant Varga supports the indication', 'संबंधित वर्ग संकेत का समर्थन करता है'),
  partialConvergence('PARTIAL_CONVERGENCE', 'Several layers agree, one or more absent or conflicting', 'कई परतें सहमत, एक या अधिक अनुपस्थित या विरोधी'),
  insufficientData('INSUFFICIENT_DATA', 'Calculation cannot be completed', 'गणना पूरी नहीं हो सकती');

  final String code;
  final String _en;
  final String _hi;
  const PredictionStatus(this.code, this._en, this._hi);

  String get label => tr(_en, _hi);
}

/// Volume 6 §45 prediction states (not numerical rankings).
enum V6Status {
  notSupported('NOT_SUPPORTED'),
  natalPromise('NATAL_PROMISE'),
  supported('SUPPORTED'),
  activated('ACTIVATED'),
  timingWindow('TIMING_WINDOW'),
  confirmedByTransit('CONFIRMED_BY_TRANSIT'),
  conflicted('CONFLICTED'),
  insufficientData('INSUFFICIENT_DATA');

  final String code;
  const V6Status(this.code);
}

/// Volume 6 §46 evidence states; never a percentage.
enum Confidence {
  low('LOW'),
  moderate('MODERATE'),
  strong('STRONG'),
  veryStrong('VERY_STRONG'),
  conflicted('CONFLICTED'),
  insufficient('INSUFFICIENT');

  final String code;
  const Confidence(this.code);
}

class Evidence {
  final EvidenceLayer layer;
  final Polarity polarity;
  final String text;
  final SourceTier tier;

  /// Classical or engine locator (free text).
  final String rule;
  final String? _ruleId;
  String id = '';
  Evidence(this.layer, this.polarity, this.text, this.tier, this.rule, {String? ruleId}) : _ruleId = ruleId;

  /// Registry rule (R001...) this evidence was produced by.
  String get ruleId => _ruleId ?? KnowledgeRegistry.ruleIdFor(rule);

  String get mark => switch (polarity) { Polarity.support => '✓', Polarity.obstruction => '✗', Polarity.neutral => '△' };
}

class LifeDomain {
  final String id;
  final String name;
  final List<int> bhavas;
  final List<String> karakas;

  /// Primary Varga for the domain.
  final String varga;
  final List<String> dimensions;
  final String? caution;

  /// Master KB event-domain code (E01-E12; A01-A02 are app additions).
  final String code;

  /// Volume 6 §43 domain name.
  final String v6Name;

  /// Supporting Vargas (Master KB prediction dependencies), D1 first.
  final List<String> vargas;
  const LifeDomain(this.id, this.name, this.bhavas, this.karakas, this.varga, this.dimensions,
      {this.caution, required this.code, required this.v6Name, required this.vargas});
}

/// Explanation graph (Volume 6 §61): every node has a stable ID.
class ExplanationNode {
  final String id;
  final String type;
  final String label;
  const ExplanationNode(this.id, this.type, this.label);
  Map<String, String> toJson() => {'id': id, 'type': type, 'label': label};
}

class ExplanationEdge {
  final String from;
  final String to;
  final String relation;
  const ExplanationEdge(this.from, this.to, this.relation);
  Map<String, String> toJson() => {'from': from, 'to': to, 'relation': relation};
}

class ExplanationGraph {
  final Map<String, ExplanationNode> nodes = {};
  final List<ExplanationEdge> edges = [];

  void node(String id, String type, String label) => nodes.putIfAbsent(id, () => ExplanationNode(id, type, label));
  void edge(String from, String to, String relation) {
    if (!edges.any((e) => e.from == from && e.to == to && e.relation == relation)) edges.add(ExplanationEdge(from, to, relation));
  }

  List<ExplanationEdge> from(String id) => edges.where((e) => e.from == id).toList();
  Map<String, dynamic> toJson() => {'nodes': [for (final n in nodes.values) n.toJson()], 'edges': [for (final e in edges) e.toJson()]};
}

/// An event window: a period whose Daśā lords activate a domain (Volume 5 §19).
class EventWindow {
  final String label;
  final double startJd;
  final double endJd;
  final String start;
  final String end;
  final List<String> factors;
  final List<String> peakPeriods;
  const EventWindow(this.label, this.startJd, this.endJd, this.start, this.end, this.factors, this.peakPeriods);
}

/// A slow-planet ingress into a domain's house sign (retrograde re-entries kept separately).
class TransitContact {
  final String planet;
  final int rashi;
  final double jd;
  final String date;
  final bool retrogradeRecontact;
  final String note;
  const TransitContact(this.planet, this.rashi, this.jd, this.date, this.retrogradeRecontact, this.note);
}

class DomainSynthesis {
  final LifeDomain domain;
  final List<Evidence> evidence;
  final List<String> lordChains;
  final Set<PredictionStatus> statuses;
  final SourceTier tier;
  final String interpretation;
  final List<EventWindow> windows;
  final List<TransitContact> transits;

  /// Volume 6 state and evidence-state confidence.
  final V6Status v6Status;
  final Confidence confidence;

  /// Master KB required layers -> SUPPORTING / OPPOSING / MIXED / ABSENT / NOT_APPLICABLE.
  final Map<String, String> dependencies;

  /// Master KB status policy: SUPPORTED, CONDITIONALLY_SUPPORTED, CONFLICTED, INSUFFICIENT_INPUT.
  final String masterStatus;

  /// Degree-exact transit triggers on this domain's factors (next three years).
  final List<TransitTrigger> triggers;

  /// Daśā ∩ transit windows (Volume 6 §91-92).
  final List<TimingWindow> timingWindows;

  /// Rule trace (Volume 6 §62): rule id -> fired.
  final Map<String, bool> ruleTrace;
  final ExplanationGraph graph;

  DomainSynthesis(this.domain, this.evidence, this.lordChains, this.statuses, this.tier, this.interpretation, this.windows, this.transits,
      {this.v6Status = V6Status.natalPromise,
      this.confidence = Confidence.low,
      this.dependencies = const {},
      this.masterStatus = 'CONDITIONALLY_SUPPORTED',
      this.triggers = const [],
      this.timingWindows = const [],
      this.ruleTrace = const {},
      ExplanationGraph? graph})
      : graph = graph ?? ExplanationGraph();

  List<String> get supportingFactors => [for (final e in evidence) if (e.polarity == Polarity.support) e.text];
  List<String> get contradictions => [for (final e in evidence) if (e.polarity == Polarity.obstruction) e.text];

  /// Volume 6 §60 explanation object.
  Map<String, dynamic> explanation() => {
        'claim': interpretation,
        'event_domain': domain.v6Name,
        'status': v6Status.code,
        'confidence': confidence.code,
        'support': [for (final e in evidence) if (e.polarity == Polarity.support) {'factor': e.text, 'layer': e.layer.label, 'rule': e.ruleId}],
        'modifiers': [for (final e in evidence) if (e.polarity == Polarity.neutral) {'factor': e.text, 'layer': e.layer.label, 'rule': e.ruleId}],
        'contradictions': [for (final e in evidence) if (e.polarity == Polarity.obstruction) {'factor': e.text, 'layer': e.layer.label, 'rule': e.ruleId}],
        'source_refs': {for (final e in evidence) ...KnowledgeRegistry.rule(e.ruleId).sourceIds}.toList()..sort(),
      };

  List<Evidence> layer(EvidenceLayer l) => evidence.where((e) => e.layer == l).toList();
  List<Evidence> get conflicts => evidence.where((e) => e.polarity == Polarity.obstruction).toList();
  bool layerSupports(EvidenceLayer l) => layer(l).any((e) => e.polarity == Polarity.support);

  PredictionStatus get primaryStatus {
    for (final s in [
      PredictionStatus.insufficientData,
      PredictionStatus.natalContradiction,
      PredictionStatus.partialConvergence,
      PredictionStatus.natalPromisePresent,
      PredictionStatus.natalPromiseWeak,
    ]) {
      if (statuses.contains(s)) return s;
    }
    return statuses.first;
  }

  /// Plain-text report of the domain in the "no black box" format (Volume 5 §36).
  String report() {
    final b = StringBuffer('DOMAIN: ${domain.name}\n');
    for (final l in EvidenceLayer.values) {
      final items = layer(l);
      if (items.isEmpty) continue;
      b.writeln('\n${l.label.toUpperCase()} (Level ${l.level}):');
      for (final e in items) {
        b.writeln('${e.mark} [${e.id}/${e.ruleId}] ${e.text}');
      }
    }
    b.writeln('\nSTATUS: ${statuses.map((s) => s.code).join(', ')}');
    b.writeln('V6 STATUS: ${v6Status.code}; CONFIDENCE: ${confidence.code}; MASTER KB: $masterStatus');
    b.writeln('SOURCE TIER: ${tier.code}');
    if (timingWindows.isNotEmpty) {
      b.writeln('\nTIMING WINDOWS:');
      for (final w in timingWindows.take(5)) {
        b.writeln('${w.start} – ${w.end}: ${w.activation.join(', ')} [${w.status}]');
      }
    }
    b.writeln('\nRESULT: $interpretation');
    return b.toString();
  }
}

class InputFlag {
  final String severity; // info, warning, critical
  final String message;
  const InputFlag(this.severity, this.message);
}

class SynthesisReport {
  final ChartData chart;
  final List<DomainSynthesis> domains;
  final List<InputFlag> inputFlags;
  final Map<String, String> audit;
  final List<String> running;
  final JaiminiResult? jaimini;
  final SensitivityResult? sensitivity;
  const SynthesisReport(this.chart, this.domains, this.inputFlags, this.audit, this.running, {this.jaimini, this.sensitivity});
}

/// Candidate birth time for rectification (Volume 5 §42).
class RectificationCandidate {
  final int offsetMinutes;
  final ChartData chart;
  final double score;
  final List<String> details;
  const RectificationCandidate(this.offsetMinutes, this.chart, this.score, this.details);
}

class LifeEvent {
  final DateTime date;
  final String domainId;
  final String note;
  const LifeEvent(this.date, this.domainId, [this.note = '']);
}

/// Backtest of one known event (Volume 5 §43).
class BacktestResult {
  final LifeEvent event;
  final List<String> periods;
  final List<String> activatedDomains;
  final bool expectedDomainActivated;
  final List<String> trace;
  const BacktestResult(this.event, this.periods, this.activatedDomains, this.expectedDomainActivated, this.trace);
}

/// Volume 5 predictive synthesis engine: orchestrates the natal, strength,
/// Daśā, transit, Varga and Ashtakavarga layers into auditable evidence.
class SynthesisEngine {
  static const String sourceVersions =
      'Conjunction Database Vol. 2-6 (3 Oct 2026); Master Knowledge Base v1.0.0; Production Knowledge Graph v1.0.0; Conjunctions Deep Research; Yoga guide (2 Oct 2026)';

  static const Map<int, List<String>> houseKarakas = {
    1: ['sun'], 2: ['jupiter'], 3: ['mars'], 4: ['moon'], 5: ['jupiter'], 6: ['mars', 'saturn'], 7: ['venus'],
    8: ['saturn'], 9: ['jupiter', 'sun'], 10: ['sun', 'mercury', 'jupiter', 'saturn'], 11: ['jupiter'], 12: ['saturn'],
  };

  static const List<LifeDomain> domains = [
    LifeDomain('identity', 'Identity & vitality', [1], ['sun'], 'D1', ['temperament', 'self-direction', 'vitality'],
        code: 'E01', v6Name: 'IDENTITY', vargas: ['D1', 'D27', 'D60']),
    LifeDomain('wealth', 'Wealth & savings', [2, 11, 5, 9], ['jupiter', 'venus'], 'D2',
        ['accumulated wealth', 'income', 'speculation', 'fortune'], caution: 'Debt and loss are judged separately from the 6th, 8th and 12th.',
        code: 'E02', v6Name: 'WEALTH', vargas: ['D1', 'D2']),
    LifeDomain('skills', 'Skills, communication & siblings', [3], ['mars', 'mercury'], 'D3', ['initiative', 'communication', 'younger siblings'],
        code: 'E03', v6Name: 'COMMUNICATION', vargas: ['D1', 'D3']),
    LifeDomain('home', 'Home, property & mother', [4, 2, 11], ['moon', 'venus', 'mars'], 'D4',
        ['acquisition', 'construction', 'relocation', 'sale', 'inheritance'], code: 'E04', v6Name: 'HOME_PROPERTY', vargas: ['D1', 'D4', 'D16']),
    LifeDomain('children', 'Children & creativity', [5], ['jupiter'], 'D7', ['children', 'creativity', 'intelligence'],
        code: 'E05', v6Name: 'CHILDREN_CREATIVITY', vargas: ['D1', 'D7', 'D24']),
    LifeDomain('health', 'Health, service & competition', [6, 1, 8], ['sun', 'moon'], 'D30', ['routines', 'competition', 'debts', 'vitality'],
        caution: 'Traditional indications only; not a medical assessment.', code: 'E06', v6Name: 'HEALTH_SERVICE', vargas: ['D1', 'D27', 'D30']),
    LifeDomain('marriage', 'Marriage & partnership', [7, 2], ['venus', 'jupiter'], 'D9',
        ['relationship activation', 'partnership formation', 'formalisation', 'strain', 'separation indicators'],
        code: 'E07', v6Name: 'MARRIAGE_PARTNERSHIP', vargas: ['D1', 'D9']),
    LifeDomain('transformation', 'Transformation, inheritance & research', [8], ['saturn'], 'D30', ['research', 'joint resources', 'major change'],
        code: 'E08', v6Name: 'TRANSFORMATION', vargas: ['D1', 'D30', 'D60']),
    LifeDomain('fortune', 'Fortune, father & higher learning', [9], ['jupiter', 'sun'], 'D9', ['fortune', 'father/guru', 'pilgrimage'],
        code: 'E09', v6Name: 'FORTUNE_HIGHER_LEARNING', vargas: ['D1', 'D9', 'D12', 'D20', 'D40', 'D45', 'D60']),
    LifeDomain('career', 'Career & status', [10, 6, 11], ['sun', 'saturn', 'mercury', 'jupiter'], 'D10',
        ['employment', 'promotion/authority', 'role change', 'business', 'professional conflict', 'gains from work'],
        code: 'E10', v6Name: 'CAREER', vargas: ['D1', 'D10']),
    LifeDomain('gains', 'Gains & networks', [11], ['jupiter'], 'D1', ['income channels', 'networks', 'ambitions'],
        code: 'E11', v6Name: 'GAINS_NETWORK', vargas: ['D1']),
    LifeDomain('foreign', 'Expenditure, foreign lands & retreat', [12, 9, 7, 4], ['saturn', 'rahu', 'moon'], 'D12',
        ['travel', 'temporary stay', 'relocation', 'foreign work', 'long-term residence'],
        code: 'E12', v6Name: 'FOREIGN_RETREAT', vargas: ['D1', 'D30', 'D12']),
    LifeDomain('education', 'Education & intelligence', [4, 5, 9], ['mercury', 'jupiter'], 'D24',
        ['foundational education', 'higher education', 'specialised study', 'teaching/research'],
        code: 'A01', v6Name: 'EDUCATION', vargas: ['D1', 'D24']),
    LifeDomain('spiritual', 'Spiritual practice & research', [5, 9, 12, 8], ['jupiter', 'ketu'], 'D20',
        ['spiritual practice', 'academic research', 'esoteric interests', 'life transformation'],
        code: 'A02', v6Name: 'SPIRITUAL', vargas: ['D1', 'D20']),
  ];

  static final Map<String, int> _divisions = {for (final v in VedicMath.vargaDefs) v.key: v.div};

  static String _n(String p) => L10n.planet(p);

  /// Hindi ordinal ("10वें") for house references inside Hindi sentences.
  static String _h(int h) => '$hवें';
  static String _dig(String d) => L10n.dignity(d);
  static String lordOf(ChartData c, int house) => VedicMath.rashis[(c.lagnaRashi + house - 1) % 12].lord;
  static int houseOfPlanet(ChartData c, String p) => VedicMath.houseOf(VedicMath.rashiIndex(c.planetLongitudes[p]!), c.lagnaRashi);
  static List<int> housesOwned(ChartData c, String p) => [for (int h = 1; h <= 12; h++) if (lordOf(c, h) == p) h];

  static bool _naturalBenefic(ChartData c, String p) {
    final l = c.planetLongitudes;
    switch (p) {
      case 'jupiter':
      case 'venus':
        return true;
      case 'moon':
        return VedicMath.norm360(l['moon']! - l['sun']!) < 180;
      case 'mercury':
        final r = VedicMath.rashiIndex(l['mercury']!);
        return !['sun', 'mars', 'saturn', 'rahu', 'ketu'].any((m) => l[m] != null && VedicMath.rashiIndex(l[m]!) == r);
      default:
        return false;
    }
  }

  /// Planets that cast a full sign-based aspect on [house].
  static List<String> aspectingHouse(ChartData c, int house, CalcConfig cfg) {
    final target = (c.lagnaRashi + house - 1) % 12;
    return [
      for (final p in Ephemeris.planetOrder)
        if (c.planetLongitudes.containsKey(p) &&
            PrecisionMath.aspectHouses(p, cfg).contains(VedicMath.houseOf(target, VedicMath.rashiIndex(c.planetLongitudes[p]!))))
          p,
    ];
  }

  /// Why [lord] (a Daśā lord) activates [domain]; empty if it does not.
  static List<String> activationReasons(ChartData c, String lord, LifeDomain domain, CalcConfig cfg) {
    final out = <String>[];
    final hl = houseOfPlanet(c, lord);
    final owned = housesOwned(c, lord);
    for (final h in domain.bhavas) {
      if (owned.contains(h)) out.add(tr('owns the ${VedicMath.ordinal(h)}', '${_h(h)} भाव का स्वामी है'));
      if (hl == h) out.add(tr('occupies the ${VedicMath.ordinal(h)}', '${_h(h)} भाव में स्थित है'));
      if (aspectingHouse(c, h, cfg).contains(lord)) out.add(tr('aspects the ${VedicMath.ordinal(h)}', '${_h(h)} भाव को देखता है'));
      final hLord = lordOf(c, h);
      if (hLord != lord && VedicMath.rashiIndex(c.planetLongitudes[hLord]!) == VedicMath.rashiIndex(c.planetLongitudes[lord]!)) {
        out.add(tr('is joined with the ${VedicMath.ordinal(h)} lord', '${_h(h)} भाव के स्वामी के साथ है'));
      }
      if (hLord != lord && VedicMath.rashis[VedicMath.rashiIndex(c.planetLongitudes[hLord]!)].lord == lord) {
        out.add(tr('disposits the ${VedicMath.ordinal(h)} lord', '${_h(h)} भाव के स्वामी का राशि स्वामी है'));
      }
    }
    if (domain.karakas.contains(lord)) out.add(tr('is a karaka of the domain', 'इस क्षेत्र का कारक है'));
    return out.toSet().toList();
  }

  /// Rules every domain evaluates; conditional rules are added when they apply.
  static const List<String> _domainRules = [
    'R001', 'R012', 'R029', 'R028', 'R003', 'R026', 'R016', 'R017', 'R018', 'R009', 'R025', 'R010', 'R011', 'R007', 'R004', 'R030',
    'R005', 'R021', 'R006', 'R022', 'R013', 'R014', 'R015',
  ];

  /// Ashtakavarga, Shadbala and other heavy layers are computed once per chart.
  static SynthesisReport analyse(ChartData c,
      {CalcConfig cfg = CalcConfig.defaults, double? atJd, bool includeTransits = true, bool includeSensitivity = true}) {
    final now = atJd ?? Ephemeris.nowJd();
    final flags = inputFlags(c, cfg);
    final sb = ShadbalaMath.compute(c, cfg: cfg);
    final av = AshtakavargaMath.compute(c);
    final recs = PrecisionMath.records(c, cfg);
    final wars = PrecisionMath.wars(c, cfg);
    final yogas = YogasMath.forChart(c, atJd: now).where((y) => y.formed).toList();
    final conjunctions = ConjunctionDb.find(c, cfg: cfg, atJd: now);
    final dashas = DashaCalculations.compute(c.jd, c.planetLongitudes['moon']!, utcOffset: c.utcOffset);
    final running = dashas.runningAt(now);
    final jaimini = JaiminiMath.compute(c, scheme: cfg.karakaScheme);
    ChartData? transit;
    var allTriggers = <TransitTrigger>[];
    if (includeTransits) {
      try {
        transit = Ephemeris.computeChartForJd(now, c.lat, c.lon, utcOffset: c.utcOffset);
        allTriggers = TimingMath.triggers(c, TimingMath.natalTargets(c), fromJd: now, orb: cfg.transitOrb);
      } catch (_) {
        transit = null;
      }
    }
    SensitivityResult? sensitivity;
    if (includeSensitivity) {
      try {
        sensitivity = TimingMath.sensitivity((m) => Ephemeris.computeChartForJd(c.jd + m / 1440, c.lat, c.lon, utcOffset: c.utcOffset),
            scheme: cfg.karakaScheme);
      } catch (_) {
        sensitivity = null;
      }
    }
    final meanBhava = sb.bhavas.fold<double>(0, (s, b) => s + b.total) / 12;
    var executed = 0, triggered = 0, conflicted = 0;

    final out = <DomainSynthesis>[];
    for (final d in domains) {
      final ev = <Evidence>[];
      final chains = <String>[];
      final rulesRun = <String>{..._domainRules};
      void add(EvidenceLayer l, Polarity p, String t, SourceTier tier, String rule, {String? ruleId}) =>
          ev.add(Evidence(l, p, t, tier, rule, ruleId: ruleId));

      // ---------------- A: natal promise ----------------
      for (final h in d.bhavas) {
        final primary = h == d.bhavas.first;
        final lord = lordOf(c, h);
        final hl = houseOfPlanet(c, lord);
        final r = recs[lord]!;
        final dispositor = r.dispositor;
        final dispRec = recs[dispositor]!;
        final disp2 = dispRec.dispositor;
        final disp2Rec = recs[disp2]!;
        chains.add('${tr('${VedicMath.ordinal(h)} Bhāva', '${_h(h)} भाव')} → ${_n(lord)} → ${L10n.sign(r.rashi)} (${tr('house', 'भाव')} $hl) → '
            '${_n(dispositor)} → ${tr('house', 'भाव')} ${dispRec.house} (${_dig(dispRec.dignity)}${sb.planets[dispositor] != null ? ', ${tr('Shadbala', 'षड्बल')} ${sb.planets[dispositor]!.ratio.toStringAsFixed(2)}×' : ''})'
            '${disp2 != dispositor ? ' → ${_n(disp2)} → ${tr('house', 'भाव')} ${disp2Rec.house} (${_dig(disp2Rec.dignity)})' : tr(' (own-sign terminus)', ' (स्वराशि पर समाप्त)')}');
        if (!primary && hl != h && !YogasMath.isDusthana(hl) && !YogasMath.isKendra(hl) && !YogasMath.isTrikona(hl)) continue;
        if (YogasMath.isDusthana(h) && YogasMath.isDusthana(hl)) {
          add(EvidenceLayer.natal, Polarity.support, tr('${VedicMath.ordinal(h)} lord ${_n(lord)} in the ${VedicMath.ordinal(hl)}: a dusthana lord in a dusthana (Viparīta reversal).',
              '${_h(h)} भाव का स्वामी ${_n(lord)} ${_h(hl)} भाव में: दुःस्थान का स्वामी दुःस्थान में (विपरीत फल)।'),
              SourceTier.classicalDerived, 'Phaladeepika ch. 6 (Viparita)');
        } else if (hl == h || YogasMath.isKendra(hl) || YogasMath.isTrikona(hl) || hl == 11) {
          add(EvidenceLayer.natal, Polarity.support, tr('${VedicMath.ordinal(h)} lord ${_n(lord)} is in the ${VedicMath.ordinal(hl)} (${hl == h ? 'its own house' : 'a good house'}).',
              '${_h(h)} भाव का स्वामी ${_n(lord)} ${_h(hl)} भाव में है (${hl == h ? 'अपना भाव' : 'शुभ भाव'})।'),
              SourceTier.classicalDerived, 'BPHS bhava-lord placement');
        } else if (YogasMath.isDusthana(hl)) {
          add(EvidenceLayer.natal, Polarity.obstruction, tr('${VedicMath.ordinal(h)} lord ${_n(lord)} is in the ${VedicMath.ordinal(hl)}, a dusthana.',
              '${_h(h)} भाव का स्वामी ${_n(lord)} ${_h(hl)} भाव (दुःस्थान) में है।'),
              SourceTier.classicalDerived, 'BPHS bhava-lord placement');
        }
        if (!primary) continue;
        final occupants = Ephemeris.planetOrder.where((p) => c.planetLongitudes.containsKey(p) && houseOfPlanet(c, p) == h).toList();
        for (final p in occupants) {
          final ben = _naturalBenefic(c, p);
          if (ben) {
            add(EvidenceLayer.natal, Polarity.support, tr('${_n(p)} (benefic) occupies the ${VedicMath.ordinal(h)}.', '${_n(p)} (शुभ ग्रह) ${_h(h)} भाव में है।'), SourceTier.classicalDerived, 'Phaladeepika bhava analysis');
          } else if (YogasMath.isUpachaya(h)) {
            add(EvidenceLayer.natal, Polarity.support, tr('${_n(p)} (malefic) in the ${VedicMath.ordinal(h)}, an Upachaya, where malefics do well.', '${_n(p)} (पाप ग्रह) ${_h(h)} भाव (उपचय) में, जहाँ पाप ग्रह अच्छा फल देते हैं।'), SourceTier.classicalDerived, 'Phaladeepika bhava analysis (Upachaya)');
          } else {
            add(EvidenceLayer.natal, Polarity.obstruction, tr('${_n(p)} (malefic) occupies the ${VedicMath.ordinal(h)}.', '${_n(p)} (पाप ग्रह) ${_h(h)} भाव में है।'), SourceTier.classicalDerived, 'Phaladeepika bhava analysis');
          }
        }
        for (final p in aspectingHouse(c, h, cfg)) {
          if (occupants.contains(p)) continue;
          final ben = _naturalBenefic(c, p);
          if (ben || YogasMath.isUpachaya(h)) {
            add(EvidenceLayer.natal, ben ? Polarity.support : Polarity.neutral, tr('${_n(p)} aspects the ${VedicMath.ordinal(h)}.', '${_n(p)} की ${_h(h)} भाव पर दृष्टि है।'), SourceTier.classicalDerived, 'Parashari graha drishti');
          } else {
            add(EvidenceLayer.natal, Polarity.obstruction, tr('${_n(p)} (malefic) aspects the ${VedicMath.ordinal(h)}.', '${_n(p)} (पाप ग्रह) की ${_h(h)} भाव पर दृष्टि है।'), SourceTier.classicalDerived, 'Parashari graha drishti');
          }
        }
        for (final cj in conjunctions.where((x) => x.record.bhava == h)) {
          add(EvidenceLayer.natal, Polarity.neutral,
              tr('Conjunction ${cj.record.clusterId} (${cj.record.clusterLabel}) in the ${VedicMath.ordinal(h)}; closest pair ${cj.closestPair == null ? '-' : '${_n(cj.closestPair!.a)}–${_n(cj.closestPair!.b)} ${cj.closestPair!.separation.toStringAsFixed(1)}°'}.',
                  '${_h(h)} भाव में युति ${cj.record.clusterId} (${cj.record.clusterLabel}); सबसे निकट जोड़ा ${cj.closestPair == null ? '-' : '${_n(cj.closestPair!.a)}–${_n(cj.closestPair!.b)} ${cj.closestPair!.separation.toStringAsFixed(1)}°'}।'),
              SourceTier.systematicSynthesis, 'Conjunction DB ${cj.record.recordId}');
          final rep = ConjunctionDb.vargaRepetition(c, cj.record.planets, [...{'D9', ...d.vargas.where((v) => v != 'D1')}]);
          if (rep.isNotEmpty) {
            rulesRun.add('R024');
            add(EvidenceLayer.varga, Polarity.support, tr('The ${cj.record.planets.map(_n).join('–')} conjunction repeats in ${rep.join(', ')}, which strengthens it.',
                '${cj.record.planets.map(_n).join('–')} युति ${rep.join(', ')} में दोहराई गई है, जो इसे मज़बूत करती है।'),
                SourceTier.systematicSynthesis, 'Varga repetition of a conjunction', ruleId: 'R024');
          }
        }
      }
      for (final k in d.karakas) {
        final r = recs[k];
        if (r == null) continue;
        if (r.dignity == 'Exalted' || r.dignity == 'Own Sign' || r.dignity == 'Moolatrikona') {
          add(EvidenceLayer.natal, Polarity.support, tr('Karaka ${_n(k)} is ${r.dignity.toLowerCase()}.', 'कारक ${_n(k)} ${_dig(r.dignity)} है।'), SourceTier.classicalDerived, 'Karaka layer (Vol. 5 §31)');
        } else if (r.dignity == 'Debilitated' || r.combust) {
          add(EvidenceLayer.natal, Polarity.obstruction, tr('Karaka ${_n(k)} is ${r.combust ? 'combust' : 'debilitated'}.', 'कारक ${_n(k)} ${r.combust ? 'अस्त' : 'नीच'} है।'), SourceTier.classicalDerived, 'Karaka layer (Vol. 5 §31)');
        }
      }
      _jaiminiEvidence(c, d, jaimini, recs, add, rulesRun);
      final lords = {for (final h in d.bhavas) lordOf(c, h)};
      for (final y in yogas) {
        if (!y.planets.any(lords.contains)) continue;
        if (y.category.startsWith('Nabhasa') || y.category == YogaFamilies.arishta || y.category == YogaFamilies.pravrajya) continue;
        add(EvidenceLayer.natal, y.nature == YogaNature.adverse ? Polarity.obstruction : Polarity.support,
            tr('${y.name} involves ${y.planets.where(lords.contains).map(_n).join(', ')} (${y.strength}).',
                '${y.hindi} में ${y.planets.where(lords.contains).map(_n).join(', ')} शामिल (${Interpret.yogaStrength(y.strength)})।'),
            SourceTier.classicalDirect, y.source, ruleId: 'R016');
      }

      // ---------------- B: strength ----------------
      final primaryLord = lordOf(c, d.bhavas.first);
      final ps = sb.planets[primaryLord];
      if (ps != null) {
        add(EvidenceLayer.strength, ps.meetsMinimum ? Polarity.support : Polarity.obstruction,
            tr('${d.bhavas.first == 1 ? 'Lagna' : VedicMath.ordinal(d.bhavas.first)} lord ${_n(primaryLord)}: Shadbala ${ps.rupas.toStringAsFixed(2)} rupas (${ps.ratio.toStringAsFixed(2)}× the minimum).',
                '${d.bhavas.first == 1 ? 'लग्नेश' : '${_h(d.bhavas.first)} भाव का स्वामी'} ${_n(primaryLord)}: षड्बल ${ps.rupas.toStringAsFixed(2)} रूप (न्यूनतम का ${ps.ratio.toStringAsFixed(2)}×)।'),
            SourceTier.classicalDerived, 'BPHS Shadbala');
      }
      final bb = sb.bhavas[d.bhavas.first - 1];
      add(EvidenceLayer.strength, bb.total >= meanBhava ? Polarity.support : Polarity.obstruction,
          tr('Bhāva Bala of the ${VedicMath.ordinal(d.bhavas.first)}: ${bb.rupas.toStringAsFixed(2)} rupas (chart average ${(meanBhava / 60).toStringAsFixed(2)}).',
              '${_h(d.bhavas.first)} भाव का भाव बल: ${bb.rupas.toStringAsFixed(2)} रूप (कुंडली औसत ${(meanBhava / 60).toStringAsFixed(2)})।'),
          SourceTier.classicalDerived, 'Bhava Bala (Raman method)');
      final pr = recs[primaryLord]!;
      final pn = _n(primaryLord);
      if (pr.combust) {
        add(EvidenceLayer.strength, Polarity.obstruction, tr('$pn is combust (${pr.sunDistance!.toStringAsFixed(1)}° from the Sun).', '$pn अस्त है (सूर्य से ${pr.sunDistance!.toStringAsFixed(1)}°)।'),
            SourceTier.configurableTradition, 'Combustion orb table');
      }
      if (pr.vargottama) add(EvidenceLayer.strength, Polarity.support, tr('$pn is vargottama.', '$pn वर्गोत्तम है।'), SourceTier.classicalDerived, 'Phaladeepika (Vargottama)');
      if (pr.sandhi) {
        add(EvidenceLayer.strength, Polarity.obstruction, tr('$pn is near a Bhāva-sandhi, which reduces effectiveness.', '$pn भाव-संधि के पास है, जिससे प्रभाव कम होता है।'),
            SourceTier.configurableTradition, 'Phaladeepika (Bhava-sandhi)');
      }
      if (pr.retrograde && !pr.isNode) {
        add(EvidenceLayer.strength, Polarity.neutral, tr('$pn is retrograde (Cheṣṭā strength; delayed or repeated expression).', '$pn वक्री है (चेष्टा बल; फल देर से या बार-बार)।'),
            SourceTier.classicalDerived, 'Phaladeepika ch. 4');
      }
      for (final w in wars.where((w) => w.a == primaryLord || w.b == primaryLord)) {
        add(EvidenceLayer.strength, w.winner == primaryLord ? Polarity.support : Polarity.obstruction,
            tr('${_n(primaryLord)} is in planetary war with ${_n(w.a == primaryLord ? w.b : w.a)} and ${w.winner == primaryLord ? 'wins' : (w.winner == null ? 'the result is undetermined' : 'loses')}.',
                '${_n(primaryLord)} का ${_n(w.a == primaryLord ? w.b : w.a)} से ग्रह युद्ध है और वह ${w.winner == primaryLord ? 'जीतता है' : (w.winner == null ? 'अनिश्चित है' : 'हारता है')}।'),
            SourceTier.configurableTradition, w.rule, ruleId: 'R010');
      }
      if (pr.dignity == 'Debilitated') add(EvidenceLayer.strength, Polarity.obstruction, tr('$pn is debilitated.', '$pn नीच का है।'), SourceTier.classicalDerived, 'Dignity');
      if (pr.dignity == 'Exalted' || pr.dignity == 'Moolatrikona' || pr.dignity == 'Own Sign') {
        add(EvidenceLayer.strength, Polarity.support, tr('$pn is ${pr.dignity.toLowerCase()}.', '$pn ${_dig(pr.dignity)} है।'), SourceTier.classicalDerived, 'Dignity');
      }

      // ---------------- E: varga (every supporting Varga of the domain) ----------------
      for (final vk in d.vargas) {
        if (vk == 'D1') continue;
        final div = _divisions[vk] ?? 1;
        final vLagna = VedicMath.vargaRashi(c.ascendantSidereal, vk, div);
        final vSign = VedicMath.vargaRashi(c.planetLongitudes[primaryLord]!, vk, div);
        final vHouse = VedicMath.houseOf(vSign, vLagna);
        final p = VedicMath.planets[primaryLord]!;
        final dign = p.exalt == vSign ? 'exalted' : (p.debi == vSign ? 'debilitated' : (p.ownSigns.contains(vSign) ? 'in its own sign' : null));
        final good = YogasMath.isKendra(vHouse) || YogasMath.isTrikona(vHouse) || dign == 'exalted' || dign == 'in its own sign';
        final bad = YogasMath.isDusthana(vHouse) || dign == 'debilitated';
        add(EvidenceLayer.varga, good && !bad ? Polarity.support : (bad && !good ? Polarity.obstruction : Polarity.neutral),
            tr('$vk: ${_n(primaryLord)} in ${VedicMath.rashis[vSign].name}, house $vHouse from the $vk Lagna${dign != null ? ', $dign' : ''}.',
                '$vk: ${_n(primaryLord)} ${L10n.sign(vSign)} में, $vk लग्न से $vHouseवें भाव में${dign == null ? '' : ', ${dign == 'exalted' ? 'उच्च' : (dign == 'debilitated' ? 'नीच' : 'स्वराशि')}'}।'),
            SourceTier.classicalDerived, 'BPHS Shodashavarga');
      }

      // ---------------- C: dasha ----------------
      final levels = L10n.hi ? const ['महादशा', 'अंतर्दशा', 'प्रत्यंतर्दशा', 'सूक्ष्मदशा'] : const ['Mahādaśā', 'Antardaśā', 'Pratyantardaśā', 'Sūkṣmadaśā'];
      final activeLevels = <int>[];
      for (int i = 0; i < running.length && i < 3; i++) {
        final lord = running[i].lord;
        final reasons = activationReasons(c, lord, d, cfg);
        if (reasons.isNotEmpty) {
          activeLevels.add(i);
          add(EvidenceLayer.dasha, i < 2 ? Polarity.support : Polarity.neutral,
              tr('${levels[i]} lord ${_n(lord)} ${reasons.join(', ')} (${running[i].startDate} – ${running[i].endDate}).',
                  '${levels[i]} स्वामी ${_n(lord)}: ${reasons.join(', ')} (${running[i].startDate} – ${running[i].endDate})।'),
              SourceTier.classicalDerived, 'Phaladeepika Dasha chapters; BPHS');
        }
      }
      if (running.length >= 2) {
        final m = running[0].lord, a = running[1].lord;
        if (m != a && c.planetLongitudes.containsKey(m) && c.planetLongitudes.containsKey(a)) {
          final dist = VedicMath.houseOf(VedicMath.rashiIndex(c.planetLongitudes[a]!), VedicMath.rashiIndex(c.planetLongitudes[m]!));
          if (const [6, 8, 12].contains(dist)) {
            add(EvidenceLayer.dasha, Polarity.obstruction, tr('Antardaśā lord ${_n(a)} is ${VedicMath.ordinal(dist)} from the Mahādaśā lord ${_n(m)} (6/8/12 relationship).',
                'अंतर्दशा स्वामी ${_n(a)} महादशा स्वामी ${_n(m)} से $distवें स्थान पर है (6/8/12 संबंध)।'),
                SourceTier.classicalDerived, 'BPHS Antardasha relationship');
          } else if (YogasMath.isKendra(dist) || YogasMath.isTrikona(dist)) {
            add(EvidenceLayer.dasha, Polarity.neutral, tr('Antardaśā lord ${_n(a)} is ${VedicMath.ordinal(dist)} from the Mahādaśā lord ${_n(m)} (supportive relationship).',
                'अंतर्दशा स्वामी ${_n(a)} महादशा स्वामी ${_n(m)} से $distवें स्थान पर है (सहायक संबंध)।'),
                SourceTier.classicalDerived, 'BPHS Antardasha relationship');
          }
        }
      }
      if (activeLevels.isEmpty && running.isNotEmpty) {
        add(EvidenceLayer.dasha, Polarity.neutral, tr('The current Daśā lords (${running.take(2).map((x) => _n(x.lord)).join(' / ')}) are not directly connected with this domain.',
            'वर्तमान दशा स्वामी (${running.take(2).map((x) => _n(x.lord)).join(' / ')}) इस क्षेत्र से सीधे नहीं जुड़े हैं।'),
            SourceTier.classicalDerived, 'Daśā activation rule (Vol. 5 §10)');
      }

      // ---------------- D: transit ----------------
      final contacts = <TransitContact>[];
      final domainTriggers = triggersFor(c, d, allTriggers);
      if (transit != null) {
        for (final tp in ['jupiter', 'saturn', 'rahu']) {
          final ts = VedicMath.rashiIndex(transit.planetLongitudes[tp]!);
          for (final h in d.bhavas.take(2)) {
            final target = (c.lagnaRashi + h - 1) % 12;
            final dist = VedicMath.houseOf(target, ts);
            final aspects = PrecisionMath.aspectHouses(tp, cfg).contains(dist);
            if (ts == target || aspects) {
              final support = AshtakavargaMath.transitSupport(av, tp, ts);
              final bindus = av.bindusFor(tp, ts);
              add(EvidenceLayer.transit, tp == 'jupiter' || (tp == 'saturn' && YogasMath.isUpachaya(h)) ? Polarity.support : Polarity.neutral,
                  tr('Transit ${_n(tp)} in ${VedicMath.rashis[ts].name} ${ts == target ? 'passes through' : 'aspects'} the ${VedicMath.ordinal(h)}${tp == 'rahu' ? '' : '; $support'}.',
                      'गोचर ${_n(tp)} ${L10n.sign(ts)} में ${ts == target ? '${_h(h)} भाव से गुज़र रहा है' : '${_h(h)} भाव को देख रहा है'}${tp == 'rahu' ? '' : '; $support'}।'),
                  SourceTier.classicalDerived, 'Phaladeepika transit chapter; BPHS Ashtakavarga', ruleId: 'R005');
              if (tp != 'rahu' && bindus < 4 && tp == 'jupiter') {
                add(EvidenceLayer.ashtakavarga, Polarity.obstruction, tr('Transit Jupiter has only $bindus bindus in ${VedicMath.rashis[ts].name}.', 'गोचर गुरु के ${L10n.sign(ts)} में केवल $bindus बिंदु हैं।'),
                    SourceTier.classicalDerived, 'BPHS Ashtakavarga', ruleId: 'R006');
              }
            }
          }
          final natalLord = lordOf(c, d.bhavas.first);
          final lordSign = VedicMath.rashiIndex(c.planetLongitudes[natalLord]!);
          if (tp != 'rahu' && (ts == lordSign || PrecisionMath.aspectHouses(tp, cfg).contains(VedicMath.houseOf(lordSign, ts)))) {
            add(EvidenceLayer.transit, tp == 'jupiter' ? Polarity.support : Polarity.neutral,
                tr('Transit ${_n(tp)} ${ts == lordSign ? 'joins' : 'aspects'} the natal ${VedicMath.ordinal(d.bhavas.first)} lord ${_n(natalLord)}.',
                    'गोचर ${_n(tp)} जन्म कुंडली के ${_h(d.bhavas.first)} भाव के स्वामी ${_n(natalLord)} ${ts == lordSign ? 'के साथ है' : 'को देख रहा है'}।'),
                SourceTier.classicalDerived, 'Phaladeepika transit chapter');
          }
        }
        for (final x in running.take(2)) {
          final lord = x.lord;
          if (!transit.planetLongitudes.containsKey(lord) || lord == 'rahu' || lord == 'ketu') continue;
          if (activationReasons(c, lord, d, cfg).isEmpty) continue;
          final ts = VedicMath.rashiIndex(transit.planetLongitudes[lord]!);
          final p = VedicMath.planets[lord]!;
          if (p.exalt == ts || p.ownSigns.contains(ts)) {
            add(EvidenceLayer.transit, Polarity.support, tr('Daśā lord ${_n(lord)} transits its ${p.exalt == ts ? 'exaltation' : 'own'} sign ${VedicMath.rashis[ts].name}, strengthening the houses it represents.',
                'दशा स्वामी ${_n(lord)} अपनी ${p.exalt == ts ? 'उच्च' : 'स्व'} राशि ${L10n.sign(ts)} में गोचर कर रहा है, जिससे उसके भाव मज़बूत होते हैं।'),
                SourceTier.classicalDirect, 'Phaladeepika (transit of the Daśā planet)', ruleId: 'R005');
          }
        }
        for (final t in domainTriggers.where((t) => t.activeAt(now))) {
          add(EvidenceLayer.transit, t.transit == 'jupiter' ? Polarity.support : Polarity.neutral,
              '${t.summary}; ${t.applyingAt(now) ? tr('applying', 'निकट आ रहा') : tr('separating', 'दूर जा रहा')} ${tr('now', 'अभी')}.',
              SourceTier.systematicSynthesis, 'Degree-exact transit trigger', ruleId: 'R021');
        }
        contacts.addAll(_ingresses(c, d, now));
      }

      // ---------------- F: ashtakavarga ----------------
      final sav = av.sarvaInHouse(d.bhavas.first);
      add(EvidenceLayer.ashtakavarga, sav >= 28 ? Polarity.support : (sav < 25 ? Polarity.obstruction : Polarity.neutral),
          tr('Sarvāṣṭakavarga of the ${VedicMath.ordinal(d.bhavas.first)}: $sav bindus (28 is average).', '${_h(d.bhavas.first)} भाव का सर्वाष्टकवर्ग: $sav बिंदु (28 औसत है)।'),
          SourceTier.classicalDerived, 'BPHS Ashtakavarga');

      // ---------------- status ----------------
      final ordered = [for (final l in EvidenceLayer.values) ...ev.where((e) => e.layer == l)];
      ev
        ..clear()
        ..addAll(ordered);
      int i = 1;
      for (final e in ev) {
        e.id = '${d.code}-EV${i++}';
      }
      final natalPlus = ev.where((e) => (e.layer == EvidenceLayer.natal || e.layer == EvidenceLayer.strength) && e.polarity == Polarity.support).length;
      final natalMinus = ev.where((e) => (e.layer == EvidenceLayer.natal || e.layer == EvidenceLayer.strength) && e.polarity == Polarity.obstruction).length;
      final statuses = <PredictionStatus>{};
      if (!c.planetLongitudes.containsKey('moon')) statuses.add(PredictionStatus.insufficientData);
      if (natalMinus > natalPlus + 1) {
        statuses.add(PredictionStatus.natalContradiction);
      } else if (natalPlus > natalMinus) {
        statuses.add(PredictionStatus.natalPromisePresent);
      } else {
        statuses.add(PredictionStatus.natalPromiseWeak);
      }
      final dashaOn = activeLevels.any((l) => l < 2);
      final transitOn = ev.any((e) => e.layer == EvidenceLayer.transit && e.polarity == Polarity.support);
      final vargaOn = ev.any((e) => e.layer == EvidenceLayer.varga && e.polarity == Polarity.support);
      if (dashaOn) statuses.add(PredictionStatus.timingActive);
      if (transitOn) statuses.add(PredictionStatus.transitConfirmed);
      if (vargaOn) statuses.add(PredictionStatus.vargaConfirmed);
      final layersOn = [statuses.contains(PredictionStatus.natalPromisePresent), dashaOn, transitOn, vargaOn || d.vargas.length == 1];
      final agreeing = layersOn.where((x) => x).length;
      if (agreeing >= 2 && agreeing < 4) statuses.add(PredictionStatus.partialConvergence);
      final supportLayers = EvidenceLayer.values.where((l) => ev.any((e) => e.layer == l && e.polarity == Polarity.support && e.tier != SourceTier.systematicSynthesis)).length;
      final tier = supportLayers >= 3 ? SourceTier.multiSourceConvergence : SourceTier.systematicSynthesis;

      final dashaWindows = windows(c, d, dashas, cfg, now);
      final timing = intersect(d, dashaWindows, dashas, domainTriggers, now, c);

      // Volume 6 status and confidence (§45-46).
      final insufficient = statuses.contains(PredictionStatus.insufficientData);
      final contradiction = statuses.contains(PredictionStatus.natalContradiction);
      final promise = statuses.contains(PredictionStatus.natalPromisePresent);
      final currentTrigger = domainTriggers.any((t) => t.activeAt(now));
      final V6Status v6 = insufficient
          ? V6Status.insufficientData
          : contradiction
              ? V6Status.conflicted
              : natalPlus == 0
                  ? V6Status.notSupported
                  : (promise && dashaOn && (transitOn || currentTrigger))
                      ? V6Status.confirmedByTransit
                      : (promise && dashaOn)
                          ? V6Status.activated
                          : (promise && timing.isNotEmpty)
                              ? V6Status.timingWindow
                              : (promise && (layerHasSupport(ev, EvidenceLayer.strength) || vargaOn))
                                  ? V6Status.supported
                                  : V6Status.natalPromise;
      // Layers whose supporting evidence outweighs the obstructing evidence.
      final netLayers = EvidenceLayer.values.where((l) {
        final items = ev.where((e) => e.layer == l);
        return items.where((e) => e.polarity == Polarity.support).length > items.where((e) => e.polarity == Polarity.obstruction).length;
      }).length;
      final Confidence confidence = insufficient
          ? Confidence.insufficient
          : contradiction
              ? Confidence.conflicted
              : (promise && dashaOn && (transitOn || currentTrigger) && netLayers >= 5)
                  ? Confidence.veryStrong
                  : (promise && dashaOn && netLayers >= 4)
                      ? Confidence.strong
                      : netLayers >= 3
                          ? Confidence.moderate
                          : Confidence.low;

      // Master KB dependency template (required layers).
      String layerState(Iterable<Evidence> xs, {bool applicable = true}) {
        if (!applicable) return 'NOT_APPLICABLE';
        final plus = xs.any((e) => e.polarity == Polarity.support), minus = xs.any((e) => e.polarity == Polarity.obstruction);
        return plus && minus ? 'MIXED' : (plus ? 'SUPPORTING' : (minus ? 'OPPOSING' : 'ABSENT'));
      }

      final hasConj = conjunctions.any((x) => d.bhavas.contains(x.record.bhava));
      final dependencies = {
        'NATAL_PROMISE': layerState(ev.where((e) => e.layer == EvidenceLayer.natal)),
        'BHAVA_LORD_CHAIN': layerState(ev.where((e) => e.ruleId == 'R001')),
        'PLANETARY_STRENGTH': layerState(ev.where((e) => e.layer == EvidenceLayer.strength)),
        'CONJUNCTION_SYNTHESIS': hasConj ? 'PRESENT' : 'NOT_APPLICABLE',
        'DASHA_ACTIVATION': layerState(ev.where((e) => e.layer == EvidenceLayer.dasha)),
        'TRANSIT_CONFIRMATION': layerState(ev.where((e) => e.layer == EvidenceLayer.transit), applicable: transit != null),
      };
      final required = dependencies.values.where((v) => v != 'NOT_APPLICABLE' && v != 'PRESENT');
      final masterStatus = insufficient
          ? 'INSUFFICIENT_INPUT'
          : (contradiction || (natalPlus == 0 && natalMinus > 0))
              ? 'CONFLICTED'
              : required.every((v) => v == 'SUPPORTING' || v == 'MIXED')
                  ? 'SUPPORTED'
                  : 'CONDITIONALLY_SUPPORTED';

      // Rule trace and audit counts (§62-63).
      if (timing.isNotEmpty) rulesRun.add('R022');
      final fired = {for (final e in ev) e.ruleId};
      if (timing.isNotEmpty) fired.add('R022');
      final trace = {for (final r in rulesRun.toList()..sort()) r: fired.contains(r)};
      final anySupport = ev.any((e) => e.polarity == Polarity.support);
      final conflictedRules = {for (final e in ev) if (e.polarity == Polarity.obstruction && anySupport) e.ruleId};
      executed += rulesRun.length;
      triggered += fired.length;
      conflicted += conflictedRules.length;

      final interpretation = _language(d, agreeing, natalPlus, natalMinus, dashaOn, transitOn, statuses);
      out.add(DomainSynthesis(d, ev, chains, statuses, tier, interpretation, dashaWindows, contacts,
          v6Status: v6,
          confidence: confidence,
          dependencies: dependencies,
          masterStatus: masterStatus,
          triggers: domainTriggers,
          timingWindows: timing,
          ruleTrace: trace,
          graph: _graph(c, d, ev, v6, running, timing)));
    }

    final audit = SynthesisEngine.audit(c, cfg, now)
      ..['rules_executed'] = '$executed'
      ..['rules_triggered'] = '$triggered'
      ..['rules_conflicted'] = '$conflicted';
    audit['run_id'] = 'RUN-${TimingMath.sha256Of({'inputs': audit['inputs_hash'], 'at': now.toStringAsFixed(5)}).substring(0, 12).toUpperCase()}';
    return SynthesisReport(c, out, flags, audit, running.map((r) => r.lord).toList(), jaimini: jaimini, sensitivity: sensitivity);
  }

  static bool layerHasSupport(List<Evidence> ev, EvidenceLayer l) => ev.any((e) => e.layer == l && e.polarity == Polarity.support);

  /// Amatyakaraka for career, Darakaraka and Upapada for marriage, Atmakaraka
  /// and Arudha Lagna for identity (Jaimini; configurable karaka scheme).
  static void _jaiminiEvidence(ChartData c, LifeDomain d, JaiminiResult j, Map<String, GrahaRecord> recs,
      void Function(EvidenceLayer, Polarity, String, SourceTier, String, {String? ruleId}) add, Set<String> rulesRun) {
    void karaka(String code, int house) {
      final k = j.karaka(code);
      if (k == null) return;
      rulesRun.add('R019');
      final r = recs[k.planet]!;
      final h = VedicMath.houseOf(r.rashi, c.lagnaRashi);
      final link = h == house || housesOwned(c, k.planet).contains(house) || aspectingHouse(c, house, CalcConfig.defaults).contains(k.planet);
      final good = r.dignity == 'Exalted' || r.dignity == 'Own Sign' || r.dignity == 'Moolatrikona';
      final bad = r.dignity == 'Debilitated' || r.combust;
      add(EvidenceLayer.natal, good || (link && !bad) ? Polarity.support : (bad ? Polarity.obstruction : Polarity.neutral),
          tr(
              '${k.name} (${k.code}, ${k.signifies}) is ${_n(k.planet)} in the ${VedicMath.ordinal(h)}${link ? ', linked to the ${VedicMath.ordinal(house)}' : ''}'
                  '${good || bad ? ' (${bad ? (r.combust ? 'combust' : 'debilitated') : r.dignity.toLowerCase()})' : ''}.',
              '${k.name} (${k.code}, ${k.signifies}) ${_n(k.planet)} है, ${_h(h)} भाव में${link ? ', ${_h(house)} भाव से जुड़ा' : ''}'
                  '${good || bad ? ' (${bad ? (r.combust ? 'अस्त' : 'नीच') : _dig(r.dignity)})' : ''}।'),
          SourceTier.configurableTradition, 'Jaimini Chara Karaka (${j.scheme}-karaka scheme)', ruleId: 'R019');
    }

    void pada(ArudhaPada a, String meaning) {
      rulesRun.add('R020');
      final lord = VedicMath.rashis[a.rashi].lord;
      final lr = recs[lord]!;
      final malefics = [
        for (final p in ['sun', 'mars', 'saturn', 'rahu', 'ketu'])
          if (c.planetLongitudes.containsKey(p) && VedicMath.houseOf(VedicMath.rashiIndex(c.planetLongitudes[p]!), a.rashi) == 2) p,
      ];
      final benefics = [
        for (final p in ['jupiter', 'venus', 'mercury'])
          if (c.planetLongitudes.containsKey(p) && VedicMath.houseOf(VedicMath.rashiIndex(c.planetLongitudes[p]!), a.rashi) == 2) p,
      ];
      add(EvidenceLayer.natal, benefics.isNotEmpty && malefics.isEmpty ? Polarity.support : (malefics.isNotEmpty && benefics.isEmpty ? Polarity.obstruction : Polarity.neutral),
          tr(
              '${a.name} (${a.code}, $meaning) falls in ${VedicMath.rashis[a.rashi].name}, the ${VedicMath.ordinal(a.fromLagna)} from the Lagna; its lord ${_n(lord)} is in house ${lr.house}'
                  '${benefics.isNotEmpty ? '; benefics ${benefics.map(_n).join(', ')} in the 2nd from it' : ''}${malefics.isNotEmpty ? '; malefics ${malefics.map(_n).join(', ')} in the 2nd from it' : ''}.',
              '${a.name} (${a.code}, $meaning) ${L10n.sign(a.rashi)} राशि में, लग्न से ${_h(a.fromLagna)} भाव में; इसका स्वामी ${_n(lord)} भाव ${lr.house} में'
                  '${benefics.isNotEmpty ? '; इससे दूसरे भाव में शुभ ग्रह ${benefics.map(_n).join(', ')}' : ''}${malefics.isNotEmpty ? '; इससे दूसरे भाव में पाप ग्रह ${malefics.map(_n).join(', ')}' : ''}।'),
          SourceTier.classicalDerived, 'Jaimini Arudha / Upapada', ruleId: 'R020');
    }

    switch (d.id) {
      case 'career':
        karaka('AmK', 10);
      case 'marriage':
        karaka('DK', 7);
        pada(j.upapada, tr('marriage and its continuity', 'विवाह और उसकी निरंतरता'));
      case 'identity':
        karaka('AK', 1);
        pada(j.arudhaLagna, tr('public image', 'सार्वजनिक छवि'));
      case 'children':
        karaka('PK', 5);
      case 'home':
        karaka('MK', 4);
      case 'skills':
        karaka('BK', 3);
      case 'fortune':
        if (j.scheme == 8) karaka('PiK', 9);
      case 'spiritual':
        karaka('AK', 12);
    }
  }

  /// Triggers on this domain's factors: lords and karakas of its houses, and
  /// the cusps of its first two houses.
  static List<TransitTrigger> triggersFor(ChartData c, LifeDomain d, List<TransitTrigger> all) {
    final codes = <String>{
      for (final h in d.bhavas) 'NATAL_${lordOf(c, h).toUpperCase()}',
      for (final k in d.karakas) 'NATAL_${k.toUpperCase()}',
      for (final h in d.bhavas.take(2)) 'BHAVA_$h',
    };
    return all.where((t) => codes.contains(t.target.code)).toList();
  }

  /// Daśā windows intersected with transit triggers (Volume 6 §91): each
  /// exact trigger pass is clipped to the Antardaśā that activates the domain,
  /// and overlapping passes are merged. The result is a set of windows, not dates.
  static List<TimingWindow> intersect(LifeDomain d, List<EventWindow> dashaWindows, DashaCalculations dashas, List<TransitTrigger> triggers, double now, ChartData c) {
    final out = <TimingWindow>[];
    final exact = triggers.where((t) => t.exactJds.isNotEmpty && t.exitJd > now).toList()..sort((a, b) => a.enterJd.compareTo(b.enterJd));
    for (final w in dashaWindows) {
      final lo = w.startJd > now ? w.startJd : now;
      final hits = exact.where((t) => t.enterJd < w.endJd && t.exitJd > lo).toList();
      if (hits.isEmpty) continue;
      final md = dashas.runningAt((w.startJd + w.endJd) / 2);
      if (md.length < 2) continue;
      // Merge overlapping passes.
      final groups = <List<TransitTrigger>>[];
      double groupEnd = -1;
      for (final t in hits) {
        if (groups.isEmpty || t.enterJd > groupEnd) {
          groups.add([t]);
          groupEnd = t.exitJd;
        } else {
          groups.last.add(t);
          if (t.exitJd > groupEnd) groupEnd = t.exitJd;
        }
      }
      for (final g in groups) {
        final first = g.map((t) => t.enterJd).reduce((a, b) => a < b ? a : b);
        final last = g.map((t) => t.exitJd).reduce((a, b) => a > b ? a : b);
        final s = first > lo ? first : lo;
        final e = last < w.endJd ? last : w.endJd;
        if (e <= s) continue;
        final current = s <= now && now <= e && g.any((t) => t.activeAt(now));
        out.add(TimingWindow(
          d.v6Name,
          s,
          e,
          VedicMath.jdToDate(s + c.utcOffset / 24),
          VedicMath.jdToDate(e + c.utcOffset / 24),
          ['${md[0].lord.toUpperCase()}_MD', '${md[1].lord.toUpperCase()}_AD', ...{for (final t in g) t.tag}],
          current ? 'CONFIRMED_BY_TRANSIT' : 'TIMING_WINDOW',
          g,
        ));
      }
    }
    out.sort((a, b) => a.startJd.compareTo(b.startJd));
    return out;
  }

  /// Explanation graph: prediction → event → layer → evidence → rule → source,
  /// with planets, houses, Daśā lords and triggers as linked nodes.
  static ExplanationGraph _graph(ChartData c, LifeDomain d, List<Evidence> ev, V6Status status, List<DashaPeriod> running, List<TimingWindow> timing) {
    final g = ExplanationGraph();
    final pred = 'PRED:${d.code}';
    final event = 'EVENT:${d.code}';
    g.node(pred, 'Prediction', '${d.v6Name}: ${status.code}');
    g.node(event, 'Event', d.name);
    g.edge(pred, event, 'APPLIES_TO');
    for (final h in d.bhavas) {
      g.node('HOUSE:$h', 'House', '${VedicMath.ordinal(h)} house');
      g.edge(event, 'HOUSE:$h', 'JUDGED_FROM');
      final lord = lordOf(c, h);
      g.node('PLANET:${lord.toUpperCase()}', 'Planet', _n(lord));
      g.edge('PLANET:${lord.toUpperCase()}', 'HOUSE:$h', 'LORDS');
    }
    final levels = ['MD', 'AD', 'PD', 'SD'];
    for (int i = 0; i < running.length && i < 2; i++) {
      final id = 'DASHA:${levels[i]}:${running[i].lord.toUpperCase()}';
      g.node(id, 'Dasha', '${levels[i]} ${_n(running[i].lord)}');
      g.node('PLANET:${running[i].lord.toUpperCase()}', 'Planet', _n(running[i].lord));
      g.edge(id, event, 'ACTIVATES');
      g.edge('PLANET:${running[i].lord.toUpperCase()}', id, 'LORDS');
    }
    for (final l in EvidenceLayer.values) {
      final items = ev.where((e) => e.layer == l).toList();
      if (items.isEmpty) continue;
      final lid = 'LAYER:${d.code}:${l.level}';
      g.node(lid, 'Layer', l.label);
      g.edge(event, lid, 'EVIDENCE_LAYER');
      for (final e in items) {
        final eid = 'EV:${e.id}';
        g.node(eid, 'Evidence', '${e.mark} ${e.text}');
        g.edge(lid, eid, 'CONTAINS');
        g.edge(eid, event, switch (e.polarity) { Polarity.support => 'SUPPORTS', Polarity.obstruction => 'CONFLICTS_WITH', Polarity.neutral => 'MODIFIES' });
        final rule = KnowledgeRegistry.rule(e.ruleId);
        g.node('RULE:${rule.id}', 'Rule', '${rule.id} ${rule.name}');
        g.edge(eid, 'RULE:${rule.id}', 'DERIVED_FROM');
        for (final s in rule.sourceIds) {
          g.node('SRC:$s', 'Source', KnowledgeRegistry.sourceLabel(s));
          g.edge('RULE:${rule.id}', 'SRC:$s', 'SUPPORTED_BY');
        }
        for (final p in Ephemeris.planetOrder) {
          if (e.text.contains(_n(p)) && g.nodes.containsKey('PLANET:${p.toUpperCase()}')) g.edge(eid, 'PLANET:${p.toUpperCase()}', 'APPLIES_TO');
        }
      }
    }
    for (final w in timing.take(5)) {
      final wid = 'WINDOW:${d.code}:${w.start}';
      g.node(wid, 'TimingWindow', '${w.start} – ${w.end} ${w.activation.join(', ')}');
      g.edge(pred, wid, 'HAS_WINDOW');
      for (final t in w.triggers) {
        final tid = 'TRIGGER:${t.tag}:${t.enterDate}';
        g.node(tid, 'Transit', t.summary);
        g.edge(tid, wid, 'TRIGGERS');
      }
    }
    return g;
  }

  /// Evidence-calibrated wording (Volume 5 §35); never deterministic.
  static String _language(LifeDomain d, int agreeing, int plus, int minus, bool dasha, bool transit, Set<PredictionStatus> st) {
    final theme = L10n.hi ? Interpret.domainName(d) : d.name.toLowerCase();
    String s;
    if (st.contains(PredictionStatus.insufficientData)) {
      s = tr('The available data do not establish this reliably.', 'उपलब्ध जानकारी से यह विश्वसनीय रूप से स्थापित नहीं होता।');
    } else if (st.contains(PredictionStatus.natalContradiction)) {
      s = tr('The chart contains both supporting and obstructing indicators for $theme; the result is conditional on the modifying factors listed.',
          'कुंडली में $theme के लिए सहायक और बाधक दोनों संकेत हैं; परिणाम सूचीबद्ध संशोधक कारकों पर निर्भर है।');
    } else if (agreeing >= 4) {
      s = tr('The chart contains multiple converging indications for $theme: the natal promise is supported, the active period directly connects with it, and the timing is reinforced by transits.',
          'कुंडली में $theme के लिए कई मिलते-जुलते संकेत हैं: जन्म का वादा समर्थित है, चल रही दशा सीधे इससे जुड़ी है और गोचर समय को मज़बूत करता है।');
    } else if (agreeing >= 2) {
      s = tr(
          'The chart indicates $theme, but ${!dasha ? 'the current Daśā does not strongly activate it' : (!transit ? 'transit support is partial' : 'Varga confirmation is limited')}. '
              '${minus > 0 ? 'Several factors support it while $minus modify the result.' : ''}',
          'कुंडली $theme का संकेत देती है, पर ${!dasha ? 'वर्तमान दशा इसे प्रबल रूप से सक्रिय नहीं करती' : (!transit ? 'गोचर का सहारा आंशिक है' : 'वर्ग पुष्टि सीमित है')}। '
              '${minus > 0 ? 'कई कारक इसका समर्थन करते हैं जबकि $minus परिणाम को बदलते हैं।' : ''}');
    } else {
      s = tr('The theme of $theme is present in the chart with limited support and is not strongly activated at present.',
          '$theme का विषय कुंडली में सीमित समर्थन के साथ है और अभी प्रबल रूप से सक्रिय नहीं है।');
    }
    if (d.caution != null) s = '$s ${domainCaution(d)}';
    return s.trim();
  }

  static String? domainCaution(LifeDomain d) => d.caution == null
      ? null
      : tr(d.caution!, switch (d.id) {
          'wealth' => 'कर्ज़ और हानि अलग से 6, 8 और 12वें भाव से देखे जाते हैं।',
          'health' => 'यह केवल पारंपरिक संकेत है; चिकित्सकीय मूल्यांकन नहीं।',
          _ => d.caution!,
        });

  /// Future Antardaśās (next ~15 years) whose lords activate the domain, with
  /// Pratyantardaśā peaks inside them.
  static List<EventWindow> windows(ChartData c, LifeDomain d, DashaCalculations dashas, CalcConfig cfg, double now, {double years = 15}) {
    final until = now + years * DashaCalculations.yearDays;
    final out = <EventWindow>[];
    for (final md in dashas.mahadashas) {
      if (md.endJD < now || md.startJD > until) continue;
      final mdReasons = activationReasons(c, md.lord, d, cfg);
      for (final ad in md.subPeriods) {
        if (ad.endJD < now || ad.startJD > until) continue;
        final adReasons = activationReasons(c, ad.lord, d, cfg);
        if (adReasons.isEmpty || (mdReasons.isEmpty && adReasons.length < 2)) continue;
        final peaks = [
          for (final pd in ad.subPeriods)
            if (pd.endJD > now && activationReasons(c, pd.lord, d, cfg).isNotEmpty) '${_n(pd.lord)} ${pd.startDate} – ${pd.endDate}',
        ];
        out.add(EventWindow(
          '${_n(md.lord)} / ${_n(ad.lord)}',
          ad.startJD,
          ad.endJD,
          ad.startDate,
          ad.endDate,
          [
            if (mdReasons.isNotEmpty) '${tr('MD', 'महादशा')} ${_n(md.lord)}: ${mdReasons.join(', ')}',
            '${tr('AD', 'अंतर्दशा')} ${_n(ad.lord)}: ${adReasons.join(', ')}',
          ],
          peaks,
        ));
      }
    }
    return out;
  }

  /// Jupiter and Saturn entering the domain's primary house sign during the next three years.
  static List<TransitContact> _ingresses(ChartData c, LifeDomain d, double now, {double years = 3}) {
    final out = <TransitContact>[];
    final target = (c.lagnaRashi + d.bhavas.first - 1) % 12;
    for (final p in ['jupiter', 'saturn']) {
      int? prev;
      int entries = 0;
      for (double jd = now; jd < now + years * 365.25; jd += 4) {
        final (lon, speed) = Ephemeris.siderealPosition(p, jd);
        final r = VedicMath.rashiIndex(lon);
        if (prev != null && r == target && prev != target) {
          entries++;
          out.add(TransitContact(p, r, jd, VedicMath.jdToDate(jd + c.utcOffset / 24), entries > 1 || speed < 0,
              tr('${_n(p)} enters ${VedicMath.rashis[r].name} (the ${VedicMath.ordinal(d.bhavas.first)})${entries > 1 ? ' again after retrogression' : ''}',
                  '${_n(p)} ${L10n.sign(r)} (${_h(d.bhavas.first)} भाव) में प्रवेश${entries > 1 ? ' — वक्री होने के बाद फिर से' : ''}')));
        }
        prev = r;
      }
      if (prev == null) continue;
      final (lon0, _) = Ephemeris.siderealPosition(p, now);
      if (VedicMath.rashiIndex(lon0) == target && out.where((t) => t.planet == p).isEmpty) {
        out.add(TransitContact(p, target, now, VedicMath.jdToDate(now + c.utcOffset / 24), false,
            tr('${_n(p)} is already in ${VedicMath.rashis[target].name}', '${_n(p)} पहले से ${L10n.sign(target)} में है')));
      }
    }
    out.sort((a, b) => a.jd.compareTo(b.jd));
    return out;
  }

  /// Safety / quality flags (Volume 5 §41).
  static List<InputFlag> inputFlags(ChartData c, CalcConfig cfg) {
    final out = <InputFlag>[];
    final ascDeg = VedicMath.degInRashi(c.ascendantSidereal);
    final edge = ascDeg < 15 ? ascDeg : 30 - ascDeg;
    if (edge < 0.25) {
      out.add(InputFlag('critical', tr('The Lagna is ${edge.toStringAsFixed(2)}° from a sign boundary: about one minute of birth time changes the Lagna and every house.',
          'लग्न राशि सीमा से ${edge.toStringAsFixed(2)}° पर है: जन्म समय में लगभग एक मिनट का अंतर लग्न और सभी भाव बदल देता है।')));
    } else if (edge < 1) {
      out.add(InputFlag('warning', tr('The Lagna is ${edge.toStringAsFixed(2)}° from a sign boundary: a few minutes of birth time change the houses.',
          'लग्न राशि सीमा से ${edge.toStringAsFixed(2)}° पर है: जन्म समय में कुछ मिनट का अंतर भाव बदल देता है।')));
    }
    final moon = c.planetLongitudes['moon'];
    if (moon != null) {
      const span = 360 / 27;
      final into = VedicMath.norm360(moon) % span;
      if (into < 0.15 || span - into < 0.15) {
        out.add(InputFlag('warning', tr('The Moon is at a nakshatra boundary: the starting Daśā lord depends on the exact birth time.', 'चन्द्र नक्षत्र सीमा पर है: पहली दशा का स्वामी सटीक जन्म समय पर निर्भर है।')));
      }
    }
    final sandhi = PrecisionMath.records(c, cfg).values.where((r) => r.sandhi).map((r) => r.name).toList();
    if (sandhi.isNotEmpty) out.add(InputFlag('info', '${tr('Near a Bhāva-sandhi', 'भाव-संधि के पास')}: ${sandhi.join(', ')}.'));
    out.add(InputFlag('info', tr('Birth time is recorded to the minute (no seconds); degree-sensitive results assume it is exact.', 'जन्म समय मिनट तक दर्ज है (सेकंड नहीं); अंश-संवेदनशील परिणाम इसे सटीक मानते हैं।')));
    return out;
  }

  /// Audit log (Volume 5 §44): everything needed to reproduce the result.
  static Map<String, String> audit(ChartData c, CalcConfig cfg, double now) => {
        'engine_version': CalcConfig.engineVersion,
        'knowledge_registry_version': KnowledgeRegistry.version,
        'inputs_hash': TimingMath.inputsHash(c, cfg),
        'calculation_hash': TimingMath.calculationHash(c),
        'source_versions': sourceVersions,
        'ephemeris': Ephemeris.ephemerisLabel,
        'ayanamsha': '${Ephemeris.ayanamsaLabel}; value ${c.ayanamsa.toStringAsFixed(6)}°',
        'node_model': Ephemeris.nodeModel,
        ...cfg.ruleVersions,
        'input_birth_data': 'JD(UT) ${c.jd.toStringAsFixed(6)}, lat ${c.lat.toStringAsFixed(4)}, lon ${c.lon.toStringAsFixed(4)}, UTC offset ${c.utcOffset}',
        'calculation_timestamp': Ephemeris.jdToUtc(now).toIso8601String(),
        'dasha_convention': 'Vimshottari, ${DashaCalculations.yearDays}-day years, Moon nakshatra balance',
      };

  // ---------------------------------------------------------------------------
  // Rectification and backtesting
  // ---------------------------------------------------------------------------

  static LifeDomain domain(String id) => domains.firstWhere((d) => d.id == id);

  /// Daśā lords running at [jd] for [chart].
  static List<DashaPeriod> periodsAt(ChartData chart, double jd) =>
      DashaCalculations.compute(chart.jd, chart.planetLongitudes['moon']!, utcOffset: chart.utcOffset).runningAt(jd);

  static BacktestResult backtest(ChartData chart, LifeEvent e, {CalcConfig cfg = CalcConfig.defaults}) {
    final jd = Ephemeris.julianDay(e.date.year, e.date.month, e.date.day, 12 - chart.utcOffset);
    final periods = periodsAt(chart, jd);
    final trace = <String>[];
    final activated = <String>[];
    for (final d in domains) {
      final md = periods.isNotEmpty ? activationReasons(chart, periods[0].lord, d, cfg) : <String>[];
      final ad = periods.length > 1 ? activationReasons(chart, periods[1].lord, d, cfg) : <String>[];
      if (md.isNotEmpty && ad.isNotEmpty) activated.add(d.id);
      if (d.id == e.domainId) {
        if (md.isNotEmpty) trace.add('${tr('Natal (known before the event): MD', 'जन्म कुंडली (घटना से पहले ज्ञात): महादशा')} ${_n(periods[0].lord)} ${md.join(', ')}');
        if (ad.isNotEmpty) trace.add('${tr('Natal (known before the event): AD', 'जन्म कुंडली (घटना से पहले ज्ञात): अंतर्दशा')} ${_n(periods[1].lord)} ${ad.join(', ')}');
        if (md.isEmpty && ad.isEmpty) {
          trace.add(tr('Neither the MD nor the AD lord connects with ${d.name.toLowerCase()}.', 'न महादशा न अंतर्दशा का स्वामी ${Interpret.domainName(d)} से जुड़ता है।'));
        }
      }
    }
    try {
      final t = Ephemeris.computeChartForJd(jd, chart.lat, chart.lon, utcOffset: chart.utcOffset);
      final d = domain(e.domainId);
      final target = (chart.lagnaRashi + d.bhavas.first - 1) % 12;
      for (final p in ['jupiter', 'saturn']) {
        final ts = VedicMath.rashiIndex(t.planetLongitudes[p]!);
        final dist = VedicMath.houseOf(target, ts);
        if (ts == target || PrecisionMath.aspectHouses(p, cfg).contains(dist)) {
          trace.add(tr('Transit at the event: ${_n(p)} in ${VedicMath.rashis[ts].name} ${ts == target ? 'in' : 'aspecting'} the ${VedicMath.ordinal(d.bhavas.first)}.',
              'घटना के समय गोचर: ${_n(p)} ${L10n.sign(ts)} में, ${_h(d.bhavas.first)} भाव ${ts == target ? 'में' : 'पर दृष्टि'}।'));
        }
      }
    } catch (_) {}
    final mdAd = periods.take(3).map((p) => _n(p.lord)).join(' / ');
    return BacktestResult(e, [mdAd], activated, activated.contains(e.domainId), trace);
  }

  /// Candidate birth times around [base] (minutes), scored against known events.
  /// The birth time itself is never changed; every candidate stays visible.
  static List<RectificationCandidate> rectify(
    ChartData Function(int offsetMinutes) chartAt,
    List<LifeEvent> events, {
    int rangeMinutes = 30,
    int stepMinutes = 5,
    CalcConfig cfg = CalcConfig.defaults,
  }) {
    final out = <RectificationCandidate>[];
    for (int m = -rangeMinutes; m <= rangeMinutes; m += stepMinutes) {
      final c = chartAt(m);
      double score = 0;
      final details = <String>[
        '${tr('Lagna', 'लग्न')} ${L10n.sign(c.lagnaRashi)} ${VedicMath.formatDegree(c.ascendantSidereal)}',
        '${tr('D9 Lagna', 'D9 लग्न')} ${L10n.sign(VedicMath.vargaRashi(c.ascendantSidereal, 'D9', 9))}, '
            '${tr('D10 Lagna', 'D10 लग्न')} ${L10n.sign(VedicMath.vargaRashi(c.ascendantSidereal, 'D10', 10))}',
      ];
      final first = DashaCalculations.compute(c.jd, c.planetLongitudes['moon']!, utcOffset: c.utcOffset).mahadashas.first;
      details.add('${tr('Daśā balance', 'दशा शेष')}: ${_n(first.lord)} ${((first.endJD - c.jd) / DashaCalculations.yearDays).toStringAsFixed(2)} ${tr('years', 'वर्ष')}');
      for (final e in events) {
        final jd = Ephemeris.julianDay(e.date.year, e.date.month, e.date.day, 12 - c.utcOffset);
        final periods = periodsAt(c, jd);
        final d = domain(e.domainId);
        final md = periods.isNotEmpty ? activationReasons(c, periods[0].lord, d, cfg).length : 0;
        final ad = periods.length > 1 ? activationReasons(c, periods[1].lord, d, cfg).length : 0;
        final pd = periods.length > 2 ? activationReasons(c, periods[2].lord, d, cfg).length : 0;
        final s = (md > 0 ? 1 : 0) + (ad > 0 ? 1.5 : 0) + (pd > 0 ? 0.5 : 0);
        score += s;
        details.add('${e.date.year}-${e.date.month.toString().padLeft(2, '0')} ${Interpret.domainName(d)}: '
            '${periods.take(3).map((p) => _n(p.lord)).join('/')} → ${s == 0 ? tr('no activation', 'सक्रियता नहीं') : '+${s.toStringAsFixed(1)}'}');
      }
      out.add(RectificationCandidate(m, c, score, details));
    }
    return out;
  }
}
