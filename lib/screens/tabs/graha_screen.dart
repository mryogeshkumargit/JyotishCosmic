import 'package:flutter/material.dart';
import '../../core/ephemeris.dart';
import '../../core/vedic_math.dart';
import '../../core/planetary_dignity.dart';
import '../../services/ai_service.dart';
import '../../providers/settings_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class GrahaScreen extends ConsumerWidget {
  final ChartData chartData;

  const GrahaScreen({super.key, required this.chartData});

  void _showAIInterpretation(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          height: MediaQuery.of(context).size.height * 0.7,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.auto_awesome, color: Theme.of(context).colorScheme.secondary),
                  const SizedBox(width: 8),
                  Text('Planetary Analysis', style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 20, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: FutureBuilder<String>(
                  future: AiService.interpret(
                    ref.read(settingsProvider), 
                    'Provide a detailed analysis of the planetary positions in this Vedic birth chart based on their degrees, Nakshatras, and dignities.'
                  ),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(child: CircularProgressIndicator(color: Theme.of(context).colorScheme.secondary));
                    }
                    if (snapshot.hasError) {
                      return Center(child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.red)));
                    }
                    return SingleChildScrollView(
                      child: Text(
                        snapshot.data ?? 'No response',
                        style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 16, height: 1.5),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Build planet list
    final List<Map<String, dynamic>> planetDetails = [];
    
    // Add Ascendant
    int ascRashiIdx = VedicMath.rashiIndex(chartData.ascendantSidereal);
    int ascNakIdx = VedicMath.nakshatraIndex(chartData.ascendantSidereal);
    double ascDeg = VedicMath.degInRashi(chartData.ascendantSidereal);
    int ascPada = VedicMath.pada(chartData.ascendantSidereal);

    planetDetails.add({
      'name': 'Ascendant',
      'hindi': 'लग्न',
      'degree': '${ascDeg.floor()}° ${(ascDeg%1*60).floor()}\'',
      'rashi': VedicMath.rashis[ascRashiIdx].name,
      'nakshatra': '${VedicMath.nakshatras[ascNakIdx].name} ($ascPada)',
      'dignity': '-',
    });

    final allRashis = {
      for (final e in chartData.planetLongitudes.entries) e.key: VedicMath.rashiIndex(e.value)
    };
    chartData.planetLongitudes.forEach((key, longitude) {
      final p = VedicMath.planets[key];
      if (p == null) return;
      int rIdx = VedicMath.rashiIndex(longitude);
      int nIdx = VedicMath.nakshatraIndex(longitude);
      double deg = VedicMath.degInRashi(longitude);
      int pada = VedicMath.pada(longitude);
      String dignity = (key == 'rahu' || key == 'ketu')
          ? VedicMath.dignityOf(key, rIdx)
          : PlanetaryDignity.getAdvancedDignity(key, rIdx, allRashis, degree: deg);
      final retro = chartData.isRetrograde(key) && key != 'rahu' && key != 'ketu';

      planetDetails.add({
        'name': retro ? '${p.name} ℞' : p.name,
        'hindi': p.hindi,
        'degree': '${deg.floor()}° ${(deg%1*60).floor()}\'',
        'rashi': VedicMath.rashis[rIdx].name,
        'nakshatra': '${VedicMath.nakshatras[nIdx].name} ($pada)',
        'dignity': dignity.toUpperCase(),
      });
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Planetary Positions'),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: planetDetails.length,
        itemBuilder: (context, index) {
          final pd = planetDetails[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            color: Theme.of(context).cardColor,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('${pd['name']} (${pd['hindi']})', style: TextStyle(color: Theme.of(context).colorScheme.secondary, fontSize: 18, fontWeight: FontWeight.bold)),
                      Text(pd['degree'], style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 16)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Sign: ${pd['rashi']}', style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8))),
                      Text('Nakshatra: ${pd['nakshatra']}', style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8))),
                    ],
                  ),
                  if (pd['dignity'] != '-') ...[
                    const SizedBox(height: 8),
                    Text('Dignity: ${pd['dignity']}', style: TextStyle(color: pd['dignity'] == 'EXALTED' ? Colors.greenAccent : (pd['dignity'] == 'DEBILITATED' ? Colors.redAccent : Colors.orangeAccent))),
                  ]
                ],
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Theme.of(context).colorScheme.secondary,
        foregroundColor: Theme.of(context).colorScheme.onSecondary,
        icon: const Icon(Icons.auto_awesome),
        label: const Text('Ask AI'),
        onPressed: () => _showAIInterpretation(context, ref),
      ),
    );
  }
}
