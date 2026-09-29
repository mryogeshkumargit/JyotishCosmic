import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_theme.dart';
import '../providers/profile_provider.dart';
import '../providers/settings_provider.dart';
import '../services/ai_service.dart';
import '../core/ephemeris.dart';
import '../core/milan_math.dart';
import '../core/database.dart';

class KundaliMilanScreen extends ConsumerStatefulWidget {
  const KundaliMilanScreen({super.key});

  @override
  ConsumerState<KundaliMilanScreen> createState() => _KundaliMilanScreenState();
}

class _KundaliMilanScreenState extends ConsumerState<KundaliMilanScreen> {
  Profile? _boyProfile;
  Profile? _girlProfile;
  bool _isLoading = false;
  String? _resultText;
  MilanResult? _milanResult;

  void _analyzeCompatibility() async {
    if (_boyProfile == null || _girlProfile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select both profiles')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _resultText = null;
      _milanResult = null;
    });

    try {
      final boyChart = Ephemeris.computeChart(
        _boyProfile!.dob.year, _boyProfile!.dob.month, _boyProfile!.dob.day,
        _boyProfile!.dob.hour.toDouble(), _boyProfile!.dob.minute.toDouble(),
        _boyProfile!.lat, _boyProfile!.lon, _boyProfile!.timezone,
      );

      final girlChart = Ephemeris.computeChart(
        _girlProfile!.dob.year, _girlProfile!.dob.month, _girlProfile!.dob.day,
        _girlProfile!.dob.hour.toDouble(), _girlProfile!.dob.minute.toDouble(),
        _girlProfile!.lat, _girlProfile!.lon, _girlProfile!.timezone,
      );

      final milanResult = MilanMath.calculateFromCharts(boyChart, girlChart);
      
      setState(() {
        _milanResult = milanResult;
      });

      final prompt = "I have performed an exact Vedic Ashtakoot Guna Milan for ${_boyProfile!.name} and ${_girlProfile!.name}. "
          "Out of 36 possible points, they scored ${milanResult.total}.\n\n"
          "Here is the breakdown of their scores:\n"
          "1. Varna (Work/Ego): ${milanResult.varna} / 1\n"
          "2. Vashya (Attraction): ${milanResult.vashya} / 2\n"
          "3. Tara (Destiny): ${milanResult.tara} / 3\n"
          "4. Yoni (Intimacy): ${milanResult.yoni} / 4\n"
          "5. Graha Maitri (Friendship): ${milanResult.maitri} / 5\n"
          "6. Gana (Temperament): ${milanResult.gana} / 6\n"
          "7. Bhakoot (Health/Wealth): ${milanResult.bhakoot} / 7\n"
          "8. Nadi (Genetic/Spiritual): ${milanResult.nadi} / 8\n"
          "Details: ${milanResult.details.entries.map((e) => '${e.key}: ${e.value}').join(', ')}\n"
          "Doshas: ${milanResult.doshas.isEmpty ? 'none' : milanResult.doshas.map((d) => '${d.name} (${d.cancelled ? 'cancelled' : 'present'}: ${d.detail})').join('; ')}\n\n"
          "As an expert Vedic Astrologer, please interpret these specific scores. "
          "Explain why they did well or poorly in key areas, identify any critical doshas (like Nadi or Bhakoot dosha), "
          "and provide a final recommendation or astrological remedies if necessary.";

      final settings = ref.read(settingsProvider);
      final response = await AiService.interpret(settings, prompt);

      setState(() {
        _resultText = response;
      });
    } catch (e) {
      setState(() {
        _resultText = "Error during analysis: $e";
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final profilesAsync = ref.watch(profileListProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Kundali Milan')),
      body: profilesAsync.when(
        data: (profiles) {
          if (profiles.isEmpty) {
            return const Center(child: Text('Please create profiles first to use Matchmaking.', style: TextStyle(color: AppTheme.starWhite)));
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildProfileSelector('Select Boy Profile', _boyProfile, profiles, (p) => setState(() => _boyProfile = p)),
                const SizedBox(height: 16),
                _buildProfileSelector('Select Girl Profile', _girlProfile, profiles, (p) => setState(() => _girlProfile = p)),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: _isLoading ? null : _analyzeCompatibility,
                  icon: const Icon(Icons.people_alt, color: AppTheme.cosmicBlack),
                  label: const Text('Analyze Compatibility', style: TextStyle(color: AppTheme.cosmicBlack)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.saffronAccent,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 24),
                
                if (_milanResult != null) ...[
                  _buildScoreCard(),
                  const SizedBox(height: 24),
                ],

                if (_isLoading && _milanResult != null)
                  const Center(
                    child: Column(
                      children: [
                        CircularProgressIndicator(color: AppTheme.saffronAccent),
                        SizedBox(height: 16),
                        Text('AI is interpreting the results...', style: TextStyle(color: AppTheme.saffronAccent)),
                      ],
                    ),
                  )
                else if (_isLoading)
                  const Center(child: CircularProgressIndicator(color: AppTheme.saffronAccent))
                else if (_resultText != null)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.secondaryMystic.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.saffronAccent.withOpacity(0.5)),
                    ),
                    child: Text(_resultText!, style: const TextStyle(color: AppTheme.starWhite, fontSize: 16, height: 1.5)),
                  ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
      ),
    );
  }

  Widget _buildScoreCard() {
    final r = _milanResult!;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.primaryMystic,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.saffronAccent),
      ),
      child: Column(
        children: [
          Text(
            'Ashtakoot Score',
            style: TextStyle(color: Theme.of(context).colorScheme.secondary, fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            '${_fmt(r.total)} / 36',
            style: const TextStyle(color: AppTheme.starWhite, fontSize: 36, fontWeight: FontWeight.bold),
          ),
          const Divider(color: AppTheme.primaryMystic, height: 32),
          _buildScoreRow('Varna (Work/Ego)', r.varna, 1),
          _buildScoreRow('Vashya (Attraction)', r.vashya, 2),
          _buildScoreRow('Tara (Destiny)', r.tara, 3),
          _buildScoreRow('Yoni (Intimacy)', r.yoni, 4),
          _buildScoreRow('Graha Maitri (Friendship)', r.maitri, 5),
          _buildScoreRow('Gana (Temperament)', r.gana, 6),
          _buildScoreRow('Bhakoot (Health/Wealth)', r.bhakoot, 7),
          _buildScoreRow('Nadi (Genetics)', r.nadi, 8),
          const SizedBox(height: 12),
          Text(r.verdict, style: const TextStyle(color: AppTheme.saffronAccent, fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(
            'Boy: ${r.details['boyRashi']} • ${r.details['boyNakshatra']} • ${r.details['boyGana']} • ${r.details['boyNadi']}\n'
            'Girl: ${r.details['girlRashi']} • ${r.details['girlNakshatra']} • ${r.details['girlGana']} • ${r.details['girlNadi']}',
            style: const TextStyle(color: AppTheme.starWhite, fontSize: 12, height: 1.5),
          ),
          ...r.doshas.map((d) => Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(d.cancelled ? Icons.check_circle_outline : Icons.warning_amber,
                        size: 18, color: d.cancelled ? Colors.green : Colors.redAccent),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text('${d.name}${d.cancelled ? ' — cancelled' : ''}: ${d.detail}',
                          style: const TextStyle(color: AppTheme.starWhite, fontSize: 13)),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  static String _fmt(double v) => v == v.roundToDouble() ? v.toInt().toString() : v.toStringAsFixed(1);

  Widget _buildScoreRow(String label, double score, double max) {
    Color barColor = score == 0 ? Colors.redAccent : (score == max ? Colors.green : AppTheme.saffronAccent);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(flex: 2, child: Text(label, style: const TextStyle(color: AppTheme.starWhite, fontSize: 14))),
          Expanded(
            flex: 3,
            child: LinearProgressIndicator(
              value: score / max,
              backgroundColor: AppTheme.primaryMystic,
              color: barColor,
              minHeight: 8,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          SizedBox(width: 56, child: Text('${_fmt(score)} / ${_fmt(max)}', textAlign: TextAlign.right, style: const TextStyle(color: AppTheme.starWhite, fontSize: 14))),
        ],
      ),
    );
  }

  Widget _buildProfileSelector(String hint, Profile? selected, List<Profile> allProfiles, ValueChanged<Profile?> onChanged) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.primaryMystic,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.saffronAccent.withOpacity(0.3)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<Profile>(
          isExpanded: true,
          hint: Text(hint, style: TextStyle(color: AppTheme.starWhite.withOpacity(0.5))),
          value: selected,
          dropdownColor: AppTheme.primaryMystic,
          icon: const Icon(Icons.arrow_drop_down, color: AppTheme.saffronAccent),
          items: allProfiles.map((p) {
            return DropdownMenuItem(
              value: p,
              child: Text(p.name, style: const TextStyle(color: AppTheme.starWhite)),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}
