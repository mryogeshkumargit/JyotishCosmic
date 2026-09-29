import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/profile_provider.dart';
import '../providers/settings_provider.dart';
import '../services/ai_service.dart';
import '../core/ephemeris.dart';
import '../core/database.dart';

class RashifalScreen extends ConsumerStatefulWidget {
  const RashifalScreen({super.key});

  @override
  ConsumerState<RashifalScreen> createState() => _RashifalScreenState();
}

class _RashifalScreenState extends ConsumerState<RashifalScreen> {
  bool _isLoading = false;
  String? _resultText;
  String _activeTab = 'Daily';
  Profile? _selectedProfile;
  bool _initialized = false;

  void _fetchRashifal(String timeFrame, Profile profile) async {
    setState(() {
      _isLoading = true;
      _resultText = null;
      _activeTab = timeFrame;
    });

    try {
      final chartData = Ephemeris.computeChart(
        profile.dob.year, profile.dob.month, profile.dob.day,
        profile.dob.hour.toDouble(), profile.dob.minute.toDouble(),
        profile.lat, profile.lon, profile.timezone,
      );

      final moonLon = chartData.planetLongitudes['moon'] ?? 0;
      final moonSignIndex = (moonLon / 30).floor();
      final signs = ['Aries', 'Taurus', 'Gemini', 'Cancer', 'Leo', 'Virgo', 'Libra', 'Scorpio', 'Sagittarius', 'Capricorn', 'Aquarius', 'Pisces'];
      final moonSign = signs[moonSignIndex];

      final prompt = "Generate a highly accurate Vedic Astrology $timeFrame Horoscope (Rashifal) for a person whose Moon Sign (Chandra Rashi) is $moonSign. "
          "Their Ascendant (Lagna) is ${signs[chartData.lagnaRashi]}. "
          "Provide insights on Career, Wealth, Love, and Health for this $timeFrame period. Format beautifully in Markdown.";

      final settings = ref.read(settingsProvider);
      final response = await AiService.interpret(settings, prompt);

      setState(() {
        _resultText = response;
      });
    } catch (e) {
      setState(() {
        _resultText = "Error fetching horoscope: $e";
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
      appBar: AppBar(title: const Text('Rashifal (Horoscope)')),
      body: profilesAsync.when(
        data: (profiles) {
          if (profiles.isEmpty) {
            return Center(child: Text('Create a profile to view your Rashifal.', style: TextStyle(color: Theme.of(context).colorScheme.onSurface)));
          }

          if (!_initialized) {
            _selectedProfile = profiles.first;
            _initialized = true;
          }

          return Column(
            children: [
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: DropdownButtonFormField<Profile>(
                  decoration: const InputDecoration(labelText: 'Select Profile'),
                  value: _selectedProfile,
                  isExpanded: true,
                  items: profiles.map((p) {
                    return DropdownMenuItem<Profile>(
                      value: p,
                      child: Text(p.name, style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
                    );
                  }).toList(),
                  onChanged: (val) {
                    setState(() {
                      _selectedProfile = val;
                      _resultText = null; // Clear previous results on profile change
                    });
                  },
                ),
              ),
              const SizedBox(height: 16),
              Text('Horoscope for ${_selectedProfile?.name ?? ''}', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildTabButton('Daily', _selectedProfile!),
                  _buildTabButton('Weekly', _selectedProfile!),
                  _buildTabButton('Monthly', _selectedProfile!),
                ],
              ),
              const SizedBox(height: 24),
              Expanded(
                child: _isLoading
                    ? Center(child: CircularProgressIndicator(color: Theme.of(context).colorScheme.primary))
                    : _resultText != null
                        ? SingleChildScrollView(
                            padding: const EdgeInsets.all(16),
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: Theme.of(context).colorScheme.outline),
                              ),
                              child: Text(_resultText!, style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 16, height: 1.5)),
                            ),
                          )
                        : Center(child: Text('Select a timeframe to view your horoscope.', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant))),
              )
            ],
          );
        },
        loading: () => Center(child: CircularProgressIndicator(color: Theme.of(context).colorScheme.primary)),
        error: (err, _) => Center(child: Text('Error: $err')),
      ),
    );
  }

  Widget _buildTabButton(String title, Profile profile) {
    final isActive = _activeTab == title;
    return ElevatedButton(
      onPressed: () => _fetchRashifal(title, profile),
      style: ElevatedButton.styleFrom(
        backgroundColor: isActive ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.surfaceContainerHighest,
        foregroundColor: isActive ? Theme.of(context).colorScheme.onPrimary : Theme.of(context).colorScheme.onSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: Theme.of(context).colorScheme.outline),
        ),
      ),
      child: Text(title),
    );
  }
}
