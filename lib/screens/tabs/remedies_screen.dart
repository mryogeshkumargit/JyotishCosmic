import 'package:flutter/material.dart';
import '../../core/ephemeris.dart';
import '../../core/remedies_math.dart';

class RemediesScreen extends StatefulWidget {
  final ChartData chartData;

  const RemediesScreen({super.key, required this.chartData});

  @override
  State<RemediesScreen> createState() => _RemediesScreenState();
}

class _RemediesScreenState extends State<RemediesScreen> {
  late List<RemedyResult> _remedies;

  @override
  void initState() {
    super.initState();
    _remedies = RemediesMath.compute(widget.chartData);
  }

  @override
  Widget build(BuildContext context) {
    final gemstones = _remedies.where((r) => r.type == 'gemstone').toList();
    final charities = _remedies.where((r) => r.type == 'charity').toList();
    final doshas = _remedies.where((r) => r.type == 'dosha').toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Astrological Remedies')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('Recommended Gemstones (Benefics)', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blue)),
          const SizedBox(height: 8),
          const Text('These gemstones strengthen your functional benefic planets (Lords of 1st, 5th, and 9th houses).', style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 16),
          ...gemstones.map((g) => _buildRemedyCard(g, Icons.diamond, Colors.blueAccent)),
          
          const SizedBox(height: 24),
          const Text('Pacification (Mantras & Charity)', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.orange)),
          const SizedBox(height: 8),
          const Text('These practices pacify functional malefic planets to reduce their negative impacts.', style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 16),
          ...charities.map((c) => _buildRemedyCard(c, Icons.clean_hands, Colors.orangeAccent)),

          if (doshas.isNotEmpty) ...[
            const SizedBox(height: 24),
            const Text('Dosha Specific Remedies', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.redAccent)),
            const SizedBox(height: 8),
            const Text('Specific remedies prescribed for the Doshas present in your chart.', style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 16),
            ...doshas.map((d) => _buildRemedyCard(d, Icons.warning_amber_rounded, Colors.redAccent)),
          ]
        ],
      ),
    );
  }

  Widget _buildRemedyCard(RemedyResult remedy, IconData icon, Color color) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(remedy.title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  Text(remedy.description, style: const TextStyle(height: 1.4)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
