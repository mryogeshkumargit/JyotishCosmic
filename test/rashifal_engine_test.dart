import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';

import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_jyotish/core/ephemeris.dart';
import 'package:mobile_jyotish/core/l10n.dart';
import 'package:mobile_jyotish/core/rashifal/rashifal_engine.dart';
import 'package:mobile_jyotish/core/rashifal/rashifal_models.dart';
import 'package:mobile_jyotish/services/location_service.dart';
import 'package:mobile_jyotish/services/rashifal_pdf.dart';

import 'helpers/sweph_test_helper.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    await initEphemerisForTests();
    LocationService.ensureTimeZones();
  });
  tearDown(() => L10n.lang = 'en');

  const delhi = RashifalPlace(name: 'New Delhi', lat: 28.6139, lon: 77.2090, tzName: 'Asia/Kolkata');

  RashifalNatal natal() {
    final chart = Ephemeris.computeChart(1990, 3, 11, 2, 30, 18.52, 73.86, 5.5);
    return RashifalNatal.fromChart(chart, profileId: 1, name: 'Test', gender: 'Female');
  }

  test('daily report has every requested section', () {
    final c = RashifalEngine.compute(natal(), DateTime(2026, 11, 23), delhi);
    final r = c.report;
    expect(r.dateKey, '2026-11-23');
    expect(r.score, inInclusiveRange(5, 95));
    expect(r.rating, DayRating.fromScore(r.score));
    expect(r.areas.map((s) => s.key), ['overall', 'family', 'marriage', 'health', 'career', 'mind', 'finance', 'social']);
    expect(r.outlook.map((s) => s.key), ['muhurat', 'travel', 'financeDecisions', 'unexpected']);
    expect(r.remedies.map((s) => s.key), ['mantra', 'upay', 'donation', 'colour', 'dosDonts']);
    expect(r.analysis.map((a) => a.key), ['date', 'panchang', 'moonSign', 'moonTransit', 'gochar', 'drishti', 'nakshatra', 'dasha', 'strength', 'energy', 'supporting']);
    for (final s in [...r.areas, ...r.outlook, ...r.remedies]) {
      expect(s.text.trim(), isNotEmpty, reason: s.key);
    }
    expect(r.section('dosDonts')!.items, isNotEmpty);
    expect(r.section('dosDonts')!.items2, isNotEmpty);
    expect(r.section('colour')!.extra['hex'], startsWith('#'));
    expect(r.timeSlots.where((s) => s.quality == 'avoid').map((s) => s.name), contains('Rahu Kaal'));
    // Gochar table: header + nine grahas.
    expect(r.analysis.firstWhere((a) => a.key == 'gochar').table.length, 10);
    expect(r.analysis.firstWhere((a) => a.key == 'dasha').table.length, 4);
    expect(r.notificationLine1, contains('/100'));
    expect(r.notificationLine2, contains('Rahu Kaal'));
    expect(c.aiContext, contains('PANCHANG'));
    expect(c.aiContext, contains('DASHA'));
  }, skip: swephSkipReason());

  test('report survives a JSON round trip unchanged', () {
    final r = RashifalEngine.compute(natal(), DateTime(2026, 11, 23), delhi).report;
    final json = jsonEncode(r.toJson());
    final back = DailyRashifalReport.fromJson(jsonDecode(json) as Map<String, dynamic>);
    expect(jsonEncode(back.toJson()), json);
  }, skip: swephSkipReason());

  test('Hindi report and light mode work for a month of days', () {
    L10n.lang = 'hi';
    final n = natal();
    final scores = <int>{};
    for (int i = 0; i < 30; i++) {
      final c = RashifalEngine.compute(n, DateTime(2026, 12, 1).add(Duration(days: i)), delhi, full: false);
      scores.add(c.report.score);
      expect(c.report.lang, 'hi');
      expect(c.report.notificationLine2, contains('राहु काल'));
    }
    // The score follows the Moon, so it must vary across a month.
    expect(scores.length, greaterThan(5));
  }, skip: swephSkipReason());

  test('places in other time zones get local sunrise times', () {
    const london = RashifalPlace(name: 'London', lat: 51.5072, lon: -0.1276, tzName: 'Europe/London');
    final r = RashifalEngine.compute(natal(), DateTime(2026, 6, 21), london).report;
    final date = r.analysis.first.points[1];
    // Midsummer sunrise in London is about 04:43 BST.
    expect(date, contains('04:4'));
    expect(date, contains('UTC+1:00'));
  }, skip: swephSkipReason());

  test('PDF report builds in English and Hindi', () async {
    final loader = FontLoader('NotoSansDevanagari')
      ..addFont(rootBundle.load('assets/fonts/NotoSansDevanagari-Regular.ttf'))
      ..addFont(rootBundle.load('assets/fonts/NotoSansDevanagari-Bold.ttf'));
    await loader.load();
    final out = Platform.environment['RASHIFAL_PDF_DIR'];
    for (final lang in ['en', 'hi']) {
      L10n.lang = lang;
      final r = RashifalEngine.compute(natal(), DateTime(2026, 11, 23), delhi).report;
      final bytes = await RashifalPdf.build(r);
      expect(bytes.length, greaterThan(20000));
      expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
      if (out != null) File('$out/rashifal_$lang.pdf').writeAsBytesSync(bytes);
    }
  }, skip: swephSkipReason());
}
