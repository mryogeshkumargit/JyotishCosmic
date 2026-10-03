import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile_jyotish/core/database.dart';
import 'package:mobile_jyotish/core/profile_chart.dart';
import 'package:mobile_jyotish/providers/database_provider.dart';
import 'package:mobile_jyotish/screens/dashboard_screen.dart';
import 'package:mobile_jyotish/screens/kundali_milan_screen.dart';
import 'package:mobile_jyotish/screens/kundali_screen.dart';
import 'package:mobile_jyotish/screens/kundli_result_screen.dart';
import 'package:mobile_jyotish/screens/knowledge_base_screen.dart';
import 'package:mobile_jyotish/screens/rashifal_screen.dart';
import 'package:mobile_jyotish/screens/report_screen.dart';
import 'package:mobile_jyotish/screens/research_screen.dart';
import 'package:mobile_jyotish/screens/rules_sources_screen.dart';
import 'package:mobile_jyotish/screens/settings_screen.dart';
import 'package:mobile_jyotish/screens/tabs/synthesis_screen.dart';
import 'package:mobile_jyotish/core/ephemeris.dart';
import 'package:mobile_jyotish/core/synthesis_engine.dart';
import 'package:mobile_jyotish/theme/app_theme.dart';
import 'package:mobile_jyotish/widgets/yoga_guide_view.dart';

import 'helpers/sweph_test_helper.dart';

/// Renders every screen on small phones (and with a large system font) and
/// fails on any layout overflow ("RenderFlex overflowed", unbounded sizes...).
void main() {
  setUpAll(() async {
    GoogleFonts.config.allowRuntimeFetching = false;
    await initEphemerisForTests();
  });

  const sizes = [Size(360, 740), Size(320, 600)];
  const scales = [1.0, 1.3];

  Future<void> settle(WidgetTester tester) async {
    for (int i = 0; i < 6; i++) {
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  Future<List<String>> collect(WidgetTester tester, Future<void> Function() body) async {
    final errors = <String>[];
    final old = FlutterError.onError;
    FlutterError.onError = (d) {
      final where = RegExp(r'lib/[\w/]+\.dart:\d+').firstMatch(d.toString())?.group(0) ?? '';
      errors.add('${d.exceptionAsString().split('\n').first} $where');
    };
    try {
      await body();
    } finally {
      FlutterError.onError = old;
    }
    return errors;
  }

  Widget app(Widget home, AppDatabase db, double scale) => ProviderScope(
        overrides: [databaseProvider.overrideWithValue(db)],
        child: MaterialApp(
          theme: AppTheme.cosmicTheme,
          home: home,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(scale)),
            child: child!,
          ),
        ),
      );

  Future<AppDatabase> seeded(WidgetTester tester) async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    await tester.runAsync(() async {
      for (final n in ['Asha Deshpande-Kulkarni', 'Ravi']) {
        await db.into(db.profiles).insert(ProfilesCompanion.insert(
          name: n,
          dob: encodeWallClock(1992, 2, 29, 6, 5),
          pob: 'Pune, Maharashtra, India',
          lat: 18.5196,
          lon: 73.8553,
          tzName: const Value('Asia/Kolkata'),
          gender: const Value('Female'),
        ));
      }
    });
    return db;
  }

  for (final size in sizes) {
    for (final scale in scales) {
      final tag = '${size.width.toInt()}x${size.height.toInt()} @${scale}x';

      testWidgets('top-level screens fit $tag', (tester) async {
        await tester.binding.setSurfaceSize(size);
        addTearDown(() => tester.binding.setSurfaceSize(null));
        final db = await seeded(tester);
        final screens = <String, Widget>{
          'dashboard': const DashboardScreen(),
          'kundali list': const KundaliScreen(),
          'kundali form': const KundaliScreen(initialTab: 1),
          'milan': const KundaliMilanScreen(),
          'rashifal': const RashifalScreen(),
          'report': const ReportScreen(),
          'settings': const SettingsScreen(),
          'knowledge base': const KnowledgeBaseScreen(),
          'rules & sources': const RulesSourcesScreen(),
          'research': const ResearchScreen(),
        };
        final failures = <String>[];
        for (final e in screens.entries) {
          final errors = await collect(tester, () async {
            await tester.pumpWidget(app(e.value, db, scale));
            await settle(tester);
            if (e.key == 'settings') {
              for (final t in ['AI', 'Sync', 'About']) {
                await tester.tap(find.text(t));
                await settle(tester);
              }
            }
            if (e.key == 'rules & sources') {
              for (final t in ['Sources', 'Coverage']) {
                await tester.tap(find.text(t));
                await settle(tester);
              }
            }
            if (e.key == 'research' && swephSkipReason() == null) {
              final search = find.text('Search saved charts');
              await tester.scrollUntilVisible(search, 200, scrollable: find.byType(Scrollable).first);
              await tester.tap(search);
              await settle(tester);
              await tester.drag(find.byType(Scrollable).first, const Offset(0, -3000));
              await settle(tester);
            }
            if (e.key == 'dashboard') {
              await tester.tap(find.text('Ask AI'));
              await settle(tester);
            }
          });
          failures.addAll(errors.map((m) => '${e.key}: $m'));
        }
        for (final d in KnowledgeBaseScreen.documents) {
          final errors = await collect(tester, () async {
            await tester.pumpWidget(app(Scaffold(key: ValueKey(d.$3), body: MarkdownDocView(asset: d.$3)), db, scale));
            for (int i = 0; i < 40 && find.byType(Scrollable).evaluate().isEmpty; i++) {
              await settle(tester);
            }
            expect(find.byType(Scrollable), findsWidgets, reason: d.$1);
            await tester.drag(find.byType(Scrollable).first, const Offset(0, -3000));
            await settle(tester);
          });
          failures.addAll(errors.map((m) => '${d.$1}: $m'));
        }
        await tester.pumpWidget(const SizedBox());
        await settle(tester);
        await tester.runAsync(db.close);
        expect(failures, isEmpty, reason: failures.join('\n'));
      });

      testWidgets('synthesis domain details fit $tag', (tester) async {
        await tester.binding.setSurfaceSize(size);
        addTearDown(() => tester.binding.setSurfaceSize(null));
        final db = AppDatabase.forTesting(NativeDatabase.memory());
        final c = Ephemeris.computeChart(1990, 6, 15, 14, 30, 19.07, 72.88, 5.5);
        final report = SynthesisEngine.analyse(c, atJd: Ephemeris.julianDay(2026, 10, 3));
        final failures = <String>[];
        for (final d in report.domains) {
          final errors = await collect(tester, () async {
            await tester.pumpWidget(app(DomainDetailScreen(key: ValueKey(d.domain.id), report: report, domain: d, name: 'Asha'), db, scale));
            await settle(tester);
            for (int i = 0; i < 6; i++) {
              await tester.drag(find.byType(Scrollable).first, const Offset(0, -1500));
              await settle(tester);
            }
          });
          failures.addAll(errors.map((m) => '${d.domain.id}: $m'));
        }
        await tester.pumpWidget(const SizedBox());
        await settle(tester);
        await tester.runAsync(db.close);
        expect(failures, isEmpty, reason: failures.join('\n'));
      }, skip: swephSkipReason() != null);

      testWidgets('chart features fit $tag', (tester) async {
        await tester.binding.setSurfaceSize(size);
        addTearDown(() => tester.binding.setSurfaceSize(null));
        final db = AppDatabase.forTesting(NativeDatabase.memory());
        const features = [
          'Planet', 'Dasha', 'Predictions', 'KP System', 'Shodashvarga', 'Lal Kitab', 'Barshphal', 'Transit',
          'Nakshatra', 'Avasthas', 'Panchang', 'Dosha', 'Yogas', 'Remedies', 'Interpretation', 'Ask AI',
      'Synthesis', 'Conjunctions', 'Strength', 'Ashtakavarga',
        ];
        final failures = <String>[];
        failures.addAll((await collect(tester, () async {
          await tester.pumpWidget(app(
            KundliResultScreen(
              name: 'Asha Deshpande-Kulkarni',
              birth: encodeWallClock(1990, 6, 15, 14, 30),
              lat: 19.07,
              lon: 72.88,
              timezone: 5.5,
              tzName: 'Asia/Kolkata',
              place: 'Mumbai, Maharashtra, India',
            ),
            db,
            scale,
          ));
          await settle(tester);
        }))
            .map((m) => 'result: $m'));
        for (final f in features) {
          final errors = await collect(tester, () async {
            final target = find.text(f).first;
            await tester.scrollUntilVisible(target, 200, scrollable: find.byType(Scrollable).first);
            await tester.tap(target);
            await settle(tester);
            // Visit every tab of tabbed feature screens.
            final tabs = find.byType(Tab);
            for (int i = 0; i < tabs.evaluate().length; i++) {
              await tester.tap(tabs.at(i), warnIfMissed: false);
              await settle(tester);
            }
            if (f == 'Synthesis') {
              await tester.tap(tabs.at(0), warnIfMissed: false);
              await settle(tester);
              await tester.tap(find.text('Jaimini karakas & Arudhas'));
              await settle(tester);
            }
          });
          failures.addAll(errors.map((m) => '$f: $m'));
          await tester.pageBack();
          await settle(tester);
        }
        await tester.pumpWidget(const SizedBox());
        await settle(tester);
        await tester.runAsync(db.close);
        expect(failures, isEmpty, reason: failures.join('\n'));
      }, skip: swephSkipReason() != null);
    }
  }
}
