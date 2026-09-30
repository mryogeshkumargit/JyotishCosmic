import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/database.dart';
import '../core/profile_chart.dart';
import '../providers/profile_provider.dart';
import 'kundli_result_screen.dart';

/// List of saved profiles (stored only on this device).
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  Future<bool> _confirmDelete(BuildContext context, WidgetRef ref, Profile profile) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Profile'),
        content: Text('Are you sure you want to delete ${profile.name}? This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(profileNotifierProvider.notifier).deleteProfile(profile);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${profile.name} deleted')));
      }
    }
    return confirmed == true;
  }

  void _goToNewTab(BuildContext context) => DefaultTabController.maybeOf(context)?.animateTo(1);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profilesAsync = ref.watch(profileListProvider);
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: profilesAsync.when(
        data: (profiles) {
          if (profiles.isEmpty) {
            return Center(
              child: Text('No profiles found. Tap + to create one.',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(color: scheme.onSurfaceVariant)),
            );
          }
          return ListView.builder(
            itemCount: profiles.length,
            itemBuilder: (context, index) {
              final profile = profiles[index];
              final b = profile.birthWallClock;
              final when = '${b.year}-${b.month.toString().padLeft(2, '0')}-${b.day.toString().padLeft(2, '0')} '
                  '${b.hour.toString().padLeft(2, '0')}:${b.minute.toString().padLeft(2, '0')}';
              return Dismissible(
                key: ValueKey(profile.id),
                direction: DismissDirection.endToStart,
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20),
                  color: Colors.red,
                  child: const Icon(Icons.delete, color: Colors.white),
                ),
                // Delete here and return false: the list refreshes from the database
                // stream, so the Dismissible never has to animate out.
                confirmDismiss: (_) async {
                  await _confirmDelete(context, ref, profile);
                  return false;
                },
                child: Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: scheme.primaryContainer,
                      child: Text(profile.name.isNotEmpty ? profile.name[0].toUpperCase() : '?',
                          style: TextStyle(color: scheme.onPrimaryContainer)),
                    ),
                    title: Text(profile.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('$when\n${profile.pob}', maxLines: 2, overflow: TextOverflow.ellipsis),
                    isThreeLine: true,
                    trailing: PopupMenuButton<String>(
                      icon: Icon(Icons.more_vert, color: scheme.onSurface),
                      onSelected: (value) {
                        if (value == 'edit') {
                          ref.read(editProfileProvider.notifier).setProfile(profile);
                          _goToNewTab(context);
                        } else if (value == 'delete') {
                          _confirmDelete(context, ref, profile);
                        }
                      },
                      itemBuilder: (context) => const [
                        PopupMenuItem(value: 'edit', child: Text('Edit')),
                        PopupMenuItem(value: 'delete', child: Text('Delete', style: TextStyle(color: Colors.red))),
                      ],
                    ),
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => KundliResultScreen.forProfile(profile)));
                    },
                  ),
                ),
              );
            },
          );
        },
        loading: () => Center(child: CircularProgressIndicator(color: scheme.secondary)),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: scheme.secondary,
        foregroundColor: scheme.onSecondary,
        tooltip: 'New Kundali',
        onPressed: () {
          ref.read(editProfileProvider.notifier).setProfile(null);
          _goToNewTab(context);
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
