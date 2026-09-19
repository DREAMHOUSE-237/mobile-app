import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../../home/data/bien_repository.dart';
import 'publication_form_state.dart';

// ══════════════════════════════════════════════════════════════════════════════
// PUBLICATION NOTIFIER
// IMPORTANT : PAS de autoDispose — le state doit survivre pendant tout le
// parcours de publication (3 étapes + modal paiement).
// autoDispose vidait le state entre les étapes, causant description/superfie/
// nbrePiece vides → erreur 400 du backend.
// ══════════════════════════════════════════════════════════════════════════════
class PublicationNotifier extends StateNotifier<PublicationFormState> {
  final ApiClient _api;
  PublicationNotifier(this._api) : super(const PublicationFormState());

  void updateStep1({
    required String titre,
    required String prix,
    required String superficie,
    required String nbPieces,
    required String description,
  }) {
    state = state.copyWith(
      titre:       titre,
      prix:        prix,
      superficie:  superficie,
      nbPieces:    nbPieces,
      description: description,
    );
  }

  void updateStep2({
    List<File>? photos,
    List<File>? documents,
    String? typePublication,
    String? typeBien,
    String? categorie,
    String? numeroPaiement,
  }) {
    state = state.copyWith(
      photos:          photos,
      documents:       documents,
      typePublication: typePublication,
      typeBien:        typeBien,
      categorie:       categorie,
      numeroPaiement:  numeroPaiement,
    );
  }

  void updateStep3({
    String? region, String? ville, String? quartier,
    double? latitude, double? longitude,
  }) {
    state = state.copyWith(
      region:    region,
      ville:     ville,
      quartier:  quartier,
      latitude:  latitude,
      longitude: longitude,
    );
  }

  // ── SOUMISSION (compatibilité) ────────────────────────────────────────────
  Future<void> submit() async {
    await submitAndGetId();
  }

  // ── SOUMISSION avec retour ID pour polling ────────────────────────────────
  // On lit le state AVANT tout reset, on construit le DTO, on envoie,
  // et on ne réinitialise qu'après avoir reçu l'ID du backend.
  Future<String?> submitAndGetId() async {
    // Snapshot du state courant (avec le numéro déjà mis à jour par updateStep2)
    final snapshot = state;

    final bienDTO = snapshot.toBienDTO();

    final formData = FormData();
    formData.files.add(MapEntry(
      'bien',
      MultipartFile.fromString(
        jsonEncode(bienDTO),
        contentType: DioMediaType('application', 'json'),
        filename: 'bien.json',
      ),
    ));

    for (final img in snapshot.photos) {
      formData.files.add(MapEntry(
        'images',
        await MultipartFile.fromFile(
            img.path, filename: img.path.split('/').last),
      ));
    }
    for (final doc in snapshot.documents) {
      formData.files.add(MapEntry(
        'documents',
        await MultipartFile.fromFile(
            doc.path, filename: doc.path.split('/').last),
      ));
    }

    final result = await _api.postMultipart(ApiEndpoints.biens, formData);

    // Récupère l'ID renvoyé par le backend
    final bienId = result?['id']?.toString()
        ?? result?['data']?['id']?.toString();

    // Reset uniquement si on a bien reçu un ID (publication créée côté backend)
    if (bienId != null) {
      state = const PublicationFormState();
    }

    return bienId;
  }

  // ── RETRY PAIEMENT (annonce déjà créée) ───────────────────────────────────
  // Contrairement à submitAndGetId(), ne renvoie ni photos ni documents :
  // relance juste la demande de paiement pour un bien existant.
  Future<void> retryPayment(String bienId, String numeroPaiement) async {
    await _api.post(
      ApiEndpoints.retryPayment(bienId),
      data: {'numeroPaiement': numeroPaiement},
    );
  }

  void reset() => state = const PublicationFormState();
}

// ── PAS de autoDispose : le state doit vivre pendant tout le parcours ─────────
final publicationNotifierProvider =
    StateNotifierProvider<PublicationNotifier, PublicationFormState>(
  (ref) => PublicationNotifier(ref.watch(apiClientProvider)),
);

final publicationUpdateProvider = Provider<_PublicationActions>((ref) {
  return _PublicationActions(ref.watch(bienRepositoryProvider));
});

class _PublicationActions {
  final BienRepository _repo;
  _PublicationActions(this._repo);
  Future<void> delete(String id) => _repo.delete(id);
  Future<void> update(String id, Map<String, dynamic> data) =>
      _repo.update(id, data);
}
