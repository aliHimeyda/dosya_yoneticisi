import 'dart:io';
import 'dart:math' as math;

import 'package:dosya_gezgini/app/router/app_router.dart';
import 'package:dosya_gezgini/features/files/presentation/models/folder_route_data.dart';
import 'package:dosya_gezgini/features/files/state/folderleragaci.dart';
import 'package:dosya_gezgini/features/files/state/izinler.dart';
import 'package:dosya_gezgini/shared/pagination/paginated_controller.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AnasayfaIcerigiProvider extends ChangeNotifier {
  AnasayfaIcerigiProvider({required Izinler izinler}) : _izinler = izinler {
    _scrollController.addListener(_handleScroll);
    _recentSignature = _buildRecentSignature();
    _resetRecentPagination(notify: false);
    _izinler.addListener(_handleIzinlerChanged);
  }

  final Izinler _izinler;
  final ScrollController _scrollController = ScrollController();

  int _visibleRecentFolderCount = 0;
  int _visibleRecentFileCount = 0;
  String _recentSignature = '';
  bool _isDisposed = false;

  ScrollController get scrollController => _scrollController;
  bool get isPermissionReady => _izinler.isPermissionStateReady;
  bool get hasStoragePermission => _izinler.hasStoragePermission;
  FileTree get fileTree => _izinler.fileTree;
  FolderFileEntries get recentEntries => _izinler.recentEntries;

  List<FolderNode> get visibleRecentFolders =>
      recentEntries.folders.take(_visibleRecentFolderCount).toList();

  List<File> get visibleRecentFiles =>
      recentEntries.files.take(_visibleRecentFileCount).toList();

  bool get hasMoreRecent =>
      _visibleRecentFolderCount < recentEntries.folders.length ||
      _visibleRecentFileCount < recentEntries.files.length;

  bool get hasRecentEntries => !recentEntries.isEmpty;

  Future<void> requestPermission() async {
    await _izinler.requestAllStoragePermission();
  }

  void openFolder(BuildContext context, FolderNode targetFolder) {
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

  void loadMoreRecentItems() {
    if (!hasMoreRecent) {
      return;
    }

    const budget = PaginatedController.pageSize;
    final folderRemaining =
        recentEntries.folders.length - _visibleRecentFolderCount;
    final folderAdd = math.min(budget, folderRemaining);
    final fileAdd = math.min(
      budget - folderAdd,
      recentEntries.files.length - _visibleRecentFileCount,
    );
    _visibleRecentFolderCount += folderAdd;
    _visibleRecentFileCount += fileAdd;
    _notifySafely();
  }

  @override
  void dispose() {
    _isDisposed = true;
    _izinler.removeListener(_handleIzinlerChanged);
    _scrollController
      ..removeListener(_handleScroll)
      ..dispose();
    super.dispose();
  }

  void _handleScroll() {
    if (!_scrollController.hasClients) {
      return;
    }

    if (_scrollController.position.extentAfter > 320) {
      return;
    }

    loadMoreRecentItems();
  }

  void _handleIzinlerChanged() {
    final nextSignature = _buildRecentSignature();
    if (nextSignature != _recentSignature) {
      _recentSignature = nextSignature;
      _resetRecentPagination(notify: false);
    }

    _notifySafely();
  }

  String _buildRecentSignature() {
    final folders = _izinler.fileTree.ensongezilenfolders;
    final files = _izinler.fileTree.ensongezilenfiles;
    final folderPaths = folders.map((item) => item.path).join('|');
    final filePaths = files.map((item) => item.path).join('|');
    return '$folderPaths::$filePaths';
  }

  void _resetRecentPagination({bool notify = true}) {
    const pageSize = PaginatedController.pageSize;
    final allFolders = recentEntries.folders;
    final allFiles = recentEntries.files;
    int budget = math.min(pageSize, allFolders.length + allFiles.length);
    final visibleFolderCount = math.min(budget, allFolders.length);
    budget -= visibleFolderCount;
    final visibleFileCount = math.min(budget, allFiles.length);
    _visibleRecentFolderCount = visibleFolderCount;
    _visibleRecentFileCount = visibleFileCount;
    if (notify) {
      _notifySafely();
    }
  }

  void _notifySafely() {
    if (_isDisposed) {
      return;
    }

    notifyListeners();
  }
}
