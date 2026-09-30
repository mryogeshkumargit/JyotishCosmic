import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_jyotish/core/database.dart';
import 'package:mobile_jyotish/core/profile_chart.dart';
import 'package:mobile_jyotish/providers/database_provider.dart';
import 'package:mobile_jyotish/providers/profile_provider.dart';
import 'package:mobile_jyotish/providers/sync_provider.dart';
import 'package:mobile_jyotish/services/sync_service.dart';

/// In-memory stand-in for the Cloudflare backend.
class FakeServer implements HttpClientAdapter {
  final Map<String, Map<String, dynamic>> profiles = {};
  final List<String> log = [];
  bool supportsPut = true;
  bool registerReturnsToken = false;
  final Map<String, String> users = {};
  String validToken = 'token-1';

  @override
  Future<ResponseBody> fetch(RequestOptions o, Stream<Uint8List>? requestStream, Future<void>? cancelFuture) async {
    final raw = requestStream == null ? '' : utf8.decode(await requestStream.expand((c) => c).toList());
    final body = raw.isEmpty ? null : jsonDecode(raw);
    final path = o.uri.path;
    log.add('${o.method} $path');

    ResponseBody json(Object? data, [int status = 200]) =>
        ResponseBody.fromString(jsonEncode(data), status, headers: {
          Headers.contentTypeHeader: [Headers.jsonContentType],
        });

    if (path == '/api/auth/register') {
      users[body['email']] = body['password'];
      return json(registerReturnsToken ? {'token': validToken} : {'ok': true});
    }
    if (path == '/api/auth/login') {
      return users[body['email']] == body['password'] ? json({'token': validToken}) : json({'error': 'Invalid credentials'}, 401);
    }
    if (o.headers['Authorization'] != 'Bearer $validToken') return json({'error': 'unauthorized'}, 401);

    if (path == '/api/profiles' && o.method == 'GET') return json(profiles.values.toList());
    if (path == '/api/profiles' && o.method == 'POST') {
      final id = body['id'] as String;
      profiles[id] = Map<String, dynamic>.from(body);
      return json({'id': id});
    }
    final id = Uri.decodeComponent(path.replaceFirst('/api/profiles/', ''));
    if (o.method == 'PUT') {
      if (!supportsPut) return json({'error': 'method not allowed'}, 405);
      if (!profiles.containsKey(id)) return json({'error': 'not found'}, 404);
      profiles[id] = Map<String, dynamic>.from(body);
      return json({'id': id});
    }
    if (o.method == 'DELETE') {
      return profiles.remove(id) == null ? json({'error': 'not found'}, 404) : json({'ok': true});
    }
    return json({'error': 'not found'}, 404);
  }

  @override
  void close({bool force = false}) {}
}

Future<int> addLocal(AppDatabase db, String name) => db.into(db.profiles).insert(ProfilesCompanion.insert(
      name: name,
      dob: encodeWallClock(1990, 6, 15, 14, 30),
      pob: 'Mumbai',
      lat: 19.07,
      lon: 72.88,
      timezone: const Value(5.5),
      tzName: const Value('Asia/Kolkata'),
    ));

void main() {
  late AppDatabase db;
  late FakeServer server;
  late SyncService sync;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    server = FakeServer();
    final dio = Dio(BaseOptions(baseUrl: 'https://sync.test', headers: {'Authorization': 'Bearer token-1'}))
      ..httpClientAdapter = server;
    sync = SyncService(dio, db);
  });
  tearDown(() => db.close());

  test('uploads new profiles once with a stable id and wall-clock birth time', () async {
    await addLocal(db, 'Asha');
    final r1 = await sync.sync();
    expect(r1.pushed, 1);
    expect(server.profiles.length, 1);
    final remote = server.profiles.values.first;
    expect(remote['dob'], '1990-06-15T14:30:00.000');
    expect(remote['timezone'], 5.5);
    expect(remote['tzName'], 'Asia/Kolkata');

    final local = await db.select(db.profiles).getSingle();
    expect(local.needsSync, isFalse);
    expect(local.cloudflareId, remote['id']);

    final r2 = await sync.sync();
    expect(r2.pushed, 0, reason: 'nothing changed');
    expect(server.profiles.length, 1, reason: 'no duplicates');
  });

  test('edits are sent with PUT, or POST upsert when the server has no PUT', () async {
    await addLocal(db, 'Asha');
    await sync.sync();
    var p = await db.select(db.profiles).getSingle();
    await db.update(db.profiles).replace(p.copyWith(name: 'Asha K', needsSync: true, updatedAt: DateTime(2030)));
    await sync.sync();
    expect(server.log, contains('PUT /api/profiles/${p.cloudflareId}'));
    expect(server.profiles[p.cloudflareId]!['name'], 'Asha K');

    server.supportsPut = false;
    p = await db.select(db.profiles).getSingle();
    await db.update(db.profiles).replace(p.copyWith(name: 'Asha R', needsSync: true, updatedAt: DateTime(2031)));
    await sync.sync();
    expect(server.profiles.length, 1);
    expect(server.profiles[p.cloudflareId]!['name'], 'Asha R');
  });

  test('downloads remote profiles, keeps local unsent edits, and reads old-format fields', () async {
    server.profiles['remote-1'] = {
      'id': 'remote-1', 'name': 'Ravi', 'dob': '1985-07-04T23:45:00.000Z', 'pob': 'Delhi', 'lat': '28.6', 'lon': 77.2,
    };
    final r = await sync.sync();
    expect(r.pulled, 1);
    final ravi = await db.select(db.profiles).getSingle();
    final b = ravi.birthWallClock;
    expect([b.year, b.month, b.day, b.hour, b.minute], [1985, 7, 4, 23, 45]);
    expect(ravi.timezone, 5.5, reason: 'default when the server has no timezone');
    expect(ravi.lat, 28.6);

    // Local unsent edit wins over a concurrent server change.
    await db.update(db.profiles).replace(ravi.copyWith(name: 'Ravi (local)', needsSync: true, updatedAt: DateTime(2030)));
    server.profiles['remote-1']!['name'] = 'Ravi (server)';
    await sync.sync();
    expect((await db.select(db.profiles).getSingle()).name, 'Ravi (local)');
    expect(server.profiles['remote-1']!['name'], 'Ravi (local)');

    // With no local edits the server copy wins.
    server.profiles['remote-1']!['name'] = 'Ravi (server 2)';
    await sync.sync();
    expect((await db.select(db.profiles).getSingle()).name, 'Ravi (server 2)');
  });

  test('deletions reach the server and deleted profiles do not come back', () async {
    await addLocal(db, 'Temp');
    await sync.sync();
    final p = await db.select(db.profiles).getSingle();

    // Delete through the notifier path: tombstone + row removal.
    final container = ProviderContainer(overrides: [databaseProvider.overrideWithValue(db)]);
    addTearDown(container.dispose);
    FlutterSecureStorage.setMockInitialValues({});
    await container.read(profileNotifierProvider.notifier).deleteProfile(p);

    expect(await db.select(db.pendingDeletions).get(), hasLength(1));
    final r = await sync.sync();
    expect(r.deleted, 1);
    expect(server.profiles, isEmpty);
    expect(await db.select(db.profiles).get(), isEmpty);
    expect(await db.select(db.pendingDeletions).get(), isEmpty);
  });

  test('an expired session is reported as unauthorized', () async {
    server.validToken = 'other';
    await addLocal(db, 'Asha');
    expect(sync.sync(), throwsA(isA<SyncException>().having((e) => e.unauthorized, 'unauthorized', isTrue)));
  });

  group('SyncController', () {
    ProviderContainer makeContainer() {
      final c = ProviderContainer(overrides: [databaseProvider.overrideWithValue(db)]);
      c.read(syncProvider.notifier).httpAdapterForTesting = server;
      return c;
    }

    test('register without a token falls back to sign in, then syncs', () async {
      FlutterSecureStorage.setMockInitialValues({});
      final c = makeContainer();
      addTearDown(c.dispose);
      await Future<void>.delayed(Duration.zero); // restore saved session
      await addLocal(db, 'Asha');

      final ok = await c.read(syncProvider.notifier).register('me@example.com', 'secret1');
      expect(ok, isTrue);
      final s = c.read(syncProvider);
      expect(s.signedIn, isTrue);
      expect(s.email, 'me@example.com');
      expect(s.lastSync, isNotNull);
      expect(server.log, containsAllInOrder(['POST /api/auth/register', 'POST /api/auth/login', 'POST /api/profiles']));
      expect(await const FlutterSecureStorage().read(key: 'jwt_token'), 'token-1');

      await c.read(syncProvider.notifier).signOut();
      expect(c.read(syncProvider).signedIn, isFalse);
      expect(await db.select(db.profiles).get(), hasLength(1), reason: 'sign out keeps local data');
    });

    test('wrong password shows an error and stays signed out', () async {
      FlutterSecureStorage.setMockInitialValues({});
      server.users['me@example.com'] = 'secret1';
      final c = makeContainer();
      addTearDown(c.dispose);
      await Future<void>.delayed(Duration.zero);
      final ok = await c.read(syncProvider.notifier).signIn('me@example.com', 'nope');
      expect(ok, isFalse);
      expect(c.read(syncProvider).signedIn, isFalse);
      expect(c.read(syncProvider).error, contains('Invalid credentials'));
    });

    test('a 401 during sync signs the user out', () async {
      FlutterSecureStorage.setMockInitialValues({'jwt_token': 'stale', 'sync_email': 'me@example.com'});
      final c = makeContainer();
      addTearDown(c.dispose);
      c.read(syncProvider);
      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(c.read(syncProvider).signedIn, isTrue);
      await c.read(syncProvider.notifier).syncNow();
      expect(c.read(syncProvider).signedIn, isFalse);
      expect(c.read(syncProvider).error, contains('sign in again'));
    });
  });
}
