import 'package:flutter_test/flutter_test.dart';
import 'package:dreamhouse237_mobile/features/auth/data/user_model.dart';

// ══════════════════════════════════════════════════════════════════════════════
// TESTS USER MODEL — Sans mocks pour éviter la génération build_runner
// Les tests AuthRepository nécessitent : flutter pub run build_runner build
// ══════════════════════════════════════════════════════════════════════════════
void main() {
  group('UserModel - parsing JWT payload', () {
    test('fromJwtPayload extrait correctement les champs', () {
      final payload = {
        'user_id': '1',
        'uuid':    'abc-def',
        'email':   'test@dreamhouse.cm',
        'role':    'client',
      };
      final user = UserModel.fromJwtPayload(payload);
      expect(user.id,    equals('1'));
      expect(user.uuid,  equals('abc-def'));
      expect(user.email, equals('test@dreamhouse.cm'));
      expect(user.role,  equals('client'));
    });

    test('fromJwtPayload gère les valeurs nulles', () {
      final user = UserModel.fromJwtPayload({});
      expect(user.id,    equals(''));
      expect(user.email, equals(''));
      expect(user.role,  equals('client'));
    });
  });

  group('UserModel - fullName', () {
    test('retourne nom + prenom quand les deux sont présents', () {
      const user = UserModel(
        id: '1', uuid: 'x', serviceId: '1', email: 'a@b.cm', role: 'client',
        nom: 'TANDENT', prenom: 'Daniel',
      );
      expect(user.fullName, equals('TANDENT Daniel'));
    });

    test('retourne seulement le nom si pas de prenom', () {
      const user = UserModel(
        id: '1', uuid: 'x', serviceId: '1', email: 'a@b.cm',
        role: 'client', nom: 'TANDENT',
      );
      expect(user.fullName, equals('TANDENT'));
    });

    test('retourne la partie locale de l\'email si pas de nom', () {
      const user = UserModel(
        id: '1', uuid: 'x',
        serviceId: '1',
        email: 'moncompte@test.cm', role: 'client',
      );
      expect(user.fullName, equals('moncompte'));
    });
  });

  group('UserModel - rôles', () {
    test('isOwnerRole true pour proprietaire', () {
      const u = UserModel(id:'1', uuid:'x', serviceId:'1', email:'a@b.cm',role:'proprietaire');
      expect(u.isOwnerRole, isTrue);
    });
    test('isOwnerRole true pour pending_proprietaire', () {
      const u = UserModel(id:'1', uuid:'x', serviceId:'1', email:'a@b.cm',role:'pending_proprietaire');
      expect(u.isOwnerRole, isTrue);
    });
    test('isOwnerRole true pour agence', () {
      const u = UserModel(id:'1', uuid:'x', serviceId:'1', email:'a@b.cm',role:'agence');
      expect(u.isOwnerRole, isTrue);
    });
    test('isOwnerRole true pour pending_agent', () {
      const u = UserModel(id:'1', uuid:'x', serviceId:'1', email:'a@b.cm',role:'pending_agent');
      expect(u.isOwnerRole, isTrue);
    });
    test('isOwnerRole false pour client', () {
      const u = UserModel(id:'1', uuid:'x', serviceId:'1', email:'a@b.cm',role:'client');
      expect(u.isOwnerRole, isFalse);
    });
    test('isAdmin true pour admin', () {
      const u = UserModel(id:'1', uuid:'x', serviceId:'1', email:'a@b.cm',role:'admin');
      expect(u.isAdmin, isTrue);
    });
  });

  group('UserModel - displayRole', () {
    final cases = {
      'client':               'Client',
      'proprietaire':         'Propriétaire',
      'pending_proprietaire': 'Propriétaire (en attente)',
      'agence':               'Agence Immobilière',
      'pending_agent':        'Agence (en attente)',
      'admin':                'Administrateur',
    };

    cases.forEach((role, expected) {
      test('displayRole correct pour $role', () {
        final user = UserModel(id:'1', uuid:'x', serviceId:'1', email:'a@b.cm', role: role);
        expect(user.displayRole, equals(expected));
      });
    });
  });

  group('UserModel - copyWith', () {
    test('modifie uniquement les champs spécifiés', () {
      const user = UserModel(
        id: '1', uuid: 'x', serviceId: '1', email: 'a@b.cm',
        role: 'client', nom: 'Ancien',
      );
      final updated = user.copyWith(nom: 'Nouveau', ville: 'Douala');
      expect(updated.nom,   equals('Nouveau'));
      expect(updated.ville, equals('Douala'));
      expect(updated.id,    equals('1'));
      expect(updated.email, equals('a@b.cm'));
    });
  });

  group('UserModel - toJson / fromJson', () {
    test('round-trip toJson -> fromJson préserve les données', () {
      const original = UserModel(
        id: '5', uuid: 'xyz', serviceId: '5', email: 'test@cm.cm',
        role: 'proprietaire', nom: 'NOM', prenom: 'PRENOM',
        telephone: '+237600000000', ville: 'Yaoundé',
        region: 'Centre', isActive: true, identityVerified: true,
      );
      final json    = original.toJson();
      final decoded = UserModel.fromJson(json);

      expect(decoded.id,               equals(original.id));
      expect(decoded.email,            equals(original.email));
      expect(decoded.role,             equals(original.role));
      expect(decoded.nom,              equals(original.nom));
      expect(decoded.isActive,         equals(original.isActive));
      expect(decoded.identityVerified, equals(original.identityVerified));
    });
  });
}
