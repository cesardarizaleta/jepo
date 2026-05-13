import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'app_config.dart';
import 'diagnostic_log_service.dart';
import 'session_events.dart';

class ApiException implements Exception {
  final int statusCode;
  final String message;
  final List<String> errors;
  final String? path;
  final DateTime? timestamp;
  final bool transient;
  final String? responseBody;

  const ApiException({
    required this.statusCode,
    required this.message,
    this.errors = const <String>[],
    this.path,
    this.timestamp,
    this.transient = false,
    this.responseBody,
  });

  factory ApiException.network({required String message}) {
    return ApiException(statusCode: 0, message: message, transient: true);
  }

  bool get isTransient => transient;

  void _logTodiagnostics(String requestPath) {
    try {
      DiagnosticLogService.logApiError(
        statusCode: statusCode,
        message: message,
        path: requestPath,
      );
    } catch (_) {}
  }

  @override
  String toString() => 'ApiException($statusCode): $message';
}

class ApiEnvelope<T> {
  final bool success;
  final String message;
  final T? data;
  final List<String> errors;
  final String? path;
  final DateTime? timestamp;
  final Map<String, dynamic> raw;

  const ApiEnvelope({
    required this.success,
    required this.message,
    required this.data,
    required this.errors,
    required this.path,
    required this.timestamp,
    required this.raw,
  });

  factory ApiEnvelope.fromJson(
    Map<String, dynamic> json, {
    T? Function(dynamic value)? dataParser,
  }) {
    final rawErrors = json['errors'];
    final parsedErrors = rawErrors is List
        ? rawErrors.map((e) => e.toString()).toList(growable: false)
        : const <String>[];

    DateTime? parsedTimestamp;
    final ts = json['timestamp'];
    if (ts != null) {
      parsedTimestamp = DateTime.tryParse(ts.toString())?.toUtc();
    }

    final dynamic rawData = json['data'];
    return ApiEnvelope<T>(
      success: json['success'] == true,
      message: json['message']?.toString() ?? 'Operacion completada',
      data: dataParser != null ? dataParser(rawData) : rawData as T?,
      errors: parsedErrors,
      path: json['path']?.toString(),
      timestamp: parsedTimestamp,
      raw: json,
    );
  }
}

class ApiClient {
  static const String _storageApiKey = 'JEPO_API_KEY';
  static const String _storageApiKeyHeader = 'JEPO_API_KEY_HEADER_NAME';
  static const String _storageAccessToken = 'JEPO_ACCESS_TOKEN';
  static const Duration _baseRetryDelay = Duration(milliseconds: 350);
  static const Duration _defaultTimeout = Duration(seconds: 15);

  final http.Client _httpClient;
  final FlutterSecureStorage _secureStorage;
  final AppConfig _config;

  late final String baseUrl;

  ApiClient._(
    this._httpClient,
    this._secureStorage,
    this._config,
    this.baseUrl,
  );

  static Future<ApiClient> create({
    String? baseUrlOverride,
    String? apiKeyOverride,
    String? apiKeyHeaderNameOverride,
  }) async {
    final client = http.Client();
    const storage = FlutterSecureStorage(
      aOptions: AndroidOptions(encryptedSharedPreferences: true),
    );

    final config = await AppConfig.load(
      baseUrlOverride: baseUrlOverride,
      apiKeyOverride: apiKeyOverride,
      apiKeyHeaderNameOverride: apiKeyHeaderNameOverride,
    );

    try {
      // Persist resolved config so background isolates can reuse values.
      final existingKey = await storage.read(key: _storageApiKey);
      if ((existingKey == null || existingKey.isEmpty) &&
          config.apiKey != null &&
          config.apiKey!.isNotEmpty) {
        await storage.write(key: _storageApiKey, value: config.apiKey!);
      }

      final existingHeader = await storage.read(key: _storageApiKeyHeader);
      if ((existingHeader == null || existingHeader.isEmpty) &&
          config.apiKeyHeaderName.isNotEmpty) {
        await storage.write(
          key: _storageApiKeyHeader,
          value: config.apiKeyHeaderName,
        );
      }
    } catch (e) {
      debugPrint('Failed to interact with secure storage during init: $e');
      try {
        await storage.deleteAll();
      } catch (_) {}
    }

    return ApiClient._(client, storage, config, config.baseUrl);
  }

  Future<String?> _getApiKey() async {
    try {
      final stored = await _secureStorage.read(key: _storageApiKey);
      if (stored != null && stored.isNotEmpty) return stored;
    } catch (e) {
      debugPrint('Error reading API key: $e');
    }

    if (_config.apiKey != null && _config.apiKey!.isNotEmpty) {
      return _config.apiKey;
    }

    return null;
  }

  Future<String> _getApiKeyHeaderName() async {
    try {
      final stored = await _secureStorage.read(key: _storageApiKeyHeader);
      if (stored != null && stored.isNotEmpty) return stored;
    } catch (e) {
      debugPrint('Error reading API key header: $e');
    }

    return _config.apiKeyHeaderName;
  }

  Future<Map<String, String>> _defaultHeaders({
    bool requiresAuth = false,
  }) async {
    final apiKey = await _getApiKey();
    final headerName = await _getApiKeyHeaderName();
    final accessToken = await getAccessToken();

    final headers = <String, String>{
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };

    if (apiKey == null || apiKey.isEmpty) {
      throw const ApiException(
        statusCode: 500,
        message:
            'La clave API no está configurada. Establezca JEPO_API_KEY o un valor seguro.',
        transient: false,
      );
    }

    headers[headerName] = apiKey;

    if (requiresAuth) {
      if (accessToken == null || accessToken.isEmpty) {
        throw const ApiException(
          statusCode: 401,
          message:
              'Falta el token de acceso. Por favor, inicie sesión de nuevo.',
          transient: false,
        );
      }
      headers['Authorization'] = 'Bearer $accessToken';
    }

    return headers;
  }

  void _debugLogRequest(
    String method,
    Uri uri,
    Map<String, String> headers, [
    Object? body,
  ]) {
    if (!_config.enableHttpLogs) return;
    try {
      debugPrint('ApiClient => $method $uri');
      debugPrint('Headers: $headers');
      if (body != null) {
        debugPrint('Body: ${body is String ? body : jsonEncode(body)}');
      }
    } catch (_) {}
  }

  Future<void> saveAccessToken(String token) async {
    try {
      await _secureStorage.write(key: _storageAccessToken, value: token);
    } catch (e) {
      debugPrint('Error saving access token: $e');
    }
  }

  Future<String?> getAccessToken() async {
    try {
      return await _secureStorage.read(key: _storageAccessToken);
    } catch (e) {
      debugPrint('Error reading access token: $e');
      return null;
    }
  }

  Future<void> clearAccessToken() async {
    try {
      await _secureStorage.delete(key: _storageAccessToken);
    } catch (e) {
      debugPrint('Error clearing access token: $e');
    }
  }

  Future<void> _onUnauthorized() async {
    // Guard: if a 401 was already handled (e.g. from a concurrent request),
    // don't cascade multiple logout events. SessionEvents.notifyUnauthorized
    // sets the invalidation flag on the first call.
    if (SessionEvents.isInvalidated) return;

    try {
      await clearAccessToken();
    } catch (_) {}
    try {
      SessionEvents.notifyUnauthorized();
    } catch (_) {}
  }

  Duration _retryDelayForAttempt(int attempt) {
    final factor = 1 << attempt;
    final jitterMs = (DateTime.now().microsecond % 150);
    return Duration(
      milliseconds: (_baseRetryDelay.inMilliseconds * factor) + jitterMs,
    );
  }

  bool _isTransientStatus(int statusCode) {
    return statusCode == 408 ||
        statusCode == 425 ||
        statusCode == 429 ||
        (statusCode >= 500 && statusCode <= 599);
  }

  ApiException _networkException(Object error) {
    if (error is TimeoutException) {
      return const ApiException(
        statusCode: 0,
        message:
            'Tiempo de espera agotado. Por favor, compruebe la conectividad e inténtelo de nuevo.',
        transient: true,
      );
    }

    if (error is http.ClientException) {
      return ApiException.network(message: error.message);
    }

    if (error is ApiException) return error;

    return ApiException.network(message: error.toString());
  }

  Future<ApiEnvelope<dynamic>> _requestEnvelope({
    required String method,
    required String path,
    Map<String, String>? queryParameters,
    Object? body,
    required bool requiresAuth,
    int maxAttempts = 2,
    Duration timeout = _defaultTimeout,
  }) async {
    var attempt = 0;
    while (true) {
      try {
        final uri = Uri.parse(
          baseUrl + path,
        ).replace(queryParameters: queryParameters);
        final headers = await _defaultHeaders(requiresAuth: requiresAuth);
        _debugLogRequest(method, uri, headers, body);

        late final http.Response resp;
        if (method == 'GET') {
          resp = await _httpClient.get(uri, headers: headers).timeout(timeout);
        } else if (method == 'POST') {
          resp = await _httpClient
              .post(
                uri,
                headers: headers,
                body: body == null ? null : jsonEncode(body),
              )
              .timeout(timeout);
        } else if (method == 'PATCH') {
          resp = await _httpClient
              .patch(
                uri,
                headers: headers,
                body: body == null ? null : jsonEncode(body),
              )
              .timeout(timeout);
        } else if (method == 'DELETE') {
          resp = await _httpClient
              .delete(uri, headers: headers)
              .timeout(timeout);
        } else {
          throw ApiException.network(message: 'Método no soportado: $method');
        }

        final envelope = _parseEnvelope(resp);
        if (resp.statusCode == 401) {
          // Only trigger session invalidation for actual auth failures.
          // Endpoints like /verificar and /reset-password return 401 for
          // "invalid OTP" — those are NOT session expirations.
          final isOtpEndpoint =
              path.contains('/verificar') || path.contains('/reset-password');
          if (!isOtpEndpoint) {
            await _onUnauthorized();
          }
        }

        if (resp.statusCode >= 200 && resp.statusCode < 300) {
          return envelope;
        }

        throw ApiException(
          statusCode: resp.statusCode,
          message: envelope.message,
          errors: envelope.errors,
          path: envelope.path,
          timestamp: envelope.timestamp,
          transient: _isTransientStatus(resp.statusCode),
          responseBody: resp.body,
        ).._logTodiagnostics(path);
      } catch (error) {
        final apiError = _networkException(error);
        final canRetry = apiError.isTransient && attempt + 1 < maxAttempts;

        if (!canRetry) {
          rethrow;
        }

        await Future.delayed(_retryDelayForAttempt(attempt));
        attempt++;
      }
    }
  }

  ApiEnvelope<dynamic> _parseEnvelope(http.Response resp) {
    final status = resp.statusCode;
    final body = resp.body.trim();

    if (_config.enableHttpLogs) {
      try {
        debugPrint('ApiClient <= HTTP $status');
        debugPrint('Response headers: ${resp.headers}');
        debugPrint('Response body: $body');
      } catch (_) {}
    }

    if (body.isEmpty) {
      return ApiEnvelope<dynamic>(
        success: status >= 200 && status < 300,
        message: status >= 200 && status < 300
            ? 'Operacion exitosa'
            : 'Error HTTP $status',
        data: null,
        errors: const <String>[],
        path: null,
        timestamp: DateTime.now().toUtc(),
        raw: const <String, dynamic>{},
      );
    }

    final dynamic decoded = jsonDecode(body);
    if (decoded is Map<String, dynamic>) {
      // API contract envelope: { success, message, data, errors, path, timestamp }
      if (decoded.containsKey('success') && decoded.containsKey('message')) {
        return ApiEnvelope<dynamic>.fromJson(decoded);
      }

      // Fallback for endpoints returning plain objects outside the envelope.
      return ApiEnvelope<dynamic>(
        success: status >= 200 && status < 300,
        message: status >= 200 && status < 300
            ? 'Operacion exitosa'
            : 'Error HTTP $status',
        data: decoded,
        errors: const <String>[],
        path: null,
        timestamp: DateTime.now().toUtc(),
        raw: decoded,
      );
    }

    if (decoded is List) {
      return ApiEnvelope<dynamic>(
        success: status >= 200 && status < 300,
        message: status >= 200 && status < 300
            ? 'Operacion exitosa'
            : 'Error HTTP $status',
        data: decoded,
        errors: const <String>[],
        path: null,
        timestamp: DateTime.now().toUtc(),
        raw: <String, dynamic>{'data': decoded},
      );
    }

    return ApiEnvelope<dynamic>(
      success: status >= 200 && status < 300,
      message: decoded.toString(),
      data: decoded,
      errors: const <String>[],
      path: null,
      timestamp: DateTime.now().toUtc(),
      raw: <String, dynamic>{'data': decoded},
    );
  }

  Future<ApiEnvelope<dynamic>> getEnvelope(
    String path, {
    Map<String, String>? queryParameters,
    bool requiresAuth = false,
  }) async {
    return _requestEnvelope(
      method: 'GET',
      path: path,
      queryParameters: queryParameters,
      requiresAuth: requiresAuth,
      maxAttempts: 3,
      timeout: const Duration(seconds: 12),
    );
  }

  Future<dynamic> get(
    String path, {
    Map<String, String>? queryParameters,
    bool requiresAuth = false,
  }) async {
    final envelope = await getEnvelope(
      path,
      queryParameters: queryParameters,
      requiresAuth: requiresAuth,
    );
    if (envelope.raw.isNotEmpty) {
      return envelope.raw;
    }
    return envelope.data;
  }

  Future<ApiEnvelope<dynamic>> postEnvelope(
    String path, {
    Object? body,
    bool requiresAuth = false,
  }) {
    return _requestEnvelope(
      method: 'POST',
      path: path,
      body: body,
      requiresAuth: requiresAuth,
      maxAttempts: 2,
      timeout: _defaultTimeout,
    );
  }

  Future<dynamic> post(
    String path, {
    Object? body,
    bool requiresAuth = false,
  }) async {
    final envelope = await postEnvelope(
      path,
      body: body,
      requiresAuth: requiresAuth,
    );
    if (envelope.raw.isNotEmpty) {
      return envelope.raw;
    }
    return envelope.data;
  }

  Future<ApiEnvelope<dynamic>> patchEnvelope(
    String path, {
    Object? body,
    bool requiresAuth = false,
  }) {
    return _requestEnvelope(
      method: 'PATCH',
      path: path,
      body: body,
      requiresAuth: requiresAuth,
      maxAttempts: 2,
      timeout: _defaultTimeout,
    );
  }

  Future<dynamic> patch(
    String path, {
    Object? body,
    bool requiresAuth = false,
  }) async {
    final envelope = await patchEnvelope(
      path,
      body: body,
      requiresAuth: requiresAuth,
    );
    if (envelope.raw.isNotEmpty) {
      return envelope.raw;
    }
    return envelope.data;
  }

  Future<ApiEnvelope<dynamic>> deleteEnvelope(
    String path, {
    bool requiresAuth = false,
  }) {
    return _requestEnvelope(
      method: 'DELETE',
      path: path,
      requiresAuth: requiresAuth,
      maxAttempts: 2,
      timeout: _defaultTimeout,
    );
  }

  Future<dynamic> delete(String path, {bool requiresAuth = false}) async {
    final envelope = await deleteEnvelope(path, requiresAuth: requiresAuth);
    if (envelope.raw.isNotEmpty) {
      return envelope.raw;
    }
    return envelope.data;
  }
}

late ApiClient appApi;

/// Flag set to true once `appApi` has been successfully initialized.
bool appApiInitialized = false;

/// Initialize the global ApiClient instance. Call this early in app startup.
Future<void> initApi({String? baseUrl}) async {
  appApi = await ApiClient.create(baseUrlOverride: baseUrl);
  appApiInitialized = true;
}
