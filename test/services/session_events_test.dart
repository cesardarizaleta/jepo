import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:jepo/services/session_events.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  // Reset state between tests since SessionEvents uses static fields.
  setUp(() {
    SessionEvents.resetInvalidation();
  });

  group('SessionEvents invalidation guard', () {
    test('notifyUnauthorized sets invalidated flag', () {
      expect(SessionEvents.isInvalidated, isFalse);

      SessionEvents.notifyUnauthorized();

      expect(SessionEvents.isInvalidated, isTrue);
    });

    test('second notifyUnauthorized is a no-op (no cascade)', () async {
      int eventCount = 0;
      final sub = SessionEvents.onUnauthorized.listen((_) => eventCount++);

      SessionEvents.notifyUnauthorized();
      SessionEvents.notifyUnauthorized(); // should be ignored

      // Allow microtask queue to flush
      await Future.delayed(const Duration(milliseconds: 50));

      expect(eventCount, 1);

      await sub.cancel();
    });

    test('notifyLogout always broadcasts', () async {
      int eventCount = 0;
      final sub = SessionEvents.onLogout.listen((_) => eventCount++);

      SessionEvents.notifyLogout();

      await Future.delayed(const Duration(milliseconds: 50));

      expect(eventCount, 1);
      expect(SessionEvents.isInvalidated, isTrue);

      await sub.cancel();
    });

    test('resetInvalidation allows future unauthorized events', () async {
      SessionEvents.notifyUnauthorized();
      expect(SessionEvents.isInvalidated, isTrue);

      SessionEvents.resetInvalidation();
      expect(SessionEvents.isInvalidated, isFalse);

      int eventCount = 0;
      final sub = SessionEvents.onUnauthorized.listen((_) => eventCount++);

      SessionEvents.notifyUnauthorized();
      await Future.delayed(const Duration(milliseconds: 50));

      expect(eventCount, 1);

      await sub.cancel();
    });
  });
}
