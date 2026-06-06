import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:dosya_gezgini/data/repositories/hidden_password_repository.dart';
import 'package:dosya_gezgini/data/services/device_auth_service.dart';
import 'package:flutter/foundation.dart';

enum HiddenPasswordVerificationStatus { success, empty, incorrect }

enum HiddenPasswordSaveStatus { success, empty, mismatch, failed }

class HiddenPasswordProvider extends ChangeNotifier {
  HiddenPasswordProvider({
    required HiddenPasswordRepository hiddenPasswordRepository,
    required DeviceAuthService deviceAuthService,
  }) : _hiddenPasswordRepository = hiddenPasswordRepository,
       _deviceAuthService = deviceAuthService;

  static const String _legacyHiddenFilesPassword = 'alihimeyda';
  static final Random _secureRandom = Random.secure();

  final HiddenPasswordRepository _hiddenPasswordRepository;
  final DeviceAuthService _deviceAuthService;

  bool isAuthenticatingDevice = false;
  bool isResettingPassword = false;
  bool wasDeviceAuthSuccessful = false;
  DeviceAuthFailureReason? lastDeviceAuthFailure;

  Future<HiddenPasswordVerificationStatus> verifyPassword(
    String rawPassword,
  ) async {
    final password = rawPassword.trim();
    if (password.isEmpty) {
      return HiddenPasswordVerificationStatus.empty;
    }

    final credentials = await _hiddenPasswordRepository.readCredentials();
    if (credentials == null) {
      if (password != _legacyHiddenFilesPassword) {
        return HiddenPasswordVerificationStatus.incorrect;
      }

      try {
        await _persistPassword(password);
      } catch (error) {
        debugPrint('Legacy hidden password migration failed: $error');
      }
      return HiddenPasswordVerificationStatus.success;
    }

    final hashedPassword = _hashPassword(
      password: password,
      salt: credentials.passwordSalt,
    );
    if (hashedPassword == credentials.passwordHash) {
      return HiddenPasswordVerificationStatus.success;
    }

    return HiddenPasswordVerificationStatus.incorrect;
  }

  Future<HiddenPasswordSaveStatus> savePassword({
    required String newPassword,
    required String confirmPassword,
  }) async {
    final normalizedPassword = newPassword.trim();
    final normalizedConfirmPassword = confirmPassword.trim();

    if (normalizedPassword.isEmpty || normalizedConfirmPassword.isEmpty) {
      return HiddenPasswordSaveStatus.empty;
    }

    if (normalizedPassword != normalizedConfirmPassword) {
      return HiddenPasswordSaveStatus.mismatch;
    }

    isResettingPassword = true;
    notifyListeners();

    try {
      await _persistPassword(normalizedPassword);
      return HiddenPasswordSaveStatus.success;
    } catch (error) {
      debugPrint('Hidden password save failed: $error');
      return HiddenPasswordSaveStatus.failed;
    } finally {
      isResettingPassword = false;
      notifyListeners();
    }
  }

  Future<DeviceAuthResult> authenticateForPasswordReset({
    required String localizedReason,
  }) async {
    isAuthenticatingDevice = true;
    wasDeviceAuthSuccessful = false;
    lastDeviceAuthFailure = null;
    notifyListeners();

    try {
      final result = await _deviceAuthService
          .authenticateForHiddenPasswordResetResult(
            localizedReason: localizedReason,
          );
      wasDeviceAuthSuccessful = result.isAuthenticated;
      lastDeviceAuthFailure = result.failureReason;
      return result;
    } finally {
      isAuthenticatingDevice = false;
      notifyListeners();
    }
  }

  void clearTransientState() {
    wasDeviceAuthSuccessful = false;
    lastDeviceAuthFailure = null;
    notifyListeners();
  }

  Future<void> _persistPassword(String password) async {
    final salt = _createSalt();
    final passwordHash = _hashPassword(password: password, salt: salt);
    await _hiddenPasswordRepository.saveCredentials(
      HiddenPasswordCredentials(passwordHash: passwordHash, passwordSalt: salt),
    );
  }

  String _createSalt() {
    final saltBytes = List<int>.generate(16, (_) => _secureRandom.nextInt(256));
    return base64UrlEncode(saltBytes);
  }

  String _hashPassword({required String password, required String salt}) {
    return sha256.convert(utf8.encode('$salt::$password')).toString();
  }
}
