import 'package:flutter/material.dart';
import '../../core/ephemeris.dart';
import '../../core/panchang_math.dart';
import '../../core/vedic_math.dart';

/// Panchang for the birth moment, or for today at the same place.
class PanchangScreen extends StatefulWidget {
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
  State<PanchangScreen> createState() => _PanchangScreenState();
}

class _PanchangScreenState extends State<PanchangScreen> {
  bool _today = false;
  late PanchangResult _birth;
  PanchangResult? _now;

  @override
  void initState() {
    super.initState();
    _birth = PanchangMath.compute(widget.chartData.jd, widget.lat, widget.lon, widget.chartData.utcOffset);
  }

  PanchangResult get _current {
    if (!_today) return _birth;
    return _now ??= PanchangMath.today(widget.lat, widget.lon, widget.chartData.utcOffset);
  }

  @override
  Widget build(BuildContext context) {
    final p = _current;
    final scheme = Theme.of(context).colorScheme;
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final d = p.localDate;

    String ends(PanchangElement e) =>
        e.endsAtJd == null ? '' : 'until ${PanchangMath.formatDateTime(e.endsAtJd!, p.utcOffset)}';

    return Scaffold(
      appBar: AppBar(title: const Text('Panchang')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SegmentedButton<bool>(
            segments: const [
              ButtonSegment(value: false, label: Text('At birth'), icon: Icon(Icons.child_care)),
              ButtonSegment(value: true, label: Text('Today'), icon: Icon(Icons.today)),
            ],
            selected: {_today},
            onSelectionChanged: (s) => setState(() => _today = s.first),
          ),
          const SizedBox(height: 12),
          Text(
            '${p.varaName}, ${d.day} ${months[d.month - 1]} ${d.year}'
            '${_today ? ' • at birth place' : ''}',
            textAlign: TextAlign.center,
            style: TextStyle(color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: 16),
          _info(context, 'Tithi', '${p.paksha} ${p.tithi.name} (${p.tithi.hindi})',
              '${p.tithiType} tithi • ${ends(p.tithi)}'),
          _info(context, 'Nakshatra', '${p.nakshatra.name} (${p.nakshatra.hindi}) — pada ${p.nakshatraPada}',
              '${p.nakshatra.extra} • ${ends(p.nakshatra)}'),
          _info(context, 'Yoga', '${p.yoga.name} (${p.yoga.hindi})', ends(p.yoga)),
          _info(context, 'Karana', '${p.karana.name} (${p.karana.hindi})', ends(p.karana)),
          _info(context, 'Vara (weekday)', '${p.varaName} (${p.varaHindi})',
              'Lord: ${VedicMath.planets[p.varaLord]!.name} • the Hindu day starts at sunrise'),
          _info(context, 'Sun / Moon sign', '${VedicMath.rashis[p.sunRashi].name} / ${VedicMath.rashis[p.moonRashi].name}', ''),
          const SizedBox(height: 24),
          Text('Timings', style: TextStyle(color: scheme.secondary, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          _timing(context, 'Sunrise / Sunset', '${p.time(p.sunriseJd)} – ${p.time(p.sunsetJd)}', Icons.wb_sunny),
          _timing(context, 'Moonrise / Moonset', '${p.time(p.moonriseJd)} – ${p.time(p.moonsetJd)}', Icons.nightlight_round),
          if (p.abhijit != null) _timing(context, 'Abhijit Muhurta', p.abhijit.toString(), Icons.star),
          if (p.rahuKaal != null) _timing(context, 'Rahu Kaal', p.rahuKaal.toString(), Icons.warning_amber),
          if (p.yamaganda != null) _timing(context, 'Yamaganda', p.yamaganda.toString(), Icons.block),
          if (p.gulikaKaal != null) _timing(context, 'Gulika Kaal', p.gulikaKaal.toString(), Icons.timer),
          const SizedBox(height: 12),
          Text(
            'Times are local (UTC${p.utcOffset >= 0 ? '+' : ''}${p.utcOffset}). Sunrise uses the visible upper limb with refraction.',
            style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _info(BuildContext context, String title, String value, String subtitle) {
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
            ],
          ],
        ),
      ),
    );
  }

  Widget _timing(BuildContext context, String title, String value, IconData icon) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(icon, color: scheme.secondary),
        title: Text(title, style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 14)),
        trailing: Text(value, style: TextStyle(color: scheme.onSurface, fontSize: 15, fontWeight: FontWeight.bold)),
      ),
    );
  }
}
