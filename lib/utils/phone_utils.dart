/// Utilities for phone number normalization and formatting.
///
/// - `normalizePhoneForApi` returns a digits-only string suitable for server
///   storage/validation (e.g. `04144019911` -> `584144019911`).
/// - `formatToE164` returns an E.164 formatted string (e.g. `584144019911` -> `+584144019911`).
library;

String _digitsOnly(String input) {
  return input.replaceAll(RegExp(r'\D'), '');
}

/// Normalizes a user-provided phone to a digits-only string expected by the API.
///
/// Rules (best-effort):
/// - Removes any non-digit characters.
/// - If the number starts with leading `0` and looks like a Venezuelan local
///   number (11 digits including leading 0), it removes the `0` and prefixes
///   the country code `58` -> `0414...` -> `58414...`.
/// - If the number already starts with `58`, it is returned as-is (digits only).
/// - If it's 10 digits (no leading 0), we assume it's local and prefix `58`.
String normalizePhoneForApi(String raw) {
  final d = _digitsOnly(raw);
  if (d.isEmpty) return d;

  // Venezuelan mobile typical formats: 0414xxxxxxx (11 digits with leading 0)
  if (d.length == 11 && d.startsWith('0')) {
    return '58${d.substring(1)}';
  }

  // If already has country code 58
  if (d.startsWith('58')) return d;

  // If it's 10 digits (local without leading 0), assume local and add country code
  if (d.length == 10) return '58$d';

  // Fallback: return digits only
  return d;
}

/// Formats a phone number (raw or normalized) into E.164 (+58...) for display
/// and for standardized contact display.
String formatToE164(String rawOrNormalized) {
  final d = _digitsOnly(rawOrNormalized);
  if (d.isEmpty) return d;

  if (d.startsWith('58')) return '+$d';

  if (d.length == 11 && d.startsWith('0')) return '+58${d.substring(1)}';

  if (d.length == 10) return '+58$d';

  // If already looks like international without plus (e.g., 54911...), add plus
  return '+$d';
}
