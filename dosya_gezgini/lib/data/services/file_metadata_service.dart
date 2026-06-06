import 'dart:async';
import 'dart:collection';
import 'dart:io';

import 'package:dosya_gezgini/data/models/file_access_result.dart';
import 'package:dosya_gezgini/data/models/file_metadata_model.dart';
import 'package:dosya_gezgini/data/repositories/file_metadata_repository.dart';
import 'package:dosya_gezgini/data/services/file_access_service.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as pathinfo;

class FileMetadataService {
  FileMetadataService({
    required FileMetadataRepository repository,
    required FileAccessService fileAccessService,
  }) : _repository = repository,
       _fileAccessService = fileAccessService;

  static const int _maxConcurrentJobs = 3;

  final FileMetadataRepository _repository;
  final FileAccessService _fileAccessService;
  final Map<String, FileMetadataModel> _memoryCache =
      <String, FileMetadataModel>{};
  final Map<String, ValueNotifier<FileMetadataModel?>> _listenables =
      <String, ValueNotifier<FileMetadataModel?>>{};
  final Map<String, Future<FileMetadataModel?>> _pendingJobs =
      <String, Future<FileMetadataModel?>>{};
  final Queue<_FileMetadataJob> _jobQueue = Queue<_FileMetadataJob>();
  int _activeJobs = 0;

  ValueListenable<FileMetadataModel?> listenableFor(String path) {
    final normalizedPath = _normalizePath(path);
    return _listenables.putIfAbsent(
      normalizedPath,
      () => ValueNotifier<FileMetadataModel?>(_memoryCache[normalizedPath]),
    );
  }

  FileMetadataModel? currentMetadata(String path) {
    return _memoryCache[_normalizePath(path)];
  }

  Future<FileMetadataModel?> getMetadataForFile(
    File file, {
    bool forceRefresh = false,
    FileMetadataModel? fallbackModel,
  }) async {
    final normalizedPath = _normalizePath(file.path);
    if (normalizedPath.isEmpty) {
      return null;
    }

    if (fallbackModel != null) {
      final currentValue = _memoryCache[normalizedPath];
      if (currentValue == null) {
        _publish(fallbackModel, persist: false);
      }
    }

    if (!forceRefresh) {
      final memoryValue = _memoryCache[normalizedPath];
      if (memoryValue != null) {
        return memoryValue;
      }

      final persistedValue = await _repository.getByPath(normalizedPath);
      if (persistedValue != null) {
        _publish(persistedValue, persist: false);
        return persistedValue;
      }
    }

    return _enqueueRefresh(
      path: normalizedPath,
      file: file,
      forceRefresh: forceRefresh,
    );
  }

  Future<Map<String, FileMetadataModel>> getMetadataForFiles(
    List<File> files, {
    bool forceRefresh = false,
  }) async {
    final uniqueFiles = _normalizeFiles(files);
    if (uniqueFiles.isEmpty) {
      return const <String, FileMetadataModel>{};
    }

    final resolved = <String, FileMetadataModel>{};
    final cachedPaths = <String>{};
    for (final entry in uniqueFiles.entries) {
      final memoryValue = _memoryCache[entry.key];
      if (memoryValue != null) {
        resolved[entry.key] = memoryValue;
        cachedPaths.add(entry.key);
      }
    }

    final missingPaths = uniqueFiles.keys
        .where((path) => !cachedPaths.contains(path))
        .toList(growable: false);
    if (missingPaths.isNotEmpty) {
      final persistedItems = await _repository.getManyByPaths(missingPaths);
      for (final item in persistedItems) {
        _publish(item, persist: false);
        resolved[item.path] = item;
        cachedPaths.add(item.path);
      }
    }

    final pathsToRefresh =
        forceRefresh
            ? uniqueFiles.keys
            : uniqueFiles.keys.where((path) => !cachedPaths.contains(path));

    final futures = <Future<FileMetadataModel?>>[
      for (final path in pathsToRefresh)
        _enqueueRefresh(
          path: path,
          file: uniqueFiles[path],
          forceRefresh: forceRefresh,
        ),
    ];
    final refreshedItems = await Future.wait<FileMetadataModel?>(futures);
    for (final item in refreshedItems.whereType<FileMetadataModel>()) {
      resolved[item.path] = item;
    }

    return Map<String, FileMetadataModel>.unmodifiable(resolved);
  }

  Future<void> prime(
    File file, {
    bool forceRefresh = false,
    FileMetadataModel? fallbackModel,
    bool allowFilesystemRead = true,
  }) async {
    await primeFiles(
      <File>[file],
      forceRefresh: forceRefresh,
      seedMetadataByPath:
          fallbackModel == null
              ? null
              : <String, FileMetadataModel>{file.path: fallbackModel},
      allowFilesystemRead: allowFilesystemRead,
    );
  }

  Future<void> primeFiles(
    Iterable<File> files, {
    bool forceRefresh = false,
    Map<String, FileMetadataModel>? seedMetadataByPath,
    bool allowFilesystemRead = true,
  }) async {
    final uniqueFiles = _normalizeFiles(files);
    if (uniqueFiles.isEmpty) {
      return;
    }

    final cachedPaths = <String>{};
    for (final path in uniqueFiles.keys) {
      final memoryValue = _memoryCache[path];
      if (memoryValue != null) {
        cachedPaths.add(path);
      }
    }

    if (seedMetadataByPath != null && seedMetadataByPath.isNotEmpty) {
      for (final entry in seedMetadataByPath.entries) {
        final normalizedPath = _normalizePath(entry.key);
        if (!uniqueFiles.containsKey(normalizedPath)) {
          continue;
        }
        if (_memoryCache.containsKey(normalizedPath)) {
          continue;
        }
        _publish(
          _normalizeSeedMetadata(
            normalizedPath: normalizedPath,
            seed: entry.value,
          ),
          persist: false,
        );
      }
    }

    final missingInMemory = uniqueFiles.keys
        .where((path) => !cachedPaths.contains(path))
        .toList(growable: false);
    if (missingInMemory.isNotEmpty) {
      final persistedItems = await _repository.getManyByPaths(missingInMemory);
      for (final item in persistedItems) {
        _publish(item, persist: false);
        cachedPaths.add(item.path);
      }
    }

    if (!allowFilesystemRead) {
      return;
    }

    final pathsToRefresh =
        forceRefresh
            ? uniqueFiles.keys
            : uniqueFiles.keys.where((path) => !cachedPaths.contains(path));
    for (final path in pathsToRefresh) {
      unawaited(
        _enqueueRefresh(
          path: path,
          file: uniqueFiles[path],
          forceRefresh: forceRefresh,
        ),
      );
    }
  }

  Future<void> refreshMetadataForPath(String path) async {
    final normalizedPath = _normalizePath(path);
    if (normalizedPath.isEmpty) {
      return;
    }

    await _enqueueRefresh(path: normalizedPath, forceRefresh: true);
  }

  Future<void> refreshMetadataForPaths(Iterable<String> paths) async {
    final futures = <Future<FileMetadataModel?>>[];
    for (final path in paths) {
      final normalizedPath = _normalizePath(path);
      if (normalizedPath.isEmpty) {
        continue;
      }
      futures.add(_enqueueRefresh(path: normalizedPath, forceRefresh: true));
    }
    if (futures.isEmpty) {
      return;
    }

    await Future.wait<FileMetadataModel?>(futures);
  }

  Future<void> deleteMetadataForPath(String path) async {
    final normalizedPath = _normalizePath(path);
    if (normalizedPath.isEmpty) {
      return;
    }

    _memoryCache.remove(normalizedPath);
    final listenable = _listenables.putIfAbsent(
      normalizedPath,
      () => ValueNotifier<FileMetadataModel?>(null),
    );
    if (listenable.value != null) {
      listenable.value = null;
    }
    await _repository.deleteByPath(normalizedPath);
  }

  Future<void> deleteMetadataForPaths(Iterable<String> paths) async {
    final uniquePaths = paths
        .map(_normalizePath)
        .where((path) => path.isNotEmpty)
        .toSet();
    if (uniquePaths.isEmpty) {
      return;
    }

    for (final path in uniquePaths) {
      _memoryCache.remove(path);
      final listenable = _listenables.putIfAbsent(
        path,
        () => ValueNotifier<FileMetadataModel?>(null),
      );
      if (listenable.value != null) {
        listenable.value = null;
      }
    }

    await _repository.deleteManyByPaths(uniquePaths.toList(growable: false));
  }

  Future<List<String>> pruneMissingPaths() async {
    final cachedItems = await _repository.readAll();
    final prunedPaths = <String>[];

    for (final item in cachedItems) {
      final accessResult = await _fileAccessService.validateFile(item.path);
      if (!accessResult.shouldPruneCaches) {
        continue;
      }

      prunedPaths.add(item.path);
    }

    if (prunedPaths.isEmpty) {
      return const <String>[];
    }

    await deleteMetadataForPaths(prunedPaths);
    return List<String>.unmodifiable(prunedPaths);
  }

  Map<String, File> _normalizeFiles(Iterable<File> files) {
    final uniqueFiles = <String, File>{};
    for (final file in files) {
      final normalizedPath = _normalizePath(file.path);
      if (normalizedPath.isEmpty) {
        continue;
      }

      uniqueFiles[normalizedPath] = File(normalizedPath);
    }
    return uniqueFiles;
  }

  Future<FileMetadataModel?> _enqueueRefresh({
    required String path,
    File? file,
    required bool forceRefresh,
  }) {
    final pendingJob = _pendingJobs[path];
    if (pendingJob != null) {
      return pendingJob;
    }

    final completer = Completer<FileMetadataModel?>();
    final future = completer.future;
    _pendingJobs[path] = future;
    _jobQueue.add(
      _FileMetadataJob(
        path: path,
        file: file,
        forceRefresh: forceRefresh,
        completer: completer,
      ),
    );
    _drainJobQueue();
    return future;
  }

  void _drainJobQueue() {
    while (_activeJobs < _maxConcurrentJobs && _jobQueue.isNotEmpty) {
      final job = _jobQueue.removeFirst();
      _activeJobs++;
      unawaited(_runJob(job));
    }
  }

  Future<void> _runJob(_FileMetadataJob job) async {
    try {
      final result = await _refreshMetadataFromFileSystem(
        path: job.path,
        file: job.file,
        forceRefresh: job.forceRefresh,
      );
      if (!job.completer.isCompleted) {
        job.completer.complete(result);
      }
    } catch (error, stackTrace) {
      if (!job.completer.isCompleted) {
        job.completer.completeError(error, stackTrace);
      }
    } finally {
      _pendingJobs.remove(job.path);
      _activeJobs--;
      _drainJobQueue();
    }
  }

  Future<FileMetadataModel?> _refreshMetadataFromFileSystem({
    required String path,
    File? file,
    required bool forceRefresh,
  }) async {
    final existingValue =
        _memoryCache[path] ?? await _repository.getByPath(path);
    if (existingValue != null) {
      _publish(existingValue, persist: false);
    }

    final accessResult = await _fileAccessService.validateFile(path);
    if (!accessResult.isAccessible) {
      _logAccessFailure(accessResult);
      if (accessResult.shouldPruneCaches) {
        await deleteMetadataForPath(path);
        return null;
      }
      return existingValue;
    }

    final resolvedFile = file ?? File(path);
    FileStat stat;
    try {
      stat = await FileStat.stat(resolvedFile.path);
    } catch (error) {
      debugPrint('File metadata stat read failed for $path: $error');
      return existingValue;
    }

    if (stat.type != FileSystemEntityType.file) {
      await deleteMetadataForPath(path);
      return null;
    }

    if (!forceRefresh &&
        existingValue != null &&
        existingValue.matchesFileStat(stat)) {
      return existingValue;
    }

    final model = FileMetadataModel(
      path: path,
      name: pathinfo.basename(path),
      sizeBytes: stat.size,
      modifiedAt: stat.modified,
      updatedAt: DateTime.now(),
      exists: true,
      extension: pathinfo.extension(path).toLowerCase(),
      parentPath: pathinfo.dirname(path),
    );
    await _repository.upsert(model);
    _publish(model, persist: false);
    return model;
  }

  FileMetadataModel _normalizeSeedMetadata({
    required String normalizedPath,
    required FileMetadataModel seed,
  }) {
    if (_normalizePath(seed.path) == normalizedPath) {
      return seed;
    }

    return FileMetadataModel(
      path: normalizedPath,
      name: seed.name,
      sizeBytes: seed.sizeBytes,
      modifiedAt: seed.modifiedAt,
      updatedAt: seed.updatedAt,
      exists: seed.exists,
      extension: seed.extension,
      parentPath: seed.parentPath,
    );
  }

  void _publish(FileMetadataModel model, {required bool persist}) {
    final existingValue = _memoryCache[model.path];
    final hasSameValue =
        existingValue?.path == model.path &&
        existingValue?.sizeBytes == model.sizeBytes &&
        existingValue?.modifiedAt == model.modifiedAt &&
        existingValue?.updatedAt == model.updatedAt &&
        existingValue?.exists == model.exists &&
        existingValue?.name == model.name &&
        existingValue?.extension == model.extension &&
        existingValue?.parentPath == model.parentPath;
    if (hasSameValue) {
      return;
    }

    _memoryCache[model.path] = model;
    final listenable = _listenables.putIfAbsent(
      model.path,
      () => ValueNotifier<FileMetadataModel?>(model),
    );
    if (!_hasSameListenableValue(listenable.value, model)) {
      listenable.value = model;
    }
    if (persist) {
      unawaited(_repository.upsert(model));
    }
  }

  bool _hasSameListenableValue(
    FileMetadataModel? current,
    FileMetadataModel next,
  ) {
    return current?.path == next.path &&
        current?.sizeBytes == next.sizeBytes &&
        current?.modifiedAt == next.modifiedAt &&
        current?.updatedAt == next.updatedAt &&
        current?.exists == next.exists &&
        current?.name == next.name &&
        current?.extension == next.extension &&
        current?.parentPath == next.parentPath;
  }

  String _normalizePath(String value) => value.trim();

  void _logAccessFailure(FileAccessResult accessResult) {
    debugPrint(
      'File metadata access check failed for ${accessResult.path}: ${accessResult.debugCode}',
    );
  }
}

class _FileMetadataJob {
  const _FileMetadataJob({
    required this.path,
    required this.file,
    required this.forceRefresh,
    required this.completer,
  });

  final String path;
  final File? file;
  final bool forceRefresh;
  final Completer<FileMetadataModel?> completer;
}
