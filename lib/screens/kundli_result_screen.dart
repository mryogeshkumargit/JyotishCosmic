import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/chart_summary.dart';
import '../core/database.dart';
import '../core/ephemeris.dart';
import '../core/vedic_math.dart';
import '../widgets/ai_sheet.dart';
import '../widgets/kundli_chart.dart';
import '../services/pdf_service.dart';
import 'tabs/graha_screen.dart';
import 'tabs/dasha_screen.dart';
import 'tabs/panchang_screen.dart';
import 'tabs/yogas_screen.dart';
import 'tabs/doshas_screen.dart';
import 'tabs/varga_screen.dart';
import 'tabs/transit_screen.dart';
import 'tabs/nakshatra_screen.dart';
import 'tabs/kp_system_screen.dart';
import 'tabs/lal_kitab_screen.dart';
import 'tabs/barshphal_screen.dart';
import 'tabs/planet_cons_screen.dart';
import 'tabs/interpretation_screen.dart';
import 'tabs/ai_chat_screen.dart';
import 'tabs/remedies_screen.dart';
import 'tabs/predictions_screen.dart';
import 'tabs/conjunctions_screen.dart';
import 'tabs/strength_screen.dart';
import 'tabs/ashtakavarga_screen.dart';
import 'tabs/synthesis_screen.dart';

class KundliResultScreen extends ConsumerStatefulWidget {
  final String name;

  /// Birth wall-clock time at the birth place (UTC-encoded, see Profiles.dob).
  final DateTime birth;
  final double lat;
  final double lon;
  final double timezone;
  final String? tzName;
  final String? place;
  final String? gender;
  final int? profileId;

  const KundliResultScreen({
    super.key,
    required this.name,
    required this.birth,
    required this.lat,
    required this.lon,
    required this.timezone,
    this.tzName,
    this.place,
    this.gender,
    this.profileId,
  });

  factory KundliResultScreen.forProfile(Profile p) => KundliResultScreen(
        name: p.name,
        birth: p.dob.toUtc(),
        lat: p.lat,
        lon: p.lon,
        timezone: p.timezone,
        tzName: p.tzName,
        place: p.pob,
        gender: p.gender,
        profileId: p.id,
      );

  @override
  ConsumerState<KundliResultScreen> createState() => _KundliResultScreenState();
}

class _KundliResultScreenState extends ConsumerState<KundliResultScreen> {
  late final ChartData _chartData;

  static const List<(String, IconData)> _actionButtons = [
    ('Synthesis', Icons.hub),
    ('Planet', Icons.public),
    ('Dasha', Icons.timeline),
    ('Predictions', Icons.auto_awesome),
    ('KP System', Icons.calculate),
    ('Shodashvarga', Icons.grid_view),
    ('Lal Kitab', Icons.menu_book),
    ('Barshphal', Icons.calendar_today),
    ('Transit', Icons.sync),
    ('Nakshatra', Icons.wb_twilight),
    ('Avasthas', Icons.balance),
    ('Panchang', Icons.today),
    ('Dosha', Icons.warning_amber),
    ('Yogas', Icons.psychology),
    ('Conjunctions', Icons.join_inner),
    ('Strength', Icons.fitness_center),
    ('Ashtakavarga', Icons.grid_on),
    ('Remedies', Icons.healing),
    ('Interpretation', Icons.lightbulb_outline),
    ('Ask AI', Icons.chat_bubble_outline),
  ];

  @override
  void initState() {
    super.initState();
    final b = widget.birth;
    _chartData = Ephemeris.computeChart(
        b.year, b.month, b.day, b.hour.toDouble(), b.minute.toDouble(), widget.lat, widget.lon, widget.timezone);
  }

  String get _birthLabel {
    final b = widget.birth;
    String two(int v) => v.toString().padLeft(2, '0');
    final off = widget.timezone;
    final sign = off >= 0 ? '+' : '-';
    final mins = (off.abs() * 60).round();
    return '${b.year}-${two(b.month)}-${two(b.day)}  ${two(b.hour)}:${two(b.minute)}  (UTC$sign${mins ~/ 60}:${two(mins % 60)})';
  }

  void _handleHouseTapped(int houseNum) {
    final prompt = 'Analyze house $houseNum of this Vedic birth chart in detail.\n\n'
        '${ChartSummary.describeHouse(_chartData, houseNum)}\n\n'
        'Full chart for context:\n${ChartSummary.describe(_chartData, name: widget.name)}';
    showAiSheet(context, ref, title: 'House $houseNum Analysis', prompt: prompt, profileId: widget.profileId);
  }

  void _open(Widget screen) => Navigator.push(context, MaterialPageRoute(builder: (_) => screen));

  void _handleActionTapped(String featureTitle) {
    final c = _chartData;
    final id = widget.profileId;
    switch (featureTitle) {
      case 'Synthesis':
        _open(SynthesisScreen(chartData: c, profileId: id, name: widget.name));
      case 'Conjunctions':
        _open(ConjunctionsScreen(chartData: c, profileId: id, name: widget.name));
      case 'Strength':
        _open(StrengthScreen(chartData: c));
      case 'Ashtakavarga':
        _open(AshtakavargaScreen(chartData: c));
      case 'Planet':
        _open(GrahaScreen(chartData: c, profileId: id, name: widget.name));
      case 'Dasha':
        _open(DashaScreen(chartData: c, profileId: id, name: widget.name));
      case 'Panchang':
        _open(PanchangScreen(chartData: c, lat: widget.lat, lon: widget.lon, timezone: widget.timezone, tzName: widget.tzName));
      case 'Dosha':
        _open(DoshasScreen(chartData: c));
      case 'Yogas':
        _open(YogasScreen(chartData: c, gender: widget.gender, profileId: id, name: widget.name));
      case 'Shodashvarga':
        _open(VargaScreen(chartData: c, profileId: id));
      case 'Transit':
        _open(TransitScreen(chartData: c, profileId: id));
      case 'Nakshatra':
        _open(NakshatraScreen(chartData: c));
      case 'KP System':
        _open(KPSystemScreen(chartData: c));
      case 'Lal Kitab':
        _open(LalKitabScreen(chartData: c));
      case 'Predictions':
        _open(PredictionsScreen(chartData: c, profileId: id, name: widget.name));
      case 'Barshphal':
        _open(BarshphalScreen(chartData: c));
      case 'Remedies':
        _open(RemediesScreen(chartData: c));
      case 'Avasthas':
        _open(PlanetConsScreen(chartData: c));
      case 'Interpretation':
        _open(InterpretationScreen(profileId: id));
      case 'Ask AI':
        _open(AiChatScreen(chartData: c, profileId: id, name: widget.name));
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final asc = _chartData.ascendantSidereal;
    final moon = _chartData.planetLongitudes['moon']!;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Horoscope'),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            tooltip: 'Export PDF',
            onPressed: () => PdfService().generateAndShareAstrologicalReport(
              _chartData,
              widget.name,
              birthLabel: _birthLabel,
              place: widget.place,
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(widget.name, style: TextStyle(color: scheme.onSurface, fontSize: 24, fontWeight: FontWeight.bold)),
            Text(_birthLabel, style: TextStyle(color: scheme.secondary.withValues(alpha: 0.8), fontSize: 14)),
            if (widget.place != null)
              Text(widget.place!, style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12), textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(
              'Lagna ${VedicMath.rashis[_chartData.lagnaRashi].name} ${VedicMath.formatDegree(asc)}  •  '
              'Moon ${VedicMath.rashis[VedicMath.rashiIndex(moon)].name}, ${VedicMath.nakshatras[VedicMath.nakshatraIndex(moon)].name}',
              style: TextStyle(color: scheme.onSurface, fontSize: 13),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text('Tap on any house for AI interpretation',
                style: TextStyle(color: scheme.secondary.withValues(alpha: 0.8), fontSize: 12)),
            KundliChart(
              housePlanets: chartLabels(_chartData),
              ascendantSign: _chartData.lagnaRashi + 1,
              onHouseTapped: _handleHouseTapped,
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              alignment: WrapAlignment.center,
              children: _actionButtons.map((btn) => _buildActionButton(btn.$1, btn.$2)).toList(),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(String title, IconData icon) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: 100,
      height: 80,
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: scheme.secondary.withValues(alpha: 0.2)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 4, offset: const Offset(0, 2))],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _handleActionTapped(title),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: scheme.secondary, size: 28),
              const SizedBox(height: 8),
              Text(title,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: scheme.onSurface, fontSize: 11, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }
}
