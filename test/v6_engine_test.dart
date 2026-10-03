import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_jyotish/core/calc_config.dart';
import 'package:mobile_jyotish/core/conjunction_db.dart';
import 'package:mobile_jyotish/core/ephemeris.dart';
import 'package:mobile_jyotish/core/jaimini_math.dart';
import 'package:mobile_jyotish/core/knowledge_registry.dart';
import 'package:mobile_jyotish/core/precision_math.dart';
import 'package:mobile_jyotish/core/synthesis_engine.dart';
import 'package:mobile_jyotish/core/timing_math.dart';
import 'package:mobile_jyotish/core/vedic_math.dart';

import 'helpers/sweph_test_helper.dart';

/// Synthetic chart from explicit longitudes (no ephemeris needed).
ChartData chartOf(double asc, Map<String, double> lons) {
  final lagna = (asc / 30).floor();
  final houses = {for (int i = 1; i <= 12; i++) i: <String>[]};
  lons.forEach((p, l) => houses[VedicMath.houseOf(VedicMath.rashiIndex(l), lagna)]!.add(Ephemeris.planetAbbreviations[p]!));
  return ChartData(houses, lons, asc, 2451545.0);
}

void main() {
  setUpAll(initEphemerisForTests);
  final skip = swephSkipReason();

  group('Knowledge registry (Volume 6 §104-105)', () {
    test('coverage report has no orphans', () {
      final cov = KnowledgeRegistry.coverage();
      expect(cov['rules_without_source'], 3, reason: 'R013-R015 are engineering/synthesis policies without a classical source');
      expect(cov['direct_classical_without_source'], 0);
      expect(cov['orphan_source_references'], 0);
      expect(KnowledgeRegistry.rules.map((r) => r.id).toSet().length, KnowledgeRegistry.rules.length);
      expect(KnowledgeRegistry.sources.map((s) => s.id).toSet().length, KnowledgeRegistry.sources.length);
    });

    test('master KB rules R001-R015 are present with their classifications', () {
      for (int i = 1; i <= 15; i++) {
        expect(KnowledgeRegistry.rules.any((r) => r.id == 'R${i.toString().padLeft(3, '0')}' && !r.appAddition), isTrue);
      }
      expect(KnowledgeRegistry.rule('R013').classification, 'ENGINEERING_HEURISTIC');
      expect(KnowledgeRegistry.rule('R012').sourceIds, ['SRC07']);
    });

    test('locators map to the right rules', () {
      expect(KnowledgeRegistry.ruleIdFor('BPHS Ashtakavarga'), 'R006');
      expect(KnowledgeRegistry.ruleIdFor('Phaladeepika (transit of the Daśā planet)'), 'R005');
      expect(KnowledgeRegistry.ruleIdFor('Phaladeepika (Vargottama)'), 'R011');
      expect(KnowledgeRegistry.ruleIdFor('BPHS Shodashavarga'), 'R007');
      expect(KnowledgeRegistry.ruleIdFor('Phaladeepika Dasha chapters; BPHS'), 'R004');
      expect(KnowledgeRegistry.ruleIdFor('Combustion orb table'), 'R009');
      expect(SourceTier.classicalDirect.code, 'DIRECT_CLASSICAL');
      expect(SourceTier.engineeringHeuristic.code, 'ENGINEERING_HEURISTIC');
    });
  });

  group('Jaimini', () {
    // Lagna Aries 10°. Degrees: Sun 29, Moon 3, Mars 20, Mercury 15, Jupiter 25, Venus 8, Saturn 12, Rahu 2 (=28 reversed).
    final c = chartOf(10, {
      'sun': 30 + 29, 'moon': 90 + 3, 'mars': 120 + 20, 'mercury': 60 + 15, 'jupiter': 240 + 25,
      'venus': 30 + 8, 'saturn': 300 + 12, 'rahu': 180 + 2, 'ketu': 0 + 2,
    });

    test('8-karaka scheme ranks Rahu from the end of its sign', () {
      final ks = JaiminiMath.karakas(c);
      expect(ks.map((k) => k.planet).toList(), ['sun', 'rahu', 'jupiter', 'mars', 'mercury', 'saturn', 'venus', 'moon']);
      expect(ks.map((k) => k.code).toList(), ['AK', 'AmK', 'BK', 'MK', 'PiK', 'PK', 'GK', 'DK']);
    });

    test('7-karaka scheme drops Rahu and Pitrikaraka', () {
      final ks = JaiminiMath.karakas(c, scheme: 7);
      expect(ks.map((k) => k.planet).toList(), ['sun', 'jupiter', 'mars', 'mercury', 'saturn', 'venus', 'moon']);
      expect(ks.map((k) => k.code).toList(), ['AK', 'AmK', 'BK', 'MK', 'PK', 'GK', 'DK']);
    });

    test('Arudha Lagna and the 10th-from exception', () {
      // Lagna Aries, lord Mars in Leo (5th): count 5 again from Leo -> Sagittarius.
      final al = JaiminiMath.arudha(c, 1);
      expect(al.rashi, 8);
      expect(al.exception, isFalse);
      // 2nd house Taurus, lord Venus in Taurus (own sign) -> falls in the house -> 10th from it = Aquarius.
      final a2 = JaiminiMath.arudha(c, 2);
      expect(a2.rashi, 10);
      expect(a2.exception, isTrue);
      // 12th Pisces, lord Jupiter in Sagittarius (10th from Pisces) -> 10th from Sagittarius = Virgo, the 7th from Pisces -> 10th from Virgo = Gemini.
      final ul = JaiminiMath.arudha(c, 12);
      expect(ul.code, 'UL');
      expect(ul.rashi, 2);
      expect(ul.exception, isTrue);
    });

    test('property: Arudha never falls in its house or the 7th from it', () {
      final rnd = math.Random(7);
      for (int n = 0; n < 200; n++) {
        final chart = chartOf(rnd.nextDouble() * 360, {for (final p in Ephemeris.planetOrder) p: rnd.nextDouble() * 360});
        for (int h = 1; h <= 12; h++) {
          final a = JaiminiMath.arudha(chart, h);
          final sign = (chart.lagnaRashi + h - 1) % 12;
          expect(a.rashi == sign || a.rashi == (sign + 6) % 12, isFalse);
        }
        final ks = JaiminiMath.karakas(chart);
        expect(ks.length, 8);
        for (int i = 1; i < ks.length; i++) {
          expect(ks[i - 1].degree >= ks[i].degree, isTrue);
        }
      }
    });
  });

  group('Cluster diagnostics (Volume 6 §18)', () {
    test('arc span wraps across 0°', () {
      final (span, center) = ClusterDiagnostics.arc([355, 5, 2]);
      expect(span, closeTo(10, 1e-9));
      expect(center, closeTo(0, 1e-9));
    });

    test('Deep Research tables are complete', () {
      expect(ConjunctionDb.signModifiers.length, 12);
      expect(ConjunctionDb.classicalObservations.length, 21);
      for (final (_, ps) in ConjunctionDb.clusters.where((c) => c.$2.length == 2)) {
        expect(ConjunctionDb.classicalObservation(ps[0], ps[1]), isNotEmpty);
      }
      expect(ConjunctionDb.pairSignModifierText('mars', 'mercury', 6), contains('partnership and negotiation'));
    });
  });

  group('Transit triggers and timing (Volume 6 §37, §91-94)', () {
    test('Jupiter-Saturn great conjunction is found on 21 Dec 2020', () {
      final jd = Ephemeris.julianDay(2020, 12, 21, 18);
      final sat = Ephemeris.siderealLongitude('saturn', jd);
      final natal = chartOf(0, {'saturn': sat});
      final ts = TimingMath.triggers(natal, [TriggerTarget('NATAL_SATURN_POINT', 'Saturn point', sat)],
          fromJd: Ephemeris.julianDay(2020, 6, 1), years: 1, planets: ['jupiter']);
      final conj = ts.where((t) => t.angle == 0).toList();
      expect(conj, isNotEmpty);
      expect(conj.first.exactJds, isNotEmpty);
      expect((conj.first.exactJds.first - jd).abs(), lessThan(1.0));
      expect(conj.first.enterJd, lessThan(conj.first.exactJds.first));
      expect(conj.first.exitJd, greaterThan(conj.first.exactJds.first));
    }, skip: skip);

    test('exact dates really are exact', () {
      final c = Ephemeris.computeChart(1990, 6, 15, 14, 30, 19.07, 72.88, 5.5);
      final from = Ephemeris.julianDay(2026, 10, 3);
      final ts = TimingMath.triggers(c, TimingMath.natalTargets(c), fromJd: from);
      expect(ts, isNotEmpty);
      for (final t in ts) {
        expect(t.exitJd, greaterThanOrEqualTo(t.enterJd));
        for (final e in t.exactJds) {
          final lon = Ephemeris.siderealLongitude(t.transit, e);
          expect(PrecisionMath.separation(lon, t.target.longitude - t.angle), lessThan(0.001), reason: t.summary);
          expect(e, inInclusiveRange(t.enterJd, t.exitJd));
        }
      }
    }, skip: skip);

    test('birth-time sensitivity separates stable and sensitive factors', () {
      final c = Ephemeris.computeChart(1990, 6, 15, 14, 30, 19.07, 72.88, 5.5);
      final s = TimingMath.sensitivity((m) => Ephemeris.computeChartForJd(c.jd + m / 1440, c.lat, c.lon, utcOffset: c.utcOffset));
      expect(s.offsets, [-5, -2, 0, 2, 5]);
      expect(s.stable, containsAll(['Sun sign', 'Moon sign']));
      expect(s.sensitive, contains('D60 Lagna'));
      expect({...s.stable, ...s.sensitive}.length, s.values.length);
    }, skip: skip);
  });

  group('Golden chart (Volume 6 §99): 15 Jun 1990 14:30 IST, Mumbai', () {
    test('positions, karakas, arudhas and Daśā', () {
      final c = Ephemeris.computeChart(1990, 6, 15, 14, 30, 19.07, 72.88, 5.5);
      expect(VedicMath.rashis[c.lagnaRashi].name, 'Virgo');
      expect(c.ascendantSidereal, closeTo(176.349, 0.01));
      final expected = {'sun': 60.283, 'moon': 319.963, 'mars': 347.224, 'mercury': 41.749, 'jupiter': 82.135, 'venus': 24.903, 'saturn': 270.312, 'rahu': 285.977};
      expected.forEach((p, v) => expect(c.planetLongitudes[p], closeTo(v, 0.01), reason: p));
      final j = JaiminiMath.compute(c);
      expect(j.karakas.map((k) => k.planet).toList(), ['venus', 'jupiter', 'moon', 'mars', 'rahu', 'mercury', 'saturn', 'sun']);
      expect(VedicMath.rashis[j.arudhaLagna.rashi].name, 'Capricorn');
      expect(VedicMath.rashis[j.upapada.rashi].name, 'Aries');
      expect(VedicMath.rashis[j.karakamsa].name, 'Scorpio');
      final running = DashaCalculations.compute(c.jd, c.planetLongitudes['moon']!, utcOffset: c.utcOffset).runningAt(Ephemeris.julianDay(2026, 10, 3));
      expect(running.take(2).map((p) => p.lord), ['mercury', 'mercury']);
    }, skip: skip);

    test('configurable ayanamsa, node and Daśā year', () {
      final c = Ephemeris.computeChart(1990, 6, 15, 14, 30, 19.07, 72.88, 5.5);
      try {
        Ephemeris.configure(ayanamsa: 'RAMAN', trueNode: true);
        final raman = Ephemeris.computeChart(1990, 6, 15, 14, 30, 19.07, 72.88, 5.5);
        expect(raman.ayanamsa, lessThan(c.ayanamsa - 1));
        expect(raman.planetLongitudes['sun']! - c.planetLongitudes['sun']!, closeTo(c.ayanamsa - raman.ayanamsa, 1e-6));
        expect(raman.planetLongitudes['rahu'], isNot(closeTo(c.planetLongitudes['rahu']! + c.ayanamsa - raman.ayanamsa, 1e-3)));
        expect(Ephemeris.nodeModel, contains('True'));
      } finally {
        Ephemeris.configure(ayanamsa: 'LAHIRI', trueNode: false);
      }
      expect(Ephemeris.computeChart(1990, 6, 15, 14, 30, 19.07, 72.88, 5.5).ayanamsa, closeTo(c.ayanamsa, 1e-9));
      final base = DashaCalculations.compute(c.jd, c.planetLongitudes['moon']!).mahadashas[3].endJD;
      try {
        DashaCalculations.yearDays = 365.2425;
        final tropical = DashaCalculations.compute(c.jd, c.planetLongitudes['moon']!).mahadashas[3].endJD;
        expect(tropical, lessThan(base));
      } finally {
        DashaCalculations.yearDays = 365.25;
      }
      final deep = DashaCalculations.compute(c.jd, c.planetLongitudes['moon']!, levels: 4).runningAt(Ephemeris.julianDay(2026, 10, 3));
      expect(deep.length, 4);
    }, skip: skip);
  });

  group('Synthesis engine (Volume 6)', () {
    late SynthesisReport r;
    late ChartData c;
    setUpAll(() {
      if (skip != null) return;
      c = Ephemeris.computeChart(1990, 6, 15, 14, 30, 19.07, 72.88, 5.5);
      r = SynthesisEngine.analyse(c, atJd: Ephemeris.julianDay(2026, 10, 3));
    });

    test('domains carry codes, V6 states, dependencies and rule traces', () {
      expect(r.domains.map((d) => d.domain.code).toSet().length, r.domains.length);
      for (final d in r.domains) {
        expect(d.dependencies.keys, ['NATAL_PROMISE', 'BHAVA_LORD_CHAIN', 'PLANETARY_STRENGTH', 'CONJUNCTION_SYNTHESIS', 'DASHA_ACTIVATION', 'TRANSIT_CONFIRMATION']);
        expect(['SUPPORTED', 'CONDITIONALLY_SUPPORTED', 'CONFLICTED', 'INSUFFICIENT_INPUT'], contains(d.masterStatus));
        expect(d.ruleTrace, isNotEmpty);
        for (final e in d.evidence) {
          expect(d.ruleTrace[e.ruleId], isTrue, reason: '${d.domain.id}: ${e.rule} -> ${e.ruleId}');
          expect(KnowledgeRegistry.rules.any((x) => x.id == e.ruleId), isTrue);
        }
        expect(d.domain.vargas.first, 'D1');
        for (final w in d.timingWindows) {
          expect(w.endJd, greaterThan(w.startJd));
          expect(w.activation.first, endsWith('_MD'));
          expect(w.activation[1], endsWith('_AD'));
        }
        expect(d.graph.nodes.containsKey('PRED:${d.domain.code}'), isTrue);
        for (final e in d.graph.edges) {
          expect(d.graph.nodes.containsKey(e.from) && d.graph.nodes.containsKey(e.to), isTrue);
        }
        expect(d.explanation()['status'], d.v6Status.code);
        if (!d.statuses.contains(PredictionStatus.natalPromisePresent)) {
          expect([Confidence.low, Confidence.moderate, Confidence.conflicted, Confidence.insufficient], contains(d.confidence));
        }
        for (int i = 1; i < d.timingWindows.length; i++) {
          expect(d.timingWindows[i].startJd, greaterThanOrEqualTo(d.timingWindows[i - 1].startJd));
        }
        for (final w in d.timingWindows) {
          expect(w.triggers.every((t) => t.exactJds.isNotEmpty), isTrue);
        }
      }
      final career = r.domains.firstWhere((d) => d.domain.id == 'career');
      expect(career.evidence.any((e) => e.ruleId == 'R019' && e.text.contains('Amātyakāraka')), isTrue);
      final marriage = r.domains.firstWhere((d) => d.domain.id == 'marriage');
      expect(marriage.evidence.any((e) => e.text.contains('Upapada')), isTrue);
      expect(marriage.evidence.any((e) => e.text.contains('Dārakāraka')), isTrue);
      final fortune = r.domains.firstWhere((d) => d.domain.id == 'fortune');
      expect(fortune.layer(EvidenceLayer.varga).where((e) => e.ruleId == 'R007').length, 6);
    }, skip: skip);

    test('audit has fingerprints and rule counts', () {
      expect(r.audit['inputs_hash'], hasLength(64));
      expect(r.audit['calculation_hash'], hasLength(64));
      expect(r.audit['run_id'], startsWith('RUN-'));
      final executed = int.parse(r.audit['rules_executed']!);
      final triggered = int.parse(r.audit['rules_triggered']!);
      expect(triggered, lessThanOrEqualTo(executed));
      expect(int.parse(r.audit['rules_conflicted']!), lessThanOrEqualTo(triggered));
      expect(r.jaimini, isNotNull);
      expect(r.sensitivity, isNotNull);
    }, skip: skip);

    test('determinism: same input and versions give the same result', () {
      final again = SynthesisEngine.analyse(Ephemeris.computeChart(1990, 6, 15, 14, 30, 19.07, 72.88, 5.5), atJd: Ephemeris.julianDay(2026, 10, 3));
      expect(again.audit['inputs_hash'], r.audit['inputs_hash']);
      expect(again.audit['calculation_hash'], r.audit['calculation_hash']);
      expect(again.audit['run_id'], r.audit['run_id']);
      for (int i = 0; i < r.domains.length; i++) {
        expect(again.domains[i].report(), r.domains[i].report());
        expect(again.domains[i].graph.toJson(), r.domains[i].graph.toJson());
      }
      final other = TimingMath.inputsHash(c, const CalcConfig(karakaScheme: 7));
      expect(other, isNot(r.audit['inputs_hash']));
    }, skip: skip);
  });
}
