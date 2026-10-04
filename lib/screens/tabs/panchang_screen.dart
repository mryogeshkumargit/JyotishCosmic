import 'package:flutter/material.dart';
import '../../core/ephemeris.dart';
import '../../core/panchang_math.dart';
import '../../services/location_service.dart';
import '../../core/l10n.dart';
import '../../core/nakshatra_hi.dart';
import '../../core/vedic_math.dart';
import '../../widgets/analysis_widgets.dart';

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
    String both(Object? en, Object? hi) => L10n.hi ? '$hi' : '$en ($hi)';
    final nakIdx = VedicMath.nakshatraIndex(chart.planetLongitudes['moon']!);
    String lord(String name) => L10n.hi ? L10n.planet(name.toLowerCase()) : name;
    const tithiTypes = {'Nanda': 'नंदा', 'Bhadra': 'भद्रा', 'Jaya': 'जया', 'Rikta': 'रिक्ता', 'Purna': 'पूर्णा'};

    return Scaffold(
      appBar: AppBar(title: Text(tr('Panchang', 'पंचांग'))),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SegmentedButton<bool>(
            segments: [
              ButtonSegment(value: true, label: Text(tr('Today', 'आज')), icon: const Icon(Icons.today)),
              ButtonSegment(value: false, label: Text(tr('At Birth', 'जन्म के समय')), icon: const Icon(Icons.child_care)),
            ],
            selected: {_today},
            onSelectionChanged: (s) => setState(() => _today = s.first),
          ),
          const SizedBox(height: 8),
          Text(
            '${local.year}-${two(local.month)}-${two(local.day)} ${two(local.hour)}:${two(local.minute)} '
            '${tr('at', 'स्थान')} ${widget.lat.toStringAsFixed(2)}, ${widget.lon.toStringAsFixed(2)}',
            textAlign: TextAlign.center,
            style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 12),
          ),
          const SizedBox(height: 12),
          SimpleMeaningCard([
            tr('The Panchang ("five limbs") describes the quality of a moment: the lunar day (Tithi), the Moon\'s star (Nakshatra), the Sun–Moon combination (Yoga), '
                'the half lunar day (Karana) and the weekday (Vara). It is used to choose good times and to understand the mood of a day.',
                'पंचांग ("पाँच अंग") किसी समय की गुणवत्ता बताता है: चन्द्र दिवस (तिथि), चन्द्र का नक्षत्र, सूर्य-चन्द्र का योग, आधी तिथि (करण) और वार। '
                    'इसका उपयोग शुभ समय चुनने और दिन का स्वभाव समझने के लिए होता है।'),
            tr('Rahu Kaal, Yamaganda and Gulika Kaal are short daily periods traditionally avoided for starting new work.',
                'राहु काल, यमगंड और गुलिक काल दिन के छोटे समय हैं, जिनमें परंपरा से नए काम की शुरुआत टाली जाती है।'),
          ]),
          _buildInfoCard(context, tr('Tithi', 'तिथि'), both(tithi['name'], tithi['hindi']),
              '${tr('Type', 'प्रकार')}: ${tr('${tithi['type']}', tithiTypes[tithi['type']] ?? '${tithi['type']}')} | ${tr('Paksha', 'पक्ष')}: ${tr(paksha['en']!, paksha['hi']!)}'),
          _buildInfoCard(context, tr('Nakshatra', 'नक्षत्र'), both(nak['name'], nak['hindi']),
              '${tr('Lord', 'स्वामी')}: ${lord('${nak['lord']}')} | ${tr('Deity', 'देवता')}: ${NakshatraHi.deity(nakIdx)} | ${tr('Pada', 'पद')}: ${nak['pada']}'),
          _buildInfoCard(context, tr('Karana', 'करण'), both(karana['en'], karana['hi']), ''),
          _buildInfoCard(context, tr('Yoga', 'योग'), both(yoga['en'], yoga['hi']), ''),
          _buildInfoCard(context, tr('Vara (Day, sunrise to sunrise)', 'वार (सूर्योदय से सूर्योदय)'), both(vara['name'], vara['hindi']), '${tr('Lord', 'स्वामी')}: ${lord('${vara['lord']}')}'),
          const SizedBox(height: 24),
          Text(tr('Important Timings (local time)', 'महत्वपूर्ण समय (स्थानीय)'),
              style: TextStyle(color: Theme.of(context).colorScheme.secondary, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          _buildTimingCard(context, tr('Sunrise / Sunset', 'सूर्योदय / सूर्यास्त'), '${panchang['sunrise']} - ${panchang['sunset']}', Icons.wb_sunny),
          _buildTimingCard(context, tr('Rahu Kaal', 'राहु काल'), '${panchang['rahuKaal']['start']} - ${panchang['rahuKaal']['end']}', Icons.warning_amber),
          _buildTimingCard(context, tr('Yamaganda', 'यमगंड'), '${panchang['yamaganda']['start']} - ${panchang['yamaganda']['end']}', Icons.block),
          _buildTimingCard(context, tr('Gulika Kaal', 'गुलिक काल'), '${panchang['gulikaKaal']['start']} - ${panchang['gulikaKaal']['end']}', Icons.timer),
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
