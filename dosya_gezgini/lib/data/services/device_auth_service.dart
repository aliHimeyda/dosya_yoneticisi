import 'package:flutter/services.dart';
import 'package:local_auth/error_codes.dart' as auth_error;
import 'package:local_auth/local_auth.dart';

enum DeviceAuthFailureReason { unsupported, noSecureLock, cancelled, failed }

class DeviceAuthResult {
  const DeviceAuthResult._({required this.isAuthenticated, this.failureReason});

  const DeviceAuthResult.success() : this._(isAuthenticated: true);

  const DeviceAuthResult.failure(DeviceAuthFailureReason reason)
    : this._(isAuthenticated: false, failureReason: reason);

  final bool isAuthenticated;
  final DeviceAuthFailureReason? failureReason;
}

class DeviceAuthService {
  DeviceAuthService({LocalAuthentication? localAuthentication})
    : _localAuthentication = localAuthentication ?? LocalAuthentication();

  final LocalAuthentication _localAuthentication;

  Future<bool> authenticateForHiddenPasswordReset({
    required String localizedReason,
  }) async {
    final result = await authenticateForHiddenPasswordResetResult(
      localizedReason: localizedReason,
    );
    return result.isAuthenticated;
  }

  Future<DeviceAuthResult> authenticateForHiddenPasswordResetResult({
    required String localizedReason,
  }) async {
    try {
      final isSupported = await _localAuthentication.isDeviceSupported();
      if (!isSupported) {
        return const DeviceAuthResult.failure(
          DeviceAuthFailureReason.unsupported,
        );
      }

      final isAuthenticated = await _localAuthentication.authenticate(
        localizedReason: localizedReason,
        options: const AuthenticationOptions(
          biometricOnly: false,
          stickyAuth: true,
          useErrorDialogs: true,
        ),
      );

      if (isAuthenticated) {
        return const DeviceAuthResult.success();
      }

      return const DeviceAuthResult.failure(DeviceAuthFailureReason.failed);
    } on PlatformException catch (error) {
      return DeviceAuthResult.failure(_mapPlatformError(error));
    }
  }

  DeviceAuthFailureReason _mapPlatformError(PlatformException error) {
    final code = error.code.toLowerCase();
    final message = (error.message ?? '').toLowerCase();

    if (code.contains('cancel')) {
      return DeviceAuthFailureReason.cancelled;
    }

    if (code == auth_error.passcodeNotSet ||
        code == auth_error.notEnrolled ||
        message.contains('security credentials not available') ||
        message.contains('required security features not enabled') ||
        message.contains('no pin, pattern or password is set')) {
      return DeviceAuthFailureReason.noSecureLock;
    }

    if (code == auth_error.notAvailable ||
        code == auth_error.otherOperatingSystem) {
      return DeviceAuthFailureReason.unsupported;
    }

    return DeviceAuthFailureReason.failed;
  }
}
