import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/auth_service.dart';
import 'api_providers.dart';

/// Riverpod-exposed [AuthService] bound to the current [ApiClient].
final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService(ref.watch(apiClientProvider));
});

/// Granular state for the "Forgot Password" flow so the UI can swap
/// between the request-OTP card and the confirm-OTP card declaratively.
enum ForgotPasswordStep { requestOtp, confirmOtp, done }

class ForgotPasswordState {
  final ForgotPasswordStep step;
  final String emailOrPhone;
  final String method; // "email" | "whatsapp"
  final bool isLoading;
  final String? error;

  const ForgotPasswordState({
    this.step = ForgotPasswordStep.requestOtp,
    this.emailOrPhone = '',
    this.method = 'email',
    this.isLoading = false,
    this.error,
  });

  ForgotPasswordState copyWith({
    ForgotPasswordStep? step,
    String? emailOrPhone,
    String? method,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return ForgotPasswordState(
      step: step ?? this.step,
      emailOrPhone: emailOrPhone ?? this.emailOrPhone,
      method: method ?? this.method,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class ForgotPasswordController extends StateNotifier<ForgotPasswordState> {
  final Ref _ref;
  ForgotPasswordController(this._ref) : super(const ForgotPasswordState());

  void setMethod(String method) {
    state = state.copyWith(method: method, clearError: true);
  }

  Future<bool> requestOtp(String emailOrPhone) async {
    if (emailOrPhone.trim().isEmpty) {
      state = state.copyWith(error: 'Ingresa tu email o telefono');
      return false;
    }
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await _ref
          .read(authServiceProvider)
          .forgotPassword(
            emailOrPhone: emailOrPhone.trim(),
            method: state.method,
          );
      state = state.copyWith(
        step: ForgotPasswordStep.confirmOtp,
        emailOrPhone: emailOrPhone.trim(),
        isLoading: false,
      );
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<bool> confirmReset({
    required String otp,
    required String newPassword,
  }) async {
    if (otp.length != 6) {
      state = state.copyWith(error: 'El codigo debe tener 6 digitos');
      return false;
    }
    if (newPassword.length < 8) {
      state = state.copyWith(error: 'Minimo 8 caracteres');
      return false;
    }
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await _ref
          .read(authServiceProvider)
          .resetPassword(
            emailOrPhone: state.emailOrPhone,
            otp: otp,
            newPassword: newPassword,
          );
      state = state.copyWith(step: ForgotPasswordStep.done, isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  void goBackToRequest() {
    state = state.copyWith(
      step: ForgotPasswordStep.requestOtp,
      clearError: true,
    );
  }
}

final forgotPasswordControllerProvider =
    StateNotifierProvider.autoDispose<
      ForgotPasswordController,
      ForgotPasswordState
    >((ref) {
      return ForgotPasswordController(ref);
    });
