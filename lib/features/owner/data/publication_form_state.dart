import 'dart:io';

// ══════════════════════════════════════════════════════════════════════════════
// PUBLICATION FORM STATE
// Les régions utilisent les valeurs ENUM exactes du backend Java/Spring
// Exemple : 'YAOUNDE_Centre' et non 'Centre'
// ══════════════════════════════════════════════════════════════════════════════
class PublicationFormState {
  final String titre;
  final String prix;
  final String superficie;
  final String nbPieces;
  final String description;
  final List<File> photos;
  final List<File> documents;
  final String typePublication;
  final String typeBien;
  final String categorie;
  final String numeroPaiement;
  final String region;      // Valeur enum backend ex: 'YAOUNDE_Centre'
  final String ville;
  final String quartier;
  final double? latitude;
  final double? longitude;

  const PublicationFormState({
    this.titre          = '',
    this.prix           = '',
    this.superficie     = '',
    this.nbPieces       = '',
    this.description    = '',
    this.photos         = const [],
    this.documents      = const [],
    this.typePublication  = 'LOCATION',
    this.typeBien       = 'APPARTEMENT',
    this.categorie      = 'MEUBLE',
    this.numeroPaiement = '',
    this.region         = 'YAOUNDE_Centre',  // ← valeur enum backend par défaut
    this.ville          = '',
    this.quartier       = '',
    this.latitude,
    this.longitude,
  });

  PublicationFormState copyWith({
    String? titre, String? prix, String? superficie,
    String? nbPieces, String? description,
    List<File>? photos, List<File>? documents,
    String? typePublication, String? typeBien,
    String? categorie, String? numeroPaiement,
    String? region, String? ville, String? quartier,
    double? latitude, double? longitude,
  }) => PublicationFormState(
    titre:           titre           ?? this.titre,
    prix:            prix            ?? this.prix,
    superficie:      superficie      ?? this.superficie,
    nbPieces:        nbPieces        ?? this.nbPieces,
    description:     description     ?? this.description,
    photos:          photos          ?? this.photos,
    documents:       documents       ?? this.documents,
    typePublication: typePublication ?? this.typePublication,
    typeBien:        typeBien        ?? this.typeBien,
    categorie:       categorie       ?? this.categorie,
    numeroPaiement:  numeroPaiement  ?? this.numeroPaiement,
    region:          region          ?? this.region,
    ville:           ville           ?? this.ville,
    quartier:        quartier        ?? this.quartier,
    latitude:        latitude        ?? this.latitude,
    longitude:       longitude       ?? this.longitude,
  );

  Map<String, dynamic> toBienDTO() => {
    'titreBien':          titre,
    'superfie':           double.tryParse(superficie) ?? 0,
    'nbrePiece':          int.tryParse(nbPieces)      ?? 0,
    'description':        description,
    'typeBienImmobilier': typeBien,
    'categorie':          categorie,
    'prix':               double.tryParse(prix)       ?? 0,
    'numeroPaiement':     int.tryParse('237$numeroPaiement') ?? int.tryParse(numeroPaiement) ?? 0,
    'typePublication':    typePublication,
    'adresse': {
      'region':    region,    // ← valeur enum backend ex: 'YAOUNDE_Centre'
      'ville':     ville,
      'quartier':  quartier,
      'longitude': longitude ?? 0.0,
      'lattitude': latitude  ?? 0.0,
    },
  };
}

// ══════════════════════════════════════════════════════════════════════════════
// CONSTANTES — Valeurs exactes attendues par le backend Java/Spring
// ══════════════════════════════════════════════════════════════════════════════
class PublicationConstants {
  static const typesPublication = ['LOCATION', 'VENTE', 'BAIL'];
  static const typesBien = [
    'APPARTEMENT', 'MAISON', 'STUDIO', 'VILLA', 'BUREAU',
    'TERRAIN', 'IMMEUBLE', 'BOUTIQUE', 'CHAMBRE',
  ];
  static const categories = ['MEUBLE', 'NON_MEUBLE'];

  // Clés = valeurs enum backend, valeurs = labels affichés
  static const Map<String, String> regionLabels = {
    'YAOUNDE_Centre':      'Centre',
    'Douala_Littoral':     'Littoral',
    'Bamenda_NordOuest':   'Nord-Ouest',
    'Buea_SudOuest':       'Sud-Ouest',
    'Bafoussam_Ouest':     'Ouest',
    'Ebolowa_Sud':         'Sud',
    'Bertoua_Est':         'Est',
    'Garoua_Nord':         'Nord',
    'Maroua_Ngaoundere':   'Extrême-Nord',
    'Adamaoua_ExtremeNord':'Adamaoua',
  };

  // Liste des clés enum pour les dropdowns
  static List<String> get regionKeys => regionLabels.keys.toList();

  // Normalise une chaîne quelconque vers la valeur enum backend
  // (utilisé pour la détection automatique depuis Nominatim)
  static String normalizeRegion(String input) {
    final clean = input.toLowerCase()
        .replaceAll(RegExp(r'[àáâã]'), 'a')
        .replaceAll(RegExp(r'[éèêë]'), 'e')
        .replaceAll(RegExp(r'[îï]'), 'i')
        .replaceAll(RegExp(r'[ôõ]'), 'o')
        .replaceAll(RegExp(r'[ùúû]'), 'u')
        .replaceAll(RegExp(r'[-_\s]'), ' ');

    if (clean.contains('centre'))                           return 'YAOUNDE_Centre';
    if (clean.contains('littoral'))                         return 'Douala_Littoral';
    if (clean.contains('nord') && clean.contains('ouest'))  return 'Bamenda_NordOuest';
    if (clean.contains('sud') && clean.contains('ouest'))   return 'Buea_SudOuest';
    if (clean.contains('ouest'))                            return 'Bafoussam_Ouest';
    if (clean.contains('sud'))                              return 'Ebolowa_Sud';
    if (clean.contains('est'))                              return 'Bertoua_Est';
    if (clean.contains('extreme') || clean.contains('extr'))return 'Maroua_Ngaoundere';
    if (clean.contains('nord'))                             return 'Garoua_Nord';
    if (clean.contains('adamaoua'))                         return 'Adamaoua_ExtremeNord';
    return 'YAOUNDE_Centre'; // fallback
  }
}
