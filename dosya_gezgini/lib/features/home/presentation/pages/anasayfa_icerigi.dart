import 'dart:math' as math;

import 'package:dosya_gezgini/app/router/app_router.dart';
import 'package:dosya_gezgini/core/localization/l10n_extensions.dart';
import 'package:dosya_gezgini/features/files/presentation/models/folder_route_data.dart';
import 'package:dosya_gezgini/features/files/presentation/widgets/dosya_folder.dart';
import 'package:dosya_gezgini/features/files/state/folderleragaci.dart';
import 'package:dosya_gezgini/features/files/state/izinler.dart';
import 'package:dosya_gezgini/shared/pagination/paginated_controller.dart';
import 'package:dosya_gezgini/shared/widgets/app_skeleton.dart';
import 'package:dosya_gezgini/shared/widgets/category_grid_skeleton.dart';
import 'package:dosya_gezgini/shared/widgets/empty_state_widget.dart';
import 'package:dosya_gezgini/shared/widgets/error_state_widget.dart';
import 'package:dosya_gezgini/shared/widgets/file_item_skeleton.dart';
import 'package:dosya_gezgini/shared/widgets/folder_list_skeleton.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class Anasayfaicerigi extends StatefulWidget {
  const Anasayfaicerigi({super.key});

  @override
  State<Anasayfaicerigi> createState() => _AnasayfaicerigiState();
}

class _AnasayfaicerigiState extends State<Anasayfaicerigi> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_handleScroll);
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_handleScroll)
      ..dispose();
    super.dispose();
  }

  void _handleScroll() {
    if (!_scrollController.hasClients) return;
    if (_scrollController.position.extentAfter > 320) return;
    _recentSectionKey.currentState?.loadMore();
  }

  final GlobalKey<_PaginatedRecentSectionState> _recentSectionKey =
      GlobalKey<_PaginatedRecentSectionState>();

  Future<void> _requestPermission(BuildContext context) async {
    await context.read<Izinler>().requestAllStoragePermission();
  }

  void _openFolder(BuildContext context, FolderNode targetFolder) {
    final destination =
        targetFolder.isVirtual
            ? Paths.categoryContentLocation(targetFolder.path)
            : Paths.homeFolderContentLocation(targetFolder.path);
    final currentLocation = GoRouterState.of(context).uri.toString();

    if (currentLocation == destination) {
      return;
    }

    context.push(
      destination,
      extra: FolderRouteData.fromFolderNode(targetFolder),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final appTheme = Theme.of(context);
    return Selector<Izinler, ({bool isReady, bool hasPermission})>(
      selector:
          (_, izinler) => (
            isReady: izinler.isPermissionStateReady,
            hasPermission: izinler.hasStoragePermission,
          ),
      builder: (context, permissionState, _) {
        if (!permissionState.isReady) {
          return const _HomeLoadingView();
        }

        if (!permissionState.hasPermission) {
          return ErrorStateWidget(
            message: l10n.errorOccurred,
            onRetry: () => _requestPermission(context),
            retryLabel: l10n.tryAgain,
          );
        }

        final fileTree = context.read<Izinler>().fileTree;

        return Animate(
          effects: const [SlideEffect(begin: Offset(2, 0))],
          child: ListView(
            controller: _scrollController,
            padding: const EdgeInsets.only(bottom: 24),
            children: [
              Padding(
                padding: const EdgeInsets.all(15),
                child: Center(
                  child: Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 3,
                    runSpacing: 3,
                    children: [
                      _categoryIcon(
                        'assets/file.png',
                        l10n.categoryFiles,
                        fileTree.bilinmeyendosya,
                        context,
                      ),
                      _categoryIcon(
                        'assets/xls.png',
                        l10n.categoryExcel,
                        fileTree.exceldosya,
                        context,
                      ),
                      _categoryIcon(
                        'assets/image.png',
                        l10n.categoryImages,
                        fileTree.resimdosya,
                        context,
                      ),
                      _categoryIcon(
                        'assets/mp4.png',
                        l10n.categoryVideos,
                        fileTree.videodosya,
                        context,
                      ),
                      _categoryIcon(
                        'assets/mp3.png',
                        l10n.categoryAudio,
                        fileTree.sesdosya,
                        context,
                      ),
                      _categoryIcon(
                        'assets/doc.png',
                        l10n.categoryWord,
                        fileTree.worddosya,
                        context,
                      ),
                      _categoryIcon(
                        'assets/ppt.png',
                        l10n.categoryPowerPoint,
                        fileTree.powerpointdosya,
                        context,
                      ),
                      _categoryIcon(
                        'assets/zip.png',
                        l10n.categoryArchives,
                        fileTree.zipdosya,
                        context,
                      ),
                      _categoryIcon(
                        'assets/pdf.png',
                        l10n.categoryPdf,
                        fileTree.pdfdosya,
                        context,
                      ),
                      _categoryIcon(
                        'assets/txt.png',
                        l10n.categoryText,
                        fileTree.txtdosya,
                        context,
                      ),
                    ],
                  ),
                ),
              ),
              Center(
                child: Container(
                  width: MediaQuery.of(context).size.width - 50,
                  height: 60,
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        width: 0.3,
                        color: appTheme.iconTheme.color!,
                      ),
                    ),
                  ),
                  child: Text(
                    l10n.recentlyVisited,
                    style: appTheme.textTheme.bodyLarge,
                  ),
                ),
              ),
              Selector<Izinler, FolderFileEntries>(
                selector: (_, izinler) => izinler.recentEntries,
                builder: (context, entries, _) {
                  if (entries.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 48,
                      ),
                      child: EmptyStateWidget(
                        message: l10n.noOpenedFolder,
                        icon: Icons.history_toggle_off_rounded,
                      ),
                    );
                  }

                  return _PaginatedRecentSection(
                    key: _recentSectionKey,
                    entries: entries,
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  GestureDetector _categoryIcon(
    String imagePath,
    String label,
    FolderNode targetFolder,
    BuildContext context,
  ) {
    return GestureDetector(
      onTap: () => _openFolder(context, targetFolder),
      child: SizedBox(
        width: 80,
        height: 100,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Image.asset(imagePath, width: 50, height: 50),
                Text(label),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Paginated column of recently visited folders and files.
///
/// Shows the first [PaginatedController.pageSize] items immediately. The
/// parent's [ScrollController] signals when to load the next page via
/// [loadMore].
class _PaginatedRecentSection extends StatefulWidget {
  const _PaginatedRecentSection({super.key, required this.entries});

  final FolderFileEntries entries;

  @override
  State<_PaginatedRecentSection> createState() =>
      _PaginatedRecentSectionState();
}

class _PaginatedRecentSectionState extends State<_PaginatedRecentSection> {
  int _visibleFolderCount = 0;
  int _visibleFileCount = 0;

  @override
  void initState() {
    super.initState();
    _resetPagination();
  }

  @override
  void didUpdateWidget(_PaginatedRecentSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.entries.folders, widget.entries.folders) ||
        !identical(oldWidget.entries.files, widget.entries.files)) {
      _resetPagination();
    }
  }

  void _resetPagination() {
    const ps = PaginatedController.pageSize;
    final allFolders = widget.entries.folders;
    final allFiles = widget.entries.files;
    int budget = math.min(ps, allFolders.length + allFiles.length);
    final fTake = math.min(budget, allFolders.length);
    budget -= fTake;
    final fileTake = math.min(budget, allFiles.length);
    setState(() {
      _visibleFolderCount = fTake;
      _visibleFileCount = fileTake;
    });
  }

  bool get _hasMore =>
      _visibleFolderCount < widget.entries.folders.length ||
      _visibleFileCount < widget.entries.files.length;

  void loadMore() {
    if (!_hasMore || !mounted) return;
    setState(() {
      const budget = PaginatedController.pageSize;
      final folderRemaining =
          widget.entries.folders.length - _visibleFolderCount;
      final folderAdd = math.min(budget, folderRemaining);
      final fileAdd = math.min(
        budget - folderAdd,
        widget.entries.files.length - _visibleFileCount,
      );
      _visibleFolderCount += folderAdd;
      _visibleFileCount += fileAdd;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final visibleFolders =
        widget.entries.folders.take(_visibleFolderCount).toList();
    final visibleFiles = widget.entries.files.take(_visibleFileCount).toList();

    return Column(
      children: [
        for (final folder in visibleFolders)
          Klasor(
            key: ValueKey(folder.path),
            name: folder.name,
            path: folder.path,
            klasor: folder,
          ),
        for (final file in visibleFiles)
          Dosya(key: ValueKey(file.path), file: file),
        if (_hasMore)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: FileItemSkeleton(),
          )
        else
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Center(child: Text(l10n.listEnd)),
          ),
      ],
    );
  }
}

class _HomeLoadingView extends StatelessWidget {
  const _HomeLoadingView();

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 24),
      children: const [
        CategoryGridSkeleton(),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          child: AppSkeleton(height: 18, width: 180),
        ),
        SizedBox(height: 8),
        FolderListSkeleton(
          itemCount: 4,
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
        ),
      ],
    );
  }
}
