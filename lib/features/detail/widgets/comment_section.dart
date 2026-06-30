import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../auth/auth_notifier.dart';
import '../data/comment_model.dart';
import '../data/comment_repository.dart';

// ══════════════════════════════════════════════════════════════════════════════
// COMMENT SECTION — Équivalent de la section discussion dans detail.jsx
// ══════════════════════════════════════════════════════════════════════════════
class CommentSection extends ConsumerStatefulWidget {
  final String publicationId;
  const CommentSection({super.key, required this.publicationId});

  @override
  ConsumerState<CommentSection> createState() => _CommentSectionState();
}

class _CommentSectionState extends ConsumerState<CommentSection> {
  final _ctrl         = TextEditingController();
  String? _replyingTo;   // ID du commentaire auquel on répond
  String? _replyingName;
  bool    _sending    = false;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _ctrl.text.trim();
    if (text.isEmpty) return;
    setState(() => _sending = true);

    try {
      await ref.read(commentRepositoryProvider).create(
        publicationId: widget.publicationId,
        contenu: text,
        parentId: _replyingTo,
      );
      _ctrl.clear();
      setState(() { _replyingTo = null; _replyingName = null; });
      ref.invalidate(commentsProvider(widget.publicationId));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _like(String commentId) async {
    try {
      await ref.read(commentRepositoryProvider).like(commentId);
      ref.invalidate(commentsProvider(widget.publicationId));
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final commentsAsync = ref.watch(commentsProvider(widget.publicationId));
    final user          = ref.watch(currentUserProvider);
    final isLoggedIn    = user != null;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ───────────────────────────────────────────────────
          commentsAsync.when(
            data: (list) => _Header(count: list.length),
            loading: ()  => const _Header(count: 0),
            error: (_, __) => const _Header(count: 0),
          ),

          const Divider(height: 1, color: AppColors.borderLight),

          // ── Liste commentaires ────────────────────────────────────────
          commentsAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator(
                  color: AppColors.teal, strokeWidth: 2)),
            ),
            error: (e, _) => Padding(
              padding: const EdgeInsets.all(16),
              child: Text('Erreur : $e',
                  style: const TextStyle(color: AppColors.error, fontSize: 13)),
            ),
            data: (comments) => comments.isEmpty
                ? const _EmptyComments()
                : ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    itemCount: comments.length,
                    separatorBuilder: (_, __) =>
                        const Divider(color: AppColors.borderLight, height: 24),
                    itemBuilder: (_, i) => _CommentTile(
                      comment: comments[i],
                      onLike: () => _like(comments[i].id),
                      onReply: isLoggedIn
                          ? () => setState(() {
                                _replyingTo   = comments[i].id;
                                _replyingName = comments[i].auteurDisplay;
                              })
                          : null,
                    ),
                  ),
          ),

          // ── Champ saisie ─────────────────────────────────────────────
          if (isLoggedIn)
            _CommentInput(
              ctrl:         _ctrl,
              sending:      _sending,
              replyingName: _replyingName,
              onCancelReply: () => setState(() {
                _replyingTo   = null;
                _replyingName = null;
              }),
              onSend: _send,
            )
          else
            const _LoginPrompt(),
        ],
      ),
    );
  }
}

// ── Header ────────────────────────────────────────────────────────────────────
class _Header extends StatelessWidget {
  final int count;
  const _Header({required this.count});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(children: [
        const Icon(Icons.chat_bubble_outline_rounded,
            size: 16, color: AppColors.teal),
        const SizedBox(width: 8),
        Text(
          'DISCUSSIONS ($count)',
          style: const TextStyle(
            fontFamily: 'Inter', fontSize: 11,
            fontWeight: FontWeight.w800, color: AppColors.teal, letterSpacing: 0.5,
          ),
        ),
      ]),
    );
  }
}

// ── Tuile commentaire ─────────────────────────────────────────────────────────
class _CommentTile extends StatelessWidget {
  final CommentModel comment;
  final VoidCallback onLike;
  final VoidCallback? onReply;

  const _CommentTile({
    required this.comment,
    required this.onLike,
    this.onReply,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Auteur + date
        Row(children: [
          CircleAvatar(
            radius: 14,
            backgroundColor: AppColors.teal.withOpacity(0.12),
            child: Text(
              comment.auteurDisplay.isNotEmpty
                  ? comment.auteurDisplay[0].toUpperCase() : 'U',
              style: const TextStyle(
                fontFamily: 'Inter', fontSize: 11,
                fontWeight: FontWeight.w800, color: AppColors.teal,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              comment.auteurDisplay,
              style: const TextStyle(
                fontFamily: 'Inter', fontSize: 12,
                fontWeight: FontWeight.w700, color: AppColors.teal,
              ),
            ),
          ),
          Text(
            comment.dateDisplay,
            style: const TextStyle(fontFamily: 'Inter',
                fontSize: 10, color: AppColors.textMuted),
          ),
        ]),
        const SizedBox(height: 6),

        // Contenu
        Text(
          '"${comment.contenu}"',
          style: const TextStyle(
            fontFamily: 'Inter', fontSize: 13,
            color: AppColors.textPrimary, height: 1.4, fontStyle: FontStyle.italic,
          ),
        ),
        const SizedBox(height: 8),

        // Actions
        Row(children: [
          GestureDetector(
            onTap: onLike,
            child: Row(children: [
              Icon(
                comment.likedByMe
                    ? Icons.thumb_up_rounded : Icons.thumb_up_outlined,
                size: 14,
                color: comment.likedByMe ? AppColors.teal : AppColors.textMuted,
              ),
              const SizedBox(width: 4),
              Text('${comment.likes}',
                  style: const TextStyle(
                    fontFamily: 'Inter', fontSize: 11, color: AppColors.textMuted,
                  )),
            ]),
          ),
          if (onReply != null) ...[
            const SizedBox(width: 16),
            GestureDetector(
              onTap: onReply,
              child: const Row(children: [
                Icon(Icons.reply_rounded, size: 14, color: AppColors.textMuted),
                SizedBox(width: 4),
                Text('Répondre',
                    style: TextStyle(
                      fontFamily: 'Inter', fontSize: 11, color: AppColors.textMuted,
                    )),
              ]),
            ),
          ],
        ]),

        // Réponses
        if (comment.reponses.isNotEmpty) ...[
          const SizedBox(height: 10),
          Container(
            margin: const EdgeInsets.only(left: 20),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.bgTealLight,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.borderLight),
            ),
            child: Column(
              children: comment.reponses.map((r) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Réponse',
                      style: TextStyle(
                        fontFamily: 'Inter', fontSize: 10,
                        fontWeight: FontWeight.w800, color: AppColors.teal,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '"${r.contenu}"',
                      style: const TextStyle(
                        fontFamily: 'Inter', fontSize: 12,
                        color: AppColors.textSecondary, fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              )).toList(),
            ),
          ),
        ],
      ],
    );
  }
}

// ── Champ saisie commentaire ──────────────────────────────────────────────────
class _CommentInput extends StatelessWidget {
  final TextEditingController ctrl;
  final bool sending;
  final String? replyingName;
  final VoidCallback onCancelReply;
  final VoidCallback onSend;

  const _CommentInput({
    required this.ctrl, required this.sending,
    this.replyingName, required this.onCancelReply, required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.borderLight)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Badge réponse
          if (replyingName != null)
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.teal.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(children: [
                Text(
                  'Répondre à $replyingName',
                  style: const TextStyle(
                    fontFamily: 'Inter', fontSize: 11,
                    fontWeight: FontWeight.w600, color: AppColors.teal,
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: onCancelReply,
                  child: const Icon(Icons.close_rounded,
                      size: 14, color: AppColors.teal),
                ),
              ]),
            ),

          Row(children: [
            Expanded(
              child: TextField(
                controller: ctrl,
                maxLines: 3,
                minLines: 1,
                style: const TextStyle(fontFamily: 'Inter', fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'Écrire un commentaire...',
                  hintStyle: const TextStyle(
                    fontFamily: 'Inter', fontSize: 12, color: AppColors.textMuted,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.borderLight),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.teal, width: 2),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                ),
              ),
            ),
            const SizedBox(width: 10),
            GestureDetector(
              onTap: sending ? null : onSend,
              child: Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  color: sending ? AppColors.textMuted : AppColors.dark,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: sending
                    ? const Center(child: SizedBox(
                        width: 18, height: 18,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2)))
                    : const Icon(Icons.send_rounded,
                        color: Colors.white, size: 18),
              ),
            ),
          ]),
        ],
      ),
    );
  }
}

class _EmptyComments extends StatelessWidget {
  const _EmptyComments();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(24),
      child: Center(
        child: Text(
          'Aucun commentaire pour le moment.',
          style: TextStyle(
            fontFamily: 'Inter', fontSize: 13, color: AppColors.textMuted,
          ),
        ),
      ),
    );
  }
}

class _LoginPrompt extends StatelessWidget {
  const _LoginPrompt();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.borderLight)),
      ),
      child: const Text(
        'Connectez-vous pour laisser un commentaire.',
        style: TextStyle(
          fontFamily: 'Inter', fontSize: 12,
          color: AppColors.textMuted, fontStyle: FontStyle.italic,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}
