import 'package:flutter/material.dart';
import '../../core/ephemeris.dart';
import '../../core/doshas_math.dart';
import '../../core/vedic_math.dart';

class DoshasScreen extends StatelessWidget {
  final ChartData chartData;

  const DoshasScreen({super.key, required this.chartData});

  @override
  Widget build(BuildContext context) {
    int lagnaRashi = (chartData.ascendantSidereal / 30).floor();
    
    List<DoshaResult> doshas = [];
    
    var manglik = DoshasMath.computeManglik(chartData.planetLongitudes, lagnaRashi);
    if (manglik != null) doshas.add(manglik);
    
    var kaalSarp = DoshasMath.computeKaalSarp(chartData.planetLongitudes, lagnaRashi);
    if (kaalSarp != null) doshas.add(kaalSarp);
    
    var pitru = DoshasMath.computePitruDosha(chartData.planetLongitudes, lagnaRashi);
    doshas.add(pitru);
    
    var grahan = DoshasMath.computeGrahanDosha(chartData.planetLongitudes);
    doshas.add(grahan);

    var chandal = DoshasMath.computeGuruChandalDosha(chartData.planetLongitudes);
    doshas.add(chandal);

    var kemadruma = DoshasMath.computeKemadrumaDosha(chartData.planetLongitudes, lagnaRashi);
    doshas.add(kemadruma);

    // Compute Sadesati using current transit
    if (chartData.planetLongitudes.containsKey('moon')) {
      int moonRashi = VedicMath.rashiIndex(chartData.planetLongitudes['moon']!);
      final ChartData transitChart = Ephemeris.currentChart();
      if (transitChart.planetLongitudes.containsKey('saturn')) {
        int saturnRashi = VedicMath.rashiIndex(transitChart.planetLongitudes['saturn']!);
        var sadesati = DoshasMath.computeSadesati(moonRashi, saturnRashi);
        doshas.add(sadesati);
      }
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Doshas')),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: doshas.length,
        itemBuilder: (context, index) {
          final dosha = doshas[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(child: Text(
                        '${dosha.name} (${dosha.hindi})',
                        style: TextStyle(
                          color: dosha.isActive ? Theme.of(context).colorScheme.error : Theme.of(context).colorScheme.primary,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      )),
                      Chip(
                        label: Text(!dosha.present ? 'Absent' : (dosha.cancelled ? 'Cancelled' : 'Present')),
                        backgroundColor: dosha.isActive ? Theme.of(context).colorScheme.errorContainer : Theme.of(context).colorScheme.primaryContainer,
                      ),
                    ],
                  ),
                  if (dosha.present && dosha.severity.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text('Severity: ${dosha.severity}', style: const TextStyle(fontWeight: FontWeight.bold)),
                  ],
                  const SizedBox(height: 12),
                  Text(dosha.description),
                  if (dosha.conditions.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    ...dosha.conditions.map((c) => Text('• $c')),
                  ],
                  if (dosha.present && dosha.exceptions.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text('Cancellation factors:', style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold)),
                    ...dosha.exceptions.map((c) => Text('• $c')),
                  ],
                  if (dosha.isActive && dosha.remedies.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text('Remedies:', style: TextStyle(color: Theme.of(context).colorScheme.secondary, fontWeight: FontWeight.bold)),
                    ...dosha.remedies.map((r) => Text('• $r')),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
