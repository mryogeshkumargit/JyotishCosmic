import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../services/sync_service.dart';
import 'database_provider.dart';

/// Keys in secure storage.
const _kToken = 'jwt_token';
const _kEmail = 'sync_email';
const _kServer = 'sync_server_url';
const _kLastAccount = 'sync_last_account';

const String defaultSyncServer = 'https://jyotish-cosmic.pages.dev';

/// Where the sync token and settings are persisted. Overridable in tests.
final secureStorageProvider = Provider<FlutterSecureStorage>((ref) => const FlutterSecureStorage());

class SyncState {
  final bool loading; // restoring the saved session
  final String serverUrl;
  final String? email;
  final String? token;
  final bool busy; // signing in or syncing
  final String? error;
  final DateTime? lastSync;
  final String? lastResult;

  const SyncState({
    this.loading = true,
    this.serverUrl = defaultSyncServer,
    this.email,
    this.token,
    this.busy = false,
    this.error,
    this.lastSync,
    this.lastResult,
  });

  bool get signedIn => token != null;

  SyncState copyWith({
    bool? loading,
    String? serverUrl,
    String? email,
    String? token,
    bool clearToken = false,
    bool? busy,
    String? error,
    bool clearError = false,
    DateTime? lastSync,
    String? lastResult,
  }) {
    return SyncState(
      loading: loading ?? this.loading,
      serverUrl: serverUrl ?? this.serverUrl,
      email: email ?? this.email,
      token: clearToken ? null : (token ?? this.token),
      busy: busy ?? this.busy,
      error: clearError ? null : (error ?? this.error),
      lastSync: lastSync ?? this.lastSync,
      lastResult: lastResult ?? this.lastResult,
    );
  }
}

final syncProvider = NotifierProvider<SyncController, SyncState>(SyncController.new);

/// Optional cloud sync: sign-in, token storage and background sync scheduling.
class SyncController extends Notifier<SyncState> {
  Timer? _debounce;
  Future<void>? _running;

  FlutterSecureStorage get _storage => ref.read(secureStorageProvider);

  @override
  SyncState build() {
    ref.onDispose(() => _debounce?.cancel());
    Future.microtask(_restore);
    return const SyncState();
  }

  Future<void> _restore() async {
    try {
      final values = await _storage.readAll();
      state = state.copyWith(
        loading: false,
        serverUrl: values[_kServer] ?? defaultSyncServer,
        email: values[_kEmail],
        token: values[_kToken],
      );
      if (state.signedIn) scheduleSync(delay: const Duration(seconds: 2));
    } catch (_) {
      state = state.copyWith(loading: false);
    }
  }

  Dio _dio({bool withAuth = true}) {
    final dio = Dio(BaseOptions(
      baseUrl: state.serverUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 30),
      contentType: Headers.jsonContentType,
    ));
    if (withAuth && state.token != null) {
      dio.options.headers['Authorization'] = 'Bearer ${state.token}';
    }
    return dio;
  }

  /// Visible for tests: lets a fake HTTP adapter be installed.
  HttpClientAdapter? httpAdapterForTesting;

  Dio _client({bool withAuth = true}) {
    final dio = _dio(withAuth: withAuth);
    if (httpAdapterForTesting != null) dio.httpClientAdapter = httpAdapterForTesting!;
    return dio;
  }

  Future<void> setServerUrl(String url) async {
    final clean = url.trim().replaceAll(RegExp(r'/+$'), '');
    if (clean.isEmpty) return;
    state = state.copyWith(serverUrl: clean);
    await _storage.write(key: _kServer, value: clean);
  }

  static String? _tokenFrom(dynamic data) {
    if (data is! Map) return null;
    for (final key in ['token', 'jwt', 'accessToken', 'access_token']) {
      final v = data[key];
      if (v is String && v.isNotEmpty) return v;
    }
    return null;
  }

  String _authError(Object e, String action) {
    if (e is DioException) {
      final status = e.response?.statusCode;
      final data = e.response?.data;
      final msg = data is Map ? (data['error'] ?? data['message']) : null;
      if (msg != null) return '$action failed: $msg';
      if (status == 401 || status == 403) return '$action failed: wrong email or password';
      if (status != null) return '$action failed (HTTP $status)';
      return '$action failed: cannot reach ${state.serverUrl}';
    }
    return '$action failed: $e';
  }

  /// Signs in and runs a first sync. Returns true on success.
  Future<bool> signIn(String email, String password) async {
    state = state.copyWith(busy: true, clearError: true);
    try {
      final res = await _client(withAuth: false)
          .post('/api/auth/login', data: {'email': email.trim(), 'password': password});
      final token = _tokenFrom(res.data);
      if (token == null) throw 'the server did not return a session token';
      await _onSignedIn(email.trim(), token);
      return true;
    } catch (e) {
      state = state.copyWith(busy: false, error: _authError(e, 'Sign in'));
      return false;
    }
  }

  /// Creates an account, then signs in. Returns true on success.
  Future<bool> register(String email, String password) async {
    state = state.copyWith(busy: true, clearError: true);
    try {
      final res = await _client(withAuth: false)
          .post('/api/auth/register', data: {'email': email.trim(), 'password': password});
      final token = _tokenFrom(res.data);
      if (token != null) {
        await _onSignedIn(email.trim(), token);
        return true;
      }
    } catch (e) {
      state = state.copyWith(busy: false, error: _authError(e, 'Registration'));
      return false;
    }
    // Some servers only create the account; sign in explicitly.
    return signIn(email, password);
  }

  Future<void> _onSignedIn(String email, String token) async {
    final lastAccount = await _storage.read(key: _kLastAccount);
    final account = '${state.serverUrl}|${email.toLowerCase()}';
    if (lastAccount != account) {
      // Different account or server: upload every local profile to it as new.
      final db = ref.read(databaseProvider);
      await db.customUpdate('UPDATE profiles SET needs_sync = 1, cloudflare_id = NULL',
          updates: {db.profiles});
      await db.delete(db.pendingDeletions).go();
      await _storage.write(key: _kLastAccount, value: account);
    }
    await _storage.write(key: _kToken, value: token);
    await _storage.write(key: _kEmail, value: email);
    state = state.copyWith(token: token, email: email, busy: false, clearError: true);
    await syncNow();
  }

  Future<void> signOut() async {
    _debounce?.cancel();
    await _storage.delete(key: _kToken);
    state = state.copyWith(clearToken: true, clearError: true);
  }

  /// Debounced background sync after local edits (no-op when signed out).
  void scheduleSync({Duration delay = const Duration(seconds: 3)}) {
    if (!state.signedIn) return;
    _debounce?.cancel();
    _debounce = Timer(delay, () => syncNow());
  }

  Future<void> syncNow() {
    if (!state.signedIn) return Future.value();
    return _running ??= _doSync().whenComplete(() => _running = null);
  }

  Future<void> _doSync() async {
    state = state.copyWith(busy: true, clearError: true);
    try {
      final result = await SyncService(_client(), ref.read(databaseProvider)).sync();
      state = state.copyWith(
        busy: false,
        lastSync: DateTime.now(),
        lastResult: result.summary,
        error: result.errors.isEmpty ? null : result.errors.first,
        clearError: result.errors.isEmpty,
      );
    } on SyncException catch (e) {
      if (e.unauthorized) {
        await _storage.delete(key: _kToken);
        state = state.copyWith(busy: false, clearToken: true, error: e.message);
      } else {
        state = state.copyWith(busy: false, error: e.message);
      }
    } catch (e) {
      state = state.copyWith(busy: false, error: 'Sync failed: $e');
    }
  }
}
