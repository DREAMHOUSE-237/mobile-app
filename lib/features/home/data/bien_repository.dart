import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/network/connectivity_service.dart';
import '../../../core/storage/cache_service.dart';
import 'bien_model.dart';

// ══════════════════════════════════════════════════════════════════════════════
// FILTRE DE RECHERCHE
// ══════════════════════════════════════════════════════════════════════════════
class BienFilter {
  final String? ville;
  final String? categorie;
  final String? type;
  final String? quartier;
  final double? prixMax;
  final int?    piecesMin;

  const BienFilter({
    this.ville, this.categorie, this.type,
    this.quartier, this.prixMax, this.piecesMin,
  });

  bool get isEmpty =>
      ville == null && categorie == null && type == null &&
      quartier == null && prixMax == null && piecesMin == null;
}

// ══════════════════════════════════════════════════════════════════════════════
// BIEN REPOSITORY — avec cache offline (US-036)
// ══════════════════════════════════════════════════════════════════════════════
class BienRepository {
  final ApiClient          _api;
  final CacheService       _cache;
  final ConnectivityService _connectivity;

  BienRepository(this._api, this._cache, this._connectivity);

  // ── Tous les biens (avec fallback cache) ─────────────────────────────────
  Future<List<BienModel>> getAll() async {
    final online = await _connectivity.isConnected();
    if (!online) {
      final cached = await _cache.loadBiens();
      if (cached != null) return cached;
      throw const ApiException(
          message: 'Pas de connexion. Aucun cache disponible.');
    }
    final data  = await _api.get(ApiEndpoints.biens);
    final biens = _parseList(data);
    // Mise en cache en arrière-plan
    _cache.saveBiens(biens);
    return biens;
  }

  // ── Recherche avec filtres ────────────────────────────────────────────────
  Future<List<BienModel>> search(BienFilter filter) async {
    if (filter.isEmpty) return getAll();

    if (filter.ville != null && filter.prixMax != null) {
      final data = await _api.get(ApiEndpoints.bienSearchVillePrix(
          filter.ville!, filter.prixMax!.toInt().toString()));
      return _parseAndFilter(data, filter);
    }
    if (filter.ville != null) {
      final data = await _api.get(ApiEndpoints.bienSearchVille(filter.ville!));
      return _parseAndFilter(data, filter);
    }
    if (filter.categorie != null) {
      final data = await _api.get(
          ApiEndpoints.bienSearchCategorie(filter.categorie!));
      return _parseAndFilter(data, filter);
    }
    if (filter.quartier != null) {
      final data = await _api.get(
          ApiEndpoints.bienSearchQuartier(filter.quartier!));
      return _parseAndFilter(data, filter);
    }
    if (filter.prixMax != null) {
      final data = await _api.get(
          ApiEndpoints.bienSearchPrixMax(filter.prixMax!.toInt().toString()));
      return _parseAndFilter(data, filter);
    }
    return getAll();
  }

  // ── Détail (avec cache) ───────────────────────────────────────────────────
  Future<BienModel> getById(String id) async {
    final online = await _connectivity.isConnected();
    if (!online) {
      final cached = await _cache.loadBienDetail(id);
      if (cached != null) return cached;
      throw const ApiException(message: 'Pas de connexion.');
    }
    final data = await _api.get(ApiEndpoints.bienById(id));
    if (data is Map<String, dynamic>) {
      final bien = BienModel.fromJson(data);
      _cache.saveBienDetail(bien);
      return bien;
    }
    throw const ApiException(message: 'Bien introuvable');
  }

  // ── Mes publications ──────────────────────────────────────────────────────
  Future<List<BienModel>> getMesPublications() async {
    final data = await _api.get(ApiEndpoints.mesPublications);
    return _parseList(data);
  }

  // ── CRUD ──────────────────────────────────────────────────────────────────
  Future<BienModel> create(Map<String, dynamic> payload) async {
    final data = await _api.post(ApiEndpoints.biens, data: payload);
    return BienModel.fromJson(data as Map<String, dynamic>);
  }

  Future<BienModel> update(String id, Map<String, dynamic> payload) async {
    final data = await _api.put(ApiEndpoints.bienById(id), data: payload);
    return BienModel.fromJson(data as Map<String, dynamic>);
  }

  Future<void> delete(String id) => _api.delete(ApiEndpoints.bienById(id));

  // ── Helpers privés ────────────────────────────────────────────────────────
  List<BienModel> _parseList(dynamic data) {
    if (data is List) {
      return data.map((e) => BienModel.fromJson(e)).toList();
    }
    if (data is Map && data['results'] is List) {
      return (data['results'] as List)
          .map((e) => BienModel.fromJson(e))
          .toList();
    }
    return [];
  }

  List<BienModel> _parseAndFilter(dynamic data, BienFilter filter) {
    final list = _parseList(data);
    return list.where((b) {
      if (filter.type != null &&
          filter.type != 'Tous les types' &&
          b.typePublication.toLowerCase() != filter.type!.toLowerCase()) {
        return false;
      }
      if (filter.piecesMin != null && b.nbPieces < filter.piecesMin!) {
        return false;
      }
      return true;
    }).toList();
  }
}

final bienRepositoryProvider = Provider<BienRepository>((ref) {
  return BienRepository(
    ref.watch(apiClientProvider),
    ref.watch(cacheServiceProvider),
    ref.watch(connectivityServiceProvider),
  );
});
