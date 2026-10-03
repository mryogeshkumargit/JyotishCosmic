import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sweph/sweph.dart';
import 'core/ephemeris.dart';
import 'core/vedic_math.dart';
import 'services/location_service.dart';
import 'theme/app_theme.dart';
import 'screens/dashboard_screen.dart';
import 'providers/settings_provider.dart';

class _RootBundleAssetLoader implements AssetLoader {
  @override
  Future<Uint8List> load(String assetPath) async {
    return (await rootBundle.load(assetPath)).buffer.asUint8List();
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Fonts are bundled under assets/google_fonts; never download them.
  GoogleFonts.config.allowRuntimeFetching = false;

  Object? startupError;
  try {
    final supportDir = await getApplicationSupportDirectory();
    await Ephemeris.init(
      assetLoader: _RootBundleAssetLoader(),
      epheFilesPath: '${supportDir.path}/ephe_files',
    );
    LocationService.ensureTimeZones();
  } catch (e) {
    startupError = e;
  }

  runApp(
    ProviderScope(
      child: startupError == null ? const MobileJyotishApp() : _StartupErrorApp(startupError),
    ),
  );
}

class MobileJyotishApp extends ConsumerWidget {
  const MobileJyotishApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    // Apply the calculation conventions chosen in Settings to the engines.
    Ephemeris.configure(ayanamsa: settings.calc.ayanamsa, trueNode: settings.calc.trueNode);
    DashaCalculations.yearDays = settings.calc.dashaYearDays;

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

class _StartupErrorApp extends StatelessWidget {
  final Object error;
  const _StartupErrorApp(this.error);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text('Could not start the Swiss Ephemeris engine:\n\n$error', textAlign: TextAlign.center),
          ),
        ),
      ),
    );
  }
}
