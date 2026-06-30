import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/storage/secure_storage.dart';
import '../../auth/data/user_model.dart';

// ══════════════════════════════════════════════════════════════════════════════
// PROFILE REPOSITORY — Aligné avec getUserProfile + updateProfile du frontend
// getUserProfile   : GET /USER-SERVICE/users/users/{userId}/profile/
// updateProfile    : PATCH /USER-SERVICE/users/user/{userId}/modification/
// ══════════════════════════════════════════════════════════════════════════════
class ProfileRepository {
  final ApiClient _api;
  final SecureStorage _storage;
  ProfileRepository(this._api, this._storage);

  // ── Récupérer le profil ───────────────────────────────────────────────────
  Future<UserModel> getProfile() async {
    // getUserId() = user_service_id (comme localStorage.getItem('userId'))
    final id   = await _storage.getUserId();
    if (id == null || id.isEmpty) {
      throw const ApiException(
          message: 'ID utilisateur introuvable. Reconnectez-vous.');
    }
    final data = await _api.get(ApiEndpoints.userProfile(id));
    final user = UserModel.fromJson(data as Map<String, dynamic>);
    await _storage.saveUserObject(user.toJson());
    return user;
  }

  // ── Modifier le profil — PATCH (comme updateProfile dans auth_service.js) ─
  Future<UserModel> updateProfile({
    required String nom,
    required String prenom,
    required String tel,      // "tel" comme dans le frontend
    required String ville,
    required String region,
  }) async {
    final id   = await _storage.getUserId();
    final data = await _api.patch(
      ApiEndpoints.userUpdate(id ?? ''),
      data: {
        'nom':    nom,
        'prenom': prenom,
        'tel':    tel,
        'ville':  ville,
        'region': region,
      },
    );
    final user = UserModel.fromJson(data as Map<String, dynamic>);
    await _storage.saveUserObject(user.toJson());
    return user;
  }

  // ── Soumettre CNI ─────────────────────────────────────────────────────────
  Future<void> submitIdentity({
    required File cniRecto,
    required File cniVerso,
  }) async {
    final formData = FormData.fromMap({
      'cni_recto': await MultipartFile.fromFile(
          cniRecto.path, filename: 'cni_recto.jpg'),
      'cni_verso': await MultipartFile.fromFile(
          cniVerso.path, filename: 'cni_verso.jpg'),
    });
    await _api.postMultipart(ApiEndpoints.identitySubmit, formData);
  }

  // ── Statut vérification identité ──────────────────────────────────────────
  Future<Map<String, dynamic>?> getIdentityStatus() async {
    try {
      final email = await _storage.getUserEmail();
      final data  = await _api.get(
          '${ApiEndpoints.identityStatus}?email=$email');
      return data as Map<String, dynamic>?;
    } catch (_) {
      return null;
    }
  }
}

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return ProfileRepository(
    ref.watch(apiClientProvider),
    ref.watch(secureStorageProvider),
  );
});

final userProfileProvider =
    FutureProvider.autoDispose<UserModel>((ref) {
  return ref.watch(profileRepositoryProvider).getProfile();
});

final identityStatusProvider =
    FutureProvider.autoDispose<Map<String, dynamic>?>((ref) {
  return ref.watch(profileRepositoryProvider).getIdentityStatus();
});
