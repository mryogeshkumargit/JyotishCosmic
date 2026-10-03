import 'ephemeris.dart';
import 'jaimini_math.dart';
import 'planetary_dignity.dart';
import 'vedic_math.dart';
import 'yogas_math.dart';
import 'shadbala_math.dart';

/// Human-readable chart description used as context for AI prompts.
class ChartSummary {
  static String planetLine(ChartData chart, String planet) {
    final sid = chart.planetLongitudes[planet]!;
    final r = VedicMath.rashiIndex(sid);
    final house = VedicMath.houseOf(r, chart.lagnaRashi);
    final nak = VedicMath.nakshatras[VedicMath.nakshatraIndex(sid)];
    final rashis = {for (final e in chart.planetLongitudes.entries) e.key: VedicMath.rashiIndex(e.value)};
    final dignity = PlanetaryDignity.getAdvancedDignity(planet, r, rashis, degree: VedicMath.degInRashi(sid));
    final retro = chart.isRetrograde(planet) ? ', retrograde' : '';
    return '${VedicMath.planets[planet]!.name}: ${VedicMath.rashis[r].name} ${VedicMath.formatDegree(sid)}, '
        'house $house, ${nak.name} pada ${VedicMath.pada(sid)}, $dignity$retro';
  }

  static String describe(ChartData chart, {String? name}) {
    final asc = chart.ascendantSidereal;
    final ascNak = VedicMath.nakshatras[VedicMath.nakshatraIndex(asc)];
    final buf = StringBuffer();
    if (name != null) buf.writeln('Native: $name');
    buf.writeln('Sidereal zodiac, ${Ephemeris.ayanamsaLabel.split(';').first} ayanamsa ${chart.ayanamsa.toStringAsFixed(4)}°, ${Ephemeris.nodeModel.toLowerCase()}, whole-sign houses.');
    buf.writeln('Ascendant (Lagna): ${VedicMath.rashis[chart.lagnaRashi].name} ${VedicMath.formatDegree(asc)}, '
        '${ascNak.name} pada ${VedicMath.pada(asc)}');
    for (final p in Ephemeris.planetOrder) {
      if (chart.planetLongitudes.containsKey(p)) buf.writeln(planetLine(chart, p));
    }
    final moon = chart.planetLongitudes['moon'];
    if (moon != null) {
      final dashas = DashaCalculations.compute(chart.jd, moon, utcOffset: chart.utcOffset);
      final running = dashas.runningAt(Ephemeris.nowJd());
      if (running.isNotEmpty) {
        final names = running.map((d) => VedicMath.planets[d.lord]!.name).join(' / ');
        buf.writeln('Current Vimshottari dasha (Maha / Antar / Pratyantar): $names '
            '(Mahadasha ${running.first.startDate} to ${running.first.endDate})');
      }
    }
    try {
      final sb = ShadbalaMath.compute(chart);
      buf.writeln('Shadbala (rupas, ratio to BPHS minimum): ${sb.ranked.map((s) => '${s.name} ${s.rupas.toStringAsFixed(2)} (${s.ratio.toStringAsFixed(2)}x)').join(', ')}');
    } catch (_) {}
    try {
      final j = JaiminiMath.compute(chart);
      String n(String p) => VedicMath.planets[p]!.name;
      buf.writeln('Jaimini (8 Chara Karakas): ${j.karakas.map((k) => '${k.code} ${n(k.planet)}').join(', ')}; '
          'Arudha Lagna ${VedicMath.rashis[j.arudhaLagna.rashi].name}, Upapada ${VedicMath.rashis[j.upapada.rashi].name}, Karakamsa ${VedicMath.rashis[j.karakamsa].name}');
    } catch (_) {}
    final yogas = YogasMath.forChart(chart).where((y) => y.formed && y.strength != 'Secondary').toList();
    if (yogas.isNotEmpty) {
      buf.writeln('Classical yogas (calculated): ${yogas.map((y) => '${y.name} (${y.strength}${y.active ? ', active in current dasha' : ''})').join('; ')}');
    }
    return buf.toString().trim();
  }

  /// Describes a single house for house-level AI analysis.
  static String describeHouse(ChartData chart, int house) {
    final sign = (chart.lagnaRashi + house - 1) % 12;
    final lord = VedicMath.rashis[sign].lord;
    final occupants = chart.planetLongitudes.keys
        .where((p) => VedicMath.houseOf(VedicMath.rashiIndex(chart.planetLongitudes[p]!), chart.lagnaRashi) == house)
        .map((p) => planetLine(chart, p))
        .toList();
    final lordLine = chart.planetLongitudes.containsKey(lord) ? planetLine(chart, lord) : lord;
    return 'House $house sign: ${VedicMath.rashis[sign].name}\n'
        'House lord: $lordLine\n'
        'Occupants: ${occupants.isEmpty ? 'none' : '\n${occupants.join('\n')}'}';
  }
}
