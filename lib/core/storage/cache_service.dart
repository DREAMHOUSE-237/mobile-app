import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../features/home/data/bien_model.dart';

// ══════════════════════════════════════════════════════════════════════════════
// CACHE SERVICE (US-036) — Stockage local des annonces
// Permet de voir les dernières annonces même sans connexion
// ══════════════════════════════════════════════════════════════════════════════
class CacheService {
  static const _keyBiens         = 'cache_biens';
  static const _keyBienDetail    = 'cache_bien_';
  static const _keyTimestamp     = 'cache_timestamp_biens';
  static const _cacheDuration    = Duration(hours: 2);

  // ── Sauvegarder la liste des biens ───────────────────────────────────────
  Future<void> saveBiens(List<BienModel> biens) async {
    final prefs = await SharedPreferences.getInstance();
    final json  = jsonEncode(biens.map((b) => b.toJson()).toList());
    await prefs.setString(_keyBiens, json);
    await prefs.setInt(
        _keyTimestamp, DateTime.now().millisecondsSinceEpoch);
  }

  // ── Charger la liste des biens ────────────────────────────────────────────
  Future<List<BienModel>?> loadBiens() async {
    final prefs = await SharedPreferences.getInstance();
    // Vérifier si le cache est encore valide
    final ts = prefs.getInt(_keyTimestamp);
    if (ts != null) {
      final age = DateTime.now().millisecondsSinceEpoch - ts;
      if (age > _cacheDuration.inMilliseconds) {
        await prefs.remove(_keyBiens);
        return null;
      }
    }
    final raw = prefs.getString(_keyBiens);
    if (raw == null) return null;
    try {
      final list = jsonDecode(raw) as List;
      return list.map((e) => BienModel.fromJson(e)).toList();
    } catch (_) {
      return null;
    }
  }

  // ── Sauvegarder le détail d'un bien ──────────────────────────────────────
  Future<void> saveBienDetail(BienModel bien) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        '$_keyBienDetail${bien.id}', jsonEncode(bien.toJson()));
  }

  // ── Charger le détail d'un bien ───────────────────────────────────────────
  Future<BienModel?> loadBienDetail(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final raw   = prefs.getString('$_keyBienDetail$id');
    if (raw == null) return null;
    try {
      return BienModel.fromJson(jsonDecode(raw));
    } catch (_) {
      return null;
    }
  }

  // ── Vider tout le cache ───────────────────────────────────────────────────
  Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    final keys  = prefs.getKeys()
        .where((k) => k.startsWith('cache_'))
        .toList();
    for (final k in keys) {
      await prefs.remove(k);
    }
  }

  // ── Taille du cache (debug) ───────────────────────────────────────────────
  Future<int> getCachedBienCount() async {
    final prefs = await SharedPreferences.getInstance();
    final raw   = prefs.getString(_keyBiens);
    if (raw == null) return 0;
    try {
      return (jsonDecode(raw) as List).length;
    } catch (_) {
      return 0;
    }
  }
}

final cacheServiceProvider = Provider<CacheService>((ref) => CacheService());
