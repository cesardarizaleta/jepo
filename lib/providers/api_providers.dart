import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/api_client.dart';

/// Root provider that exposes the global [ApiClient] to the Riverpod graph.
///
/// [appApi] is initialized during `main()` via `initApi()`, so by the time any
/// widget consumes this provider, the client is guaranteed to be ready.
/// Having it flow through Riverpod means every downstream service provider
/// (contacts, alerts, auth, telemetry) can be overridden in tests without
/// touching a global singleton.
final apiClientProvider = Provider<ApiClient>((ref) {
  if (!appApiInitialized) {
    throw StateError(
      'ApiClient is not initialized yet. Ensure initApi() has been awaited '
      'before reading apiClientProvider.',
    );
  }
  return appApi;
});
