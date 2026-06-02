import 'dart:async';

import 'package:dosya_gezgini/data/models/file_index_metadata.dart';
import 'package:dosya_gezgini/data/models/indexed_file_model.dart';
import 'package:dosya_gezgini/data/repositories/file_index_repository.dart';
import 'package:dosya_gezgini/data/services/file_system_service.dart';

class IndexReadiness {
  const IndexReadiness({
    required this.hasReadyCache,
    required this.rebuiltNow,
    required this.needsBackgroundRefresh,
  });

  final bool hasReadyCache;
  final bool rebuiltNow;
  final bool needsBackgroundRefresh;
}

class FileIndexService {
  FileIndexService({
    required FileIndexRepository repository,
    required FileSystemService fileSystemService,
    Duration staleAfter = const Duration(minutes: 30),
  }) : _repository = repository,
       _fileSystemService = fileSystemService,
       _staleAfter = staleAfter;

  static const int _writeChunkSize = 250;
  static const int _currentSchemaVersion = 2;

  final FileIndexRepository _repository;
  final FileSystemService _fileSystemService;
  final Duration _staleAfter;

  Future<void>? _activeRefresh;

  Future<IndexReadiness> ensureReady({
    required String rootPath,
    bool forceRefresh = false,
  }) async {
    final metadata = await _repository.readMetadata();
    final hasCachedIndex = await _repository.hasActiveIndex();
    final matchesRootPath = metadata?.rootPath == rootPath;
    final isStale = _isMetadataStale(metadata);
    final isSchemaCurrent = metadata?.schemaVersion == _currentSchemaVersion;

    if (forceRefresh ||
        !hasCachedIndex ||
        !matchesRootPath ||
        !isSchemaCurrent) {
      await refreshIndex(rootPath: rootPath);
      return const IndexReadiness(
        hasReadyCache: true,
        rebuiltNow: true,
        needsBackgroundRefresh: false,
      );
    }

    return IndexReadiness(
      hasReadyCache: true,
      rebuiltNow: false,
      needsBackgroundRefresh: isStale,
    );
  }

  Future<void> refreshIndex({required String rootPath}) {
    final existingRefresh = _activeRefresh;
    if (existingRefresh != null) {
      return existingRefresh;
    }

    final completer = Completer<void>();
    _activeRefresh = completer.future;
    _runRefresh(rootPath)
        .then(completer.complete)
        .catchError(
          (Object error, StackTrace stackTrace) =>
              completer.completeError(error, stackTrace),
        )
        .whenComplete(() {
          _activeRefresh = null;
        });
    return completer.future;
  }

  bool _isMetadataStale(FileIndexMetadata? metadata) {
    if (metadata == null) {
      return true;
    }

    return DateTime.now().difference(metadata.indexedAt) > _staleAfter;
  }

  Future<void> _runRefresh(String rootPath) async {
    await _repository.clearDraftIndex();

    final chunk = <IndexedFileModel>[];
    var indexedItemCount = 0;

    await for (final indexedFile in _fileSystemService.scanEntries(rootPath)) {
      chunk.add(indexedFile);
      indexedItemCount++;

      if (chunk.length >= _writeChunkSize) {
        await _repository.appendDraftEntries(
          List<IndexedFileModel>.from(chunk),
        );
        chunk.clear();
      }
    }

    if (chunk.isNotEmpty) {
      await _repository.appendDraftEntries(List<IndexedFileModel>.from(chunk));
    }

    await _repository.activateDraftIndex(
      rootPath: rootPath,
      indexedAt: DateTime.now(),
      itemCount: indexedItemCount,
      schemaVersion: _currentSchemaVersion,
    );
  }
}
