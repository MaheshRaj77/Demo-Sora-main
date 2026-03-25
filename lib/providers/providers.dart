/// ─── Riverpod Providers ─────────────────────────────────────
/// Central provider definitions for the entire app.
/// Uses Riverpod for dependency injection and state management.
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/user_model.dart';
import '../data/repositories/auth_repository.dart';
import '../data/repositories/feature_repository.dart';

// ── Repository Providers ────────────────────────────────────
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository();
});

final featureRepositoryProvider = Provider<FeatureRepository>((ref) {
  return FeatureRepository();
});

// ── Auth State ──────────────────────────────────────────────
enum AuthStatus { initial, authenticated, unauthenticated, guest }

class AuthState {
  final AuthStatus status;
  final UserModel? user;
  final String? error;
  final bool isLoading;

  const AuthState({
    this.status = AuthStatus.initial,
    this.user,
    this.error,
    this.isLoading = false,
  });

  AuthState copyWith({
    AuthStatus? status,
    UserModel? user,
    String? error,
    bool? isLoading,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      error: error,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

// ── Auth Notifier ───────────────────────────────────────────
class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository _authRepo;

  AuthNotifier(this._authRepo) : super(const AuthState()) {
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    try {
      final isAuth = await _authRepo.isAuthenticated();
      if (isAuth) {
        final user = await _authRepo.getProfile();
        state = AuthState(status: AuthStatus.authenticated, user: user);
      } else {
        state = const AuthState(status: AuthStatus.unauthenticated);
      }
    } catch (_) {
      state = const AuthState(status: AuthStatus.unauthenticated);
    }
  }

  Future<void> login({required String email, required String password}) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final result = await _authRepo.login(email: email, password: password);
      state = AuthState(status: AuthStatus.authenticated, user: result.user);
    } on AuthException catch (e) {
      state = state.copyWith(isLoading: false, error: e.message);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Login failed. Please try again.');
    }
  }

  Future<void> register({
    required String email,
    required String password,
    required String fullName,
    String? department,
    int? year,
    int? semester,
    String? rollNumber,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final result = await _authRepo.register(
        email: email,
        password: password,
        fullName: fullName,
        department: department,
        year: year,
        semester: semester,
        rollNumber: rollNumber,
      );
      state = AuthState(status: AuthStatus.authenticated, user: result.user);
    } on AuthException catch (e) {
      state = state.copyWith(isLoading: false, error: e.message);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Registration failed.');
    }
  }

  void loginAsGuest() {
    state = AuthState(
      status: AuthStatus.guest,
      user: UserModel.guest,
    );
  }

  Future<void> logout() async {
    await _authRepo.logout();
    state = const AuthState(status: AuthStatus.unauthenticated);
  }

  Future<void> refreshProfile() async {
    try {
      final user = await _authRepo.getProfile();
      state = state.copyWith(user: user);
    } catch (_) {
      // Silently fail profile refresh
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref.read(authRepositoryProvider));
});

// ── Convenience providers ───────────────────────────────────
final currentUserProvider = Provider<UserModel?>((ref) {
  return ref.watch(authProvider).user;
});

final isAuthenticatedProvider = Provider<bool>((ref) {
  final status = ref.watch(authProvider).status;
  return status == AuthStatus.authenticated;
});

final isGuestProvider = Provider<bool>((ref) {
  return ref.watch(authProvider).status == AuthStatus.guest;
});
