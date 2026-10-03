import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile_jyotish/core/database.dart';
import 'package:mobile_jyotish/core/profile_chart.dart';
import 'package:mobile_jyotish/providers/database_provider.dart';
import 'package:mobile_jyotish/screens/dashboard_screen.dart';
import 'package:mobile_jyotish/screens/kundali_screen.dart';
import 'package:mobile_jyotish/screens/kundli_result_screen.dart';
import 'package:drift/drift.dart' show Value;
import 'package:mobile_jyotish/widgets/kundli_chart.dart';

import 'helpers/sweph_test_helper.dart';

void main() {
  setUpAll(() async {
    GoogleFonts.config.allowRuntimeFetching = false;
    await initEphemerisForTests();
  });

  /// Lets real async work (drift queries) complete, then pumps frames.
  Future<void> settle(WidgetTester tester) async {
    for (int i = 0; i < 10; i++) {
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  Widget app(Widget home, AppDatabase db) => ProviderScope(
        overrides: [databaseProvider.overrideWithValue(db)],
        child: MaterialApp(home: home),
      );

  for (final style in ['North', 'South', 'East']) {
    testWidgets('$style Indian chart maps taps to houses', (tester) async {
      int? tapped;
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);
      await tester.pumpWidget(app(
        Scaffold(
          body: SizedBox(
            width: 400,
            height: 400,
            child: KundliChart(
              style: style,
              ascendantSign: 2, // Taurus
              housePlanets: {for (int i = 1; i <= 12; i++) i: i == 1 ? ['Su 12°', 'Sa 3°ᴿ'] : <String>[]},
              onHouseTapped: (h) => tapped = h,
            ),
          ),
        ),
        db,
      ));
      final box = tester.getRect(find.byType(CustomPaint).last);
      // Tap the cell holding Taurus: house 1.
      final Offset taurus = switch (style) {
        'North' => Offset(box.left + box.width / 2, box.top + box.height / 4),
        'South' => Offset(box.left + box.width * 5 / 8, box.top + box.height / 8),
        _ => Offset(box.left + box.width * 0.28, box.top + box.height * 0.08),
      };
      await tester.tapAt(taurus);
      expect(tapped, 1);
    });
  }

  testWidgets('result screen opens every feature without errors', (tester) async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    await tester.binding.setSurfaceSize(const Size(900, 2400));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(app(
      KundliResultScreen(
        name: 'Test',
        birth: encodeWallClock(1990, 6, 15, 14, 30),
        lat: 19.07,
        lon: 72.88,
        timezone: 5.5,
        tzName: 'Asia/Kolkata',
        place: 'Mumbai, Maharashtra, India',
      ),
      db,
    ));
    await tester.pumpAndSettle();
    expect(find.textContaining('Lagna'), findsWidgets);

    const features = [
      'Planet', 'Dasha', 'Predictions', 'KP System', 'Shodashvarga', 'Lal Kitab', 'Barshphal', 'Transit',
      'Nakshatra', 'Avasthas', 'Panchang', 'Dosha', 'Yogas', 'Remedies', 'Interpretation', 'Ask AI',
      'Synthesis', 'Conjunctions', 'Strength', 'Ashtakavarga',
    ];
    for (final f in features) {
      await tester.tap(find.text(f).first);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: f);
      await tester.pageBack();
      await tester.pumpAndSettle();
    }
  }, skip: swephSkipReason() != null);

  testWidgets('editing a saved profile fills the New Kundali form', (tester) async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(() => tester.runAsync(db.close));
    await tester.runAsync(() => db.into(db.profiles).insert(ProfilesCompanion.insert(
      name: 'Asha',
      dob: encodeWallClock(1992, 2, 29, 6, 5),
      pob: 'Pune, Maharashtra, India',
      lat: 18.5196,
      lon: 73.8553,
      tzName: const Value('Asia/Kolkata'),
    )));

    await tester.pumpWidget(app(const KundaliScreen(), db));
    await settle(tester);
    expect(find.text('Asha'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.more_vert));
    await settle(tester);
    await tester.tap(find.text('Edit'));
    await settle(tester);

    expect(find.text('Editing Profile'), findsOneWidget);
    expect(find.widgetWithText(TextField, 'Asha'), findsOneWidget);
    expect(find.text('1992-02-29'), findsOneWidget);
    expect(find.text('06:05'), findsOneWidget);
    expect(find.widgetWithText(TextField, 'Pune, Maharashtra, India'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    await settle(tester);
  });

  testWidgets('dashboard renders offline', (tester) async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    await tester.pumpWidget(app(const DashboardScreen(), db));
    await settle(tester);
    expect(find.text('Kundali Milan'), findsOneWidget);
    await tester.tap(find.text('Ask AI'));
    await settle(tester);
    await tester.tap(find.text('Settings'));
    await settle(tester);
    await tester.tap(find.text('Sync'));
    await settle(tester);
    expect(find.text('Create Account'), findsOneWidget);
    expect(tester.takeException(), isNull);
    // Dispose widgets (and their drift stream subscriptions) before closing the database.
    await tester.pumpWidget(const SizedBox());
    await settle(tester);
  });
}
