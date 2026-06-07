import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../services/api_client.dart';

final authProvider = NotifierProvider<AuthNotifier, AuthState>(AuthNotifier.new);

class AuthState {
  final bool isAuthenticated;
  final bool isLoading;
  final String? error;

  AuthState({this.isAuthenticated = false, this.isLoading = true, this.error});

  AuthState copyWith({bool? isAuthenticated, bool? isLoading, String? error}) {
    return AuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class AuthNotifier extends Notifier<AuthState> {
  final _storage = const FlutterSecureStorage();

  @override
  AuthState build() {
    _checkAuth();
    return AuthState(isLoading: true);
  }

  Future<void> _checkAuth() async {
    final token = await _storage.read(key: 'jwt_token');
    if (token != null) {
      try {
        state = state.copyWith(isAuthenticated: true, isLoading: false);
      } catch (e) {
        state = state.copyWith(isAuthenticated: false, isLoading: false);
      }
    } else {
      state = state.copyWith(isAuthenticated: false, isLoading: false);
    }
  }

  Future<bool> login(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final dio = ref.read(apiClientProvider);
      final response = await dio.post('/api/auth/login', data: {
        'email': email,
        'password': password,
      });
      
      final token = response.data['token']; // assuming the response contains a token field
      if (token != null) {
        await _storage.write(key: 'jwt_token', value: token);
        state = state.copyWith(isAuthenticated: true, isLoading: false);
        return true;
      } else {
        state = state.copyWith(isLoading: false, error: 'Login failed: Invalid response format');
        return false;
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Login failed: ${e.toString()}');
      return false;
    }
  }

  Future<bool> register(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final dio = ref.read(apiClientProvider);
      final response = await dio.post('/api/auth/register', data: {
        'email': email,
        'password': password,
      });
      
      // Some APIs return token on register, some require separate login.
      // Assuming it returns token or we login right after.
      final token = response.data['token'];
      if (token != null) {
        await _storage.write(key: 'jwt_token', value: token);
        state = state.copyWith(isAuthenticated: true, isLoading: false);
        return true;
      } else {
        // If no token returned, they need to log in, but registration succeeded
        state = state.copyWith(isLoading: false);
        return true;
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Registration failed: ${e.toString()}');
      return false;
    }
  }

  Future<void> logout() async {
    await _storage.delete(key: 'jwt_token');
    state = state.copyWith(isAuthenticated: false);
  }
}
