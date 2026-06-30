import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/storage/secure_storage.dart';
import 'user_model.dart';

// ══════════════════════════════════════════════════════════════════════════════
// AUTH REPOSITORY — Aligné avec auth_service.js du nouveau frontend
// FIX : champs agence transmis au backend (nomAgence, nomPDG, etc.)
// ══════════════════════════════════════════════════════════════════════════════
class AuthRepository {
  final ApiClient _api;
  final SecureStorage _storage;

  AuthRepository(this._api, this._storage);

  // ── LOGIN ─────────────────────────────────────────────────────────────────
  Future<UserModel> login({
    required String email,
    required String password,
  }) async {
    final data = await _api.post(
      ApiEndpoints.login,
      data: {'email': email, 'password': password},
    );

    final token    = data['access'] as String;
    final userData = data['user'] as Map<String, dynamic>?;
    final user     = _buildUserFromResponse(token, userData);

    await _storage.saveSession(
      token:      token,
      userId:     user.serviceId,
      userUuid:   user.uuid,
      email:      user.email,
      role:       user.role,
      userObject: user.toJson(),
    );

    return user;
  }

  // ── REGISTER CLIENT ───────────────────────────────────────────────────────
  Future<void> registerClient({
    required String nom,
    required String prenom,
    required String email,
    required String tel,
    required String ville,
    required String region,
    required String password,
    required String role,
  }) async {
    await _api.post(ApiEndpoints.register, data: {
      'nom':      nom,
      'prenom':   prenom,
      'email':    email,
      'password': password,
      'tel':      tel,
      'ville':    ville,
      'region':   region,
      'role':     role,
    });
  }

  // ── REGISTER PROPRIO/AGENCE avec CNI ─────────────────────────────────────
  // FIX : les champs agence (nomAgence, nomPDG, etc.) sont inclus dans
  // l'appel registerUser, aligné sur Inscription.jsx lignes 52-69
  Future<void> registerWithIdentity({
    required String nom,
    required String prenom,
    required String email,
    required String tel,
    required String ville,
    required String region,
    required String password,
    required String role,
    required File cniRecto,
    required File cniVerso,
    String? nomAgence,
    String? nomPDG,
    String? numeroIdentification,
    String? contactPrincipal,
    String? quartier,
  }) async {
    final cleanTel = tel.replaceAll(RegExp(r'[+\s\-]'), '')
        .replaceFirst(RegExp(r'^237'), '');

    // Étape 1 : Créer le compte utilisateur avec tous les champs du rôle
    final Map<String, dynamic> userData = {
      'nom': nom, 'prenom': prenom, 'email': email,
      'password': password, 'tel': cleanTel,
      'ville': ville, 'region': region, 'role': role,
    };

    // Champs agence si présents (Inscription.jsx lignes 62-66)
    if (role == 'agence') {
      if (nomAgence != null && nomAgence.isNotEmpty)
        userData['nomAgence'] = nomAgence;
      if (nomPDG != null && nomPDG.isNotEmpty)
        userData['nomPDG'] = nomPDG;
      if (numeroIdentification != null && numeroIdentification.isNotEmpty)
        userData['numeroIdentification'] = numeroIdentification;
      if (contactPrincipal != null && contactPrincipal.isNotEmpty)
        userData['contactPrincipal'] = contactPrincipal;
      if (quartier != null && quartier.isNotEmpty)
        userData['quartier'] = quartier;
    }

    await _api.post(ApiEndpoints.register, data: userData);

    // Étape 2 : Soumettre la CNI à l'Identity Service
    final identityForm = FormData.fromMap({
      'email':          email,
      'password':       password,
      'requested_role': role,
      if (role == 'agence' && nomAgence != null)
        'nom_agence': nomAgence,
      if (role == 'agence' && numeroIdentification != null)
        'numero_identification': numeroIdentification,
      'cni_recto': await MultipartFile.fromFile(
          cniRecto.path, filename: 'cni_recto.jpg'),
      'cni_verso': await MultipartFile.fromFile(
          cniVerso.path, filename: 'cni_verso.jpg'),
    });
    await _api.postMultipart(ApiEndpoints.identitySubmit, identityForm);
  }

  // ── LOGOUT ────────────────────────────────────────────────────────────────
  Future<void> logout() => _storage.clearAll();

  Future<UserModel?> getCurrentUser() async {
    final json = await _storage.getUserObject();
    if (json == null) return null;
    return UserModel.fromJson(json);
  }

  Future<bool> isLoggedIn() => _storage.hasValidSession();

  // ── DÉCODAGE JWT ──────────────────────────────────────────────────────────
  UserModel _buildUserFromResponse(
    String token,
    Map<String, dynamic>? userData,
  ) {
    try {
      final parts   = token.split('.');
      final payload = jsonDecode(
        utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))),
      ) as Map<String, dynamic>;

      final serviceId = userData?['user_service_id']?.toString()
          ?? payload['user_service_id']?.toString()
          ?? payload['user_id']?.toString()
          ?? '';

      final uuid  = payload['user_id']?.toString()  ?? '';
      final email = payload['email']?.toString()     ?? '';
      final role  = payload['role']?.toString()      ?? 'client';

      return UserModel(
        id:        serviceId,
        uuid:      uuid,
        serviceId: serviceId,
        email:     email,
        role:      role,
        nom:       userData?['nom'],
        prenom:    userData?['prenom'],
      );
    } catch (e) {
      return UserModel(
        id:        '',
        uuid:      '',
        serviceId: '',
        email:     userData?['email'] ?? '',
        role:      'client',
      );
    }
  }
}

final authRepositoryProvider = Provider<AuthRepository>((ref) => AuthRepository(
  ref.watch(apiClientProvider),
  ref.watch(secureStorageProvider),
));