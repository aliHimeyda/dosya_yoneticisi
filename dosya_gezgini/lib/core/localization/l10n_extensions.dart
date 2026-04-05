import 'package:dosya_gezgini/l10n/generated/app_localizations.dart';
import 'package:flutter/widgets.dart';

extension L10nBuildContextX on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this)!;
}
