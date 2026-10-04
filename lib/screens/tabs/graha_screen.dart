import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/chart_summary.dart';
import '../../core/ephemeris.dart';
import '../../core/planetary_dignity.dart';
import '../../core/vedic_math.dart';
import '../../widgets/ai_sheet.dart';
import '../../core/l10n.dart';
import '../../core/plain/interpret.dart';

class GrahaScreen extends ConsumerWidget {
  final ChartData chartData;
  final int? profileId;
  final String? name;

  const GrahaScreen({super.key, required this.chartData, this.profileId, this.name});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final List<Map<String, dynamic>> planetDetails = [];
    final rashis = {for (final e in chartData.planetLongitudes.entries) e.key: VedicMath.rashiIndex(e.value)};

    void add(String label, String hindi, double sid, {String dignity = '-', bool retro = false, double? speed, String? key}) {
      final r = VedicMath.rashiIndex(sid);
      planetDetails.add({
        'name': label,
        'hindi': hindi,
        'key': key,
        'sign': r,
        'degree': VedicMath.formatDegree(sid),
        'rashi': L10n.sign(r),
        'house': VedicMath.houseOf(r, chartData.lagnaRashi),
        'nakshatra': '${L10n.nakshatra(VedicMath.nakshatraIndex(sid))} (${VedicMath.pada(sid)})',
        'dignity': dignity,
        'retro': retro,
        'speed': speed,
      });
    }

    add('Ascendant', 'लग्न', chartData.ascendantSidereal);
    for (final key in Ephemeris.planetOrder) {
      final sid = chartData.planetLongitudes[key];
      final p = VedicMath.planets[key];
      if (sid == null || p == null) continue;
      add(p.name, p.hindi, sid,
          key: key,
          dignity: PlanetaryDignity.getAdvancedDignity(key, VedicMath.rashiIndex(sid), rashis, degree: VedicMath.degInRashi(sid)),
          retro: chartData.isRetrograde(key),
          speed: chartData.planetSpeeds[key]);
    }

    return Scaffold(
      appBar: AppBar(title: Text(tr('Planets', 'ग्रह'))),
      body: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
        itemCount: planetDetails.length,
        itemBuilder: (context, index) {
          final pd = planetDetails[index];
          final scheme = Theme.of(context).colorScheme;
          final String dignity = pd['dignity'];
          final Color dignityColor = dignity == 'Exalted' || dignity == 'Moolatrikona' || dignity == 'Own Sign'
              ? Colors.green
              : (dignity == 'Debilitated' || dignity.contains('Enemy') ? Colors.redAccent : Colors.orangeAccent);
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Text('${L10n.hi ? pd['hindi'] : '${pd['name']} (${pd['hindi']})'}${pd['retro'] ? '  ℞' : ''}',
                            style: TextStyle(color: scheme.secondary, fontSize: 18, fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(width: 8),
                      Text('${pd['rashi']} ${pd['degree']}', style: TextStyle(color: scheme.onSurface, fontSize: 15)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 16,
                    runSpacing: 4,
                    children: [
                      Text('${tr('House', 'भाव')} ${pd['house']}', style: TextStyle(color: scheme.onSurface.withValues(alpha: 0.8))),
                      Text('${tr('Nakshatra', 'नक्षत्र')}: ${pd['nakshatra']}', style: TextStyle(color: scheme.onSurface.withValues(alpha: 0.8))),
                      if (pd['speed'] != null)
                        Text('${tr('Speed', 'गति')}: ${(pd['speed'] as double).toStringAsFixed(3)}°/${tr('day', 'दिन')}',
                            style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12)),
                    ],
                  ),
                  if (dignity != '-') ...[
                    const SizedBox(height: 8),
                    Text('${tr('Dignity', 'गरिमा')}: ${L10n.dignity(dignity)}', style: TextStyle(color: dignityColor)),
                  ],
                  if (pd['key'] != null) ...[
                    const SizedBox(height: 8),
                    Text(Interpret.planetInHouse(pd['key'], pd['house'], pd['sign']), style: TextStyle(fontSize: 13, height: 1.4, color: scheme.onSurfaceVariant)),
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
        label: Text(tr('Ask AI', 'AI से पूछें')),
        onPressed: () => showAiSheet(
          context,
          ref,
          title: tr('Planetary Analysis', 'ग्रह विश्लेषण'),
          profileId: profileId,
          prompt: 'Provide a detailed analysis of each planet in this Vedic birth chart based on its sign, '
              'house, nakshatra, dignity and retrogression.\n\n${ChartSummary.describe(chartData, name: name)}',
        ),
      ),
    );
  }
}
