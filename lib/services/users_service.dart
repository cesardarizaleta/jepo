import 'package:shared_preferences/shared_preferences.dart';
import 'api_client.dart';

class UsersService {
  final ApiClient api;

  UsersService(this.api);

  Future<Map<String, dynamic>> createUser(Map<String, dynamic> payload) async {
    final resp = await api.post('/api/usuarios', body: payload);
    if (resp is Map<String, dynamic>) return resp;
    return {'success': false, 'message': 'Unexpected response', 'data': null};
  }

  Future<List<dynamic>> listUsers() async {
    final resp = await api.get('/api/usuarios');
    if (resp is Map && resp.containsKey('data')) {
      return resp['data'] as List<dynamic>;
    }
    if (resp is List) return resp;
    return [];
  }

  Future<Map<String, dynamic>?> getUser(int id) async {
    final resp = await api.get('/api/usuarios/$id');
    if (resp is Map<String, dynamic> && resp.containsKey('data')) {
      return resp['data'] as Map<String, dynamic>;
    }
    return null;
  }

  Future<void> saveCurrentUserId(int id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('jepo_current_user_id', id);
  }

  Future<int?> getCurrentUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('jepo_current_user_id');
  }
}
