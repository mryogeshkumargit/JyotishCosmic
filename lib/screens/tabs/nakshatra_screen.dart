import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/ephemeris.dart';
import '../../core/vedic_math.dart';

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
      appBar: AppBar(title: const Text('Nakshatra')),
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
                    Text('Your Birth Nakshatra', style: TextStyle(color: Theme.of(context).colorScheme.secondary, fontSize: 14)),
                    const SizedBox(height: 8),
                    Text(moonNak.name, textAlign: TextAlign.center, style: GoogleFonts.cinzel(fontSize: 32, fontWeight: FontWeight.bold)),
                    Text(moonNak.hindi, style: const TextStyle(fontSize: 24, color: Colors.amber)),
                    const SizedBox(height: 16),
                    Text('Pada $moonPada', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 24),
                    _buildDetailRow('Lord / स्वामी', '${lordPlanet.name} (${lordPlanet.hindi})'),
                    _buildDetailRow('Deity / देवता', moonNak.deity),
                    _buildDetailRow('Symbol / प्रतीक', moonNak.symbol),
                    _buildDetailRow('Gana / गण', moonNak.gana),
                    _buildDetailRow('Nadi / नाड़ी', moonNak.nadi),
                    _buildDetailRow('Lucky Nos / शुभ अंक', moonNak.lucky),
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
                          const Text('Detailed Interpretation', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          const SizedBox(height: 8),
                          Text(moonNak.description, style: const TextStyle(fontSize: 14, height: 1.4)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text('The 27 Nakshatras', style: Theme.of(context).textTheme.titleLarge),
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
                      Text(nak.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12), textAlign: TextAlign.center),
                      Text(nak.hindi, style: TextStyle(color: Theme.of(context).colorScheme.secondary, fontSize: 12)),
                      Text(VedicMath.planets[nak.lord]!.name, style: const TextStyle(color: Colors.grey, fontSize: 10)),
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
