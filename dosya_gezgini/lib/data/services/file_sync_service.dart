import 'package:dosya_gezgini/data/models/file_access_result.dart';
import 'package:dosya_gezgini/data/models/file_sync_models.dart';
import 'package:dosya_gezgini/data/repositories/directory_cache_repository.dart';
import 'package:dosya_gezgini/data/repositories/folder_count_repository.dart';
import 'package:dosya_gezgini/data/repositories/hidden_repository.dart';
import 'package:dosya_gezgini/data/repositories/recent_repository.dart';
import 'package:dosya_gezgini/data/repositories/saved_repository.dart';
import 'package:dosya_gezgini/data/services/file_access_service.dart';
import 'package:dosya_gezgini/data/services/file_index_service.dart';
import 'package:dosya_gezgini/data/services/file_metadata_service.dart';
import 'package:flutter/foundation.dart';

class FileSyncService {
  FileSyncService({
    required FileAccessService fileAccessService,
    required SavedRepository savedRepository,
    required HiddenRepository hiddenRepository,
    required RecentRepository recentRepository,
    required DirectoryCacheRepository directoryCacheRepository,
    required FileMetadataService fileMetadataService,
    required FolderCountRepository folderCountRepository,
    required FileIndexService fileIndexService,
  }) : _fileAccessService = fileAccessService,
       _savedRepository = savedRepository,
       _hiddenRepository = hiddenRepository,
       _recentRepository = recentRepository,
       _directoryCacheRepository = directoryCacheRepository,
       _fileMetadataService = fileMetadataService,
       _folderCountRepository = folderCountRepository,
       _fileIndexService = fileIndexService;

  final FileAccessService _fileAccessService;
  final SavedRepository _savedRepository;
  final HiddenRepository _hiddenRepository;
  final RecentRepository _recentRepository;
  final DirectoryCacheRepository _directoryCacheRepository;
  final FileMetadataService _fileMetadataService;
  final FolderCountRepository _folderCountRepository;
  final FileIndexService _fileIndexService;

  Future<FileSyncResult> syncAll({
    required String rootPath,
    bool refreshIndex = false,
  }) async {
    final runContext = _FileSyncRunContext();
    final saved = await _syncSaved(runContext: runContext);
    final hidden = await _syncHidden(runContext: runContext);
    final recent = await _syncRecent(runContext: runContext);
    final prunedDirectoryCachePaths = await _pruneDirectoryCaches(
      runContext: runContext,
    );
    await _fileMetadataService.pruneMissingPaths();
    final prunedFolderCountPaths = await _pruneFolderCounts(
      runContext: runContext,
    );

    var refreshedIndex = false;
    final shouldRefreshIndex =
        refreshIndex ||
        saved.hasChanges ||
        hidden.hasChanges ||
        recent.hasChanges;
    if (shouldRefreshIndex) {
      try {
        await _fileIndexService.refreshIndex(rootPath: rootPath);
        refreshedIndex = true;
      } catch (error) {
        debugPrint('File sync index refresh failed: $error');
      }
    }

    return FileSyncResult(
      saved: saved,
      hidden: hidden,
      recent: recent,
      prunedDirectoryCachePaths: prunedDirectoryCachePaths,
      prunedFolderCountPaths: prunedFolderCountPaths,
      refreshedIndex: refreshedIndex,
    );
  }

  Future<FileSyncCollectionResult> syncSaved() async {
    return _syncSaved(runContext: _FileSyncRunContext());
  }

  Future<FileSyncCollectionResult> _syncSaved({
    required _FileSyncRunContext runContext,
  }) async {
    return _syncTrackedCollection(
      items: await _savedRepository.readAll(),
      removePaths: _savedRepository.removePaths,
      runContext: runContext,
    );
  }

  Future<FileSyncCollectionResult> syncHidden() async {
    return _syncHidden(runContext: _FileSyncRunContext());
  }

  Future<FileSyncCollectionResult> _syncHidden({
    required _FileSyncRunContext runContext,
  }) async {
    return _syncTrackedCollection(
      items: await _hiddenRepository.readAll(),
      removePaths: _hiddenRepository.removePaths,
      runContext: runContext,
    );
  }

  Future<FileSyncCollectionResult> syncRecent() async {
    return _syncRecent(runContext: _FileSyncRunContext());
  }

  Future<FileSyncCollectionResult> _syncRecent({
    required _FileSyncRunContext runContext,
  }) async {
    return _syncTrackedCollection(
      items: await _recentRepository.readAll(),
      removePaths: _recentRepository.removePaths,
      runContext: runContext,
    );
  }

  Future<FileSyncCollectionResult> _syncTrackedCollection({
    required Iterable<dynamic> items,
    required Future<void> Function(Iterable<String>) removePaths,
    required _FileSyncRunContext runContext,
  }) async {
    final retainedEntries = <SyncedPathEntry>[];
    final removedPaths = <String>[];
    final invalidPaths = <String>[];
    final inaccessiblePaths = <String>[];

    for (final item in items) {
      final rawPath = (item.path as String?) ?? '';
      final normalizedPath = rawPath.trim();
      final isDirectory = item.isDirectory as bool? ?? false;

      if (normalizedPath.isEmpty) {
        invalidPaths.add(rawPath);
        continue;
      }

      final accessResult = await _validateTrackedPath(
        normalizedPath,
        isDirectory: isDirectory,
        runContext: runContext,
      );

      if (accessResult.shouldPruneCaches) {
        if (accessResult.issueCode == FileAccessIssueCode.deleted) {
          removedPaths.add(normalizedPath);
        }
        invalidPaths.add(normalizedPath);
        continue;
      }

      if (!accessResult.isAccessible) {
        inaccessiblePaths.add(normalizedPath);
      }

      retainedEntries.add(
        SyncedPathEntry(
          path: normalizedPath,
          isDirectory: isDirectory,
          isAccessible: accessResult.isAccessible,
        ),
      );
    }

    final pathsToRemove = <String>{...removedPaths, ...invalidPaths};
    if (pathsToRemove.isNotEmpty) {
      await removePaths(pathsToRemove);
    }

    return FileSyncCollectionResult(
      retainedEntries: List<SyncedPathEntry>.unmodifiable(retainedEntries),
      removedPaths: List<String>.unmodifiable(removedPaths),
      invalidPaths: List<String>.unmodifiable(invalidPaths),
      inaccessiblePaths: List<String>.unmodifiable(inaccessiblePaths),
    );
  }

  Future<List<String>> _pruneDirectoryCaches({
    required _FileSyncRunContext runContext,
  }) async {
    final cachedItems = await _directoryCacheRepository.readAll();
    final prunedPaths = <String>[];

    for (final item in cachedItems) {
      final normalizedPath = item.path.trim();
      if (normalizedPath.isEmpty) {
        prunedPaths.add(item.path);
        continue;
      }

      final accessResult = await _validateTrackedPath(
        normalizedPath,
        isDirectory: true,
        runContext: runContext,
      );
      if (accessResult.shouldPruneCaches) {
        prunedPaths.add(normalizedPath);
      }
    }

    if (prunedPaths.isNotEmpty) {
      await _directoryCacheRepository.removePaths(prunedPaths);
    }

    return List<String>.unmodifiable(prunedPaths);
  }

  Future<List<String>> _pruneFolderCounts({
    required _FileSyncRunContext runContext,
  }) async {
    final cachedItems = await _folderCountRepository.readAll();
    final prunedPaths = <String>[];

    for (final item in cachedItems) {
      final normalizedPath = item.path.trim();
      if (normalizedPath.isEmpty) {
        prunedPaths.add(item.path);
        continue;
      }

      final accessResult = await _validateTrackedPath(
        normalizedPath,
        isDirectory: true,
        runContext: runContext,
      );
      if (accessResult.shouldPruneCaches) {
        prunedPaths.add(normalizedPath);
      }
    }

    if (prunedPaths.isNotEmpty) {
      await _folderCountRepository.removePaths(prunedPaths);
    }

    return List<String>.unmodifiable(prunedPaths);
  }
  Future<FileAccessResult> _validateTrackedPath(
    String path, {
    required bool isDirectory,
    required _FileSyncRunContext runContext,
  }) async {
    final cacheKey = '$isDirectory|$path';
    final cachedResult = runContext.validationCache[cacheKey];
    if (cachedResult != null) {
      return cachedResult;
    }

    final result =
        isDirectory
            ? await _fileAccessService.validateDirectory(path)
            : await _fileAccessService.validateFile(path);
    runContext.validationCache[cacheKey] = result;
    return result;
  }
}

class _FileSyncRunContext {
  final Map<String, FileAccessResult> validationCache =
      <String, FileAccessResult>{};
}
