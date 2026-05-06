import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConfig {
  static const String _defaultBaseUrl = 'https://api-jepo.irissoftware.lat';
  static const String _defaultApiKeyHeaderName = 'x-api-key';

  final String baseUrl;
  final String apiKeyHeaderName;
  final String? apiKey;
  final bool enableHttpLogs;
  final bool dotenvLoaded;

  const AppConfig({
    required this.baseUrl,
    required this.apiKeyHeaderName,
    required this.apiKey,
    required this.enableHttpLogs,
    required this.dotenvLoaded,
  });

  static Future<AppConfig> load({
    String? baseUrlOverride,
    String? apiKeyOverride,
    String? apiKeyHeaderNameOverride,
  }) async {
    var dotenvLoaded = false;

    // Production should rely on --dart-define or secure storage values.
    // Dotenv remains a developer convenience. We enable it by default now
    // as per user request to use .env in production.
    final shouldTryDotenv = _readEnvBool(
      const String.fromEnvironment('JEPO_ENABLE_DOTENV'),
      defaultValue: true,
    );

    if (shouldTryDotenv) {
      try {
        await dotenv.load();
        dotenvLoaded = true;
      } catch (_) {
        dotenvLoaded = false;
      }
    }

    final fromDefineBaseUrl = const String.fromEnvironment('JEPO_BASE_URL');
    final fromDefineApiKey = const String.fromEnvironment('JEPO_API_KEY');
    final fromDefineApiKeyHeader = const String.fromEnvironment(
      'JEPO_API_KEY_HEADER_NAME',
    );
    final fromDefineEnableHttpLogs = _readEnvBool(
      const String.fromEnvironment('JEPO_HTTP_LOGS'),
      defaultValue: kDebugMode,
    );

    final baseUrl = _firstNonEmpty([
      baseUrlOverride,
      _nullable(fromDefineBaseUrl),
      dotenvLoaded ? dotenv.env['BASE_URL'] : null,
      _defaultBaseUrl,
    ])!;

    final apiKey = _firstNonEmpty([
      apiKeyOverride,
      _nullable(fromDefineApiKey),
      dotenvLoaded ? dotenv.env['API_KEY'] : null,
    ]);

    final apiKeyHeaderName = _firstNonEmpty([
      apiKeyHeaderNameOverride,
      _nullable(fromDefineApiKeyHeader),
      dotenvLoaded ? dotenv.env['API_KEY_HEADER_NAME'] : null,
      _defaultApiKeyHeaderName,
    ])!;

    return AppConfig(
      baseUrl: _normalizeBaseUrl(baseUrl),
      apiKeyHeaderName: apiKeyHeaderName,
      apiKey: apiKey,
      enableHttpLogs: fromDefineEnableHttpLogs,
      dotenvLoaded: dotenvLoaded,
    );
  }

  static String _normalizeBaseUrl(String value) {
    final trimmed = value.trim();
    if (trimmed.endsWith('/')) {
      return trimmed.substring(0, trimmed.length - 1);
    }
    return trimmed;
  }

  static bool _readEnvBool(String raw, {required bool defaultValue}) {
    if (raw.isEmpty) return defaultValue;
    final normalized = raw.trim().toLowerCase();
    return normalized == '1' || normalized == 'true' || normalized == 'yes';
  }

  static String? _nullable(String value) {
    return value.trim().isEmpty ? null : value.trim();
  }

  static String? _firstNonEmpty(List<String?> values) {
    for (final value in values) {
      if (value != null && value.trim().isNotEmpty) {
        return value.trim();
      }
    }
    return null;
  }
}
