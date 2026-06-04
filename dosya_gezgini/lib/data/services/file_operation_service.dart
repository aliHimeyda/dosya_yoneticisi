import 'dart:io';

import 'package:disk_space_2/disk_space_2.dart';
import 'package:dosya_gezgini/data/models/file_operation_models.dart';
import 'package:path/path.dart' as pathinfo;

typedef FileConflictResolver =
    Future<FileConflictResolution> Function(FileConflictRequest request);
typedef FileOperationProgressCallback =
    void Function(FileOperationProgress progress);

class FileOperationService {
  static const _invalidNamePattern = r'[<>:"/\\|?*\x00-\x1F]';

  Future<FileCreateResult> createFolder({
    required String parentDirectoryPath,
    required String folderName,
  }) async {
    if (!_isValidName(folderName)) {
      return const FileCreateResult(
        errorCode: FileOperationErrorCodes.invalidName,
      );
    }

    final parentDirectory = Directory(parentDirectoryPath);
    if (!await parentDirectory.exists()) {
      return const FileCreateResult(
        errorCode: FileOperationErrorCodes.parentNotFound,
      );
    }

    final targetPath = pathinfo.join(parentDirectoryPath, folderName.trim());
    final targetDirectory = Directory(targetPath);
    if (await targetDirectory.exists()) {
      return FileCreateResult(
        errorCode: FileOperationErrorCodes.alreadyExists,
        impactedDirectoryPaths: <String>{parentDirectoryPath},
      );
    }

    await targetDirectory.create(recursive: true);
    return FileCreateResult(
      createdPath: targetDirectory.path,
      impactedDirectoryPaths: <String>{parentDirectoryPath},
    );
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

    final entityType = FileSystemEntity.typeSync(sourcePath);
    if (entityType == FileSystemEntityType.notFound) {
      return FileRenameResult(
        oldPath: sourcePath,
        newPath: null,
        isDirectory: false,
        errorCode: FileOperationErrorCodes.sourceNotFound,
      );
    }

    final isDirectory = entityType == FileSystemEntityType.directory;
    final sourceEntity =
        isDirectory
            ? Directory(sourcePath) as FileSystemEntity
            : File(sourcePath);
    final parentPath = pathinfo.dirname(sourcePath);
    final targetPath = pathinfo.join(parentPath, trimmedName);
    final impactedDirectoryPaths = <String>{parentPath};

    if (_normalizePath(sourcePath) != _normalizePath(targetPath) &&
        await _pathExists(targetPath)) {
      return FileRenameResult(
        oldPath: sourcePath,
        newPath: null,
        isDirectory: isDirectory,
        errorCode: FileOperationErrorCodes.alreadyExists,
        impactedDirectoryPaths: impactedDirectoryPaths,
      );
    }

    final renamedEntity = await sourceEntity.rename(targetPath);
    return FileRenameResult(
      oldPath: sourcePath,
      newPath: renamedEntity.path,
      isDirectory: isDirectory,
      impactedDirectoryPaths: impactedDirectoryPaths,
    );
  }

  Future<FileOperationResult> deleteEntries(
    List<FileOperationEntry> entries, {
    FileOperationProgressCallback? onProgress,
  }) async {
    final removedPaths = <String>[];
    final skippedPaths = <String>[];
    final failures = <FileOperationFailure>[];
    final impactedDirectoryPaths = <String>{};

    for (var index = 0; index < entries.length; index++) {
      final entry = entries[index];
      onProgress?.call(
        FileOperationProgress(
          operationType: FileOperationType.delete,
          processedItems: index,
          totalItems: entries.length,
          currentPath: entry.path,
        ),
      );

      final entity = _entityFromEntry(entry);
      impactedDirectoryPaths.add(pathinfo.dirname(entry.path));
      if (!await entity.exists()) {
        skippedPaths.add(entry.path);
        continue;
      }

      try {
        await entity.delete(recursive: true);
        removedPaths.add(entry.path);
      } catch (error) {
        failures.add(
          FileOperationFailure(
            path: entry.path,
            errorCode: FileOperationErrorCodes.sourceNotFound,
            details: error,
          ),
        );
      }
    }

    onProgress?.call(
      FileOperationProgress(
        operationType: FileOperationType.delete,
        processedItems: entries.length,
        totalItems: entries.length,
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
    final destinationDirectory = Directory(destinationDirectoryPath);
    if (!await destinationDirectory.exists()) {
      return const FileOperationResult(
        failures: <FileOperationFailure>[
          FileOperationFailure(
            path: '',
            errorCode: FileOperationErrorCodes.parentNotFound,
          ),
        ],
      );
    }

    final requiredBytes = await _calculateTotalSize(entries);
    final hasEnoughSpace = await _hasEnoughSpace(requiredBytes);
    if (!hasEnoughSpace) {
      return const FileOperationResult(
        failures: <FileOperationFailure>[
          FileOperationFailure(
            path: '',
            errorCode: FileOperationErrorCodes.insufficientSpace,
          ),
        ],
      );
    }

    final createdPaths = <String>[];
    final removedPaths = <String>[];
    final skippedPaths = <String>[];
    final failures = <FileOperationFailure>[];
    final impactedDirectoryPaths = <String>{destinationDirectoryPath};

    for (var index = 0; index < entries.length; index++) {
      final entry = entries[index];
      onProgress?.call(
        FileOperationProgress(
          operationType:
              mode == ClipboardOperation.cut
                  ? FileOperationType.move
                  : FileOperationType.copy,
          processedItems: index,
          totalItems: entries.length,
          currentPath: entry.path,
        ),
      );

      final sourceEntity = _entityFromEntry(entry);
      if (!await sourceEntity.exists()) {
        failures.add(
          FileOperationFailure(
            path: entry.path,
            errorCode: FileOperationErrorCodes.sourceNotFound,
          ),
        );
        continue;
      }

      impactedDirectoryPaths.add(pathinfo.dirname(entry.path));
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

      try {
        final copiedEntity = await _copyEntry(
          entry: entry,
          sourceEntity: sourceEntity,
          destinationPath: destinationPath,
        );
        final isVerified = await _verifyCopy(
          sourceEntity: sourceEntity,
          copiedEntity: copiedEntity,
          isDirectory: entry.isDirectory,
        );
        if (!isVerified) {
          failures.add(
            FileOperationFailure(
              path: entry.path,
              errorCode: FileOperationErrorCodes.conflict,
            ),
          );
          continue;
        }

        createdPaths.add(copiedEntity.path);

        if (mode == ClipboardOperation.cut) {
          await sourceEntity.delete(recursive: true);
          removedPaths.add(entry.path);
        }
      } catch (error) {
        failures.add(
          FileOperationFailure(
            path: entry.path,
            errorCode: FileOperationErrorCodes.conflict,
            details: error,
          ),
        );
      }
    }

    onProgress?.call(
      FileOperationProgress(
        operationType:
            mode == ClipboardOperation.cut
                ? FileOperationType.move
                : FileOperationType.copy,
        processedItems: entries.length,
        totalItems: entries.length,
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
        await _entityForPath(baseDestinationPath).delete(recursive: true);
        return _ResolvedDestinationPath.value(baseDestinationPath);
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

    if (isDirectory) {
      return true;
    }

    final sourceFile = sourceEntity as File;
    final copiedFile = copiedEntity as File;
    return await sourceFile.length() == await copiedFile.length();
  }

  FileSystemEntity _entityFromEntry(FileOperationEntry entry) {
    return _entityForPath(entry.path, isDirectory: entry.isDirectory);
  }

  FileSystemEntity _entityForPath(String path, {bool? isDirectory}) {
    final resolvedIsDirectory =
        isDirectory ?? FileSystemEntity.isDirectorySync(path);
    return resolvedIsDirectory ? Directory(path) : File(path);
  }

  Future<bool> _pathExists(String value) async {
    return await FileSystemEntity.type(value) != FileSystemEntityType.notFound;
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
  });

  const _ResolvedDestinationPath.value(String value)
    : this._(path: value, cancelled: false);

  const _ResolvedDestinationPath.skip() : this._(path: null, cancelled: false);

  const _ResolvedDestinationPath.cancel() : this._(path: null, cancelled: true);

  final String? path;
  final bool cancelled;
}
