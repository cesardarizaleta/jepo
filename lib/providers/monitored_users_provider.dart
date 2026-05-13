import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/monitored_user.dart';
import '../services/monitored_users_service.dart';
import 'api_providers.dart';

/// Exposes the repository through Riverpod so tests can override it.
final monitoredUsersServiceProvider = Provider<MonitoredUsersService>((ref) {
  return MonitoredUsersService(ref.watch(apiClientProvider));
});

/// One-shot fetch of the users I can monitor. Use `ref.invalidate` on
/// this provider (or the auto-refresh provider below) to refresh.
final monitoredUsersProvider = FutureProvider.autoDispose<List<MonitoredUser>>((
  ref,
) async {
  final service = ref.watch(monitoredUsersServiceProvider);
  return service.listMonitored();
});

/// Auto-refreshing variant that re-fetches every [_autoRefreshInterval]
/// while the map screen is mounted, so pins update in near real time
/// without the user having to pull-to-refresh.
final autoRefreshMonitoredUsersProvider =
    StreamProvider.autoDispose<List<MonitoredUser>>((ref) async* {
      final service = ref.watch(monitoredUsersServiceProvider);

      const refresh = Duration(seconds: 30);

      // Emit immediately, then poll.
      try {
        yield await service.listMonitored();
      } catch (e) {
        rethrow;
      }

      await for (final _ in Stream<void>.periodic(refresh)) {
        try {
          yield await service.listMonitored();
        } catch (_) {
          // Silent failure — keep the last snapshot on the screen.
        }
      }
    });
