// Pure-Dart tests of the astrological rules (no Swiss Ephemeris needed).
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_jyotish/core/doshas_math.dart';
import 'package:mobile_jyotish/core/kp_math.dart';
import 'package:mobile_jyotish/core/milan_math.dart';
import 'package:mobile_jyotish/core/panchang_math.dart';
import 'package:mobile_jyotish/core/planetary_dignity.dart';
import 'package:mobile_jyotish/core/vedic_math.dart';
import 'package:mobile_jyotish/core/yogas_math.dart';

void main() {
  group('Nakshatra / pada / sign helpers', () {
    test('boundaries', () {
      expect(VedicMath.rashiIndex(0), 0);
      expect(VedicMath.rashiIndex(29.999), 0);
      expect(VedicMath.rashiIndex(30), 1);
      expect(VedicMath.rashiIndex(-1), 11);
      expect(VedicMath.nakshatraIndex(13.3333), 0);
      expect(VedicMath.nakshatraIndex(13.3334), 1);
      expect(VedicMath.pada(0), 1);
      expect(VedicMath.pada(3.34), 2);
      expect(VedicMath.pada(13.3), 4);
    });

    test('angular distance wraps around 0°', () {
      expect(VedicMath.angularDistance(359, 1), closeTo(2, 1e-9));
      expect(VedicMath.angularDistance(10, 200), closeTo(170, 1e-9));
    });
  });

  group('Divisional charts', () {
    test('Navamsa (D9)', () {
      expect(VedicMath.vargaRashi(0.5, 'D9', 9), 0); // Aries 1st navamsa -> Aries
      expect(VedicMath.vargaRashi(29.9, 'D9', 9), 8); // Aries last -> Sagittarius
      expect(VedicMath.vargaRashi(30.5, 'D9', 9), 9); // Taurus starts from Capricorn
      expect(VedicMath.vargaRashi(60.5, 'D9', 9), 6); // Gemini starts from Libra
      expect(VedicMath.vargaRashi(90.5, 'D9', 9), 3); // Cancer starts from Cancer
    });

    test('Hora (D2)', () {
      expect(VedicMath.vargaRashi(5, 'D2', 2), 4); // odd sign first half: Sun (Leo)
      expect(VedicMath.vargaRashi(20, 'D2', 2), 3); // odd sign second half: Moon (Cancer)
      expect(VedicMath.vargaRashi(35, 'D2', 2), 3); // even sign first half: Moon
    });

    test('Trimsamsa (D30) boundaries are half-open', () {
      expect(VedicMath.vargaRashi(4.99, 'D30', 30), 0);
      expect(VedicMath.vargaRashi(5.0, 'D30', 30), 10);
      expect(VedicMath.vargaRashi(30 + 4.99, 'D30', 30), 1);
      expect(VedicMath.vargaRashi(30 + 5.0, 'D30', 30), 5);
    });

    test('Dasamsa (D10) even signs start from the 9th', () {
      expect(VedicMath.vargaRashi(30.5, 'D10', 10), 9); // Taurus -> Capricorn
    });
  });

  group('Vimshottari dasha', () {
    test('Moon at 0° Aries: Ketu dasha starts at birth, 120 years total', () {
      final d = DashaCalculations.compute(2451545.0, 0.0);
      expect(d.mahadashas.first.lord, 'ketu');
      expect(d.mahadashas.first.startJD, closeTo(2451545.0, 1e-6));
      final total = d.mahadashas.fold<double>(0, (s, p) => s + p.years);
      expect(total, closeTo(120, 1e-9));
      expect(d.balanceYears, closeTo(7, 1e-9));
    });

    test('Half-way through Bharani: Venus dasha started 10 years before birth', () {
      const birth = 2451545.0;
      final moon = 13 + 1 / 3 + 20 / 3; // middle of Bharani
      final d = DashaCalculations.compute(birth, moon);
      expect(d.mahadashas.first.lord, 'venus');
      expect(d.mahadashas.first.startJD, closeTo(birth - 10 * DashaCalculations.yearDays, 1e-6));
      expect(d.balanceYears, closeTo(10, 1e-9));
    });

    test('Sub-periods tile their parent exactly', () {
      final d = DashaCalculations.compute(2451545.0, 123.456, depth: 3);
      for (final maha in d.mahadashas) {
        expect(maha.subPeriods.length, 9);
        expect(maha.subPeriods.first.lord, maha.lord);
        expect(maha.subPeriods.first.startJD, closeTo(maha.startJD, 1e-6));
        expect(maha.subPeriods.last.endJD, closeTo(maha.endJD, 1e-6));
        for (final antar in maha.subPeriods) {
          expect(antar.subPeriods.last.endJD, closeTo(antar.endJD, 1e-6));
        }
      }
    });

    test('runningAt returns Maha → Antar → Pratyantar chain', () {
      final d = DashaCalculations.compute(2451545.0, 200.0);
      final chain = d.runningAt(2451545.0 + 3000);
      expect(chain.length, 3);
      expect(chain[0].level, 1);
      expect(chain[1].contains(2451545.0 + 3000), isTrue);
    });
  });

  group('Ashtakoot Milan tables', () {
    test('Yoni table is symmetric and enemies score 0', () {
      for (int i = 0; i < 14; i++) {
        expect(MilanMath.yoniTable[i][i], 4);
        for (int j = 0; j < 14; j++) {
          expect(MilanMath.yoniTable[i][j], MilanMath.yoniTable[j][i], reason: '$i,$j');
        }
      }
      const enemies = [[0, 8], [1, 13], [2, 11], [3, 12], [4, 10], [5, 6], [7, 9]];
      for (final e in enemies) {
        expect(MilanMath.yoniTable[e[0]][e[1]], 0);
      }
    });

    test('Nadi follows the Adi-Madhya-Antya zig-zag', () {
      const adi = [0, 5, 6, 11, 12, 17, 18, 23, 24];
      const madhya = [1, 4, 7, 10, 13, 16, 19, 22, 25];
      for (final n in adi) {
        expect(MilanMath.nadiOf(n), 0, reason: 'nak $n');
      }
      for (final n in madhya) {
        expect(MilanMath.nadiOf(n), 1, reason: 'nak $n');
      }
      expect(MilanMath.nadiOf(2), 2);
      expect(MilanMath.nadiOf(26), 2);
    });

    test('Gana: Krittika is Rakshasa, Uttara Bhadrapada is Manushya', () {
      expect(MilanMath.ganaOf(2), 2);
      expect(MilanMath.ganaOf(25), 1);
      expect(MilanMath.ganaOf(0), 0);
    });

    test('Vashya splits Sagittarius and Capricorn at 15°', () {
      expect(MilanMath.vashyaOf(240 + 10), 1); // Sagittarius 1st half: Manava
      expect(MilanMath.vashyaOf(240 + 20), 0); // 2nd half: Chatushpada
      expect(MilanMath.vashyaOf(270 + 10), 0); // Capricorn 1st half: Chatushpada
      expect(MilanMath.vashyaOf(270 + 20), 2); // 2nd half: Jalachara
    });

    test('Graha Maitri points', () {
      expect(MilanMath.maitriPoints(0, 7), 5); // Mars-Mars
      expect(MilanMath.maitriPoints(4, 0), 5); // Sun-Mars mutual friends
      expect(MilanMath.maitriPoints(4, 10), 0); // Sun-Saturn mutual enemies
      expect(MilanMath.maitriPoints(3, 5), 1); // Moon-Mercury: friend / enemy
    });

    test('Worked example: Ashwini (Aries 5°) boy with Bharani (Aries 20°) girl = 34', () {
      final r = MilanMath.calculateMilan(5, 20);
      expect(r.varna, 1);
      expect(r.vashya, 2);
      expect(r.tara, 3);
      expect(r.yoni, 2); // Horse-Elephant
      expect(r.maitri, 5);
      expect(r.gana, 6); // Deva boy, Manushya girl
      expect(r.bhakoot, 7);
      expect(r.nadi, 8);
      expect(r.total, 34);
      expect(r.doshas, isEmpty);
    });

    test('Same nakshatra and pada gives an uncancelled Nadi dosha', () {
      final r = MilanMath.calculateMilan(2, 2.5);
      expect(r.nadi, 0);
      final nadi = r.doshas.firstWhere((d) => d.name == 'Nadi Dosha');
      expect(nadi.cancelled, isFalse);
    });

    test('Same Moon sign, different nakshatra cancels Nadi dosha', () {
      // Ashwini (Adi) and Mula share Adi nadi but are in different signs; use Ardra/Punarvasu:
      // Ardra (Gemini 6°40'-20°) and Punarvasu (Gemini 20°-...) are both Adi nadi in Gemini.
      final r = MilanMath.calculateMilan(60 + 10, 60 + 25);
      expect(r.nadi, 0);
      expect(r.doshas.firstWhere((d) => d.name == 'Nadi Dosha').cancelled, isTrue);
    });

    test('6/8 Bhakoot scores 0', () {
      expect(MilanMath.bhakootPoints(0, 5), 0); // Aries-Virgo = 6/8
      expect(MilanMath.bhakootPoints(0, 6), 7); // 1/7
    });
  });

  group('Panchang rules', () {
    test('Tithi numbering', () {
      expect(PanchangMath.tithiNumber(0), 1);
      expect(PanchangMath.tithiNumber(179.9), 15);
      expect(PanchangMath.tithiNumber(180), 16);
      expect(PanchangMath.tithiNumber(359.9), 30);
      expect(PanchangMath.tithiName(15), 'Purnima');
      expect(PanchangMath.tithiName(30), 'Amavasya');
      expect(PanchangMath.tithiName(16), 'Pratipada');
    });

    test('Karana sequence', () {
      expect(PanchangMath.karanaName(0), 'Kimstughna');
      expect(PanchangMath.karanaName(1), 'Bava');
      expect(PanchangMath.karanaName(7), 'Vishti');
      expect(PanchangMath.karanaName(8), 'Bava');
      expect(PanchangMath.karanaName(56), 'Vishti');
      expect(PanchangMath.karanaName(57), 'Shakuni');
      expect(PanchangMath.karanaName(58), 'Chatushpada');
      expect(PanchangMath.karanaName(59), 'Naga');
    });

    test('Rahu Kaal slots by weekday (Sunday = 0)', () {
      expect(PanchangMath.rahuKaalPart, [8, 2, 7, 5, 6, 4, 3]);
      expect(PanchangMath.gulikaPart, [7, 6, 5, 4, 3, 2, 1]);
      expect(PanchangMath.yamagandaPart, [5, 4, 3, 2, 1, 7, 6]);
    });
  });

  group('KP sub-lords', () {
    test('start of zodiac is Ketu/Ketu/Ketu', () {
      expect(KPMath.lordsOf(0.0001), ['ketu', 'ketu', 'ketu']);
    });
    test('start of Bharani is Venus star, Venus sub', () {
      final l = KPMath.lordsOf(13.3334);
      expect(l[0], 'venus');
      expect(l[1], 'venus');
    });
    test('last sub of Ashwini is Mercury', () {
      expect(KPMath.lordsOf(13.33)[1], 'mercury');
    });
  });

  group('Dignity', () {
    test('degree-based Moon and Mercury', () {
      expect(PlanetaryDignity.getAdvancedDignity('moon', 1, {}, degree: 2), 'Exalted');
      expect(PlanetaryDignity.getAdvancedDignity('moon', 1, {}, degree: 10), 'Moolatrikona');
      expect(PlanetaryDignity.getAdvancedDignity('mercury', 5, {}, degree: 10), 'Exalted');
      expect(PlanetaryDignity.getAdvancedDignity('mercury', 5, {}, degree: 17), 'Moolatrikona');
      expect(PlanetaryDignity.getAdvancedDignity('mercury', 5, {}, degree: 25), 'Own Sign');
    });
    test('Moolatrikona only inside its degree range', () {
      expect(PlanetaryDignity.getAdvancedDignity('sun', 4, {}, degree: 10), 'Moolatrikona');
      expect(PlanetaryDignity.getAdvancedDignity('sun', 4, {}, degree: 25), 'Own Sign');
    });
  });

  group('Doshas', () {
    test('Manglik from 7th house, cancelled by own sign', () {
      // Lagna Libra (6); Mars in Aries (house 7) -> Manglik, but Mars in own sign.
      final r = DoshasMath.computeManglik({'mars': 10, 'moon': 100, 'venus': 100}, 6)!;
      expect(r.present, isTrue);
      expect(r.cancelled, isTrue);
    });

    test('Kaal Sarp detection and type by Rahu house', () {
      final longs = {
        'rahu': 10.0, 'ketu': 190.0,
        'sun': 20.0, 'moon': 50.0, 'mars': 80.0, 'mercury': 110.0,
        'jupiter': 140.0, 'venus': 160.0, 'saturn': 185.0,
      };
      final r = DoshasMath.computeKaalSarp(longs, 0)!;
      expect(r.present, isTrue);
      expect(r.conditions.any((c) => c.contains('Anant')), isTrue);
      final broken = Map<String, double>.from(longs)..['saturn'] = 200.0;
      expect(DoshasMath.computeKaalSarp(broken, 0)!.present, isFalse);
    });

    test('Sade Sati phases', () {
      expect(DoshasMath.computeSadesati(5, 4).present, isTrue);
      expect(DoshasMath.computeSadesati(5, 5).present, isTrue);
      expect(DoshasMath.computeSadesati(5, 6).present, isTrue);
      expect(DoshasMath.computeSadesati(5, 7).present, isFalse);
    });
  });

  group('Yogas', () {
    test('Gajakesari and Hamsa', () {
      // Lagna Cancer (3); Jupiter in Cancer (exalted, kendra); Moon in Capricorn (7th from Jupiter).
      final longs = {
        'sun': 45.0, 'moon': 280.0, 'mars': 200.0, 'mercury': 50.0,
        'jupiter': 95.0, 'venus': 70.0, 'saturn': 330.0, 'rahu': 150.0, 'ketu': 330.0,
      };
      final yogas = YogasMath.computeAllYogas(longs, 3);
      final names = yogas.map((y) => y.name).toList();
      expect(names, contains('Gajakesari Yoga'));
      expect(names, contains('Hamsa Yoga'));
    });

    test('No duplicate Kendra-Trikona entries', () {
      final longs = {
        'sun': 5.0, 'moon': 5.0, 'mars': 5.0, 'mercury': 5.0,
        'jupiter': 5.0, 'venus': 5.0, 'saturn': 5.0, 'rahu': 100.0, 'ketu': 280.0,
      };
      final yogas = YogasMath.computeAllYogas(longs, 0);
      final kt = yogas.where((y) => y.name == 'Kendra-Trikona Raja Yoga').map((y) => (y.planets.toList()..sort()).join());
      expect(kt.length, kt.toSet().length);
    });
  });
}
