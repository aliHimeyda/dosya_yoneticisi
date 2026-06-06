import 'package:dosya_gezgini/core/localization/l10n_extensions.dart';
import 'package:dosya_gezgini/data/services/device_auth_service.dart';
import 'package:dosya_gezgini/features/files/state/hidden_password_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

enum HiddenPasswordSheetMode { verifyPassword, createPassword, resetPassword }

enum HiddenPasswordFlowResult { authenticated, passwordCreated, passwordReset }

enum _HiddenPasswordSheetResult {
  authenticated,
  forgotPassword,
  passwordCreated,
  passwordReset,
}

Future<HiddenPasswordFlowResult?> showHiddenFilesPasswordFlow(
  BuildContext context,
) async {
  final provider = context.read<HiddenPasswordProvider>();
  provider.clearTransientState();

  final verifyResult = await _showHiddenPasswordBottomSheet(
    context,
    mode: HiddenPasswordSheetMode.verifyPassword,
  );

  if (!context.mounted || verifyResult == null) {
    return null;
  }

  if (verifyResult == _HiddenPasswordSheetResult.authenticated) {
    return HiddenPasswordFlowResult.authenticated;
  }

  if (verifyResult != _HiddenPasswordSheetResult.forgotPassword) {
    return null;
  }

  final authResult = await provider.authenticateForPasswordReset(
    localizedReason: context.l10n.hiddenPasswordDeviceAuthReason,
  );
  if (!context.mounted) {
    return null;
  }

  if (!authResult.isAuthenticated) {
    _showFeedback(
      context,
      _deviceAuthMessage(context, authResult.failureReason),
      isError: true,
    );
    return null;
  }

  final resetResult = await _showHiddenPasswordBottomSheet(
    context,
    mode: HiddenPasswordSheetMode.resetPassword,
  );
  if (!context.mounted || resetResult == null) {
    return null;
  }

  if (resetResult == _HiddenPasswordSheetResult.passwordReset) {
    _showFeedback(
      context,
      context.l10n.hiddenPasswordUpdatedSuccess,
      isError: false,
    );
    return HiddenPasswordFlowResult.passwordReset;
  }

  return null;
}

Future<_HiddenPasswordSheetResult?> _showHiddenPasswordBottomSheet(
  BuildContext context, {
  required HiddenPasswordSheetMode mode,
}) {
  return showModalBottomSheet<_HiddenPasswordSheetResult>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Theme.of(context).canvasColor,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => _HiddenPasswordBottomSheet(mode: mode),
  );
}

String _deviceAuthMessage(
  BuildContext context,
  DeviceAuthFailureReason? reason,
) {
  switch (reason) {
    case DeviceAuthFailureReason.noSecureLock:
      return context.l10n.hiddenPasswordNoSecureLock;
    case DeviceAuthFailureReason.cancelled:
      return context.l10n.hiddenPasswordResetCancelled;
    case DeviceAuthFailureReason.unsupported:
      return context.l10n.hiddenPasswordAuthUnsupported;
    case DeviceAuthFailureReason.failed:
    case null:
      return context.l10n.hiddenPasswordAuthFailed;
  }
}

void _showFeedback(
  BuildContext context,
  String message, {
  required bool isError,
}) {
  final theme = Theme.of(context);
  final colorScheme = theme.colorScheme;

  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        backgroundColor: isError ? colorScheme.error : theme.primaryColor,
        content: Text(
          message,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: isError ? colorScheme.onError : colorScheme.onPrimary,
          ),
        ),
      ),
    );
}

class _HiddenPasswordBottomSheet extends StatefulWidget {
  const _HiddenPasswordBottomSheet({required this.mode});

  final HiddenPasswordSheetMode mode;

  @override
  State<_HiddenPasswordBottomSheet> createState() =>
      _HiddenPasswordBottomSheetState();
}

class _HiddenPasswordBottomSheetState
    extends State<_HiddenPasswordBottomSheet> {
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  String? _errorMessage;

  bool get _requiresConfirmation =>
      widget.mode == HiddenPasswordSheetMode.createPassword ||
      widget.mode == HiddenPasswordSheetMode.resetPassword;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handlePrimaryAction() async {
    FocusScope.of(context).unfocus();
    setState(() {
      _errorMessage = null;
    });

    final provider = context.read<HiddenPasswordProvider>();
    if (widget.mode == HiddenPasswordSheetMode.verifyPassword) {
      final result = await provider.verifyPassword(_passwordController.text);
      if (!mounted) {
        return;
      }

      switch (result) {
        case HiddenPasswordVerificationStatus.success:
          Navigator.of(context).pop(_HiddenPasswordSheetResult.authenticated);
          return;
        case HiddenPasswordVerificationStatus.empty:
          setState(() {
            _errorMessage = context.l10n.hiddenPasswordEmptyError;
          });
          return;
        case HiddenPasswordVerificationStatus.incorrect:
          setState(() {
            _errorMessage = context.l10n.incorrectPassword;
          });
          return;
      }
    }

    final result = await provider.savePassword(
      newPassword: _passwordController.text,
      confirmPassword: _confirmPasswordController.text,
    );
    if (!mounted) {
      return;
    }

    switch (result) {
      case HiddenPasswordSaveStatus.success:
        Navigator.of(context).pop(
          widget.mode == HiddenPasswordSheetMode.createPassword
              ? _HiddenPasswordSheetResult.passwordCreated
              : _HiddenPasswordSheetResult.passwordReset,
        );
        return;
      case HiddenPasswordSaveStatus.empty:
        setState(() {
          _errorMessage = context.l10n.hiddenPasswordEmptyError;
        });
        return;
      case HiddenPasswordSaveStatus.mismatch:
        setState(() {
          _errorMessage = context.l10n.hiddenPasswordMismatch;
        });
        return;
      case HiddenPasswordSaveStatus.failed:
        setState(() {
          _errorMessage = context.l10n.hiddenPasswordUpdateFailed;
        });
        return;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sheetCopy = _sheetCopy(context);

    return Consumer<HiddenPasswordProvider>(
      builder: (context, provider, _) {
        final isBusy =
            provider.isAuthenticatingDevice || provider.isResettingPassword;

        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(sheetCopy.title, style: theme.textTheme.titleLarge),
              if (sheetCopy.description != null) ...[
                const SizedBox(height: 6),
                Text(
                  sheetCopy.description!,
                  style: (theme.textTheme.bodyMedium ?? const TextStyle())
                      .copyWith(
                        color: (theme.textTheme.bodyMedium?.color ??
                                theme.iconTheme.color)
                            ?.withValues(alpha: 0.76),
                      ),
                ),
              ],
              const SizedBox(height: 16),
              _PasswordFieldContainer(
                controller: _passwordController,
                hintText: sheetCopy.primaryHint,
                theme: theme,
              ),
              if (_requiresConfirmation) ...[
                const SizedBox(height: 12),
                _PasswordFieldContainer(
                  controller: _confirmPasswordController,
                  hintText: context.l10n.hiddenPasswordConfirmHint,
                  theme: theme,
                ),
              ],
              if (_errorMessage != null) ...[
                const SizedBox(height: 12),
                Text(
                  _errorMessage!,
                  style: (theme.textTheme.bodyMedium ?? const TextStyle())
                      .copyWith(color: theme.colorScheme.error),
                ),
              ],
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  ElevatedButton(
                    onPressed: isBusy ? null : _handlePrimaryAction,
                    child:
                        isBusy
                            ? SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: theme.colorScheme.onPrimary,
                              ),
                            )
                            : Text(sheetCopy.primaryActionLabel),
                  ),
                  ElevatedButton(
                    onPressed:
                        isBusy ? null : () => Navigator.of(context).pop(),
                    child: Text(context.l10n.cancel),
                  ),
                ],
              ),
              if (widget.mode == HiddenPasswordSheetMode.verifyPassword) ...[
                const SizedBox(height: 8),
                Center(
                  child: TextButton(
                    onPressed:
                        isBusy
                            ? null
                            : () => Navigator.of(
                              context,
                            ).pop(_HiddenPasswordSheetResult.forgotPassword),
                    style: TextButton.styleFrom(
                      foregroundColor: theme.primaryColor,
                    ),
                    child: Text(context.l10n.forgotHiddenPassword),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  _HiddenPasswordSheetCopy _sheetCopy(BuildContext context) {
    switch (widget.mode) {
      case HiddenPasswordSheetMode.verifyPassword:
        return _HiddenPasswordSheetCopy(
          title: context.l10n.hiddenFiles,
          description: context.l10n.hiddenPasswordVerifyDescription,
          primaryHint: context.l10n.passwordHint,
          primaryActionLabel: context.l10n.ok,
        );
      case HiddenPasswordSheetMode.createPassword:
        return _HiddenPasswordSheetCopy(
          title: context.l10n.hiddenPasswordCreateTitle,
          description: context.l10n.hiddenPasswordCreateDescription,
          primaryHint: context.l10n.hiddenPasswordNewHint,
          primaryActionLabel: context.l10n.hiddenPasswordCreateAction,
        );
      case HiddenPasswordSheetMode.resetPassword:
        return _HiddenPasswordSheetCopy(
          title: context.l10n.hiddenPasswordResetTitle,
          description: context.l10n.hiddenPasswordResetDescription,
          primaryHint: context.l10n.hiddenPasswordNewHint,
          primaryActionLabel: context.l10n.hiddenPasswordUpdateAction,
        );
    }
  }
}

class _PasswordFieldContainer extends StatelessWidget {
  const _PasswordFieldContainer({
    required this.controller,
    required this.hintText,
    required this.theme,
  });

  final TextEditingController controller;
  final String hintText;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      constraints: BoxConstraints(
        minHeight: MediaQuery.of(context).size.height / 10,
      ),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(width: 0.3, color: theme.iconTheme.color!),
          top: BorderSide(width: 1, color: theme.iconTheme.color!),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Row(
          children: [
            Icon(Icons.lock, color: theme.primaryColor, size: 40),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: controller,
                obscureText: true,
                textInputAction: TextInputAction.done,
                style: theme.textTheme.bodyLarge,
                decoration: InputDecoration(
                  hintText: hintText,
                  hintStyle: theme.textTheme.bodyLarge,
                  border: InputBorder.none,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HiddenPasswordSheetCopy {
  const _HiddenPasswordSheetCopy({
    required this.title,
    required this.primaryHint,
    required this.primaryActionLabel,
    this.description,
  });

  final String title;
  final String? description;
  final String primaryHint;
  final String primaryActionLabel;
}
