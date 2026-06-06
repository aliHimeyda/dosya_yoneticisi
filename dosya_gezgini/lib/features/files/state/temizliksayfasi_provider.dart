import 'dart:async';

import 'package:dosya_gezgini/data/models/cleaning_models.dart';
import 'package:dosya_gezgini/features/files/state/dosyaislemleri.dart';
import 'package:dosya_gezgini/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:path/path.dart' as path;

class TemizliksayfasiProvider extends ChangeNotifier {
  TemizliksayfasiProvider({required Dosyaislemleri owner}) : _owner = owner {
    _owner.addListener(_handleOwnerChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_isDisposed || _didStartInitialScan) {
        return;
      }

      _didStartInitialScan = true;
      unawaited(_owner.startCleanupScan());
    });
  }

  final Dosyaislemleri _owner;
  bool _didStartInitialScan = false;
  bool _isDisposed = false;
  bool _notifyScheduled = false;

  Dosyaislemleri get owner => _owner;
  CleaningScanProgress? get scanProgress => _owner.cleanupScanProgress;
  CleaningScanResult? get scanResult => _owner.cleanupScanResult;
  CleaningDeleteProgress? get deleteProgress => _owner.cleanupDeleteProgress;
  CleaningDeleteResult? get deleteResult => _owner.cleanupDeleteResult;
  Object? get cleanupError => _owner.cleanupError;
  bool get isCleanupScanning => _owner.isCleanupScanning;
  bool get isCleanupDeleting => _owner.isCleanupDeleting;
  bool get hasCleanupCandidates => _owner.hasCleanupCandidates;
  bool get isIdle => !isCleanupScanning && !isCleanupDeleting;
  bool get hasCleanupResult => _owner.hasCleanupResult;
  bool get geciciDosyalarTamamlandi => _owner.gecicidosyalaralinmasi;
  bool get onbellekDosyalariTamamlandi => _owner.onbellekdosyalarialinmasi;
  int get cleanupCandidateCount => _owner.cleanupCandidateCount;
  int get cleanupCandidateBytes => _owner.cleanupCandidateBytes;

  List<CleaningIssue> get scanIssues => _owner.cleanupIssues
      .where((issue) => issue.stage == CleaningIssueStage.scan)
      .toList(growable: false);

  List<CleaningIssue> get deleteIssues => _owner.cleanupIssues
      .where((issue) => issue.stage == CleaningIssueStage.delete)
      .toList(growable: false);

  IconData get statusIcon {
    if (isCleanupDeleting) {
      return Icons.delete_sweep_rounded;
    }
    if (isCleanupScanning) {
      return Icons.cleaning_services_rounded;
    }
    if (hasCleanupCandidates) {
      return Icons.warning_amber_rounded;
    }
    return Icons.verified_rounded;
  }

  Color resolveIconColor(ThemeData theme) {
    return hasCleanupCandidates
        ? Colors.orange.shade700
        : theme.colorScheme.primary;
  }

  String resolveHeadline(AppLocalizations l10n) {
    if (isCleanupDeleting) {
      return l10n.cleanupDeleting;
    }
    if (isCleanupScanning) {
      return l10n.cleanupInProgress;
    }
    if (cleanupError != null) {
      return l10n.errorOccurred;
    }
    if (deleteResult != null) {
      return l10n.cleanupReportTitle;
    }
    if (hasCleanupCandidates) {
      return l10n.cleanupReady;
    }
    return l10n.cleanupNothingToClean;
  }

  String resolveSummary(AppLocalizations l10n) {
    if (isCleanupDeleting) {
      return l10n.cleanupConfirmMessage(
        cleanupCandidateCount,
        formatBytes(cleanupCandidateBytes),
      );
    }
    if (deleteResult != null) {
      return l10n.cleanupFreedSpace(formatBytes(deleteResult!.deletedBytes));
    }
    if (scanResult != null && scanResult!.hasCandidates) {
      return l10n.cleanupRecoverableSpace(formatBytes(scanResult!.totalBytes));
    }
    return l10n.cleanupScannedFiles(
      scanProgress?.processedFiles ?? scanResult?.processedFiles ?? 0,
    );
  }

  String? get currentPathBasename {
    final currentPath =
        scanProgress?.currentPath ?? deleteProgress?.currentPath;
    if (currentPath == null || currentPath.isEmpty) {
      return null;
    }

    return path.basename(currentPath);
  }

  Future<void> retryScan() async {
    await _owner.startCleanupScan();
  }

  Future<void> confirmCleanup(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (dialogContext) => AlertDialog(
            title: Text(l10n.cleanupConfirmTitle),
            content: Text(
              l10n.cleanupConfirmMessage(
                cleanupCandidateCount,
                formatBytes(cleanupCandidateBytes),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: Text(l10n.cancel),
              ),
              FilledButton(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                child: Text(l10n.clean),
              ),
            ],
          ),
    );

    if (confirmed == true && context.mounted) {
      await _owner.startCleanupDelete();
    }
  }

  String formatBytes(int bytes) {
    if (bytes <= 0) {
      return '0 B';
    }

    const units = <String>['B', 'KB', 'MB', 'GB', 'TB'];
    var size = bytes.toDouble();
    var unitIndex = 0;

    while (size >= 1024 && unitIndex < units.length - 1) {
      size /= 1024;
      unitIndex++;
    }

    final fractionDigits = unitIndex == 0 ? 0 : 2;
    return '${size.toStringAsFixed(fractionDigits)} ${units[unitIndex]}';
  }

  void _handleOwnerChanged() {
    _notifySafely();
  }

  void _notifySafely() {
    if (_isDisposed) {
      return;
    }

    final schedulerPhase = WidgetsBinding.instance.schedulerPhase;
    final canNotifyNow =
        schedulerPhase == SchedulerPhase.idle ||
        schedulerPhase == SchedulerPhase.postFrameCallbacks;
    if (canNotifyNow) {
      _notifyScheduled = false;
      notifyListeners();
      return;
    }

    if (_notifyScheduled) {
      return;
    }

    _notifyScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_isDisposed) {
        return;
      }

      _notifyScheduled = false;
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _isDisposed = true;
    _owner.removeListener(_handleOwnerChanged);
    super.dispose();
  }
}
