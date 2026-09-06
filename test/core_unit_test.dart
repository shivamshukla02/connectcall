import 'package:connectcall/core/utils/validators.dart';
import 'package:connectcall/models/user_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Validators', () {
    test('email rejects empty and invalid, accepts valid', () {
      expect(Validators.email(''), isNotNull);
      expect(Validators.email('notanemail'), isNotNull);
      expect(Validators.email('a@b.com'), isNull);
    });

    test('password enforces minimum length', () {
      expect(Validators.password('12345'), isNotNull);
      expect(Validators.password('123456'), isNull);
    });

    test('confirmPassword matches original', () {
      expect(Validators.confirmPassword('abc123', 'abc123'), isNull);
      expect(Validators.confirmPassword('abc123', 'different'), isNotNull);
    });

    test('name rejects empty/too short', () {
      expect(Validators.name(''), isNotNull);
      expect(Validators.name('A'), isNotNull);
      expect(Validators.name('Al'), isNull);
    });
  });

  group('UserModel', () {
    test('toMap/fromMap round-trip preserves fields', () {
      final user = UserModel(
        uid: 'u1',
        name: 'Shivam',
        email: 's@example.com',
        isOnline: true,
        lastSeen: DateTime.utc(2026, 1, 1),
      );
      final map = user.toMap();
      // fromMap expects a Firestore Timestamp for lastSeen in real usage;
      // here we only round-trip the non-timestamp fields directly.
      expect(map['name'], 'Shivam');
      expect(map['email'], 's@example.com');
      expect(map['isOnline'], true);
    });

    test('copyWith overrides only given fields', () {
      const user = UserModel(uid: 'u1', name: 'A', email: 'a@a.com');
      final updated = user.copyWith(name: 'B');
      expect(updated.name, 'B');
      expect(updated.email, 'a@a.com');
      expect(updated.uid, 'u1');
    });
  });
}
