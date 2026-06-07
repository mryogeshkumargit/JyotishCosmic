import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_theme.dart';
import '../providers/profile_provider.dart';
import '../providers/auth_provider.dart';
import 'login_screen.dart';
import 'home_screen.dart';
import 'package:dio/dio.dart';
import 'kundli_result_screen.dart';
import '../widgets/city_autocomplete.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profilesAsync = ref.watch(profileListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profiles'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              ref.read(authProvider.notifier).logout();
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
            },
          )
        ],
      ),
      body: profilesAsync.when(
        data: (profiles) {
          if (profiles.isEmpty) {
            return Center(
              child: Text('No profiles found. Tap + to create one.', 
                style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
            );
          }
          return ListView.builder(
            itemCount: profiles.length,
            itemBuilder: (context, index) {
              final profile = profiles[index];
              return Dismissible(
                key: Key(profile.id.toString()),
                direction: DismissDirection.endToStart,
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20),
                  color: Colors.red,
                  child: const Icon(Icons.delete, color: Colors.white),
                ),
                onDismissed: (direction) {
                  ref.read(profileNotifierProvider.notifier).deleteProfile(profile);
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${profile.name} deleted')));
                },
                child: Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                      child: Icon(Icons.person, color: Theme.of(context).colorScheme.secondary),
                    ),
                    title: Text(profile.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(profile.pob),
                    trailing: PopupMenuButton<String>(
                      icon: Icon(Icons.more_vert, color: Theme.of(context).colorScheme.onSurface),
                      color: Theme.of(context).cardColor,
                      onSelected: (value) {
                        if (value == 'edit') {
                          ref.read(editProfileProvider.notifier).setProfile(profile);
                          DefaultTabController.of(context).animateTo(1);
                        } else if (value == 'delete') {
                          showDialog(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                              title: Text('Delete Profile', style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
                              content: Text('Are you sure you want to delete ${profile.name}?', style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
                              actions: [
                                TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Cancel', style: TextStyle(color: Theme.of(context).colorScheme.onSurface))),
                                TextButton(
                                  onPressed: () {
                                    ref.read(profileNotifierProvider.notifier).deleteProfile(profile);
                                    Navigator.pop(ctx);
                                  },
                                  child: const Text('Delete', style: TextStyle(color: Colors.red)),
                                ),
                              ],
                            ),
                          );
                        }
                      },
                      itemBuilder: (context) => [
                        PopupMenuItem(value: 'edit', child: Text('Edit', style: TextStyle(color: Theme.of(context).colorScheme.onSurface))),
                        const PopupMenuItem(value: 'delete', child: Text('Delete', style: TextStyle(color: Colors.red))),
                      ],
                    ),
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => KundliResultScreen(
                        name: profile.name,
                        date: profile.dob,
                        time: TimeOfDay.fromDateTime(profile.dob),
                        lat: profile.lat,
                        lon: profile.lon,
                        timezone: profile.timezone,
                        profileId: profile.id,
                      )));
                    },
                  ),
                ),
              );
            },
          );
        },
        loading: () => Center(child: CircularProgressIndicator(color: Theme.of(context).colorScheme.secondary)),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Theme.of(context).colorScheme.secondary,
        foregroundColor: Theme.of(context).colorScheme.onSecondary,
        onPressed: () {
          // Open Add Profile Dialog/Screen
          _showAddProfileDialog(context, ref);
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showAddProfileDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) {
        return const _AddProfileDialog();
      },
    );
  }
}

class _AddProfileDialog extends ConsumerStatefulWidget {
  const _AddProfileDialog();

  @override
  ConsumerState<_AddProfileDialog> createState() => _AddProfileDialogState();
}

class _AddProfileDialogState extends ConsumerState<_AddProfileDialog> {
  final _nameController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();
  bool _isSaving = false;
  
  double? _selectedLat;
  double? _selectedLon;
  String _selectedPob = '';
  double _selectedTimezone = 5.5; // Default to IST (+5.5)

  void _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(1900),
      lastDate: DateTime(2100),
    );
    if (date != null) {
      setState(() {
        _selectedDate = date;
      });
    }
  }

  void _pickTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (time != null) {
      setState(() {
        _selectedTime = time;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      title: Text('Add Profile', style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: _nameController, decoration: const InputDecoration(labelText: 'Name')),
            const SizedBox(height: 12),
            ListTile(
              title: const Text('Date of Birth'),
              subtitle: Text(_selectedDate.toIso8601String().split('T')[0]),
              trailing: const Icon(Icons.calendar_today),
              onTap: _pickDate,
            ),
            ListTile(
              title: const Text('Time of Birth'),
              subtitle: Text(_selectedTime.format(context)),
              trailing: const Icon(Icons.access_time),
              onTap: _pickTime,
            ),
            const SizedBox(height: 12),
            CityAutocomplete(
              onSelected: (loc) {
                setState(() {
                  _selectedLat = loc.lat;
                  _selectedLon = loc.lon;
                  _selectedPob = loc.displayName;
                });
              },
            ),
            if (_selectedLat != null && _selectedLon != null)
              Padding(
                padding: const EdgeInsets.only(top: 8, left: 12, bottom: 8),
                child: Text(
                  'Coordinates: \${_selectedLat!.toStringAsFixed(4)}, \${_selectedLon!.toStringAsFixed(4)}',
                  style: TextStyle(color: Theme.of(context).colorScheme.secondary, fontSize: 12),
                ),
              ),
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
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancel', style: TextStyle(color: Theme.of(context).colorScheme.onSurface))),
        _isSaving 
          ? const CircularProgressIndicator()
          : ElevatedButton(
          onPressed: () async {
            if (_nameController.text.isNotEmpty && _selectedLat != null && _selectedLon != null) {
              setState(() { _isSaving = true; });

              final dob = DateTime(
                _selectedDate.year,
                _selectedDate.month,
                _selectedDate.day,
                _selectedTime.hour,
                _selectedTime.minute,
              );
              
              ref.read(profileNotifierProvider.notifier).addProfile(
                _nameController.text, 
                dob, 
                _selectedPob, 
                _selectedLat!, 
                _selectedLon!,
                _selectedTimezone,
              );
              
              if (mounted) Navigator.pop(context);
            } else {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a valid location.')));
            }
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}
