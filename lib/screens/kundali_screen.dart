import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../widgets/city_autocomplete.dart';
import 'profile_screen.dart';
import 'kundli_result_screen.dart';
import '../providers/profile_provider.dart';
import 'package:drift/drift.dart' show Value;
import '../core/database.dart';
import '../core/profile_chart.dart';
import '../services/location_service.dart';

class KundaliScreen extends StatelessWidget {
  final int initialTab;
  const KundaliScreen({super.key, this.initialTab = 0});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      initialIndex: initialTab,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Kundali'),
          bottom: TabBar(
            indicatorColor: Theme.of(context).colorScheme.secondary,
            labelColor: Theme.of(context).colorScheme.secondary,
            unselectedLabelColor: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
            tabs: const [
              Tab(text: 'Open Kundali'),
              Tab(text: 'New Kundali'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            ProfileScreen(),
            _NewKundaliTab(),
          ],
        ),
      ),
    );
  }
}

class _NewKundaliTab extends ConsumerStatefulWidget {
  const _NewKundaliTab();

  @override
  ConsumerState<_NewKundaliTab> createState() => _NewKundaliTabState();
}

class _NewKundaliTabState extends ConsumerState<_NewKundaliTab> {
  final _nameController = TextEditingController();
  final _latController = TextEditingController();
  final _lonController = TextEditingController();
  final _tzController = TextEditingController(text: '5.5');
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  String _gender = 'Male';
  bool _saveProfile = true;
  String _placeName = '';
  String? _tzName;
  bool _tzEditedManually = false;
  int _formVersion = 0; // forces the city field to pick up a new initial text

  @override
  void initState() {
    super.initState();
    // The tab may be built after "Edit" was chosen, so read the current value too.
    final editing = ref.read(editProfileProvider);
    if (editing != null) _populate(editing);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _latController.dispose();
    _lonController.dispose();
    _tzController.dispose();
    super.dispose();
  }

  void _populate(Profile p) {
    final b = p.birthWallClock;
    _nameController.text = p.name;
    _selectedDate = DateTime(b.year, b.month, b.day);
    _selectedTime = TimeOfDay(hour: b.hour, minute: b.minute);
    _latController.text = p.lat.toStringAsFixed(4);
    _lonController.text = p.lon.toStringAsFixed(4);
    _tzController.text = _fmtOffset(p.timezone);
    _placeName = p.pob;
    _tzName = p.tzName;
    _gender = p.gender ?? 'Male';
    _tzEditedManually = p.tzName == null;
    _formVersion++;
  }

  void _clear() {
    _nameController.clear();
    _latController.clear();
    _lonController.clear();
    _tzController.text = '5.5';
    _selectedDate = null;
    _selectedTime = null;
    _placeName = '';
    _tzName = null;
    _tzEditedManually = false;
    _formVersion++;
  }

  static String _fmtOffset(double v) => v == v.roundToDouble() ? v.toStringAsFixed(1) : v.toString();

  /// Recomputes the UTC offset from the place's time zone for the chosen date/time (handles DST).
  void _updateOffset() {
    if (_tzEditedManually || _tzName == null || _selectedDate == null) return;
    final t = _selectedTime ?? const TimeOfDay(hour: 12, minute: 0);
    final off = LocationService.utcOffsetFor(
        _tzName, DateTime(_selectedDate!.year, _selectedDate!.month, _selectedDate!.day, t.hour, t.minute));
    if (off != null) _tzController.text = _fmtOffset(off);
  }

  void _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime(2000),
      firstDate: DateTime(1800),
      lastDate: DateTime(2399),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _updateOffset();
      });
    }
  }

  void _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? const TimeOfDay(hour: 12, minute: 0),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        _selectedTime = picked;
        _updateOffset();
      });
    }
  }

  Future<void> _submit() async {
    final lat = double.tryParse(_latController.text.trim());
    final lon = double.tryParse(_lonController.text.trim());
    final tz = double.tryParse(_tzController.text.trim());
    String? error;
    if (_nameController.text.trim().isEmpty) {
      error = 'Please enter a name';
    } else if (_selectedDate == null || _selectedTime == null) {
      error = 'Please select the date and time of birth';
    } else if (lat == null || lon == null || lat.abs() > 90 || lon.abs() > 180) {
      error = 'Please choose a city or enter valid coordinates';
    } else if (tz == null || tz < -14 || tz > 14) {
      error = 'Please enter a valid UTC offset (e.g. 5.5 for IST)';
    }
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
      return;
    }

    final name = _nameController.text.trim();
    final birth = encodeWallClock(_selectedDate!.year, _selectedDate!.month, _selectedDate!.day,
        _selectedTime!.hour, _selectedTime!.minute);
    final pob = _placeName.isNotEmpty ? _placeName : '${lat!.toStringAsFixed(2)}, ${lon!.toStringAsFixed(2)}';

    final notifier = ref.read(profileNotifierProvider.notifier);
    final editing = ref.read(editProfileProvider);
    int? profileId;
    try {
      if (editing != null) {
        await notifier.updateProfile(editing.copyWith(
          name: name,
          dob: birth,
          pob: pob,
          lat: lat!,
          lon: lon!,
          timezone: tz!,
          tzName: Value(_tzName),
          gender: Value(_gender),
        ));
        profileId = editing.id;
        ref.read(editProfileProvider.notifier).setProfile(null);
      } else if (_saveProfile) {
        profileId = await notifier.addProfile(
          name: name,
          dob: birth,
          pob: pob,
          lat: lat!,
          lon: lon!,
          timezone: tz!,
          tzName: _tzName,
          gender: _gender,
        );
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not save profile: $e')));
      return;
    }

    if (!mounted) return;
    final tabController = DefaultTabController.of(context);
    final gender = _gender;
    if (profileId != null) {
      setState(_clear);
      tabController.animateTo(0);
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => KundliResultScreen(
          name: name,
          birth: birth,
          lat: lat!,
          lon: lon!,
          timezone: tz!,
          tzName: _tzName,
          gender: gender,
          profileId: profileId,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<Profile?>(editProfileProvider, (prev, next) {
      if (next != null && next != prev) setState(() => _populate(next));
    });

    final isEditing = ref.watch(editProfileProvider) != null;
    final scheme = Theme.of(context).colorScheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isEditing) ...[
            Row(
              children: [
                Expanded(
                  child: Text('Editing Profile',
                      style: TextStyle(color: scheme.secondary, fontSize: 18, fontWeight: FontWeight.bold)),
                ),
                TextButton(
                  onPressed: () {
                    ref.read(editProfileProvider.notifier).setProfile(null);
                    setState(_clear);
                  },
                  child: const Text('Cancel Edit', style: TextStyle(color: Colors.red)),
                )
              ],
            ),
            const SizedBox(height: 16),
          ],
          TextField(
            controller: _nameController,
            decoration: InputDecoration(labelText: 'Name', prefixIcon: Icon(Icons.person, color: scheme.secondary)),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildPickerCard(
                  'Date of Birth',
                  _selectedDate != null
                      ? '${_selectedDate!.year}-${_selectedDate!.month.toString().padLeft(2, '0')}-${_selectedDate!.day.toString().padLeft(2, '0')}'
                      : 'Select Date',
                  Icons.calendar_today,
                  _pickDate,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildPickerCard(
                  'Time of Birth',
                  _selectedTime != null
                      ? '${_selectedTime!.hour.toString().padLeft(2, '0')}:${_selectedTime!.minute.toString().padLeft(2, '0')}'
                      : 'Select Time',
                  Icons.access_time,
                  _pickTime,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          CityAutocomplete(
            key: ValueKey(_formVersion),
            initialText: _placeName,
            onSelected: (loc) {
              setState(() {
                _placeName = loc.displayName;
                _latController.text = loc.lat.toStringAsFixed(4);
                _lonController.text = loc.lon.toStringAsFixed(4);
                _tzName = loc.tzName;
                _tzEditedManually = false;
                _updateOffset();
              });
            },
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _latController,
                  decoration: const InputDecoration(labelText: 'Latitude', hintText: 'N +, S -'),
                  keyboardType: const TextInputType.numberWithOptions(signed: true, decimal: true),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _lonController,
                  decoration: const InputDecoration(labelText: 'Longitude', hintText: 'E +, W -'),
                  keyboardType: const TextInputType.numberWithOptions(signed: true, decimal: true),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _tzController,
            decoration: InputDecoration(
              labelText: 'UTC Offset at birth (hours)',
              hintText: 'e.g. 5.5 for IST',
              helperMaxLines: 3,
              helperText: _tzName != null && !_tzEditedManually
                  ? 'Calculated from $_tzName (includes daylight saving)'
                  : 'Enter the offset in force at the time of birth',
            ),
            keyboardType: const TextInputType.numberWithOptions(signed: true, decimal: true),
            onChanged: (_) => _tzEditedManually = true,
          ),
          const SizedBox(height: 24),
          Text('Gender', style: TextStyle(color: scheme.onSurface, fontSize: 16)),
          RadioGroup<String>(
            groupValue: _gender,
            onChanged: (val) => setState(() => _gender = val!),
            child: const Row(
              children: [
                Radio<String>(value: 'Male'),
                Text('Male'),
                SizedBox(width: 24),
                Radio<String>(value: 'Female'),
                Text('Female'),
              ],
            ),
          ),
          if (!isEditing) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Checkbox(
                  value: _saveProfile,
                  activeColor: scheme.secondary,
                  onChanged: (val) => setState(() => _saveProfile = val!),
                ),
                const Text('Save this profile on this device'),
              ],
            ),
          ],
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: scheme.secondary,
                foregroundColor: scheme.onSecondary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: _submit,
              child: Text(isEditing ? 'Update Horoscope' : 'Get Horoscope',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildPickerCard(String label, String value, IconData icon, VoidCallback onTap) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(color: scheme.surfaceContainerHighest, borderRadius: BorderRadius.circular(12)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12)),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(icon, color: scheme.secondary, size: 18),
                const SizedBox(width: 8),
                Text(value, style: TextStyle(color: scheme.onSurface, fontSize: 14)),
              ],
            )
          ],
        ),
      ),
    );
  }
}
