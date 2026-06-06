class SyncedPathEntry {
  const SyncedPathEntry({
    required this.path,
    required this.isDirectory,
    required this.isAccessible,
  });

  final String path;
  final bool isDirectory;
  final bool isAccessible;
}

class FileSyncCollectionResult {
  const FileSyncCollectionResult({
    this.retainedEntries = const <SyncedPathEntry>[],
    this.removedPaths = const <String>[],
    this.invalidPaths = const <String>[],
    this.inaccessiblePaths = const <String>[],
  });

  final List<SyncedPathEntry> retainedEntries;
  final List<String> removedPaths;
  final List<String> invalidPaths;
  final List<String> inaccessiblePaths;

  bool get hasChanges => removedPaths.isNotEmpty || invalidPaths.isNotEmpty;
}

class FileSyncResult {
  const FileSyncResult({
    this.saved = const FileSyncCollectionResult(),
    this.hidden = const FileSyncCollectionResult(),
    this.recent = const FileSyncCollectionResult(),
    this.prunedDirectoryCachePaths = const <String>[],
    this.prunedFolderCountPaths = const <String>[],
    this.refreshedIndex = false,
  });

  final FileSyncCollectionResult saved;
  final FileSyncCollectionResult hidden;
  final FileSyncCollectionResult recent;
  final List<String> prunedDirectoryCachePaths;
  final List<String> prunedFolderCountPaths;
  final bool refreshedIndex;

  Set<String> get removedTrackedPaths => <String>{
    ...saved.removedPaths,
    ...hidden.removedPaths,
    ...recent.removedPaths,
  };

  Set<String> get invalidTrackedPaths => <String>{
    ...saved.invalidPaths,
    ...hidden.invalidPaths,
    ...recent.invalidPaths,
  };

  bool get hasTrackedChanges =>
      removedTrackedPaths.isNotEmpty || invalidTrackedPaths.isNotEmpty;

  int get affectedTrackedPathCount =>
      <String>{...removedTrackedPaths, ...invalidTrackedPaths}.length;
}
