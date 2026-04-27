import 'package:flutter_test/flutter_test.dart';
import 'package:jepo/models/api_response.dart';

void main() {
  group('ApiResponse.fromJson', () {
    test('parses a successful envelope with typed data', () {
      final json = <String, dynamic>{
        'success': true,
        'message': 'OK',
        'data': {'id': 1, 'name': 'Test'},
        'errors': <dynamic>[],
        'path': '/api/test',
        'timestamp': '2026-04-26T10:00:00.000Z',
      };

      final response = ApiResponse<Map<String, dynamic>>.fromJson(json);

      expect(response.success, isTrue);
      expect(response.message, 'OK');
      expect(response.data, isA<Map<String, dynamic>>());
      expect(response.data!['id'], 1);
      expect(response.errors, isEmpty);
      expect(response.path, '/api/test');
      expect(response.timestamp, isNotNull);
    });

    test('parses error envelope with errors array', () {
      final json = <String, dynamic>{
        'success': false,
        'message': 'Validation failed',
        'data': null,
        'errors': ['email must be valid', 'password too short'],
        'path': '/api/auth/register',
        'timestamp': '2026-04-26T10:00:00.000Z',
      };

      final response = ApiResponse<void>.fromJson(json);

      expect(response.success, isFalse);
      expect(response.errors, hasLength(2));
      expect(response.errors[0], 'email must be valid');
      expect(response.errors[1], 'password too short');
    });

    test('uses dataParser when provided', () {
      final json = <String, dynamic>{
        'success': true,
        'message': 'OK',
        'data': {'value': 42},
        'errors': <dynamic>[],
      };

      final response = ApiResponse<int>.fromJson(
        json,
        dataParser: (value) {
          if (value is Map<String, dynamic>) return value['value'] as int;
          return null;
        },
      );

      expect(response.data, 42);
    });

    test('handles missing optional fields gracefully', () {
      final json = <String, dynamic>{
        'success': true,
        'message': 'OK',
      };

      final response = ApiResponse<void>.fromJson(json);

      expect(response.success, isTrue);
      expect(response.errors, isEmpty);
      expect(response.path, isNull);
      expect(response.timestamp, isNull);
    });

    test('handles non-list errors gracefully', () {
      final json = <String, dynamic>{
        'success': false,
        'message': 'Error',
        'errors': 'single error as string', // Not a list
      };

      final response = ApiResponse<void>.fromJson(json);

      // Should gracefully handle non-list errors
      expect(response.errors, isEmpty);
    });

    test('parses timestamp correctly to UTC', () {
      final json = <String, dynamic>{
        'success': true,
        'message': 'OK',
        'timestamp': '2026-04-26T14:30:00.000Z',
      };

      final response = ApiResponse<void>.fromJson(json);

      expect(response.timestamp, isNotNull);
      expect(response.timestamp!.isUtc, isTrue);
      expect(response.timestamp!.hour, 14);
      expect(response.timestamp!.minute, 30);
    });
  });
}
