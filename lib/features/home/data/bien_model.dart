// ══════════════════════════════════════════════════════════════════════════════
// BIEN MODEL — Champs internes alignés avec la couche présentation Flutter
// fromJson() accepte les deux variantes (backend réel + anciens noms)
// ══════════════════════════════════════════════════════════════════════════════
class BienModel {
  final String id;
  final String titre;             // affiché dans l'UI
  final double prix;
  final String typePublication;
  final String typeBien;          // affiché dans l'UI
  final String categorie;
  final int nbPieces;             // affiché dans l'UI
  final double? superficie;       // affiché dans l'UI
  final String? description;
  final String ville;
  final String? region;
  final String? quartier;
  final double? latitude;
  final double? longitude;
  final List<String> photos;      // affiché dans l'UI (URLs Cloudinary)
  final List<String> documents;
  final String? proprietaireId;
  final String? proprietaireNom;
  final String? proprietaireTelephone;
  final double? rating;
  final int? nbCommentaires;
  final DateTime? createdAt;

  const BienModel({
    required this.id,
    required this.titre,
    required this.prix,
    required this.typePublication,
    required this.typeBien,
    required this.categorie,
    required this.nbPieces,
    this.superficie,
    this.description,
    required this.ville,
    this.region,
    this.quartier,
    this.latitude,
    this.longitude,
    this.photos = const [],
    this.documents = const [],
    this.proprietaireId,
    this.proprietaireNom,
    this.proprietaireTelephone,
    this.rating,
    this.nbCommentaires,
    this.createdAt,
  });

  // ── Formatage prix FCFA ───────────────────────────────────────────────────
  String get prixFormate {
    final p = prix.toInt();
    if (p >= 1000000) {
      final m = p / 1000000;
      return '${m % 1 == 0 ? m.toInt() : m.toStringAsFixed(1)} M FCFA';
    }
    if (p >= 1000) {
      final s = p.toString();
      final buf = StringBuffer();
      for (int i = 0; i < s.length; i++) {
        if (i > 0 && (s.length - i) % 3 == 0) buf.write(' ');
        buf.write(s[i]);
      }
      return '${buf.toString()} FCFA';
    }
    return '$p FCFA';
  }

  String get localisation =>
      (quartier != null && quartier!.isNotEmpty) ? '$quartier, $ville' : ville;

  String get typeBadge      => typePublication.toUpperCase();
  String get categorieBadge => categorie.toUpperCase();
  String? get photoUrl      => photos.isNotEmpty ? photos.first : null;
  bool   get hasLocation    => latitude != null && longitude != null;

  // ── fromJson — accepte les champs backend réels ET les anciens noms ───────
  factory BienModel.fromJson(Map<String, dynamic> json) {
    List<String> extractList(dynamic raw) {
      if (raw == null) return [];
      if (raw is List) return raw.map((e) => e.toString()).toList();
      if (raw is String && raw.isNotEmpty) return [raw];
      return [];
    }

    // Adresse peut être imbriquée ou à la racine
    final adresse = json['adresse'] as Map<String, dynamic>?;

    return BienModel(
      id:    json['id']?.toString() ?? '',

      // Backend envoie "titreBien", on stocke dans "titre"
      titre: json['titreBien']
           ?? json['titre']
           ?? 'Sans titre',

      prix:  _toDouble(json['prix']) ?? 0,

      typePublication:   json['typePublication']    ?? 'LOCATION',

      // Backend envoie "typeBienImmobilier", on stocke dans "typeBien"
      typeBien:          json['typeBienImmobilier']
                       ?? json['typeBien']
                       ?? '',

      categorie:         json['categorie']  ?? '',

      // Backend envoie "nbrePiece", on stocke dans "nbPieces"
      nbPieces:          _toInt(json['nbrePiece'])
                       ?? _toInt(json['nbPieces'])
                       ?? 0,

      // Backend envoie "superfie" (sic), on stocke dans "superficie"
      superficie:        _toDouble(json['superfie'])
                       ?? _toDouble(json['superficie']),

      description: json['description'],

      // Adresse imbriquée ou champs à la racine
      ville:    adresse?['ville']    ?? json['ville']    ?? '',
      region:   adresse?['region']   ?? json['region'],
      quartier: adresse?['quartier'] ?? json['quartier'],

      // "lattitude" (sic) dans le backend
      latitude:  _toDouble(adresse?['lattitude'])
               ?? _toDouble(adresse?['latitude'])
               ?? _toDouble(json['latitude']),
      longitude: _toDouble(adresse?['longitude'])
               ?? _toDouble(json['longitude']),

      // Backend envoie "images" (URLs Cloudinary), on stocke dans "photos"
      photos:    extractList(json['images']) +
                 extractList(json['photos']),
      documents: extractList(json['documents']),

      proprietaireId:        json['proprietaire_id']?.toString(),
      proprietaireNom:       json['proprietaire_nom'],
      proprietaireTelephone: json['proprietaire_telephone']
                           ?? json['numeroPaiement']?.toString(),
      rating:         _toDouble(json['rating']),
      nbCommentaires: _toInt(json['nb_commentaires']),
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
    );
  }

  static double? _toDouble(dynamic v) {
    if (v == null) return null;
    if (v is double) return v;
    if (v is int)    return v.toDouble();
    return double.tryParse(v.toString());
  }

  static int? _toInt(dynamic v) {
    if (v == null) return null;
    if (v is int)    return v;
    if (v is double) return v.toInt();
    return int.tryParse(v.toString());
  }

  // toJson — utilise les vrais noms backend pour les appels API
  Map<String, dynamic> toJson() => {
    'id':                id,
    'titreBien':         titre,
    'prix':              prix,
    'typePublication':   typePublication,
    'typeBienImmobilier': typeBien,
    'categorie':         categorie,
    'nbrePiece':         nbPieces,
    'superfie':          superficie,
    'description':       description,
    'adresse': {
      'ville':     ville,
      'region':    region,
      'quartier':  quartier,
      'lattitude': latitude,
      'longitude': longitude,
    },
    'images':    photos,
    'documents': documents,
    'proprietaire_telephone': proprietaireTelephone,
  };
}
