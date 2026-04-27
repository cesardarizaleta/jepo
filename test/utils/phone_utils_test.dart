import 'package:flutter_test/flutter_test.dart';
import 'package:jepo/utils/phone_utils.dart';

void main() {
  group('normalizePhoneForApi', () {
    test('strips non-digit characters', () {
      expect(normalizePhoneForApi('+58 414-401.99.11'), '584144019911');
    });

    test('converts 11-digit Venezuelan local (leading 0) to 58-prefix', () {
      // 0414-4019911 → 584144019911
      expect(normalizePhoneForApi('04144019911'), '584144019911');
    });

    test('leaves 58-prefixed number unchanged', () {
      expect(normalizePhoneForApi('584144019911'), '584144019911');
    });

    test('adds 58 prefix to 10-digit local number without leading 0', () {
      expect(normalizePhoneForApi('4144019911'), '584144019911');
    });

    test('returns empty for empty input', () {
      expect(normalizePhoneForApi(''), '');
    });

    test('returns digits only for non-Venezuelan numbers', () {
      // A 13-digit international number should just strip non-digits
      expect(normalizePhoneForApi('+1-555-012-3456'), '15550123456');
    });

    test('handles parentheses and spaces', () {
      expect(normalizePhoneForApi('(0414) 401 9911'), '584144019911');
    });
  });

  group('formatToE164', () {
    test('adds + to 58-prefixed digits', () {
      expect(formatToE164('584144019911'), '+584144019911');
    });

    test('normalizes 11-digit with leading 0', () {
      expect(formatToE164('04144019911'), '+584144019911');
    });

    test('normalizes 10-digit local', () {
      expect(formatToE164('4144019911'), '+584144019911');
    });

    test('adds + to already-international number', () {
      expect(formatToE164('15550123456'), '+15550123456');
    });

    test('handles empty input', () {
      expect(formatToE164(''), '');
    });

    test('strips + and readds properly', () {
      expect(formatToE164('+584144019911'), '+584144019911');
    });
  });
}
