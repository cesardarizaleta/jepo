import 'dart:async';
import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'session_events.dart';

class ApiException implements Exception {
  final int statusCode;
  final String message;

  ApiException(this.statusCode, this.message);

  @override
  String toString() => 'ApiException($statusCode): $message';
}

class ApiClient {
  static const String _defaultBaseUrl = 'https://api-jepo.irissoftware.lat';
  static const String _envApiKey = 'API_KEY';
  static const String _envApiKeyHeaderName = 'API_KEY_HEADER_NAME';
  static const String _storageApiKey = 'JEPO_API_KEY';
  static const String _storageApiKeyHeader = 'JEPO_API_KEY_HEADER_NAME';
  static const String _storageAccessToken = 'JEPO_ACCESS_TOKEN';

  final http.Client _httpClient;
  final FlutterSecureStorage _secureStorage;
  final bool _dotenvLoaded;

  late final String baseUrl;

  ApiClient._(
    this._httpClient,
    this._secureStorage,
    this.baseUrl,
    this._dotenvLoaded,
  );

  static Future<ApiClient> create({String? baseUrlOverride}) async {
    final client = http.Client();
    final storage = const FlutterSecureStorage();

    // Load dotenv (silently ignore if no file)
    bool dotenvLoaded = false;
    try {
      await dotenv.load();
      dotenvLoaded = true;
    } catch (e) {
      // Don't fail startup if dotenv can't be loaded (e.g., missing file or
      // running in an isolate where asset loading isn't available). We will
      // continue with defaults and any values already in secure storage.
      // Log for diagnostics.
      // ignore: avoid_print
      print('dotenv.load() failed: $e');
    }

    final envKey = dotenvLoaded ? dotenv.env[_envApiKey] : null;
    final envHeaderName = dotenvLoaded
        ? dotenv.env[_envApiKeyHeaderName]
        : null;

    // Seed secure storage from env if present and not already set
    final existingKey = await storage.read(key: _storageApiKey);
    if ((existingKey == null || existingKey.isEmpty) &&
        envKey != null &&
        envKey.isNotEmpty) {
      await storage.write(key: _storageApiKey, value: envKey);
    }

    final existingHeader = await storage.read(key: _storageApiKeyHeader);
    if ((existingHeader == null || existingHeader.isEmpty) &&
        envHeaderName != null &&
        envHeaderName.isNotEmpty) {
      await storage.write(key: _storageApiKeyHeader, value: envHeaderName);
    }

    final resolvedBase =
        baseUrlOverride ??
        (dotenvLoaded ? dotenv.env['BASE_URL'] : null) ??
        _defaultBaseUrl;

    return ApiClient._(client, storage, resolvedBase, dotenvLoaded);
  }

  Future<String?> _readApiKeyFromEnvIfPossible() async {
    try {
      await dotenv.load();
      final envKey = dotenv.env[_envApiKey];
      if (envKey != null && envKey.isNotEmpty) {
        // Persist for subsequent runs
        await _secureStorage.write(key: _storageApiKey, value: envKey);
        return envKey;
      }
    } catch (_) {
      // ignore - best-effort
    }
    return null;
  }

  Future<String?> _getApiKey() async {
    final stored = await _secureStorage.read(key: _storageApiKey);
    if (stored != null && stored.isNotEmpty) return stored;

    // Last-resort: try to load from dotenv at the time of request
    return await _readApiKeyFromEnvIfPossible();
  }

  Future<String> _getApiKeyHeaderName() async {
    final stored = await _secureStorage.read(key: _storageApiKeyHeader);
    if (stored != null && stored.isNotEmpty) return stored;

    if (_dotenvLoaded) {
      final envHeader = dotenv.env[_envApiKeyHeaderName];
      if (envHeader != null && envHeader.isNotEmpty) return envHeader;
    }

    // Try to load dotenv now as a best-effort fallback
    try {
      await dotenv.load();
      final envHeader = dotenv.env[_envApiKeyHeaderName];
      if (envHeader != null && envHeader.isNotEmpty) {
        await _secureStorage.write(key: _storageApiKeyHeader, value: envHeader);
        return envHeader;
      }
    } catch (_) {}

    return 'x-api-key';
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

    if (apiKey != null && apiKey.isNotEmpty) {
      headers[headerName] = apiKey;
    }

    if (requiresAuth) {
      if (accessToken == null || accessToken.isEmpty) {
        throw ApiException(401, 'Missing access token. Please login again.');
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
    if (!kDebugMode) return;
    try {
      debugPrint('ApiClient => $method $uri');
      debugPrint('Headers: $headers');
      if (body != null)
        debugPrint('Body: ${body is String ? body : jsonEncode(body)}');
    } catch (_) {}
  }

  Future<void> saveAccessToken(String token) async {
    await _secureStorage.write(key: _storageAccessToken, value: token);
  }

  Future<String?> getAccessToken() async {
    return _secureStorage.read(key: _storageAccessToken);
  }

  Future<void> clearAccessToken() async {
    await _secureStorage.delete(key: _storageAccessToken);
  }

  Future<T> _withRetry<T>(Future<T> Function() fn, {int retries = 1}) async {
    int attempt = 0;
    while (true) {
      try {
        return await fn();
      } catch (e) {
        if (attempt >= retries) rethrow;
        attempt++;
        await Future.delayed(const Duration(milliseconds: 300));
      }
    }
  }

  Future<dynamic> get(
    String path, {
    Map<String, String>? queryParameters,
    bool requiresAuth = false,
  }) async {
    return _withRetry(() async {
      final uri = Uri.parse(
        baseUrl + path,
      ).replace(queryParameters: queryParameters);
      final headers = await _defaultHeaders(requiresAuth: requiresAuth);
      _debugLogRequest('GET', uri, headers);
      final resp = await _httpClient
          .get(uri, headers: headers)
          .timeout(const Duration(seconds: 10));
      return _processResponse(resp);
    });
  }

  Future<dynamic> post(
    String path, {
    Object? body,
    bool requiresAuth = false,
  }) async {
    return _withRetry(() async {
      final uri = Uri.parse(baseUrl + path);
      final headers = await _defaultHeaders(requiresAuth: requiresAuth);
      _debugLogRequest('POST', uri, headers, body);
      final resp = await _httpClient
          .post(
            uri,
            headers: headers,
            body: body == null ? null : jsonEncode(body),
          )
          .timeout(const Duration(seconds: 10));
      return _processResponse(resp);
    });
  }

  Future<dynamic> patch(
    String path, {
    Object? body,
    bool requiresAuth = false,
  }) async {
    return _withRetry(() async {
      final uri = Uri.parse(baseUrl + path);
      final headers = await _defaultHeaders(requiresAuth: requiresAuth);
      _debugLogRequest('PATCH', uri, headers, body);
      final resp = await _httpClient
          .patch(
            uri,
            headers: headers,
            body: body == null ? null : jsonEncode(body),
          )
          .timeout(const Duration(seconds: 10));
      return _processResponse(resp);
    });
  }

  Future<dynamic> delete(String path, {bool requiresAuth = false}) async {
    return _withRetry(() async {
      final uri = Uri.parse(baseUrl + path);
      final headers = await _defaultHeaders(requiresAuth: requiresAuth);
      _debugLogRequest('DELETE', uri, headers);
      final resp = await _httpClient
          .delete(uri, headers: headers)
          .timeout(const Duration(seconds: 10));
      return _processResponse(resp);
    });
  }

  dynamic _processResponse(http.Response resp) {
    final status = resp.statusCode;
    final body = resp.body.isNotEmpty ? resp.body : '';
    // Debug - always log response status and body in debug mode
    if (kDebugMode) {
      try {
        debugPrint('ApiClient <= HTTP $status');
        debugPrint('Response headers: ${resp.headers}');
        debugPrint('Response body: $body');
      } catch (_) {}
    }

    if (status >= 200 && status < 300) {
      try {
        return jsonDecode(body);
      } catch (_) {
        return body;
      }
    }

    // If unauthorized, clear stored token and notify app to return to login.
    if (status == 401) {
      try {
        // Best-effort: clear stored access token so subsequent hasSession
        // checks return false.
        clearAccessToken();
      } catch (_) {}
      try {
        SessionEvents.notifyUnauthorized();
      } catch (_) {}
    }

    // Log and propagate non-2xx responses as ApiException
    try {
      debugPrint('ApiClient error: status=$status body=$body');
    } catch (_) {}
    throw ApiException(status, body);
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
