import 'package:flutter/material.dart';
import '../../core/ephemeris.dart';
import '../../core/panchang_math.dart';
import '../../services/location_service.dart';

/// Panchang at birth or for today, at the birth place.
class PanchangScreen extends StatefulWidget {
  final ChartData chartData;
  final double lat;
  final double lon;
  final double timezone;
  final String? tzName;

  const PanchangScreen({
    super.key,
    required this.chartData,
    required this.lat,
    required this.lon,
    required this.timezone,
    this.tzName,
  });

  @override
  State<PanchangScreen> createState() => _PanchangScreenState();
}

class _PanchangScreenState extends State<PanchangScreen> {
  bool _today = true;

  @override
  Widget build(BuildContext context) {
    final double offset = _today ? (LocationService.currentUtcOffset(widget.tzName) ?? widget.timezone) : widget.timezone;
    final ChartData chart = _today
        ? Ephemeris.computeChartForJd(Ephemeris.nowJd(), widget.lat, widget.lon, utcOffset: offset)
        : widget.chartData;
    final panchang = PanchangMath.computePanchang(chart, widget.lat, widget.lon, offset);

    final tithi = panchang['tithi'] as Map<String, dynamic>;
    final paksha = panchang['paksha'] as Map<String, String>;
    final vara = panchang['vara'] as Map<String, dynamic>;
    final nak = panchang['nakshatra'] as Map<String, dynamic>;
    final yoga = panchang['yoga'] as Map<String, String>;
    final karana = panchang['karana'] as Map<String, String>;
    final local = Ephemeris.jdToUtc(chart.jd).add(Duration(minutes: (offset * 60).round()));
    String two(int v) => v.toString().padLeft(2, '0');

    return Scaffold(
      appBar: AppBar(title: const Text('Panchang')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SegmentedButton<bool>(
            segments: const [
              ButtonSegment(value: true, label: Text('Today'), icon: Icon(Icons.today)),
              ButtonSegment(value: false, label: Text('At Birth'), icon: Icon(Icons.child_care)),
            ],
            selected: {_today},
            onSelectionChanged: (s) => setState(() => _today = s.first),
          ),
          const SizedBox(height: 8),
          Text(
            '${local.year}-${two(local.month)}-${two(local.day)} ${two(local.hour)}:${two(local.minute)} '
            'at ${widget.lat.toStringAsFixed(2)}, ${widget.lon.toStringAsFixed(2)}',
            textAlign: TextAlign.center,
            style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 12),
          ),
          const SizedBox(height: 12),
          _buildInfoCard(context, 'Tithi', '${tithi['name']} (${tithi['hindi']})', 'Type: ${tithi['type']} | Paksha: ${paksha['en']}'),
          _buildInfoCard(context, 'Nakshatra', '${nak['name']} (${nak['hindi']})', 'Lord: ${nak['lord']} | Deity: ${nak['deity']} | Pada: ${nak['pada']}'),
          _buildInfoCard(context, 'Karana', '${karana['en']} (${karana['hi']})', ''),
          _buildInfoCard(context, 'Yoga', '${yoga['en']} (${yoga['hi']})', ''),
          _buildInfoCard(context, 'Vara (Day, sunrise to sunrise)', '${vara['name']} (${vara['hindi']})', 'Lord: ${vara['lord']}'),
          const SizedBox(height: 24),
          Text('Important Timings (local time)',
              style: TextStyle(color: Theme.of(context).colorScheme.secondary, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          _buildTimingCard(context, 'Sunrise / Sunset', '${panchang['sunrise']} - ${panchang['sunset']}', Icons.wb_sunny),
          _buildTimingCard(context, 'Rahu Kaal', '${panchang['rahuKaal']['start']} - ${panchang['rahuKaal']['end']}', Icons.warning_amber),
          _buildTimingCard(context, 'Yamaganda', '${panchang['yamaganda']['start']} - ${panchang['yamaganda']['end']}', Icons.block),
          _buildTimingCard(context, 'Gulika Kaal', '${panchang['gulikaKaal']['start']} - ${panchang['gulikaKaal']['end']}', Icons.timer),
        ],
      ),
    );
  }

  Widget _buildInfoCard(BuildContext context, String title, String value, String subtitle) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        title: Text(title, style: TextStyle(color: scheme.secondary, fontSize: 12, fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(value, style: TextStyle(color: scheme.onSurface, fontSize: 16)),
            if (subtitle.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(subtitle, style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 13)),
            ]
          ],
        ),
      ),
    );
  }

  Widget _buildTimingCard(BuildContext context, String title, String value, IconData icon) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(icon, color: scheme.secondary),
        title: Text(title, style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 14)),
        trailing: Text(value, style: TextStyle(color: scheme.onSurface, fontSize: 16, fontWeight: FontWeight.bold)),
      ),
    );
  }
}
