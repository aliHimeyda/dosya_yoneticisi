import 'package:dosya_gezgini/data/models/file_access_result.dart';
import 'package:dosya_gezgini/l10n/generated/app_localizations.dart';

String resolveFileAccessErrorMessage(AppLocalizations l10n, Object? error) {
  if (error is FileAccessResult) {
    switch (error.issueCode) {
      case FileAccessIssueCode.invalidPath:
        return l10n.fileAccessInvalidPath;
      case FileAccessIssueCode.deleted:
        return l10n.fileAccessDeleted;
      case FileAccessIssueCode.wrongType:
        return l10n.fileAccessExpectedDirectory;
      case FileAccessIssueCode.readDenied:
        return l10n.fileAccessReadDenied;
      case FileAccessIssueCode.permissionDenied:
        return l10n.fileAccessPermissionDenied;
      case FileAccessIssueCode.symbolicLinkUnsupported:
        return l10n.fileAccessSymbolicLinkUnsupported;
      case null:
        return l10n.fileAccessUnavailable;
    }
  }

  final normalizedError = error.toString().toLowerCase();
  if (normalizedError.contains('folder_route_not_found')) {
    return l10n.fileAccessInvalidPath;
  }
  if (normalizedError.contains('directory_not_found')) {
    return l10n.fileAccessDeleted;
  }

  return l10n.fileAccessUnavailable;
}
