import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/profile_provider.dart';
import '../providers/sync_provider.dart';
import 'kundali_screen.dart';
import 'chat_screen.dart';
import 'settings_screen.dart';
import 'kundali_milan_screen.dart';
import 'rashifal_screen.dart';
import 'report_screen.dart';
import 'tabs/interpretation_screen.dart';
import 'knowledge_base_screen.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  int _currentIndex = 0;

  void _selectProfileAndNavigate(BuildContext context, Widget Function(int profileId) builder) {
    final profilesAsync = ref.read(profileListProvider);
    final profiles = profilesAsync.value ?? const [];

    if (profiles.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please create a profile first.')));
      return;
    }

    if (profiles.length == 1) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => builder(profiles.first.id)));
      return;
    }

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Select Profile', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 16),
              ...profiles.map((p) => ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
                      child: Text(p.name[0].toUpperCase(), style: TextStyle(color: Theme.of(context).colorScheme.primary)),
                    ),
                    title: Text(p.name, style: Theme.of(context).textTheme.titleMedium),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(context, MaterialPageRoute(builder: (_) => builder(p.id)));
                    },
                  )),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _buildBody(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
        selectedItemColor: Theme.of(context).colorScheme.secondary,
        unselectedItemColor: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.auto_awesome), label: 'Ask AI'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Settings'),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_currentIndex == 1) return const ChatScreen();
    if (_currentIndex == 2) return const SettingsScreen();

    // Dashboard Home (Index 0)
    return SafeArea(
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _buildHeroSection()),
          SliverToBoxAdapter(child: _buildQuickChips()),
          SliverPadding(
            padding: const EdgeInsets.all(24),
            sliver: _buildSquareGrid(),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Text(
                'Unlock the mysteries of your life through the ancient wisdom of Vedic Astrology.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                  fontSize: 14,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildHeroSection() {
    return Container(
      padding: const EdgeInsets.all(24.0),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Theme.of(context).colorScheme.surfaceContainerHighest, Theme.of(context).colorScheme.primaryContainer],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        image: DecorationImage(
          image: const AssetImage('assets/app_icon.png'),
          fit: BoxFit.cover,
          colorFilter: ColorFilter.mode(Colors.black.withValues(alpha: 0.65), BlendMode.darken),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: Theme.of(context).colorScheme.secondary.withValues(alpha: 0.2),
                backgroundImage: const AssetImage('assets/app_icon.png'),
              ),
              const SizedBox(width: 8),
              Consumer(builder: (context, ref, _) {
                final synced = ref.watch(syncProvider.select((s) => s.signedIn));
                return Chip(
                  avatar: Icon(synced ? Icons.cloud_done : Icons.offline_bolt, size: 16),
                  label: Text(synced ? 'Cloud sync on' : 'Offline', style: const TextStyle(fontSize: 12)),
                  visualDensity: VisualDensity.compact,
                );
              }),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            'Namaste, Seeker ✨',
            style: TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Welcome to Jyotish Cosmic. Your celestial journey awaits.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.9),
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickChips() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: 8,
        runSpacing: 8,
        children: [
          _buildChip('New Kundali', Icons.add_circle_outline, () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const KundaliScreen(initialTab: 1)));
          }),
          _buildChip('Interpretation', Icons.menu_book_outlined, () {
            _selectProfileAndNavigate(context, (id) => InterpretationScreen(profileId: id));
          }),
          _buildChip('Report', Icons.picture_as_pdf_outlined, () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const ReportScreen()));
          }),
          _buildChip('Knowledge Base', Icons.auto_stories_outlined, () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const KnowledgeBaseScreen()));
          }),
        ],
      ),
    );
  }

  Widget _buildChip(String label, IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Theme.of(context).colorScheme.secondary.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Theme.of(context).colorScheme.secondary, size: 18),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSquareGrid() {
    return SliverGrid.count(
      crossAxisCount: 2,
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      children: [
        _buildGridCard(
          title: 'Kundali',
          icon: Icons.grid_view,
          onTap: () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const KundaliScreen()));
          },
        ),
        _buildGridCard(title: 'Kundali Milan', icon: Icons.people_outline, onTap: () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const KundaliMilanScreen()));
        }),
        _buildGridCard(title: 'Rashifal', icon: Icons.auto_awesome, onTap: () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const RashifalScreen()));
        }),
        _buildGridCard(title: 'Interpretation', icon: Icons.menu_book, onTap: () {
            _selectProfileAndNavigate(context, (id) => InterpretationScreen(profileId: id));
        }),
      ],
    );
  }

  Widget _buildGridCard({required String title, required IconData icon, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Theme.of(context).colorScheme.secondary.withValues(alpha: 0.1)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 48, color: Theme.of(context).colorScheme.secondary),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
