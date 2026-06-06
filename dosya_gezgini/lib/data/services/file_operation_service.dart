import 'dart:io';

import 'package:disk_space_2/disk_space_2.dart';
import 'package:dosya_gezgini/data/models/file_access_result.dart';
import 'package:dosya_gezgini/data/models/file_operation_models.dart';
import 'package:dosya_gezgini/data/services/file_access_service.dart';
import 'package:path/path.dart' as pathinfo;

typedef FileConflictResolver =
    Future<FileConflictResolution> Function(FileConflictRequest request);
typedef FileOperationProgressCallback =
    void Function(FileOperationProgress progress);

class FileOperationService {
  FileOperationService({required FileAccessService fileAccessService})
    : _fileAccessService = fileAccessService;

  static const _backupMarker = '.__dg_backup__';
  static const _invalidNamePattern = r'[<>:"/\\|?*\x00-\x1F]';

  final FileAccessService _fileAccessService;

  Future<FileCreateResult> createFolder({
    required String parentDirectoryPath,
    required String folderName,
  }) async {
    if (!_isValidName(folderName)) {
      return const FileCreateResult(
        errorCode: FileOperationErrorCodes.invalidName,
      );
    }

    final parentError = await _validateDirectoryPathForWrite(
      parentDirectoryPath,
    );
    if (parentError != null) {
      return FileCreateResult(errorCode: parentError);
    }

    final targetPath = pathinfo.join(parentDirectoryPath, folderName.trim());
    final impactedDirectoryPaths = <String>{parentDirectoryPath};
    if (await _pathExists(targetPath)) {
      return FileCreateResult(
        errorCode: FileOperationErrorCodes.alreadyExists,
        impactedDirectoryPaths: impactedDirectoryPaths,
      );
    }

    final targetDirectory = Directory(targetPath);
    var created = false;
    try {
      await targetDirectory.create(recursive: false);
      created = await targetDirectory.exists();
      if (!created) {
        throw FileSystemException('create_verification_failed');
      }

      return FileCreateResult(
        createdPath: targetDirectory.path,
        impactedDirectoryPaths: impactedDirectoryPaths,
      );
    } catch (error) {
      if (created || await targetDirectory.exists()) {
        final rollbackSucceeded = await _deleteIfExists(
          path: targetPath,
          isDirectory: true,
        );
        return FileCreateResult(
          errorCode:
              rollbackSucceeded
                  ? FileOperationErrorCodes.rolledBack
                  : FileOperationErrorCodes.rollbackFailed,
          impactedDirectoryPaths: impactedDirectoryPaths,
        );
      }

      return FileCreateResult(
        errorCode: _mapExceptionToErrorCode(
          error,
          defaultCode: FileOperationErrorCodes.conflict,
          prefersParentMissing: true,
        ),
        impactedDirectoryPaths: impactedDirectoryPaths,
      );
    }
  }

  Future<FileRenameResult> renameEntry({
    required String sourcePath,
    required String newName,
  }) async {
    final trimmedName = newName.trim();
    if (!_isValidName(trimmedName)) {
      return FileRenameResult(
        oldPath: sourcePath,
        newPath: null,
        isDirectory: await FileSystemEntity.isDirectory(sourcePath),
        errorCode: FileOperationErrorCodes.invalidName,
      );
    }

    final sourceValidation = await _validateRenameSource(sourcePath);
    if (!sourceValidation.isSuccess || sourceValidation.value == null) {
      return FileRenameResult(
        oldPath: sourcePath,
        newPath: null,
        isDirectory: sourceValidation.inferredIsDirectory,
        errorCode: sourceValidation.errorCode,
      );
    }

    final validatedEntry = sourceValidation.value!;
    final parentPath = pathinfo.dirname(sourcePath);
    final targetPath = pathinfo.join(parentPath, trimmedName);
    final impactedDirectoryPaths = <String>{parentPath};

    if (_normalizePath(sourcePath) == _normalizePath(targetPath)) {
      return FileRenameResult(
        oldPath: sourcePath,
        newPath: sourcePath,
        isDirectory: validatedEntry.entry.isDirectory,
        impactedDirectoryPaths: impactedDirectoryPaths,
      );
    }

    if (await _pathExists(targetPath)) {
      return FileRenameResult(
        oldPath: sourcePath,
        newPath: null,
        isDirectory: validatedEntry.entry.isDirectory,
        errorCode: FileOperationErrorCodes.alreadyExists,
        impactedDirectoryPaths: impactedDirectoryPaths,
      );
    }

    try {
      final renamedEntity = await validatedEntry.entity.rename(targetPath);
      if (!await _pathExists(targetPath)) {
        throw FileSystemException('rename_verification_failed');
      }

      return FileRenameResult(
        oldPath: sourcePath,
        newPath: renamedEntity.path,
        isDirectory: validatedEntry.entry.isDirectory,
        impactedDirectoryPaths: impactedDirectoryPaths,
      );
    } catch (error) {
      final sourceStillExists = await _pathExists(sourcePath);
      final targetExists = await _pathExists(targetPath);
      if (!sourceStillExists && targetExists) {
        final rollbackSucceeded = await _rollbackRename(
          sourcePath: sourcePath,
          targetPath: targetPath,
          isDirectory: validatedEntry.entry.isDirectory,
        );

        return FileRenameResult(
          oldPath: sourcePath,
          newPath: null,
          isDirectory: validatedEntry.entry.isDirectory,
          errorCode:
              rollbackSucceeded
                  ? FileOperationErrorCodes.rolledBack
                  : FileOperationErrorCodes.rollbackFailed,
          impactedDirectoryPaths: impactedDirectoryPaths,
        );
      }

      return FileRenameResult(
        oldPath: sourcePath,
        newPath: null,
        isDirectory: validatedEntry.entry.isDirectory,
        errorCode: _mapExceptionToErrorCode(
          error,
          defaultCode: FileOperationErrorCodes.conflict,
          prefersSourceMissing: true,
        ),
        impactedDirectoryPaths: impactedDirectoryPaths,
      );
    }
  }

  Future<FileOperationResult> deleteEntries(
    List<FileOperationEntry> entries, {
    FileOperationProgressCallback? onProgress,
  }) async {
    final normalizedEntries = _collapseNestedEntries(entries);
    final removedPaths = <String>[];
    final skippedPaths = <String>[];
    final failures = <FileOperationFailure>[];
    final impactedDirectoryPaths = <String>{};

    for (var index = 0; index < normalizedEntries.length; index++) {
      final entry = normalizedEntries[index];
      onProgress?.call(
        FileOperationProgress(
          operationType: FileOperationType.delete,
          processedItems: index,
          totalItems: normalizedEntries.length,
          currentPath: entry.path,
        ),
      );

      impactedDirectoryPaths.add(pathinfo.dirname(entry.path));

      final validation = await _validateSourceEntry(
        entry,
        requireParentWrite: true,
      );
      if (!validation.isSuccess || validation.value == null) {
        if (validation.errorCode == FileOperationErrorCodes.sourceNotFound) {
          skippedPaths.add(entry.path);
        } else {
          failures.add(
            FileOperationFailure(
              path: entry.path,
              errorCode:
                  validation.errorCode ?? FileOperationErrorCodes.conflict,
            ),
          );
        }
        continue;
      }

      try {
        await validation.value!.entity.delete(recursive: true);
        removedPaths.add(entry.path);
      } catch (error) {
        failures.add(
          FileOperationFailure(
            path: entry.path,
            errorCode: _mapExceptionToErrorCode(
              error,
              defaultCode: FileOperationErrorCodes.conflict,
              prefersSourceMissing: true,
            ),
            details: error,
          ),
        );
      }
    }

    onProgress?.call(
      FileOperationProgress(
        operationType: FileOperationType.delete,
        processedItems: normalizedEntries.length,
        totalItems: normalizedEntries.length,
      ),
    );

    return FileOperationResult(
      removedPaths: removedPaths,
      skippedPaths: skippedPaths,
      failures: failures,
      impactedDirectoryPaths: impactedDirectoryPaths,
    );
  }

  Future<FileOperationResult> pasteEntries({
    required List<FileOperationEntry> entries,
    required ClipboardOperation mode,
    required String destinationDirectoryPath,
    required FileConflictResolver onConflict,
    FileOperationProgressCallback? onProgress,
  }) async {
    final normalizedEntries = _collapseNestedEntries(entries);
    final destinationError = await _validateDirectoryPathForWrite(
      destinationDirectoryPath,
    );
    if (destinationError != null) {
      return FileOperationResult(
        failures: <FileOperationFailure>[
          FileOperationFailure(
            path: destinationDirectoryPath,
            errorCode: destinationError,
          ),
        ],
        impactedDirectoryPaths: <String>{destinationDirectoryPath},
      );
    }

    final createdPaths = <String>[];
    final removedPaths = <String>[];
    final skippedPaths = <String>[];
    final failures = <FileOperationFailure>[];
    final impactedDirectoryPaths = <String>{destinationDirectoryPath};
    final validatedEntries = <_ValidatedEntry>[];

    for (final entry in normalizedEntries) {
      final validation = await _validateSourceEntry(
        entry,
        requireParentWrite: mode == ClipboardOperation.cut,
      );
      if (!validation.isSuccess || validation.value == null) {
        final errorCode =
            validation.errorCode ?? FileOperationErrorCodes.conflict;
        if (errorCode == FileOperationErrorCodes.sourceNotFound) {
          skippedPaths.add(entry.path);
        } else {
          failures.add(
            FileOperationFailure(path: entry.path, errorCode: errorCode),
          );
        }
        continue;
      }

      validatedEntries.add(validation.value!);
      impactedDirectoryPaths.add(pathinfo.dirname(entry.path));
    }

    if (validatedEntries.isEmpty) {
      return FileOperationResult(
        createdPaths: createdPaths,
        removedPaths: removedPaths,
        skippedPaths: skippedPaths,
        failures: failures,
        impactedDirectoryPaths: impactedDirectoryPaths,
      );
    }

    final requiredBytes = await _calculateTotalSize(
      validatedEntries.map((item) => item.entry).toList(growable: false),
    );
    final hasEnoughSpace = await _hasEnoughSpace(requiredBytes);
    if (!hasEnoughSpace) {
      failures.add(
        const FileOperationFailure(
          path: '',
          errorCode: FileOperationErrorCodes.insufficientSpace,
        ),
      );
      return FileOperationResult(
        createdPaths: createdPaths,
        removedPaths: removedPaths,
        skippedPaths: skippedPaths,
        failures: failures,
        impactedDirectoryPaths: impactedDirectoryPaths,
      );
    }

    for (var index = 0; index < validatedEntries.length; index++) {
      final validatedEntry = validatedEntries[index];
      final entry = validatedEntry.entry;
      final sourceEntity = validatedEntry.entity;

      onProgress?.call(
        FileOperationProgress(
          operationType:
              mode == ClipboardOperation.cut
                  ? FileOperationType.move
                  : FileOperationType.copy,
          processedItems: index,
          totalItems: validatedEntries.length,
          currentPath: entry.path,
        ),
      );

      final baseDestinationPath = pathinfo.join(
        destinationDirectoryPath,
        entry.name,
      );

      final resolvedDestination = await _resolveDestinationPath(
        entry: entry,
        baseDestinationPath: baseDestinationPath,
        mode: mode,
        onConflict: onConflict,
      );

      if (resolvedDestination.cancelled) {
        return FileOperationResult(
          createdPaths: createdPaths,
          removedPaths: removedPaths,
          skippedPaths: skippedPaths,
          failures: failures,
          impactedDirectoryPaths: impactedDirectoryPaths,
          cancelled: true,
        );
      }

      final destinationPath = resolvedDestination.path;
      if (destinationPath == null) {
        skippedPaths.add(entry.path);
        continue;
      }

      if (entry.isDirectory &&
          _isNestedPath(
            sourcePath: entry.path,
            candidatePath: destinationPath,
          )) {
        failures.add(
          FileOperationFailure(
            path: entry.path,
            errorCode: FileOperationErrorCodes.destinationInSource,
          ),
        );
        continue;
      }

      _OverwriteBackup? overwriteBackup;
      var mutationStarted = false;

      try {
        if (resolvedDestination.overwriteExisting) {
          final backupResult = await _backupExistingDestination(
            destinationPath,
          );
          if (!backupResult.isSuccess) {
            failures.add(
              FileOperationFailure(
                path: entry.path,
                errorCode:
                    backupResult.errorCode ?? FileOperationErrorCodes.conflict,
              ),
            );
            continue;
          }
          overwriteBackup = backupResult.value;
          mutationStarted = overwriteBackup != null;
        }

        final copiedEntity = await _copyEntry(
          entry: entry,
          sourceEntity: sourceEntity,
          destinationPath: destinationPath,
        );
        mutationStarted = true;

        final isVerified = await _verifyCopy(
          sourceEntity: sourceEntity,
          copiedEntity: copiedEntity,
          isDirectory: entry.isDirectory,
        );
        if (!isVerified) {
          throw FileSystemException('copy_verification_failed');
        }

        if (mode == ClipboardOperation.cut) {
          try {
            await sourceEntity.delete(recursive: true);
            removedPaths.add(entry.path);
          } catch (error) {
            final rollbackSucceeded = await _rollbackDestinationMutation(
              destinationPath: destinationPath,
              copiedEntityIsDirectory: entry.isDirectory,
              overwriteBackup: overwriteBackup,
            );
            failures.add(
              FileOperationFailure(
                path: entry.path,
                errorCode:
                    rollbackSucceeded
                        ? FileOperationErrorCodes.rolledBack
                        : FileOperationErrorCodes.rollbackFailed,
                details: error,
              ),
            );
            continue;
          }
        }

        createdPaths.add(copiedEntity.path);
        await _cleanupOverwriteBackup(overwriteBackup);
      } catch (error) {
        if (mutationStarted) {
          final rollbackSucceeded = await _rollbackDestinationMutation(
            destinationPath: destinationPath,
            copiedEntityIsDirectory: entry.isDirectory,
            overwriteBackup: overwriteBackup,
          );
          failures.add(
            FileOperationFailure(
              path: entry.path,
              errorCode:
                  rollbackSucceeded
                      ? FileOperationErrorCodes.rolledBack
                      : FileOperationErrorCodes.rollbackFailed,
              details: error,
            ),
          );
        } else {
          failures.add(
            FileOperationFailure(
              path: entry.path,
              errorCode: _mapExceptionToErrorCode(
                error,
                defaultCode: FileOperationErrorCodes.conflict,
                prefersSourceMissing: true,
              ),
              details: error,
            ),
          );
        }
      }
    }

    onProgress?.call(
      FileOperationProgress(
        operationType:
            mode == ClipboardOperation.cut
                ? FileOperationType.move
                : FileOperationType.copy,
        processedItems: validatedEntries.length,
        totalItems: validatedEntries.length,
      ),
    );

    return FileOperationResult(
      createdPaths: createdPaths,
      removedPaths: removedPaths,
      skippedPaths: skippedPaths,
      failures: failures,
      impactedDirectoryPaths: impactedDirectoryPaths,
    );
  }

  bool isValidName(String value) => _isValidName(value);

  Future<int> _calculateTotalSize(List<FileOperationEntry> entries) async {
    var totalBytes = 0;
    for (final entry in entries) {
      totalBytes += await _calculateEntrySize(_entityFromEntry(entry));
    }
    return totalBytes;
  }

  Future<int> _calculateEntrySize(FileSystemEntity entity) async {
    if (entity is File) {
      return entity.length();
    }

    if (entity is! Directory) {
      return 0;
    }

    var totalBytes = 0;
    await for (final child in entity.list(
      recursive: true,
      followLinks: false,
    )) {
      if (child is File) {
        totalBytes += await child.length();
      }
    }
    return totalBytes;
  }

  Future<bool> _hasEnoughSpace(int requiredBytes) async {
    final freeSpaceInMegabytes = await DiskSpace.getFreeDiskSpace;
    if (freeSpaceInMegabytes == null) {
      return true;
    }

    return freeSpaceInMegabytes * 1024 * 1024 >= requiredBytes;
  }

  Future<_ResolvedDestinationPath> _resolveDestinationPath({
    required FileOperationEntry entry,
    required String baseDestinationPath,
    required ClipboardOperation mode,
    required FileConflictResolver onConflict,
  }) async {
    if (_normalizePath(entry.path) == _normalizePath(baseDestinationPath)) {
      if (mode == ClipboardOperation.cut) {
        return const _ResolvedDestinationPath.skip();
      }

      return _ResolvedDestinationPath.value(
        await _buildUniquePath(baseDestinationPath, entry.isDirectory),
      );
    }

    if (!await _pathExists(baseDestinationPath)) {
      return _ResolvedDestinationPath.value(baseDestinationPath);
    }

    final resolution = await onConflict(
      FileConflictRequest(
        source: entry,
        destinationPath: baseDestinationPath,
        operationType:
            mode == ClipboardOperation.cut
                ? FileOperationType.move
                : FileOperationType.copy,
      ),
    );

    switch (resolution) {
      case FileConflictResolution.overwrite:
        return _ResolvedDestinationPath.overwrite(baseDestinationPath);
      case FileConflictResolution.createUniqueName:
        return _ResolvedDestinationPath.value(
          await _buildUniquePath(baseDestinationPath, entry.isDirectory),
        );
      case FileConflictResolution.skip:
        return const _ResolvedDestinationPath.skip();
      case FileConflictResolution.cancel:
        return const _ResolvedDestinationPath.cancel();
    }
  }

  Future<String> _buildUniquePath(String basePath, bool isDirectory) async {
    final parentPath = pathinfo.dirname(basePath);
    final extension = isDirectory ? '' : pathinfo.extension(basePath);
    final baseName =
        isDirectory
            ? pathinfo.basename(basePath)
            : pathinfo.basenameWithoutExtension(basePath);

    var suffix = 1;
    while (true) {
      final candidateName = '$baseName ($suffix)$extension';
      final candidatePath = pathinfo.join(parentPath, candidateName);
      if (!await _pathExists(candidatePath)) {
        return candidatePath;
      }
      suffix++;
    }
  }

  Future<FileSystemEntity> _copyEntry({
    required FileOperationEntry entry,
    required FileSystemEntity sourceEntity,
    required String destinationPath,
  }) async {
    if (!entry.isDirectory) {
      return (sourceEntity as File).copy(destinationPath);
    }

    final targetDirectory = Directory(destinationPath);
    if (!await targetDirectory.exists()) {
      await targetDirectory.create(recursive: true);
    }

    await _copyDirectory(
      sourceDirectory: sourceEntity as Directory,
      targetDirectory: targetDirectory,
    );
    return targetDirectory;
  }

  Future<void> _copyDirectory({
    required Directory sourceDirectory,
    required Directory targetDirectory,
  }) async {
    await for (final entity in sourceDirectory.list(followLinks: false)) {
      final destinationPath = pathinfo.join(
        targetDirectory.path,
        pathinfo.basename(entity.path),
      );

      if (entity is Directory) {
        final childDirectory = Directory(destinationPath);
        if (!await childDirectory.exists()) {
          await childDirectory.create(recursive: true);
        }
        await _copyDirectory(
          sourceDirectory: entity,
          targetDirectory: childDirectory,
        );
        continue;
      }

      if (entity is File) {
        await entity.copy(destinationPath);
      }
    }
  }

  Future<bool> _verifyCopy({
    required FileSystemEntity sourceEntity,
    required FileSystemEntity copiedEntity,
    required bool isDirectory,
  }) async {
    if (!await copiedEntity.exists()) {
      return false;
    }

    if (!isDirectory) {
      final sourceFile = sourceEntity as File;
      final copiedFile = copiedEntity as File;
      return await sourceFile.length() == await copiedFile.length();
    }

    final sourceSnapshot = await _snapshotDirectory(sourceEntity as Directory);
    final copiedSnapshot = await _snapshotDirectory(copiedEntity as Directory);
    return sourceSnapshot == copiedSnapshot;
  }

  Future<_DirectorySnapshot> _snapshotDirectory(Directory directory) async {
    var fileCount = 0;
    var directoryCount = 0;
    var totalBytes = 0;

    await for (final child in directory.list(
      recursive: true,
      followLinks: false,
    )) {
      if (child is File) {
        fileCount++;
        totalBytes += await child.length();
      } else if (child is Directory) {
        directoryCount++;
      }
    }

    return _DirectorySnapshot(
      fileCount: fileCount,
      directoryCount: directoryCount,
      totalBytes: totalBytes,
    );
  }

  Future<_ValidationResult<_ValidatedEntry>> _validateRenameSource(
    String sourcePath,
  ) async {
    final entityType = await FileSystemEntity.type(
      sourcePath,
      followLinks: false,
    );
    switch (entityType) {
      case FileSystemEntityType.directory:
        return _validateSourceEntry(
          const FileOperationEntry(path: '', isDirectory: true),
          overridePath: sourcePath,
          requireParentWrite: true,
        );
      case FileSystemEntityType.file:
        return _validateSourceEntry(
          const FileOperationEntry(path: '', isDirectory: false),
          overridePath: sourcePath,
          requireParentWrite: true,
        );
      case FileSystemEntityType.link:
        return const _ValidationResult.failure(
          FileOperationErrorCodes.symbolicLinkUnsupported,
          inferredIsDirectory: false,
        );
      case FileSystemEntityType.notFound:
        return const _ValidationResult.failure(
          FileOperationErrorCodes.sourceNotFound,
          inferredIsDirectory: false,
        );
      case FileSystemEntityType.pipe:
      case FileSystemEntityType.unixDomainSock:
      default:
        return const _ValidationResult.failure(
          FileOperationErrorCodes.invalidPath,
          inferredIsDirectory: false,
        );
    }
  }

  Future<_ValidationResult<_ValidatedEntry>> _validateSourceEntry(
    FileOperationEntry entry, {
    String? overridePath,
    required bool requireParentWrite,
  }) async {
    final resolvedPath = overridePath ?? entry.path;
    final effectiveEntry = FileOperationEntry(
      path: resolvedPath,
      isDirectory: entry.isDirectory,
    );
    final accessResult =
        effectiveEntry.isDirectory
            ? await _fileAccessService.validateDirectory(effectiveEntry.path)
            : await _fileAccessService.validateFile(effectiveEntry.path);

    if (!accessResult.isAccessible) {
      return _ValidationResult.failure(
        _mapAccessResultToErrorCode(accessResult, prefersSourceMissing: true),
        inferredIsDirectory: effectiveEntry.isDirectory,
      );
    }

    if (requireParentWrite) {
      final parentError = await _validateDirectoryPathForWrite(
        pathinfo.dirname(effectiveEntry.path),
      );
      if (parentError != null) {
        return _ValidationResult.failure(
          parentError,
          inferredIsDirectory: effectiveEntry.isDirectory,
        );
      }
    }

    return _ValidationResult.success(
      _ValidatedEntry(
        entry: effectiveEntry,
        entity: _entityForPath(
          effectiveEntry.path,
          isDirectory: effectiveEntry.isDirectory,
        ),
      ),
      inferredIsDirectory: effectiveEntry.isDirectory,
    );
  }

  Future<String?> _validateDirectoryPathForWrite(String path) async {
    final accessResult = await _fileAccessService.validateDirectory(
      path,
      requireWriteAccess: true,
    );
    if (accessResult.isAccessible) {
      return null;
    }

    return _mapAccessResultToErrorCode(
      accessResult,
      prefersParentMissing: true,
    );
  }

  String _mapAccessResultToErrorCode(
    FileAccessResult accessResult, {
    bool prefersSourceMissing = false,
    bool prefersParentMissing = false,
  }) {
    switch (accessResult.issueCode) {
      case FileAccessIssueCode.deleted:
        if (prefersParentMissing) {
          return FileOperationErrorCodes.parentNotFound;
        }
        if (prefersSourceMissing) {
          return FileOperationErrorCodes.sourceNotFound;
        }
        return FileOperationErrorCodes.invalidPath;
      case FileAccessIssueCode.permissionDenied:
      case FileAccessIssueCode.readDenied:
        return FileOperationErrorCodes.accessDenied;
      case FileAccessIssueCode.symbolicLinkUnsupported:
        return FileOperationErrorCodes.symbolicLinkUnsupported;
      case FileAccessIssueCode.invalidPath:
      case FileAccessIssueCode.wrongType:
      case null:
        return FileOperationErrorCodes.invalidPath;
    }
  }

  String _mapExceptionToErrorCode(
    Object error, {
    required String defaultCode,
    bool prefersSourceMissing = false,
    bool prefersParentMissing = false,
  }) {
    final normalizedError = error.toString().toLowerCase();
    if (normalizedError.contains('permission denied') ||
        normalizedError.contains('access is denied') ||
        normalizedError.contains('operation not permitted')) {
      return FileOperationErrorCodes.accessDenied;
    }

    if (normalizedError.contains('cannot open file')) {
      return FileOperationErrorCodes.accessDenied;
    }

    if (normalizedError.contains('no such file') ||
        normalizedError.contains('cannot find the path') ||
        normalizedError.contains('path not found')) {
      if (prefersParentMissing) {
        return FileOperationErrorCodes.parentNotFound;
      }
      if (prefersSourceMissing) {
        return FileOperationErrorCodes.sourceNotFound;
      }
      return FileOperationErrorCodes.invalidPath;
    }

    return defaultCode;
  }

  Future<_ValidationResult<_OverwriteBackup?>> _backupExistingDestination(
    String destinationPath,
  ) async {
    final entityType = await FileSystemEntity.type(
      destinationPath,
      followLinks: false,
    );
    if (entityType == FileSystemEntityType.notFound) {
      return const _ValidationResult.success(null, inferredIsDirectory: false);
    }

    if (entityType == FileSystemEntityType.link) {
      return const _ValidationResult.failure(
        FileOperationErrorCodes.symbolicLinkUnsupported,
        inferredIsDirectory: false,
      );
    }

    final isDirectory = entityType == FileSystemEntityType.directory;
    final backupPath = await _buildBackupPath(
      destinationPath,
      isDirectory: isDirectory,
    );
    try {
      final backupEntity = await _entityForPath(
        destinationPath,
        isDirectory: isDirectory,
      ).rename(backupPath);
      return _ValidationResult.success(
        _OverwriteBackup(
          originalPath: destinationPath,
          backupPath: backupEntity.path,
          backupIsDirectory: isDirectory,
        ),
        inferredIsDirectory: isDirectory,
      );
    } catch (error) {
      return _ValidationResult.failure(
        _mapExceptionToErrorCode(
          error,
          defaultCode: FileOperationErrorCodes.conflict,
        ),
        inferredIsDirectory: isDirectory,
      );
    }
  }

  Future<String> _buildBackupPath(
    String originalPath, {
    required bool isDirectory,
  }) async {
    final parentPath = pathinfo.dirname(originalPath);
    final extension = isDirectory ? '' : pathinfo.extension(originalPath);
    final baseName =
        isDirectory
            ? pathinfo.basename(originalPath)
            : pathinfo.basenameWithoutExtension(originalPath);

    var suffix = 0;
    while (true) {
      final suffixLabel = suffix == 0 ? '' : '_$suffix';
      final candidateName = '$baseName$_backupMarker$suffixLabel$extension';
      final candidatePath = pathinfo.join(parentPath, candidateName);
      if (!await _pathExists(candidatePath)) {
        return candidatePath;
      }
      suffix++;
    }
  }

  Future<bool> _rollbackDestinationMutation({
    required String destinationPath,
    required bool copiedEntityIsDirectory,
    required _OverwriteBackup? overwriteBackup,
  }) async {
    try {
      await _deleteIfExists(
        path: destinationPath,
        isDirectory: copiedEntityIsDirectory,
      );
      if (overwriteBackup != null) {
        final backupEntity = _entityForPath(
          overwriteBackup.backupPath,
          isDirectory: overwriteBackup.backupIsDirectory,
        );
        if (await backupEntity.exists()) {
          await backupEntity.rename(overwriteBackup.originalPath);
        }
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> _cleanupOverwriteBackup(
    _OverwriteBackup? overwriteBackup,
  ) async {
    if (overwriteBackup == null) {
      return;
    }

    await _deleteIfExists(
      path: overwriteBackup.backupPath,
      isDirectory: overwriteBackup.backupIsDirectory,
    );
  }

  Future<bool> _rollbackRename({
    required String sourcePath,
    required String targetPath,
    required bool isDirectory,
  }) async {
    final sourceStillExists = await _pathExists(sourcePath);
    final targetExists = await _pathExists(targetPath);
    if (sourceStillExists || !targetExists) {
      return false;
    }

    try {
      await _entityForPath(
        targetPath,
        isDirectory: isDirectory,
      ).rename(sourcePath);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> _deleteIfExists({
    required String path,
    required bool isDirectory,
  }) async {
    final entity = _entityForPath(path, isDirectory: isDirectory);
    if (!await entity.exists()) {
      return false;
    }

    await entity.delete(recursive: true);
    return true;
  }

  List<FileOperationEntry> _collapseNestedEntries(
    List<FileOperationEntry> entries,
  ) {
    final sortedEntries = entries.toList(growable: false)
      ..sort((a, b) => a.path.length.compareTo(b.path.length));
    final uniqueEntries = <FileOperationEntry>[];

    for (final entry in sortedEntries) {
      final normalizedEntryPath = _normalizePath(entry.path);
      final isNested = uniqueEntries.any((candidate) {
        final normalizedCandidatePath = _normalizePath(candidate.path);
        if (normalizedEntryPath == normalizedCandidatePath) {
          return true;
        }

        if (!candidate.isDirectory) {
          return false;
        }

        return normalizedEntryPath.startsWith(
          '$normalizedCandidatePath${Platform.pathSeparator}',
        );
      });
      if (!isNested) {
        uniqueEntries.add(entry);
      }
    }

    return uniqueEntries;
  }

  FileSystemEntity _entityFromEntry(FileOperationEntry entry) {
    return _entityForPath(entry.path, isDirectory: entry.isDirectory);
  }

  FileSystemEntity _entityForPath(String path, {required bool isDirectory}) {
    return isDirectory ? Directory(path) : File(path);
  }

  Future<bool> _pathExists(String value) async {
    return await FileSystemEntity.type(value, followLinks: false) !=
        FileSystemEntityType.notFound;
  }

  bool _isNestedPath({
    required String sourcePath,
    required String candidatePath,
  }) {
    final normalizedSource = _normalizePath(sourcePath);
    final normalizedCandidate = _normalizePath(candidatePath);
    return normalizedCandidate.startsWith(
      '$normalizedSource${Platform.pathSeparator}',
    );
  }

  String _normalizePath(String value) {
    return pathinfo.normalize(value);
  }

  bool _isValidName(String value) {
    final trimmedValue = value.trim();
    if (trimmedValue.isEmpty || trimmedValue == '.' || trimmedValue == '..') {
      return false;
    }

    return !RegExp(_invalidNamePattern).hasMatch(trimmedValue);
  }
}

class _ResolvedDestinationPath {
  const _ResolvedDestinationPath._({
    required this.path,
    required this.cancelled,
    required this.overwriteExisting,
  });

  const _ResolvedDestinationPath.value(String value)
    : this._(path: value, cancelled: false, overwriteExisting: false);

  const _ResolvedDestinationPath.overwrite(String value)
    : this._(path: value, cancelled: false, overwriteExisting: true);

  const _ResolvedDestinationPath.skip()
    : this._(path: null, cancelled: false, overwriteExisting: false);

  const _ResolvedDestinationPath.cancel()
    : this._(path: null, cancelled: true, overwriteExisting: false);

  final String? path;
  final bool cancelled;
  final bool overwriteExisting;
}

class _ValidatedEntry {
  const _ValidatedEntry({required this.entry, required this.entity});

  final FileOperationEntry entry;
  final FileSystemEntity entity;
}

class _ValidationResult<T> {
  const _ValidationResult.success(
    this.value, {
    required this.inferredIsDirectory,
  }) : errorCode = null;
  const _ValidationResult.failure(
    this.errorCode, {
    required this.inferredIsDirectory,
  }) : value = null;

  final T? value;
  final String? errorCode;
  final bool inferredIsDirectory;

  bool get isSuccess => errorCode == null;
}

class _OverwriteBackup {
  const _OverwriteBackup({
    required this.originalPath,
    required this.backupPath,
    required this.backupIsDirectory,
  });

  final String originalPath;
  final String backupPath;
  final bool backupIsDirectory;
}

class _DirectorySnapshot {
  const _DirectorySnapshot({
    required this.fileCount,
    required this.directoryCount,
    required this.totalBytes,
  });

  final int fileCount;
  final int directoryCount;
  final int totalBytes;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }

    return other is _DirectorySnapshot &&
        other.fileCount == fileCount &&
        other.directoryCount == directoryCount &&
        other.totalBytes == totalBytes;
  }

  @override
  int get hashCode => Object.hash(fileCount, directoryCount, totalBytes);
}
