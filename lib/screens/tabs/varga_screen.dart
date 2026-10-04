import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/ephemeris.dart';
import '../../core/vedic_math.dart';
import '../../widgets/ai_sheet.dart';
import '../../widgets/kundli_chart.dart';
import '../../widgets/analysis_widgets.dart';
import '../../core/l10n.dart';

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
      appBar: AppBar(title: Text(tr('Shodashvarga', 'षोडशवर्ग'))),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: VedicMath.vargaDefs.length + 2,
        itemBuilder: (context, index) => index == 0
            ? Padding(padding: const EdgeInsets.only(bottom: 12), child: SimpleMeaningCard(_plain()))
            : index == 1
                ? const Padding(padding: EdgeInsets.only(bottom: 12), child: ChartLegend())
                : _buildVargaCard(context, ref, VedicMath.vargaDefs[index - 2]),
      ),
    );
  }

  List<String> _plain() => [
        tr('Divisional charts (vargas) zoom into one area of life. Each one re-divides every sign into smaller parts, so the same planet can land in a different sign there.',
            'वर्ग कुंडलियाँ जीवन के किसी एक क्षेत्र को बड़ा करके दिखाती हैं। हर राशि को छोटे भागों में बाँटा जाता है, इसलिए वही ग्रह वहाँ अलग राशि में आ सकता है।'),
        tr('Read the D1 (birth chart) first; a varga only confirms or refines its promise. D9 (marriage, inner strength) and D10 (career) are the most used.',
            'पहले D1 (जन्म कुंडली) देखें; वर्ग कुंडली केवल उसके वादे की पुष्टि या सूक्ष्म जानकारी देती है। D9 (विवाह, आंतरिक बल) और D10 (करियर) सबसे अधिक देखी जाती हैं।'),
        tr('A planet in the same sign in D1 and D9 is "vargottama" (□) and gives steadier results. Exact birth time matters: higher vargas like D60 change every few minutes.',
            'जो ग्रह D1 और D9 में एक ही राशि में हो वह "वर्गोत्तम" (□) कहलाता है और स्थिर फल देता है। जन्म समय सही होना ज़रूरी है: D60 जैसी ऊँची वर्ग कुंडलियाँ कुछ ही मिनटों में बदल जाती हैं।'),
      ];

  Widget _buildVargaCard(BuildContext context, WidgetRef ref, VargaDef def) {
    final int lagnaVargaRashi = VedicMath.vargaRashi(chartData.ascendantSidereal, def.key, def.div);
    final labels = buildHouseLabels(
      chartData.planetLongitudes,
      lagnaVargaRashi,
      speeds: chartData.planetSpeeds,
      signOverride: def.key == 'D1' ? null : _vargaSigns(def),
      showDegrees: def.key == 'D1',
      ascendant: def.key == 'D1' ? chartData.ascendantSidereal : null,
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
                      Text(L10n.hi ? '${def.key} - ${def.hindi}  (${def.name})' : '${def.key} - ${def.name}  ${def.hindi}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text('${def.purposeText} • ${tr('Lagna', 'लग्न')} ${L10n.sign(lagnaVargaRashi)}',
                          style: TextStyle(color: Theme.of(context).colorScheme.secondary, fontSize: 14)),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.auto_awesome, color: Theme.of(context).colorScheme.secondary),
                  onPressed: () => _analyzeWholeVargaChart(context, ref, def, lagnaVargaRashi),
                  tooltip: tr('Analyze Holistic Chart', 'पूरी कुंडली का विश्लेषण'),
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

    showAiSheet(context, ref, title: tr('${def.key} - ${def.name} Analysis', '${def.key} - ${def.hindi} विश्लेषण'), prompt: prompt, profileId: profileId);
  }
}
