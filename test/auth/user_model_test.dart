import 'package:flutter_test/flutter_test.dart';
import 'package:dreamhouse237_mobile/features/auth/data/user_model.dart';

void main() {
  group('UserModel.fromJson()', () {
    final json = {
      'id':               '42',
      'uuid':             'abc-def-ghi',
      'service_id':       '42',
      'email':            'tandent@test.cm',
      'role':             'proprietaire',
      'nom':              'TANDENT',
      'prenom':           'Daniel',
      'tel':              '+237691234567',
      'ville':            'Yaoundé',
      'region':           'Centre',
      'is_active':        true,
      'identity_verified': true,
    };

    test('parse tous les champs correctement', () {
      final user = UserModel.fromJson(json);
      expect(user.id,               equals('42'));
      expect(user.email,            equals('tandent@test.cm'));
      expect(user.role,             equals('proprietaire'));
      expect(user.nom,              equals('TANDENT'));
      expect(user.prenom,           equals('Daniel'));
      expect(user.isActive,         isTrue);
      expect(user.identityVerified, isTrue);
    });

    test('fullName retourne nom + prénom', () {
      final user = UserModel.fromJson(json);
      expect(user.fullName, equals('TANDENT Daniel'));
    });

    test('fullName retourne email local si pas de nom', () {
      const user = UserModel(
        id: '2', uuid: 'x', serviceId: '2',
        email: 'user@test.cm', role: 'client',
      );
      expect(user.fullName, equals('user'));
    });
  });

  group('UserModel.fromJwtPayload()', () {
    test('extrait user_service_id et user_id (UUID)', () {
      final payload = {
        'user_id':         'uuid-123',
        'user_service_id': '42',
        'email':           'test@cm.cm',
        'role':            'proprietaire',
      };
      final user = UserModel.fromJwtPayload(payload);
      expect(user.uuid,      equals('uuid-123'));
      expect(user.serviceId, equals('42'));
      expect(user.id,        equals('42'));
      expect(user.role,      equals('proprietaire'));
    });

    test('fallback sur user_id si user_service_id absent', () {
      final payload = {
        'user_id': 'uuid-only',
        'email':   'test@cm.cm',
        'role':    'client',
      };
      final user = UserModel.fromJwtPayload(payload);
      expect(user.id,   equals('uuid-only'));
      expect(user.uuid, equals('uuid-only'));
    });
  });

  group('UserModel.isOwnerRole()', () {
    for (final role in ['proprietaire', 'pending_proprietaire', 'agence', 'pending_agent']) {
      test('true pour $role', () {
        final u = UserModel(id:'1', uuid:'x', serviceId:'1',
            email:'a@b.cm', role: role);
        expect(u.isOwnerRole, isTrue);
      });
    }
    test('false pour client', () {
      const u = UserModel(id:'1', uuid:'x', serviceId:'1',
          email:'a@b.cm', role:'client');
      expect(u.isOwnerRole, isFalse);
    });
  });

  group('UserModel.displayRole()', () {
    final cases = {
      'client':               'Client',
      'proprietaire':         'Propriétaire',
      'pending_proprietaire': 'Propriétaire (en attente)',
      'agence':               'Agence Immobilière',
      'pending_agent':        'Agence (en attente)',
      'admin':                'Administrateur',
    };
    cases.forEach((role, expected) {
      test('$role → $expected', () {
        final u = UserModel(id:'1', uuid:'x', serviceId:'1',
            email:'a@b.cm', role: role);
        expect(u.displayRole, equals(expected));
      });
    });
  });

  group('UserModel.copyWith()', () {
    test('modifie uniquement les champs spécifiés', () {
      const user = UserModel(
        id: '1', uuid: 'x', serviceId: '1',
        email: 'a@b.cm', role: 'client', nom: 'Ancien',
      );
      final updated = user.copyWith(nom: 'Nouveau', ville: 'Douala');
      expect(updated.nom,   equals('Nouveau'));
      expect(updated.ville, equals('Douala'));
      expect(updated.id,    equals('1'));
    });
  });
}
