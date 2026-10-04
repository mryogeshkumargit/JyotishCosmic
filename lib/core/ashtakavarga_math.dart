import 'ephemeris.dart';
import 'l10n.dart';
import 'vedic_math.dart';

/// Bhinnashtakavarga of one planet: bindus in each sign (0 = Aries).
class Bhinnashtakavarga {
  final String planet;
  final List<int> bindus;

  /// Contributions: contributor -> signs where it gave a bindu.
  final Map<String, List<int>> contributions;
  const Bhinnashtakavarga(this.planet, this.bindus, this.contributions);
  int get total => bindus.fold(0, (s, b) => s + b);
}

/// Shodhya Pinda of one planet (after Trikona and Ekadhipatya Shodhana).
class ShodhyaPinda {
  final String planet;
  final List<int> afterTrikona;
  final List<int> afterEkadhipatya;
  final int rashiPinda;
  final int grahaPinda;
  const ShodhyaPinda(this.planet, this.afterTrikona, this.afterEkadhipatya, this.rashiPinda, this.grahaPinda);
  int get total => rashiPinda + grahaPinda;
}

class AshtakavargaResult {
  final Map<String, Bhinnashtakavarga> bhinna;
  final List<int> sarva;
  final Map<String, ShodhyaPinda> pinda;
  final int lagnaRashi;
  const AshtakavargaResult(this.bhinna, this.sarva, this.pinda, this.lagnaRashi);

  int get sarvaTotal => sarva.fold(0, (s, b) => s + b);

  /// Sarvashtakavarga bindus of the [house]th house from the Lagna.
  int sarvaInHouse(int house) => sarva[(lagnaRashi + house - 1) % 12];

  /// Bindus of [planet]'s own Bhinnashtakavarga in [rashi] (for transits).
  int bindusFor(String planet, int rashi) => bhinna[planet]?.bindus[rashi] ?? 0;
}

/// Ashtakavarga (BPHS Ashtakavarga chapters).
///
/// The benefic-place tables are the standard Parashari ones: each of the
/// seven planets and the Lagna contributes a bindu to a planet's chart from
/// the listed houses counted from itself. The totals are fixed: Sun 48,
/// Moon 49, Mars 39, Mercury 54, Jupiter 56, Venus 52, Saturn 39 (SAV 337).
class AshtakavargaMath {
  static const List<String> planets = ['sun', 'moon', 'mars', 'mercury', 'jupiter', 'venus', 'saturn'];
  static const List<String> contributors = ['sun', 'moon', 'mars', 'mercury', 'jupiter', 'venus', 'saturn', 'lagna'];

  static const Map<String, Map<String, List<int>>> table = {
    'sun': {
      'sun': [1, 2, 4, 7, 8, 9, 10, 11], 'moon': [3, 6, 10, 11], 'mars': [1, 2, 4, 7, 8, 9, 10, 11],
      'mercury': [3, 5, 6, 9, 10, 11, 12], 'jupiter': [5, 6, 9, 11], 'venus': [6, 7, 12],
      'saturn': [1, 2, 4, 7, 8, 9, 10, 11], 'lagna': [3, 4, 6, 10, 11, 12],
    },
    'moon': {
      'sun': [3, 6, 7, 8, 10, 11], 'moon': [1, 3, 6, 7, 10, 11], 'mars': [2, 3, 5, 6, 9, 10, 11],
      'mercury': [1, 3, 4, 5, 7, 8, 10, 11], 'jupiter': [1, 4, 7, 8, 10, 11, 12], 'venus': [3, 4, 5, 7, 9, 10, 11],
      'saturn': [3, 5, 6, 11], 'lagna': [3, 6, 10, 11],
    },
    'mars': {
      'sun': [3, 5, 6, 10, 11], 'moon': [3, 6, 11], 'mars': [1, 2, 4, 7, 8, 10, 11],
      'mercury': [3, 5, 6, 11], 'jupiter': [6, 10, 11, 12], 'venus': [6, 8, 11, 12],
      'saturn': [1, 4, 7, 8, 9, 10, 11], 'lagna': [1, 3, 6, 10, 11],
    },
    'mercury': {
      'sun': [5, 6, 9, 11, 12], 'moon': [2, 4, 6, 8, 10, 11], 'mars': [1, 2, 4, 7, 8, 9, 10, 11],
      'mercury': [1, 3, 5, 6, 9, 10, 11, 12], 'jupiter': [6, 8, 11, 12], 'venus': [1, 2, 3, 4, 5, 8, 9, 11],
      'saturn': [1, 2, 4, 7, 8, 9, 10, 11], 'lagna': [1, 2, 4, 6, 8, 10, 11],
    },
    'jupiter': {
      'sun': [1, 2, 3, 4, 7, 8, 9, 10, 11], 'moon': [2, 5, 7, 9, 11], 'mars': [1, 2, 4, 7, 8, 10, 11],
      'mercury': [1, 2, 4, 5, 6, 9, 10, 11], 'jupiter': [1, 2, 3, 4, 7, 8, 10, 11], 'venus': [2, 5, 6, 9, 10, 11],
      'saturn': [3, 5, 6, 12], 'lagna': [1, 2, 4, 5, 6, 7, 9, 10, 11],
    },
    'venus': {
      'sun': [8, 11, 12], 'moon': [1, 2, 3, 4, 5, 8, 9, 11, 12], 'mars': [3, 5, 6, 9, 11, 12],
      'mercury': [3, 5, 6, 9, 11], 'jupiter': [5, 8, 9, 10, 11], 'venus': [1, 2, 3, 4, 5, 8, 9, 10, 11],
      'saturn': [3, 4, 5, 8, 9, 10, 11], 'lagna': [1, 2, 3, 4, 5, 8, 9, 11],
    },
    'saturn': {
      'sun': [1, 2, 4, 7, 8, 10, 11], 'moon': [3, 6, 11], 'mars': [3, 5, 6, 10, 11, 12],
      'mercury': [6, 8, 9, 10, 11, 12], 'jupiter': [5, 6, 11, 12], 'venus': [6, 11, 12],
      'saturn': [3, 5, 6, 11], 'lagna': [1, 3, 4, 6, 10, 11],
    },
  };

  static const Map<String, int> expectedTotals = {
    'sun': 48, 'moon': 49, 'mars': 39, 'mercury': 54, 'jupiter': 56, 'venus': 52, 'saturn': 39,
  };

  /// Rashi multipliers (Aries..Pisces) and Graha multipliers for Shodhya Pinda.
  static const List<int> rashiGunakara = [7, 10, 8, 4, 10, 5, 7, 8, 9, 5, 11, 12];
  static const Map<String, int> grahaGunakara = {
    'sun': 5, 'moon': 5, 'mars': 8, 'mercury': 5, 'jupiter': 10, 'venus': 7, 'saturn': 5,
  };

  static AshtakavargaResult compute(ChartData c) {
    final positions = <String, int>{
      for (final p in planets) p: VedicMath.rashiIndex(c.planetLongitudes[p]!),
      'lagna': c.lagnaRashi,
    };
    final bhinna = <String, Bhinnashtakavarga>{};
    for (final p in planets) {
      final bindus = List.filled(12, 0);
      final contrib = <String, List<int>>{};
      for (final k in contributors) {
        final from = positions[k]!;
        final signs = [for (final h in table[p]![k]!) (from + h - 1) % 12];
        contrib[k] = signs;
        for (final s in signs) {
          bindus[s]++;
        }
      }
      bhinna[p] = Bhinnashtakavarga(p, bindus, contrib);
    }
    final sarva = List.generate(12, (i) => planets.fold(0, (s, p) => s + bhinna[p]!.bindus[i]));
    final occupied = <int>{for (final p in planets) positions[p]!, ...['rahu', 'ketu'].where(c.planetLongitudes.containsKey).map((n) => VedicMath.rashiIndex(c.planetLongitudes[n]!))};
    final pinda = {
      for (final p in planets) p: shodhyaPinda(p, bhinna[p]!.bindus, occupied, {for (final q in planets) q: positions[q]!}),
    };
    return AshtakavargaResult(bhinna, sarva, pinda, c.lagnaRashi);
  }

  /// Trikona Shodhana: in each trine of signs, subtract the smallest count;
  /// if all three are equal they become zero; nothing changes if one is zero.
  static List<int> trikonaShodhana(List<int> bindus) {
    final out = List.of(bindus);
    for (int start = 0; start < 4; start++) {
      final idx = [start, start + 4, start + 8];
      final vals = idx.map((i) => out[i]).toList();
      if (vals.contains(0)) continue;
      final m = vals.reduce((a, b) => a < b ? a : b);
      for (final i in idx) {
        out[i] -= m;
      }
    }
    return out;
  }

  /// Ekadhipatya Shodhana for the five planets owning two signs.
  static List<int> ekadhipatyaShodhana(List<int> bindus, Set<int> occupied) {
    final out = List.of(bindus);
    const pairs = [(0, 7), (1, 6), (2, 5), (8, 11), (9, 10)]; // Mars, Venus, Mercury, Jupiter, Saturn
    for (final (a, b) in pairs) {
      final va = out[a], vb = out[b];
      if (va == 0 || vb == 0) continue;
      final oa = occupied.contains(a), ob = occupied.contains(b);
      if (oa && ob) continue;
      if (!oa && !ob) {
        if (va == vb) {
          out[a] = 0;
          out[b] = 0;
        } else {
          final m = va < vb ? va : vb;
          out[a] = m;
          out[b] = m;
        }
        continue;
      }
      // One sign occupied, the other empty.
      final (occ, empty) = oa ? (a, b) : (b, a);
      if (out[occ] > out[empty]) {
        out[empty] = 0;
      } else if (out[occ] < out[empty]) {
        out[empty] -= out[occ];
      } else {
        out[empty] = 0;
      }
    }
    return out;
  }

  static ShodhyaPinda shodhyaPinda(String planet, List<int> bindus, Set<int> occupied, Map<String, int> positions) {
    final t = trikonaShodhana(bindus);
    final e = ekadhipatyaShodhana(t, occupied);
    int rashiPinda = 0;
    for (int i = 0; i < 12; i++) {
      rashiPinda += e[i] * rashiGunakara[i];
    }
    int grahaPinda = 0;
    for (final q in planets) {
      grahaPinda += e[positions[q]!] * grahaGunakara[q]!;
    }
    return ShodhyaPinda(planet, t, e, rashiPinda, grahaPinda);
  }

  /// Transit support of [planet] moving through [rashi]: 4+ bindus in its own
  /// Bhinnashtakavarga is favourable, fewer is weak.
  static String transitSupport(AshtakavargaResult av, String planet, int rashi) {
    if (!av.bhinna.containsKey(planet)) return 'n/a';
    final b = av.bindusFor(planet, rashi);
    final s = av.sarva[rashi];
    final q = b >= 5 ? tr('strong', 'प्रबल') : (b == 4 ? tr('average', 'औसत') : tr('weak', 'कमज़ोर'));
    return tr('$b bindus in its own Ashtakavarga ($q); Sarvashtakavarga $s${s >= 28 ? ' (above average)' : ' (below 28)'}',
        'अपने अष्टकवर्ग में $b बिंदु ($q); सर्वाष्टकवर्ग $s${s >= 28 ? ' (औसत से अधिक)' : ' (28 से कम)'}');
  }
}
