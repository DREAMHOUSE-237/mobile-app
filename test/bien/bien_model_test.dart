import 'package:flutter_test/flutter_test.dart';
import 'package:dreamhouse237_mobile/features/home/data/bien_model.dart';

void main() {
  // JSON qui reproduit ce que le backend envoie réellement
  final jsonBackend = {
    'id':                   '3',
    'titreBien':            'Maison spacieuse',   // ← vrai nom backend
    'prix':                 1200000,
    'typePublication':      'VENTE',
    'typeBienImmobilier':   'MAISON',             // ← vrai nom backend
    'categorie':            'MEUBLE',
    'nbrePiece':            10,                   // ← vrai nom backend
    'superfie':             159.0,                // ← vrai nom backend (sic)
    'description':          'Belle maison',
    'adresse': {                                  // ← structure imbriquée
      'ville':    'Douala',
      'region':   'Littoral',
      'quartier': 'Deido',
      'lattitude': 4.0483,                        // ← vrai nom (sic)
      'longitude': 9.7043,
    },
    'images': ['http://example.com/photo1.jpg'],  // ← vrai nom backend
    'proprietaire_telephone': '694907134',
    'rating':               4.0,
    'created_at':           '2026-05-11T00:00:00Z',
  };

  group('BienModel.fromJson() — avec noms backend réels', () {
    test('mappe titreBien → titre', () {
      final bien = BienModel.fromJson(jsonBackend);
      expect(bien.titre, equals('Maison spacieuse'));
    });

    test('mappe typeBienImmobilier → typeBien', () {
      final bien = BienModel.fromJson(jsonBackend);
      expect(bien.typeBien, equals('MAISON'));
    });

    test('mappe nbrePiece → nbPieces', () {
      final bien = BienModel.fromJson(jsonBackend);
      expect(bien.nbPieces, equals(10));
    });

    test('mappe superfie → superficie', () {
      final bien = BienModel.fromJson(jsonBackend);
      expect(bien.superficie, equals(159.0));
    });

    test('mappe images → photos', () {
      final bien = BienModel.fromJson(jsonBackend);
      expect(bien.photos.length, equals(1));
      expect(bien.photos.first, equals('http://example.com/photo1.jpg'));
    });

    test('extrait adresse imbriquée', () {
      final bien = BienModel.fromJson(jsonBackend);
      expect(bien.ville,    equals('Douala'));
      expect(bien.region,   equals('Littoral'));
      expect(bien.quartier, equals('Deido'));
    });

    test('mappe lattitude (sic) → latitude', () {
      final bien = BienModel.fromJson(jsonBackend);
      expect(bien.latitude,  equals(4.0483));
      expect(bien.longitude, equals(9.7043));
    });

    test('hasLocation est true', () {
      final bien = BienModel.fromJson(jsonBackend);
      expect(bien.hasLocation, isTrue);
    });

    test('parse createdAt', () {
      final bien = BienModel.fromJson(jsonBackend);
      expect(bien.createdAt?.year, equals(2026));
    });
  });

  group('BienModel.fromJson() — compatibilité anciens noms', () {
    test('accepte aussi "titre" (ancien nom)', () {
      final bien = BienModel.fromJson({'id':'1','titre':'Test','prix':0,
        'typePublication':'LOCATION','typeBienImmobilier':'MAISON',
        'categorie':'MEUBLE','nbrePiece':1,'ville':'Yaoundé'});
      expect(bien.titre, equals('Test'));
    });

    test('accepte photos à la racine sans adresse', () {
      final bien = BienModel.fromJson({'id':'1','titreBien':'T','prix':0,
        'typePublication':'LOCATION','typeBienImmobilier':'MAISON',
        'categorie':'MEUBLE','nbrePiece':1,'ville':'Douala',
        'photos':['http://img.com/1.jpg']});
      expect(bien.photos.length, equals(1));
    });
  });

  group('BienModel.prixFormate()', () {
    test('formate 1 200 000 → M FCFA', () {
      const bien = BienModel(
        id:'1', titre:'T', prix:1200000,
        typePublication:'LOCATION', typeBien:'APPARTEMENT',
        categorie:'MEUBLE', nbPieces:2, ville:'Yaoundé',
      );
      expect(bien.prixFormate, contains('M FCFA'));
    });

    test('formate 150 000 FCFA', () {
      const bien = BienModel(
        id:'1', titre:'T', prix:150000,
        typePublication:'LOCATION', typeBien:'APPARTEMENT',
        categorie:'MEUBLE', nbPieces:2, ville:'Yaoundé',
      );
      expect(bien.prixFormate, contains('FCFA'));
    });
  });

  group('BienModel.localisation()', () {
    test('retourne quartier + ville si quartier présent', () {
      const bien = BienModel(
        id:'1', titre:'T', prix:0,
        typePublication:'LOCATION', typeBien:'MAISON',
        categorie:'MEUBLE', nbPieces:1, ville:'Douala',
        quartier: 'Deido',
      );
      expect(bien.localisation, equals('Deido, Douala'));
    });

    test('retourne seulement ville si pas de quartier', () {
      const bien = BienModel(
        id:'1', titre:'T', prix:0,
        typePublication:'LOCATION', typeBien:'MAISON',
        categorie:'MEUBLE', nbPieces:1, ville:'Douala',
      );
      expect(bien.localisation, equals('Douala'));
    });
  });

  group('BienModel.photoUrl()', () {
    test('retourne première URL si photos non vides', () {
      const bien = BienModel(
        id:'1', titre:'T', prix:0,
        typePublication:'LOCATION', typeBien:'MAISON',
        categorie:'MEUBLE', nbPieces:1, ville:'Douala',
        photos: ['http://img.com/1.jpg', 'http://img.com/2.jpg'],
      );
      expect(bien.photoUrl, equals('http://img.com/1.jpg'));
    });

    test('retourne null si pas de photos', () {
      const bien = BienModel(
        id:'1', titre:'T', prix:0,
        typePublication:'LOCATION', typeBien:'MAISON',
        categorie:'MEUBLE', nbPieces:1, ville:'Douala',
      );
      expect(bien.photoUrl, isNull);
    });
  });

  group('BienModel.toJson()', () {
    test('round-trip fromJson → toJson → fromJson préserve les données', () {
      final original = BienModel.fromJson(jsonBackend);
      final json2    = original.toJson();
      final restored = BienModel.fromJson(json2);

      expect(restored.titre,    equals(original.titre));
      expect(restored.prix,     equals(original.prix));
      expect(restored.typeBien, equals(original.typeBien));
      expect(restored.nbPieces, equals(original.nbPieces));
      expect(restored.ville,    equals(original.ville));
    });
  });
}
