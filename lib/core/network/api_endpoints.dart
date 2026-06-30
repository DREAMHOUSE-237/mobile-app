// ══════════════════════════════════════════════════════════════════════════════
// API ENDPOINTS — Équivalent de VITE_API_URL + tous les paths du projet web
// ══════════════════════════════════════════════════════════════════════════════
class ApiEndpoints {
  ApiEndpoints._();

  // ── Authentification ─────────────────────────────────────────────────────────
  static const String login    = '/AUTHENTIFICATION/login/';

  // ── User Service ─────────────────────────────────────────────────────────────
  static const String register      = '/USER-SERVICE/users/register/';
  static String userProfile(String id) => '/USER-SERVICE/users/users/$id/profile/';
  static String userUpdate(String id)  => '/USER-SERVICE/users/user/$id/modification/';
  static const String adminUsers     = '/USER-SERVICE/users/admin/users/';
  static String adminUser(String id) => '/USER-SERVICE/users/admin/users/$id/';
  static const String adminValidateCNI = '/USER-SERVICE/users/admin/validate-cni/';

  // ── Publication Service ───────────────────────────────────────────────────────
  static const String biens            = '/PUBLICATION-SERVICE/api/biens';
  static const String mesPublications  = '/PUBLICATION-SERVICE/api/biens/mes-publications';
  static String bienById(String id)    => '/PUBLICATION-SERVICE/api/biens/$id';
  static String bienSearchVille(String ville) =>
      '/PUBLICATION-SERVICE/api/biens/search/ville?ville=$ville';
  static String bienSearchCategorie(String cat) =>
      '/PUBLICATION-SERVICE/api/biens/search/categorie?categorie=$cat';
  static String bienSearchQuartier(String q) =>
      '/PUBLICATION-SERVICE/api/biens/search/quartier?quartier=$q';
  static String bienSearchPrixMax(String prix) =>
      '/PUBLICATION-SERVICE/api/biens/search/prix-max?prix=$prix';
  static String bienSearchVillePrix(String ville, String prix) =>
      '/PUBLICATION-SERVICE/api/biens/search/ville-prix?ville=$ville&prix=$prix';
  static String imageUrl(String name) =>
      '/PUBLICATION-SERVICE/upload/$name';

  // ── Commentary Service ────────────────────────────────────────────────────────
  static String comments(String pubId) =>
      '/COMMENTARY-SERVICE/publications/$pubId/comments';
  static const String createComment  = '/COMMENTARY-SERVICE/comments';
  static String likeComment(String id) => '/COMMENTARY-SERVICE/comments/$id/like';
  static String deleteComment(String id) => '/COMMENTARY-SERVICE/comments/$id';

  // ── Identity Service ──────────────────────────────────────────────────────────
  static const String identitySubmit  = '/IDENTITY-SERVICE/identity/submit/';
  static const String identityStatus  = '/IDENTITY-SERVICE/identity/status/';
  static const String identityPending = '/IDENTITY-SERVICE/identity/pending/';
  static const String identityAll     = '/IDENTITY-SERVICE/identity/all/';
  static String identityDetails(String id) => '/IDENTITY-SERVICE/identity/$id/';
  static String identityReview(String id)  => '/IDENTITY-SERVICE/identity/$id/review/';
}
