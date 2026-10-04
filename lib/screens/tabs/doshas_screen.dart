import 'package:flutter/material.dart';
import '../../core/doshas_math.dart';
import '../../core/ephemeris.dart';
import '../../core/l10n.dart';
import '../../core/vedic_math.dart';
import '../../widgets/analysis_widgets.dart';

class DoshasScreen extends StatelessWidget {
  final ChartData chartData;

  const DoshasScreen({super.key, required this.chartData});

  List<DoshaResult> _doshas() {
    final lagnaRashi = chartData.lagnaRashi;
    final l = chartData.planetLongitudes;
    return [
      ?DoshasMath.computeManglik(l, lagnaRashi),
      ?DoshasMath.computeKaalSarp(l, lagnaRashi),
      DoshasMath.computePitruDosha(l, lagnaRashi),
      DoshasMath.computeGrahanDosha(l),
      DoshasMath.computeGuruChandalDosha(l),
      DoshasMath.computeKemadrumaDosha(l),
      // Sade Sati uses the current (transit) Saturn.
      if (l.containsKey('moon'))
        DoshasMath.computeSadesati(VedicMath.rashiIndex(l['moon']!), VedicMath.rashiIndex(Ephemeris.siderealLongitude('saturn', Ephemeris.nowJd()))),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final doshas = _doshas();
    final present = doshas.where((d) => d.present).toList();
    return Scaffold(
      appBar: AppBar(title: Text(tr('Doshas', 'दोष'))),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SimpleMeaningCard([
            tr('A dosha is a planetary pattern that tradition links with a specific difficulty. It is not a curse or a certainty; most doshas have cancellations, and their effect depends on the strength of the planets involved and on timing.',
                'दोष ग्रहों की ऐसी स्थिति है जिसे परंपरा किसी विशेष कठिनाई से जोड़ती है। यह कोई श्राप या निश्चितता नहीं है; अधिकतर दोषों के भंग होते हैं और इनका असर ग्रहों के बल और समय पर निर्भर करता है।'),
            present.isEmpty
                ? tr('None of the doshas checked here is active in your chart.', 'यहाँ जाँचे गए दोषों में से कोई भी आपकी कुंडली में सक्रिय नहीं है।')
                : tr('Active in your chart: ${L10n.join(present.map((d) => d.title).toList())}. Read each card below for what it means in practice.',
                    'आपकी कुंडली में सक्रिय: ${L10n.join(present.map((d) => d.title).toList())}। व्यवहार में इसका क्या अर्थ है, नीचे हर कार्ड में पढ़ें।'),
          ]),
          for (final dosha in doshas)
            Card(
              margin: const EdgeInsets.only(bottom: 16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            L10n.hi ? dosha.hindi : '${dosha.name} (${dosha.hindi})',
                            style: TextStyle(color: dosha.present ? scheme.error : scheme.primary, fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Chip(
                          label: Text(dosha.present ? tr('Present', 'उपस्थित') : tr('Absent', 'अनुपस्थित')),
                          backgroundColor: dosha.present ? scheme.errorContainer : scheme.primaryContainer,
                        ),
                      ],
                    ),
                    if (dosha.present && dosha.severity.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text('${tr('Severity', 'तीव्रता')}: ${dosha.severityLabel}', style: const TextStyle(fontWeight: FontWeight.bold)),
                    ],
                    if (dosha.simple.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      SimpleMeaningCard(dosha.simple, card: false),
                    ],
                    if (dosha.conditions.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(tr('Chart factors', 'कुंडली के कारक'), style: TextStyle(color: scheme.secondary, fontWeight: FontWeight.bold)),
                      ...dosha.conditions.map((c) => BulletLine(c)),
                    ],
                    if (dosha.exceptions.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(tr('Cancellations', 'भंग के कारण'), style: TextStyle(color: scheme.primary, fontWeight: FontWeight.bold)),
                      ...dosha.exceptions.map((c) => BulletLine(c, mark: '✓', color: Colors.green)),
                    ],
                    if (dosha.description.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text('${tr('Rule', 'नियम')}: ${dosha.description}', style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant)),
                    ],
                    if (dosha.present && dosha.remedies.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Text(tr('Traditional remedies', 'पारंपरिक उपाय'), style: TextStyle(color: scheme.secondary, fontWeight: FontWeight.bold)),
                      ...dosha.remedies.map((r) => BulletLine(r)),
                    ],
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
