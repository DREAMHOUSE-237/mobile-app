// ══════════════════════════════════════════════════════════════════════════════
// COMMENT MODEL — Équivalent des données retournées par COMMENTARY-SERVICE
// ══════════════════════════════════════════════════════════════════════════════
class CommentModel {
  final String id;
  final String publicationId;
  final String? userId;
  final String? userEmail;
  final String contenu;
  final int likes;
  final bool likedByMe;
  final List<CommentModel> reponses;
  final DateTime? createdAt;

  const CommentModel({
    required this.id,
    required this.publicationId,
    this.userId,
    this.userEmail,
    required this.contenu,
    this.likes = 0,
    this.likedByMe = false,
    this.reponses = const [],
    this.createdAt,
  });

  String get auteurDisplay {
    if (userEmail != null && userEmail!.isNotEmpty) {
      // "tandentdaniel@test.com" → "Utilisateur #tandent"
      final local = userEmail!.split('@').first;
      return local.length > 10 ? local.substring(0, 10) : local;
    }
    if (userId != null) return 'Utilisateur #$userId';
    return 'Utilisateur #null';
  }

  String get dateDisplay {
    if (createdAt == null) return '';
    final d = createdAt!;
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  }

  factory CommentModel.fromJson(Map<String, dynamic> json) => CommentModel(
    id:            json['id']?.toString()             ?? '',
    publicationId: json['publication_id']?.toString() ?? '',
    userId:        json['user_id']?.toString(),
    userEmail:     json['user_email'],
    contenu:       json['contenu']                    ?? json['content'] ?? '',
    likes:         (json['likes'] as num?)?.toInt()   ?? 0,
    likedByMe:     json['liked_by_me']                ?? false,
    reponses: (json['reponses'] as List?)
        ?.map((r) => CommentModel.fromJson(r as Map<String, dynamic>))
        .toList() ?? [],
    createdAt: json['created_at'] != null
        ? DateTime.tryParse(json['created_at'].toString())
        : null,
  );
}
