import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_theme.dart';
import '../providers/profile_provider.dart';
import '../providers/settings_provider.dart';
import '../services/ai_service.dart';
import '../core/ephemeris.dart';
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

      final prompt = "Perform a Vedic Astrology Kundali Milan (Ashtakoota Matchmaking) for the following two profiles:\n\n"
          "Boy Name: ${_boyProfile!.name}\n"
          "Boy Ascendant: ${boyChart.ascendantSidereal}\n"
          "Boy Planets: ${boyChart.planetLongitudes.entries.map((e) => '${e.key}: ${e.value}').join(', ')}\n\n"
          "Girl Name: ${_girlProfile!.name}\n"
          "Girl Ascendant: ${girlChart.ascendantSidereal}\n"
          "Girl Planets: ${girlChart.planetLongitudes.entries.map((e) => '${e.key}: ${e.value}').join(', ')}\n\n"
          "Please provide a detailed compatibility report including Varna, Vashya, Tara, Yoni, Graha Maitri, Gana, Bhakoot, and Nadi kootas, along with an overall conclusion and compatibility percentage.";

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
                if (_isLoading)
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
