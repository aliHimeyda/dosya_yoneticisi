import 'dart:async';
import 'dart:collection';
import 'dart:io';

import 'package:dosya_gezgini/data/constants/file_category_constants.dart';
import 'package:dosya_gezgini/data/models/directory_cache_model.dart';
import 'package:dosya_gezgini/data/models/folder_count_model.dart';
import 'package:dosya_gezgini/data/repositories/directory_cache_repository.dart';
import 'package:dosya_gezgini/data/repositories/folder_count_repository.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as pathinfo;

class FolderNode extends ChangeNotifier {
  FolderNode(
    this.name,
    this.path,
    List<FolderNode>? folderchildren,
    List<File>? filechildren,
    this.parent, {
    this.isVirtual = false,
    Set<String>? allowedExtensions,
    bool areChildrenLoaded = false,
    bool isHydratedFromCache = false,
    FolderCountModel? folderCountModel,
  }) : folderchildren = folderchildren ?? [],
       filechildren = filechildren ?? [],
       allowedExtensions = allowedExtensions ?? const {},
       _areChildrenLoaded = areChildrenLoaded,
       _isHydratedFromCache = isHydratedFromCache,
       _folderCountModel = folderCountModel {
    if (!isVirtual) {
      _olusumtarihi();
    }
  }

  final bool isVirtual;
  final Set<String> allowedExtensions;

  String name;
  String path;
  List<FolderNode> folderchildren;
  List<File> filechildren;
  DateTime? olusumtarihi;
  FolderNode? parent;
  bool _areChildrenLoaded;
  bool _isHydratedFromCache;
  FolderCountModel? _folderCountModel;

  int get childCount => folderchildren.length + filechildren.length;
  bool get areChildrenLoaded => _areChildrenLoaded;
  bool get isHydratedFromCache => _isHydratedFromCache;
  FolderCountModel? get folderCountModel => _folderCountModel;
  int? get cachedFolderCount =>
      _folderCountModel?.isLoaded == true ? _folderCountModel!.folderCount : null;
  int? get cachedFileCount =>
      _folderCountModel?.isLoaded == true ? _folderCountModel!.fileCount : null;
  int? get cachedTotalCount =>
      _folderCountModel?.isLoaded == true ? _folderCountModel!.totalCount : null;
  String get itemCountLabel => cachedTotalCount?.toString() ?? '-';

  String get formatlanmistarih {
    if (olusumtarihi == null) return "Bilinmiyor";
    return DateFormat('dd/MM/yyyy HH:mm').format(olusumtarihi!);
  }

  Future<void> _olusumtarihi() async {
    try {
      final stat = await FileStat.stat(path);
      olusumtarihi = stat.changed;
      notifyListeners();
    } catch (e) {
      debugPrint("Klasor tarihi okunamadi: $e");
    }
  }

  void replaceChildren({
    required List<FolderNode> folders,
    required List<File> files,
    bool fromCache = false,
  }) {
    folderchildren = folders;
    filechildren = files;
    _areChildrenLoaded = !fromCache;
    _isHydratedFromCache = fromCache;
    notifyListeners();
  }

  void applyFolderCountModel(FolderCountModel model, {bool notify = true}) {
    final hasSameValues =
        _folderCountModel?.path == model.path &&
        _folderCountModel?.folderCount == model.folderCount &&
        _folderCountModel?.fileCount == model.fileCount &&
        _folderCountModel?.totalCount == model.totalCount &&
        _folderCountModel?.isLoaded == model.isLoaded &&
        _folderCountModel?.updatedAt == model.updatedAt;
    if (hasSameValues) {
      return;
    }

    _folderCountModel = model;
    if (notify) {
      notifyListeners();
    }
  }

  @override
  String toString() {
    return 'Folder: $name ($path)';
  }
}

class FolderLoadResult {
  const FolderLoadResult.success() : error = null;
  const FolderLoadResult.failure(this.error);

  final Object? error;

  bool get hasError => error != null;
}

class FileTree extends ChangeNotifier {
  FileTree(
    this.rootPath, {
    required DirectoryCacheRepository directoryCacheRepository,
    required FolderCountRepository folderCountRepository,
  }) : _directoryCacheRepository = directoryCacheRepository,
       _folderCountRepository = folderCountRepository,
      root = FolderNode("Root", rootPath, [], [], null);

  static const int _progressChunkSize = 25;
  static const int _maxConcurrentFolderCountJobs = 2;
  static const Duration _directoryCacheMaxAge = Duration(minutes: 15);

  final String rootPath;
  final DirectoryCacheRepository _directoryCacheRepository;
  final FolderCountRepository _folderCountRepository;
  final FolderNode root;
  Set<String> _hiddenPaths = <String>{};
  final List<FolderNode> kaydedilenfolder = [];
  final List<File> kaydedilenfile = [];
  final List<FolderNode> gizlenenfolder = [];
  final List<File> gizlenenfile = [];
  final List<FolderNode> ensongezilenfolders = [];
  final List<File> ensongezilenfiles = [];
  final Map<String, DirectoryCacheModel> _directoryCacheMemory =
      <String, DirectoryCacheModel>{};
  final Map<String, FolderCountModel> _folderCountCache = {};
  final Queue<_FolderCountJob> _folderCountQueue = Queue<_FolderCountJob>();
  final Set<String> _queuedFolderCountPaths = <String>{};
  final Set<String> _runningFolderCountPaths = <String>{};
  int _activeFolderCountJobs = 0;

  void addRecentFolder(FolderNode folder) {
    ensongezilenfolders.removeWhere((item) => item.path == folder.path);
    ensongezilenfolders.insert(0, folder);
    notifyListeners();
  }

  void addRecentFile(File file) {
    ensongezilenfiles.removeWhere((item) => item.path == file.path);
    ensongezilenfiles.insert(0, file);
    notifyListeners();
  }

  void setSavedItems({
    required List<FolderNode> folders,
    required List<File> files,
  }) {
    kaydedilenfolder
      ..clear()
      ..addAll(folders);
    kaydedilenfile
      ..clear()
      ..addAll(files);
    notifyListeners();
  }

  void setHiddenItems({
    required List<FolderNode> folders,
    required List<File> files,
  }) {
    gizlenenfolder
      ..clear()
      ..addAll(folders);
    gizlenenfile
      ..clear()
      ..addAll(files);
    notifyListeners();
  }

  void setRecentItems({
    required List<FolderNode> folders,
    required List<File> files,
  }) {
    ensongezilenfolders
      ..clear()
      ..addAll(folders);
    ensongezilenfiles
      ..clear()
      ..addAll(files);
    notifyListeners();
  }

  void setHiddenPaths(Set<String> hiddenPaths) {
    _hiddenPaths = Set<String>.from(hiddenPaths);
    notifyListeners();
  }

  late final FolderNode bilinmeyendosya = _createCategoryNode(
    FileCategoryConstants.unknown,
  );
  late final FolderNode exceldosya = _createCategoryNode(
    FileCategoryConstants.excel,
  );
  late final FolderNode resimdosya = _createCategoryNode(
    FileCategoryConstants.image,
  );
  late final FolderNode videodosya = _createCategoryNode(
    FileCategoryConstants.video,
  );
  late final FolderNode sesdosya = _createCategoryNode(
    FileCategoryConstants.audio,
  );
  late final FolderNode worddosya = _createCategoryNode(
    FileCategoryConstants.word,
  );
  late final FolderNode zipdosya = _createCategoryNode(
    FileCategoryConstants.archive,
  );
  late final FolderNode pdfdosya = _createCategoryNode(
    FileCategoryConstants.pdf,
  );
  late final FolderNode txtdosya = _createCategoryNode(
    FileCategoryConstants.text,
  );
  late final FolderNode powerpointdosya = _createCategoryNode(
    FileCategoryConstants.powerPoint,
  );

  List<FolderNode> get _virtualFolders => [
    bilinmeyendosya,
    exceldosya,
    resimdosya,
    videodosya,
    sesdosya,
    worddosya,
    zipdosya,
    pdfdosya,
    txtdosya,
    powerpointdosya,
  ];

  FolderNode _createCategoryNode(FileCategoryDefinition category) {
    return FolderNode(
      category.folderName,
      category.virtualPath,
      [],
      [],
      root,
      isVirtual: true,
      allowedExtensions: category.extensions,
    );
  }

  Future<FolderNode> buildTree({bool forceRefresh = false}) async {
    await loadFolder(root, forceRefresh: forceRefresh);
    return root;
  }

  Future<void> primeFolderCounts(
    Iterable<FolderNode> folders, {
    bool refresh = false,
  }) async {
    for (final folder in folders) {
      unawaited(ensureFolderCount(folder, refresh: refresh));
    }
  }

  Future<void> ensureFolderCount(
    FolderNode folder, {
    bool refresh = false,
  }) async {
    if (folder.isVirtual) {
      return;
    }

    final path = folder.path;
    final memoryValue = _folderCountCache[path];
    if (memoryValue != null) {
      folder.applyFolderCountModel(memoryValue);
      if (!refresh) {
        return;
      }
    }

    if (folder.areChildrenLoaded) {
      await _persistResolvedFolderCount(
        folder,
        folderCount: folder.folderchildren.length,
        fileCount: folder.filechildren.length,
      );
      return;
    }

    if (!refresh) {
      final persistedValue = await _folderCountRepository.read(path);
      if (persistedValue != null) {
        _folderCountCache[path] = persistedValue;
        folder.applyFolderCountModel(persistedValue);
        return;
      }
    }

    _enqueueFolderCountJob(folder);
  }

  FolderNode? findKnownFolder(String path) {
    if (root.path == path) {
      return root;
    }

    for (final folder in _virtualFolders) {
      if (folder.path == path) {
        return folder;
      }
    }

    return null;
  }

  Future<FolderLoadResult> loadFolder(
    FolderNode folder, {
    bool forceRefresh = false,
    ValueChanged<FolderNode>? onProgress,
  }) async {
    if (folder.isVirtual) {
      _emitFolderSnapshot(
        folder,
        folders: folder.folderchildren,
        files: folder.filechildren,
        fromCache: folder.isHydratedFromCache,
        onProgress: onProgress,
      );
      notifyListeners();
      return const FolderLoadResult.success();
    }

    final result = await _loadDirectoryFolder(
      folder,
      forceRefresh: forceRefresh,
      onProgress: onProgress,
    );
    notifyListeners();
    return result;
  }

  Future<FolderLoadResult> _loadDirectoryFolder(
    FolderNode folder, {
    required bool forceRefresh,
    ValueChanged<FolderNode>? onProgress,
  }) async {
    final dir = Directory(folder.path);
    if (!await dir.exists()) {
      await _clearDirectoryCache(folder.path);
      folder.replaceChildren(folders: [], files: []);
      return const FolderLoadResult.failure('directory_not_found');
    }

    final directoryStat = await dir.stat();
    final persistedCache =
        forceRefresh ? null : await _readDirectoryCache(folder.path);
    final shouldHydrateFromCache =
        !forceRefresh &&
        persistedCache != null &&
        (!folder.areChildrenLoaded || folder.childCount == 0);
    final shouldPreserveVisibleSnapshot =
        shouldHydrateFromCache || folder.childCount > 0;

    if (shouldHydrateFromCache) {
      _applyDirectoryCacheSnapshot(
        folder,
        persistedCache,
        onProgress: onProgress,
      );
    }

    if (!forceRefresh && persistedCache != null) {
      final shouldRefresh = _shouldRefreshDirectoryCache(
        persistedCache,
        directoryStat.modified,
      );
      if (!shouldRefresh) {
        return const FolderLoadResult.success();
      }
    }

    final folders = <FolderNode>[];
    final files = <File>[];

    try {
      var processedItems = 0;
      await for (final entity in dir.list(followLinks: false)) {
        if (_hiddenPaths.contains(entity.path)) {
          continue;
        }

        final name = pathinfo.basename(entity.path);
        if (entity is Directory) {
          final childFolder = FolderNode(name, entity.path, [], [], folder);
          final cachedCount = _folderCountCache[entity.path];
          if (cachedCount != null) {
            childFolder.applyFolderCountModel(cachedCount, notify: false);
          }
          folders.add(childFolder);
        } else if (entity is File) {
          files.add(File(entity.path));
        }

        processedItems++;
        if (!shouldPreserveVisibleSnapshot &&
            processedItems % _progressChunkSize == 0) {
          _emitFolderSnapshot(
            folder,
            folders: folders,
            files: files,
            onProgress: onProgress,
          );
        }
      }
    } catch (e) {
      debugPrint("Klasor okunamadi ${folder.path}: $e");
      if (folders.isEmpty && files.isEmpty) {
        folder.replaceChildren(folders: [], files: []);
      }
      return FolderLoadResult.failure(e);
    }

    _emitFolderSnapshot(
      folder,
      folders: folders,
      files: files,
      onProgress: onProgress,
    );
    await _persistDirectoryCache(
      folder,
      folders: folders,
      files: files,
      directoryModifiedAt: directoryStat.modified,
    );
    await _persistResolvedFolderCount(
      folder,
      folderCount: folders.length,
      fileCount: files.length,
    );
    return const FolderLoadResult.success();
  }

  void _emitFolderSnapshot(
    FolderNode folder, {
    required List<FolderNode> folders,
    required List<File> files,
    bool fromCache = false,
    ValueChanged<FolderNode>? onProgress,
  }) {
    _sortEntries(folders, files);
    folder.replaceChildren(
      folders: List<FolderNode>.from(folders),
      files: List<File>.from(files),
      fromCache: fromCache,
    );
    onProgress?.call(folder);
  }

  void _sortEntries(List<FolderNode> folders, List<File> files) {
    folders.sort(
      (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
    );
    files.sort(
      (a, b) => pathinfo
          .basename(a.path)
          .toLowerCase()
          .compareTo(pathinfo.basename(b.path).toLowerCase()),
    );
  }

  void ekraniguncelle() {
    notifyListeners();
  }

  Future<DirectoryCacheModel?> _readDirectoryCache(String path) async {
    final memoryValue = _directoryCacheMemory[path];
    if (memoryValue != null) {
      return memoryValue;
    }

    final persistedValue = await _directoryCacheRepository.read(path);
    if (persistedValue == null) {
      return null;
    }

    _directoryCacheMemory[path] = persistedValue;
    return persistedValue;
  }

  bool _shouldRefreshDirectoryCache(
    DirectoryCacheModel cache,
    DateTime directoryModifiedAt,
  ) {
    final now = DateTime.now();
    if (cache.isExpired(_directoryCacheMaxAge, now)) {
      return true;
    }

    return !cache.matchesDirectoryModifiedAt(directoryModifiedAt);
  }

  void _applyDirectoryCacheSnapshot(
    FolderNode folder,
    DirectoryCacheModel cache, {
    ValueChanged<FolderNode>? onProgress,
  }) {
    final cachedFolders =
        cache.folderPaths
            .where((path) => !_hiddenPaths.contains(path))
            .map((path) => _restoreFolderNodeFromCache(path, folder))
            .toList(growable: false);
    final cachedFiles =
        cache.filePaths
            .where((path) => !_hiddenPaths.contains(path))
            .map(File.new)
            .toList(growable: false);

    _emitFolderSnapshot(
      folder,
      folders: cachedFolders,
      files: cachedFiles,
      fromCache: true,
      onProgress: onProgress,
    );
  }

  FolderNode _restoreFolderNodeFromCache(String path, FolderNode parent) {
    final resolvedName = pathinfo.basename(path);
    final folder = FolderNode(
      resolvedName.isEmpty ? path : resolvedName,
      path,
      [],
      [],
      parent,
    );
    final cachedCount = _folderCountCache[path];
    if (cachedCount != null) {
      folder.applyFolderCountModel(cachedCount, notify: false);
    }
    return folder;
  }

  Future<void> _persistDirectoryCache(
    FolderNode folder, {
    required List<FolderNode> folders,
    required List<File> files,
    required DateTime directoryModifiedAt,
  }) async {
    final cacheModel = DirectoryCacheModel(
      path: folder.path,
      folderPaths:
          folders.map((childFolder) => childFolder.path).toList(growable: false),
      filePaths:
          files.map((childFile) => childFile.path).toList(growable: false),
      directoryModifiedAt: directoryModifiedAt,
      updatedAt: DateTime.now(),
    );
    _directoryCacheMemory[folder.path] = cacheModel;
    await _directoryCacheRepository.upsert(cacheModel);
  }

  Future<void> _clearDirectoryCache(String path) async {
    _directoryCacheMemory.remove(path);
    await _directoryCacheRepository.removePaths(<String>[path]);
  }

  void _enqueueFolderCountJob(FolderNode folder) {
    final path = folder.path;
    if (_queuedFolderCountPaths.contains(path) ||
        _runningFolderCountPaths.contains(path)) {
      return;
    }

    _queuedFolderCountPaths.add(path);
    _folderCountQueue.add(_FolderCountJob(folder));
    _drainFolderCountQueue();
  }

  void _drainFolderCountQueue() {
    while (_activeFolderCountJobs < _maxConcurrentFolderCountJobs &&
        _folderCountQueue.isNotEmpty) {
      final job = _folderCountQueue.removeFirst();
      _queuedFolderCountPaths.remove(job.folder.path);
      _runningFolderCountPaths.add(job.folder.path);
      _activeFolderCountJobs++;
      unawaited(_runFolderCountJob(job));
    }
  }

  Future<void> _runFolderCountJob(_FolderCountJob job) async {
    try {
      final model = await _calculateFolderCount(job.folder.path);
      if (model == null) {
        return;
      }

      _folderCountCache[job.folder.path] = model;
      await _folderCountRepository.upsert(model);
      job.folder.applyFolderCountModel(model);
    } catch (error) {
      debugPrint('Klasor item count hesaplanamadi ${job.folder.path}: $error');
    } finally {
      _runningFolderCountPaths.remove(job.folder.path);
      _activeFolderCountJobs--;
      _drainFolderCountQueue();
    }
  }

  Future<FolderCountModel?> _calculateFolderCount(String folderPath) async {
    final directory = Directory(folderPath);
    if (!await directory.exists()) {
      return null;
    }

    var folderCount = 0;
    var fileCount = 0;
    var processedItems = 0;

    try {
      await for (final entity in directory.list(followLinks: false)) {
        if (_hiddenPaths.contains(entity.path)) {
          continue;
        }

        if (entity is Directory) {
          folderCount++;
        } else if (entity is File) {
          fileCount++;
        }

        processedItems++;
        if (processedItems % _progressChunkSize == 0) {
          await Future<void>.delayed(Duration.zero);
        }
      }
    } catch (error) {
      debugPrint('Klasor sayimi okunamadi $folderPath: $error');
      return null;
    }

    return FolderCountModel(
      path: folderPath,
      folderCount: folderCount,
      fileCount: fileCount,
      totalCount: folderCount + fileCount,
      isLoaded: true,
      updatedAt: DateTime.now(),
    );
  }

  Future<void> _persistResolvedFolderCount(
    FolderNode folder, {
    required int folderCount,
    required int fileCount,
  }) async {
    if (folder.isVirtual) {
      return;
    }

    final model = FolderCountModel(
      path: folder.path,
      folderCount: folderCount,
      fileCount: fileCount,
      totalCount: folderCount + fileCount,
      isLoaded: true,
      updatedAt: DateTime.now(),
    );
    _folderCountCache[folder.path] = model;
    folder.applyFolderCountModel(model);
    await _folderCountRepository.upsert(model);
  }
}

class _FolderCountJob {
  const _FolderCountJob(this.folder);

  final FolderNode folder;
}
