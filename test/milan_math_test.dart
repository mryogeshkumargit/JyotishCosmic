import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_jyotish/core/milan_math.dart';

/// Sidereal longitude at the middle of nakshatra [n] (0 = Ashwini).
double nak(int n) => n * 360 / 27 + 360 / 54;

void main() {
  test('identical Moon gives 28 points (Nadi dosha)', () {
    final r = MilanMath.calculateMilan(nak(0), nak(0));
    expect(r.varna, 1);
    expect(r.vashya, 2);
    expect(r.tara, 3);
    expect(r.yoni, 4);
    expect(r.maitri, 5);
    expect(r.gana, 6);
    expect(r.bhakoot, 7);
    expect(r.nadi, 0);
    expect(r.total, 28);
    expect(r.hasNadiDosha, isTrue);
  });

  test('Nadi follows the nakshatra table (Ashwini and Hasta are both Adi)', () {
    expect(MilanMath.nadiScore(0, 12), 0);
    expect(MilanMath.nadiScore(0, 1), 8); // Adi vs Madhya
    expect(MilanMath.nadiScore(17, 23), 0); // Jyeshtha & Shatabhisha: Adi
  });

  test('Gana uses the correct groups (Krittika is Rakshasa)', () {
    expect(MilanMath.ganaOf(2), 2);
    expect(MilanMath.ganaOf(25), 1); // Uttara Bhadrapada: Manushya
    expect(MilanMath.ganaScore(2, 3), 0); // boy Rakshasa, girl Manushya
    expect(MilanMath.ganaScore(0, 3), 6); // boy Deva, girl Manushya
  });

  test('Yoni uses the 14-animal table', () {
    expect(MilanMath.yoniOfNakshatra.length, 27);
    expect(MilanMath.yoniScore(0, 12), 0); // Horse vs Buffalo: sworn enemies
    expect(MilanMath.yoniScore(0, 23), 4); // Ashwini & Shatabhisha: both Horse
    expect(MilanMath.yoniScore(9, 6), 0); // Rat vs Cat
  });

  test('Graha Maitri 5-level scoring', () {
    expect(MilanMath.maitriScore(0, 2), 0.5); // Mars->Mercury enemy, Mercury->Mars neutral
    expect(MilanMath.maitriScore(0, 4), 5); // Mars & Sun mutual friends
    expect(MilanMath.maitriScore(4, 9), 0); // Sun & Saturn mutual enemies
    expect(MilanMath.maitriScore(1, 0), 3); // Venus->Mars neutral, Mars->Venus neutral
  });

  test('Vashya splits Sagittarius and Capricorn', () {
    expect(MilanMath.vashyaGroup(245), 1); // Sagittarius 5°: Manava
    expect(MilanMath.vashyaGroup(260), 0); // Sagittarius 20°: Chatushpada
    expect(MilanMath.vashyaGroup(290), 2); // Capricorn 20°: Jalachara
    expect(MilanMath.vashyaScore(3, 1), 0); // Vanachara boy, Manava girl
  });

  test('Bhakoot 6/8 is inauspicious', () {
    expect(MilanMath.bhakootScore(0, 5), 0);
    expect(MilanMath.bhakootScore(0, 6), 7);
  });
}
