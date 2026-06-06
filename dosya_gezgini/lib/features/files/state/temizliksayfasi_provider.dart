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
  }

  static const List<CleaningSourceType> _stageOrder = <CleaningSourceType>[
    CleaningSourceType.cache,
    CleaningSourceType.unusedFiles,
    CleaningSourceType.packages,
    CleaningSourceType.residualFiles,
    CleaningSourceType.memory,
  ];

  static const double _bytesInKilobyte = 1024;
  static const double _bytesInMegabyte = _bytesInKilobyte * 1024;
  static const double _bytesInGigabyte = _bytesInMegabyte * 1024;

  final Dosyaislemleri _owner;
  bool _didScheduleInitialScan = false;
  bool _isDisposed = false;
  bool _notifyScheduled = false;

  Dosyaislemleri get owner => _owner;
  CleaningScanProgress? get scanProgress => _owner.cleanupScanProgress;
  CleaningScanResult? get scanResult => _owner.cleanupScanResult;
  CleaningDeleteProgress? get deleteProgress => _owner.cleanupDeleteProgress;
  CleaningDeleteResult? get deleteResult => _owner.cleanupDeleteResult;
  Object? get cleanupError => _owner.cleanupError;
  bool get isScanning => _owner.isCleanupScanning;
  bool get isCleaning => _owner.isCleanupDeleting;
  bool get isStopped => _owner.cleanupWasStopped;
  bool get hasCleanupCandidates => _owner.hasCleanupCandidates;
  bool get hasCleanupResult => _owner.hasCleanupResult;
  bool get isCompleted =>
      !isScanning &&
      !isCleaning &&
      (scanResult != null || deleteResult != null);
  bool get isIdle => !isScanning && !isCleaning;
  bool get canRetryFromHeader => isIdle;
  bool get isActionEnabled => !isCleaning;
  bool get stopRequested => _owner.cleanupStopRequested;
  int get cleanupCandidateCount => _owner.cleanupCandidateCount;
  int get cleanupCandidateBytes => _owner.cleanupCandidateBytes;

  List<CleaningIssue> get scanIssues => _owner.cleanupIssues
      .where((issue) => issue.stage == CleaningIssueStage.scan)
      .toList(growable: false);

  List<CleaningIssue> get deleteIssues => _owner.cleanupIssues
      .where((issue) => issue.stage == CleaningIssueStage.delete)
      .toList(growable: false);

  void ensureScanStarted() {
    if (_didScheduleInitialScan) {
      return;
    }

    _didScheduleInitialScan = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_isDisposed || isScanning || isCleaning || scanResult != null) {
        return;
      }

      unawaited(_owner.startCleanupScan());
    });
  }

  Future<void> retryScan() async {
    await _owner.startCleanupScan();
  }

  Future<void> handleHeaderAction() async {
    if (!canRetryFromHeader) {
      return;
    }

    await retryScan();
  }

  Future<void> handleMainAction(BuildContext context) async {
    if (isCleaning) {
      return;
    }

    if (isScanning) {
      _owner.requestCleanupStop();
      return;
    }

    if (deleteResult != null) {
      await Navigator.of(context).maybePop();
      return;
    }

    if (hasCleanupCandidates) {
      await confirmCleanup(context);
      return;
    }

    await retryScan();
  }

  Future<void> confirmCleanup(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (dialogContext) => AlertDialog(
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            title: Text(
              l10n.cleanupConfirmTitle,
              style: TextStyle(
                color: Theme.of(context).textTheme.titleMedium?.color,
              ),
            ),
            content: Text(
              l10n.cleanupConfirmMessage(
                cleanupCandidateCount,
                formatBytes(cleanupCandidateBytes),
              ),
              style: TextStyle(
                color: Theme.of(context).textTheme.titleMedium?.color,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                style: TextButton.styleFrom(
                  textStyle: TextStyle(color: Theme.of(context).primaryColor),
                ),
                child: Text(
                  l10n.cancel,
                  style: TextStyle(color: Theme.of(context).primaryColor),
                ),
              ),
              FilledButton(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                style: FilledButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  textStyle: const TextStyle(color: Colors.white),
                ),
                child: Text(
                  l10n.clean,
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
    );

    if (confirmed == true && context.mounted) {
      await _owner.startCleanupDelete();
    }
  }

  String resolveActionButtonText(AppLocalizations l10n) {
    if (isCleaning) {
      return l10n.cleanerCleaningInProgress;
    }
    if (isScanning) {
      return stopRequested ? l10n.cleanerStopping : l10n.cleanerStop;
    }
    if (deleteResult != null) {
      return l10n.cleanerCompleted;
    }
    if (hasCleanupCandidates) {
      return l10n.clean;
    }
    return l10n.tryAgain;
  }

  String resolveCurrentScanLabel(AppLocalizations l10n) {
    if (isCleaning) {
      return l10n.cleanerCleaningCurrent;
    }
    if (isStopped) {
      return l10n.cleanerScanStopped;
    }
    if (cleanupError != null && scanResult == null) {
      return l10n.errorOccurred;
    }
    if (!isScanning) {
      return l10n.cleanerScanCompleted;
    }

    final currentPath = currentScanningPackage;
    if (currentPath != null && currentPath.isNotEmpty) {
      return currentPath;
    }

    return _sourceLabel(_activeSource ?? CleaningSourceType.cache, l10n);
  }

  String? get currentScanningPackage {
    final currentPath =
        deleteProgress?.currentPath ?? scanProgress?.currentPath;
    if (currentPath == null || currentPath.isEmpty) {
      return null;
    }

    return path.basename(currentPath);
  }

  List<CleanerScanItem> buildScanItems(AppLocalizations l10n) {
    final completedCount = _completedStageCount;
    final activeSource = _activeSource;

    return _stageOrder
        .asMap()
        .entries
        .map(
          (entry) => CleanerScanItem(
            id: entry.value.name,
            title: _sourceLabel(entry.value, l10n),
            status: _resolveStageStatus(
              stageIndex: entry.key,
              source: entry.value,
              completedCount: completedCount,
              activeSource: activeSource,
            ),
            foundSizeBytes: _summaryFor(entry.value)?.detectedBytes ?? 0,
            isCleanable: _summaryFor(entry.value)?.isCleanable ?? false,
          ),
        )
        .toList(growable: false);
  }

  double get totalCleanableSize {
    final bytes = _displayBytes;
    if (bytes <= 0) {
      return 0;
    }
    return bytes / _bytesInGigabyte;
  }

  String get totalSizeText => _splitSizeLabel(_displayBytes).$1;

  String get sizeUnit => _splitSizeLabel(_displayBytes).$2;

  double? get progressValue {
    if (isCleaning) {
      return deleteProgress?.progress;
    }

    if (isScanning) {
      final rawProgress =
          (_completedStageCount + (stopRequested ? 0.0 : 0.5)) /
          _stageOrder.length;
      return rawProgress.clamp(0.0, 1.0).toDouble();
    }

    if (isCompleted || hasCleanupResult) {
      return 1;
    }

    return null;
  }

  String get errorMessage => cleanupError?.toString() ?? '';

  int get processedFiles =>
      scanProgress?.processedFiles ?? scanResult?.processedFiles ?? 0;

  int get scannedCandidateCount =>
      scanResult?.candidates.length ?? scanProgress?.candidateCount ?? 0;

  String get reclaimableSizeText => formatBytes(
    scanResult?.totalBytes ?? scanProgress?.reclaimableBytes ?? 0,
  );

  String? get currentPathBasename {
    final currentPath =
        deleteProgress?.currentPath ?? scanProgress?.currentPath;
    if (currentPath == null || currentPath.isEmpty) {
      return null;
    }

    return path.basename(currentPath);
  }

  String formatBytes(int bytes) {
    if (bytes <= 0) {
      return '0 B';
    }

    if (bytes >= _bytesInGigabyte) {
      return '${(bytes / _bytesInGigabyte).toStringAsFixed(2)} GB';
    }
    if (bytes >= _bytesInMegabyte) {
      return '${(bytes / _bytesInMegabyte).toStringAsFixed(2)} MB';
    }
    if (bytes >= _bytesInKilobyte) {
      return '${(bytes / _bytesInKilobyte).toStringAsFixed(2)} KB';
    }

    return '$bytes B';
  }

  CleaningSourceSummary? _summaryFor(CleaningSourceType source) {
    return scanResult?.summaryFor(source);
  }

  int get _displayBytes {
    if (deleteResult != null) {
      return deleteResult!.deletedBytes;
    }
    if (cleanupCandidateBytes > 0) {
      return cleanupCandidateBytes;
    }
    return scanProgress?.reclaimableBytes ?? 0;
  }

  (String, String) _splitSizeLabel(int bytes) {
    final formatted = formatBytes(bytes);
    final splitIndex = formatted.indexOf(' ');
    if (splitIndex == -1) {
      return (formatted, 'B');
    }

    return (
      formatted.substring(0, splitIndex),
      formatted.substring(splitIndex + 1),
    );
  }

  int get _completedStageCount {
    if (scanProgress != null) {
      return scanProgress!.completedSourceCount
          .clamp(0, _stageOrder.length)
          .toInt();
    }
    if (scanResult != null || deleteResult != null) {
      return _stageOrder.length;
    }
    return 0;
  }

  CleaningSourceType? get _activeSource {
    if (scanProgress == null) {
      return null;
    }

    if (isScanning || isStopped || cleanupError != null) {
      return scanProgress!.source;
    }

    return null;
  }

  CleanerScanStatus _resolveStageStatus({
    required int stageIndex,
    required CleaningSourceType source,
    required int completedCount,
    required CleaningSourceType? activeSource,
  }) {
    if (cleanupError != null &&
        !isStopped &&
        scanResult == null &&
        activeSource == source) {
      return CleanerScanStatus.failed;
    }

    if (isScanning) {
      if (stageIndex < completedCount) {
        return CleanerScanStatus.completed;
      }
      if (activeSource == source) {
        return CleanerScanStatus.scanning;
      }
      return CleanerScanStatus.pending;
    }

    if (isStopped) {
      if (stageIndex < completedCount) {
        return CleanerScanStatus.completed;
      }
      return CleanerScanStatus.pending;
    }

    if (scanResult != null || deleteResult != null) {
      return CleanerScanStatus.completed;
    }

    return CleanerScanStatus.pending;
  }

  String _sourceLabel(CleaningSourceType source, AppLocalizations l10n) {
    switch (source) {
      case CleaningSourceType.cache:
        return l10n.cleanerStageCacheFiles;
      case CleaningSourceType.unusedFiles:
        return l10n.cleanerStageUnusedFiles;
      case CleaningSourceType.packages:
        return l10n.cleanerStagePackages;
      case CleaningSourceType.residualFiles:
      case CleaningSourceType.temporary:
        return l10n.cleanerStageResidualFiles;
      case CleaningSourceType.memory:
        return l10n.cleanerStageMemory;
    }
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

class CleanerScanItem {
  const CleanerScanItem({
    required this.id,
    required this.title,
    required this.status,
    required this.foundSizeBytes,
    required this.isCleanable,
  });

  final String id;
  final String title;
  final CleanerScanStatus status;
  final int foundSizeBytes;
  final bool isCleanable;
}

enum CleanerScanStatus { pending, scanning, completed, failed }
