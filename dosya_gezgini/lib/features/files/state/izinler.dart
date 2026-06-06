import 'dart:io';

import 'package:dosya_gezgini/core/constants/storage_paths.dart';
import 'package:dosya_gezgini/data/models/file_sync_models.dart';
import 'package:dosya_gezgini/data/models/recent_item_model.dart';
import 'package:dosya_gezgini/data/repositories/directory_cache_repository.dart';
import 'package:dosya_gezgini/data/repositories/folder_count_repository.dart';
import 'package:dosya_gezgini/data/repositories/hidden_repository.dart';
import 'package:dosya_gezgini/data/repositories/recent_repository.dart';
import 'package:dosya_gezgini/data/repositories/saved_repository.dart';
import 'package:dosya_gezgini/data/services/file_access_service.dart';
import 'package:dosya_gezgini/data/services/file_metadata_service.dart';
import 'package:dosya_gezgini/data/services/file_sync_service.dart';
import 'package:dosya_gezgini/features/files/state/folderleragaci.dart';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path/path.dart' as pathinfo;
import 'package:shared_preferences/shared_preferences.dart';

class Izinler extends ChangeNotifier {
  Izinler({
    required DirectoryCacheRepository directoryCacheRepository,
    required FileAccessService fileAccessService,
    required FileMetadataService fileMetadataService,
    required FileSyncService fileSyncService,
    required FolderCountRepository folderCountRepository,
    required RecentRepository recentRepository,
    required SavedRepository savedRepository,
    required HiddenRepository hiddenRepository,
  }) : _recentRepository = recentRepository,
       _fileMetadataService = fileMetadataService,
       _fileSyncService = fileSyncService,
       _folderCountRepository = folderCountRepository,
       _savedRepository = savedRepository,
       _hiddenRepository = hiddenRepository,
       fileTree = FileTree(
         storageRootPath,
         directoryCacheRepository: directoryCacheRepository,
         fileAccessService: fileAccessService,
         fileMetadataService: fileMetadataService,
         folderCountRepository: folderCountRepository,
       ) {
    fileTree.addListener(notifyListeners);
  }

  final FolderCountRepository _folderCountRepository;
  final FileMetadataService _fileMetadataService;
  final RecentRepository _recentRepository;
  final SavedRepository _savedRepository;
  final HiddenRepository _hiddenRepository;
  final FileSyncService _fileSyncService;
  final FileTree fileTree;

  bool _izin = false;
  bool _izinDurumuHazir = false;
  List<String>? _currentFolderPath;
  FolderNode? _currentFolder;
  Object? _rootLoadError;

  final List<FolderNode> previousFolders = [];

  List<String>? get getcurrentFolderPath {
    if (_currentFolder == null) {
      _currentFolderPath = ['kok dizin'];
      return _currentFolderPath;
    }

    if (_currentFolder!.isVirtual) {
      _currentFolderPath = [_currentFolder!.name];
      return _currentFolderPath;
    }

    final segments = _currentFolder!.path.split('/');
    if (segments.length <= 4) {
      _currentFolderPath = ['kok dizin'];
      return _currentFolderPath;
    }

    _currentFolderPath = segments.sublist(4);
    return _currentFolderPath;
  }

  bool get hasStoragePermission => _izin;
  bool get isPermissionStateReady => _izinDurumuHazir;
  FolderNode? get currentFolder => _currentFolder;
  FolderNode? get getCurrentFolder => _currentFolder;
  Object? get rootLoadError => _rootLoadError;
  List<String> get currentFolderPathSegments =>
      List<String>.unmodifiable(getcurrentFolderPath ?? const ['kok dizin']);
  FolderFileEntries get rootEntries => FolderFileEntries(
    folders: List<FolderNode>.unmodifiable(fileTree.root.folderchildren),
    files: List<File>.unmodifiable(fileTree.root.filechildren),
  );
  FolderFileEntries get hiddenEntries => FolderFileEntries(
    folders: List<FolderNode>.unmodifiable(fileTree.gizlenenfolder),
    files: List<File>.unmodifiable(fileTree.gizlenenfile),
  );
  FolderFileEntries get savedEntries => FolderFileEntries(
    folders: List<FolderNode>.unmodifiable(fileTree.kaydedilenfolder),
    files: List<File>.unmodifiable(fileTree.kaydedilenfile),
  );
  FolderFileEntries get recentEntries => FolderFileEntries(
    folders: List<FolderNode>.unmodifiable(fileTree.ensongezilenfolders),
    files: List<File>.unmodifiable(fileTree.ensongezilenfiles),
  );

  void setVisibleFolder(FolderNode? folder) {
    if (identical(_currentFolder, folder)) {
      return;
    }

    _currentFolder = folder;
    notifyListeners();
  }

  void klasorekle(FolderNode folder) {
    _currentFolder!.folderchildren.add(folder);
    notifyListeners();
  }

  Future<void> setCurrentFolder(FolderNode folder) async {
    setVisibleFolder(folder);
    await fileTree.loadFolder(folder);
  }

  void rememberPreviousFolder(FolderNode folder) {
    if (previousFolders.any((item) => item.path == folder.path)) {
      return;
    }

    previousFolders.add(folder);
  }

  bool goBack() {
    if (previousFolders.isNotEmpty) {
      _currentFolder = previousFolders.removeLast();
      notifyListeners();
      return true;
    }

    return false;
  }

  Future<bool> get izin async {
    final pref = await SharedPreferences.getInstance();
    final izinverilmismi = pref.getBool('izinanahtari') ?? false;
    if (izinverilmismi) {
      _izin = true;
      _izinDurumuHazir = true;
      return _izin;
    }

    _izin = await Permission.manageExternalStorage.status.isGranted;
    _izinDurumuHazir = true;
    pref.setBool('izinanahtari', _izin);
    return _izin;
  }

  Future<void> setIzin(bool value) async {
    final pref = await SharedPreferences.getInstance();
    _izin = value;
    _izinDurumuHazir = true;
    pref.setBool('izinanahtari', _izin);
    notifyListeners();
  }

  Future<void> requestAllStoragePermission() async {
    final status = await Permission.manageExternalStorage.status;

    if (status.isGranted) {
      await setIzin(true);
      await synchronizePersistentCollections();
      final result = await fileTree.buildTree();
      _rootLoadError = result.error;
      notifyListeners();
      return;
    }

    final newStatus = await Permission.manageExternalStorage.request();

    if (newStatus.isGranted) {
      await setIzin(true);
      await synchronizePersistentCollections();
      final result = await fileTree.buildTree();
      _rootLoadError = result.error;
      notifyListeners();
      return;
    }

    if (newStatus.isDenied) {
      await setIzin(false);
      return;
    }

    await openAppSettings();
    await setIzin(false);
  }

  Future<FileSyncCollectionResult> syncSavedEntries() async {
    final result = await _fileSyncService.syncSaved();
    await _applySavedSyncResult(result);
    return result;
  }

  Future<FileSyncCollectionResult> syncHiddenEntries() async {
    final result = await _fileSyncService.syncHidden();
    await _applyHiddenSyncResult(result);
    return result;
  }

  Future<FileSyncCollectionResult> syncRecentEntries() async {
    final result = await _fileSyncService.syncRecent();
    await _applyRecentSyncResult(result);
    return result;
  }

  Future<FileSyncResult> synchronizePersistentCollections({
    bool refreshIndex = false,
  }) async {
    final result = await _fileSyncService.syncAll(
      rootPath: fileTree.rootPath,
      refreshIndex: refreshIndex,
    );
    await _applyHiddenSyncResult(result.hidden);
    await _applySavedSyncResult(result.saved);
    await _applyRecentSyncResult(result.recent);
    return result;
  }

  Future<FileSyncResult> refreshRootEntries() async {
    if (!hasStoragePermission) {
      await requestAllStoragePermission();
      return const FileSyncResult();
    }

    final syncResult = await synchronizePersistentCollections();
    final result = await fileTree.buildTree(forceRefresh: true);
    _rootLoadError = result.error;
    notifyListeners();
    return syncResult;
  }

  Future<FileSyncResult> refreshHiddenEntries() async {
    return synchronizePersistentCollections();
  }

  Future<FileSyncResult> refreshSavedEntries() async {
    return synchronizePersistentCollections();
  }

  Future<void> ensureFolderCount(
    FolderNode folder, {
    bool refresh = false,
  }) async {
    await fileTree.ensureFolderCount(folder, refresh: refresh);
  }

  Future<void> primeFolderCounts(
    Iterable<FolderNode> folders, {
    bool refresh = false,
  }) async {
    await fileTree.primeFolderCounts(folders, refresh: refresh);
  }

  Future<void> primeFileMetadata(
    Iterable<File> files, {
    bool refresh = false,
  }) async {
    await _fileMetadataService.primeFiles(files, forceRefresh: refresh);
  }

  Future<void> addRecentFolderEntry(FolderNode folder) async {
    try {
      await _recentRepository.upsert(
        RecentItemModel(
          path: folder.path,
          isDirectory: true,
          updatedAt: DateTime.now(),
        ),
      );
      await syncRecentEntries();
    } catch (error) {
      debugPrint('Recent folder write failed: $error');
    }
  }

  Future<void> addRecentFileEntry(File file) async {
    try {
      await _recentRepository.upsert(
        RecentItemModel(
          path: file.path,
          isDirectory: false,
          updatedAt: DateTime.now(),
        ),
      );
      await syncRecentEntries();
    } catch (error) {
      debugPrint('Recent file write failed: $error');
    }
  }

  Future<void> removePathsFromPersistentCollections(
    Iterable<String> paths,
  ) async {
    final uniquePaths =
        paths
            .map((path) => path.trim())
            .where((path) => path.isNotEmpty)
            .toSet();
    if (uniquePaths.isEmpty) {
      return;
    }

    await Future.wait<void>([
      _recentRepository.removePaths(uniquePaths),
      _savedRepository.removePaths(uniquePaths),
      _hiddenRepository.removePaths(uniquePaths),
    ]);
    await synchronizePersistentCollections();
  }

  Future<void> _applySavedSyncResult(FileSyncCollectionResult result) async {
    final resolvedEntries = await _materializeSyncedEntries(
      result.retainedEntries,
    );
    fileTree.setSavedItems(
      folders: resolvedEntries.folders,
      files: resolvedEntries.files,
    );
  }

  Future<void> _applyHiddenSyncResult(FileSyncCollectionResult result) async {
    final resolvedEntries = await _materializeSyncedEntries(
      result.retainedEntries,
    );
    fileTree.setHiddenPaths(resolvedEntries.paths.toSet());
    fileTree.setHiddenItems(
      folders: resolvedEntries.folders,
      files: resolvedEntries.files,
    );
  }

  Future<void> _applyRecentSyncResult(FileSyncCollectionResult result) async {
    final resolvedEntries = await _materializeSyncedEntries(
      result.retainedEntries,
    );
    fileTree.setRecentItems(
      folders: resolvedEntries.folders,
      files: resolvedEntries.files,
    );
  }

  Future<_ResolvedPersistedEntries> _materializeSyncedEntries(
    Iterable<SyncedPathEntry> items,
  ) async {
    final folders = <FolderNode>[];
    final files = <File>[];
    final paths = <String>[];

    for (final item in items) {
      final path = item.path.trim();
      if (path.isEmpty) {
        continue;
      }

      paths.add(path);
      if (item.isDirectory) {
        final folder = FolderNode(
          pathinfo.basename(path).isEmpty ? path : pathinfo.basename(path),
          path,
          [],
          [],
          null,
        );
        final cachedCount = await _folderCountRepository.read(path);
        if (cachedCount != null) {
          folder.applyFolderCountModel(cachedCount, notify: false);
        }
        folders.add(folder);
      } else {
        files.add(File(path));
      }
    }

    return _ResolvedPersistedEntries(
      folders: folders,
      files: files,
      paths: paths,
    );
  }

  @override
  void dispose() {
    fileTree.removeListener(notifyListeners);
    super.dispose();
  }
}

@immutable
class FolderFileEntries {
  const FolderFileEntries({required this.folders, required this.files});

  final List<FolderNode> folders;
  final List<File> files;

  bool get isEmpty => folders.isEmpty && files.isEmpty;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }

    return other is FolderFileEntries &&
        listEquals(folders, other.folders) &&
        listEquals(files, other.files);
  }

  @override
  int get hashCode =>
      Object.hash(Object.hashAll(folders), Object.hashAll(files));
}

class _ResolvedPersistedEntries {
  const _ResolvedPersistedEntries({
    required this.folders,
    required this.files,
    required this.paths,
  });

  final List<FolderNode> folders;
  final List<File> files;
  final List<String> paths;
}
