import 'dart:async';
import 'dart:io';

import 'package:dosya_gezgini/core/constants/storage_paths.dart';
import 'package:dosya_gezgini/data/constants/cleaning_constants.dart';
import 'package:dosya_gezgini/data/models/cleaning_models.dart';
import 'package:dosya_gezgini/data/repositories/thumbnail_cache_repository.dart';
import 'package:dosya_gezgini/data/services/file_index_service.dart';
import 'package:dosya_gezgini/data/services/file_metadata_service.dart';
import 'package:path/path.dart' as path;
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
    bool Function()? shouldCancel,
  }) async {
    final stages = await _resolveStages();
    final candidates = <CleaningCandidate>[];
    final issues = <CleaningIssue>[];
    final summaries = <CleaningSourceSummary>[];
    final seenCandidatePaths = <String>{};
    var processedFiles = 0;
    var reclaimableBytes = 0;

    for (var stageIndex = 0; stageIndex < stages.length; stageIndex++) {
      _throwIfCancelled(shouldCancel);
      final stage = stages[stageIndex];

      onProgress?.call(
        CleaningScanProgress(
          source: stage.type,
          processedFiles: processedFiles,
          candidateCount: candidates.length,
          reclaimableBytes: reclaimableBytes,
          completedSourceCount: stageIndex,
        ),
      );

      final stageCandidates = <CleaningCandidate>[];
      final stageIssues = <CleaningIssue>[];
      var stageProcessedFiles = 0;
      var stageDetectedCount = 0;
      var stageDetectedBytes = 0;
      var stageCleanableBytes = 0;

      void emitStageProgress({String? currentPath}) {
        onProgress?.call(
          CleaningScanProgress(
            source: stage.type,
            processedFiles: processedFiles + stageProcessedFiles,
            candidateCount: candidates.length + stageCandidates.length,
            reclaimableBytes: reclaimableBytes + stageCleanableBytes,
            completedSourceCount: stageIndex,
            currentPath: currentPath,
          ),
        );
      }

      if (stage.directories.isNotEmpty) {
        for (final directory in stage.directories) {
          _throwIfCancelled(shouldCancel);
          if (!await directory.exists()) {
            continue;
          }

          await for (final entity in directory.list(
            recursive: true,
            followLinks: false,
          )) {
            _throwIfCancelled(shouldCancel);
            if (entity is! File) {
              continue;
            }

            stageProcessedFiles++;

            try {
              final resolveReason = stage.resolveReason;
              if (resolveReason == null) {
                continue;
              }

              final lastModified = await entity.lastModified();
              final fileSize = await entity.length();
              final reason = resolveReason(entity, lastModified, fileSize);

              if (reason != null) {
                stageDetectedCount++;
                stageDetectedBytes += fileSize;

                if (stage.isCleanable &&
                    seenCandidatePaths.add(entity.path)) {
                  stageCandidates.add(
                    CleaningCandidate(
                      path: entity.path,
                      sizeBytes: fileSize,
                      modifiedAt: lastModified,
                      source: stage.type,
                      reason: reason,
                    ),
                  );
                  stageCleanableBytes += fileSize;
                }
              }
            } catch (error) {
              stageIssues.add(
                CleaningIssue(
                  path: entity.path,
                  stage: CleaningIssueStage.scan,
                  message: error.toString(),
                ),
              );
            }

            if (stageProcessedFiles % CleaningConstants.scanYieldEveryFiles ==
                0) {
              emitStageProgress(currentPath: entity.path);
              await Future<void>.delayed(Duration.zero);
            }
          }
        }
      } else {
        await Future<void>.delayed(Duration.zero);
      }

      if (stage.type == CleaningSourceType.memory) {
        emitStageProgress();
      }

      processedFiles += stageProcessedFiles;
      reclaimableBytes += stageCleanableBytes;
      candidates.addAll(stageCandidates);
      issues.addAll(stageIssues);
      summaries.add(
        CleaningSourceSummary(
          source: stage.type,
          detectedItemCount: stageDetectedCount,
          detectedBytes: stageDetectedBytes,
          isCleanable: stage.isCleanable,
        ),
      );

      onProgress?.call(
        CleaningScanProgress(
          source: stage.type,
          processedFiles: processedFiles,
          candidateCount: candidates.length,
          reclaimableBytes: reclaimableBytes,
          completedSourceCount: stageIndex + 1,
        ),
      );
      await Future<void>.delayed(Duration.zero);
    }

    return CleaningScanResult(
      candidates: List<CleaningCandidate>.unmodifiable(candidates),
      totalBytes: reclaimableBytes,
      processedFiles: processedFiles,
      issues: List<CleaningIssue>.unmodifiable(issues),
      sourceSummaries: List<CleaningSourceSummary>.unmodifiable(summaries),
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

  Future<List<_CleaningStage>> _resolveStages() async {
    final temporaryDirectory = await getTemporaryDirectory();
    final cacheDirectory = await getApplicationCacheDirectory();
    final userDirectories = _resolveUserScanDirectories();

    return <_CleaningStage>[
      _CleaningStage(
        type: CleaningSourceType.cache,
        directories: <Directory>[cacheDirectory],
        isCleanable: true,
        resolveReason: (file, lastModified, fileSize) {
          return _resolveCandidateReason(
            lastModified: lastModified,
            fileSize: fileSize,
          );
        },
      ),
      _CleaningStage(
        type: CleaningSourceType.unusedFiles,
        directories: userDirectories,
        isCleanable: false,
        resolveReason: (file, lastModified, fileSize) {
          final extension = path.extension(file.path).toLowerCase();
          final isPackageFile = CleaningConstants.packageExtensions.contains(
            extension,
          );
          final isResidualFile = CleaningConstants.residualExtensions.contains(
            extension,
          );
          final isUnused =
              !isPackageFile &&
              !isResidualFile &&
              fileSize > 0 &&
              DateTime.now().difference(lastModified) >
                  CleaningConstants.unusedFileAge;
          return isUnused ? CleaningCandidateReason.stale : null;
        },
      ),
      _CleaningStage(
        type: CleaningSourceType.packages,
        directories: userDirectories,
        isCleanable: true,
        resolveReason: (file, lastModified, fileSize) {
          final extension = path.extension(file.path).toLowerCase();
          if (!CleaningConstants.packageExtensions.contains(extension)) {
            return null;
          }
          return CleaningCandidateReason.packageInstaller;
        },
      ),
      _CleaningStage(
        type: CleaningSourceType.residualFiles,
        directories: <Directory>[temporaryDirectory, ...userDirectories],
        isCleanable: true,
        resolveReason: (file, lastModified, fileSize) {
          final normalizedFilePath = file.path.toLowerCase();
          final isTemporaryFile = normalizedFilePath.startsWith(
            temporaryDirectory.path.toLowerCase(),
          );
          if (isTemporaryFile) {
            return _resolveCandidateReason(
                  lastModified: lastModified,
                  fileSize: fileSize,
                ) ??
                CleaningCandidateReason.residualJunk;
          }

          final extension = path.extension(file.path).toLowerCase();
          if (!CleaningConstants.residualExtensions.contains(extension)) {
            return null;
          }
          return CleaningCandidateReason.residualJunk;
        },
      ),
      const _CleaningStage(
        type: CleaningSourceType.memory,
        directories: <Directory>[],
        isCleanable: false,
      ),
    ];
  }

  List<Directory> _resolveUserScanDirectories() {
    final directories = <Directory>[];
    final seenPaths = <String>{};

    for (final directoryName in CleaningConstants.userScanDirectoryNames) {
      final directoryPath = path.join(storageRootPath, directoryName);
      if (seenPaths.add(directoryPath)) {
        directories.add(Directory(directoryPath));
      }
    }

    return directories;
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

  void _throwIfCancelled(bool Function()? shouldCancel) {
    if (shouldCancel?.call() ?? false) {
      throw const CleaningCancelledException();
    }
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

class _CleaningStage {
  const _CleaningStage({
    required this.type,
    required this.directories,
    required this.isCleanable,
    this.resolveReason,
  });

  final CleaningSourceType type;
  final List<Directory> directories;
  final bool isCleanable;
  final CleaningCandidateReason? Function(
    File file,
    DateTime lastModified,
    int fileSize,
  )? resolveReason;
}
