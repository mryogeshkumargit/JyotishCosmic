import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/chart_summary.dart';
import '../../core/ephemeris.dart';
import '../../core/vedic_math.dart';
import '../../widgets/ai_sheet.dart';
import '../../core/l10n.dart';
import '../../core/plain/meanings.dart';
import '../../widgets/analysis_widgets.dart';

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
      appBar: AppBar(title: Text(tr('Vimshottari Dasha', 'विंशोत्तरी दशा'))),
      body: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
        itemCount: dashas.mahadashas.length + 1,
        itemBuilder: (context, i) {
          if (i == 0) {
            return SimpleMeaningCard([
              tr('A Daśā is a planetary period. Life unfolds through a fixed sequence of nine planets (120 years in total), starting from the Moon\'s nakshatra at birth. '
                  'During a planet\'s period, the houses it rules and occupies, and the things it signifies, come to the front.',
                  'दशा ग्रहों की अवधि है। जीवन नौ ग्रहों के निश्चित क्रम (कुल 120 वर्ष) से चलता है, जो जन्म के समय चन्द्र नक्षत्र से शुरू होता है। '
                      'किसी ग्रह की दशा में उसके स्वामित्व और स्थिति वाले भाव तथा उसके कारक विषय सामने आते हैं।'),
              if (running.isNotEmpty)
                tr('Now running: ${running.map((d) => L10n.planet(d.lord)).join(' → ')}. The ${L10n.planet(running.first.lord)} Mahādaśā sets the main theme (${Meanings.planet(running.first.lord)}); '
                    '${running.length > 1 ? 'the ${L10n.planet(running[1].lord)} Antardaśā colours it with ${Meanings.planet(running[1].lord)}.' : ''}',
                    'अभी चल रही: ${running.map((d) => L10n.planet(d.lord)).join(' → ')}। ${L10n.planet(running.first.lord)} की महादशा मुख्य विषय तय करती है (${Meanings.planet(running.first.lord)}); '
                        '${running.length > 1 ? '${L10n.planet(running[1].lord)} की अंतर्दशा इसमें ${Meanings.planet(running[1].lord)} का रंग जोड़ती है।' : ''}'),
            ]);
          }
          final index = i - 1;
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
              title: Text(tr('${p?.name ?? d.lord} Mahadasha', '${L10n.planet(d.lord)} महादशा'),
                  style: TextStyle(color: isCurrent ? scheme.secondary : scheme.onSurface, fontWeight: FontWeight.bold)),
              subtitle: Text(
                '${d.startDate} - ${d.endDate}${index == 0 ? tr('  (balance at birth ${d.years.toStringAsFixed(2)} y)', '  (जन्म के समय शेष ${d.years.toStringAsFixed(2)} वर्ष)') : ''}',
                style: TextStyle(color: scheme.onSurface.withValues(alpha: 0.7), fontSize: 12),
              ),
              children: d.subPeriods.map((antar) {
                final bool isAntarCurrent = antar.contains(todayJD);
                return ExpansionTile(
                  initiallyExpanded: isAntarCurrent,
                  title: Text(tr('${L10n.planet(antar.lord)} Antardasha', '${L10n.planet(antar.lord)} अंतर्दशा'), style: periodStyle(isAntarCurrent, 15)),
                  subtitle: Text('${antar.startDate} - ${antar.endDate}', style: const TextStyle(fontSize: 12)),
                  children: antar.subPeriods.map((pratyantar) {
                    return ListTile(
                      contentPadding: const EdgeInsets.only(left: 32, right: 16),
                      title: Text(tr('${L10n.planet(pratyantar.lord)} Pratyantardasha', '${L10n.planet(pratyantar.lord)} प्रत्यंतर्दशा'),
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
        label: Text(tr('Ask AI Current Dasha', 'वर्तमान दशा पर AI से पूछें')),
        onPressed: running.isEmpty
            ? null
            : () {
                final chain = running
                    .map((d) => '${VedicMath.planets[d.lord]!.name} (${d.startDate} to ${d.endDate})')
                    .join(' > ');
                showAiSheet(
                  context,
                  ref,
                  title: tr('Vimshottari Dasha Analysis', 'विंशोत्तरी दशा विश्लेषण'),
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
