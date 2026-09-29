import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sweph/sweph.dart' show AssetLoader;

import 'core/astro_engine.dart';
import 'theme/app_theme.dart';
import 'screens/dashboard_screen.dart';
import 'providers/settings_provider.dart';

class _RootBundleAssetLoader implements AssetLoader {
  @override
  Future<Uint8List> load(String assetPath) async =>
      (await rootBundle.load(assetPath)).buffer.asUint8List();
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  Object? engineError;
  try {
    final support = await getApplicationSupportDirectory();
    await AstroEngine.init(
      assetLoader: _RootBundleAssetLoader(),
      epheFilesPath: '${support.path}/ephe_files',
    );
  } catch (e) {
    engineError = e;
  }

  runApp(
    ProviderScope(
      child: engineError == null ? const MobileJyotishApp() : _EngineErrorApp(error: engineError),
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
      debugShowCheckedModeBanner: false,
      theme: activeTheme,
      home: const DashboardScreen(),
    );
  }
}

/// Shown only if the astronomical engine could not start (e.g. missing native library).
class _EngineErrorApp extends StatelessWidget {
  final Object error;
  const _EngineErrorApp({required this.error});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 56, color: Colors.redAccent),
                const SizedBox(height: 16),
                const Text('Could not start the astronomy engine',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                const SizedBox(height: 12),
                Text('$error', textAlign: TextAlign.center),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
