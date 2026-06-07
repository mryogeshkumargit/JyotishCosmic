import 'package:flutter/material.dart';
import '../../core/ephemeris.dart';
import '../../core/avasthas_math.dart';

class PlanetConsScreen extends StatefulWidget {
  final ChartData chartData;

  const PlanetConsScreen({super.key, required this.chartData});

  @override
  State<PlanetConsScreen> createState() => _PlanetConsScreenState();
}

class _PlanetConsScreenState extends State<PlanetConsScreen> {
  late List<AvasthaData> avasthas;

  @override
  void initState() {
    super.initState();
    avasthas = AvasthasMath.compute(widget.chartData);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Planetary Avasthas')),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: avasthas.length,
        itemBuilder: (context, index) {
          final p = avasthas[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ListTile(
              leading: Text(p.planetData.symbol, style: TextStyle(fontSize: 32, color: p.planetData.color)),
              title: Text('${p.planetData.name} (${p.planetData.hindi})'),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  Text('Age State: ${p.baladi}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.amber)),
                  Text('Awake State: ${p.jagradadi}', style: const TextStyle(color: Colors.grey)),
                  Text('Degree: ${p.degreeInRashi.toStringAsFixed(2)}°', style: const TextStyle(fontSize: 12)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
