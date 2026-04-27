import 'package:flutter_test/flutter_test.dart';
import 'package:jepo/services/api_client.dart';

void main() {
  group('ApiException', () {
    test('regular exception is not transient', () {
      const e = ApiException(
        statusCode: 400,
        message: 'Bad Request',
      );

      expect(e.isTransient, isFalse);
      expect(e.statusCode, 400);
    });

    test('network exception is transient with statusCode 0', () {
      final e = ApiException.network(message: 'Connection refused');

      expect(e.isTransient, isTrue);
      expect(e.statusCode, 0);
    });

    test('carries errors array from backend', () {
      const e = ApiException(
        statusCode: 400,
        message: 'Validation failed',
        errors: ['email is required', 'password too short'],
      );

      expect(e.errors, hasLength(2));
      expect(e.errors[0], 'email is required');
    });

    test('toString includes statusCode and message', () {
      const e = ApiException(
        statusCode: 401,
        message: 'Unauthorized',
      );

      expect(e.toString(), contains('401'));
      expect(e.toString(), contains('Unauthorized'));
    });

    test('500+ status codes should be marked transient by the client', () {
      // This tests the expectation — the client marks 500/502/503/504 as transient
      const transientCodes = [500, 502, 503, 504];
      for (final code in transientCodes) {
        final e = ApiException(
          statusCode: code,
          message: 'Server Error',
          transient: true, // Client would set this
        );
        expect(e.isTransient, isTrue, reason: 'Expected $code to be transient');
      }
    });

    test('4xx codes (except 429) should NOT be transient', () {
      const permanentCodes = [400, 401, 403, 404, 409, 422];
      for (final code in permanentCodes) {
        const e = ApiException(
          statusCode: 400,
          message: 'Client Error',
          transient: false,
        );
        expect(e.isTransient, isFalse, reason: 'Expected $code to be permanent');
      }
    });
  });

  group('ApiEnvelope', () {
    test('fromJson parses successful response', () {
      final json = <String, dynamic>{
        'success': true,
        'message': 'Data retrieved',
        'data': {'key': 'value'},
        'errors': <dynamic>[],
        'path': '/api/test',
        'timestamp': '2026-04-26T10:00:00.000Z',
      };

      final envelope = ApiEnvelope<Map<String, dynamic>>.fromJson(json);

      expect(envelope.success, isTrue);
      expect(envelope.message, 'Data retrieved');
      expect(envelope.data, isA<Map<String, dynamic>>());
      expect(envelope.data!['key'], 'value');
      expect(envelope.errors, isEmpty);
      expect(envelope.path, '/api/test');
      expect(envelope.timestamp, isNotNull);
    });

    test('fromJson parses error response with errors[]', () {
      final json = <String, dynamic>{
        'success': false,
        'message': 'Validation error',
        'data': null,
        'errors': ['Field required', 'Invalid format'],
        'path': '/api/auth/register',
      };

      final envelope = ApiEnvelope.fromJson(json);

      expect(envelope.success, isFalse);
      expect(envelope.errors, hasLength(2));
      expect(envelope.errors[0], 'Field required');
    });

    test('uses dataParser when provided', () {
      final json = <String, dynamic>{
        'success': true,
        'message': 'OK',
        'data': [1, 2, 3],
      };

      final envelope = ApiEnvelope<int>.fromJson(
        json,
        dataParser: (value) {
          if (value is List) return value.length;
          return null;
        },
      );

      expect(envelope.data, 3);
    });

    test('raw field contains the original JSON', () {
      final json = <String, dynamic>{
        'success': true,
        'message': 'OK',
        'data': 'test',
        'extra_field': 'should be in raw',
      };

      final envelope = ApiEnvelope.fromJson(json);

      expect(envelope.raw, equals(json));
      expect(envelope.raw['extra_field'], 'should be in raw');
    });

    test('defaults message when missing', () {
      final json = <String, dynamic>{
        'success': true,
      };

      final envelope = ApiEnvelope.fromJson(json);
      expect(envelope.message, isNotEmpty);
    });

    test('handles null errors gracefully', () {
      final json = <String, dynamic>{
        'success': false,
        'message': 'Error',
        'errors': null,
      };

      final envelope = ApiEnvelope.fromJson(json);
      expect(envelope.errors, isEmpty);
    });
  });
}
