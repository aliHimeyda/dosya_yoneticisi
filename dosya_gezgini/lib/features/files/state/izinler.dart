import 'dart:io';

import 'package:dosya_gezgini/core/constants/storage_paths.dart';
import 'package:dosya_gezgini/data/models/recent_item_model.dart';
import 'package:dosya_gezgini/data/repositories/directory_cache_repository.dart';
import 'package:dosya_gezgini/data/repositories/folder_count_repository.dart';
import 'package:dosya_gezgini/data/repositories/hidden_repository.dart';
import 'package:dosya_gezgini/data/repositories/recent_repository.dart';
import 'package:dosya_gezgini/data/repositories/saved_repository.dart';
import 'package:dosya_gezgini/features/files/state/folderleragaci.dart';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path/path.dart' as pathinfo;
import 'package:shared_preferences/shared_preferences.dart';

class Izinler extends ChangeNotifier {
  Izinler({
    required DirectoryCacheRepository directoryCacheRepository,
    required FolderCountRepository folderCountRepository,
    required RecentRepository recentRepository,
    required SavedRepository savedRepository,
    required HiddenRepository hiddenRepository,
  }) : _recentRepository = recentRepository,
       _folderCountRepository = folderCountRepository,
       _savedRepository = savedRepository,
       _hiddenRepository = hiddenRepository,
       fileTree = FileTree(
         storageRootPath,
         directoryCacheRepository: directoryCacheRepository,
         folderCountRepository: folderCountRepository,
       ) {
    fileTree.addListener(notifyListeners);
  }

  final FolderCountRepository _folderCountRepository;
  final RecentRepository _recentRepository;
  final SavedRepository _savedRepository;
  final HiddenRepository _hiddenRepository;
  final FileTree fileTree;

  bool _izin = false;
  bool _izinDurumuHazir = false;
  List<String>? _currentFolderPath;
  FolderNode? _currentFolder;

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
      await syncHiddenEntries();
      await fileTree.buildTree();
      await syncSavedEntries();
      await syncRecentEntries();
      notifyListeners();
      return;
    }

    final newStatus = await Permission.manageExternalStorage.request();

    if (newStatus.isGranted) {
      await setIzin(true);
      await syncHiddenEntries();
      await fileTree.buildTree();
      await syncSavedEntries();
      await syncRecentEntries();
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

  Future<void> syncSavedEntries() async {
    final items = await _savedRepository.readAll();
    final resolvedEntries = await _resolvePersistedEntries(items);
    if (resolvedEntries.missingPaths.isNotEmpty) {
      await _savedRepository.removePaths(resolvedEntries.missingPaths);
    }

    fileTree.setSavedItems(
      folders: resolvedEntries.folders,
      files: resolvedEntries.files,
    );
  }

  Future<void> syncHiddenEntries() async {
    final items = await _hiddenRepository.readAll();
    final resolvedEntries = await _resolvePersistedEntries(items);
    if (resolvedEntries.missingPaths.isNotEmpty) {
      await _hiddenRepository.removePaths(resolvedEntries.missingPaths);
    }

    fileTree.setHiddenPaths(resolvedEntries.paths.toSet());
    fileTree.setHiddenItems(
      folders: resolvedEntries.folders,
      files: resolvedEntries.files,
    );
  }

  Future<void> syncRecentEntries() async {
    final items = await _recentRepository.readAll();
    final resolvedEntries = await _resolvePersistedEntries(items);
    if (resolvedEntries.missingPaths.isNotEmpty) {
      await _recentRepository.removePaths(resolvedEntries.missingPaths);
    }

    fileTree.setRecentItems(
      folders: resolvedEntries.folders,
      files: resolvedEntries.files,
    );
  }

  Future<void> refreshRootEntries() async {
    if (!hasStoragePermission) {
      await requestAllStoragePermission();
      return;
    }

    await syncHiddenEntries();
    await fileTree.buildTree(forceRefresh: true);
    await syncSavedEntries();
    await syncRecentEntries();
    notifyListeners();
  }

  Future<void> refreshHiddenEntries() async {
    await syncHiddenEntries();
  }

  Future<void> refreshSavedEntries() async {
    await syncSavedEntries();
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
    await syncHiddenEntries();
    await syncSavedEntries();
    await syncRecentEntries();
  }

  Future<_ResolvedPersistedEntries> _resolvePersistedEntries(
    Iterable<dynamic> items,
  ) async {
    final folders = <FolderNode>[];
    final files = <File>[];
    final paths = <String>[];
    final missingPaths = <String>[];

    for (final item in items) {
      final path = (item.path as String?)?.trim() ?? '';
      if (path.isEmpty) {
        continue;
      }

      final isDirectory = item.isDirectory as bool? ?? false;
      final entity =
          isDirectory ? Directory(path) as FileSystemEntity : File(path);
      if (!await entity.exists()) {
        missingPaths.add(path);
        continue;
      }

      paths.add(path);
      if (isDirectory) {
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
      missingPaths: missingPaths,
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
    required this.missingPaths,
  });

  final List<FolderNode> folders;
  final List<File> files;
  final List<String> paths;
  final List<String> missingPaths;
}
