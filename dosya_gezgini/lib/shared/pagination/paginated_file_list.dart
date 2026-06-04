import 'dart:async';
import 'dart:io';

import 'package:dosya_gezgini/features/files/presentation/widgets/dosya_folder.dart';
import 'package:dosya_gezgini/features/files/state/folderleragaci.dart';
import 'package:dosya_gezgini/features/files/state/izinler.dart';
import 'package:dosya_gezgini/shared/pagination/paginated_controller.dart';
import 'package:dosya_gezgini/shared/widgets/file_item_skeleton.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// A self-contained paginated list of [FolderNode] and [File] items.
///
/// Renders the first [PaginatedController.pageSize] items on initial build and
/// loads the next page automatically as the user scrolls toward the bottom.
/// When [onRefresh] is provided the list is wrapped with [RefreshIndicator].
///
/// Pagination resets whenever [folders] or [files] changes (detected via
/// reference comparison in [didUpdateWidget]).
class PaginatedFileListView extends StatefulWidget {
  const PaginatedFileListView({
    super.key,
    required this.folders,
    required this.files,
    this.onRefresh,
    this.physics = const AlwaysScrollableScrollPhysics(),
  });

  final List<FolderNode> folders;
  final List<File> files;
  final Future<void> Function()? onRefresh;
  final ScrollPhysics physics;

  @override
  State<PaginatedFileListView> createState() => _PaginatedFileListViewState();
}

class _PaginatedFileListViewState extends State<PaginatedFileListView> {
  final ScrollController _scrollController = ScrollController();
  final PaginatedController _ctrl = PaginatedController();
  bool _isLoadingMore = false;

  @override
  void initState() {
    super.initState();
    _ctrl.setData(widget.folders, widget.files);
    _scrollController.addListener(_handleScroll);
    _primeVisibleFolderCounts(refresh: false);
  }

  @override
  void didUpdateWidget(PaginatedFileListView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.folders, widget.folders) ||
        !identical(oldWidget.files, widget.files)) {
      setState(() {
        _ctrl.setData(widget.folders, widget.files);
        _isLoadingMore = false;
      });
      _primeVisibleFolderCounts(refresh: true);
    }
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_handleScroll)
      ..dispose();
    super.dispose();
  }

  void _handleScroll() {
    if (!_scrollController.hasClients || _isLoadingMore || !_ctrl.hasMore) {
      return;
    }
    if (_scrollController.position.extentAfter > 320) {
      return;
    }
    unawaited(_loadMore());
  }

  Future<void> _loadMore() async {
    setState(() => _isLoadingMore = true);
    await Future.microtask(() {
      if (!mounted) return;
      setState(() {
        _ctrl.loadNextPage();
        _isLoadingMore = false;
      });
      _primeVisibleFolderCounts(refresh: false);
    });
  }

  void _primeVisibleFolderCounts({required bool refresh}) {
    unawaited(
      context.read<Izinler>().primeFolderCounts(
        _ctrl.visibleFolders,
        refresh: refresh,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final visibleFolders = _ctrl.visibleFolders;
    final visibleFiles = _ctrl.visibleFiles;
    final skeletonCount = _isLoadingMore ? 3 : 0;
    final itemCount =
        visibleFolders.length + visibleFiles.length + skeletonCount;

    Widget list = ListView.builder(
      controller: _scrollController,
      physics: widget.physics,
      itemCount: itemCount,
      itemBuilder: (context, index) {
        if (index < visibleFolders.length) {
          final folder = visibleFolders[index];
          return Klasor(
            key: ValueKey(folder.path),
            name: folder.name,
            path: folder.path,
            klasor: folder,
          );
        }

        final fileIndex = index - visibleFolders.length;
        if (fileIndex < visibleFiles.length) {
          final file = visibleFiles[fileIndex];
          return Dosya(key: ValueKey(file.path), file: file);
        }

        return const FileItemSkeleton();
      },
    );

    if (widget.onRefresh != null) {
      list = RefreshIndicator(
        color: Theme.of(context).primaryColor,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        onRefresh: widget.onRefresh!,
        child: list,
      );
    }

    return list;
  }
}
