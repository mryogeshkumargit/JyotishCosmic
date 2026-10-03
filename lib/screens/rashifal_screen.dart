import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/chart_summary.dart';
import '../core/database.dart';
import '../core/profile_chart.dart';
import '../core/transit_math.dart';
import '../core/vedic_math.dart';
import '../providers/profile_provider.dart';
import '../providers/settings_provider.dart';
import '../services/ai_service.dart';
import '../widgets/ai_sheet.dart';

class RashifalScreen extends ConsumerStatefulWidget {
  const RashifalScreen({super.key});

  @override
  ConsumerState<RashifalScreen> createState() => _RashifalScreenState();
}

class _RashifalScreenState extends ConsumerState<RashifalScreen> {
  bool _isLoading = false;
  String? _resultText;
  String? _error;
  String? _activeTab;
  int? _selectedId;

  Future<void> _fetchRashifal(String timeFrame, Profile profile) async {
    setState(() {
      _isLoading = true;
      _resultText = null;
      _error = null;
      _activeTab = timeFrame;
    });

    try {
      final chartData = profile.computeChart();
      final moonSid = chartData.planetLongitudes['moon']!;
      final moonSign = VedicMath.rashis[VedicMath.rashiIndex(moonSid)].name;
      final nakshatra = VedicMath.nakshatras[VedicMath.nakshatraIndex(moonSid)].name;
      final transits = TransitMath.compute(chartData);
      final today = DateTime.now();

      final prompt = 'Today is ${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}. '
          'Generate a Vedic $timeFrame horoscope (Rashifal) for a person whose Moon sign (Chandra Rashi) is $moonSign '
          '(nakshatra $nakshatra). Use the current planetary transits counted from the Moon sign below. '
          'Cover career, wealth, love and health for this $timeFrame period.\n\n'
          'Current transits (sidereal):\n'
          '${transits.map((t) => '- ${t.planetData.name} in ${t.rashiData.name}${t.retrograde ? ' (retrograde)' : ''}, house ${t.houseFromMoon} from Moon').join('\n')}\n\n'
          'Natal chart:\n${ChartSummary.describe(chartData, name: profile.name)}';

      final response = await AiService.interpret(ref.read(settingsProvider), prompt, onPartial: (partial) {
        if (mounted) setState(() => _resultText = partial);
      });
      if (mounted) setState(() => _resultText = response);
    } catch (e) {
      if (mounted) setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final profilesAsync = ref.watch(profileListProvider);
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Rashifal')),
      body: profilesAsync.when(
        data: (profiles) {
          if (profiles.isEmpty) {
            return const Center(child: Text('Create a profile to view your Rashifal.'));
          }
          Profile? selected;
          for (final p in profiles) {
            if (p.id == _selectedId) selected = p;
          }
          final Profile profile = selected ?? profiles.first;
          final moonSid = profile.computeChart().planetLongitudes['moon']!;

          return Column(
            children: [
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: DropdownButtonFormField<int>(
                  decoration: const InputDecoration(labelText: 'Select Profile'),
                  initialValue: profile.id,
                  isExpanded: true,
                  items: profiles.map((p) => DropdownMenuItem<int>(value: p.id, child: Text(p.name))).toList(),
                  onChanged: _isLoading
                      ? null
                      : (val) => setState(() {
                            _selectedId = val;
                            _resultText = null;
                            _error = null;
                            _activeTab = null;
                          }),
                ),
              ),
              const SizedBox(height: 12),
              Text('Moon sign: ${VedicMath.rashis[VedicMath.rashiIndex(moonSid)].name} '
                  '(${VedicMath.rashis[VedicMath.rashiIndex(moonSid)].hindi})',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                children: [
                  for (final tab in ['Daily', 'Weekly', 'Monthly'])
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: ElevatedButton(
                      onPressed: _isLoading ? null : () => _fetchRashifal(tab, profile),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
                        backgroundColor: _activeTab == tab ? scheme.primary : scheme.surfaceContainerHighest,
                        foregroundColor: _activeTab == tab ? scheme.onPrimary : scheme.onSurface,
                      ),
                      child: FittedBox(fit: BoxFit.scaleDown, child: Text(tab)),
                    ),
                      ),
                    ),
                ],
              ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: _isLoading && _resultText == null
                    ? Center(child: CircularProgressIndicator(color: scheme.primary))
                    : _error != null && _resultText == null
                        ? SingleChildScrollView(
                            padding: const EdgeInsets.all(24),
                            child: Text(_error!, textAlign: TextAlign.center, style: TextStyle(color: scheme.error)))
                        : _resultText != null
                            ? SingleChildScrollView(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    if (_isLoading) LinearProgressIndicator(color: scheme.primary, minHeight: 2),
                                    Container(
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: scheme.surfaceContainerHighest,
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(color: scheme.outline),
                                      ),
                                      child: AiMarkdown(_resultText!),
                                    ),
                                    if (_error != null)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 12),
                                        child: Text(_error!, style: TextStyle(color: scheme.error)),
                                      ),
                                  ],
                                ),
                              )
                            : Center(
                                child: Text('Select a timeframe to view the horoscope.',
                                    style: TextStyle(color: scheme.onSurfaceVariant))),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
      ),
    );
  }
}
