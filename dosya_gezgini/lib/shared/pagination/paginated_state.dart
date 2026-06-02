import 'package:flutter/foundation.dart';

/// Immutable snapshot of pagination progress for a combined folder + file list.
@immutable
class PaginatedState {
  const PaginatedState({
    required this.visibleFolderCount,
    required this.visibleFileCount,
    this.isLoadingMore = false,
  });

  final int visibleFolderCount;
  final int visibleFileCount;
  final bool isLoadingMore;

  int get totalVisible => visibleFolderCount + visibleFileCount;

  PaginatedState copyWith({
    int? visibleFolderCount,
    int? visibleFileCount,
    bool? isLoadingMore,
  }) {
    return PaginatedState(
      visibleFolderCount: visibleFolderCount ?? this.visibleFolderCount,
      visibleFileCount: visibleFileCount ?? this.visibleFileCount,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    );
  }
}
