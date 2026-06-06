import 'dart:async';
import 'dart:io';

import 'package:dosya_gezgini/core/constants/storage_paths.dart';
import 'package:dosya_gezgini/data/constants/cleaning_constants.dart';
import 'package:dosya_gezgini/data/models/cleaning_models.dart';
import 'package:dosya_gezgini/data/repositories/thumbnail_cache_repository.dart';
import 'package:dosya_gezgini/data/services/file_index_service.dart';
import 'package:dosya_gezgini/data/services/file_metadata_service.dart';
import 'package:path_provider/path_provider.dart';

typedef CleaningScanProgressCallback =
    void Function(CleaningScanProgress progress);
typedef CleaningDeleteProgressCallback =
    void Function(CleaningDeleteProgress progress);

class CleaningService {
  CleaningService({
    required FileIndexService fileIndexService,
    required FileMetadataService fileMetadataService,
    required ThumbnailCacheRepository thumbnailCacheRepository,
  }) : _fileIndexService = fileIndexService,
       _fileMetadataService = fileMetadataService,
       _thumbnailCacheRepository = thumbnailCacheRepository;

  final FileIndexService _fileIndexService;
  final FileMetadataService _fileMetadataService;
  final ThumbnailCacheRepository _thumbnailCacheRepository;

  Future<CleaningScanResult> scan({
    CleaningScanProgressCallback? onProgress,
  }) async {
    final sources = await _resolveSources();
    final candidates = <CleaningCandidate>[];
    final issues = <CleaningIssue>[];
    var processedFiles = 0;
    var reclaimableBytes = 0;

    for (var sourceIndex = 0; sourceIndex < sources.length; sourceIndex++) {
      final source = sources[sourceIndex];
      if (!await source.directory.exists()) {
        onProgress?.call(
          CleaningScanProgress(
            source: source.type,
            processedFiles: processedFiles,
            candidateCount: candidates.length,
            reclaimableBytes: reclaimableBytes,
            completedSourceCount: sourceIndex + 1,
          ),
        );
        continue;
      }

      await for (final entity in source.directory.list(
        recursive: true,
        followLinks: false,
      )) {
        if (entity is! File) {
          continue;
        }

        processedFiles++;

        try {
          final lastModified = await entity.lastModified();
          final fileSize = await entity.length();
          final reason = _resolveCandidateReason(
            lastModified: lastModified,
            fileSize: fileSize,
          );

          if (reason != null) {
            candidates.add(
              CleaningCandidate(
                path: entity.path,
                sizeBytes: fileSize,
                modifiedAt: lastModified,
                source: source.type,
                reason: reason,
              ),
            );
            reclaimableBytes += fileSize;
          }
        } catch (error) {
          issues.add(
            CleaningIssue(
              path: entity.path,
              stage: CleaningIssueStage.scan,
              message: error.toString(),
            ),
          );
        }

        if (processedFiles % CleaningConstants.scanYieldEveryFiles == 0) {
          onProgress?.call(
            CleaningScanProgress(
              source: source.type,
              processedFiles: processedFiles,
              candidateCount: candidates.length,
              reclaimableBytes: reclaimableBytes,
              completedSourceCount: sourceIndex,
              currentPath: entity.path,
            ),
          );
          await Future<void>.delayed(Duration.zero);
        }
      }

      onProgress?.call(
        CleaningScanProgress(
          source: source.type,
          processedFiles: processedFiles,
          candidateCount: candidates.length,
          reclaimableBytes: reclaimableBytes,
          completedSourceCount: sourceIndex + 1,
        ),
      );
      await Future<void>.delayed(Duration.zero);
    }

    return CleaningScanResult(
      candidates: List<CleaningCandidate>.unmodifiable(candidates),
      totalBytes: reclaimableBytes,
      processedFiles: processedFiles,
      issues: List<CleaningIssue>.unmodifiable(issues),
    );
  }

  Future<CleaningDeleteResult> deleteCandidates(
    List<CleaningCandidate> candidates, {
    CleaningDeleteProgressCallback? onProgress,
  }) async {
    final deletedPaths = <String>[];
    final issues = <CleaningIssue>[];
    var deletedBytes = 0;
    var deletedCount = 0;
    var failedCount = 0;

    for (var index = 0; index < candidates.length; index++) {
      final candidate = candidates[index];
      final file = File(candidate.path);

      try {
        if (!await file.exists()) {
          failedCount++;
          issues.add(
            CleaningIssue(
              path: candidate.path,
              stage: CleaningIssueStage.delete,
              message: 'source_not_found',
            ),
          );
        } else {
          await file.delete();
          deletedPaths.add(candidate.path);
          deletedBytes += candidate.sizeBytes;
          deletedCount++;
        }
      } catch (error) {
        failedCount++;
        issues.add(
          CleaningIssue(
            path: candidate.path,
            stage: CleaningIssueStage.delete,
            message: error.toString(),
          ),
        );
      }

      onProgress?.call(
        CleaningDeleteProgress(
          processedItems: index + 1,
          totalItems: candidates.length,
          deletedCount: deletedCount,
          failedCount: failedCount,
          deletedBytes: deletedBytes,
          currentPath: candidate.path,
        ),
      );

      if ((index + 1) % CleaningConstants.scanYieldEveryFiles == 0) {
        await Future<void>.delayed(Duration.zero);
      }
    }

    await _purgeThumbnailMetadata(deletedPaths);
    await _fileMetadataService.deleteMetadataForPaths(deletedPaths);
    if (deletedPaths.isNotEmpty) {
      unawaited(_fileIndexService.refreshIndex(rootPath: storageRootPath));
    }

    return CleaningDeleteResult(
      deletedPaths: List<String>.unmodifiable(deletedPaths),
      deletedBytes: deletedBytes,
      issues: List<CleaningIssue>.unmodifiable(issues),
    );
  }

  Future<List<_CleaningSource>> _resolveSources() async {
    return <_CleaningSource>[
      _CleaningSource(
        type: CleaningSourceType.temporary,
        directory: await getTemporaryDirectory(),
      ),
      _CleaningSource(
        type: CleaningSourceType.cache,
        directory: await getApplicationCacheDirectory(),
      ),
    ];
  }

  CleaningCandidateReason? _resolveCandidateReason({
    required DateTime lastModified,
    required int fileSize,
  }) {
    final isStale =
        DateTime.now().difference(lastModified) >
        CleaningConstants.staleFileAge;
    final isLarge = fileSize >= CleaningConstants.largeFileThresholdBytes;

    if (!isStale && !isLarge) {
      return null;
    }

    if (isStale && isLarge) {
      return CleaningCandidateReason.staleAndLarge;
    }

    return isStale
        ? CleaningCandidateReason.stale
        : CleaningCandidateReason.large;
  }

  Future<void> _purgeThumbnailMetadata(List<String> deletedPaths) async {
    if (deletedPaths.isEmpty) {
      return;
    }

    final deletedPathSet = deletedPaths.toSet();
    final thumbnailEntries = await _thumbnailCacheRepository.readAll();
    final sourcePathsToDelete =
        thumbnailEntries
            .where((entry) => deletedPathSet.contains(entry.thumbnailPath))
            .map((entry) => entry.sourcePath)
            .toSet();

    if (sourcePathsToDelete.isEmpty) {
      return;
    }

    await _thumbnailCacheRepository.removePaths(sourcePathsToDelete);
  }
}

class _CleaningSource {
  const _CleaningSource({required this.type, required this.directory});

  final CleaningSourceType type;
  final Directory directory;
}
