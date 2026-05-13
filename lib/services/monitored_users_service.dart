import '../models/api_response.dart';
import '../models/monitored_user.dart';
import 'api_client.dart';

/// Repository for the Family Map feature.
///
/// Consumes `GET /api/mapa/monitoreados` — users who have me registered as
/// a verified emergency contact and are therefore visible in my map.
class MonitoredUsersService {
  final ApiClient api;

  MonitoredUsersService(this.api);

  Future<List<MonitoredUser>> listMonitored() async {
    final envelope = await api.getEnvelope(
      '/api/mapa/monitoreados',
      requiresAuth: true,
    );

    final response = ApiResponse<List<MonitoredUser>>.fromJson(
      envelope.raw,
      dataParser: (value) {
        if (value is! List) return const <MonitoredUser>[];
        return value
            .whereType<Map>()
            .map((e) => MonitoredUser.fromJson(e.cast<String, dynamic>()))
            .toList(growable: false);
      },
    );

    final list = response.data ?? const <MonitoredUser>[];
    // Active alerts first, then by name.
    final sorted = list.toList(growable: false)
      ..sort((a, b) {
        if (a.tieneAlertaActiva != b.tieneAlertaActiva) {
          return a.tieneAlertaActiva ? -1 : 1;
        }
        return a.fullName.compareTo(b.fullName);
      });
    return sorted;
  }
}
