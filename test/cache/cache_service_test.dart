import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:dreamhouse237_mobile/core/storage/cache_service.dart';
import 'package:dreamhouse237_mobile/features/home/data/bien_model.dart';

// ══════════════════════════════════════════════════════════════════════════════
// TESTS CACHE SERVICE
// ══════════════════════════════════════════════════════════════════════════════
void main() {
  late CacheService cacheService;

  setUp(() async {
    // Mock SharedPreferences pour les tests
    SharedPreferences.setMockInitialValues({});
    cacheService = CacheService();
  });

  const mockBien = BienModel(
    id: '1', titre: 'Maison test', prix: 500000,
    typePublication: 'LOCATION', typeBien: 'MAISON',
    categorie: 'MEUBLE', nbPieces: 3, ville: 'Yaoundé',
    region: 'Centre', quartier: 'Bastos',
  );

  group('CacheService.saveBiens() / loadBiens()', () {
    test('sauvegarde et recharge correctement une liste de biens', () async {
      await cacheService.saveBiens([mockBien]);
      final loaded = await cacheService.loadBiens();

      expect(loaded, isNotNull);
      expect(loaded!.length, equals(1));
      expect(loaded.first.id,    equals('1'));
      expect(loaded.first.titre, equals('Maison test'));
    });

    test('retourne null si le cache est vide', () async {
      final loaded = await cacheService.loadBiens();
      expect(loaded, isNull);
    });

    test('getCachedBienCount retourne le bon nombre', () async {
      await cacheService.saveBiens([mockBien, mockBien]);
      final count = await cacheService.getCachedBienCount();
      expect(count, equals(2));
    });
  });

  group('CacheService.saveBienDetail() / loadBienDetail()', () {
    test('sauvegarde et recharge un bien par ID', () async {
      await cacheService.saveBienDetail(mockBien);
      final loaded = await cacheService.loadBienDetail('1');

      expect(loaded, isNotNull);
      expect(loaded!.id,    equals('1'));
      expect(loaded.titre,  equals('Maison test'));
      expect(loaded.ville,  equals('Yaoundé'));
    });

    test('retourne null si ID inconnu', () async {
      final loaded = await cacheService.loadBienDetail('inconnu');
      expect(loaded, isNull);
    });
  });

  group('CacheService.clearAll()', () {
    test('vide complètement le cache', () async {
      await cacheService.saveBiens([mockBien]);
      await cacheService.saveBienDetail(mockBien);
      await cacheService.clearAll();

      final biens  = await cacheService.loadBiens();
      final detail = await cacheService.loadBienDetail('1');
      final count  = await cacheService.getCachedBienCount();

      expect(biens,  isNull);
      expect(detail, isNull);
      expect(count,  equals(0));
    });
  });
}
