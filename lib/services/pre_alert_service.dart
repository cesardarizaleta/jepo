import 'dart:async';

class PreAlertRequest {
  final int seconds;
  final Completer<bool> _completer = Completer<bool>();

  PreAlertRequest({required this.seconds});

  Future<bool> get isSafeDecision => _completer.future;

  void resolveAsSafe(bool isSafe) {
    if (!_completer.isCompleted) {
      _completer.complete(isSafe);
    }
  }
}

class PreAlertService {
  static final StreamController<PreAlertRequest> _controller =
      StreamController<PreAlertRequest>.broadcast();

  static Stream<PreAlertRequest> get onRequest => _controller.stream;

  /// Returns true when alert should be sent, false when user confirmed safe.
  static Future<bool> requestConfirmation({int seconds = 10}) async {
    // If there is no active UI listener, allow send to avoid blocking alarms.
    if (!_controller.hasListener) {
      return true;
    }

    final request = PreAlertRequest(seconds: seconds);
    _controller.add(request);

    final isSafe = await request.isSafeDecision.timeout(
      Duration(seconds: seconds + 2),
      onTimeout: () => false,
    );

    return !isSafe;
  }
}
