import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/chart_summary.dart';
import '../../core/ephemeris.dart';
import '../../core/vedic_math.dart';
import '../../widgets/ai_sheet.dart';

class DashaScreen extends ConsumerWidget {
  final ChartData chartData;
  final int? profileId;
  final String? name;

  const DashaScreen({super.key, required this.chartData, this.profileId, this.name});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final double moonSid = chartData.planetLongitudes['moon'] ?? 0.0;
    final dashas = DashaCalculations.compute(chartData.jd, moonSid, utcOffset: chartData.utcOffset);
    final double todayJD = Ephemeris.nowJd();
    final running = dashas.runningAt(todayJD);
    final scheme = Theme.of(context).colorScheme;

    TextStyle periodStyle(bool current, double size) => TextStyle(
          color: current ? scheme.secondary : scheme.onSurface,
          fontWeight: current ? FontWeight.bold : FontWeight.normal,
          fontSize: size,
        );

    return Scaffold(
      appBar: AppBar(title: const Text('Vimshottari Dasha')),
      body: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
        itemCount: dashas.mahadashas.length,
        itemBuilder: (context, index) {
          final d = dashas.mahadashas[index];
          final p = VedicMath.planets[d.lord];
          final bool isCurrent = d.contains(todayJD);

          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            color: isCurrent ? scheme.secondary.withValues(alpha: 0.1) : Theme.of(context).cardColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: isCurrent ? scheme.secondary : Colors.transparent, width: 1.5),
            ),
            child: ExpansionTile(
              initiallyExpanded: isCurrent,
              leading: CircleAvatar(
                backgroundColor: p?.color.withValues(alpha: 0.2) ?? Colors.grey,
                child: Text(p?.symbol ?? '', style: TextStyle(color: p?.color ?? Colors.white, fontSize: 18)),
              ),
              title: Text('${p?.name ?? d.lord} Mahadasha',
                  style: TextStyle(color: isCurrent ? scheme.secondary : scheme.onSurface, fontWeight: FontWeight.bold)),
              subtitle: Text(
                '${d.startDate} - ${d.endDate}${index == 0 ? '  (balance at birth ${d.years.toStringAsFixed(2)} y)' : ''}',
                style: TextStyle(color: scheme.onSurface.withValues(alpha: 0.7), fontSize: 12),
              ),
              children: d.subPeriods.map((antar) {
                final ap = VedicMath.planets[antar.lord];
                final bool isAntarCurrent = antar.contains(todayJD);
                return ExpansionTile(
                  initiallyExpanded: isAntarCurrent,
                  title: Text('${ap?.name ?? antar.lord} Antardasha', style: periodStyle(isAntarCurrent, 15)),
                  subtitle: Text('${antar.startDate} - ${antar.endDate}', style: const TextStyle(fontSize: 12)),
                  children: antar.subPeriods.map((pratyantar) {
                    final pp = VedicMath.planets[pratyantar.lord];
                    return ListTile(
                      contentPadding: const EdgeInsets.only(left: 32, right: 16),
                      title: Text('${pp?.name ?? pratyantar.lord} Pratyantardasha',
                          style: periodStyle(pratyantar.contains(todayJD), 14)),
                      subtitle: Text('${pratyantar.startDate} - ${pratyantar.endDate}', style: const TextStyle(fontSize: 11)),
                    );
                  }).toList(),
                );
              }).toList(),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: scheme.secondary,
        foregroundColor: scheme.onSecondary,
        icon: const Icon(Icons.auto_awesome),
        label: const Text('Ask AI Current Dasha'),
        onPressed: running.isEmpty
            ? null
            : () {
                final chain = running
                    .map((d) => '${VedicMath.planets[d.lord]!.name} (${d.startDate} to ${d.endDate})')
                    .join(' > ');
                showAiSheet(
                  context,
                  ref,
                  title: 'Vimshottari Dasha Analysis',
                  profileId: profileId,
                  prompt: 'Analyze the currently running Vimshottari dasha periods for this native: $chain. '
                      'Explain what the Mahadasha, Antardasha and Pratyantardasha lords signify from their '
                      'placement, lordship and strength in this chart, and what to expect in this period.\n\n'
                      '${ChartSummary.describe(chartData, name: name)}',
                );
              },
      ),
    );
  }
}
