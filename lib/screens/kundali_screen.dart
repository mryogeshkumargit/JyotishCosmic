import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../widgets/city_autocomplete.dart';
import '../widgets/kundli_chart.dart';
import 'profile_screen.dart';
import 'kundli_result_screen.dart';
import '../providers/profile_provider.dart';
import '../core/database.dart';

class KundaliScreen extends StatelessWidget {
  const KundaliScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Kundali'),
          bottom: TabBar(
            indicatorColor: Theme.of(context).colorScheme.secondary,
            labelColor: Theme.of(context).colorScheme.secondary,
            unselectedLabelColor: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            tabs: const [
              Tab(text: 'Open Kundali'),
              Tab(text: 'New Kundali'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            const ProfileScreen(), // The existing profile list screen
            _NewKundaliTab(),
          ],
        ),
      ),
    );
  }
}

class _NewKundaliTab extends ConsumerStatefulWidget {
  @override
  ConsumerState<_NewKundaliTab> createState() => _NewKundaliTabState();
}

class _NewKundaliTabState extends ConsumerState<_NewKundaliTab> {
  final TextEditingController _nameController = TextEditingController();
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  String _gender = 'Male';
  bool _saveProfile = true;
  
  double? _selectedLat;
  double? _selectedLon;
  double _selectedTimezone = 5.5;

  void _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2000),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  void _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) setState(() => _selectedTime = picked);
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<Profile?>(editProfileProvider, (prev, next) {
      if (next != null && next != prev) {
        setState(() {
          _nameController.text = next.name;
          _selectedDate = next.dob;
          _selectedTime = TimeOfDay.fromDateTime(next.dob);
          _selectedLat = next.lat;
          _selectedLon = next.lon;
          _selectedTimezone = next.timezone;
          // _gender could be mapped if it was in DB, defaults to Male for now
        });
      }
    });

    final isEditing = ref.watch(editProfileProvider) != null;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isEditing) ...[
             Row(
               mainAxisAlignment: MainAxisAlignment.spaceBetween,
               children: [
                 Text('Editing Profile', style: TextStyle(color: Theme.of(context).colorScheme.secondary, fontSize: 18, fontWeight: FontWeight.bold)),
                 TextButton(
                   onPressed: () {
                     ref.read(editProfileProvider.notifier).setProfile(null);
                     setState(() {
                       _nameController.clear();
                       _selectedDate = null;
                       _selectedTime = null;
                       _selectedLat = null;
                       _selectedLon = null;
                     });
                   },
                   child: const Text('Cancel Edit', style: TextStyle(color: Colors.red)),
                 )
               ],
             ),
             const SizedBox(height: 16),
          ],
          _buildTextField('Name', _nameController, Icons.person),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _buildPickerCard('Date of Birth', _selectedDate != null ? _selectedDate!.toLocal().toString().split(' ')[0] : 'Select Date', Icons.calendar_today, _pickDate)),
              const SizedBox(width: 16),
              Expanded(child: _buildPickerCard('Time of Birth', _selectedTime?.format(context) ?? 'Select Time', Icons.access_time, _pickTime)),
            ],
          ),
          const SizedBox(height: 16),
          CityAutocomplete(
            onSelected: (loc) {
              setState(() {
                _selectedLat = loc.lat;
                _selectedLon = loc.lon;
              });
            },
          ),
          if (_selectedLat != null && _selectedLon != null)
            Padding(
              padding: const EdgeInsets.only(top: 8, left: 12, bottom: 8),
              child: Text(
                'Coordinates: ${_selectedLat!.toStringAsFixed(4)}, ${_selectedLon!.toStringAsFixed(4)}',
                style: TextStyle(color: Theme.of(context).colorScheme.secondary, fontSize: 12),
              ),
            ),
          const SizedBox(height: 16),
          TextField(
            decoration: const InputDecoration(
              labelText: 'Timezone (UTC Offset)',
              hintText: 'e.g. 5.5 for IST',
            ),
            keyboardType: const TextInputType.numberWithOptions(signed: true, decimal: true),
            controller: TextEditingController(text: _selectedTimezone.toString()),
            onChanged: (val) {
              if (double.tryParse(val) != null) {
                _selectedTimezone = double.parse(val);
              }
            },
          ),
          const SizedBox(height: 24),
          Text('Gender', style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 16)),
          Row(
            children: [
              Radio<String>(
                value: 'Male',
                groupValue: _gender,
                activeColor: Theme.of(context).colorScheme.secondary,
                onChanged: (val) => setState(() => _gender = val!),
              ),
              Text('Male', style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color)),
              const SizedBox(width: 24),
              Radio<String>(
                value: 'Female',
                groupValue: _gender,
                activeColor: Theme.of(context).colorScheme.secondary,
                onChanged: (val) => setState(() => _gender = val!),
              ),
              Text('Female', style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color)),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Checkbox(
                value: _saveProfile,
                activeColor: Theme.of(context).colorScheme.secondary,
                onChanged: (val) => setState(() => _saveProfile = val!),
              ),
              Text('Save this profile', style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color)),
            ],
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.secondary,
                foregroundColor: Theme.of(context).colorScheme.onSecondary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () {
                if (_nameController.text.isNotEmpty && _selectedDate != null && _selectedTime != null && _selectedLat != null) {
                  final combinedDateTime = DateTime(
                    _selectedDate!.year,
                    _selectedDate!.month,
                    _selectedDate!.day,
                    _selectedTime!.hour,
                    _selectedTime!.minute,
                  );
                  final editingProfile = ref.read(editProfileProvider);
                  if (editingProfile != null) {
                    final updatedProfile = editingProfile.copyWith(
                      name: _nameController.text,
                      dob: combinedDateTime,
                      pob: '${_selectedLat!.toStringAsFixed(2)}, ${_selectedLon!.toStringAsFixed(2)}',
                      lat: _selectedLat!,
                      lon: _selectedLon!,
                      timezone: _selectedTimezone,
                    );
                    ref.read(profileNotifierProvider.notifier).updateProfile(updatedProfile);
                    ref.read(editProfileProvider.notifier).setProfile(null);
                  } else if (_saveProfile) {
                    ref.read(profileNotifierProvider.notifier).addProfile(
                      _nameController.text,
                      combinedDateTime,
                      '${_selectedLat!.toStringAsFixed(2)}, ${_selectedLon!.toStringAsFixed(2)}',
                      _selectedLat!,
                      _selectedLon!,
                      _selectedTimezone
                    );
                  }
                  
                  final nameToPass = editingProfile?.name ?? _nameController.text;
                  final timeToPass = _selectedTime!;
                  final latToPass = _selectedLat!;
                  final lonToPass = _selectedLon!;
                  final tzToPass = _selectedTimezone;

                  // Clear form after generating/saving
                  if (_saveProfile) {
                    _nameController.clear();
                    setState(() {
                      _selectedDate = null;
                      _selectedTime = null;
                      _selectedLat = null;
                      _selectedLon = null;
                    });
                  }
                  
                  // Switch to Open Kundali tab
                  DefaultTabController.of(context).animateTo(0);
                  
                  Navigator.push(context, MaterialPageRoute(builder: (_) => KundliResultScreen(
                    name: nameToPass,
                    date: combinedDateTime,
                    time: timeToPass,
                    lat: latToPass,
                    lon: lonToPass,
                    timezone: tzToPass,
                  )));
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill all required fields and select a city from the suggestions')));
                }
              },
              child: Text(ref.watch(editProfileProvider) != null ? 'Update Horoscope' : 'Get Horoscope', style: TextStyle(color: Theme.of(context).colorScheme.onSecondary, fontSize: 18, fontWeight: FontWeight.bold)),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, IconData icon) {
    return TextField(
      controller: controller,
      style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7)),
        prefixIcon: Icon(icon, color: Theme.of(context).colorScheme.secondary),
        filled: true,
        fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      ),
    );
  }

  Widget _buildPickerCard(String label, String value, IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7), fontSize: 12)),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(icon, color: Theme.of(context).colorScheme.secondary, size: 18),
                const SizedBox(width: 8),
                Text(value, style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color, fontSize: 14)),
              ],
            )
          ],
        ),
      ),
    );
  }
}
