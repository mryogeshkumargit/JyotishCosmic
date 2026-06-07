import 'package:flutter/material.dart';
import '../../core/ephemeris.dart';
import '../../core/panchang_math.dart';

class PanchangScreen extends StatelessWidget {
  final ChartData chartData;
  final double lat;
  final double lon;

  const PanchangScreen({
    super.key,
    required this.chartData,
    required this.lat,
    required this.lon,
  });

  @override
  Widget build(BuildContext context) {
    double utcOffset = lon / 15.0;
    final panchang = PanchangMath.computePanchang(chartData, lat, lon, utcOffset);

    final tithi = panchang['tithi'] as Map<String, dynamic>;
    final paksha = panchang['paksha'] as Map<String, String>;
    final vara = panchang['vara'] as Map<String, dynamic>;
    final nak = panchang['nakshatra'] as Map<String, dynamic>;
    final yoga = panchang['yoga'] as Map<String, String>;
    final karana = panchang['karana'] as Map<String, String>;

    return Scaffold(
      appBar: AppBar(title: const Text('Daily Panchang')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildInfoCard(context, 'Tithi', '${tithi['name']} (${tithi['hindi']})', 'Type: ${tithi['type']} | Paksha: ${paksha['en']}'),
          _buildInfoCard(context, 'Nakshatra', '${nak['name']} (${nak['hindi']})', 'Lord: ${nak['lord']} | Deity: ${nak['deity']} | Pada: ${nak['pada']}'),
          _buildInfoCard(context, 'Karana', '${karana['en']} (${karana['hi']})', ''),
          _buildInfoCard(context, 'Yoga', '${yoga['en']} (${yoga['hi']})', ''),
          _buildInfoCard(context, 'Vara (Day)', '${vara['name']} (${vara['hindi']})', 'Lord: ${vara['lord']}'),
          
          const SizedBox(height: 24),
          Text('Important Timings', style: TextStyle(color: Theme.of(context).colorScheme.secondary, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          _buildTimingCard(context, 'Sunrise / Sunset', '${panchang['sunrise']} - ${panchang['sunset']}', Icons.wb_sunny),
          _buildTimingCard(context, 'Rahu Kaal', '${panchang['rahuKaal']['start']} - ${panchang['rahuKaal']['end']}', Icons.warning_amber),
          _buildTimingCard(context, 'Gulika Kaal', '${panchang['gulikaKaal']['start']} - ${panchang['gulikaKaal']['end']}', Icons.timer),
        ],
      ),
    );
  }

  Widget _buildInfoCard(BuildContext context, String title, String value, String subtitle) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        title: Text(title, style: TextStyle(color: Theme.of(context).colorScheme.secondary, fontSize: 12, fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(value, style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 16)),
            if (subtitle.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(subtitle, style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 13)),
            ]
          ],
        ),
      ),
    );
  }

  Widget _buildTimingCard(BuildContext context, String title, String value, IconData icon) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(icon, color: Theme.of(context).colorScheme.secondary),
        title: Text(title, style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 14)),
        trailing: Text(value, style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 16, fontWeight: FontWeight.bold)),
      ),
    );
  }
}
