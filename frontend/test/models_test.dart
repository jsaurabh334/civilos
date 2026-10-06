import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/api_client.dart';

void main() {
  group('ApiClient', () {
    test('baseUrl defaults to localhost:8080/api/v1', () {
      expect(ApiClient.baseUrl, 'http://localhost:8080/api/v1');
    });
  });

  group('ApiException', () {
    test('ApiException stores message and statusCode', () {
      final ex = ApiException('Not found', statusCode: 404);
      expect(ex.message, 'Not found');
      expect(ex.statusCode, 404);
      expect(ex.toString(), 'Not found');
    });

    test('UnauthorizedException has statusCode 401', () {
      final ex = UnauthorizedException('Invalid token');
      expect(ex.statusCode, 401);
      expect(ex.message, 'Invalid token');
    });

    test('ForbiddenException has statusCode 403', () {
      final ex = ForbiddenException('Access denied');
      expect(ex.statusCode, 403);
    });

    test('NotFoundException has statusCode 404', () {
      final ex = NotFoundException('User not found');
      expect(ex.statusCode, 404);
    });

    test('ValidationException has statusCode 422', () {
      final ex = ValidationException('Validation failed', data: {'field': 'email'});
      expect(ex.statusCode, 422);
      expect(ex.data, {'field': 'email'});
    });

    test('NetworkException extends ApiException', () {
      final ex = NetworkException('No internet');
      expect(ex, isA<ApiException>());
      expect(ex.message, 'No internet');
    });
  });
}
