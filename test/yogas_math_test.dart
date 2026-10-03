import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_jyotish/core/yogas_math.dart';

/// Builds sidereal longitudes from sign indexes (0 = Aries) at 15° in each sign.
Map<String, double> chart(Map<String, int> signs, {Map<String, double> degrees = const {}}) => {
      for (final e in signs.entries) e.key: e.value * 30 + (degrees[e.key] ?? 15.0),
    };

YogaResult find(List<YogaResult> ys, String name) => ys.firstWhere((y) => y.name == name, orElse: () => throw StateError('no $name'));

void main() {
  // A spread-out base chart with Aries Lagna; tests override the planets they need.
  const base = {
    'sun': 4, 'moon': 9, 'mars': 2, 'mercury': 5, 'jupiter': 7, 'venus': 6, 'saturn': 10, 'rahu': 11, 'ketu': 5,
  };

  test('Hamsa and Gaja Kesari', () {
    final ys = YogasMath.computeAllYogas(chart({...base, 'jupiter': 3, 'moon': 0}), 3); // Cancer Lagna
    final hamsa = find(ys, 'Hamsa Yoga');
    expect(hamsa.formed, isTrue);
    expect(hamsa.rule, contains('Kendra'));
    expect(find(ys, 'Gaja Kesari Yoga').formed, isTrue); // Jupiter 4th from the Moon
    expect(find(ys, 'Ruchaka Yoga').formed, isFalse);
  });

  test('Mahapurusha from the Moon only is reported but not formed', () {
    // Mars exalted in Capricorn, 3rd from an Aquarius... use Lagna Leo (4): Capricorn = 6th house; Moon in Aries -> Capricorn 10th from Moon.
    final ys = YogasMath.computeAllYogas(chart({...base, 'mars': 9, 'moon': 0}), 4);
    final r = find(ys, 'Ruchaka Yoga');
    expect(r.formed, isFalse);
    expect(r.strength, 'From Moon only');
  });

  test('Sunapha, Anapha, Durudhara and Kemadruma are exclusive', () {
    final sunapha = YogasMath.computeAllYogas(chart({...base, 'moon': 0, 'mars': 1, 'mercury': 4, 'jupiter': 4, 'venus': 4, 'saturn': 4}), 0);
    expect(find(sunapha, 'Sunapha Yoga').formed, isTrue);
    expect(find(sunapha, 'Durudhara Yoga').formed, isFalse);
    expect(find(sunapha, 'Kemadruma Yoga').formed, isFalse);

    final kema = YogasMath.computeAllYogas(chart({...base, 'moon': 0, 'mars': 4, 'mercury': 4, 'jupiter': 4, 'venus': 4, 'saturn': 4}), 0);
    final k = find(kema, 'Kemadruma Yoga');
    expect(k.formed, isTrue);
    expect(k.strength, 'Challenging'); // nothing in a Kendra from the Moon
    final kc = YogasMath.computeAllYogas(chart({...base, 'moon': 0, 'mars': 3, 'mercury': 4, 'jupiter': 4, 'venus': 4, 'saturn': 4}), 0);
    expect(find(kc, 'Kemadruma Yoga').strength, 'Cancelled'); // Mars in the 4th from the Moon
  });

  test('Sun yogas exclude the Moon', () {
    final ys = YogasMath.computeAllYogas(chart({...base, 'sun': 4, 'moon': 5, 'venus': 3, 'mercury': 4}), 0);
    expect(find(ys, 'Vasi Yoga').formed, isTrue); // Venus 12th from the Sun, only the Moon in the 2nd
    expect(find(ys, 'Vesi Yoga').formed, isFalse);
    expect(find(ys, 'Budha-Aditya Yoga').formed, isTrue);
  });

  test('Kendra-Trikona Raja Yoga, Yogakaraka and Dharma-Karmadhipati', () {
    // Taurus Lagna: Saturn rules the 9th and 10th -> Yogakaraka and Dharma-Karmadhipati.
    final ys = YogasMath.computeAllYogas(chart(base), 1);
    expect(find(ys, 'Yogakaraka Saturn').formed, isTrue);
    expect(find(ys, 'Dharma-Karmadhipati Yoga').formed, isTrue);
    // Aries Lagna: Sun (5th lord) conjunct Moon (4th lord).
    final kt = YogasMath.computeAllYogas(chart({...base, 'sun': 4, 'moon': 4}), 0);
    expect(kt.where((y) => y.name == 'Kendra-Trikona Raja Yoga' && y.formed && y.planets.toSet().containsAll({'sun', 'moon'})), isNotEmpty);
  });

  test('Parivartana types', () {
    // Aries Lagna: Mars in Taurus (2nd), Venus in Aries (1st) -> Maha.
    final ys = YogasMath.computeAllYogas(chart({...base, 'mars': 1, 'venus': 0}), 0);
    expect(ys.any((y) => y.name == 'Maha Parivartana Yoga' && y.formed), isTrue);
    // Mars in Virgo (6th) and Mercury in Aries -> Dainya.
    final d = YogasMath.computeAllYogas(chart({...base, 'mars': 5, 'mercury': 0}), 0);
    expect(d.any((y) => y.name == 'Dainya Parivartana Yoga' && y.formed), isTrue);
  });

  test('Neecha Bhanga when the dispositor is in a Kendra', () {
    // Sun debilitated in Libra; Venus (lord of Libra) in Cancer, a Kendra from an Aries Lagna.
    final ys = YogasMath.computeAllYogas(chart({...base, 'sun': 6, 'venus': 3, 'saturn': 1, 'mercury': 5}), 0);
    final nb = ys.firstWhere((y) => y.category == YogaFamilies.neecha && y.planets.contains('sun'));
    expect(nb.formed, isTrue);
    expect(nb.reasons.join(' '), contains('Venus is in a Kendra'));
  });

  test('Viparita Raja Yoga', () {
    // Aries Lagna: 6th lord Mercury in Scorpio (8th) -> Harsha.
    final ys = YogasMath.computeAllYogas(chart({...base, 'mercury': 7}), 0);
    expect(find(ys, 'Harsha Yoga').formed, isTrue);
    expect(find(ys, 'Harsha Yoga').rule, contains('dusthana'));
  });

  group('Nabhasa', () {
    test('Gola: all seven planets in one sign', () {
      final ys = YogasMath.computeAllYogas(
          chart({'sun': 0, 'moon': 0, 'mars': 0, 'mercury': 0, 'jupiter': 0, 'venus': 0, 'saturn': 0}), 0);
      expect(find(ys, 'Gola Yoga').formed, isTrue);
      expect(find(ys, 'Rajju Yoga').formed, isTrue); // Aries is movable
      expect(ys.where((y) => y.category == YogaFamilies.nabhasaSankhya && y.formed).length, 1);
      expect(find(ys, 'Pravrajya Yoga').formed, isTrue);
    });

    test('Kamala: all four Kendras occupied', () {
      final ys = YogasMath.computeAllYogas(
          chart({'sun': 0, 'moon': 3, 'mars': 6, 'mercury': 9, 'jupiter': 0, 'venus': 3, 'saturn': 6}), 0);
      expect(find(ys, 'Kamala (Padma) Yoga').formed, isTrue);
      expect(find(ys, 'Chatussagara Yoga').formed, isTrue);
      expect(find(ys, 'Kedara Yoga').formed, isTrue);
      expect(find(ys, 'Kedara Yoga').strength, 'Secondary');
    });

    test('Chakra and Nauka', () {
      final chakra = YogasMath.computeAllYogas(
          chart({'sun': 0, 'moon': 2, 'mars': 4, 'mercury': 6, 'jupiter': 8, 'venus': 10, 'saturn': 0}), 0);
      expect(find(chakra, 'Chakra Yoga').formed, isTrue);
      final nauka = YogasMath.computeAllYogas(
          chart({'sun': 0, 'moon': 1, 'mars': 2, 'mercury': 3, 'jupiter': 4, 'venus': 5, 'saturn': 6}), 0);
      expect(find(nauka, 'Nauka Yoga').formed, isTrue);
      expect(find(nauka, 'Veena (Vallaki) Yoga').formed, isTrue);
    });

    test('Mala and Sarpa', () {
      final mala = YogasMath.computeAllYogas(
          chart({'jupiter': 0, 'venus': 3, 'mercury': 6, 'sun': 1, 'mars': 2, 'saturn': 4, 'moon': 5}), 0);
      expect(find(mala, 'Mala (Srik) Yoga').formed, isTrue);
      final sarpa = YogasMath.computeAllYogas(
          chart({'sun': 0, 'mars': 3, 'saturn': 6, 'jupiter': 1, 'venus': 2, 'mercury': 4, 'moon': 5}), 0);
      expect(find(sarpa, 'Sarpa Yoga').formed, isTrue);
      expect(find(sarpa, 'Sarpa Yoga').nature, YogaNature.adverse);
    });
  });

  test('Mahabhagya depends on day birth and gender', () {
    // Aries Lagna (asc 10°), Sun in Aquarius (above the horizon: day birth), Moon in Gemini. All odd signs.
    final longs = chart({...base, 'sun': 10, 'moon': 2});
    final male = YogasMath.computeAllYogas(longs, 0, ascendant: 10, gender: 'Male');
    expect(find(male, 'Mahabhagya Yoga').formed, isTrue);
    final female = YogasMath.computeAllYogas(longs, 0, ascendant: 10, gender: 'Female');
    expect(find(female, 'Mahabhagya Yoga').formed, isFalse);
  });

  test('yogas of the running Dasha lords are marked active', () {
    final ys = YogasMath.computeAllYogas(chart({...base, 'jupiter': 3, 'moon': 0}), 3, dashaLords: ['jupiter']);
    expect(find(ys, 'Hamsa Yoga').active, isTrue);
    expect(ys.where((y) => !y.formed && y.active), isEmpty);
  });

  test('every family is checked and every yoga states its rule and source', () {
    final ys = YogasMath.computeAllYogas(chart(base), 0, ascendant: 15);
    for (final f in YogaFamilies.order) {
      expect(ys.where((y) => y.category == f), isNotEmpty, reason: f);
    }
    for (final y in ys) {
      expect(y.rule, isNotEmpty, reason: y.name);
      expect(y.source, isNotEmpty, reason: y.name);
    }
    // All 32 Nabhasa yogas are evaluated.
    expect(ys.where((y) => y.category.startsWith('Nabhasa')).length, 32);
  });
}
