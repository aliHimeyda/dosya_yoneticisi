import 'dart:async';
import 'dart:io';

import 'package:dosya_gezgini/core/localization/l10n_extensions.dart';
import 'package:dosya_gezgini/data/models/cleaning_models.dart';
import 'package:dosya_gezgini/data/models/file_operation_models.dart';
import 'package:dosya_gezgini/data/models/hidden_item_model.dart';
import 'package:dosya_gezgini/data/models/saved_item_model.dart';
import 'package:dosya_gezgini/data/repositories/hidden_repository.dart';
import 'package:dosya_gezgini/data/repositories/saved_repository.dart';
import 'package:dosya_gezgini/data/services/cleaning_service.dart';
import 'package:dosya_gezgini/data/services/file_index_service.dart';
import 'package:dosya_gezgini/data/services/file_metadata_service.dart';
import 'package:dosya_gezgini/data/services/file_operation_service.dart';
import 'package:dosya_gezgini/features/files/state/altislem_provider.dart';
import 'package:dosya_gezgini/features/files/state/folderleragaci.dart';
import 'package:dosya_gezgini/features/files/state/izinler.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:dosya_gezgini/l10n/generated/app_localizations.dart';
import 'package:path/path.dart' as path;
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

class Dosyaislemleri extends ChangeNotifier {
  static const Duration _minimumProgressOverlayDuration = Duration(
    milliseconds: 350,
  );
  static const int _postMutationProgressStageCount = 2;

  Dosyaislemleri({
    required SavedRepository savedRepository,
    required HiddenRepository hiddenRepository,
    required CleaningService cleaningService,
    required FileMetadataService fileMetadataService,
    required FileOperationService fileOperationService,
    required FileIndexService fileIndexService,
  }) : _savedRepository = savedRepository,
       _hiddenRepository = hiddenRepository,
       _cleaningService = cleaningService,
       _fileMetadataService = fileMetadataService,
       _fileOperationService = fileOperationService,
       _fileIndexService = fileIndexService;

  final SavedRepository _savedRepository;
  final HiddenRepository _hiddenRepository;
  final CleaningService _cleaningService;
  final FileMetadataService _fileMetadataService;
  final FileOperationService _fileOperationService;
  final FileIndexService _fileIndexService;

  final List<FolderNode> folderlistesi = <FolderNode>[];
  final List<File> filelistesi = <File>[];
  final List<FolderNode> kopyalananfolder = <FolderNode>[];
  final List<File> kopyalananfile = <File>[];
  final List<FileSystemEntity> gereksizdosyalar = <FileSystemEntity>[];

  int gereksizdosyalartoplamboyutu = 0;
  bool loading = false;
  bool aramaloading = false;
  bool gecicidosyalaralinmasi = false;
  bool onbellekdosyalarialinmasi = false;
  FolderNode? guncelparent;

  ClipboardOperation? _clipboardOperation;
  FileOperationType? _activeOperationType;
  FileOperationProgress? _activeOperationProgress;
  String? _activeOperationTitle;
  CleaningScanProgress? _cleanupScanProgress;
  CleaningScanResult? _cleanupScanResult;
  CleaningDeleteProgress? _cleanupDeleteProgress;
  CleaningDeleteResult? _cleanupDeleteResult;
  Object? _cleanupError;
  bool _isCleanupScanning = false;
  bool _isCleanupDeleting = false;
  bool _cleanupStopRequested = false;
  bool _cleanupWasStopped = false;

  bool get hasSelectedFiles => filelistesi.isNotEmpty;
  bool get hasClipboardContent =>
      kopyalananfolder.isNotEmpty || kopyalananfile.isNotEmpty;
  bool get hasActiveOperation => _activeOperationType != null;
  FileOperationProgress? get activeOperationProgress =>
      _activeOperationProgress;
  String? get activeOperationTitle => _activeOperationTitle;
  CleaningScanProgress? get cleanupScanProgress => _cleanupScanProgress;
  CleaningScanResult? get cleanupScanResult => _cleanupScanResult;
  CleaningDeleteProgress? get cleanupDeleteProgress => _cleanupDeleteProgress;
  CleaningDeleteResult? get cleanupDeleteResult => _cleanupDeleteResult;
  Object? get cleanupError => _cleanupError;
  bool get isCleanupScanning => _isCleanupScanning;
  bool get isCleanupDeleting => _isCleanupDeleting;
  bool get cleanupStopRequested => _cleanupStopRequested;
  bool get cleanupWasStopped => _cleanupWasStopped;
  bool get hasCleanupCandidates =>
      (_cleanupScanResult?.candidates.length ?? 0) > 0;
  bool get hasCleanupResult => _cleanupDeleteResult != null;
  int get cleanupCandidateCount => _cleanupScanResult?.candidates.length ?? 0;
  int get cleanupCandidateBytes => _cleanupScanResult?.totalBytes ?? 0;
  List<CleaningIssue> get cleanupIssues => <CleaningIssue>[
    ...?_cleanupScanResult?.issues,
    ...?_cleanupDeleteResult?.issues,
  ];

  bool isFolderSelected(FolderNode folder) {
    return folderlistesi.any((item) => item.path == folder.path);
  }

  bool isFileSelected(File file) {
    return filelistesi.any((item) => item.path == file.path);
  }

  void toggleFolderSelection(FolderNode folder) {
    if (isFolderSelected(folder)) {
      folderlistesi.removeWhere((item) => item.path == folder.path);
    } else {
      folderlistesi.add(folder);
    }
    notifyListeners();
  }

  void toggleFileSelection(File file) {
    if (isFileSelected(file)) {
      filelistesi.removeWhere((item) => item.path == file.path);
    } else {
      filelistesi.add(file);
    }
    notifyListeners();
  }

  void clearSelection({bool notify = true}) {
    final hadSelection = folderlistesi.isNotEmpty || filelistesi.isNotEmpty;
    folderlistesi.clear();
    filelistesi.clear();
    if (notify && hadSelection) {
      notifyListeners();
    }
  }

  List<FolderNode>? getfolders() {
    if (folderlistesi.isEmpty) {
      return null;
    }

    return folderlistesi;
  }

  List<File>? getfiles() {
    if (filelistesi.isEmpty) {
      return null;
    }

    return filelistesi;
  }

  Future<void> temizlenecekleritoplamaislemi([BuildContext? _]) async {
    await startCleanupScan();
  }

  Future<void> gereksizdosyalaritemizle() async {
    await startCleanupDelete();
  }

  Future<void> startCleanupScan() async {
    if (_isCleanupScanning || _isCleanupDeleting) {
      return;
    }

    _isCleanupScanning = true;
    _cleanupStopRequested = false;
    _cleanupWasStopped = false;
    _cleanupError = null;
    _cleanupScanProgress = null;
    _cleanupScanResult = null;
    _cleanupDeleteProgress = null;
    _cleanupDeleteResult = null;
    gereksizdosyalar.clear();
    gereksizdosyalartoplamboyutu = 0;
    loading = true;
    aramaloading = false;
    gecicidosyalaralinmasi = false;
    onbellekdosyalarialinmasi = false;
    notifyListeners();

    try {
      final result = await _cleaningService.scan(
        onProgress: (progress) {
          _cleanupScanProgress = progress;
          loading = true;
          gecicidosyalaralinmasi = progress.completedSourceCount >= 4;
          onbellekdosyalarialinmasi = progress.completedSourceCount >= 1;
          notifyListeners();
        },
        shouldCancel: () => _cleanupStopRequested,
      );

      _cleanupScanResult = result;
      _syncCleanupCandidates(result.candidates);
      gecicidosyalaralinmasi = true;
      onbellekdosyalarialinmasi = true;
      aramaloading = result.hasCandidates;
    } on CleaningCancelledException {
      _cleanupWasStopped = true;
      aramaloading = false;
    } catch (error) {
      _cleanupError = error;
      aramaloading = false;
    } finally {
      loading = false;
      _isCleanupScanning = false;
      _cleanupStopRequested = false;
      notifyListeners();
    }
  }

  Future<void> startCleanupDelete() async {
    if (_isCleanupScanning || _isCleanupDeleting) {
      return;
    }

    final currentScanResult = _cleanupScanResult;
    if (currentScanResult == null || currentScanResult.candidates.isEmpty) {
      return;
    }

    _isCleanupDeleting = true;
    _cleanupStopRequested = false;
    _cleanupWasStopped = false;
    _cleanupError = null;
    _cleanupDeleteProgress = CleaningDeleteProgress(
      processedItems: 0,
      totalItems: currentScanResult.candidates.length,
      deletedCount: 0,
      failedCount: 0,
      deletedBytes: 0,
    );
    loading = true;
    notifyListeners();

    try {
      final result = await _cleaningService.deleteCandidates(
        currentScanResult.candidates,
        onProgress: (progress) {
          _cleanupDeleteProgress = progress;
          loading = true;
          notifyListeners();
        },
      );

      _cleanupDeleteResult = result;
      final resolvedPaths = <String>{
        ...result.deletedPaths,
        ...result.issues
            .where((issue) => issue.message == 'source_not_found')
            .map((issue) => issue.path),
      };
      final remainingCandidates = currentScanResult.candidates
          .where((candidate) => !resolvedPaths.contains(candidate.path))
          .toList(growable: false);

      _cleanupScanResult = CleaningScanResult(
        candidates: remainingCandidates,
        totalBytes: remainingCandidates.fold<int>(
          0,
          (sum, candidate) => sum + candidate.sizeBytes,
        ),
        processedFiles: currentScanResult.processedFiles,
        issues: currentScanResult.issues,
        sourceSummaries: currentScanResult.sourceSummaries,
      );
      _syncCleanupCandidates(remainingCandidates);
      aramaloading = remainingCandidates.isNotEmpty;
    } catch (error) {
      _cleanupError = error;
    } finally {
      loading = false;
      _isCleanupDeleting = false;
      notifyListeners();
    }
  }

  void requestCleanupStop() {
    if (!_isCleanupScanning || _cleanupStopRequested) {
      return;
    }

    _cleanupStopRequested = true;
    notifyListeners();
  }

  void _syncCleanupCandidates(List<CleaningCandidate> candidates) {
    gereksizdosyalar
      ..clear()
      ..addAll(
        candidates.map<FileSystemEntity>((candidate) => File(candidate.path)),
      );
    gereksizdosyalartoplamboyutu = candidates.fold<int>(
      0,
      (sum, candidate) => sum + candidate.sizeBytes,
    );
  }

  /*
  Future<void> legacyTemizlenecekleritoplamaislemi(BuildContext context) async {
    var silinecekboyut = 0;
    loading = true;
    notifyListeners();
    debugPrint('başladı');

    final tempDir = await getTemporaryDirectory();
    final cacheDir = await getApplicationCacheDirectory();

    await Future<void>.delayed(const Duration(seconds: 5));
    gecicidosyalaralinmasi = true;
    notifyListeners();
    debugPrint('geçici dosyalar alındı');

    final tempFiles = tempDir.listSync(recursive: true);
    final cacheFiles = cacheDir.listSync(recursive: true);
    final allFiles = <FileSystemEntity>[...tempFiles, ...cacheFiles];

    final now = DateTime.now();
    const ageLimit = Duration(days: 30);
    const sizeLimit = 100 * 1024 * 1024;

    for (final file in allFiles) {
      if (file is! File) {
        continue;
      }

      try {
        final lastModified = await file.lastModified();
        final fileSize = await file.length();

        if (now.difference(lastModified) > ageLimit || fileSize > sizeLimit) {
          gereksizdosyalar.add(file);
          silinecekboyut += fileSize;
          debugPrint('listeye alındı: ${file.path}');
        }
      } catch (error) {
        debugPrint('Hata oluştu: $error');
      }
    }

    gereksizdosyalartoplamboyutu = silinecekboyut;
    await Future<void>.delayed(const Duration(seconds: 5));
    onbellekdosyalarialinmasi = true;
    notifyListeners();
    debugPrint('önbellek dosyaları alındı');

    await Future<void>.delayed(const Duration(seconds: 2));
    loading = false;
    aramaloading = true;
    notifyListeners();
    debugPrint('işlem bitti');
  }

  Future<void> gereksizdosyalaritemizle() async {
    loading = true;
    notifyListeners();
    for (final file in gereksizdosyalar) {
      try {
        await file.delete();
      } catch (error) {
        debugPrint('Hata oluştu: $error');
      }
    }
    await Future<void>.delayed(const Duration(seconds: 5));
    aramaloading = false;
    loading = false;
    gecicidosyalaralinmasi = false;
    onbellekdosyalarialinmasi = false;
    notifyListeners();
    await Future<void>.delayed(const Duration(seconds: 2));
  }

  */

  Future<void> sil(BuildContext context) async {
    final entries = _selectedEntries;
    if (entries.isEmpty) {
      return;
    }

    final l10n = context.l10n;
    final theme = Theme.of(context);
    final izinler = context.read<Izinler>();
    final altIslemProvider = context.read<Altislemprovider>();
    final totalProgressItems = _resolveLifecycleProgressTotal(entries.length);
    var completedOperationItems = 0;

    final result = await _runOperationWithProgress<FileOperationResult>(
      context: context,
      title: l10n.operationDeletingProgress,
      operationType: FileOperationType.delete,
      totalItems: totalProgressItems,
      showProgress: true,
      task: () async {
        final result = await _fileOperationService.deleteEntries(
          entries,
          onProgress: (progress) {
            completedOperationItems = progress.processedItems;
            _setOperationProgress(
              _bindProgressToLifecycleTotal(progress, totalProgressItems),
            );
          },
        );
        await _refreshAfterFilesystemMutation(
          izinler: izinler,
          l10n: l10n,
          operationType: FileOperationType.delete,
          completedItems: completedOperationItems,
          totalItems: totalProgressItems,
          persistentPathsToRemove: result.removedPaths.toSet(),
          metadataDeletePaths: result.removedPaths.toSet(),
        );
        return result;
      },
    );

    if (result.cancelled) {
      return;
    }
    clearSelection(notify: false);
    altIslemProvider.setSelectionMode(false);
    notifyListeners();

    _showToast(
      message: _resolveResultMessage(
        l10n: l10n,
        result: result,
        successMessage: l10n.deleteSuccess,
        fallbackMessage: l10n.errorOccurred,
      ),
      theme: theme,
    );
    await _refreshVisibleContentAfterToast(izinler: izinler);
  }

  Future<void> dosyalaripaylas() async {
    final paylasilacakdosyalar = <XFile>[];
    for (final file in filelistesi) {
      if (!await file.exists()) {
        continue;
      }
      paylasilacakdosyalar.add(XFile(file.path));
    }

    if (paylasilacakdosyalar.isEmpty) {
      return;
    }

    await Share.shareXFiles(paylasilacakdosyalar);
  }

  void kopyala(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final altIslemProvider = context.read<Altislemprovider>();

    _syncClipboardFromSelection(mode: ClipboardOperation.copy);
    clearSelection(notify: false);
    altIslemProvider.setSelectionMode(false);
    notifyListeners();

    _showToast(message: l10n.copied, theme: theme);
  }

  Future<void> kes(BuildContext context) async {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final altIslemProvider = context.read<Altislemprovider>();

    _syncClipboardFromSelection(mode: ClipboardOperation.cut);
    clearSelection(notify: false);
    altIslemProvider.setSelectionMode(false);
    notifyListeners();

    _showToast(message: l10n.cutReady, theme: theme);
  }

  Future<void> klasorekle(
    FolderNode _,
    BuildContext context,
    String klasoradi,
  ) async {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final izinler = context.read<Izinler>();
    final targetDirectoryPath = _resolveWritableDirectoryPath(izinler);
    if (targetDirectoryPath == null) {
      _showToast(message: l10n.errorOccurred, theme: theme);
      return;
    }

    final totalProgressItems = _resolveLifecycleProgressTotal(1);

    final result = await _runOperationWithProgress<FileCreateResult>(
      context: context,
      title: l10n.operationCreatingFolderProgress,
      operationType: FileOperationType.createFolder,
      totalItems: totalProgressItems,
      showProgress: true,
      task: () async {
        final targetPath = path.join(targetDirectoryPath, klasoradi.trim());
        _setOperationProgress(
          FileOperationProgress(
            operationType: FileOperationType.createFolder,
            processedItems: 0,
            totalItems: totalProgressItems,
            currentPath: targetPath,
          ),
        );
        final result = await _fileOperationService.createFolder(
          parentDirectoryPath: targetDirectoryPath,
          folderName: klasoradi,
        );
        _setOperationProgress(
          FileOperationProgress(
            operationType: FileOperationType.createFolder,
            processedItems: 1,
            totalItems: totalProgressItems,
            currentPath: result.createdPath ?? targetPath,
          ),
        );
        if (result.isSuccess) {
          await _refreshAfterFilesystemMutation(
            izinler: izinler,
            l10n: l10n,
            operationType: FileOperationType.createFolder,
            completedItems: 1,
            totalItems: totalProgressItems,
          );
        }
        return result;
      },
    );

    if (!result.isSuccess) {
      _showToast(
        message: _messageForErrorCode(l10n, result.errorCode),
        theme: theme,
      );
      return;
    }
    _showToast(message: l10n.newFolderCreated, theme: theme);
    await _refreshVisibleContentAfterToast(izinler: izinler);
  }

  Future<void> fileekle(File file, BuildContext context) async {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final izinler = context.read<Izinler>();
    final targetDirectoryPath = _resolveWritableDirectoryPath(izinler);
    if (targetDirectoryPath == null) {
      _showToast(message: l10n.errorOccurred, theme: theme);
      return;
    }

    final totalProgressItems = _resolveLifecycleProgressTotal(1);
    var completedOperationItems = 0;

    final result = await _runOperationWithProgress<FileOperationResult>(
      context: context,
      title: l10n.operationCopyingProgress,
      operationType: FileOperationType.copy,
      totalItems: totalProgressItems,
      showProgress: true,
      task: () async {
        final result = await _fileOperationService.pasteEntries(
          entries: <FileOperationEntry>[
            FileOperationEntry(path: file.path, isDirectory: false),
          ],
          mode: ClipboardOperation.copy,
          destinationDirectoryPath: targetDirectoryPath,
          onConflict: (request) => _resolveConflict(context, request),
          onProgress: (progress) {
            completedOperationItems = progress.processedItems;
            _setOperationProgress(
              _bindProgressToLifecycleTotal(progress, totalProgressItems),
            );
          },
        );
        if (result.hasChanges) {
          await _refreshAfterFilesystemMutation(
            izinler: izinler,
            l10n: l10n,
            operationType: FileOperationType.copy,
            completedItems: completedOperationItems,
            totalItems: totalProgressItems,
            persistentPathsToRemove: result.removedPaths.toSet(),
            metadataDeletePaths: result.removedPaths.toSet(),
            metadataRefreshPaths: result.createdPaths.toSet(),
          );
        }
        return result;
      },
    );

    if (!result.hasChanges) {
      _showToast(
        message: _resolveResultMessage(
          l10n: l10n,
          result: result,
          successMessage: l10n.newFileAdded,
          fallbackMessage: l10n.errorOccurred,
        ),
        theme: theme,
      );
      return;
    }
    _showToast(message: l10n.newFileAdded, theme: theme);
    await _refreshVisibleContentAfterToast(izinler: izinler);
  }

  Future<void> adlandir(
    String oldPath,
    String newName,
    BuildContext context,
  ) async {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final izinler = context.read<Izinler>();

    final result = await _runOperationWithProgress<FileRenameResult>(
      context: context,
      title: l10n.operationRenamingProgress,
      operationType: FileOperationType.rename,
      totalItems: _resolveLifecycleProgressTotal(1),
      showProgress: true,
      task: () async {
        final totalProgressItems = _resolveLifecycleProgressTotal(1);
        _setOperationProgress(
          FileOperationProgress(
            operationType: FileOperationType.rename,
            processedItems: 0,
            totalItems: totalProgressItems,
            currentPath: oldPath,
          ),
        );
        final result = await _fileOperationService.renameEntry(
          sourcePath: oldPath,
          newName: newName,
        );
        _setOperationProgress(
          FileOperationProgress(
            operationType: FileOperationType.rename,
            processedItems: 1,
            totalItems: totalProgressItems,
            currentPath: result.newPath ?? oldPath,
          ),
        );
        if (result.isSuccess) {
          await _refreshAfterFilesystemMutation(
            izinler: izinler,
            l10n: l10n,
            operationType: FileOperationType.rename,
            completedItems: 1,
            totalItems: totalProgressItems,
            metadataDeletePaths:
                result.isDirectory ? const <String>{} : <String>{oldPath},
            metadataRefreshPaths:
                result.isDirectory || result.newPath == null
                    ? const <String>{}
                    : <String>{result.newPath!},
          );
        }
        return result;
      },
    );

    if (!result.isSuccess || result.newPath == null) {
      _showToast(
        message: _messageForErrorCode(l10n, result.errorCode),
        theme: theme,
      );
      return;
    }

    _syncSelectionAfterRename(
      oldPath: oldPath,
      newPath: result.newPath!,
      isDirectory: result.isDirectory,
    );
    _syncClipboardAfterRename(
      oldPath: oldPath,
      newPath: result.newPath!,
      isDirectory: result.isDirectory,
    );
    notifyListeners();

    _showToast(message: l10n.renameSuccess, theme: theme);
    await _refreshVisibleContentAfterToast(izinler: izinler);
  }

  Future<void> kaydet(BuildContext context) async {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final izinler = context.read<Izinler>();
    final altIslemProvider = context.read<Altislemprovider>();

    try {
      final now = DateTime.now();
      await _savedRepository.upsertAll(<SavedItemModel>[
        for (final folder in folderlistesi)
          SavedItemModel(path: folder.path, isDirectory: true, updatedAt: now),
        for (final file in filelistesi)
          SavedItemModel(path: file.path, isDirectory: false, updatedAt: now),
      ]);
      await izinler.syncSavedEntries();
    } catch (error) {
      debugPrint('kaydetme hatası: $error');
      _showToast(message: l10n.errorOccurred, theme: theme);
      return;
    }

    clearSelection(notify: false);
    altIslemProvider.setSelectionMode(false);
    notifyListeners();
    _showToast(message: l10n.savedSuccess, theme: theme);
  }

  Future<void> sakla(BuildContext context) async {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final izinler = context.read<Izinler>();
    final altIslemProvider = context.read<Altislemprovider>();

    try {
      final now = DateTime.now();
      await _hiddenRepository.upsertAll(<HiddenItemModel>[
        for (final folder in folderlistesi)
          HiddenItemModel(path: folder.path, isDirectory: true, updatedAt: now),
        for (final file in filelistesi)
          HiddenItemModel(path: file.path, isDirectory: false, updatedAt: now),
      ]);
      await izinler.syncHiddenEntries();
      await izinler.refreshRootEntries();
      final currentFolder = izinler.currentFolder;
      if (currentFolder != null && !currentFolder.isVirtual) {
        await izinler.fileTree.loadFolder(currentFolder, forceRefresh: true);
        izinler.setVisibleFolder(currentFolder);
      }
    } catch (error) {
      debugPrint('Gizleme hatası: $error');
      _showToast(message: l10n.errorOccurred, theme: theme);
      return;
    }

    clearSelection(notify: false);
    altIslemProvider.setSelectionMode(false);
    notifyListeners();
    _showToast(message: l10n.hiddenSuccess, theme: theme);
  }

  Future<void> yapistir(BuildContext context) async {
    final entries = _clipboardEntries;
    final mode = _clipboardOperation;
    if (entries.isEmpty || mode == null) {
      return;
    }

    final l10n = context.l10n;
    final theme = Theme.of(context);
    final izinler = context.read<Izinler>();
    final targetDirectoryPath = _resolveWritableDirectoryPath(izinler);
    if (targetDirectoryPath == null) {
      _showToast(message: l10n.errorOccurred, theme: theme);
      return;
    }

    final totalProgressItems = _resolveLifecycleProgressTotal(entries.length);
    var completedOperationItems = 0;

    final result = await _runOperationWithProgress<FileOperationResult>(
      context: context,
      title:
          mode == ClipboardOperation.cut
              ? l10n.operationMovingProgress
              : l10n.operationCopyingProgress,
      operationType:
          mode == ClipboardOperation.cut
              ? FileOperationType.move
              : FileOperationType.copy,
      totalItems: totalProgressItems,
      showProgress: true,
      task: () async {
        final result = await _fileOperationService.pasteEntries(
          entries: entries,
          mode: mode,
          destinationDirectoryPath: targetDirectoryPath,
          onConflict: (request) => _resolveConflict(context, request),
          onProgress: (progress) {
            completedOperationItems = progress.processedItems;
            _setOperationProgress(
              _bindProgressToLifecycleTotal(progress, totalProgressItems),
            );
          },
        );
        if (!result.cancelled) {
          await _refreshAfterFilesystemMutation(
            izinler: izinler,
            l10n: l10n,
            operationType:
                mode == ClipboardOperation.cut
                    ? FileOperationType.move
                    : FileOperationType.copy,
            completedItems: completedOperationItems,
            totalItems: totalProgressItems,
            persistentPathsToRemove: result.removedPaths.toSet(),
            metadataDeletePaths: result.removedPaths.toSet(),
            metadataRefreshPaths: result.createdPaths.toSet(),
          );
        }
        return result;
      },
    );

    if (result.cancelled) {
      return;
    }

    if (mode == ClipboardOperation.cut) {
      _removeClipboardPaths(result.removedPaths.toSet());
      if (!hasClipboardContent) {
        _clipboardOperation = null;
      }
    }
    notifyListeners();

    _showToast(
      message: _resolveResultMessage(
        l10n: l10n,
        result: result,
        successMessage: l10n.pasteSuccess,
        fallbackMessage: l10n.errorOccurred,
      ),
      theme: theme,
    );
    await _refreshVisibleContentAfterToast(izinler: izinler);
  }

  List<FileOperationEntry> get _selectedEntries {
    return <FileOperationEntry>[
      for (final folder in folderlistesi)
        FileOperationEntry(path: folder.path, isDirectory: true),
      for (final file in filelistesi)
        FileOperationEntry(path: file.path, isDirectory: false),
    ];
  }

  List<FileOperationEntry> get _clipboardEntries {
    return <FileOperationEntry>[
      for (final folder in kopyalananfolder)
        FileOperationEntry(path: folder.path, isDirectory: true),
      for (final file in kopyalananfile)
        FileOperationEntry(path: file.path, isDirectory: false),
    ];
  }

  void _syncClipboardFromSelection({required ClipboardOperation mode}) {
    kopyalananfolder
      ..clear()
      ..addAll(folderlistesi);
    kopyalananfile
      ..clear()
      ..addAll(filelistesi);
    _clipboardOperation = mode;
  }

  void _removeClipboardPaths(Set<String> movedPaths) {
    if (movedPaths.isEmpty) {
      return;
    }

    kopyalananfolder.removeWhere((item) => movedPaths.contains(item.path));
    kopyalananfile.removeWhere((item) => movedPaths.contains(item.path));
  }

  void _syncSelectionAfterRename({
    required String oldPath,
    required String newPath,
    required bool isDirectory,
  }) {
    if (isDirectory) {
      for (final folder in folderlistesi) {
        if (folder.path == oldPath) {
          folder.path = newPath;
          folder.name = path.basename(newPath);
        }
      }
      return;
    }

    for (var index = 0; index < filelistesi.length; index++) {
      if (filelistesi[index].path == oldPath) {
        filelistesi[index] = File(newPath);
      }
    }
  }

  void _syncClipboardAfterRename({
    required String oldPath,
    required String newPath,
    required bool isDirectory,
  }) {
    if (isDirectory) {
      for (final folder in kopyalananfolder) {
        if (folder.path == oldPath) {
          folder.path = newPath;
          folder.name = path.basename(newPath);
        }
      }
      return;
    }

    for (var index = 0; index < kopyalananfile.length; index++) {
      if (kopyalananfile[index].path == oldPath) {
        kopyalananfile[index] = File(newPath);
      }
    }
  }

  String? _resolveWritableDirectoryPath(Izinler izinler) {
    final currentFolder = izinler.currentFolder;
    if (currentFolder == null) {
      return izinler.fileTree.root.path;
    }

    if (currentFolder.isVirtual) {
      return null;
    }

    return currentFolder.path;
  }

  int _resolveLifecycleProgressTotal(int operationItems) {
    return operationItems + _postMutationProgressStageCount;
  }

  FileOperationProgress _bindProgressToLifecycleTotal(
    FileOperationProgress progress,
    int totalItems,
  ) {
    return progress.copyWith(totalItems: totalItems);
  }

  Future<void> _refreshAfterFilesystemMutation({
    required Izinler izinler,
    required AppLocalizations l10n,
    required FileOperationType operationType,
    required int completedItems,
    required int totalItems,
    Set<String> persistentPathsToRemove = const <String>{},
    Set<String> metadataDeletePaths = const <String>{},
    Set<String> metadataRefreshPaths = const <String>{},
  }) async {
    var stageCompletedItems = completedItems;

    stageCompletedItems = await _runProgressStage(
      operationType: operationType,
      completedItems: stageCompletedItems,
      totalItems: totalItems,
      statusLabel: l10n.operationSyncingRecordsProgress,
      action: () async {
        if (persistentPathsToRemove.isNotEmpty) {
          await izinler.removePathsFromPersistentCollections(
            persistentPathsToRemove,
          );
        }
        if (metadataDeletePaths.isNotEmpty) {
          await _fileMetadataService.deleteMetadataForPaths(
            metadataDeletePaths,
          );
        }
        if (metadataRefreshPaths.isNotEmpty) {
          await _fileMetadataService.refreshMetadataForPaths(
            metadataRefreshPaths,
          );
        }
      },
    );

    await _runProgressStage(
      operationType: operationType,
      completedItems: stageCompletedItems,
      totalItems: totalItems,
      currentPath: izinler.fileTree.rootPath,
      statusLabel: l10n.operationRefreshingIndexProgress,
      action:
          () => _fileIndexService.refreshIndex(
            rootPath: izinler.fileTree.rootPath,
          ),
    );
  }

  Future<void> _refreshVisibleContentAfterToast({
    required Izinler izinler,
  }) async {
    await WidgetsBinding.instance.endOfFrame;
    await izinler.refreshRootEntries();

    final currentFolder = izinler.currentFolder;
    if (currentFolder != null && !currentFolder.isVirtual) {
      await izinler.fileTree.loadFolder(currentFolder, forceRefresh: true);
      izinler.setVisibleFolder(currentFolder);
    }
  }

  Future<int> _runProgressStage({
    required FileOperationType operationType,
    required int completedItems,
    required int totalItems,
    required String statusLabel,
    String? currentPath,
    required Future<void> Function() action,
  }) async {
    _setOperationProgress(
      FileOperationProgress(
        operationType: operationType,
        processedItems: completedItems,
        totalItems: totalItems,
        currentPath: currentPath,
        statusLabel: statusLabel,
      ),
    );
    await action();
    final nextCompletedItems = completedItems + 1;
    _setOperationProgress(
      FileOperationProgress(
        operationType: operationType,
        processedItems: nextCompletedItems,
        totalItems: totalItems,
        currentPath: currentPath,
        statusLabel: statusLabel,
      ),
    );
    return nextCompletedItems;
  }

  Future<T> _runOperationWithProgress<T>({
    required BuildContext context,
    required String title,
    required FileOperationType operationType,
    required int totalItems,
    required bool showProgress,
    required Future<T> Function() task,
  }) async {
    _activeOperationType = operationType;
    _activeOperationTitle = title;
    _activeOperationProgress = FileOperationProgress(
      operationType: operationType,
      processedItems: 0,
      totalItems: totalItems,
    );
    notifyListeners();

    final navigator =
        showProgress ? Navigator.of(context, rootNavigator: true) : null;
    var overlayVisible = false;
    Future<void>? overlayFuture;
    Stopwatch? overlayStopwatch;

    if (showProgress) {
      overlayStopwatch = Stopwatch()..start();
      overlayVisible = true;
      overlayFuture = showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => _FileOperationProgressDialog(owner: this),
      ).whenComplete(() {
        overlayVisible = false;
      });
      await WidgetsBinding.instance.endOfFrame;
    }

    try {
      return await task();
    } finally {
      _activeOperationType = null;
      _activeOperationTitle = null;
      _activeOperationProgress = null;
      notifyListeners();

      if (overlayVisible && navigator != null && navigator.mounted) {
        final elapsed = overlayStopwatch?.elapsed ?? Duration.zero;
        final remaining = _minimumProgressOverlayDuration - elapsed;
        if (remaining > Duration.zero) {
          await Future<void>.delayed(remaining);
        }
        navigator.pop();
        await overlayFuture;
      }
    }
  }

  void _setOperationProgress(FileOperationProgress progress) {
    _activeOperationProgress = progress;
    notifyListeners();
  }

  Future<FileConflictResolution> _resolveConflict(
    BuildContext context,
    FileConflictRequest request,
  ) async {
    if (!context.mounted) {
      return FileConflictResolution.cancel;
    }

    final result = await showModalBottomSheet<FileConflictResolution>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder:
          (sheetContext) => SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    sheetContext.l10n.nameConflictTitle,
                    style: Theme.of(sheetContext).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    sheetContext.l10n.nameConflictMessage(
                      request.destinationName,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(sheetContext.l10n.overwrite),
                    onTap:
                        () => Navigator.of(
                          sheetContext,
                        ).pop(FileConflictResolution.overwrite),
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(sheetContext.l10n.copyWithNewName),
                    onTap:
                        () => Navigator.of(
                          sheetContext,
                        ).pop(FileConflictResolution.createUniqueName),
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(sheetContext.l10n.skip),
                    onTap:
                        () => Navigator.of(
                          sheetContext,
                        ).pop(FileConflictResolution.skip),
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(sheetContext.l10n.cancel),
                    onTap:
                        () => Navigator.of(
                          sheetContext,
                        ).pop(FileConflictResolution.cancel),
                  ),
                ],
              ),
            ),
          ),
    );

    return result ?? FileConflictResolution.cancel;
  }

  String _resolveResultMessage({
    required AppLocalizations l10n,
    required FileOperationResult result,
    required String successMessage,
    required String fallbackMessage,
  }) {
    if (result.hasChanges) {
      return successMessage;
    }

    if (result.failures.isNotEmpty) {
      return _messageForErrorCode(l10n, result.failures.first.errorCode);
    }

    return fallbackMessage;
  }

  String _messageForErrorCode(AppLocalizations l10n, String? errorCode) {
    switch (errorCode) {
      case FileOperationErrorCodes.accessDenied:
        return l10n.fileAccessPermissionDenied;
      case FileOperationErrorCodes.invalidPath:
        return l10n.fileAccessInvalidPath;
      case FileOperationErrorCodes.invalidName:
        return l10n.invalidName;
      case FileOperationErrorCodes.alreadyExists:
      case FileOperationErrorCodes.conflict:
        return l10n.itemAlreadyExists;
      case FileOperationErrorCodes.parentNotFound:
        return l10n.targetFolderNotFound;
      case FileOperationErrorCodes.sourceNotFound:
        return l10n.fileAccessDeleted;
      case FileOperationErrorCodes.destinationInSource:
        return l10n.destinationInsideSource;
      case FileOperationErrorCodes.insufficientSpace:
        return l10n.insufficientStorageSpace;
      case FileOperationErrorCodes.symbolicLinkUnsupported:
        return l10n.fileAccessSymbolicLinkUnsupported;
      case FileOperationErrorCodes.rolledBack:
        return l10n.operationRolledBack;
      case FileOperationErrorCodes.rollbackFailed:
        return l10n.operationRollbackFailed;
      default:
        return l10n.errorOccurred;
    }
  }

  void _showToast({required String message, required ThemeData theme}) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.TOP,
      timeInSecForIosWeb: 10,
      backgroundColor: theme.secondaryHeaderColor,
      textColor: theme.textTheme.labelLarge?.color,
      fontSize: 16,
    );
  }
}

class _FileOperationProgressDialog extends StatelessWidget {
  const _FileOperationProgressDialog({required this.owner});

  final Dosyaislemleri owner;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return PopScope(
      canPop: false,
      child: Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: Card(
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: ListenableBuilder(
              listenable: owner,
              builder: (context, _) {
                final progress = owner.activeOperationProgress;
                final statusLabel = progress?.statusLabel;
                final currentLabel =
                    progress?.currentPath == null
                        ? null
                        : path.basename(progress!.currentPath!);

                return Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      owner.activeOperationTitle ??
                          context.l10n.operationCompleted,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 16),
                    LinearProgressIndicator(
                      value: progress?.progress,
                      minHeight: 8,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '${progress?.processedItems ?? 0}/${progress?.totalItems ?? 0}',
                      style: theme.textTheme.bodyMedium,
                    ),
                    if (statusLabel != null && statusLabel.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        statusLabel,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyMedium,
                      ),
                    ],
                    if (currentLabel != null && currentLabel.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        currentLabel,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
