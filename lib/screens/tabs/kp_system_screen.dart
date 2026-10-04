import 'package:flutter/material.dart';
import '../../core/ephemeris.dart';
import '../../core/kp_math.dart';
import '../../core/vedic_math.dart';
import '../../core/l10n.dart';
import '../../core/plain/meanings.dart';
import '../../widgets/analysis_widgets.dart';

class KPSystemScreen extends StatefulWidget {
  final ChartData chartData;

  const KPSystemScreen({super.key, required this.chartData});

  @override
  State<KPSystemScreen> createState() => _KPSystemScreenState();
}

class _KPSystemScreenState extends State<KPSystemScreen> {
  late Map<String, KPPlanetData> kpPlanets;
  late List<KPCuspData> kpCusps;
  late double kpAyanamsa;

  @override
  void initState() {
    super.initState();
    kpPlanets = KPMath.computeKPPlanets(widget.chartData);
    kpCusps = KPMath.computeKPCusps(widget.chartData.jd, widget.chartData.lat, widget.chartData.lon);
    kpAyanamsa = Ephemeris.ayanamsaValue(widget.chartData.jd, Ayanamsa.krishnamurti);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(tr('KP System', 'केपी पद्धति'))),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('${tr('Krishnamurti ayanamsa', 'कृष्णमूर्ति अयनांश')}: ${kpAyanamsa.toStringAsFixed(4)}°', style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 12),
            SimpleMeaningCard([
              tr('The KP (Krishnamurti Paddhati) system divides each nakshatra into unequal parts ruled by the Vimshottari lords. For every planet and house cusp, the star lord shows the source or nature of results, and the sub lord decides whether the matter succeeds.',
                  'केपी (कृष्णमूर्ति पद्धति) हर नक्षत्र को विंशोत्तरी स्वामियों के असमान भागों में बाँटती है। हर ग्रह और भाव संधि के लिए नक्षत्र स्वामी फल का स्रोत या प्रकृति बताता है और उप-स्वामी तय करता है कि मामला सफल होगा या नहीं।'),
            ]),
            Text(tr('Planetary Details', 'ग्रह विवरण'), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            DefaultTextStyle.merge(style: const TextStyle(fontSize: 13), child: _buildPlanetTable()),
            const SizedBox(height: 24),
            Text(tr('Placidus House Cusps', 'प्लेसिडस भाव संधियाँ'), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            DefaultTextStyle.merge(style: const TextStyle(fontSize: 13), child: _buildCuspTable()),
            const SizedBox(height: 24),
            Text(tr('KP Interpretations (Sub-Lords)', 'केपी फलादेश (उप-स्वामी)'), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            _buildInterpretations(),
          ],
        ),
      ),
    );
  }


  Widget _buildPlanetTable() {
    return Table(
      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
      border: TableBorder.all(color: Colors.grey.withValues(alpha: 0.3)),
      columnWidths: const {
        0: FlexColumnWidth(2.2),
        1: FlexColumnWidth(2.4),
        2: FlexColumnWidth(2),
        3: FlexColumnWidth(2),
      },
      children: [
        TableRow(
          decoration: const BoxDecoration(color: Colors.black12),
          children: [
            for (final h in [tr('Planet', 'ग्रह'), tr('Sign', 'राशि'), tr('Star Lord', 'नक्षत्र स्वामी'), tr('Sub Lord', 'उप-स्वामी')])
              Padding(padding: const EdgeInsets.all(6.0), child: Text(h, style: const TextStyle(fontWeight: FontWeight.bold))),
          ],
        ),
        ...Ephemeris.planetOrder.where(kpPlanets.containsKey).map((p) {
                    var data = kpPlanets[p]!;
          return TableRow(
            children: [
              Padding(padding: const EdgeInsets.all(6.0), child: Text(L10n.planet(p))),
              Padding(padding: const EdgeInsets.all(6.0), child: Text('${L10n.signShort(VedicMath.rashiIndex(data.longitude))} ${VedicMath.formatDegree(data.longitude)}')),
              Padding(padding: const EdgeInsets.all(6.0), child: Text(L10n.planet(data.nakshatraLord))),
              Padding(padding: const EdgeInsets.all(6.0), child: Text(L10n.planet(data.subLord))),
            ],
          );
        }),
      ],
    );
  }

  Widget _buildCuspTable() {
    return Table(
      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
      border: TableBorder.all(color: Colors.grey.withValues(alpha: 0.3)),
      columnWidths: const {
        0: FlexColumnWidth(1.2),
        1: FlexColumnWidth(2.4),
        2: FlexColumnWidth(2),
        3: FlexColumnWidth(2),
      },
      children: [
        TableRow(
          decoration: const BoxDecoration(color: Colors.black12),
          children: [
            for (final h in ['#', tr('Sign', 'राशि'), tr('Star Lord', 'नक्षत्र स्वामी'), tr('Sub Lord', 'उप-स्वामी')])
              Padding(padding: const EdgeInsets.all(6.0), child: Text(h, style: const TextStyle(fontWeight: FontWeight.bold))),
          ],
        ),
        ...kpCusps.map((c) {
          return TableRow(
            children: [
              Padding(padding: const EdgeInsets.all(6.0), child: Text(c.cuspNumber.toString())),
              Padding(padding: const EdgeInsets.all(6.0), child: Text('${L10n.signShort(VedicMath.rashiIndex(c.longitude))} ${VedicMath.formatDegree(c.longitude)}')),
              Padding(padding: const EdgeInsets.all(6.0), child: Text(L10n.planet(c.nakshatraLord))),
              Padding(padding: const EdgeInsets.all(6.0), child: Text(L10n.planet(c.subLord))),
            ],
          );
        }),
      ],
    );
  }

  Widget _buildInterpretations() {
    final Map<int, String> houseMeanings = {for (int h = 1; h <= 12; h++) h: Meanings.house(h)};

    return ListView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: kpCusps.length,
      itemBuilder: (context, index) {
        final c = kpCusps[index];
        final meaning = houseMeanings[c.cuspNumber] ?? '';
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${tr('Cusp', 'भाव संधि')} ${c.cuspNumber}: $meaning',
                  style: TextStyle(color: Theme.of(context).colorScheme.secondary, fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 8),
                Text(
                  tr(
                      'The sub-lord of the ${c.cuspNumber} cusp is ${L10n.planet(c.subLord)}, placed in the star of ${L10n.planet(c.nakshatraLord)}. '
                          'In KP System, the sub-lord dictates the success or failure of the house matters, while the star lord shows the source or nature of the results. '
                          'Thus, matters of $meaning will be heavily influenced by the dignity and significations of ${L10n.planet(c.subLord)} and ${L10n.planet(c.nakshatraLord)} in this chart.',
                      '${c.cuspNumber}वीं भाव संधि का उप-स्वामी ${L10n.planet(c.subLord)} है, जो ${L10n.planet(c.nakshatraLord)} के नक्षत्र में है। '
                          'केपी पद्धति में उप-स्वामी भाव के विषयों की सफलता या असफलता तय करता है, जबकि नक्षत्र स्वामी फल का स्रोत या प्रकृति बताता है। '
                          'इसलिए $meaning के विषय इस कुंडली में ${L10n.planet(c.subLord)} और ${L10n.planet(c.nakshatraLord)} की स्थिति और कारकत्व से बहुत प्रभावित होंगे।'),
                  style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8), height: 1.4),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
