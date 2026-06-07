import 'package:flutter/material.dart';
import '../../core/ephemeris.dart';
import '../../core/vedic_math.dart';
import '../../theme/app_theme.dart';
import '../../services/ai_service.dart';
import '../../providers/settings_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class DashaScreen extends ConsumerWidget {
  final ChartData chartData;
  final DateTime birthDate;

  const DashaScreen({super.key, required this.chartData, required this.birthDate});

  void _showAIInterpretation(BuildContext context, WidgetRef ref, DashaCalculations dashas) {
    // Determine current dasha based on today's JD
    double todayJD = Ephemeris.julianDay(DateTime.now().year, DateTime.now().month, DateTime.now().day);
    
    DashaPeriod? currentMaha;
    for (var d in dashas.mahadashas) {
      if (todayJD >= d.startJD && todayJD < d.endJD) {
        currentMaha = d;
        break;
      }
    }
    currentMaha ??= dashas.mahadashas.first;

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
                  Text('Vimshottari Dasha Analysis', style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 20, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: FutureBuilder<String>(
                  future: AiService.interpret(
                    ref.read(settingsProvider), 
                    'Analyze the current Vimshottari Mahadasha of ${VedicMath.planets[currentMaha!.lord]?.name ?? currentMaha.lord} running from ${currentMaha.startDate} to ${currentMaha.endDate}.'
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
    double moonSid = chartData.planetLongitudes['moon'] ?? 0.0;
    final dashas = DashaCalculations.compute(chartData.jd, moonSid);

    double todayJD = Ephemeris.julianDay(DateTime.now().year, DateTime.now().month, DateTime.now().day);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Vimshottari Dasha'),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: dashas.mahadashas.length,
        itemBuilder: (context, index) {
          final d = dashas.mahadashas[index];
          final p = VedicMath.planets[d.lord];
          bool isCurrent = todayJD >= d.startJD && todayJD < d.endJD;

          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            color: isCurrent ? Theme.of(context).colorScheme.secondary.withOpacity(0.1) : Theme.of(context).cardColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                color: isCurrent ? Theme.of(context).colorScheme.secondary : Colors.transparent,
                width: 1.5,
              ),
            ),
            child: ExpansionTile(
              leading: CircleAvatar(
                backgroundColor: p?.color.withOpacity(0.2) ?? Colors.grey,
                child: Text(p?.symbol ?? '', style: TextStyle(color: p?.color ?? Colors.white, fontSize: 18)),
              ),
              title: Text('${p?.name ?? d.lord} Mahadasha', style: TextStyle(color: isCurrent ? Theme.of(context).colorScheme.secondary : Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.bold)),
              subtitle: Text('${d.startDate} - ${d.endDate}', style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7), fontSize: 12)),
              children: d.subPeriods.map((antar) {
                final ap = VedicMath.planets[antar.lord];
                bool isAntarCurrent = todayJD >= antar.startJD && todayJD < antar.endJD;
                return ExpansionTile(
                  title: Text('${ap?.name ?? antar.lord} Antardasha', style: TextStyle(color: isAntarCurrent ? Theme.of(context).colorScheme.secondary : Theme.of(context).colorScheme.onSurface, fontWeight: isAntarCurrent ? FontWeight.bold : FontWeight.normal, fontSize: 15)),
                  subtitle: Text('${antar.startDate} - ${antar.endDate}', style: TextStyle(fontSize: 12)),
                  children: antar.subPeriods.map((pratyantar) {
                    final pp = VedicMath.planets[pratyantar.lord];
                    bool isPratCurrent = todayJD >= pratyantar.startJD && todayJD < pratyantar.endJD;
                    return ListTile(
                      contentPadding: const EdgeInsets.only(left: 32, right: 16),
                      title: Text('${pp?.name ?? pratyantar.lord} Pratyantardasha', style: TextStyle(color: isPratCurrent ? Theme.of(context).colorScheme.secondary : Theme.of(context).colorScheme.onSurface, fontWeight: isPratCurrent ? FontWeight.bold : FontWeight.normal, fontSize: 14)),
                      subtitle: Text('${pratyantar.startDate} - ${pratyantar.endDate}', style: TextStyle(fontSize: 11)),
                    );
                  }).toList(),
                );
              }).toList(),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Theme.of(context).colorScheme.secondary,
        foregroundColor: Theme.of(context).colorScheme.onSecondary,
        icon: const Icon(Icons.auto_awesome),
        label: const Text('Ask AI Current Dasha'),
        onPressed: () => _showAIInterpretation(context, ref, dashas),
      ),
    );
  }
}
