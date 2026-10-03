import 'ashtakavarga_math.dart';
import 'calc_config.dart';
import 'conjunction_db.dart';
import 'ephemeris.dart';
import 'precision_math.dart';
import 'shadbala_math.dart';
import 'vedic_math.dart';
import 'yogas_math.dart';

/// Evidence layers (Volume 5 §17).
enum EvidenceLayer {
  natal('A', 'Natal promise'),
  strength('B', 'Strength'),
  dasha('C', 'Daśā activation'),
  transit('D', 'Transit confirmation'),
  varga('E', 'Varga confirmation'),
  ashtakavarga('F', 'Ashtakavarga support');

  final String level;
  final String label;
  const EvidenceLayer(this.level, this.label);
}

enum Polarity { support, obstruction, neutral }

/// Technical evidence states (Volume 5 §18) - not guaranteed-event labels.
enum PredictionStatus {
  natalPromisePresent('NATAL_PROMISE_PRESENT', 'Natal chart contains relevant indicators'),
  natalPromiseWeak('NATAL_PROMISE_WEAK', 'Indication exists but support is limited'),
  natalContradiction('NATAL_CONTRADICTION', 'Significant opposing natal indicators'),
  timingActive('TIMING_ACTIVE', 'Current Daśā activates relevant factors'),
  transitConfirmed('TRANSIT_CONFIRMED', 'Transit independently activates the domain'),
  vargaConfirmed('VARGA_CONFIRMED', 'Relevant Varga supports the indication'),
  partialConvergence('PARTIAL_CONVERGENCE', 'Several layers agree, one or more absent or conflicting'),
  insufficientData('INSUFFICIENT_DATA', 'Calculation cannot be completed');

  final String code;
  final String label;
  const PredictionStatus(this.code, this.label);
}

class Evidence {
  final EvidenceLayer layer;
  final Polarity polarity;
  final String text;
  final SourceTier tier;
  final String rule;
  String id = '';
  Evidence(this.layer, this.polarity, this.text, this.tier, this.rule);

  String get mark => switch (polarity) { Polarity.support => '✓', Polarity.obstruction => '✗', Polarity.neutral => '△' };
}

class LifeDomain {
  final String id;
  final String name;
  final List<int> bhavas;
  final List<String> karakas;
  final String varga;
  final List<String> dimensions;
  final String? caution;
  const LifeDomain(this.id, this.name, this.bhavas, this.karakas, this.varga, this.dimensions, {this.caution});
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

  const DomainSynthesis(this.domain, this.evidence, this.lordChains, this.statuses, this.tier, this.interpretation, this.windows, this.transits);

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
        b.writeln('${e.mark} [${e.id}] ${e.text}');
      }
    }
    b.writeln('\nSTATUS: ${statuses.map((s) => s.code).join(', ')}');
    b.writeln('SOURCE TIER: ${tier.code}');
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
  const SynthesisReport(this.chart, this.domains, this.inputFlags, this.audit, this.running);
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
      'Conjunction Database Vol. 2 (3 Oct 2026), Vol. 3 (3 Oct 2026), Vol. 4 (3 Oct 2026), Vol. 5 (3 Oct 2026); Yoga guide (2 Oct 2026)';

  static const Map<int, List<String>> houseKarakas = {
    1: ['sun'], 2: ['jupiter'], 3: ['mars'], 4: ['moon'], 5: ['jupiter'], 6: ['mars', 'saturn'], 7: ['venus'],
    8: ['saturn'], 9: ['jupiter', 'sun'], 10: ['sun', 'mercury', 'jupiter', 'saturn'], 11: ['jupiter'], 12: ['saturn'],
  };

  static const List<LifeDomain> domains = [
    LifeDomain('identity', 'Identity & vitality', [1], ['sun'], 'D1', ['temperament', 'self-direction', 'vitality']),
    LifeDomain('wealth', 'Wealth & savings', [2, 11, 5, 9], ['jupiter', 'venus'], 'D2',
        ['accumulated wealth', 'income', 'speculation', 'fortune'], caution: 'Debt and loss are judged separately from the 6th, 8th and 12th.'),
    LifeDomain('skills', 'Skills, communication & siblings', [3], ['mars', 'mercury'], 'D3', ['initiative', 'communication', 'younger siblings']),
    LifeDomain('home', 'Home, property & mother', [4, 2, 11], ['moon', 'venus', 'mars'], 'D4',
        ['acquisition', 'construction', 'relocation', 'sale', 'inheritance']),
    LifeDomain('children', 'Children & creativity', [5], ['jupiter'], 'D7', ['children', 'creativity', 'intelligence']),
    LifeDomain('health', 'Health, service & competition', [6, 1, 8], ['sun', 'moon'], 'D30', ['routines', 'competition', 'debts', 'vitality'],
        caution: 'Traditional indications only; not a medical assessment.'),
    LifeDomain('marriage', 'Marriage & partnership', [7, 2], ['venus', 'jupiter'], 'D9',
        ['relationship activation', 'partnership formation', 'formalisation', 'strain', 'separation indicators']),
    LifeDomain('transformation', 'Transformation, inheritance & research', [8], ['saturn'], 'D30', ['research', 'joint resources', 'major change']),
    LifeDomain('fortune', 'Fortune, father & higher learning', [9], ['jupiter', 'sun'], 'D9', ['fortune', 'father/guru', 'pilgrimage']),
    LifeDomain('career', 'Career & status', [10, 6, 11], ['sun', 'saturn', 'mercury', 'jupiter'], 'D10',
        ['employment', 'promotion/authority', 'role change', 'business', 'professional conflict', 'gains from work']),
    LifeDomain('gains', 'Gains & networks', [11], ['jupiter'], 'D1', ['income channels', 'networks', 'ambitions']),
    LifeDomain('foreign', 'Expenditure, foreign lands & retreat', [12, 9, 7, 4], ['saturn', 'rahu', 'moon'], 'D12',
        ['travel', 'temporary stay', 'relocation', 'foreign work', 'long-term residence']),
    LifeDomain('education', 'Education & intelligence', [4, 5, 9], ['mercury', 'jupiter'], 'D24',
        ['foundational education', 'higher education', 'specialised study', 'teaching/research']),
    LifeDomain('spiritual', 'Spiritual practice & research', [5, 9, 12, 8], ['jupiter', 'ketu'], 'D20',
        ['spiritual practice', 'academic research', 'esoteric interests', 'life transformation']),
  ];

  static const Map<String, int> _divisions = {
    'D1': 1, 'D2': 2, 'D3': 3, 'D4': 4, 'D7': 7, 'D9': 9, 'D10': 10, 'D12': 12, 'D16': 16, 'D20': 20, 'D24': 24, 'D30': 30,
  };

  static String _n(String p) => VedicMath.planets[p]?.name ?? p;
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
      if (owned.contains(h)) out.add('owns the ${VedicMath.ordinal(h)}');
      if (hl == h) out.add('occupies the ${VedicMath.ordinal(h)}');
      if (aspectingHouse(c, h, cfg).contains(lord)) out.add('aspects the ${VedicMath.ordinal(h)}');
      final hLord = lordOf(c, h);
      if (hLord != lord && VedicMath.rashiIndex(c.planetLongitudes[hLord]!) == VedicMath.rashiIndex(c.planetLongitudes[lord]!)) {
        out.add('is joined with the ${VedicMath.ordinal(h)} lord');
      }
      if (hLord != lord && VedicMath.rashis[VedicMath.rashiIndex(c.planetLongitudes[hLord]!)].lord == lord) {
        out.add('disposits the ${VedicMath.ordinal(h)} lord');
      }
    }
    if (domain.karakas.contains(lord)) out.add('is a karaka of the domain');
    return out.toSet().toList();
  }

  /// Ashtakavarga, Shadbala and other heavy layers are computed once per chart.
  static SynthesisReport analyse(ChartData c, {CalcConfig cfg = CalcConfig.defaults, double? atJd, bool includeTransits = true}) {
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
    ChartData? transit;
    if (includeTransits) {
      try {
        transit = Ephemeris.computeChartForJd(now, c.lat, c.lon, utcOffset: c.utcOffset);
      } catch (_) {
        transit = null;
      }
    }
    final meanBhava = sb.bhavas.fold<double>(0, (s, b) => s + b.total) / 12;

    final out = <DomainSynthesis>[];
    for (final d in domains) {
      final ev = <Evidence>[];
      final chains = <String>[];
      void add(EvidenceLayer l, Polarity p, String t, SourceTier tier, String rule) => ev.add(Evidence(l, p, t, tier, rule));

      // ---------------- A: natal promise ----------------
      for (final h in d.bhavas) {
        final primary = h == d.bhavas.first;
        final lord = lordOf(c, h);
        final hl = houseOfPlanet(c, lord);
        final r = recs[lord]!;
        final dispositor = r.dispositor;
        final dispRec = recs[dispositor]!;
        chains.add('${VedicMath.ordinal(h)} Bhāva → ${_n(lord)} → ${VedicMath.rashis[r.rashi].name} (house $hl) → '
            '${_n(dispositor)} → house ${dispRec.house} (${dispRec.dignity}${sb.planets[dispositor] != null ? ', Shadbala ${sb.planets[dispositor]!.ratio.toStringAsFixed(2)}×' : ''})');
        if (!primary && hl != h && !YogasMath.isDusthana(hl) && !YogasMath.isKendra(hl) && !YogasMath.isTrikona(hl)) continue;
        if (YogasMath.isDusthana(h) && YogasMath.isDusthana(hl)) {
          add(EvidenceLayer.natal, Polarity.support, '${VedicMath.ordinal(h)} lord ${_n(lord)} in the ${VedicMath.ordinal(hl)}: a dusthana lord in a dusthana (Viparīta reversal).',
              SourceTier.classicalDerived, 'Phaladeepika ch. 6 (Viparita)');
        } else if (hl == h || YogasMath.isKendra(hl) || YogasMath.isTrikona(hl) || hl == 11) {
          add(EvidenceLayer.natal, Polarity.support, '${VedicMath.ordinal(h)} lord ${_n(lord)} is in the ${VedicMath.ordinal(hl)} (${hl == h ? 'its own house' : 'a good house'}).',
              SourceTier.classicalDerived, 'BPHS bhava-lord placement');
        } else if (YogasMath.isDusthana(hl)) {
          add(EvidenceLayer.natal, Polarity.obstruction, '${VedicMath.ordinal(h)} lord ${_n(lord)} is in the ${VedicMath.ordinal(hl)}, a dusthana.',
              SourceTier.classicalDerived, 'BPHS bhava-lord placement');
        }
        if (!primary) continue;
        final occupants = Ephemeris.planetOrder.where((p) => c.planetLongitudes.containsKey(p) && houseOfPlanet(c, p) == h).toList();
        for (final p in occupants) {
          final ben = _naturalBenefic(c, p);
          if (ben) {
            add(EvidenceLayer.natal, Polarity.support, '${_n(p)} (benefic) occupies the ${VedicMath.ordinal(h)}.', SourceTier.classicalDerived, 'Phaladeepika bhava analysis');
          } else if (YogasMath.isUpachaya(h)) {
            add(EvidenceLayer.natal, Polarity.support, '${_n(p)} (malefic) in the ${VedicMath.ordinal(h)}, an Upachaya, where malefics do well.', SourceTier.classicalDerived, 'Phaladeepika bhava analysis');
          } else {
            add(EvidenceLayer.natal, Polarity.obstruction, '${_n(p)} (malefic) occupies the ${VedicMath.ordinal(h)}.', SourceTier.classicalDerived, 'Phaladeepika bhava analysis');
          }
        }
        for (final p in aspectingHouse(c, h, cfg)) {
          if (occupants.contains(p)) continue;
          final ben = _naturalBenefic(c, p);
          if (ben || YogasMath.isUpachaya(h)) {
            add(EvidenceLayer.natal, ben ? Polarity.support : Polarity.neutral, '${_n(p)} aspects the ${VedicMath.ordinal(h)}.', SourceTier.classicalDerived, 'Parashari graha drishti');
          } else {
            add(EvidenceLayer.natal, Polarity.obstruction, '${_n(p)} (malefic) aspects the ${VedicMath.ordinal(h)}.', SourceTier.classicalDerived, 'Parashari graha drishti');
          }
        }
        for (final cj in conjunctions.where((x) => x.record.bhava == h)) {
          add(EvidenceLayer.natal, Polarity.neutral,
              'Conjunction ${cj.record.clusterId} (${cj.record.clusterLabel}) in the ${VedicMath.ordinal(h)}; closest pair ${cj.closestPair == null ? '-' : '${_n(cj.closestPair!.a)}–${_n(cj.closestPair!.b)} ${cj.closestPair!.separation.toStringAsFixed(1)}°'}.',
              SourceTier.systematicSynthesis, 'Conjunction DB ${cj.record.recordId}');
        }
      }
      for (final k in d.karakas) {
        final r = recs[k];
        if (r == null) continue;
        if (r.dignity == 'Exalted' || r.dignity == 'Own Sign' || r.dignity == 'Moolatrikona') {
          add(EvidenceLayer.natal, Polarity.support, 'Karaka ${_n(k)} is ${r.dignity.toLowerCase()}.', SourceTier.classicalDerived, 'Karaka layer (Vol. 5 §31)');
        } else if (r.dignity == 'Debilitated' || r.combust) {
          add(EvidenceLayer.natal, Polarity.obstruction, 'Karaka ${_n(k)} is ${r.combust ? 'combust' : 'debilitated'}.', SourceTier.classicalDerived, 'Karaka layer (Vol. 5 §31)');
        }
      }
      final lords = {for (final h in d.bhavas) lordOf(c, h)};
      for (final y in yogas) {
        if (!y.planets.any(lords.contains)) continue;
        if (y.category.startsWith('Nabhasa') || y.category == YogaFamilies.arishta || y.category == YogaFamilies.pravrajya) continue;
        add(EvidenceLayer.natal, y.nature == YogaNature.adverse ? Polarity.obstruction : Polarity.support,
            '${y.name} involves ${y.planets.where(lords.contains).map(_n).join(', ')} (${y.strength}).',
            SourceTier.classicalDirect, y.source);
      }

      // ---------------- B: strength ----------------
      final primaryLord = lordOf(c, d.bhavas.first);
      final ps = sb.planets[primaryLord];
      if (ps != null) {
        add(EvidenceLayer.strength, ps.meetsMinimum ? Polarity.support : Polarity.obstruction,
            '${d.bhavas.first == 1 ? 'Lagna' : VedicMath.ordinal(d.bhavas.first)} lord ${_n(primaryLord)}: Shadbala ${ps.rupas.toStringAsFixed(2)} rupas (${ps.ratio.toStringAsFixed(2)}× the minimum).',
            SourceTier.classicalDerived, 'BPHS Shadbala');
      }
      final bb = sb.bhavas[d.bhavas.first - 1];
      add(EvidenceLayer.strength, bb.total >= meanBhava ? Polarity.support : Polarity.obstruction,
          'Bhāva Bala of the ${VedicMath.ordinal(d.bhavas.first)}: ${bb.rupas.toStringAsFixed(2)} rupas (chart average ${(meanBhava / 60).toStringAsFixed(2)}).',
          SourceTier.classicalDerived, 'Bhava Bala (Raman method)');
      final pr = recs[primaryLord]!;
      if (pr.combust) add(EvidenceLayer.strength, Polarity.obstruction, '${_n(primaryLord)} is combust (${pr.sunDistance!.toStringAsFixed(1)}° from the Sun).', SourceTier.configurableTradition, 'Combustion orb table');
      if (pr.vargottama) add(EvidenceLayer.strength, Polarity.support, '${_n(primaryLord)} is vargottama.', SourceTier.classicalDerived, 'Phaladeepika (Vargottama)');
      if (pr.sandhi) add(EvidenceLayer.strength, Polarity.obstruction, '${_n(primaryLord)} is near a Bhāva-sandhi, which reduces effectiveness.', SourceTier.configurableTradition, 'Phaladeepika (Bhava-sandhi)');
      if (pr.retrograde && !pr.isNode) add(EvidenceLayer.strength, Polarity.neutral, '${_n(primaryLord)} is retrograde (Cheṣṭā strength; delayed or repeated expression).', SourceTier.classicalDerived, 'Phaladeepika ch. 4');
      for (final w in wars.where((w) => w.a == primaryLord || w.b == primaryLord)) {
        add(EvidenceLayer.strength, w.winner == primaryLord ? Polarity.support : Polarity.obstruction,
            '${_n(primaryLord)} is in planetary war with ${_n(w.a == primaryLord ? w.b : w.a)} and ${w.winner == primaryLord ? 'wins' : (w.winner == null ? 'the result is undetermined' : 'loses')}.',
            SourceTier.configurableTradition, w.rule);
      }
      if (pr.dignity == 'Debilitated') add(EvidenceLayer.strength, Polarity.obstruction, '${_n(primaryLord)} is debilitated.', SourceTier.classicalDerived, 'Dignity');
      if (pr.dignity == 'Exalted' || pr.dignity == 'Moolatrikona' || pr.dignity == 'Own Sign') {
        add(EvidenceLayer.strength, Polarity.support, '${_n(primaryLord)} is ${pr.dignity.toLowerCase()}.', SourceTier.classicalDerived, 'Dignity');
      }

      // ---------------- E: varga ----------------
      final div = _divisions[d.varga] ?? 1;
      if (d.varga != 'D1') {
        final vLagna = VedicMath.vargaRashi(c.ascendantSidereal, d.varga, div);
        final vSign = VedicMath.vargaRashi(c.planetLongitudes[primaryLord]!, d.varga, div);
        final vHouse = VedicMath.houseOf(vSign, vLagna);
        final p = VedicMath.planets[primaryLord]!;
        final dign = p.exalt == vSign ? 'exalted' : (p.debi == vSign ? 'debilitated' : (p.ownSigns.contains(vSign) ? 'in its own sign' : null));
        final good = YogasMath.isKendra(vHouse) || YogasMath.isTrikona(vHouse) || dign == 'exalted' || dign == 'in its own sign';
        final bad = YogasMath.isDusthana(vHouse) || dign == 'debilitated';
        add(EvidenceLayer.varga, good && !bad ? Polarity.support : (bad && !good ? Polarity.obstruction : Polarity.neutral),
            '${d.varga}: ${_n(primaryLord)} in ${VedicMath.rashis[vSign].name}, house $vHouse from the ${d.varga} Lagna${dign != null ? ', $dign' : ''}.',
            SourceTier.classicalDerived, 'BPHS Shodashavarga');
      }

      // ---------------- C: dasha ----------------
      const levels = ['Mahādaśā', 'Antardaśā', 'Pratyantardaśā'];
      final activeLevels = <int>[];
      for (int i = 0; i < running.length && i < 3; i++) {
        final lord = running[i].lord;
        final reasons = activationReasons(c, lord, d, cfg);
        if (reasons.isNotEmpty) {
          activeLevels.add(i);
          add(EvidenceLayer.dasha, i < 2 ? Polarity.support : Polarity.neutral,
              '${levels[i]} lord ${_n(lord)} ${reasons.join(', ')} (${running[i].startDate} – ${running[i].endDate}).',
              SourceTier.classicalDerived, 'Phaladeepika Dasha chapters; BPHS');
        }
      }
      if (running.length >= 2) {
        final m = running[0].lord, a = running[1].lord;
        if (m != a && c.planetLongitudes.containsKey(m) && c.planetLongitudes.containsKey(a)) {
          final dist = VedicMath.houseOf(VedicMath.rashiIndex(c.planetLongitudes[a]!), VedicMath.rashiIndex(c.planetLongitudes[m]!));
          if (const [6, 8, 12].contains(dist)) {
            add(EvidenceLayer.dasha, Polarity.obstruction, 'Antardaśā lord ${_n(a)} is ${VedicMath.ordinal(dist)} from the Mahādaśā lord ${_n(m)} (6/8/12 relationship).',
                SourceTier.classicalDerived, 'BPHS Antardasha relationship');
          } else if (YogasMath.isKendra(dist) || YogasMath.isTrikona(dist)) {
            add(EvidenceLayer.dasha, Polarity.neutral, 'Antardaśā lord ${_n(a)} is ${VedicMath.ordinal(dist)} from the Mahādaśā lord ${_n(m)} (supportive relationship).',
                SourceTier.classicalDerived, 'BPHS Antardasha relationship');
          }
        }
      }
      if (activeLevels.isEmpty && running.isNotEmpty) {
        add(EvidenceLayer.dasha, Polarity.neutral, 'The current Daśā lords (${running.take(2).map((x) => _n(x.lord)).join(' / ')}) are not directly connected with this domain.',
            SourceTier.classicalDerived, 'Daśā activation rule (Vol. 5 §10)');
      }

      // ---------------- D: transit ----------------
      final contacts = <TransitContact>[];
      if (transit != null) {
        for (final tp in ['jupiter', 'saturn', 'rahu']) {
          final tr = VedicMath.rashiIndex(transit.planetLongitudes[tp]!);
          for (final h in d.bhavas.take(2)) {
            final target = (c.lagnaRashi + h - 1) % 12;
            final dist = VedicMath.houseOf(target, tr);
            final aspects = PrecisionMath.aspectHouses(tp, cfg).contains(dist);
            if (tr == target || aspects) {
              final support = AshtakavargaMath.transitSupport(av, tp, tr);
              final bindus = av.bindusFor(tp, tr);
              add(EvidenceLayer.transit, tp == 'jupiter' || (tp == 'saturn' && YogasMath.isUpachaya(h)) ? Polarity.support : Polarity.neutral,
                  'Transit ${_n(tp)} in ${VedicMath.rashis[tr].name} ${tr == target ? 'passes through' : 'aspects'} the ${VedicMath.ordinal(h)}'
                  '${tp == 'rahu' ? '' : '; $support'}.',
                  SourceTier.classicalDerived, 'Phaladeepika transit chapter; BPHS Ashtakavarga');
              if (tp != 'rahu' && bindus < 4 && tp == 'jupiter') {
                add(EvidenceLayer.ashtakavarga, Polarity.obstruction, 'Transit Jupiter has only $bindus bindus in ${VedicMath.rashis[tr].name}.', SourceTier.classicalDerived, 'BPHS Ashtakavarga');
              }
            }
          }
          final natalLord = lordOf(c, d.bhavas.first);
          final lordSign = VedicMath.rashiIndex(c.planetLongitudes[natalLord]!);
          if (tp != 'rahu' && (tr == lordSign || PrecisionMath.aspectHouses(tp, cfg).contains(VedicMath.houseOf(lordSign, tr)))) {
            add(EvidenceLayer.transit, tp == 'jupiter' ? Polarity.support : Polarity.neutral,
                'Transit ${_n(tp)} ${tr == lordSign ? 'joins' : 'aspects'} the natal ${VedicMath.ordinal(d.bhavas.first)} lord ${_n(natalLord)}.',
                SourceTier.classicalDerived, 'Phaladeepika transit chapter');
          }
        }
        for (final x in running.take(2)) {
          final lord = x.lord;
          if (!transit.planetLongitudes.containsKey(lord) || lord == 'rahu' || lord == 'ketu') continue;
          if (activationReasons(c, lord, d, cfg).isEmpty) continue;
          final tr = VedicMath.rashiIndex(transit.planetLongitudes[lord]!);
          final p = VedicMath.planets[lord]!;
          if (p.exalt == tr || p.ownSigns.contains(tr)) {
            add(EvidenceLayer.transit, Polarity.support, 'Daśā lord ${_n(lord)} transits its ${p.exalt == tr ? 'exaltation' : 'own'} sign ${VedicMath.rashis[tr].name}, strengthening the houses it represents.',
                SourceTier.classicalDirect, 'Phaladeepika (transit of the Daśā planet)');
          }
        }
        contacts.addAll(_ingresses(c, d, now));
      }

      // ---------------- F: ashtakavarga ----------------
      final sav = av.sarvaInHouse(d.bhavas.first);
      add(EvidenceLayer.ashtakavarga, sav >= 28 ? Polarity.support : (sav < 25 ? Polarity.obstruction : Polarity.neutral),
          'Sarvāṣṭakavarga of the ${VedicMath.ordinal(d.bhavas.first)}: $sav bindus (28 is average).', SourceTier.classicalDerived, 'BPHS Ashtakavarga');

      // ---------------- status ----------------
      final ordered = [for (final l in EvidenceLayer.values) ...ev.where((e) => e.layer == l)];
      ev
        ..clear()
        ..addAll(ordered);
      int i = 1;
      for (final e in ev) {
        e.id = 'R${i++}';
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
      final layersOn = [statuses.contains(PredictionStatus.natalPromisePresent), dashaOn, transitOn, vargaOn || d.varga == 'D1'];
      final agreeing = layersOn.where((x) => x).length;
      if (agreeing >= 2 && agreeing < 4) statuses.add(PredictionStatus.partialConvergence);
      final supportLayers = EvidenceLayer.values.where((l) => ev.any((e) => e.layer == l && e.polarity == Polarity.support && e.tier != SourceTier.systematicSynthesis)).length;
      final tier = supportLayers >= 3 ? SourceTier.multiSourceConvergence : SourceTier.systematicSynthesis;

      final interpretation = _language(d, agreeing, natalPlus, natalMinus, dashaOn, transitOn, statuses);
      out.add(DomainSynthesis(d, ev, chains, statuses, tier, interpretation, windows(c, d, dashas, cfg, now), contacts));
    }

    return SynthesisReport(c, out, flags, audit(c, cfg, now), running.map((r) => r.lord).toList());
  }

  /// Evidence-calibrated wording (Volume 5 §35); never deterministic.
  static String _language(LifeDomain d, int agreeing, int plus, int minus, bool dasha, bool transit, Set<PredictionStatus> st) {
    final theme = d.name.toLowerCase();
    String s;
    if (st.contains(PredictionStatus.insufficientData)) {
      s = 'The available data do not establish this reliably.';
    } else if (st.contains(PredictionStatus.natalContradiction)) {
      s = 'The chart contains both supporting and obstructing indicators for $theme; the result is conditional on the modifying factors listed.';
    } else if (agreeing >= 4) {
      s = 'The chart contains multiple converging indications for $theme: the natal promise is supported, the active period directly connects with it, and the timing is reinforced by transits.';
    } else if (agreeing >= 2) {
      s = 'The chart indicates $theme, but ${!dasha ? 'the current Daśā does not strongly activate it' : (!transit ? 'transit support is partial' : 'Varga confirmation is limited')}. '
          '${minus > 0 ? 'Several factors support it while $minus modify the result.' : ''}';
    } else {
      s = 'The theme of $theme is present in the chart with limited support and is not strongly activated at present.';
    }
    if (d.caution != null) s = '$s ${d.caution}';
    return s.trim();
  }

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
            if (mdReasons.isNotEmpty) 'MD ${_n(md.lord)} ${mdReasons.join(', ')}',
            'AD ${_n(ad.lord)} ${adReasons.join(', ')}',
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
              '${_n(p)} enters ${VedicMath.rashis[r].name} (the ${VedicMath.ordinal(d.bhavas.first)})${entries > 1 ? ' again after retrogression' : ''}'));
        }
        prev = r;
      }
      if (prev == null) continue;
      final (lon0, _) = Ephemeris.siderealPosition(p, now);
      if (VedicMath.rashiIndex(lon0) == target && out.where((t) => t.planet == p).isEmpty) {
        out.add(TransitContact(p, target, now, VedicMath.jdToDate(now + c.utcOffset / 24), false, '${_n(p)} is already in ${VedicMath.rashis[target].name}'));
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
      out.add(InputFlag('critical', 'The Lagna is ${edge.toStringAsFixed(2)}° from a sign boundary: about one minute of birth time changes the Lagna and every house.'));
    } else if (edge < 1) {
      out.add(InputFlag('warning', 'The Lagna is ${edge.toStringAsFixed(2)}° from a sign boundary: a few minutes of birth time change the houses.'));
    }
    final moon = c.planetLongitudes['moon'];
    if (moon != null) {
      const span = 360 / 27;
      final into = VedicMath.norm360(moon) % span;
      if (into < 0.15 || span - into < 0.15) {
        out.add(const InputFlag('warning', 'The Moon is at a nakshatra boundary: the starting Daśā lord depends on the exact birth time.'));
      }
    }
    final sandhi = PrecisionMath.records(c, cfg).values.where((r) => r.sandhi).map((r) => r.name).toList();
    if (sandhi.isNotEmpty) out.add(InputFlag('info', 'Near a Bhāva-sandhi: ${sandhi.join(', ')}.'));
    out.add(const InputFlag('info', 'Birth time is recorded to the minute (no seconds); degree-sensitive results assume it is exact.'));
    return out;
  }

  /// Audit log (Volume 5 §44): everything needed to reproduce the result.
  static Map<String, String> audit(ChartData c, CalcConfig cfg, double now) => {
        'engine_version': CalcConfig.engineVersion,
        'source_versions': sourceVersions,
        'ephemeris': Ephemeris.ephemerisLabel,
        'ayanamsha': '${Ephemeris.ayanamsaLabel}; value ${c.ayanamsa.toStringAsFixed(6)}°',
        'node_model': Ephemeris.nodeModel,
        ...cfg.ruleVersions,
        'input_birth_data': 'JD(UT) ${c.jd.toStringAsFixed(6)}, lat ${c.lat.toStringAsFixed(4)}, lon ${c.lon.toStringAsFixed(4)}, UTC offset ${c.utcOffset}',
        'calculation_timestamp': Ephemeris.jdToUtc(now).toIso8601String(),
        'dasha_convention': 'Vimshottari, 365.25-day years, Moon nakshatra balance',
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
        if (md.isNotEmpty) trace.add('Natal (known before the event): MD ${_n(periods[0].lord)} ${md.join(', ')}');
        if (ad.isNotEmpty) trace.add('Natal (known before the event): AD ${_n(periods[1].lord)} ${ad.join(', ')}');
        if (md.isEmpty && ad.isEmpty) trace.add('Neither the MD nor the AD lord connects with ${d.name.toLowerCase()}.');
      }
    }
    try {
      final t = Ephemeris.computeChartForJd(jd, chart.lat, chart.lon, utcOffset: chart.utcOffset);
      final d = domain(e.domainId);
      final target = (chart.lagnaRashi + d.bhavas.first - 1) % 12;
      for (final p in ['jupiter', 'saturn']) {
        final tr = VedicMath.rashiIndex(t.planetLongitudes[p]!);
        final dist = VedicMath.houseOf(target, tr);
        if (tr == target || PrecisionMath.aspectHouses(p, cfg).contains(dist)) {
          trace.add('Transit at the event: ${_n(p)} in ${VedicMath.rashis[tr].name} ${tr == target ? 'in' : 'aspecting'} the ${VedicMath.ordinal(d.bhavas.first)}.');
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
        'Lagna ${VedicMath.rashis[c.lagnaRashi].name} ${VedicMath.formatDegree(c.ascendantSidereal)}',
        'D9 Lagna ${VedicMath.rashis[VedicMath.vargaRashi(c.ascendantSidereal, 'D9', 9)].name}, '
            'D10 Lagna ${VedicMath.rashis[VedicMath.vargaRashi(c.ascendantSidereal, 'D10', 10)].name}',
      ];
      final first = DashaCalculations.compute(c.jd, c.planetLongitudes['moon']!, utcOffset: c.utcOffset).mahadashas.first;
      details.add('Daśā balance: ${_n(first.lord)} ${((first.endJD - c.jd) / DashaCalculations.yearDays).toStringAsFixed(2)} years');
      for (final e in events) {
        final jd = Ephemeris.julianDay(e.date.year, e.date.month, e.date.day, 12 - c.utcOffset);
        final periods = periodsAt(c, jd);
        final d = domain(e.domainId);
        final md = periods.isNotEmpty ? activationReasons(c, periods[0].lord, d, cfg).length : 0;
        final ad = periods.length > 1 ? activationReasons(c, periods[1].lord, d, cfg).length : 0;
        final pd = periods.length > 2 ? activationReasons(c, periods[2].lord, d, cfg).length : 0;
        final s = (md > 0 ? 1 : 0) + (ad > 0 ? 1.5 : 0) + (pd > 0 ? 0.5 : 0);
        score += s;
        details.add('${e.date.year}-${e.date.month.toString().padLeft(2, '0')} ${d.name}: '
            '${periods.take(3).map((p) => _n(p.lord)).join('/')} → ${s == 0 ? 'no activation' : '+${s.toStringAsFixed(1)}'}');
      }
      out.add(RectificationCandidate(m, c, score, details));
    }
    return out;
  }
}
