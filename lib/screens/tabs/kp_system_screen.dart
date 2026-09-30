import 'package:flutter/material.dart';
import '../../core/ephemeris.dart';
import '../../core/kp_math.dart';
import '../../core/vedic_math.dart';

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
      appBar: AppBar(title: const Text('KP System')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Krishnamurti ayanamsa: ${kpAyanamsa.toStringAsFixed(4)}°', style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 12),
            const Text('Planetary Details', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            _buildPlanetTable(),
            const SizedBox(height: 24),
            const Text('Placidus House Cusps', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            _buildCuspTable(),
            const SizedBox(height: 24),
            const Text('KP Interpretations (Sub-Lords)', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            _buildInterpretations(),
          ],
        ),
      ),
    );
  }

  Widget _buildPlanetTable() {
    return Table(
      border: TableBorder.all(color: Colors.grey.withValues(alpha: 0.3)),
      columnWidths: const {
        0: FlexColumnWidth(2),
        1: FlexColumnWidth(2),
        2: FlexColumnWidth(2),
        3: FlexColumnWidth(2),
      },
      children: [
        const TableRow(
          decoration: BoxDecoration(color: Colors.black12),
          children: [
            Padding(padding: EdgeInsets.all(8.0), child: Text('Planet', style: TextStyle(fontWeight: FontWeight.bold))),
            Padding(padding: EdgeInsets.all(8.0), child: Text('Sign', style: TextStyle(fontWeight: FontWeight.bold))),
            Padding(padding: EdgeInsets.all(8.0), child: Text('Nak Lord', style: TextStyle(fontWeight: FontWeight.bold))),
            Padding(padding: EdgeInsets.all(8.0), child: Text('Sub Lord', style: TextStyle(fontWeight: FontWeight.bold))),
          ],
        ),
        ...Ephemeris.planetOrder.where(kpPlanets.containsKey).map((p) {
                    var data = kpPlanets[p]!;
          return TableRow(
            children: [
              Padding(padding: const EdgeInsets.all(8.0), child: Text(VedicMath.planets[p]!.name)),
              Padding(padding: const EdgeInsets.all(8.0), child: Text('${data.rashi} ${VedicMath.formatDegree(data.longitude)}')),
              Padding(padding: const EdgeInsets.all(8.0), child: Text(VedicMath.capitalize(data.nakshatraLord))),
              Padding(padding: const EdgeInsets.all(8.0), child: Text(VedicMath.capitalize(data.subLord))),
            ],
          );
        }),
      ],
    );
  }

  Widget _buildCuspTable() {
    return Table(
      border: TableBorder.all(color: Colors.grey.withValues(alpha: 0.3)),
      columnWidths: const {
        0: FlexColumnWidth(1),
        1: FlexColumnWidth(2),
        2: FlexColumnWidth(2),
        3: FlexColumnWidth(2),
      },
      children: [
        const TableRow(
          decoration: BoxDecoration(color: Colors.black12),
          children: [
            Padding(padding: EdgeInsets.all(8.0), child: Text('House', style: TextStyle(fontWeight: FontWeight.bold))),
            Padding(padding: EdgeInsets.all(8.0), child: Text('Sign', style: TextStyle(fontWeight: FontWeight.bold))),
            Padding(padding: EdgeInsets.all(8.0), child: Text('Nak Lord', style: TextStyle(fontWeight: FontWeight.bold))),
            Padding(padding: EdgeInsets.all(8.0), child: Text('Sub Lord', style: TextStyle(fontWeight: FontWeight.bold))),
          ],
        ),
        ...kpCusps.map((c) {
          return TableRow(
            children: [
              Padding(padding: const EdgeInsets.all(8.0), child: Text(c.cuspNumber.toString())),
              Padding(padding: const EdgeInsets.all(8.0), child: Text('${c.rashi} ${VedicMath.formatDegree(c.longitude)}')),
              Padding(padding: const EdgeInsets.all(8.0), child: Text(VedicMath.capitalize(c.nakshatraLord))),
              Padding(padding: const EdgeInsets.all(8.0), child: Text(VedicMath.capitalize(c.subLord))),
            ],
          );
        }),
      ],
    );
  }

  Widget _buildInterpretations() {
    final Map<int, String> houseMeanings = {
      1: 'Self, health, and vitality',
      2: 'Wealth, family, and speech',
      3: 'Courage, siblings, and communication',
      4: 'Mother, property, and happiness',
      5: 'Children, intellect, and speculation',
      6: 'Disease, debt, and enemies',
      7: 'Marriage, partnerships, and business',
      8: 'Longevity, sudden events, and inheritance',
      9: 'Luck, religion, and higher education',
      10: 'Profession, karma, and status',
      11: 'Gains, fulfillment of desires, and friends',
      12: 'Losses, foreign travels, and spirituality'
    };

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
                  'Cusp ${c.cuspNumber}: $meaning',
                  style: TextStyle(color: Theme.of(context).colorScheme.secondary, fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 8),
                Text(
                  'The sub-lord of the ${c.cuspNumber} cusp is ${c.subLord.toUpperCase()}, placed in the star of ${c.nakshatraLord.toUpperCase()}. '
                  'In KP System, the sub-lord dictates the success or failure of the house matters, while the star lord shows the source or nature of the results. '
                  'Thus, matters of $meaning will be heavily influenced by the dignity and significations of ${c.subLord.toUpperCase()} and ${c.nakshatraLord.toUpperCase()} in this chart.',
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
