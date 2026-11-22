import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sweph/sweph.dart';
import 'core/ephemeris.dart';
import 'core/l10n.dart';
import 'core/vedic_math.dart';
import 'providers/rashifal_provider.dart';
import 'screens/daily_rashifal_screen.dart';
import 'services/location_service.dart';
import 'services/rashifal_notifications.dart';
import 'theme/app_theme.dart';
import 'screens/dashboard_screen.dart';
import 'providers/settings_provider.dart';

/// Root navigator, used to open screens from notification taps.
final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

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
  RashifalPayload? launchPayload;
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
  if (startupError == null) launchPayload = await RashifalNotifications.init();

  runApp(
    ProviderScope(
      child: startupError == null ? MobileJyotishApp(launchPayload: launchPayload) : _StartupErrorApp(startupError),
    ),
  );
}

class MobileJyotishApp extends ConsumerStatefulWidget {
  /// Daily Rashifal notification that launched the app, if any.
  final RashifalPayload? launchPayload;

  const MobileJyotishApp({super.key, this.launchPayload});

  @override
  ConsumerState<MobileJyotishApp> createState() => _MobileJyotishAppState();
}

class _MobileJyotishAppState extends ConsumerState<MobileJyotishApp> {
  String _lang = L10n.lang;
  StreamSubscription<RashifalPayload>? _taps;

  @override
  void initState() {
    super.initState();
    _taps = RashifalNotifications.taps.listen(_openRashifal);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.launchPayload != null) _openRashifal(widget.launchPayload!);
      // Keep the morning notifications scheduled (refreshes the next days).
      ref.read(rashifalSchedulerProvider).scheduleSoon(delay: const Duration(seconds: 3));
    });
  }

  @override
  void dispose() {
    _taps?.cancel();
    super.dispose();
  }

  void _openRashifal(RashifalPayload p) {
    rootNavigatorKey.currentState?.push(MaterialPageRoute(
      builder: (_) => DailyRashifalScreen(profileId: p.profileId, date: DateTime.tryParse(p.dateKey)),
    ));
  }

  /// Rebuilds every widget (including routes below the current one) so text
  /// produced with [tr] switches language immediately.
  void _rebuildAll() {
    void mark(Element e) {
      e.markNeedsBuild();
      e.visitChildren(mark);
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) (context as Element).visitChildren(mark);
    });
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    // Apply the calculation conventions chosen in Settings to the engines.
    Ephemeris.configure(ayanamsa: settings.calc.ayanamsa, trueNode: settings.calc.trueNode);
    DashaCalculations.yearDays = settings.calc.dashaYearDays;
    L10n.lang = settings.appLanguage;
    if (_lang != settings.appLanguage) {
      _lang = settings.appLanguage;
      _rebuildAll();
    }

    ThemeData activeTheme;
    if (settings.themeMode == 'Dark') {
      activeTheme = AppTheme.darkTheme;
    } else if (settings.themeMode == 'Light') {
      activeTheme = AppTheme.lightTheme;
    } else {
      activeTheme = AppTheme.cosmicTheme;
    }

    return MaterialApp(
      navigatorKey: rootNavigatorKey,
      title: 'Jyotish Cosmic',
      theme: activeTheme,
      locale: Locale(settings.appLanguage),
      supportedLocales: const [Locale('en'), Locale('hi')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
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
            child: Text('${tr('Could not start the Swiss Ephemeris engine', 'स्विस एफ़ेमेरिस इंजन शुरू नहीं हो सका')}:\n\n$error', textAlign: TextAlign.center),
          ),
        ),
      ),
    );
  }
}
