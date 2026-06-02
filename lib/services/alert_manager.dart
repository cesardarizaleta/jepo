import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'alert_queue_service.dart';
import 'alerts_service.dart';
import 'api_client.dart';
import 'pre_alert_service.dart';

enum AlertStatus { none, triggered, confirming, resolved }

class AlertState {
  final AlertStatus status;
  final int? alertId;
  final bool isLoading;
  final String? error;

  const AlertState({
    this.status = AlertStatus.none,
    this.alertId,
    this.isLoading = false,
    this.error,
  });

  AlertState copyWith({
    AlertStatus? status,
    int? alertId,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return AlertState(
      status: status ?? this.status,
      alertId: alertId ?? this.alertId,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class AlertManager extends StateNotifier<AlertState> {
  final AlertsService _alertsService;
  final AlertQueueService _alertQueueService;

  AlertManager(this._alertsService, this._alertQueueService)
    : super(const AlertState());

  void setTriggered({int? alertId}) {
    state = state.copyWith(
      status: AlertStatus.triggered,
      alertId: alertId,
      clearError: true,
    );
  }

  Future<int?> ensureAlertId({
    Duration timeout = const Duration(seconds: 3),
  }) async {
    if (state.alertId != null) return state.alertId;

    final stopwatch = Stopwatch()..start();
    while (stopwatch.elapsed < timeout) {
      final preAlertId = PreAlertService.activeIncidentId;
      final queueId = await _alertQueueService.activeIncidentId;
      final resolvedId = preAlertId ?? queueId;
      if (resolvedId != null) {
        state = state.copyWith(alertId: resolvedId);
        return resolvedId;
      }
      await Future.delayed(const Duration(milliseconds: 250));
    }
    return null;
  }

  Future<void> resolveActiveAlert() async {
    state = state.copyWith(
      status: AlertStatus.confirming,
      isLoading: true,
      clearError: true,
    );

    final alertId = await ensureAlertId(timeout: const Duration(seconds: 4));
    if (alertId == null) {
      state = state.copyWith(
        status: AlertStatus.triggered,
        isLoading: false,
        error: 'No se encontro la alerta activa',
      );
      return;
    }

    try {
      await _alertsService.resolveAlert(alertId);
      PreAlertService.clearIncident();
      await _alertQueueService.clearActiveIncident();
      state = state.copyWith(status: AlertStatus.resolved, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        status: AlertStatus.triggered,
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  void reset() {
    state = const AlertState();
  }
}

final alertManagerProvider = StateNotifierProvider<AlertManager, AlertState>((
  ref,
) {
  return AlertManager(AlertsService(appApi), AlertQueueService(appApi));
});
