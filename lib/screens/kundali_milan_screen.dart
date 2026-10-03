import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/database.dart';
import '../core/doshas_math.dart';
import '../core/ephemeris.dart';
import '../core/milan_math.dart';
import '../core/profile_chart.dart';
import '../core/vedic_math.dart';
import '../providers/profile_provider.dart';
import '../widgets/ai_sheet.dart';

class KundaliMilanScreen extends ConsumerStatefulWidget {
  const KundaliMilanScreen({super.key});

  @override
  ConsumerState<KundaliMilanScreen> createState() => _KundaliMilanScreenState();
}

class _KundaliMilanScreenState extends ConsumerState<KundaliMilanScreen> {
  int? _boyId;
  int? _girlId;
  MilanResult? _milanResult;
  ChartData? _boyChart;
  ChartData? _girlChart;
  Profile? _boy;
  Profile? _girl;

  void _analyzeCompatibility(List<Profile> profiles) {
    Profile? find(int? id) {
      for (final p in profiles) {
        if (p.id == id) return p;
      }
      return null;
    }

    final boy = find(_boyId);
    final girl = find(_girlId);
    if (boy == null || girl == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select both profiles')));
      return;
    }

    final boyChart = boy.computeChart();
    final girlChart = girl.computeChart();
    setState(() {
      _boy = boy;
      _girl = girl;
      _boyChart = boyChart;
      _girlChart = girlChart;
      _milanResult = MilanMath.calculateMilan(boyChart.planetLongitudes['moon']!, girlChart.planetLongitudes['moon']!);
    });
  }

  String _moonLabel(ChartData c) {
    final m = c.planetLongitudes['moon']!;
    return '${VedicMath.rashis[VedicMath.rashiIndex(m)].name}, ${VedicMath.nakshatras[VedicMath.nakshatraIndex(m)].name} pada ${VedicMath.pada(m)}';
  }

  DoshaResult? _manglik(ChartData c) => DoshasMath.computeManglik(c.planetLongitudes, c.lagnaRashi);

  static String verdict(double total) {
    if (total < 18) return 'Not recommended (below 18)';
    if (total <= 24) return 'Average match';
    if (total <= 32) return 'Very good match';
    return 'Excellent match';
  }

  void _askAi() {
    final r = _milanResult!;
    final bm = _manglik(_boyChart!);
    final gm = _manglik(_girlChart!);
    final prompt = 'Ashtakoot Guna Milan for ${_boy!.name} (boy) and ${_girl!.name} (girl), computed with the Swiss Ephemeris.\n'
        'Boy Moon: ${_moonLabel(_boyChart!)}. Girl Moon: ${_moonLabel(_girlChart!)}.\n'
        'Total: ${r.total} / 36\n'
        '1. Varna: ${r.varna} / 1\n2. Vashya: ${r.vashya} / 2\n3. Tara: ${r.tara} / 3\n4. Yoni: ${r.yoni} / 4\n'
        '5. Graha Maitri: ${r.maitri} / 5\n6. Gana: ${r.gana} / 6\n7. Bhakoot: ${r.bhakoot} / 7\n8. Nadi: ${r.nadi} / 8\n'
        'Boy Manglik: ${bm?.present == true ? 'Yes (${bm!.severity})' : 'No'}. Girl Manglik: ${gm?.present == true ? 'Yes (${gm!.severity})' : 'No'}.\n\n'
        'As an expert Vedic astrologer, interpret these scores, explain any Nadi, Bhakoot or Manglik dosha and '
        'possible cancellations, and give a final recommendation with remedies if needed.';
    showAiSheet(context, ref, title: 'Compatibility Analysis', prompt: prompt);
  }

  @override
  Widget build(BuildContext context) {
    final profilesAsync = ref.watch(profileListProvider);
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Kundali Milan')),
      body: profilesAsync.when(
        data: (profiles) {
          if (profiles.length < 2) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text('Please create at least two profiles to use matchmaking.', textAlign: TextAlign.center),
              ),
            );
          }
          final boys = profiles.where((p) => p.gender != 'Female').toList();
          final girls = profiles.where((p) => p.gender != 'Male').toList();

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildProfileSelector('Select Boy Profile', _boyId, boys, (id) => setState(() => _boyId = id)),
              const SizedBox(height: 16),
              _buildProfileSelector('Select Girl Profile', _girlId, girls, (id) => setState(() => _girlId = id)),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => _analyzeCompatibility(profiles),
                icon: const Icon(Icons.people_alt),
                label: const Text('Analyze Compatibility'),
              ),
              const SizedBox(height: 24),
              if (_milanResult != null) ...[
                _buildScoreCard(scheme),
                const SizedBox(height: 16),
                _buildManglikCard(scheme),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: _askAi,
                  icon: const Icon(Icons.auto_awesome),
                  label: const Text('Ask AI for a detailed interpretation'),
                ),
              ],
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
      ),
    );
  }

  Widget _buildScoreCard(ColorScheme scheme) {
    final r = _milanResult!;
    String fmt(double v) => v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(1);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Text('Ashtakoot Score', style: TextStyle(color: scheme.secondary, fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('${fmt(r.total)} / 36', style: TextStyle(color: scheme.onSurface, fontSize: 36, fontWeight: FontWeight.bold)),
            Text(verdict(r.total), style: TextStyle(color: r.total < 18 ? scheme.error : Colors.green)),
            const SizedBox(height: 8),
            Text('Boy Moon: ${_moonLabel(_boyChart!)}\nGirl Moon: ${_moonLabel(_girlChart!)}',
                textAlign: TextAlign.center, style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12)),
            const Divider(height: 32),
            _buildScoreRow('Varna (Work/Ego)', r.varna, 1, fmt),
            _buildScoreRow('Vashya (Attraction)', r.vashya, 2, fmt),
            _buildScoreRow('Tara (Destiny)', r.tara, 3, fmt),
            _buildScoreRow('Yoni (Intimacy)', r.yoni, 4, fmt),
            _buildScoreRow('Graha Maitri (Friendship)', r.maitri, 5, fmt),
            _buildScoreRow('Gana (Temperament)', r.gana, 6, fmt),
            _buildScoreRow('Bhakoot (Health/Wealth)', r.bhakoot, 7, fmt),
            _buildScoreRow('Nadi (Genetics)', r.nadi, 8, fmt),
            if (r.hasNadiDosha || r.hasBhakootDosha) ...[
              const SizedBox(height: 12),
              Text(
                [if (r.hasNadiDosha) 'Nadi Dosha present', if (r.hasBhakootDosha) 'Bhakoot Dosha present'].join(' • '),
                style: TextStyle(color: scheme.error, fontWeight: FontWeight.bold),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildManglikCard(ColorScheme scheme) {
    String status(DoshaResult? d) {
      if (d == null) return 'Unknown';
      if (d.present) return 'Manglik (${d.severity})';
      if (d.exceptions.isNotEmpty) return 'Cancelled: ${d.exceptions.join(', ')}';
      return 'Not Manglik';
    }

    final b = _manglik(_boyChart!);
    final g = _manglik(_girlChart!);
    final bothOrNeither = (b?.present ?? false) == (g?.present ?? false);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Manglik Dosha', style: TextStyle(color: scheme.secondary, fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('${_boy!.name}: ${status(b)}'),
            Text('${_girl!.name}: ${status(g)}'),
            const SizedBox(height: 8),
            Text(
              bothOrNeither ? 'Manglik status is balanced.' : 'Only one partner is Manglik — consider remedies.',
              style: TextStyle(color: bothOrNeither ? Colors.green : scheme.error),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScoreRow(String label, double score, double max, String Function(double) fmt) {
    final Color barColor = score == 0 ? Colors.redAccent : (score == max ? Colors.green : Colors.orange);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(child: Text(label, style: const TextStyle(fontSize: 14))),
              const SizedBox(width: 8),
              Text('${fmt(score)} / ${fmt(max)}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 4),
          LinearProgressIndicator(
            value: score / max,
            color: barColor,
            minHeight: 8,
            borderRadius: BorderRadius.circular(4),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileSelector(String hint, int? selected, List<Profile> options, ValueChanged<int?> onChanged) {
    return DropdownButtonFormField<int>(
      decoration: InputDecoration(labelText: hint),
      initialValue: options.any((p) => p.id == selected) ? selected : null,
      isExpanded: true,
      items: options.map((p) => DropdownMenuItem(value: p.id, child: Text(p.name))).toList(),
      onChanged: onChanged,
    );
  }
}
