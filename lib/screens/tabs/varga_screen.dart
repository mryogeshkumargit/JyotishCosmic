import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/ephemeris.dart';
import '../../core/vedic_math.dart';
import '../../widgets/ai_sheet.dart';
import '../../widgets/kundli_chart.dart';

class VargaScreen extends ConsumerWidget {
  final ChartData chartData;
  final int? profileId;

  const VargaScreen({super.key, required this.chartData, this.profileId});

  static const Map<String, String> _vargaKarakas = {
    'D2': 'Jupiter (Wealth)',
    'D3': 'Mars (Siblings)',
    'D4': 'Moon (Property)',
    'D7': 'Jupiter (Children)',
    'D9': 'Venus (Marriage)',
    'D10': 'Mercury, Jupiter, Sun (Career)',
    'D12': 'Sun (Father), Moon (Mother)',
    'D16': 'Venus (Vehicles/Luxury)',
    'D20': 'Jupiter (Spirituality)',
    'D24': 'Mercury (Education)',
    'D27': 'Mars (Strength)',
    'D30': 'Saturn (Misfortunes)',
  };

  /// Varga sign (0-based) of every planet.
  Map<String, int> _vargaSigns(VargaDef def) => {
        for (final e in chartData.planetLongitudes.entries) e.key: VedicMath.vargaRashi(e.value, def.key, def.div)
      };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Shodashvarga')),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: VedicMath.vargaDefs.length,
        itemBuilder: (context, index) => _buildVargaCard(context, ref, VedicMath.vargaDefs[index]),
      ),
    );
  }

  Widget _buildVargaCard(BuildContext context, WidgetRef ref, VargaDef def) {
    final int lagnaVargaRashi = VedicMath.vargaRashi(chartData.ascendantSidereal, def.key, def.div);
    final labels = buildHouseLabels(
      chartData.planetLongitudes,
      lagnaVargaRashi,
      speeds: chartData.planetSpeeds,
      signOverride: _vargaSigns(def),
      showDegrees: def.key == 'D1',
    );

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${def.key} - ${def.name}  ${def.hindi}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text('${def.purpose} • Lagna ${VedicMath.rashis[lagnaVargaRashi].name}',
                          style: TextStyle(color: Theme.of(context).colorScheme.secondary, fontSize: 14)),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.auto_awesome, color: Theme.of(context).colorScheme.secondary),
                  onPressed: () => _analyzeWholeVargaChart(context, ref, def, lagnaVargaRashi),
                  tooltip: 'Analyze Holistic Chart',
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 300,
              child: KundliChart(housePlanets: labels, ascendantSign: lagnaVargaRashi + 1, onHouseTapped: (_) {}),
            ),
          ],
        ),
      ),
    );
  }

  void _analyzeWholeVargaChart(BuildContext context, WidgetRef ref, VargaDef def, int vargaLagna) {
    final vargaSigns = _vargaSigns(def);
    final int d1Lagna = chartData.lagnaRashi;
    final String d1LagnaLord = VedicMath.rashis[d1Lagna].lord;
    final String vargaLagnaLord = VedicMath.rashis[vargaLagna].lord;

    String houseIn(String planet, int lagna, Map<String, int> signs) =>
        signs.containsKey(planet) ? '${VedicMath.houseOf(signs[planet]!, lagna)}' : 'Unknown';

    final d1Signs = {for (final e in chartData.planetLongitudes.entries) e.key: VedicMath.rashiIndex(e.value)};

    final vargottama = [
      for (final p in Ephemeris.planetOrder)
        if (d1Signs[p] != null && d1Signs[p] == vargaSigns[p]) VedicMath.planets[p]!.name
    ];

    final placements = <String>[];
    for (int h = 1; h <= 12; h++) {
      final sign = (vargaLagna + h - 1) % 12;
      final occupants = [
        for (final p in Ephemeris.planetOrder)
          if (vargaSigns[p] == sign) VedicMath.planets[p]!.name
      ];
      if (occupants.isNotEmpty) placements.add('- House $h (${VedicMath.rashis[sign].name}): ${occupants.join(', ')}');
    }

    final karaka = _vargaKarakas[def.key];
    final prompt = '''
Perform a holistic Vedic astrological analysis of the ${def.name} (${def.key}) chart.
This divisional chart is analyzed for: "${def.purpose}".

**1. D1 (Rasi Chart) Foundation:**
- D1 Ascendant: ${VedicMath.rashis[d1Lagna].name}
- D1 Lagna Lord: ${VedicMath.planets[d1LagnaLord]!.name} in house ${houseIn(d1LagnaLord, d1Lagna, d1Signs)} of D1.

**2. ${def.name} Chart Details:**
- Varga Ascendant: ${VedicMath.rashis[vargaLagna].name}
- Varga Lagna Lord: ${VedicMath.planets[vargaLagnaLord]!.name} in house ${houseIn(vargaLagnaLord, vargaLagna, vargaSigns)} of this Varga.
- D1 Lagna Lord in this Varga: house ${houseIn(d1LagnaLord, vargaLagna, vargaSigns)}.
- Planets in the same sign in D1 and ${def.key}: ${vargottama.isEmpty ? 'None' : vargottama.join(', ')}.${karaka != null ? '\n- Primary Karaka(s): $karaka' : ''}

**3. Planetary Placements in ${def.name}:**
${placements.join('\n')}

Provide a comprehensive reading of how these placements affect the native's "${def.purpose}". Focus on the interaction between the D1 Lagna Lord and the Varga Lagna Lord, planets holding the same sign in D1 and this Varga, the Karaka's position if applicable, and the Varga Ascendant. Do not provide a general life reading.
''';

    showAiSheet(context, ref, title: '${def.key} - ${def.name} Analysis', prompt: prompt, profileId: profileId);
  }
}
