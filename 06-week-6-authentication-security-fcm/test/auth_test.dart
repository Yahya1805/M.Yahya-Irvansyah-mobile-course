import 'package:flutter_test/flutter_test.dart';
import 'package:my_app/data/auth_repository.dart';

void main() {
  group('AuthRepository', () {
    late AuthRepository authRepository;

    setUp(() {
      authRepository = AuthRepository();
    });

    test('login berhasil dengan email dan password valid', () async {
      final session = await authRepository.login(
        email: 'user@example.com',
        password: 'password123',
      );

      expect(session.access, 'mock-access-for-user@example.com');
      expect(session.refresh, 'mock-refresh-for-user@example.com');
    });

    test('login melempar exception jika format email tidak valid', () async {
      expect(
        () => authRepository.login(
          email: 'invalid-email',
          password: 'password123',
        ),
        throwsException,
      );
    });

    test('login melempar exception jika password kurang dari 6 karakter',
        () async {
      expect(
        () => authRepository.login(
          email: 'user@example.com',
          password: '123',
        ),
        throwsException,
      );
    });

    test('refresh mengembalikan token akses baru', () async {
      final renewed = await authRepository.refresh('mock-refresh-token');
      expect(renewed, contains('mock-access-renewed-'));
    });

    test('refresh melempar exception jika refresh token kosong', () async {
      expect(
        () => authRepository.refresh(''),
        throwsException,
      );
    });
  });
}
