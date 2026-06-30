import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import 'comment_model.dart';

// ══════════════════════════════════════════════════════════════════════════════
// COMMENT REPOSITORY — Équivalent de CommentService dans auth_service.js
// FIX : les noms de champs envoyés au backend sont alignés sur le web :
//   'contenu'        → 'content'
//   'publication_id' → 'publicationId'
//   'parent_id'      → 'parentId'
// ══════════════════════════════════════════════════════════════════════════════
class CommentRepository {
  final ApiClient _api;
  CommentRepository(this._api);

  Future<List<CommentModel>> getByPublication(String pubId) async {
    final data = await _api.get(ApiEndpoints.comments(pubId));
    if (data is List) {
      return data.map((e) => CommentModel.fromJson(e)).toList();
    }
    return [];
  }

  Future<CommentModel> create({
    required String publicationId,
    required String contenu,
    String? parentId,
  }) async {
    // ✅ Aligné sur le payload du web (auth_service.js → CommentService.create)
    //    { publicationId: String(publicationId), content: content.trim(), parentId }
    final data = await _api.post(ApiEndpoints.createComment, data: {
      'publicationId': publicationId,   // était 'publication_id'
      'content': contenu.trim(),        // était 'contenu'
      if (parentId != null) 'parentId': parentId,  // était 'parent_id'
    });
    return CommentModel.fromJson(data as Map<String, dynamic>);
  }

  Future<void> like(String commentId) =>
      _api.post(ApiEndpoints.likeComment(commentId));

  Future<void> delete(String commentId) =>
      _api.delete(ApiEndpoints.deleteComment(commentId));
}

final commentRepositoryProvider = Provider<CommentRepository>((ref) {
  return CommentRepository(ref.watch(apiClientProvider));
});

// ── Provider commentaires par publication ─────────────────────────────────────
final commentsProvider = FutureProvider.family
    .autoDispose<List<CommentModel>, String>((ref, pubId) {
  return ref.watch(commentRepositoryProvider).getByPublication(pubId);
});