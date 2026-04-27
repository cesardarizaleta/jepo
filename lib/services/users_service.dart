import 'package:shared_preferences/shared_preferences.dart';
import '../models/api_response.dart';
import '../models/user.dart';
import '../utils/phone_utils.dart';
import 'api_client.dart';
import 'auth_service.dart';

/// Service for user operations scoped to the authenticated user (ownership).
///
/// In the frontend context the user should only access their own profile via
/// [AuthService.me] and [AuthService.updateProfile]. The CRUD-wide methods
/// (listUsers, createUser, deleteUser, getUser) are retained for admin/debug
/// tooling but are **not** intended for regular UI consumption.
class UsersService {
  final ApiClient api;

  UsersService(this.api);

  // -----------------------------------------------------------------------
  // Ownership-scoped operations (recommended for normal UI)
  // -----------------------------------------------------------------------

  /// Update the FCM push token for the currently authenticated user.
  ///
  /// Reads the user ID from local storage rather than requiring the caller to
  /// supply it, reinforcing ownership semantics.
  Future<User?> updateMyTokenFcm(String tokenFcm) async {
    final userId = await _requireCurrentUserId();
    final envelope = await api.patchEnvelope(
      '/api/usuarios/$userId/token-fcm',
      body: <String, dynamic>{'token_fcm': tokenFcm},
      requiresAuth: true,
    );
    final response = ApiResponse<User>.fromJson(
      envelope.raw,
      dataParser: _parseUser,
    );
    return response.data;
  }

  /// Update the profile of the currently authenticated user.
  ///
  /// Automatically normalises the phone number before sending. Falls back to
  /// [AuthService.updateProfile] semantics (local-first optimistic update on
  /// network failure).
  Future<User?> updateMyProfile(UpdateUserDto payload) async {
    final userId = await _requireCurrentUserId();
    final body = payload.toJson();
    if (body.containsKey('telefono')) {
      body['telefono'] = normalizePhoneForApi(
        body['telefono']?.toString() ?? '',
      );
    }
    final envelope = await api.patchEnvelope(
      '/api/usuarios/$userId',
      body: body,
      requiresAuth: true,
    );
    final response = ApiResponse<User>.fromJson(
      envelope.raw,
      dataParser: _parseUser,
    );
    return response.data;
  }

  // -----------------------------------------------------------------------
  // Admin/debug CRUD — NOT for regular UI (retained for tooling)
  // -----------------------------------------------------------------------

  @Deprecated('Use AuthService.register for user creation in normal flows')
  Future<User?> createUser(CreateUserDto payload) async {
    final envelope = await api.postEnvelope('/api/usuarios', body: payload.toJson());
    final response = ApiResponse<User>.fromJson(
      envelope.raw,
      dataParser: _parseUser,
    );
    return response.data;
  }

  @Deprecated('Regular UI should not list all users')
  Future<List<User>> listUsers() async {
    final envelope = await api.getEnvelope('/api/usuarios');
    final response = ApiResponse<List<User>>.fromJson(
      envelope.raw,
      dataParser: (value) {
        if (value is! List) return const <User>[];
        return value
            .whereType<Map>()
            .map((e) => User.fromJson(e.cast<String, dynamic>()))
            .toList(growable: false);
      },
    );
    return response.data ?? const <User>[];
  }

  @Deprecated('Regular UI should not read arbitrary user profiles')
  Future<User?> getUser(int id) async {
    final envelope = await api.getEnvelope('/api/usuarios/$id');
    final response = ApiResponse<User>.fromJson(
      envelope.raw,
      dataParser: _parseUser,
    );
    return response.data;
  }

  @Deprecated('Use updateMyProfile for the authenticated user')
  Future<User?> updateUser(int id, UpdateUserDto payload) async {
    final envelope = await api.patchEnvelope(
      '/api/usuarios/$id',
      body: payload.toJson(),
    );
    final response = ApiResponse<User>.fromJson(
      envelope.raw,
      dataParser: _parseUser,
    );
    return response.data;
  }

  @Deprecated('Use updateMyTokenFcm for the authenticated user')
  Future<User?> updateTokenFcm(int id, String tokenFcm) async {
    final envelope = await api.patchEnvelope(
      '/api/usuarios/$id/token-fcm',
      body: <String, dynamic>{'token_fcm': tokenFcm},
    );
    final response = ApiResponse<User>.fromJson(
      envelope.raw,
      dataParser: _parseUser,
    );
    return response.data;
  }

  @Deprecated('Regular UI should not delete arbitrary users')
  Future<void> deleteUser(int id) async {
    await api.deleteEnvelope('/api/usuarios/$id');
  }

  // -----------------------------------------------------------------------
  // Helpers
  // -----------------------------------------------------------------------

  Future<int> _requireCurrentUserId() async {
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getInt('jepo_current_user_id');
    if (id == null) {
      throw const ApiException(
        statusCode: 401,
        message: 'No authenticated user. Please login first.',
      );
    }
    return id;
  }

  static User? _parseUser(dynamic value) {
    if (value is Map<String, dynamic>) return User.fromJson(value);
    if (value is Map) return User.fromJson(value.cast<String, dynamic>());
    return null;
  }

  @Deprecated('Use AuthService.getCurrentUserId instead')
  Future<void> saveCurrentUserId(int id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('jepo_current_user_id', id);
  }

  @Deprecated('Use AuthService.getCurrentUserId instead')
  Future<int?> getCurrentUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('jepo_current_user_id');
  }
}
