import 'package:flutter/material.dart';
import '../../core/ephemeris.dart';
import '../../core/yogas_math.dart';

class YogasScreen extends StatelessWidget {
  final ChartData chartData;

  const YogasScreen({super.key, required this.chartData});

  @override
  Widget build(BuildContext context) {
    int lagnaRashi = (chartData.ascendantSidereal / 30).floor();
    List<YogaResult> yogas = YogasMath.computeAllYogas(chartData.planetLongitudes, lagnaRashi);

    if (yogas.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Yogas')),
        body: const Center(child: Text('No major Yogas formed in this chart.')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Yogas')),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: yogas.length,
        itemBuilder: (context, index) {
          final yoga = yogas[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            child: ListTile(
              title: Text('${yoga.name} (${yoga.hindi})', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  Text('Category: ${yoga.category} | Strength: ${yoga.strength}', style: TextStyle(color: Theme.of(context).colorScheme.secondary, fontSize: 13)),
                  const SizedBox(height: 8),
                  Text(yoga.description, style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 14)),
                  const SizedBox(height: 8),
                  Text('Planets Involved: ${yoga.planets.join(', ').toUpperCase()}', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 12)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
