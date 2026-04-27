import 'package:flutter_test/flutter_test.dart';
import 'package:jepo/utils/geo_utils.dart';

void main() {
  group('normalizeCoordinate8', () {
    test('normalizes double to 8 decimal places', () {
      expect(normalizeCoordinate8(10.123456789), 10.12345679);
    });

    test('handles integer input', () {
      expect(normalizeCoordinate8(10), 10.0);
    });

    test('parses string input', () {
      expect(normalizeCoordinate8('10.123456789'), 10.12345679);
    });

    test('returns 0 for null input', () {
      expect(normalizeCoordinate8(null), 0.0);
    });

    test('returns 0 for invalid string', () {
      expect(normalizeCoordinate8('not_a_number'), 0.0);
    });

    test('preserves negative coordinates', () {
      expect(normalizeCoordinate8(-70.123456789), -70.12345679);
    });

    test('pads with zeros if fewer than 8 decimals', () {
      final result = normalizeCoordinate8(10.5);
      expect(result, 10.5);
      // Verify it is a valid 8-decimal representation
      expect(result.toStringAsFixed(8), '10.50000000');
    });
  });
}
