import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:dosya_gezgini/core/localization/file_sync_messages.dart';
import 'package:dosya_gezgini/data/constants/file_category_constants.dart';
import 'package:dosya_gezgini/data/repositories/category_repository.dart';
import 'package:dosya_gezgini/features/files/presentation/models/folder_route_data.dart';
import 'package:dosya_gezgini/features/files/state/folderleragaci.dart';
import 'package:dosya_gezgini/features/files/state/izinler.dart';
import 'package:dosya_gezgini/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

class KlasoricerigisayfasiProvider extends ChangeNotifier {
  KlasoricerigisayfasiProvider({
    required Izinler izinler,
    required CategoryRepository categoryRepository,
    FolderRouteData? routeData,
  }) : _izinler = izinler,
       _categoryRepository = categoryRepository,
       _routeData = routeData {
    _scrollController.addListener(_handleScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_isDisposed) {
        return;
      }
      unawaited(_loadInitialFolder());
    });
  }

  static const int pageSize = 100;
  static const int categoryPageSize = pageSize;

  final Izinler _izinler;
  final CategoryRepository _categoryRepository;
  final FolderRouteData? _routeData;
  final ScrollController _scrollController = ScrollController();

  FolderNode? _folder;
  FolderNode? _observedFolder;
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMoreCategoryItems = false;
  Object? _loadError;
  bool _didLoadInitialFolder = false;
  bool _isDisposed = false;
  bool _notifyScheduled = false;
  int _activeLoadId = 0;
  int _nextCategoryOffset = 0;
  String? _categoryProgressLabel;
  int _visibleDirectoryFolderCount = 0;
  int _visibleDirectoryFileCount = 0;
  bool _isDirectoryLoadingMore = false;
  int _knownDirectoryTotalCount = 0;

  ScrollController get scrollController => _scrollController;
  FolderNode? get folder => _folder;
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  bool get hasMoreCategoryItems => _hasMoreCategoryItems;
  Object? get loadError => _loadError;
  String? get categoryProgressLabel => _categoryProgressLabel;
  bool get isDirectoryLoadingMore => _isDirectoryLoadingMore;

  List<FolderNode> get visibleFolders {
    final currentFolder = _folder;
    if (currentFolder == null) {
      return const <FolderNode>[];
    }

    if (currentFolder.isVirtual) {
      return currentFolder.folderchildren;
    }

    return currentFolder.folderchildren
        .take(_visibleDirectoryFolderCount)
        .toList();
  }

  List<File> get visibleFiles {
    final currentFolder = _folder;
    if (currentFolder == null) {
      return const <File>[];
    }

    if (currentFolder.isVirtual) {
      return currentFolder.filechildren;
    }

    return currentFolder.filechildren.take(_visibleDirectoryFileCount).toList();
  }

  int get loadingPlaceholderCount {
    final currentFolder = _folder;
    if (currentFolder == null) {
      return 0;
    }

    if (currentFolder.isVirtual) {
      return _isLoadingMore ? 3 : 0;
    }

    return _isDirectoryLoadingMore ? 3 : 0;
  }

  Future<String?> refreshFolderWithSync(
    AppLocalizations l10n, {
    bool forceRefresh = true,
  }) async {
    final syncResult = await _izinler.synchronizePersistentCollections();
    final message = buildFileSyncNoticeMessage(l10n, syncResult);
    await loadFolder(forceRefresh: forceRefresh);
    return message;
  }

  Future<void> loadFolder({bool forceRefresh = false}) async {
    final loadId = ++_activeLoadId;
    final routeData = _resolveRouteData();
    final targetFolder = routeData?.resolveFolderNode(
      fileTree: _izinler.fileTree,
    );

    if (targetFolder == null) {
      _attachFolderListener(null);
      _folder = null;
      _isLoading = false;
      _loadError = StateError('folder_route_not_found');
      _notifySafely();
      return;
    }

    if (targetFolder.isVirtual) {
      await _loadCategoryFolder(
        targetFolder,
        loadId: loadId,
        forceRefresh: forceRefresh,
      );
      return;
    }

    await _loadDirectoryFolder(
      targetFolder,
      loadId: loadId,
      forceRefresh: forceRefresh,
    );
  }

  String buildCategoryProgressLabel(AppLocalizations l10n, FolderNode folder) {
    final categoryName = switch (folder.path) {
      _ when folder.path == FileCategoryConstants.unknown.virtualPath =>
        l10n.categoryFiles,
      _ when folder.path == FileCategoryConstants.excel.virtualPath =>
        l10n.categoryExcel,
      _ when folder.path == FileCategoryConstants.image.virtualPath =>
        l10n.categoryImages,
      _ when folder.path == FileCategoryConstants.video.virtualPath =>
        l10n.categoryVideos,
      _ when folder.path == FileCategoryConstants.audio.virtualPath =>
        l10n.categoryAudio,
      _ when folder.path == FileCategoryConstants.word.virtualPath =>
        l10n.categoryWord,
      _ when folder.path == FileCategoryConstants.powerPoint.virtualPath =>
        l10n.categoryPowerPoint,
      _ when folder.path == FileCategoryConstants.archive.virtualPath =>
        l10n.categoryArchives,
      _ when folder.path == FileCategoryConstants.pdf.virtualPath =>
        l10n.categoryPdf,
      _ when folder.path == FileCategoryConstants.text.virtualPath =>
        l10n.categoryText,
      _ => folder.name,
    };

    return l10n.categoryIndexPreparing(categoryName);
  }

  @override
  void dispose() {
    _isDisposed = true;
    _detachFolderListener();
    _scrollController
      ..removeListener(_handleScroll)
      ..dispose();
    super.dispose();
  }

  Future<void> _loadInitialFolder() async {
    if (_didLoadInitialFolder) {
      return;
    }

    _didLoadInitialFolder = true;
    await loadFolder();
  }

  bool get _hasMoreDirectoryItems {
    final currentFolder = _folder;
    if (currentFolder == null || currentFolder.isVirtual) {
      return false;
    }

    return _visibleDirectoryFolderCount < currentFolder.folderchildren.length ||
        _visibleDirectoryFileCount < currentFolder.filechildren.length;
  }

  void _handleScroll() {
    if (!_scrollController.hasClients) {
      return;
    }

    if (_scrollController.position.extentAfter > 320) {
      return;
    }

    final currentFolder = _folder;
    if (currentFolder == null) {
      return;
    }

    if (currentFolder.isVirtual) {
      if (!_isLoadingMore && _hasMoreCategoryItems) {
        unawaited(_loadMoreCategoryItems());
      }
      return;
    }

    if (!_isDirectoryLoadingMore && _hasMoreDirectoryItems) {
      unawaited(_loadMoreDirectoryItems());
    }
  }

  Future<void> _loadMoreDirectoryItems() async {
    final currentFolder = _folder;
    if (currentFolder == null ||
        currentFolder.isVirtual ||
        _isDirectoryLoadingMore ||
        !_hasMoreDirectoryItems) {
      return;
    }

    _isDirectoryLoadingMore = true;
    _notifySafely();

    await Future.microtask(() {
      if (_isDisposed || !identical(currentFolder, _folder)) {
        return;
      }

      int budget = pageSize;
      final folderRemaining =
          currentFolder.folderchildren.length - _visibleDirectoryFolderCount;
      final folderAdd = math.min(budget, folderRemaining);
      budget -= folderAdd;
      final fileAdd = math.min(
        budget,
        currentFolder.filechildren.length - _visibleDirectoryFileCount,
      );
      _visibleDirectoryFolderCount += folderAdd;
      _visibleDirectoryFileCount += fileAdd;
      _knownDirectoryTotalCount = currentFolder.childCount;
      _isDirectoryLoadingMore = false;
      _notifySafely();
    });
  }

  FolderRouteData? _resolveRouteData() {
    final routeData = _routeData;
    if (routeData != null) {
      return routeData;
    }

    final currentFolder = _izinler.currentFolder;
    if (currentFolder == null) {
      return null;
    }

    return FolderRouteData.fromFolderNode(currentFolder);
  }

  Future<void> _loadDirectoryFolder(
    FolderNode targetFolder, {
    required int loadId,
    required bool forceRefresh,
  }) async {
    final isRefreshingCurrentFolder = _folder?.path == targetFolder.path;

    _folder = targetFolder;
    _isLoading = true;
    _isLoadingMore = false;
    _loadError = null;
    _hasMoreCategoryItems = false;
    _nextCategoryOffset = 0;
    _categoryProgressLabel = null;
    if (!isRefreshingCurrentFolder) {
      _visibleDirectoryFolderCount = 0;
      _visibleDirectoryFileCount = 0;
      _knownDirectoryTotalCount = 0;
    }
    _isDirectoryLoadingMore = false;
    _attachFolderListener(targetFolder);
    _syncVisibleFolder(targetFolder);
    _notifySafely();

    final result = await _izinler.fileTree.loadFolder(
      targetFolder,
      forceRefresh: forceRefresh,
      onProgress: (_) {
        if (_isDisposed || loadId != _activeLoadId) {
          return;
        }

        _folder = targetFolder;
        _syncDirectoryVisibleCounts(targetFolder);
        _notifySafely();
      },
    );

    if (_isDisposed || loadId != _activeLoadId) {
      return;
    }

    _folder = targetFolder;
    _isLoading = false;
    _loadError = result.error;
    _syncDirectoryVisibleCounts(targetFolder);
    _syncVisibleFolder(targetFolder);
    _notifySafely();
  }

  void _syncDirectoryVisibleCounts(FolderNode folder) {
    if (folder.isVirtual) {
      return;
    }

    final newTotal = folder.childCount;
    final currentVisibleTotal =
        _visibleDirectoryFolderCount + _visibleDirectoryFileCount;
    final hasExistingWindow = currentVisibleTotal > 0;
    if (hasExistingWindow) {
      final wasShowingAllKnownItems =
          _knownDirectoryTotalCount > 0 &&
          currentVisibleTotal >= _knownDirectoryTotalCount;
      final grewBy = math.max(0, newTotal - _knownDirectoryTotalCount);
      final desiredVisibleTotal =
          wasShowingAllKnownItems
              ? math.min(pageSize, newTotal)
              : math.min(newTotal, currentVisibleTotal + grewBy);
      _applyDirectoryVisibleBudget(folder, desiredVisibleTotal);
      _knownDirectoryTotalCount = newTotal;
      return;
    }

    _applyDirectoryVisibleBudget(folder, math.min(pageSize, newTotal));
    _knownDirectoryTotalCount = newTotal;
  }

  void _applyDirectoryVisibleBudget(FolderNode folder, int visibleItemBudget) {
    int budget = visibleItemBudget;
    final visibleFolders = math.min(budget, folder.folderchildren.length);
    budget -= visibleFolders;
    _visibleDirectoryFolderCount = visibleFolders;
    _visibleDirectoryFileCount = math.min(budget, folder.filechildren.length);
  }

  Future<void> _loadCategoryFolder(
    FolderNode targetFolder, {
    required int loadId,
    required bool forceRefresh,
  }) async {
    _folder = targetFolder;
    _isLoading = true;
    _isLoadingMore = false;
    _loadError = null;
    _hasMoreCategoryItems = false;
    _nextCategoryOffset = 0;
    _categoryProgressLabel = targetFolder.name;
    _attachFolderListener(targetFolder);
    _syncVisibleFolder(targetFolder);
    _notifySafely();

    try {
      final rootPath = _izinler.fileTree.rootPath;
      final readiness = await _categoryRepository.ensureCategoryReady(
        rootPath: rootPath,
        categoryPath: targetFolder.path,
        forceRefresh: forceRefresh,
      );

      if (_isDisposed || loadId != _activeLoadId) {
        return;
      }

      final firstPage = await _categoryRepository.getCategoryPage(
        categoryPath: targetFolder.path,
        limit: categoryPageSize,
      );

      if (_isDisposed || loadId != _activeLoadId) {
        return;
      }

      targetFolder.replaceChildren(
        folders: const <FolderNode>[],
        files: firstPage.items.map((item) => item.toFile()).toList(),
      );

      _folder = targetFolder;
      _isLoading = false;
      _loadError = null;
      _hasMoreCategoryItems = firstPage.hasMore;
      _nextCategoryOffset = firstPage.nextOffset;
      _categoryProgressLabel = null;
      _syncVisibleFolder(targetFolder);
      _notifySafely();

      if (readiness.needsBackgroundRefresh && !forceRefresh) {
        unawaited(_refreshCategoryInBackground(targetFolder, loadId: loadId));
      }
    } catch (error) {
      if (_isDisposed || loadId != _activeLoadId) {
        return;
      }

      _folder = targetFolder;
      _isLoading = false;
      _loadError = error;
      _notifySafely();
    }
  }

  Future<void> _refreshCategoryInBackground(
    FolderNode targetFolder, {
    required int loadId,
  }) async {
    try {
      final rootPath = _izinler.fileTree.rootPath;
      await _categoryRepository.refreshIndex(rootPath: rootPath);

      if (_isDisposed ||
          loadId != _activeLoadId ||
          _folder?.path != targetFolder.path) {
        return;
      }

      final refreshedPage = await _categoryRepository.getCategoryPage(
        categoryPath: targetFolder.path,
        limit: categoryPageSize,
      );

      if (_isDisposed ||
          loadId != _activeLoadId ||
          _folder?.path != targetFolder.path) {
        return;
      }

      targetFolder.replaceChildren(
        folders: const <FolderNode>[],
        files: refreshedPage.items.map((item) => item.toFile()).toList(),
      );

      _folder = targetFolder;
      _hasMoreCategoryItems = refreshedPage.hasMore;
      _nextCategoryOffset = refreshedPage.nextOffset;
      _loadError = null;
      _notifySafely();
    } catch (_) {
      // Silent refresh should not replace visible cached results with an error state.
    }
  }

  Future<void> _loadMoreCategoryItems() async {
    final currentFolder = _folder;
    if (currentFolder == null ||
        !currentFolder.isVirtual ||
        _isLoading ||
        _isLoadingMore ||
        !_hasMoreCategoryItems) {
      return;
    }

    _isLoadingMore = true;
    _notifySafely();

    try {
      final nextPage = await _categoryRepository.getCategoryPage(
        categoryPath: currentFolder.path,
        offset: _nextCategoryOffset,
        limit: categoryPageSize,
      );

      if (_isDisposed || !identical(currentFolder, _folder)) {
        return;
      }

      currentFolder.replaceChildren(
        folders: const <FolderNode>[],
        files: <File>[
          ...currentFolder.filechildren,
          ...nextPage.items.map((item) => item.toFile()),
        ],
      );

      _folder = currentFolder;
      _hasMoreCategoryItems = nextPage.hasMore;
      _nextCategoryOffset = nextPage.nextOffset;
      _notifySafely();
    } catch (error) {
      if (_isDisposed || !identical(currentFolder, _folder)) {
        return;
      }

      _loadError = error;
      _notifySafely();
    } finally {
      final shouldResetLoadingMore =
          !_isDisposed && identical(currentFolder, _folder);
      if (shouldResetLoadingMore) {
        _isLoadingMore = false;
        _notifySafely();
      }
    }
  }

  void _attachFolderListener(FolderNode? folder) {
    if (identical(_observedFolder, folder)) {
      return;
    }

    _detachFolderListener();
    _observedFolder = folder;
    _observedFolder?.addListener(_handleObservedFolderChanged);
  }

  void _detachFolderListener() {
    _observedFolder?.removeListener(_handleObservedFolderChanged);
    _observedFolder = null;
  }

  void _handleObservedFolderChanged() {
    final observedFolder = _observedFolder;
    if (_isDisposed || observedFolder == null) {
      return;
    }

    _folder = observedFolder;
    if (!observedFolder.isVirtual) {
      _syncDirectoryVisibleCounts(observedFolder);
    }
    _notifySafely();
  }

  void _syncVisibleFolder(FolderNode folder) {
    void updateVisibleFolder() {
      if (_isDisposed || identical(_izinler.currentFolder, folder)) {
        return;
      }

      _izinler.setVisibleFolder(folder);
    }

    final schedulerPhase = WidgetsBinding.instance.schedulerPhase;
    if (schedulerPhase == SchedulerPhase.idle ||
        schedulerPhase == SchedulerPhase.postFrameCallbacks) {
      updateVisibleFolder();
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      updateVisibleFolder();
    });
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
}
