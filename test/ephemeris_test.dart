import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_jyotish/core/barshphal_math.dart';
import 'package:mobile_jyotish/core/chart_summary.dart';
import 'package:mobile_jyotish/core/ephemeris.dart';
import 'package:mobile_jyotish/core/kp_math.dart';
import 'package:mobile_jyotish/core/panchang_math.dart';
import 'package:mobile_jyotish/core/transit_math.dart';
import 'package:mobile_jyotish/core/vedic_math.dart';

import 'helpers/sweph_test_helper.dart';

void main() {
  setUpAll(initEphemerisForTests);
  final skip = swephSkipReason();

  test('India independence chart (1947-08-15 00:00 IST, Delhi)', () {
    final c = Ephemeris.computeChart(1947, 8, 15, 0, 0, 28.6139, 77.2090, 5.5);
    expect(VedicMath.rashis[c.lagnaRashi].name, 'Taurus');
    expect(c.ascendantSidereal, closeTo(37.7, 0.2)); // Taurus ~7°44'
    expect(c.planetLongitudes['moon'], closeTo(93.98, 0.05)); // Cancer ~3°59'
    expect(c.planetLongitudes['sun'], closeTo(117.99, 0.05)); // Cancer ~27°59'
    expect(VedicMath.rashis[VedicMath.rashiIndex(c.planetLongitudes['rahu']!)].name, 'Taurus');
    expect(c.ayanamsa, closeTo(23.12, 0.02));
    expect(c.isRetrograde('saturn'), isFalse);
  }, skip: skip);

  test('retrograde detection (Mercury retrograde on 2023-04-25)', () {
    final c = Ephemeris.computeChart(2023, 4, 25, 12, 0, 28.6, 77.2, 5.5);
    expect(c.isRetrograde('mercury'), isTrue);
    expect(c.isRetrograde('rahu'), isFalse, reason: 'nodes are not flagged');
  }, skip: skip);

  test('Panchang for New Delhi on 2025-01-01 (Wednesday)', () {
    // 10:00 IST
    final c = Ephemeris.computeChart(2025, 1, 1, 10, 0, 28.6139, 77.2090, 5.5);
    final p = PanchangMath.computePanchang(c, 28.6139, 77.2090, 5.5);
    expect((p['vara'] as Map)['name'], 'Wednesday');
    expect(p['sunrise'], anyOf('07:13', '07:14', '07:15'));
    expect(p['sunset'], anyOf('17:35', '17:36', '17:37'));
    // Wednesday Rahu Kaal is the 5th eighth of the day (~12:25-13:43).
    expect((p['rahuKaal'] as Map)['start'], startsWith('12:'));
    expect((p['tithi'] as Map)['name'], 'Dwitiya'); // Shukla Dwitiya
  }, skip: skip);

  test('Vara before sunrise belongs to the previous day', () {
    // 2025-01-02 05:00 IST is before sunrise, so it is still Wednesday's vara.
    final c = Ephemeris.computeChart(2025, 1, 2, 5, 0, 28.6139, 77.2090, 5.5);
    final p = PanchangMath.computePanchang(c, 28.6139, 77.2090, 5.5);
    expect((p['vara'] as Map)['name'], 'Wednesday');
  }, skip: skip);

  test('KP: Placidus cusp 1 equals the KP ascendant, KP ayanamsa close to Lahiri', () {
    final c = Ephemeris.computeChart(1990, 6, 15, 14, 30, 19.07, 72.88, 5.5);
    final cusps = KPMath.computeKPCusps(c.jd, c.lat, c.lon);
    final kpAsc = Ephemeris.ascendant(c.jd, c.lat, c.lon, Ayanamsa.krishnamurti);
    expect(cusps.first.longitude, closeTo(kpAsc, 1e-6));
    final diff = Ephemeris.ayanamsaValue(c.jd) - Ephemeris.ayanamsaValue(c.jd, Ayanamsa.krishnamurti);
    expect(diff.abs(), lessThan(0.2));
    expect(KPMath.computeKPPlanets(c).length, 9);
  }, skip: skip);

  test('Varshaphal solar return lands on the natal Sun longitude', () {
    final c = Ephemeris.computeChart(1990, 6, 15, 14, 30, 19.07, 72.88, 5.5);
    final b = BarshphalMath.compute(c, 30);
    expect(b.varshaphalChart.planetLongitudes['sun'], closeTo(c.planetLongitudes['sun']!, 1e-5));
    final years = (b.solarReturnJD - c.jd) / 365.256363;
    expect(years, closeTo(30, 0.01));
    expect(b.munthaRashi, (c.lagnaRashi + 30) % 12);
    expect(b.solarReturnDate, contains('2020-06-'));

    final now = Ephemeris.julianDay(2025, 1, 1);
    expect(BarshphalMath.currentAge(c, now), 34);
  }, skip: skip);

  test('Transits and chart summary', () {
    final c = Ephemeris.computeChart(1990, 6, 15, 14, 30, 19.07, 72.88, 5.5);
    final t = TransitMath.compute(c, Ephemeris.julianDay(2025, 1, 1));
    expect(t.length, 9);
    final saturn = t.firstWhere((x) => x.planet == 'saturn');
    expect(saturn.rashiData.name, 'Aquarius');
    final summary = ChartSummary.describe(c, name: 'Test');
    expect(summary, contains('Ascendant (Lagna)'));
    expect(summary, contains('Saturn:'));
  }, skip: skip);
}
