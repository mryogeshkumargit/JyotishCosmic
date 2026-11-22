import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mobile_jyotish/core/database.dart';
import 'package:mobile_jyotish/core/profile_chart.dart';
import 'package:mobile_jyotish/core/rashifal/rashifal_ai.dart';
import 'package:mobile_jyotish/core/rashifal/rashifal_models.dart';
import 'package:mobile_jyotish/providers/settings_provider.dart';
import 'package:mobile_jyotish/services/ai_service.dart';
import 'package:mobile_jyotish/services/location_service.dart';
import 'package:mobile_jyotish/services/rashifal_notifications.dart';
import 'package:mobile_jyotish/services/rashifal_repository.dart';
import 'package:mobile_jyotish/services/rashifal_service.dart';

import 'helpers/sweph_test_helper.dart';

DailyRashifalReport sampleReport({int profileId = 1, String date = '2026-11-23', int score = 70, String lang = 'en'}) => DailyRashifalReport(
  profileId: profileId,
  profileName: 'Asha',
  dateKey: date,
  lang: lang,
  placeName: 'Pune',
  score: score,
  rating: DayRating.fromScore(score),
  headline: 'Good day',
  dayReasons: const ['+ Chandra Bala'],
  notificationLine1: 'Good day (70/100)',
  notificationLine2: 'Colour: Yellow',
  areas: const [
    RashifalSection(key: 'overall', title: 'Day', text: 'engine overall', score: 70, rating: DayRating.good),
    RashifalSection(key: 'family', title: 'Family', text: 'engine family', score: 55, rating: DayRating.average),
  ],
  outlook: const [RashifalSection(key: 'travel', title: 'Travel', text: 'engine travel', score: 60)],
  remedies: const [
    RashifalSection(key: 'mantra', title: 'Mantra', text: 'engine mantra'),
    RashifalSection(key: 'dosDonts', title: 'Dos', text: 'x', items: ['a'], items2: ['b']),
  ],
  timeSlots: const [TimeSlot('Rahu Kaal', '08:00', '09:30', 'avoid')],
  analysis: const [
    AnalysisBlock(
      key: 'panchang',
      title: 'Panchang',
      summary: 'engine panchang',
      table: [
        ['a', 'b'],
        ['1', '2'],
      ],
    ),
  ],
  generatedAt: DateTime(2026, 11, 23, 7),
);

void main() {
  group('database', () {
    late AppDatabase db;
    late RashifalRepository repo;
    setUp(() {
      db = AppDatabase.forTesting(NativeDatabase.memory());
      repo = RashifalRepository(db);
    });
    tearDown(() => db.close());

    test('saves, upserts and loads reports by profile, date and language', () async {
      await repo.save(sampleReport());
      await repo.save(sampleReport(lang: 'hi'));
      final id = (await repo.page()).firstWhere((s) => s.lang == 'en').id;
      await repo.setFavourite(id, true);
      // Same key again: updated in place, favourite and raw AI kept.
      await repo.save(sampleReport(score: 30), aiRaw: '{"x":1}');
      await repo.save(sampleReport(score: 35));
      expect(await repo.count(), 2);
      final r = await repo.load(1, '2026-11-23', 'en');
      expect(r!.score, 35);
      expect(r.rating, DayRating.bad);
      final row = await repo.rowById(id);
      expect(row!.favourite, isTrue);
      expect(row.aiRaw, '{"x":1}');
      expect((await repo.loadById(id))!.areas.length, 2);
    });

    test('pages a long history newest first using only summary columns', () async {
      final start = DateTime(2024, 1, 1);
      await db.transaction(() async {
        for (int i = 0; i < 400; i++) {
          await repo.save(
            sampleReport(
              date: dateKeyOf(start.add(Duration(days: i))),
              profileId: i.isEven ? 1 : 2,
            ),
          );
        }
      });
      expect(await repo.count(), 400);
      expect(await repo.count(profileId: 2), 200);
      final first = await repo.page(limit: 30);
      expect(first.length, 30);
      expect(first.first.dateKey, dateKeyOf(start.add(const Duration(days: 399))));
      final second = await repo.page(limit: 30, offset: 30);
      expect(second.first.dateKey.compareTo(first.last.dateKey), lessThan(0));
      final ranged = await repo.page(from: '2024-02-01', to: '2024-02-29', limit: 100);
      expect(ranged.length, 29);
      expect(await repo.deleteOlderThan('2024-06-01'), 152);
      expect(await repo.deleteForProfile(1), greaterThan(0));
      expect(await repo.count(profileId: 1), 0);
    });

    test('migration from schema 5 creates the daily Rashifal table', () async {
      final executor = NativeDatabase.memory(
        setup: (raw) {
          raw.execute('''
          CREATE TABLE profiles (
            id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT, name TEXT NOT NULL, dob INTEGER NOT NULL, pob TEXT NOT NULL,
            lat REAL NOT NULL, lon REAL NOT NULL, created_at INTEGER NOT NULL DEFAULT 0, updated_at INTEGER NOT NULL DEFAULT 0,
            ai_interpretation TEXT NULL, timezone REAL NOT NULL DEFAULT 5.5, tz_name TEXT NULL, gender TEXT NULL,
            cloudflare_id TEXT NULL, needs_sync INTEGER NOT NULL DEFAULT 1
          );
        ''');
          raw.execute('CREATE TABLE pending_deletions (cloud_id TEXT NOT NULL PRIMARY KEY)');
          raw.execute("INSERT INTO profiles (name, dob, pob, lat, lon) VALUES ('Kept', 0, 'Pune', 18.5, 73.8)");
          raw.execute('PRAGMA user_version = 5');
        },
      );
      final old = AppDatabase.forTesting(executor);
      addTearDown(old.close);
      expect((await old.select(old.profiles).getSingle()).name, 'Kept');
      await RashifalRepository(old).save(sampleReport());
      expect(await RashifalRepository(old).count(), 1);
      final idx = await old.customSelect("SELECT name FROM sqlite_master WHERE type = 'index' AND tbl_name = 'daily_rashifals'").get();
      expect(idx.map((r) => r.read<String>('name')), contains('idx_daily_rashifals_date'));
    });
  });

  group('AI', () {
    test('parses JSON wrapped in prose or code fences', () {
      expect(RashifalAi.parseJson('Here you go:\n```json\n{"a": 1}\n```'), {'a': 1});
      expect(RashifalAi.parseJson('{"a": {"b": 2}} trailing'), {
        'a': {'b': 2},
      });
      expect(RashifalAi.parseJson('no json'), isNull);
    });

    test('merges AI texts and keeps engine scores, ratings and tables', () {
      final merged = RashifalAi.merge(sampleReport(), {
        'summary': 'AI summary',
        'notification': ['AI line one', 'AI line two'],
        'areas': {
          'family': {'text': 'AI family'},
          'overall': 'AI overall',
        },
        'remedies': {
          'mantra': {'text': 'AI mantra'},
        },
        'dosDonts': {
          'dos': ['AI do'],
          'donts': [],
        },
        'analysis': {'panchang': 'AI panchang'},
      }, model: 'OpenAI · m');
      expect(merged.hasAi, isTrue);
      expect(merged.aiSummary, 'AI summary');
      expect(merged.notificationLine1, 'AI line one');
      expect(merged.section('family')!.text, 'AI family');
      expect(merged.section('family')!.score, 55);
      expect(merged.section('overall')!.text, 'AI overall');
      expect(merged.section('travel')!.text, 'engine travel');
      expect(merged.section('mantra')!.text, 'AI mantra');
      expect(merged.section('dosDonts')!.items, ['AI do']);
      expect(merged.section('dosDonts')!.items2, ['b'], reason: 'empty AI list keeps the engine list');
      expect(merged.analysis.first.summary, 'AI panchang');
      expect(merged.analysis.first.table.length, 2);
      expect(merged.score, 70);
    });
  });

  group('with the Swiss Ephemeris', () {
    setUpAll(() async {
      await initEphemerisForTests();
      LocationService.ensureTimeZones();
    });

    Profile profile() => Profile(
      id: 1,
      name: 'Asha',
      dob: encodeWallClock(1992, 2, 29, 6, 5),
      pob: 'Pune, Maharashtra, India',
      lat: 18.5196,
      lon: 73.8553,
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
      timezone: 5.5,
      tzName: 'Asia/Kolkata',
      needsSync: false,
    );

    test('AI enrichment retries invalid JSON, then saves the merged report', () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);
      final service = RashifalService(RashifalRepository(db));
      final prompts = <String>[];
      int calls = 0;
      AiService.clientFactory = () => MockClient((request) async {
        calls++;
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        prompts.add((body['messages'] as List).last['content'] as String);
        final content = calls == 1
            ? 'Here is your horoscope in prose.'
            : '```json\n${jsonEncode({
                'summary': 'A steady day.',
                'notification': ['Steady day — good for family.', 'Wear yellow; start work at 11:50.'],
                'areas': {
                  'family': {'text': 'Jupiter blesses the home.'},
                },
                'analysis': {'dasha': 'The Pratyantar lord leads the day.'},
              })}\n```';
        return http.Response(
          jsonEncode({
            'choices': [
              {
                'message': {'content': content},
              },
            ],
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });
      addTearDown(() => AiService.clientFactory = http.Client.new);
      final settings = SettingsState(llmProvider: 'OpenAI', apiEndpoint: LlmProviders.endpoints['OpenAI']!, apiKey: 'k', modelName: 'gpt-test');
      final r = await service.runAi(settings, profile(), DateTime(2026, 11, 23));
      expect(calls, 2);
      expect(prompts.first, contains('=== NATAL CHART ==='));
      expect(prompts.first, contains('GOCHAR'));
      expect(prompts.first, contains('SAV by house'));
      expect(prompts.first, contains('D9 / D10'));
      expect(prompts.last, contains('not valid JSON'));
      expect(r.hasAi, isTrue);
      expect(r.section('family')!.text, 'Jupiter blesses the home.');
      expect(r.analysis.firstWhere((a) => a.key == 'dasha').summary, 'The Pratyantar lord leads the day.');
      final saved = await RashifalRepository(db).load(1, '2026-11-23', 'en');
      expect(saved!.aiSummary, 'A steady day.');
      // Notifications use the saved (AI) lines for that day.
      final (l1, _) = await service.notificationLines(profile(), DateTime(2026, 11, 23), const RashifalPrefs());
      expect(l1, 'Steady day — good for family.');
    });

    test('plans notifications only on chosen weekdays at the chosen time', () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);
      final service = RashifalService(RashifalRepository(db));
      final now = DateTime(2026, 11, 23, 9, 0); // Monday, after 08:00
      final plan = await RashifalNotifications.plan(const RashifalPrefs(hour: 8, minute: 30, weekdays: {1, 3, 5}), [profile()], service, now: now);
      expect(plan, isNotEmpty);
      for (final p in plan) {
        expect([1, 3, 5], contains(p.when.weekday));
        expect([p.when.hour, p.when.minute], [8, 30]);
        expect(p.when.isAfter(now), isTrue);
        expect(p.body.split('\n').length, 2);
        expect(RashifalPayload.decode(p.payload.encode())!.dateKey, dateKeyOf(p.when));
      }
      expect(plan.first.when.day, 25, reason: 'Monday 08:30 has passed; next is Wednesday');
      expect(await RashifalNotifications.plan(const RashifalPrefs(enabled: false), [profile()], service, now: now), isEmpty);
      expect(await RashifalNotifications.plan(const RashifalPrefs(), const [], service, now: now), isEmpty);
    });

    test('prefs survive a storage round trip', () {
      const p = RashifalPrefs(hour: 6, minute: 45, weekdays: {7, 1}, profileId: 3, placeName: 'London', lat: 51.5, lon: -0.12, tzName: 'Europe/London', autoAi: false);
      final back = RashifalPrefs.fromJson(jsonDecode(jsonEncode(p.toJson())) as Map<String, dynamic>);
      expect(back, p);
      expect(back.copyWith(clearPlace: true).hasPlace, isFalse);
    });
  }, skip: swephSkipReason());
}
