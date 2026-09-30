import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_jyotish/core/doshas_math.dart';
import 'package:mobile_jyotish/core/panchang_math.dart';
import 'package:mobile_jyotish/core/vedic_math.dart';
import 'package:mobile_jyotish/services/update_service.dart';

void main() {
  group('Vimshottari dasha', () {
    const birth = 2451545.0;

    test('Moon at start of Ashwini gives a full Ketu Mahadasha', () {
      final d = DashaCalculations.compute(birth, 0.0001);
      expect(d.mahadashas.first.lord, 'ketu');
      expect(d.mahadashas.first.years, closeTo(7, 1e-3));
      expect(d.mahadashas.length, 9);
    });

    test('balance and sub-periods are continuous inside the partial first Mahadasha', () {
      final moon = 360 / 27 * 0.5; // half of Ashwini elapsed
      final d = DashaCalculations.compute(birth, moon);
      final first = d.mahadashas.first;
      expect(first.years, closeTo(3.5, 1e-6));
      expect(first.startJD, birth);

      // Antardashas cover exactly [birth, end of Mahadasha].
      expect(first.subPeriods.first.startJD, closeTo(birth, 1e-9));
      expect(first.subPeriods.last.endJD, closeTo(first.endJD, 1e-6));
      for (int i = 1; i < first.subPeriods.length; i++) {
        expect(first.subPeriods[i].startJD, closeTo(first.subPeriods[i - 1].endJD, 1e-6));
      }

      // 3.5 of Ketu's 7 years elapsed: Ke(0.408) Ve(1.167) Su(0.35) Mo(0.583) Ma(0.408)
      // sum to 2.917, and Ra(1.05) reaches 3.967 > 3.5, so Ketu-Rahu runs at birth.
      expect(first.subPeriods.first.lord, 'rahu');
      // Pratyantardashas of a partially elapsed antardasha keep their true lengths.
      final rahuAntar = first.subPeriods.first;
      expect(rahuAntar.subPeriods.last.endJD, closeTo(rahuAntar.endJD, 1e-6));
      expect(rahuAntar.subPeriods.last.lord, 'mars'); // Ra Ju Sa Me Ke Ve Su Mo Ma
    });

    test('runningAt returns maha/antar/pratyantar chain', () {
      final d = DashaCalculations.compute(birth, 100);
      final chain = d.runningAt(birth + 5000);
      expect(chain.length, 3);
    });
  });

  group('Panchang tables', () {
    test('karana sequence over the lunar month', () {
      expect(PanchangMath.karanas[PanchangMath.karanaIndexForHalfTithi(0)], 'Kimstughna');
      expect(PanchangMath.karanas[PanchangMath.karanaIndexForHalfTithi(1)], 'Bava');
      expect(PanchangMath.karanas[PanchangMath.karanaIndexForHalfTithi(7)], 'Vishti');
      expect(PanchangMath.karanas[PanchangMath.karanaIndexForHalfTithi(8)], 'Bava');
      expect(PanchangMath.karanas[PanchangMath.karanaIndexForHalfTithi(56)], 'Vishti');
      expect(PanchangMath.karanas[PanchangMath.karanaIndexForHalfTithi(57)], 'Shakuni');
      expect(PanchangMath.karanas[PanchangMath.karanaIndexForHalfTithi(58)], 'Chatushpada');
      expect(PanchangMath.karanas[PanchangMath.karanaIndexForHalfTithi(59)], 'Naga');
    });

    test('Rahu Kaal is the 7th part on Tuesday', () {
      expect(PanchangMath.rahuKaalPart[2], 6);
      expect(PanchangMath.fmtTime(15.5), '15:30');
      expect(PanchangMath.fmtTime(-0.5), '23:30');
    });
  });

  group('Doshas', () {
    test('Grahan dosha handles the 0/360 wrap-around', () {
      final r = DoshasMath.computeGrahanDosha({'sun': 358.0, 'rahu': 3.0, 'moon': 100, 'ketu': 183.0});
      expect(r.present, isTrue);
    });

    test('Kaal Sarp type follows Rahu house from Lagna', () {
      final longs = {
        'rahu': 95.0, 'ketu': 275.0,
        'sun': 120.0, 'moon': 130.0, 'mars': 140.0, 'mercury': 150.0,
        'jupiter': 160.0, 'venus': 170.0, 'saturn': 200.0,
      };
      final r = DoshasMath.computeKaalSarp(longs, 3)!; // Cancer Lagna, Rahu in Cancer
      expect(r.present, isTrue);
      expect(r.conditions.first, contains('Anant'));
    });

    test('Mars in Aries (moolatrikona) cancels Manglik', () {
      final r = DoshasMath.computeManglik({'mars': 10.0, 'moon': 200, 'venus': 250}, 0)!;
      expect(r.present, isFalse);
      expect(r.exceptions, isNotEmpty);
    });
  });

  test('D30 boundary at exactly 5 degrees belongs to the second segment', () {
    expect(VedicMath.vargaRashi(5.0, 'D30', 30), 10);
  });

  test('update version comparison', () {
    expect(UpdateService.isNewer('v1.0.1', '1.0.0'), isTrue);
    expect(UpdateService.isNewer('1.0.0', '1.0.0'), isFalse);
    expect(UpdateService.isNewer('v1.2.9', '1.2.10'), isFalse);
    expect(UpdateService.isNewer('2.0.0+5', '1.9.9'), isTrue);
  });
}
