import 'package:dosya_gezgini/data/models/file_sync_models.dart';
import 'package:dosya_gezgini/l10n/generated/app_localizations.dart';

String? buildFileSyncNoticeMessage(
  AppLocalizations l10n,
  FileSyncResult result,
) {
  final count = result.affectedTrackedPathCount;
  if (count <= 0) {
    return null;
  }

  return l10n.fileSyncItemsMissing(count);
}
