import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'theme/app_theme.dart';
import 'screens/dashboard_screen.dart';
import 'providers/settings_provider.dart';

void main() {
  runApp(
    const ProviderScope(
      child: MobileJyotishApp(),
    ),
  );
}

class MobileJyotishApp extends ConsumerWidget {
  const MobileJyotishApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    
    ThemeData activeTheme;
    if (settings.themeMode == 'Dark') {
      activeTheme = AppTheme.darkTheme;
    } else if (settings.themeMode == 'Light') {
      activeTheme = AppTheme.lightTheme;
    } else {
      activeTheme = AppTheme.cosmicTheme;
    }

    return MaterialApp(
      title: 'Jyotish Cosmic',
      theme: activeTheme,
      home: const DashboardScreen(),
    );
  }
}


