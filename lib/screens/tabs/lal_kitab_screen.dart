import 'package:flutter/material.dart';
import '../../core/ephemeris.dart';
import '../../core/lal_kitab_math.dart';

class LalKitabScreen extends StatefulWidget {
  final ChartData chartData;

  const LalKitabScreen({super.key, required this.chartData});

  @override
  State<LalKitabScreen> createState() => _LalKitabScreenState();
}

class _LalKitabScreenState extends State<LalKitabScreen> {
  late List<LalKitabPlanet> planets;

  @override
  void initState() {
    super.initState();
    planets = LalKitabMath.compute(widget.chartData);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Lal Kitab')),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: planets.length,
        itemBuilder: (context, index) {
          final p = planets[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ExpansionTile(
              leading: Text(p.planetData.symbol, style: TextStyle(fontSize: 32, color: p.planetData.color)),
              title: Text('${p.planetData.name} (${p.planetData.hindi})'),
              subtitle: Text('House ${p.natalHouse} • Kalpurush Sign: ${p.rashiData.name}'),
              trailing: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: p.isSleeping ? Colors.grey.withValues(alpha: 0.2) : Colors.green.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  p.isSleeping ? 'Sleeping' : 'Awake',
                  style: TextStyle(color: p.isSleeping ? Colors.grey : Colors.green, fontWeight: FontWeight.bold),
                ),
              ),
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.healing, color: Theme.of(context).colorScheme.secondary, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Remedy: ${p.remedy}',
                          style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
