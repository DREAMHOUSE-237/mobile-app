// ══════════════════════════════════════════════════════════════════════════════
// USER MODEL — Aligné avec le payload JWT + réponse getUserProfile du backend
//
// FIX : Le backend retourne `username` (ex: "CLIENT3") et non `nom`/`prenom`
// séparés. On décompose `username` comme le fait Profil.jsx :
//   nameParts = userData.username.split(' ')
//   nom    = nameParts[0]
//   prenom = nameParts.slice(1).join(' ')
//
// FIX : `tel` et `telephone` sont lus tous les deux (le backend peut
// utiliser l'un ou l'autre selon l'endpoint).
// ══════════════════════════════════════════════════════════════════════════════
class UserModel {
  final String id;
  final String uuid;
  final String serviceId;
  final String email;
  final String role;
  final String? nom;
  final String? prenom;
  final String? telephone;
  final String? ville;
  final String? region;
  final bool isActive;
  final bool identityVerified;

  const UserModel({
    required this.id,
    required this.uuid,
    required this.serviceId,
    required this.email,
    required this.role,
    this.nom,
    this.prenom,
    this.telephone,
    this.ville,
    this.region,
    this.isActive = false,
    this.identityVerified = false,
  });

  String get fullName {
    final n = nom?.trim() ?? '';
    final p = prenom?.trim() ?? '';
    if (n.isNotEmpty && p.isNotEmpty) return '$n $p';
    if (n.isNotEmpty) return n;
    if (p.isNotEmpty) return p;
    return email.split('@').first;
  }

  String get displayRole {
    switch (role.toLowerCase()) {
      case 'proprietaire':         return 'Propriétaire';
      case 'pending_proprietaire': return 'Propriétaire (en attente)';
      case 'agence':               return 'Agence Immobilière';
      case 'pending_agent':        return 'Agence (en attente)';
      case 'client':               return 'Client';
      case 'admin':                return 'Administrateur';
      default:                     return role;
    }
  }

  bool get isOwnerRole => [
    'proprietaire', 'pending_proprietaire',
    'agence', 'pending_agent',
  ].contains(role.toLowerCase());

  bool get isAdmin => role.toLowerCase() == 'admin';

  factory UserModel.fromJson(Map<String, dynamic> json) {
    // FIX : décomposition de `username` en nom / prenom
    // comme Profil.jsx : nameParts = userData.username.split(' ')
    String? nom    = json['nom'] as String?;
    String? prenom = json['prenom'] as String?;

    final username = json['username'] as String?;
    if ((nom == null || nom.isEmpty) && username != null && username.isNotEmpty) {
      final parts = username.trim().split(' ');
      nom    = parts.first;
      prenom = parts.length > 1 ? parts.sublist(1).join(' ') : null;
    }

    return UserModel(
      id:               json['id']?.toString()        ?? '',
      uuid:             json['uuid']?.toString()       ?? '',
      serviceId:        json['service_id']?.toString() ?? json['id']?.toString() ?? '',
      email:            json['email']                  ?? '',
      role:             json['role']                   ?? 'client',
      nom:              nom,
      prenom:           prenom,
      // FIX : lire `tel` en priorité, puis `telephone`, comme Profil.jsx
      // userData.tel || userData.contact || ''
      telephone:        json['tel'] as String?
                     ?? json['telephone'] as String?
                     ?? json['contact'] as String?,
      ville:            json['ville'] as String?,
      region:           json['region'] as String?,
      isActive:         json['is_active']         as bool? ?? false,
      identityVerified: json['identity_verified'] as bool? ?? false,
    );
  }

  factory UserModel.fromJwtPayload(Map<String, dynamic> payload) => UserModel(
    id:        payload['user_service_id']?.toString() ?? payload['user_id']?.toString() ?? '',
    uuid:      payload['user_id']?.toString()         ?? '',
    serviceId: payload['user_service_id']?.toString() ?? '',
    email:     payload['email']                       ?? '',
    role:      payload['role']                        ?? 'client',
  );

  Map<String, dynamic> toJson() => {
    'id':               id,
    'uuid':             uuid,
    'service_id':       serviceId,
    'email':            email,
    'role':             role,
    'nom':              nom,
    'prenom':           prenom,
    'telephone':        telephone,
    'ville':            ville,
    'region':           region,
    'is_active':        isActive,
    'identity_verified': identityVerified,
  };

  UserModel copyWith({
    String? nom, String? prenom, String? telephone,
    String? ville, String? region,
    bool? isActive, bool? identityVerified,
  }) => UserModel(
    id:               id,
    uuid:             uuid,
    serviceId:        serviceId,
    email:            email,
    role:             role,
    nom:              nom              ?? this.nom,
    prenom:           prenom          ?? this.prenom,
    telephone:        telephone       ?? this.telephone,
    ville:            ville           ?? this.ville,
    region:           region          ?? this.region,
    isActive:         isActive        ?? this.isActive,
    identityVerified: identityVerified ?? this.identityVerified,
  );
}