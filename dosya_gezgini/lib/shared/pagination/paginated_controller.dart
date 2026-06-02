import 'dart:io';
import 'dart:math' as math;

import 'package:dosya_gezgini/features/files/state/folderleragaci.dart';
import 'package:dosya_gezgini/shared/pagination/paginated_state.dart';

/// Manages slice-based pagination for a combined [FolderNode] + [File] list.
///
/// Folders are prioritised: each page fills folder slots first, then file
/// slots with the remaining budget.
class PaginatedController {
  static const int pageSize = 100;

  List<FolderNode> _folders = const [];
  List<File> _files = const [];
  PaginatedState _state = const PaginatedState(
    visibleFolderCount: 0,
    visibleFileCount: 0,
  );

  PaginatedState get state => _state;

  bool get hasMore =>
      _state.visibleFolderCount < _folders.length ||
      _state.visibleFileCount < _files.length;

  List<FolderNode> get visibleFolders =>
      _folders.take(_state.visibleFolderCount).toList();

  List<File> get visibleFiles =>
      _files.take(_state.visibleFileCount).toList();

  /// Replaces the data source and resets to the first page.
  void setData(List<FolderNode> folders, List<File> files) {
    _folders = folders;
    _files = files;
    _state = _buildFirstPage(folders, files);
  }

  /// Advances one page. Returns the updated [PaginatedState].
  PaginatedState loadNextPage() {
    if (!hasMore) return _state;

    int budget = pageSize;
    final folderRemaining = _folders.length - _state.visibleFolderCount;
    final folderAdd = math.min(budget, folderRemaining);
    budget -= folderAdd;
    final fileAdd = math.min(budget, _files.length - _state.visibleFileCount);

    _state = PaginatedState(
      visibleFolderCount: _state.visibleFolderCount + folderAdd,
      visibleFileCount: _state.visibleFileCount + fileAdd,
    );
    return _state;
  }

  static PaginatedState _buildFirstPage(
    List<FolderNode> folders,
    List<File> files,
  ) {
    int budget = pageSize;
    final folderTake = math.min(budget, folders.length);
    budget -= folderTake;
    final fileTake = math.min(budget, files.length);
    return PaginatedState(
      visibleFolderCount: folderTake,
      visibleFileCount: fileTake,
    );
  }
}
