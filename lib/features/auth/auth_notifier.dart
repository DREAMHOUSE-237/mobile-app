import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:io';
import 'data/auth_repository.dart';
import 'data/user_model.dart';
import '../../core/network/api_client.dart';

// ══════════════════════════════════════════════════════════════════════════════
// AUTH STATE
// ══════════════════════════════════════════════════════════════════════════════
enum AuthStatus { initial, loading, authenticated, unauthenticated, error }

class AuthState {
  final AuthStatus status;
  final UserModel? user;
  final String? errorMessage;

  const AuthState({
    this.status = AuthStatus.initial,
    this.user,
    this.errorMessage,
  });

  bool get isLoading       => status == AuthStatus.loading;
  bool get isAuthenticated => status == AuthStatus.authenticated;

  AuthState copyWith({
    AuthStatus? status, UserModel? user, String? errorMessage,
  }) => AuthState(
    status:       status       ?? this.status,
    user:         user         ?? this.user,
    errorMessage: errorMessage ?? this.errorMessage,
  );
}

// ══════════════════════════════════════════════════════════════════════════════
// AUTH NOTIFIER
// ══════════════════════════════════════════════════════════════════════════════
class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository _repo;

  AuthNotifier(this._repo) : super(const AuthState()) {
    _checkSession();
  }

  Future<void> _checkSession() async {
    state = state.copyWith(status: AuthStatus.loading);
    try {
      final loggedIn = await _repo.isLoggedIn();
      if (loggedIn) {
        final user = await _repo.getCurrentUser();
        state = AuthState(status: AuthStatus.authenticated, user: user);
      } else {
        state = const AuthState(status: AuthStatus.unauthenticated);
      }
    } catch (_) {
      state = const AuthState(status: AuthStatus.unauthenticated);
    }
  }

  // ── LOGIN ──────────────────────────────────────────────────────────────────
  Future<bool> login({
    required String email,
    required String password,
  }) async {
    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);
    try {
      await _repo.logout();
      final user = await _repo.login(email: email, password: password);
      state = AuthState(status: AuthStatus.authenticated, user: user);
      return true;
    } on ApiException catch (e) {
      state = AuthState(status: AuthStatus.error, errorMessage: e.message);
      return false;
    } catch (_) {
      state = const AuthState(
        status: AuthStatus.error,
        errorMessage: 'Impossible de se connecter. Vérifiez votre connexion.',
      );
      return false;
    }
  }

  // ── REGISTER — aligné avec Inscription.jsx ────────────────────────────────
  // FIX : ajout des champs agence (nomAgence, nomPDG, etc.) — optionnels via named params
  Future<bool> register({
    required String nom,
    required String prenom,
    required String email,
    required String tel,
    required String ville,
    required String region,
    required String password,
    required String role,
    File? cniRecto,
    File? cniVerso,
    // Champs agence (Inscription.jsx lignes 62-66)
    String? nomAgence,
    String? nomPDG,
    String? numeroIdentification,
    String? contactPrincipal,
    String? quartier,
  }) async {
    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);
    try {
      if ((role == 'proprietaire' || role == 'agence') &&
          cniRecto != null && cniVerso != null) {
        await _repo.registerWithIdentity(
          nom: nom, prenom: prenom, email: email, tel: tel,
          ville: ville, region: region, password: password,
          role: role, cniRecto: cniRecto, cniVerso: cniVerso,
          nomAgence: nomAgence,
          nomPDG: nomPDG,
          numeroIdentification: numeroIdentification,
          contactPrincipal: contactPrincipal,
          quartier: quartier,
        );
      } else {
        await _repo.registerClient(
          nom: nom, prenom: prenom, email: email, tel: tel,
          ville: ville, region: region, password: password, role: role,
        );
      }
      state = const AuthState(status: AuthStatus.unauthenticated);
      return true;
    } on ApiException catch (e) {
      state = AuthState(status: AuthStatus.error, errorMessage: e.message);
      return false;
    } catch (_) {
      state = const AuthState(
        status: AuthStatus.error,
        errorMessage: 'Erreur lors de l\'inscription.',
      );
      return false;
    }
  }

  // ── LOGOUT ─────────────────────────────────────────────────────────────────
  Future<void> logout() async {
    await _repo.logout();
    state = const AuthState(status: AuthStatus.unauthenticated);
  }

  void clearError() =>
      state = state.copyWith(errorMessage: null);
}

// ── PROVIDERS ─────────────────────────────────────────────────────────────────
final authNotifierProvider =
    StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref.watch(authRepositoryProvider));
});

final currentUserProvider = Provider<UserModel?>((ref) {
  return ref.watch(authNotifierProvider).user;
});