import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ══════════════════════════════════════════════════════════════════════════════
// SECURE STORAGE — Adaptatif Web / Mobile
//
// Sur Web  (kIsWeb = true)  → SharedPreferences
//   flutter_secure_storage utilise Web Crypto API qui requiert HTTPS
//   Sur localhost sans HTTPS → OperationError. On bascule sur SharedPreferences.
//
// Sur Mobile (Android/iOS)  → FlutterSecureStorage (chiffré)
// ══════════════════════════════════════════════════════════════════════════════

class _Keys {
  static const String token      = 'jwt_token';
  static const String userId     = 'user_id';       // user_service_id
  static const String userUuid   = 'user_uuid';     // user_id JWT (UUID)
  static const String userEmail  = 'user_email';
  static const String userRole   = 'user_role';
  static const String userObject = 'user_object';
}

class SecureStorage {
  // ── Stockage mobile (chiffré) ─────────────────────────────────────────────
  static const _secureStorage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  // ── Lecture/Écriture adaptative ───────────────────────────────────────────
  Future<void> _write(String key, String value) async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(key, value);
    } else {
      await _secureStorage.write(key: key, value: value);
    }
  }

  Future<String?> _read(String key) async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(key);
    } else {
      return _secureStorage.read(key: key);
    }
  }

  Future<void> _delete(String key) async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(key);
    } else {
      await _secureStorage.delete(key: key);
    }
  }

  Future<void> _deleteAll() async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_Keys.token);
      await prefs.remove(_Keys.userId);
      await prefs.remove(_Keys.userUuid);
      await prefs.remove(_Keys.userEmail);
      await prefs.remove(_Keys.userRole);
      await prefs.remove(_Keys.userObject);
    } else {
      await _secureStorage.deleteAll();
    }
  }

  // ── API publique ──────────────────────────────────────────────────────────
  Future<void> saveToken(String token)     => _write(_Keys.token, token);
  Future<String?> getToken()               => _read(_Keys.token);
  Future<void> deleteToken()               => _delete(_Keys.token);

  Future<void> saveUserId(String id)       => _write(_Keys.userId, id);
  Future<String?> getUserId()              => _read(_Keys.userId);

  Future<void> saveUserUuid(String uuid)   => _write(_Keys.userUuid, uuid);
  Future<String?> getUserUuid()            => _read(_Keys.userUuid);

  Future<void> saveUserEmail(String email) => _write(_Keys.userEmail, email);
  Future<String?> getUserEmail()           => _read(_Keys.userEmail);

  Future<void> saveUserRole(String role)   => _write(_Keys.userRole, role);
  Future<String?> getUserRole()            => _read(_Keys.userRole);

  Future<void> saveUserObject(Map<String, dynamic> user) =>
      _write(_Keys.userObject, jsonEncode(user));

  Future<Map<String, dynamic>?> getUserObject() async {
    final raw = await _read(_Keys.userObject);
    if (raw == null) return null;
    try {
      return jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  // ── Session complète ──────────────────────────────────────────────────────
  Future<void> saveSession({
    required String token,
    required String userId,
    required String userUuid,
    required String email,
    required String role,
    required Map<String, dynamic> userObject,
  }) async {
    await Future.wait([
      saveToken(token),
      saveUserId(userId),
      saveUserUuid(userUuid),
      saveUserEmail(email),
      saveUserRole(role),
      saveUserObject(userObject),
    ]);
  }

  // ── Vérification JWT ──────────────────────────────────────────────────────
  Future<bool> hasValidSession() async {
    final token = await getToken();
    if (token == null || token.isEmpty) return false;
    try {
      final parts = token.split('.');
      if (parts.length != 3) return false;
      final payload = jsonDecode(
        utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))),
      ) as Map<String, dynamic>;
      final exp = payload['exp'] as int?;
      if (exp == null) return true;
      return DateTime.fromMillisecondsSinceEpoch(exp * 1000)
          .isAfter(DateTime.now());
    } catch (_) {
      return false;
    }
  }

  // ── Déconnexion ───────────────────────────────────────────────────────────
  Future<void> clearAll() => _deleteAll();
}

final secureStorageProvider =
    Provider<SecureStorage>((ref) => SecureStorage());
