import 'dart:math' as math;

import 'calc_config.dart';
import 'ephemeris.dart';
import 'planetary_dignity.dart';
import 'vedic_math.dart';

/// Evidence classes (Volume 4 §26, Volume 5 §3, Volume 6 §17).
enum SourceTier {
  classicalDirect('DIRECT_CLASSICAL', 'Exact classical rule'),
  classicalDerived('CLASSICAL_DERIVED', 'Direct calculation from a classical method'),
  multiSourceConvergence('MULTI_SOURCE_CONVERGENCE', 'Several classical rules agree'),
  configurableTradition('CONFIGURABLE_TRADITION', 'Depends on a configurable convention'),
  systematicSynthesis('SYSTEMATIC_SYNTHESIS', 'Database synthesis, not a quoted classical rule'),
  engineeringHeuristic('ENGINEERING_HEURISTIC', 'Software heuristic for ranking or display; not a classical rule'),
  insufficientInput('INSUFFICIENT_INPUT', 'Required data missing');

  final String code;
  final String label;
  const SourceTier(this.code, this.label);
}

enum Motion { direct, retrograde, stationary }

/// One graha (or node) with its exact astronomical and Jyotisha data (Volume 4 §3).
class GrahaRecord {
  final String planet;
  final double longitude;
  final int rashi;
  final double degreeInRashi;
  final double latitude;
  final double? declination;
  final double speed;
  final Motion motion;
  final bool stationary;
  final int house;
  final String nakshatra;
  final int pada;
  final String nakshatraLord;
  final double remainingNakshatraArc;
  final String dignity;
  final double? distanceFromExaltation;
  final int navamsa;
  final bool vargottama;
  final String dispositor;
  final double? sunDistance;
  final double? combustionOrb;
  final bool combust;
  final bool deeplyCombust;
  final bool sandhi;

  const GrahaRecord({
    required this.planet,
    required this.longitude,
    required this.rashi,
    required this.degreeInRashi,
    required this.latitude,
    required this.declination,
    required this.speed,
    required this.motion,
    required this.stationary,
    required this.house,
    required this.nakshatra,
    required this.pada,
    required this.nakshatraLord,
    required this.remainingNakshatraArc,
    required this.dignity,
    required this.distanceFromExaltation,
    required this.navamsa,
    required this.vargottama,
    required this.dispositor,
    required this.sunDistance,
    required this.combustionOrb,
    required this.combust,
    required this.deeplyCombust,
    required this.sandhi,
  });

  bool get isNode => planet == 'rahu' || planet == 'ketu';
  bool get retrograde => motion == Motion.retrograde;
  String get name => VedicMath.planets[planet]!.name;

  Map<String, Object?> toJson() => {
        'graha': name,
        'longitude_sidereal': double.parse(longitude.toStringAsFixed(6)),
        'rashi': VedicMath.rashis[rashi].name,
        'degree_in_rashi': double.parse(degreeInRashi.toStringAsFixed(6)),
        'latitude': double.parse(latitude.toStringAsFixed(4)),
        'speed': double.parse(speed.toStringAsFixed(4)),
        'motion': motion.name,
        'retrograde': retrograde,
        'stationary': stationary,
        'house': house,
        'nakshatra': nakshatra,
        'pada': pada,
        'nakshatra_lord': nakshatraLord,
        'remaining_nakshatra_arc': double.parse(remainingNakshatraArc.toStringAsFixed(4)),
        'dignity': dignity,
        'navamsa': VedicMath.rashis[navamsa].name,
        'vargottama': vargottama,
        'dispositor': dispositor,
        'sun_distance': sunDistance == null ? null : double.parse(sunDistance!.toStringAsFixed(4)),
        'combustion_status': combust,
        'deep_combustion_status': deeplyCombust,
        'configured_orb': combustionOrb,
      };
}

/// Planetary war between two of Mars, Mercury, Jupiter, Venus and Saturn.
class GrahaYuddha {
  final String a;
  final String b;
  final double separation;
  final String? winner;
  final String rule;
  const GrahaYuddha(this.a, this.b, this.separation, this.winner, this.rule);
  String? get loser => winner == null ? null : (winner == a ? b : a);
}

/// Exact geometry between two bodies (Volume 4 §4, §22).
class PairEdge {
  final String a;
  final String b;
  final double separation;
  final bool sameRashi;
  final bool crossesSignBoundary;
  final bool applying;
  final String closeness; // exact, close, wide
  final bool combustionLink;
  final GrahaYuddha? war;

  const PairEdge({
    required this.a,
    required this.b,
    required this.separation,
    required this.sameRashi,
    required this.crossesSignBoundary,
    required this.applying,
    required this.closeness,
    required this.combustionLink,
    required this.war,
  });

  bool get separating => !applying;
  bool get involvesNode => a == 'rahu' || a == 'ketu' || b == 'rahu' || b == 'ketu';
  String get nodePairType => !involvesNode ? 'graha-graha' : ((a == 'rahu' || b == 'rahu') ? 'Rahu-graha' : 'Ketu-graha');
}

/// A Parashari aspect with degree metadata (Volume 4 §11).
class AspectLink {
  final String from;
  final String to;
  final int houseDistance; // 1-12, house of target counted from source
  final double angle; // target - source, 0-360
  final double exactPoint; // e.g. 180 for the 7th aspect
  final double orb; // |angle - exactPoint| folded
  final double sputaValue; // BPHS sputa drishti, virupas 0-60
  final bool fullAspect; // Parashari sign-based full aspect
  final bool applying;
  const AspectLink(this.from, this.to, this.houseDistance, this.angle, this.exactPoint, this.orb, this.sputaValue, this.fullAspect, this.applying);
}

class QcCheck {
  final String id;
  final String description;
  final bool passed;
  final String detail;
  const QcCheck(this.id, this.description, this.passed, this.detail);
}

/// Descriptive metrics of a cluster (Volume 4 §24) - not predictive scores.
class ClusterMetrics {
  final double minSeparation;
  final double maxSeparation;
  final double meanSeparation;
  final double medianSeparation;
  final int closePairs;
  final int combustionLinks;
  final int warLinks;
  final int retrogradeParticipants;
  final int vargottamaParticipants;
  const ClusterMetrics(this.minSeparation, this.maxSeparation, this.meanSeparation, this.medianSeparation, this.closePairs,
      this.combustionLinks, this.warLinks, this.retrogradeParticipants, this.vargottamaParticipants);
}

/// Volume 4 precision layer: exact degrees, motion, combustion, planetary war,
/// degree dignity, Vargottama, degree-sensitive aspects and quality control.
class PrecisionMath {
  static const List<String> warCandidates = ['mars', 'mercury', 'jupiter', 'venus', 'saturn'];
  static const Map<String, double> meanDailyMotion = {
    'sun': 0.9856, 'moon': 13.1764, 'mars': 0.5240, 'mercury': 1.3833, 'jupiter': 0.0831, 'venus': 1.2000, 'saturn': 0.0335,
    'rahu': 0.0529, 'ketu': 0.0529,
  };

  static double norm180(double d) {
    var x = VedicMath.norm360(d);
    if (x > 180) x -= 360;
    return x;
  }

  static double separation(double a, double b) => norm180(a - b).abs();

  static Map<String, int> _rashis(ChartData c) => {for (final e in c.planetLongitudes.entries) e.key: VedicMath.rashiIndex(e.value)};

  /// Whether [longitude] lies within [orb] of a Bhava-sandhi (equal houses from the ascendant).
  static bool inSandhi(double longitude, double ascendant, double orb) {
    final fromAsc = VedicMath.norm360(longitude - ascendant);
    final toSandhi = (fromAsc - 15) % 30; // sandhi at 15°, 45°, ... from the ascendant
    final d = math.min(toSandhi, 30 - toSandhi);
    return d < orb;
  }

  static GrahaRecord record(ChartData c, String p, [CalcConfig cfg = CalcConfig.defaults]) {
    final lon = c.planetLongitudes[p]!;
    final r = VedicMath.rashiIndex(lon);
    final deg = VedicMath.degInRashi(lon);
    final speed = c.planetSpeeds[p] ?? 0;
    final isNode = p == 'rahu' || p == 'ketu';
    final mean = meanDailyMotion[p] ?? 1;
    final stationary = !isNode && speed.abs() < cfg.stationaryFraction * mean;
    final motion = speed < 0 ? Motion.retrograde : (stationary ? Motion.stationary : Motion.direct);
    final nakIdx = VedicMath.nakshatraIndex(lon);
    const nakSpan = 360 / 27;
    final remaining = nakSpan - (VedicMath.norm360(lon) % nakSpan);
    final rashis = _rashis(c);
    final dignity = isNode ? 'Node (judged by dispositor)' : PlanetaryDignity.getAdvancedDignity(p, r, rashis, degree: deg);
    final ex = PlanetaryDignity.deepExaltation[p];
    final nav = VedicMath.vargaRashi(lon, 'D9', 9);
    double? sunDist;
    double? orb;
    bool combust = false;
    bool deep = false;
    if (p != 'sun' && !isNode && c.planetLongitudes.containsKey('sun')) {
      sunDist = separation(lon, c.planetLongitudes['sun']!);
      orb = speed < 0 ? (CalcConfig.retrogradeCombustionOrbs[p] ?? CalcConfig.combustionOrbs[p]) : CalcConfig.combustionOrbs[p];
      if (orb != null) {
        combust = sunDist < orb;
        deep = sunDist < orb * cfg.deepCombustionFraction;
      }
    }
    return GrahaRecord(
      planet: p,
      longitude: lon,
      rashi: r,
      degreeInRashi: deg,
      latitude: c.planetLatitudes[p] ?? 0,
      declination: c.declinations[p],
      speed: speed,
      motion: isNode ? Motion.retrograde : motion,
      stationary: stationary,
      house: VedicMath.houseOf(r, c.lagnaRashi),
      nakshatra: VedicMath.nakshatras[nakIdx].name,
      pada: VedicMath.pada(lon),
      nakshatraLord: VedicMath.nakshatraLord[nakIdx],
      remainingNakshatraArc: remaining,
      dignity: dignity,
      distanceFromExaltation: ex == null ? null : separation(lon, ex),
      navamsa: nav,
      vargottama: nav == r,
      dispositor: VedicMath.rashis[r].lord,
      sunDistance: sunDist,
      combustionOrb: orb,
      combust: combust,
      deeplyCombust: deep,
      sandhi: inSandhi(lon, c.ascendantSidereal, cfg.sandhiOrb),
    );
  }

  static Map<String, GrahaRecord> records(ChartData c, [CalcConfig cfg = CalcConfig.defaults]) => {
        for (final p in Ephemeris.planetOrder)
          if (c.planetLongitudes.containsKey(p)) p: record(c, p, cfg),
      };

  /// Planetary war between two candidates within the configured orb.
  static GrahaYuddha? war(ChartData c, String a, String b, [CalcConfig cfg = CalcConfig.defaults]) {
    if (!warCandidates.contains(a) || !warCandidates.contains(b)) return null;
    final la = c.planetLongitudes[a], lb = c.planetLongitudes[b];
    if (la == null || lb == null) return null;
    final sep = separation(la, lb);
    if (sep >= cfg.warOrb) return null;
    String? winner;
    if (cfg.warRule == WarRule.venusAlwaysWins && (a == 'venus' || b == 'venus')) {
      winner = 'venus';
    } else if (c.planetLatitudes.containsKey(a) && c.planetLatitudes.containsKey(b)) {
      winner = c.planetLatitudes[a]! >= c.planetLatitudes[b]! ? a : b;
    }
    return GrahaYuddha(a, b, sep, winner, cfg.warRuleLabel);
  }

  static PairEdge edge(ChartData c, String a, String b, [CalcConfig cfg = CalcConfig.defaults]) {
    final la = c.planetLongitudes[a]!, lb = c.planetLongitudes[b]!;
    final delta = norm180(la - lb);
    final sep = delta.abs();
    final rate = (c.planetSpeeds[a] ?? 0) - (c.planetSpeeds[b] ?? 0);
    final same = VedicMath.rashiIndex(la) == VedicMath.rashiIndex(lb);
    final closeness = sep < 1 ? 'exact' : (sep <= cfg.closeConjunctionOrb ? 'close' : 'wide');
    bool combustionLink = false;
    for (final (x, y) in [(a, b), (b, a)]) {
      if (x == 'sun' && CalcConfig.combustionOrbs.containsKey(y)) {
        final orb = (c.planetSpeeds[y] ?? 0) < 0
            ? (CalcConfig.retrogradeCombustionOrbs[y] ?? CalcConfig.combustionOrbs[y]!)
            : CalcConfig.combustionOrbs[y]!;
        if (sep < orb) combustionLink = true;
      }
    }
    return PairEdge(
      a: a,
      b: b,
      separation: sep,
      sameRashi: same,
      crossesSignBoundary: !same && sep <= cfg.closeConjunctionOrb,
      applying: delta * rate < 0,
      closeness: closeness,
      combustionLink: combustionLink,
      war: war(c, a, b, cfg),
    );
  }

  /// All pair edges among [planets] (C(n,2) of them).
  static List<PairEdge> edges(ChartData c, List<String> planets, [CalcConfig cfg = CalcConfig.defaults]) => [
        for (int i = 0; i < planets.length; i++)
          for (int j = i + 1; j < planets.length; j++) edge(c, planets[i], planets[j], cfg),
      ];

  /// Every planetary war in the chart.
  static List<GrahaYuddha> wars(ChartData c, [CalcConfig cfg = CalcConfig.defaults]) => [
        for (int i = 0; i < warCandidates.length; i++)
          for (int j = i + 1; j < warCandidates.length; j++)
            ?war(c, warCandidates[i], warCandidates[j], cfg),
      ];

  static ClusterMetrics metrics(ChartData c, List<String> planets, [CalcConfig cfg = CalcConfig.defaults]) {
    final es = edges(c, planets, cfg);
    final seps = es.map((e) => e.separation).toList()..sort();
    final recs = records(c, cfg);
    double median() {
      if (seps.isEmpty) return 0;
      final m = seps.length ~/ 2;
      return seps.length.isOdd ? seps[m] : (seps[m - 1] + seps[m]) / 2;
    }

    return ClusterMetrics(
      seps.isEmpty ? 0 : seps.first,
      seps.isEmpty ? 0 : seps.last,
      seps.isEmpty ? 0 : seps.reduce((a, b) => a + b) / seps.length,
      median(),
      es.where((e) => e.closeness != 'wide').length,
      es.where((e) => e.combustionLink).length,
      es.where((e) => e.war != null).length,
      planets.where((p) => recs[p]?.retrograde == true && !(recs[p]?.isNode ?? false)).length,
      planets.where((p) => recs[p]?.vargottama == true).length,
    );
  }

  // ---------------------------------------------------------------------------
  // Aspects
  // ---------------------------------------------------------------------------

  /// Houses (counted from the planet) receiving a full Parashari aspect.
  static List<int> aspectHouses(String p, [CalcConfig cfg = CalcConfig.defaults]) => switch (p) {
        'mars' => const [4, 7, 8],
        'jupiter' => const [5, 7, 9],
        'saturn' => const [3, 7, 10],
        'rahu' || 'ketu' => switch (cfg.nodeAspects) {
            NodeAspectRule.none => const <int>[],
            NodeAspectRule.seventh => const [7],
            NodeAspectRule.fiveSevenNine => const [5, 7, 9],
          },
        _ => const [7],
      };

  static double _exactPoint(int house) => (house - 1) * 30.0;

  /// BPHS sputa drishti (virupas, 0-60) for an aspect angle (target - source).
  static double sputaDrishti(String p, double angle) {
    final d = VedicMath.norm360(angle);
    double v;
    if (d < 30) {
      v = 0;
    } else if (d < 60) {
      v = (d - 30) / 2;
    } else if (d < 90) {
      v = d - 60 + 15;
    } else if (d < 120) {
      v = (120 - d) / 2 + 30;
    } else if (d < 150) {
      v = 150 - d;
    } else if (d < 180) {
      v = (d - 150) * 2;
    } else if (d < 300) {
      v = (300 - d) / 2;
    } else {
      v = 0;
    }
    // Special aspects (full value at the 4th/8th, 5th/9th, 3rd/10th).
    if (p == 'mars' && ((d >= 90 && d < 120) || (d >= 210 && d < 240))) v += 15;
    if (p == 'jupiter' && ((d >= 120 && d < 150) || (d >= 240 && d < 270))) v += 30;
    if (p == 'saturn' && ((d >= 60 && d < 90) || (d >= 270 && d < 300))) v += 45;
    return v.clamp(0, 60).toDouble();
  }

  /// Aspects from every planet to every other planet.
  static List<AspectLink> aspects(ChartData c, [CalcConfig cfg = CalcConfig.defaults]) {
    final out = <AspectLink>[];
    final ps = Ephemeris.planetOrder.where(c.planetLongitudes.containsKey).toList();
    for (final from in ps) {
      final houses = aspectHouses(from, cfg);
      for (final to in ps) {
        if (to == from) continue;
        final lf = c.planetLongitudes[from]!, lt = c.planetLongitudes[to]!;
        final hd = VedicMath.houseOf(VedicMath.rashiIndex(lt), VedicMath.rashiIndex(lf));
        if (!houses.contains(hd)) continue;
        final angle = VedicMath.norm360(lt - lf);
        final exact = _exactPoint(hd);
        final dev = norm180(angle - exact);
        final rate = (c.planetSpeeds[to] ?? 0) - (c.planetSpeeds[from] ?? 0);
        final isNode = from == 'rahu' || from == 'ketu';
        out.add(AspectLink(from, to, hd, angle, exact, dev.abs(), isNode ? 0 : sputaDrishti(from, angle), true, dev * rate < 0));
      }
    }
    return out;
  }

  // ---------------------------------------------------------------------------
  // Quality control (Volume 4 §28)
  // ---------------------------------------------------------------------------

  static List<QcCheck> qualityControl(ChartData c, [CalcConfig cfg = CalcConfig.defaults]) {
    final checks = <QcCheck>[];
    final longs = c.planetLongitudes;
    final normalised = longs.values.every((l) => l >= 0 && l < 360) && c.ascendantSidereal >= 0 && c.ascendantSidereal < 360;
    checks.add(QcCheck('QC1', 'All longitudes normalised to 0-360°', normalised, normalised ? 'OK' : 'A longitude is out of range'));

    if (longs.containsKey('rahu') && longs.containsKey('ketu')) {
      final dev = (separation(longs['rahu']!, longs['ketu']!) - 180).abs();
      checks.add(QcCheck('QC2', 'Rahu and Ketu exactly opposite', dev < 1e-6, 'Deviation ${dev.toStringAsExponential(1)}°'));
    }

    final lagnaOk = c.lagnaRashi == VedicMath.rashiIndex(c.ascendantSidereal);
    checks.add(QcCheck('QC3', 'Ascendant and whole-sign houses consistent', lagnaOk, 'Lagna ${VedicMath.rashis[c.lagnaRashi].name}'));

    bool d1 = true;
    for (final e in longs.entries) {
      final house = VedicMath.houseOf(VedicMath.rashiIndex(e.value), c.lagnaRashi);
      final abbr = Ephemeris.planetAbbreviations[e.key];
      if (abbr != null && !(c.housePlanets[house]?.contains(abbr) ?? false)) d1 = false;
    }
    checks.add(QcCheck('QC4', 'D1 signs match raw longitudes', d1, d1 ? 'All planets placed in the sign of their longitude' : 'Mismatch'));

    final recs = records(c, cfg);
    final vargOk = recs.values.every((r) => r.vargottama == (r.navamsa == r.rashi) && r.navamsa == VedicMath.vargaRashi(r.longitude, 'D9', 9));
    checks.add(QcCheck('QC5', 'D9 reproducible and Vargottama = (D1 sign = D9 sign)', vargOk, 'Navamsa rule: Parashari'));

    final combOk = recs.values.every((r) => r.sunDistance == null || r.combustionOrb == null || r.combust == (r.sunDistance! < r.combustionOrb!));
    checks.add(QcCheck('QC6', 'Combustion uses the stored Sun distance and orb table', combOk, 'Orb table: default (configurable)'));

    final warOk = wars(c, cfg).every((w) => warCandidates.contains(w.a) && warCandidates.contains(w.b));
    checks.add(QcCheck('QC7', 'Graha Yuddha only for Mars, Mercury, Jupiter, Venus, Saturn', warOk, '${wars(c, cfg).length} war(s)'));

    final retroOk = recs.values.where((r) => !r.isNode).every((r) => r.retrograde == (r.speed < 0));
    checks.add(QcCheck('QC8', 'Retrograde status from ephemeris speed', retroOk, 'Speeds from Swiss Ephemeris'));

    if (longs.containsKey('moon')) {
      final dashas = DashaCalculations.compute(c.jd, longs['moon']!, utcOffset: c.utcOffset);
      final first = dashas.mahadashas.first;
      final lord = VedicMath.nakshatraLord[VedicMath.nakshatraIndex(longs['moon']!)];
      const nakSpan = 360 / 27;
      final remainingFrac = 1 - (VedicMath.norm360(longs['moon']!) % nakSpan) / nakSpan;
      final expectedBalance = VedicMath.dashaYears[lord]! * remainingFrac;
      final balanceOk = first.lord == lord && ((first.endJD - c.jd) / DashaCalculations.yearDays - expectedBalance).abs() < 1e-3;
      checks.add(QcCheck('QC9', 'Dasha balance reproduces from the Moon\'s nakshatra', balanceOk,
          '${VedicMath.planets[lord]!.name} balance ${expectedBalance.toStringAsFixed(3)} years'));
      final total = VedicMath.dashaYears.values.reduce((a, b) => a + b);
      checks.add(QcCheck('QC10', 'Vimshottari Mahadasha years total 120', total == 120, '$total years'));
      bool adOk = true;
      for (final md in dashas.mahadashas.skip(1).take(8)) {
        final sum = md.subPeriods.fold<double>(0, (s, d) => s + (d.endJD - d.startJD));
        if ((sum - (md.endJD - md.startJD)).abs() > 1e-6) adOk = false;
      }
      checks.add(QcCheck('QC11', 'Antardasha durations sum to the Mahadasha', adOk, 'Checked 8 complete Mahadashas'));
    }
    return checks;
  }
}
