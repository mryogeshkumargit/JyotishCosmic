import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_jyotish/core/ashtakavarga_math.dart';
import 'package:mobile_jyotish/core/conjunction_db.dart';
import 'package:mobile_jyotish/core/ephemeris.dart';
import 'package:mobile_jyotish/core/shadbala_math.dart';
import 'package:mobile_jyotish/core/synthesis_engine.dart';

import 'helpers/sweph_test_helper.dart';

void main() {
  setUpAll(initEphemerisForTests);
  final skip = swephSkipReason();

  group('Conjunction database (Volumes 2-3)', () {
    test('120 clusters in catalogue order', () {
      final sizes = <int, int>{};
      for (final c in ConjunctionDb.clusters) {
        sizes[c.$2.length] = (sizes[c.$2.length] ?? 0) + 1;
      }
      expect(sizes, {2: 21, 3: 35, 4: 35, 5: 21, 6: 7, 7: 1});
      expect(ConjunctionDb.planetsOf('T01'), ['sun', 'moon', 'mars']);
      expect(ConjunctionDb.planetsOf('Q23'), ['moon', 'mars', 'mercury', 'saturn']);
      expect(ConjunctionDb.planetsOf('Q35'), ['mercury', 'jupiter', 'venus', 'saturn']);
      expect(ConjunctionDb.planetsOf('H01').length, 7);
      expect(ConjunctionDb.clusterIdOf(['saturn', 'sun']), 'P06');
    });

    test('record V3-Q23-B07-SCO matches Volume 3 exactly', () {
      final r = ConjunctionDb.record('Q23', 7, 7);
      expect(r.recordId, 'V3-Q23-B07-SCO');
      expect(r.clusterLabel, 'Moon + Mars + Mercury + Saturn');
      expect(ConjunctionDb.planetName(r.dispositor), 'Mars');
      expect(r.element, 'Water');
      expect(r.modality, 'Fixed');
      expect(r.pairwiseText, 'Moon-Mars; Moon-Mercury; Moon-Saturn; Mars-Mercury; Mars-Saturn; Mercury-Saturn');
      expect(r.functionalLordshipText,
          'Moon: 3 (Upachaya) | Mars: 7,12 (Kendra/Maraka; Dusthana) | Mercury: 2,5 (Maraka; Trikona) | Saturn: 9,10 (Trikona; Kendra/Upachaya)');
      expect(r.sourceTier, 'CLASSICAL-DIRECT-WHERE-SOURCE-EXACT; OTHERWISE CLASSICAL-PAIRWISE + SYSTEMATIC-SYNTHESIS');
      expect(r.coreThemes,
          'mind, emotion, nourishment, adaptability; action, courage, initiative, conflict; intellect, speech, analysis, commerce; discipline, duty, delay, structure, endurance');
      expect(r.bhavaInteraction, 'The cluster concentrates its combined planetary significations into the Yuvati domain.');
      expect(r.rashiInteraction, 'The Scorpio environment modifies expression through water element, fixed modality, and Mars as dispositor.');
    });

    test('17,280 records with the Volume 3 source-tier distribution', () {
      final tiers = <String, int>{};
      int n = 0;
      for (final c in ConjunctionDb.clusters) {
        for (int h = 1; h <= 12; h++) {
          for (int s = 0; s < 12; s++) {
            final r = ConjunctionDb.record(c.$1, h, s);
            tiers[r.sourceTier] = (tiers[r.sourceTier] ?? 0) + 1;
            expect(r.pairs.length, r.size * (r.size - 1) ~/ 2);
            n++;
          }
        }
      }
      expect(n, ConjunctionDb.totalRecords);
      expect(tiers['CLASSICAL-DIRECT + SYSTEMATIC-SYNTHESIS'], 3024);
      expect(tiers['CLASSICAL-DIRECT-WHERE-SOURCE-EXACT; OTHERWISE CLASSICAL-PAIRWISE + SYSTEMATIC-SYNTHESIS'], 14112);
      expect(tiers['CLASSICAL-PAIRWISE + SYSTEMATIC-SYNTHESIS'], 144);
    });

    test('Volume 2 pair texts', () {
      expect(ConjunctionDb.pairBhavaText('sun', 'moon', 1),
          'will/identity + mind/feeling expressed through identity, body, temperament, self-direction. Judge the house lord, Karaka, sign and dispositor before final synthesis.');
      expect(ConjunctionDb.pairRashiText('sun', 'moon', 0),
          'will/identity + mind/feeling operating through fire movable Aries symbolism; Mars is the dispositor.');
      expect(ConjunctionDb.pairLagnaText('sun', 'mars', 0),
          'Sun owns 5; Mars owns 1,8. Combine these house significations with the house occupied by the conjunction.');
    });

    test('finds the conjunctions of a real chart with degree data', () {
      final c = Ephemeris.computeChart(1990, 6, 15, 14, 30, 19.07, 72.88, 5.5);
      final found = ConjunctionDb.find(c);
      expect(found, isNotEmpty);
      final cj = found.first;
      expect(cj.edges.length, cj.record.pairs.length);
      expect(cj.record.bhava, 10);
      expect(ConjunctionDb.nodeAssociations(c).length, 2);
    }, skip: skip);
  });

  group('Ashtakavarga', () {
    test('Bhinnashtakavarga totals are fixed and SAV is 337', () {
      final c = Ephemeris.computeChart(1990, 6, 15, 14, 30, 19.07, 72.88, 5.5);
      final av = AshtakavargaMath.compute(c);
      for (final e in AshtakavargaMath.expectedTotals.entries) {
        expect(av.bhinna[e.key]!.total, e.value, reason: e.key);
      }
      expect(av.sarvaTotal, 337);
      expect(av.pinda.length, 7);
    }, skip: skip);

    test('Trikona Shodhana', () {
      // Trine Aries/Leo/Sagittarius: 5, 3, 4 -> 2, 0, 1; trine with a zero stays.
      final out = AshtakavargaMath.trikonaShodhana([5, 0, 2, 2, 3, 1, 2, 2, 4, 6, 2, 2]);
      expect([out[0], out[4], out[8]], [2, 0, 1]);
      expect([out[1], out[5], out[9]], [0, 1, 6]);
      expect([out[3], out[7], out[11]], [0, 0, 0]); // all equal -> zero
    });

    test('Ekadhipatya Shodhana', () {
      // Mars signs Aries (0) and Scorpio (7).
      List<int> run(int a, int b, Set<int> occ) {
        final v = List.filled(12, 0);
        v[0] = a;
        v[7] = b;
        final r = AshtakavargaMath.ekadhipatyaShodhana(v, occ);
        return [r[0], r[7]];
      }

      expect(run(3, 5, {}), [3, 3]); // both empty, unequal -> the smaller
      expect(run(4, 4, {}), [0, 0]); // both empty, equal -> zero
      expect(run(4, 2, {0}), [4, 0]); // occupied has more -> empty becomes zero
      expect(run(2, 5, {0}), [2, 3]); // occupied has fewer -> empty reduced
      expect(run(3, 5, {0, 7}), [3, 5]); // both occupied -> unchanged
    });
  });

  group('Shadbala', () {
    test('components are consistent and within classical ranges', () {
      final c = Ephemeris.computeChart(1990, 6, 15, 14, 30, 19.07, 72.88, 5.5);
      final r = ShadbalaMath.compute(c);
      expect(r.planets.length, 7);
      expect(r.bhavas.length, 12);
      expect(r.dayBirth, isTrue);
      for (final s in r.planets.values) {
        final sum = s.six.values.reduce((a, b) => a + b);
        expect(s.total, closeTo(sum, 1e-9), reason: s.planet);
        expect(s.component('Uchcha'), inInclusiveRange(0, 60));
        expect(s.dig, inInclusiveRange(0, 60));
        expect(s.cheshta, inInclusiveRange(0, 60));
        expect(s.naisargika, ShadbalaMath.naisargikaBala[s.planet]);
        expect(s.component('Kendradi'), anyOf(60, 30, 15));
        expect(s.ishtaPhala, inInclusiveRange(0, 60));
        expect(s.kashtaPhala, inInclusiveRange(0, 60));
      }
      // 15 June 1990 was a Friday: Venus is the weekday lord.
      expect(r.planets['venus']!.component('Vara'), 45);
      expect(r.planets['mercury']!.component('Nathonnata'), 60);
      expect(r.planets['jupiter']!.component('Tribhaga'), 60);
    }, skip: skip);
  });

  group('Synthesis engine (Volume 5)', () {
    test('every domain has traced evidence and a status', () {
      final c = Ephemeris.computeChart(1990, 6, 15, 14, 30, 19.07, 72.88, 5.5);
      final r = SynthesisEngine.analyse(c, atJd: Ephemeris.julianDay(2026, 10, 3));
      expect(r.domains.length, SynthesisEngine.domains.length);
      for (final d in r.domains) {
        expect(d.evidence, isNotEmpty, reason: d.domain.id);
        expect(d.evidence.map((e) => e.id).toList(), [for (int i = 1; i <= d.evidence.length; i++) 'R$i']);
        expect(d.statuses, isNotEmpty);
        expect(d.lordChains.length, d.domain.bhavas.length);
        expect(d.interpretation, isNot(contains('definitely')));
        expect(d.report(), contains('STATUS:'));
      }
      expect(r.audit.keys, containsAll(['engine_version', 'ephemeris', 'ayanamsha', 'node_model', 'planetary_war_rule', 'combustion_orb_table']));
      final career = r.domains.firstWhere((d) => d.domain.id == 'career');
      expect(career.layer(EvidenceLayer.dasha), isNotEmpty);
    }, skip: skip);

    test('rectification keeps every candidate and backtests events', () {
      final c = Ephemeris.computeChart(1990, 6, 15, 14, 30, 19.07, 72.88, 5.5);
      final events = [LifeEvent(DateTime(2015, 6, 1), 'career'), LifeEvent(DateTime(2018, 2, 1), 'marriage')];
      final cands = SynthesisEngine.rectify(
        (m) => Ephemeris.computeChartForJd(c.jd + m / 1440, c.lat, c.lon, utcOffset: c.utcOffset),
        events,
        rangeMinutes: 20,
        stepMinutes: 10,
      );
      expect(cands.map((x) => x.offsetMinutes), [-20, -10, 0, 10, 20]);
      expect(cands.firstWhere((x) => x.offsetMinutes == 0).chart.ascendantSidereal, closeTo(c.ascendantSidereal, 1e-9));
      final bt = SynthesisEngine.backtest(c, events.first);
      expect(bt.periods, isNotEmpty);
      expect(bt.trace, isNotEmpty);
    }, skip: skip);
  });
}
