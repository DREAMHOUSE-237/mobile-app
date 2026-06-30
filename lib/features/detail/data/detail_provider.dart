import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../home/data/bien_model.dart';
import '../../home/data/bien_repository.dart';

// ── Provider détail d'un bien par ID ─────────────────────────────────────────
final bienDetailProvider = FutureProvider.family
    .autoDispose<BienModel, String>((ref, id) {
  return ref.watch(bienRepositoryProvider).getById(id);
});
