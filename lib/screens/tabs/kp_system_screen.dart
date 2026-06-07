import 'package:flutter/material.dart';
import '../../core/ephemeris.dart';
import '../../core/kp_math.dart';

class KPSystemScreen extends StatefulWidget {
  final ChartData chartData;
  final double lat;
  final double lon;

  const KPSystemScreen({super.key, required this.chartData, required this.lat, required this.lon});

  @override
  State<KPSystemScreen> createState() => _KPSystemScreenState();
}

class _KPSystemScreenState extends State<KPSystemScreen> {
  late Map<String, KPPlanetData> kpPlanets;
  late List<KPCuspData> kpCusps;

  @override
  void initState() {
    super.initState();
    double ayanamsa = Ephemeris.lahiriAyanamsa(widget.chartData.jd);
    kpPlanets = KPMath.computeKPPlanets(widget.chartData);
    kpCusps = KPMath.computeKPCusps(widget.chartData.jd, widget.lat, widget.lon, ayanamsa);
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
      border: TableBorder.all(color: Colors.grey.withOpacity(0.3)),
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
        ...['sun', 'moon', 'mars', 'mercury', 'jupiter', 'venus', 'saturn', 'rahu', 'ketu'].map((p) {
          if (!kpPlanets.containsKey(p)) return const TableRow(children: [Text(''), Text(''), Text(''), Text('')]);
          var data = kpPlanets[p]!;
          return TableRow(
            children: [
              Padding(padding: const EdgeInsets.all(8.0), child: Text(p.toUpperCase())),
              Padding(padding: const EdgeInsets.all(8.0), child: Text(data.rashi)),
              Padding(padding: const EdgeInsets.all(8.0), child: Text(data.nakshatraLord.toUpperCase())),
              Padding(padding: const EdgeInsets.all(8.0), child: Text(data.subLord.toUpperCase())),
            ],
          );
        }),
      ],
    );
  }

  Widget _buildCuspTable() {
    return Table(
      border: TableBorder.all(color: Colors.grey.withOpacity(0.3)),
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
              Padding(padding: const EdgeInsets.all(8.0), child: Text(c.rashi)),
              Padding(padding: const EdgeInsets.all(8.0), child: Text(c.nakshatraLord.toUpperCase())),
              Padding(padding: const EdgeInsets.all(8.0), child: Text(c.subLord.toUpperCase())),
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
                  'Cusp ${c.cuspNumber}: ${meaning}',
                  style: TextStyle(color: Theme.of(context).colorScheme.secondary, fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 8),
                Text(
                  'The sub-lord of the ${c.cuspNumber} cusp is ${c.subLord.toUpperCase()}, placed in the star of ${c.nakshatraLord.toUpperCase()}. '
                  'In KP System, the sub-lord dictates the success or failure of the house matters, while the star lord shows the source or nature of the results. '
                  'Thus, matters of $meaning will be heavily influenced by the dignity and significations of ${c.subLord.toUpperCase()} and ${c.nakshatraLord.toUpperCase()} in this chart.',
                  style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8), height: 1.4),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
