import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/ephemeris.dart';
import '../../core/vedic_math.dart';
import '../../core/l10n.dart';
import '../../core/nakshatra_hi.dart';

class NakshatraScreen extends StatelessWidget {
  final ChartData chartData;

  const NakshatraScreen({super.key, required this.chartData});

  @override
  Widget build(BuildContext context) {
    double moonSid = chartData.planetLongitudes['moon'] ?? 0;
    int moonNakIdx = VedicMath.nakshatraIndex(moonSid);
    Nakshatra moonNak = VedicMath.nakshatras[moonNakIdx];
    int moonPada = VedicMath.pada(moonSid);
    Planet lordPlanet = VedicMath.planets[moonNak.lord]!;

    return Scaffold(
      appBar: AppBar(title: Text(tr('Nakshatra', 'नक्षत्र'))),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Text(tr('Your Birth Nakshatra', 'आपका जन्म नक्षत्र'), style: TextStyle(color: Theme.of(context).colorScheme.secondary, fontSize: 14)),
                    const SizedBox(height: 8),
                    Text(L10n.hi ? moonNak.hindi : moonNak.name, textAlign: TextAlign.center, style: GoogleFonts.cinzel(fontSize: 32, fontWeight: FontWeight.bold).copyWith(fontFamilyFallback: const ['NotoSansDevanagari'])),
                    Text(L10n.hi ? moonNak.name : moonNak.hindi, style: const TextStyle(fontSize: 24, color: Colors.amber)),
                    const SizedBox(height: 16),
                    Text('${tr('Pada', 'पद')} $moonPada', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 24),
                    _buildDetailRow(tr('Lord', 'स्वामी'), L10n.hi ? lordPlanet.hindi : '${lordPlanet.name} (${lordPlanet.hindi})'),
                    _buildDetailRow(tr('Deity', 'देवता'), NakshatraHi.deity(moonNakIdx)),
                    _buildDetailRow(tr('Symbol', 'प्रतीक'), NakshatraHi.symbol(moonNakIdx)),
                    _buildDetailRow(tr('Gana', 'गण'), NakshatraHi.gana(moonNak.gana)),
                    _buildDetailRow(tr('Nadi', 'नाड़ी'), NakshatraHi.nadi(moonNak.nadi)),
                    _buildDetailRow(tr('Lucky numbers', 'शुभ अंक'), moonNak.lucky),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(tr('Nature of this nakshatra', 'इस नक्षत्र का स्वभाव'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          const SizedBox(height: 8),
                          Text(NakshatraHi.description(moonNakIdx), style: const TextStyle(fontSize: 14, height: 1.4)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(tr('The 27 Nakshatras', '27 नक्षत्र'), style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                childAspectRatio: 0.8,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: 27,
              itemBuilder: (context, index) {
                final nak = VedicMath.nakshatras[index];
                bool isCurrent = index == moonNakIdx;
                return Container(
                  decoration: BoxDecoration(
                    color: isCurrent ? Colors.amber.withValues(alpha: 0.2) : Theme.of(context).cardColor,
                    border: Border.all(color: isCurrent ? Colors.amber : Colors.grey.withValues(alpha: 0.2)),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.all(4),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('${index + 1}', style: TextStyle(color: isCurrent ? Colors.amber : Colors.grey, fontSize: 12)),
                      Text(L10n.hi ? nak.hindi : nak.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12), textAlign: TextAlign.center),
                      Text(L10n.hi ? nak.name : nak.hindi, style: TextStyle(color: Theme.of(context).colorScheme.secondary, fontSize: 12)),
                      Text(L10n.planet(nak.lord), style: const TextStyle(color: Colors.grey, fontSize: 10)),
                    ],
                  ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: Text(label, style: const TextStyle(color: Colors.grey))),
          const SizedBox(width: 12),
          Expanded(child: Text(value, textAlign: TextAlign.right, style: const TextStyle(fontWeight: FontWeight.bold))),
        ],
      ),
    );
  }
}
