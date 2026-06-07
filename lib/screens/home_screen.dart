import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/kundli_chart.dart';
import '../core/ephemeris.dart';
import 'chat_screen.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/profile_provider.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _currentIndex = 0;
  
  ChartData? _getChartData() {
    final profilesAsync = ref.watch(profileListProvider);
    
    return profilesAsync.when(
      data: (profiles) {
        if (profiles.isEmpty) {
            return null; // No profiles, empty chart
        }
        final profile = profiles.first; // Default to first profile for now
        final chart = Ephemeris.computeChart(
          profile.dob.year,
          profile.dob.month,
          profile.dob.day,
          profile.dob.hour.toDouble(),
          profile.dob.minute.toDouble(),
          profile.lat,
          profile.lon,
          profile.timezone, // Use explicit timezone
        );
        return chart;
      },
      loading: () => null,
      error: (_, __) => null,
    );
  }

  String _getActiveProfileName() {
    final profilesAsync = ref.watch(profileListProvider);
    return profilesAsync.when(
      data: (profiles) => profiles.isNotEmpty ? profiles.first.name : 'No Profile',
      loading: () => 'Loading...',
      error: (_, __) => 'Error',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Jyotish Cosmic'),
        actions: [
          IconButton(icon: const Icon(Icons.person), onPressed: () {})
        ],
      ),
      body: _buildBody(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        backgroundColor: AppTheme.primaryMystic,
        selectedItemColor: AppTheme.saffronAccent,
        unselectedItemColor: AppTheme.starWhite.withOpacity(0.5),
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.grid_view), label: 'Charts'),
          BottomNavigationBarItem(icon: Icon(Icons.auto_awesome), label: 'Ask AI'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Settings'),
        ],
      ),
    );
  }

  Widget _buildBody() {
    switch (_currentIndex) {
      case 0:
        return _buildHomeTab();
      case 1:
        return _buildChartsTab(); // The swipeable accordions
      case 2:
        return const ChatScreen();
      default:
        return const Center(child: Text('Settings'));
    }
  }

  Widget _buildHomeTab() {
    final chartData = _getChartData();
    return SingleChildScrollView(
      child: Column(
        children: [
          const SizedBox(height: 16),
          Text('Natal Chart (${_getActiveProfileName()})', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          if (chartData != null)
            KundliChart(
              housePlanets: chartData.housePlanets,
              ascendantSign: (chartData.ascendantSidereal / 30).floor() + 1,
              onHouseTapped: (house) {},
            )
          else
            const Center(child: Text('No charts found. Create a profile to begin.')),
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'Your planetary positions are calculated precisely using the ported Jean Meeus algorithms directly on your device.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.starWhite, fontSize: 16),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildChartsTab() {
    // Swipeable Details (Graha, Varga, Nakshatra, Dasha)
    return DefaultTabController(
      length: 4,
      child: Column(
        children: [
          const TabBar(
            indicatorColor: AppTheme.saffronAccent,
            labelColor: AppTheme.saffronAccent,
            unselectedLabelColor: AppTheme.starWhite,
            tabs: [
              Tab(text: 'Graha'),
              Tab(text: 'Varga'),
              Tab(text: 'Dasha'),
              Tab(text: 'Gochar'),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                _buildListView('Planetary Details (Graha)'),
                _buildListView('Divisional Charts (Varga)'),
                _buildListView('Vimshottari Dasha Periods'),
                _buildListView('Current Transit (Gochar)'),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildListView(String title) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 5,
      itemBuilder: (context, index) {
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            title: Text('$title Item ${index + 1}'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
          ),
        );
      },
    );
  }
}
