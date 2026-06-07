import 'package:flutter/material.dart';
import '../../core/ephemeris.dart';
import '../../core/barshphal_math.dart';
import '../../widgets/kundli_chart.dart';

class BarshphalScreen extends StatefulWidget {
  final ChartData chartData;
  final int birthYear;
  final double lat;
  final double lon;

  const BarshphalScreen({
    super.key,
    required this.chartData,
    required this.birthYear,
    required this.lat,
    required this.lon,
  });

  @override
  State<BarshphalScreen> createState() => _BarshphalScreenState();
}

class _BarshphalScreenState extends State<BarshphalScreen> {
  late BarshphalData data;

  @override
  void initState() {
    super.initState();
    int currentYear = DateTime.now().year;
    data = BarshphalMath.compute(widget.chartData, widget.birthYear, currentYear, widget.lat, widget.lon);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Barshphal (Varshaphala)')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    const Text('Solar Return Chart for Age', style: TextStyle(color: Colors.grey)),
                    const SizedBox(height: 8),
                    Text('${data.age}', style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: Colors.amber)),
                    const SizedBox(height: 16),
                    const Text('Exact Solar Return Time (UTC)'),
                    Text(data.solarReturnDate, style: const TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            _buildDetailCard(
              'Muntha',
              '${data.munthaRashiData.name} (${data.munthaRashiData.hindi})',
              'Lord: ${data.munthaLord.name}',
              data.munthaLord.color,
            ),
            const SizedBox(height: 16),
            _buildDetailCard(
              'Year Lagna (Varsheshwar)',
              '${data.yearLagnaData.name} (${data.yearLagnaData.hindi})',
              'Lord: ${data.yearLagnaLord.name}',
              data.yearLagnaLord.color,
            ),
            const SizedBox(height: 24),
            const Text('Annual Chart (Varshfal)', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
            const SizedBox(height: 16),
            SizedBox(
              height: 350,
              child: _buildVarshfalChart(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVarshfalChart() {
    Map<int, List<String>> houses = {for (var i = 1; i <= 12; i++) i: []};
    int lagnaSign = (data.varshaphalChart.ascendantSidereal / 30).floor() + 1;

    final Map<String, String> pNames = {
      'sun': 'Su', 'moon': 'Mo', 'mars': 'Ma', 'mercury': 'Me',
      'jupiter': 'Ju', 'venus': 'Ve', 'saturn': 'Sa',
      'rahu': 'Ra', 'ketu': 'Ke'
    };

    data.varshaphalChart.planetLongitudes.forEach((pName, sidereal) {
      if (!pNames.containsKey(pName)) return;
      int pSign = (sidereal / 30).floor() + 1;
      int house = (pSign - lagnaSign + 12) % 12 + 1;
      houses[house]!.add(pNames[pName]!);
    });

    return KundliChart(
      housePlanets: houses,
      ascendantSign: lagnaSign,
      onHouseTapped: (house) {},
    );
  }

  Widget _buildDetailCard(String title, String value, String subtitle, Color color) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        title: Text(title, style: const TextStyle(fontSize: 14, color: Colors.grey)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(subtitle, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
