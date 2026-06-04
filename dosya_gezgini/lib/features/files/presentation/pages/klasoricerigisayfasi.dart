import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:dosya_gezgini/data/constants/file_category_constants.dart';
import 'package:dosya_gezgini/data/repositories/category_repository.dart';
import 'package:dosya_gezgini/core/localization/l10n_extensions.dart';
import 'package:dosya_gezgini/features/files/presentation/models/folder_route_data.dart';
import 'package:dosya_gezgini/features/files/presentation/widgets/dosya_folder.dart';
import 'package:dosya_gezgini/features/files/state/altislem_provider.dart';
import 'package:dosya_gezgini/features/files/state/dosyaislemleri.dart';
import 'package:dosya_gezgini/features/files/state/folderleragaci.dart';
import 'package:dosya_gezgini/features/files/state/izinler.dart';
import 'package:dosya_gezgini/shared/widgets/empty_state_widget.dart';
import 'package:dosya_gezgini/shared/widgets/error_state_widget.dart';
import 'package:dosya_gezgini/shared/widgets/file_item_skeleton.dart';
import 'package:dosya_gezgini/shared/widgets/folder_list_skeleton.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

class Klasoricerigisayfasi extends StatefulWidget {
  const Klasoricerigisayfasi({super.key, this.folder});

  final FolderRouteData? folder;

  @override
  State<Klasoricerigisayfasi> createState() => _KlasoricerigisayfasiState();
}

class _KlasoricerigisayfasiState extends State<Klasoricerigisayfasi> {
  static const int _pageSize = 100;
  // Keep the old name as an alias so existing references compile unchanged.
  static const int _categoryPageSize = _pageSize;

  final ScrollController _scrollController = ScrollController();

  FolderNode? _folder;
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMoreCategoryItems = false;
  Object? _loadError;
  bool _didLoadInitialFolder = false;
  int _activeLoadId = 0;
  int _nextCategoryOffset = 0;
  String? _categoryProgressLabel;

  // Directory (non-virtual) pagination state
  int _visibleDirectoryFolderCount = 0;
  int _visibleDirectoryFileCount = 0;
  bool _isDirectoryLoadingMore = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_handleScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitialFolder();
    });
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_handleScroll)
      ..dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant Klasoricerigisayfasi oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.folder?.path == oldWidget.folder?.path) {
      return;
    }

    _didLoadInitialFolder = false;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitialFolder();
    });
  }

  Future<void> _loadInitialFolder() async {
    if (_didLoadInitialFolder) {
      return;
    }

    _didLoadInitialFolder = true;
    await _loadFolder();
  }

  bool get _hasMoreDirectoryItems {
    final folder = _folder;
    if (folder == null || folder.isVirtual) return false;
    return _visibleDirectoryFolderCount < folder.folderchildren.length ||
        _visibleDirectoryFileCount < folder.filechildren.length;
  }

  void _handleScroll() {
    if (!_scrollController.hasClients) return;
    if (_scrollController.position.extentAfter > 320) return;

    final folder = _folder;
    if (folder == null) return;

    if (folder.isVirtual) {
      if (!_isLoadingMore && _hasMoreCategoryItems) {
        unawaited(_loadMoreCategoryItems());
      }
    } else {
      if (!_isDirectoryLoadingMore && _hasMoreDirectoryItems) {
        unawaited(_loadMoreDirectoryItems());
      }
    }
  }

  Future<void> _loadMoreDirectoryItems() async {
    final folder = _folder;
    if (folder == null ||
        folder.isVirtual ||
        _isDirectoryLoadingMore ||
        !_hasMoreDirectoryItems) {
      return;
    }

    setState(() => _isDirectoryLoadingMore = true);

    await Future.microtask(() {
      if (!mounted || !identical(folder, _folder)) return;
      setState(() {
        int budget = _pageSize;
        final folderRemaining =
            folder.folderchildren.length - _visibleDirectoryFolderCount;
        final folderAdd = math.min(budget, folderRemaining);
        budget -= folderAdd;
        final fileAdd = math.min(
          budget,
          folder.filechildren.length - _visibleDirectoryFileCount,
        );
        _visibleDirectoryFolderCount += folderAdd;
        _visibleDirectoryFileCount += fileAdd;
        _isDirectoryLoadingMore = false;
      });
    });
  }

  FolderRouteData? _resolveRouteData() {
    final routeFolder = widget.folder;
    if (routeFolder != null) {
      return routeFolder;
    }

    final currentFolder = context.read<Izinler>().currentFolder;
    if (currentFolder == null) {
      return null;
    }

    return FolderRouteData.fromFolderNode(currentFolder);
  }

  Future<void> _loadFolder({bool forceRefresh = false}) async {
    final loadId = ++_activeLoadId;
    final routeData = _resolveRouteData();
    final targetFolder = routeData?.resolveFolderNode(
      fileTree: context.read<Izinler>().fileTree,
    );

    if (targetFolder == null) {
      if (!mounted) {
        return;
      }

      setState(() {
        _folder = null;
        _isLoading = false;
        _loadError = StateError('folder_route_not_found');
      });
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

  Future<void> _loadDirectoryFolder(
    FolderNode targetFolder, {
    required int loadId,
    required bool forceRefresh,
  }) async {
    if (!mounted) {
      return;
    }

    final isRefreshingCurrentFolder = _folder?.path == targetFolder.path;

    setState(() {
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
      }
      _isDirectoryLoadingMore = false;
    });

    _syncVisibleFolder(targetFolder);

    final result = await context.read<Izinler>().fileTree.loadFolder(
      targetFolder,
      forceRefresh: forceRefresh,
      onProgress: (_) {
        if (!mounted || loadId != _activeLoadId) {
          return;
        }

        setState(() {
          _folder = targetFolder;
          _syncDirectoryVisibleCounts(targetFolder);
        });
      },
    );

    if (!mounted || loadId != _activeLoadId) {
      return;
    }

    setState(() {
      _folder = targetFolder;
      _isLoading = false;
      _loadError = result.error;
      _syncDirectoryVisibleCounts(targetFolder);
    });

    _syncVisibleFolder(targetFolder);
  }

  void _syncDirectoryVisibleCounts(FolderNode folder) {
    if (folder.isVirtual) {
      return;
    }

    final hasExistingWindow =
        _visibleDirectoryFolderCount > 0 || _visibleDirectoryFileCount > 0;
    if (hasExistingWindow) {
      _visibleDirectoryFolderCount = math.min(
        _visibleDirectoryFolderCount,
        folder.folderchildren.length,
      );
      _visibleDirectoryFileCount = math.min(
        _visibleDirectoryFileCount,
        folder.filechildren.length,
      );
      if (_visibleDirectoryFolderCount > 0 || _visibleDirectoryFileCount > 0) {
        return;
      }
    }

    int budget = _pageSize;
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
    if (!mounted) {
      return;
    }

    setState(() {
      _folder = targetFolder;
      _isLoading = true;
      _isLoadingMore = false;
      _loadError = null;
      _hasMoreCategoryItems = false;
      _nextCategoryOffset = 0;
      _categoryProgressLabel = _buildCategoryProgressLabel(
        context,
        targetFolder,
      );
    });

    _syncVisibleFolder(targetFolder);

    try {
      final rootPath = context.read<Izinler>().fileTree.rootPath;
      final categoryRepository = context.read<CategoryRepository>();
      final readiness = await categoryRepository.ensureCategoryReady(
        rootPath: rootPath,
        categoryPath: targetFolder.path,
        forceRefresh: forceRefresh,
      );

      if (!mounted || loadId != _activeLoadId) {
        return;
      }

      final firstPage = await categoryRepository.getCategoryPage(
        categoryPath: targetFolder.path,
        limit: _categoryPageSize,
      );

      if (!mounted || loadId != _activeLoadId) {
        return;
      }

      targetFolder.replaceChildren(
        folders: const <FolderNode>[],
        files: firstPage.items.map((item) => item.toFile()).toList(),
      );

      setState(() {
        _folder = targetFolder;
        _isLoading = false;
        _loadError = null;
        _hasMoreCategoryItems = firstPage.hasMore;
        _nextCategoryOffset = firstPage.nextOffset;
        _categoryProgressLabel = null;
      });

      _syncVisibleFolder(targetFolder);

      if (readiness.needsBackgroundRefresh && !forceRefresh) {
        unawaited(_refreshCategoryInBackground(targetFolder, loadId: loadId));
      }
    } catch (error) {
      if (!mounted || loadId != _activeLoadId) {
        return;
      }

      setState(() {
        _folder = targetFolder;
        _isLoading = false;
        _loadError = error;
      });
    }
  }

  Future<void> _refreshCategoryInBackground(
    FolderNode targetFolder, {
    required int loadId,
  }) async {
    try {
      final categoryRepository = context.read<CategoryRepository>();
      final rootPath = context.read<Izinler>().fileTree.rootPath;
      await categoryRepository.refreshIndex(rootPath: rootPath);

      if (!mounted ||
          loadId != _activeLoadId ||
          _folder?.path != targetFolder.path) {
        return;
      }

      final refreshedPage = await categoryRepository.getCategoryPage(
        categoryPath: targetFolder.path,
        limit: _categoryPageSize,
      );

      if (!mounted ||
          loadId != _activeLoadId ||
          _folder?.path != targetFolder.path) {
        return;
      }

      targetFolder.replaceChildren(
        folders: const <FolderNode>[],
        files: refreshedPage.items.map((item) => item.toFile()).toList(),
      );

      setState(() {
        _folder = targetFolder;
        _hasMoreCategoryItems = refreshedPage.hasMore;
        _nextCategoryOffset = refreshedPage.nextOffset;
        _loadError = null;
      });
    } catch (_) {
      // Silent refresh should not replace visible cached results with an error state.
    }
  }

  Future<void> _loadMoreCategoryItems() async {
    final folder = _folder;
    if (folder == null ||
        !folder.isVirtual ||
        _isLoading ||
        _isLoadingMore ||
        !_hasMoreCategoryItems) {
      return;
    }

    setState(() {
      _isLoadingMore = true;
    });

    try {
      final nextPage = await context.read<CategoryRepository>().getCategoryPage(
        categoryPath: folder.path,
        offset: _nextCategoryOffset,
        limit: _categoryPageSize,
      );

      if (!mounted || !identical(folder, _folder)) {
        return;
      }

      folder.replaceChildren(
        folders: const <FolderNode>[],
        files: <File>[
          ...folder.filechildren,
          ...nextPage.items.map((item) => item.toFile()),
        ],
      );

      setState(() {
        _folder = folder;
        _hasMoreCategoryItems = nextPage.hasMore;
        _nextCategoryOffset = nextPage.nextOffset;
      });
    } catch (error) {
      if (!mounted || !identical(folder, _folder)) {
        return;
      }

      setState(() {
        _loadError = error;
      });
    } finally {
      final shouldResetLoadingMore = mounted && identical(folder, _folder);
      if (shouldResetLoadingMore) {
        setState(() {
          _isLoadingMore = false;
        });
      }
    }
  }

  String _buildCategoryProgressLabel(BuildContext context, FolderNode folder) {
    final l10n = context.l10n;
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

  void _syncVisibleFolder(FolderNode folder) {
    final izinler = context.read<Izinler>();
    if (identical(izinler.currentFolder, folder)) {
      return;
    }

    izinler.setVisibleFolder(folder);
  }

  @override
  Widget build(BuildContext context) {
    final activeFolder = _folder;
    if (activeFolder != null &&
        !identical(context.read<Izinler>().currentFolder, activeFolder)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) {
          return;
        }
        _syncVisibleFolder(activeFolder);
      });
    }

    return Selector<Altislemprovider, bool>(
      selector: (_, altIslemProvider) => altIslemProvider.anahtar,
      builder: (context, isSelectionMode, child) {
        return PopScope(
          canPop: !isSelectionMode,
          onPopInvokedWithResult: (didPop, result) {
            if (didPop || !isSelectionMode) {
              return;
            }

            context.read<Altislemprovider>().setSelectionMode(false);
            context.read<Dosyaislemleri>().clearSelection();
          },
          child: child!,
        );
      },
      child: Animate(
        effects: const [SlideEffect(begin: Offset(2, 0))],
        child: _buildBody(context),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    final l10n = context.l10n;
    final folder = _folder;

    if (_loadError != null && (folder == null || folder.childCount == 0)) {
      return _buildRefreshableState(
        context,
        child: ErrorStateWidget(
          message: l10n.errorOccurred,
          onRetry: () => _loadFolder(forceRefresh: folder?.isVirtual ?? false),
          retryLabel: l10n.tryAgain,
        ),
      );
    }

    if (folder == null) {
      return const FolderListSkeleton();
    }

    if (folder.isVirtual && _isLoading && folder.childCount == 0) {
      return _buildCategoryLoadingState(context, folder);
    }

    if (_isLoading && folder.childCount == 0) {
      return const FolderListSkeleton();
    }

    if (!_isLoading && folder.childCount == 0) {
      return _buildRefreshableState(
        context,
        child: EmptyStateWidget(message: l10n.folderEmpty),
      );
    }

    final List<FolderNode> folders;
    final List<File> files;
    final int loadingPlaceholderCount;

    if (folder.isVirtual) {
      folders = folder.folderchildren;
      files = folder.filechildren;
      loadingPlaceholderCount = _isLoadingMore ? 3 : 0;
    } else {
      folders =
          folder.folderchildren.take(_visibleDirectoryFolderCount).toList();
      files = folder.filechildren.take(_visibleDirectoryFileCount).toList();
      loadingPlaceholderCount = _isDirectoryLoadingMore ? 3 : 0;
    }

    return RefreshIndicator(
      color: Theme.of(context).primaryColor,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      onRefresh: () => _loadFolder(forceRefresh: true),
      child: ListView.builder(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: folders.length + files.length + loadingPlaceholderCount,
        itemBuilder: (context, index) {
          if (index < folders.length) {
            final childFolder = folders[index];
            return Klasor(
              key: ValueKey(childFolder.path),
              name: childFolder.name,
              path: childFolder.path,
              klasor: childFolder,
            );
          }

          final fileIndex = index - folders.length;
          if (fileIndex < files.length) {
            final file = files[fileIndex];
            return Dosya(key: ValueKey(file.path), file: file);
          }

          return const FileItemSkeleton();
        },
      ),
    );
  }

  Widget _buildCategoryLoadingState(BuildContext context, FolderNode folder) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 28, 16, 16),
      children: [
        Text(
          _categoryProgressLabel ??
              _buildCategoryProgressLabel(context, folder),
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 12),
        LinearProgressIndicator(color: Theme.of(context).primaryColor),
        const SizedBox(height: 20),
        const FolderListSkeleton(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          padding: EdgeInsets.zero,
          itemCount: 6,
        ),
      ],
    );
  }

  Widget _buildRefreshableState(BuildContext context, {required Widget child}) {
    return RefreshIndicator(
      color: Theme.of(context).primaryColor,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      onRefresh: () => _loadFolder(forceRefresh: true),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(height: MediaQuery.of(context).size.height * 0.25),
          Center(child: child),
        ],
      ),
    );
  }
}
