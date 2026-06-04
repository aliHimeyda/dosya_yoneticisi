import 'dart:async';
import 'dart:io';

import 'package:dosya_gezgini/core/localization/l10n_extensions.dart';
import 'package:dosya_gezgini/data/models/file_operation_models.dart';
import 'package:dosya_gezgini/data/models/hidden_item_model.dart';
import 'package:dosya_gezgini/data/models/saved_item_model.dart';
import 'package:dosya_gezgini/data/repositories/hidden_repository.dart';
import 'package:dosya_gezgini/data/repositories/saved_repository.dart';
import 'package:dosya_gezgini/data/services/file_index_service.dart';
import 'package:dosya_gezgini/data/services/file_operation_service.dart';
import 'package:dosya_gezgini/features/files/state/altislem_provider.dart';
import 'package:dosya_gezgini/features/files/state/folderleragaci.dart';
import 'package:dosya_gezgini/features/files/state/izinler.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:dosya_gezgini/l10n/generated/app_localizations.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

class Dosyaislemleri extends ChangeNotifier {
  Dosyaislemleri({
    required SavedRepository savedRepository,
    required HiddenRepository hiddenRepository,
    required FileOperationService fileOperationService,
    required FileIndexService fileIndexService,
  }) : _savedRepository = savedRepository,
       _hiddenRepository = hiddenRepository,
       _fileOperationService = fileOperationService,
       _fileIndexService = fileIndexService;

  final SavedRepository _savedRepository;
  final HiddenRepository _hiddenRepository;
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

  bool get hasSelectedFiles => filelistesi.isNotEmpty;
  bool get hasClipboardContent =>
      kopyalananfolder.isNotEmpty || kopyalananfile.isNotEmpty;
  bool get hasActiveOperation => _activeOperationType != null;
  FileOperationProgress? get activeOperationProgress =>
      _activeOperationProgress;
  String? get activeOperationTitle => _activeOperationTitle;

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

  Future<void> temizlenecekleritoplamaislemi(BuildContext context) async {
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

  Future<void> sil(BuildContext context) async {
    final entries = _selectedEntries;
    if (entries.isEmpty) {
      return;
    }

    final l10n = context.l10n;
    final theme = Theme.of(context);
    final izinler = context.read<Izinler>();
    final altIslemProvider = context.read<Altislemprovider>();

    final result = await _runOperationWithProgress<FileOperationResult>(
      context: context,
      title: l10n.operationDeleting,
      operationType: FileOperationType.delete,
      totalItems: entries.length,
      showProgress: _shouldShowProgress(entries),
      task:
          () => _fileOperationService.deleteEntries(
            entries,
            onProgress: _setOperationProgress,
          ),
    );

    if (result.cancelled) {
      return;
    }

    await _refreshAfterFilesystemMutation(
      izinler: izinler,
      removedPaths: result.removedPaths.toSet(),
    );
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

    final result = await _fileOperationService.createFolder(
      parentDirectoryPath: targetDirectoryPath,
      folderName: klasoradi,
    );

    if (!result.isSuccess) {
      _showToast(
        message: _messageForErrorCode(l10n, result.errorCode),
        theme: theme,
      );
      return;
    }

    await _refreshAfterFilesystemMutation(izinler: izinler);
    _showToast(message: l10n.newFolderCreated, theme: theme);
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

    final result = await _runOperationWithProgress<FileOperationResult>(
      context: context,
      title: l10n.operationCopying,
      operationType: FileOperationType.copy,
      totalItems: 1,
      showProgress: false,
      task:
          () => _fileOperationService.pasteEntries(
            entries: <FileOperationEntry>[
              FileOperationEntry(path: file.path, isDirectory: false),
            ],
            mode: ClipboardOperation.copy,
            destinationDirectoryPath: targetDirectoryPath,
            onConflict: (request) => _resolveConflict(context, request),
            onProgress: _setOperationProgress,
          ),
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

    await _refreshAfterFilesystemMutation(
      izinler: izinler,
      removedPaths: result.removedPaths.toSet(),
    );
    _showToast(message: l10n.newFileAdded, theme: theme);
  }

  Future<void> adlandir(
    String oldPath,
    String newName,
    BuildContext context,
  ) async {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final izinler = context.read<Izinler>();

    final result = await _fileOperationService.renameEntry(
      sourcePath: oldPath,
      newName: newName,
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
    await _refreshAfterFilesystemMutation(izinler: izinler);
    notifyListeners();

    _showToast(message: l10n.renameSuccess, theme: theme);
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

    final result = await _runOperationWithProgress<FileOperationResult>(
      context: context,
      title:
          mode == ClipboardOperation.cut
              ? l10n.operationMoving
              : l10n.operationCopying,
      operationType:
          mode == ClipboardOperation.cut
              ? FileOperationType.move
              : FileOperationType.copy,
      totalItems: entries.length,
      showProgress: _shouldShowProgress(entries),
      task:
          () => _fileOperationService.pasteEntries(
            entries: entries,
            mode: mode,
            destinationDirectoryPath: targetDirectoryPath,
            onConflict: (request) => _resolveConflict(context, request),
            onProgress: _setOperationProgress,
          ),
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

    await _refreshAfterFilesystemMutation(
      izinler: izinler,
      removedPaths: result.removedPaths.toSet(),
    );
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

  Future<void> _refreshAfterFilesystemMutation({
    required Izinler izinler,
    Set<String> removedPaths = const <String>{},
  }) async {
    if (removedPaths.isNotEmpty) {
      await izinler.removePathsFromPersistentCollections(removedPaths);
    }

    await izinler.refreshRootEntries();

    final currentFolder = izinler.currentFolder;
    if (currentFolder != null && !currentFolder.isVirtual) {
      await izinler.fileTree.loadFolder(currentFolder, forceRefresh: true);
      izinler.setVisibleFolder(currentFolder);
    }

    unawaited(
      _fileIndexService.refreshIndex(rootPath: izinler.fileTree.rootPath),
    );
  }

  bool _shouldShowProgress(List<FileOperationEntry> entries) {
    return entries.length > 1 || entries.any((entry) => entry.isDirectory);
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

    if (showProgress) {
      overlayVisible = true;
      overlayFuture = showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => _FileOperationProgressDialog(owner: this),
      ).whenComplete(() {
        overlayVisible = false;
      });
      await Future<void>.delayed(Duration.zero);
    }

    try {
      return await task();
    } finally {
      _activeOperationType = null;
      _activeOperationTitle = null;
      _activeOperationProgress = null;
      notifyListeners();

      if (overlayVisible && navigator != null && navigator.mounted) {
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
      case FileOperationErrorCodes.invalidName:
        return l10n.invalidName;
      case FileOperationErrorCodes.alreadyExists:
      case FileOperationErrorCodes.conflict:
        return l10n.itemAlreadyExists;
      case FileOperationErrorCodes.insufficientSpace:
        return l10n.insufficientStorageSpace;
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
    return PopScope(
      canPop: false,
      child: AlertDialog(
        title: Text(
          owner.activeOperationTitle ?? context.l10n.operationCompleted,
        ),
        content: ListenableBuilder(
          listenable: owner,
          builder: (context, _) {
            final progress = owner.activeOperationProgress;
            final currentLabel =
                progress?.currentPath == null
                    ? null
                    : path.basename(progress!.currentPath!);

            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                LinearProgressIndicator(value: progress?.progress),
                const SizedBox(height: 12),
                Text(
                  '${progress?.processedItems ?? 0}/${progress?.totalItems ?? 0}',
                ),
                if (currentLabel != null && currentLabel.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    currentLabel,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}
