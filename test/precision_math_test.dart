import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_jyotish/core/calc_config.dart';
import 'package:mobile_jyotish/core/ephemeris.dart';
import 'package:mobile_jyotish/core/planetary_dignity.dart';
import 'package:mobile_jyotish/core/precision_math.dart';

import 'helpers/sweph_test_helper.dart';

void main() {
  setUpAll(initEphemerisForTests);
  final skip = swephSkipReason();

  test('degree dignity ranges', () {
    // Moon in Taurus: exalted below 3°, Moolatrikona after.
    expect(PlanetaryDignity.getAdvancedDignity('moon', 1, const {}, degree: 2), 'Exalted');
    expect(PlanetaryDignity.getAdvancedDignity('moon', 1, const {}, degree: 10), 'Moolatrikona');
    // Mercury in Virgo: exalted, Moolatrikona, own sign.
    expect(PlanetaryDignity.getAdvancedDignity('mercury', 5, const {}, degree: 10), 'Exalted');
    expect(PlanetaryDignity.getAdvancedDignity('mercury', 5, const {}, degree: 17), 'Moolatrikona');
    expect(PlanetaryDignity.getAdvancedDignity('mercury', 5, const {}, degree: 25), 'Own Sign');
    // Sun in Leo after 20° is in its own sign, not Moolatrikona.
    expect(PlanetaryDignity.getAdvancedDignity('sun', 4, const {}, degree: 25), 'Own Sign');
    expect(PlanetaryDignity.getAdvancedDignity('sun', 4, const {}), 'Moolatrikona');
  });

  test('sputa drishti follows BPHS', () {
    expect(PrecisionMath.sputaDrishti('sun', 180), 60);
    expect(PrecisionMath.sputaDrishti('sun', 0), 0);
    expect(PrecisionMath.sputaDrishti('mars', 90), 60); // 4th aspect
    expect(PrecisionMath.sputaDrishti('mars', 210), 60); // 8th aspect
    expect(PrecisionMath.sputaDrishti('jupiter', 120), 60);
    expect(PrecisionMath.sputaDrishti('jupiter', 240), 60);
    expect(PrecisionMath.sputaDrishti('saturn', 60), 60);
    expect(PrecisionMath.sputaDrishti('saturn', 270), 60);
    expect(PrecisionMath.sputaDrishti('venus', 90), 45);
  });

  test('Bhava-sandhi uses equal houses from the ascendant', () {
    expect(PrecisionMath.inSandhi(25.5, 10, 1), isTrue); // 15.5° from the ascendant
    expect(PrecisionMath.inSandhi(40, 10, 1), isFalse);
  });

  test('quality-control checks pass for a real chart', () {
    final c = Ephemeris.computeChart(1990, 6, 15, 14, 30, 19.07, 72.88, 5.5);
    final qc = PrecisionMath.qualityControl(c);
    for (final q in qc) {
      expect(q.passed, isTrue, reason: '${q.id} ${q.description}: ${q.detail}');
    }
    expect(qc.length, greaterThanOrEqualTo(11));
    expect(c.midheaven, isNotNull);
    expect(c.planetLatitudes['moon']!.abs(), lessThan(5.5));
    expect(c.declinations['sun']!.abs(), lessThan(23.5));
    expect(c.heliocentricLongitudes.keys.toSet(), {'mars', 'mercury', 'jupiter', 'venus', 'saturn'});
  }, skip: skip);

  test('combustion, motion and pair edges', () {
    // 2023-04-25: Mercury retrograde near the Sun (inferior conjunction on 1 May).
    final c = Ephemeris.computeChart(2023, 4, 25, 12, 0, 28.6, 77.2, 5.5);
    final r = PrecisionMath.record(c, 'mercury');
    expect(r.motion, Motion.retrograde);
    expect(r.combustionOrb, 12); // retrograde orb
    expect(r.combust, isTrue);
    final e = PrecisionMath.edge(c, 'sun', 'mercury');
    expect(e.combustionLink, isTrue);
    expect(e.applying, isTrue); // they meet on 1 May
  }, skip: skip);

  test('planetary war is degree-sensitive and uses latitude', () {
    // Jupiter-Saturn great conjunction, 21 Dec 2020 (~0.1° apart).
    final c = Ephemeris.computeChart(2020, 12, 21, 18, 0, 28.6, 77.2, 5.5);
    final w = PrecisionMath.war(c, 'jupiter', 'saturn');
    expect(w, isNotNull);
    expect(w!.separation, lessThan(0.5));
    final north = c.planetLatitudes['jupiter']! >= c.planetLatitudes['saturn']! ? 'jupiter' : 'saturn';
    expect(w.winner, north);
    final venus = PrecisionMath.war(c, 'jupiter', 'saturn', const CalcConfig(warRule: WarRule.venusAlwaysWins));
    expect(venus!.winner, north); // Venus is not involved
  }, skip: skip);
}
