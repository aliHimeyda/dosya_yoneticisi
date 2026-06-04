import 'dart:async';
import 'dart:collection';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:dosya_gezgini/data/models/thumbnail_cache_model.dart';
import 'package:dosya_gezgini/data/repositories/thumbnail_cache_repository.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as pathinfo;
import 'package:path_provider/path_provider.dart';
import 'package:video_thumbnail/video_thumbnail.dart';

class ThumbnailCacheService {
  ThumbnailCacheService({required ThumbnailCacheRepository repository})
    : _repository = repository;

  static const Set<String> imageExtensions = {
    '.png',
    '.jpg',
    '.jpeg',
    '.webp',
    '.gif',
    '.bmp',
    '.heic',
  };

  static const Set<String> videoExtensions = {
    '.mp4',
    '.mkv',
    '.avi',
    '.mov',
    '.m4v',
    '.webm',
    '.3gp',
  };

  static const int _thumbnailWidth = 128;
  static const int _videoThumbnailQuality = 60;
  static const int _maxConcurrentGenerations = 2;

  final ThumbnailCacheRepository _repository;
  final Map<String, ThumbnailCacheModel?> _metadataBySourcePath = {};
  final Map<String, ValueNotifier<String?>> _thumbnailPathNotifiers = {};
  final Queue<_ThumbnailJob> _pendingJobs = Queue<_ThumbnailJob>();
  final Set<String> _queuedSourcePaths = <String>{};
  final Set<String> _activeSourcePaths = <String>{};

  Directory? _thumbnailDirectory;

  bool supports(File file) => supportsPath(file.path);

  bool supportsPath(String sourcePath) {
    final extension = pathinfo.extension(sourcePath).toLowerCase();
    return imageExtensions.contains(extension) ||
        videoExtensions.contains(extension);
  }

  bool isVideoPath(String sourcePath) {
    return videoExtensions.contains(
      pathinfo.extension(sourcePath).toLowerCase(),
    );
  }

  ValueNotifier<String?> listenableFor(String sourcePath) {
    return _thumbnailPathNotifiers.putIfAbsent(
      sourcePath,
      () => ValueNotifier<String?>(null),
    );
  }

  String? currentThumbnailPath(String sourcePath) {
    return listenableFor(sourcePath).value;
  }

  bool isPending(String sourcePath) {
    return _queuedSourcePaths.contains(sourcePath) ||
        _activeSourcePaths.contains(sourcePath);
  }

  Future<void> prime(File file, {bool allowGeneration = true}) async {
    if (!supports(file)) {
      return;
    }

    final cached = await _readValidMetadata(file);
    if (cached != null || !allowGeneration) {
      return;
    }

    _enqueueGeneration(file.path);
  }

  void _enqueueGeneration(String sourcePath) {
    if (_queuedSourcePaths.contains(sourcePath) ||
        _activeSourcePaths.contains(sourcePath)) {
      return;
    }

    _queuedSourcePaths.add(sourcePath);
    _pendingJobs.add(_ThumbnailJob(sourcePath));
    _pumpQueue();
  }

  void _pumpQueue() {
    while (_activeSourcePaths.length < _maxConcurrentGenerations &&
        _pendingJobs.isNotEmpty) {
      final job = _pendingJobs.removeFirst();
      _queuedSourcePaths.remove(job.sourcePath);
      _activeSourcePaths.add(job.sourcePath);
      unawaited(
        _runJob(job).whenComplete(() {
          _activeSourcePaths.remove(job.sourcePath);
          _pumpQueue();
        }),
      );
    }
  }

  Future<void> _runJob(_ThumbnailJob job) async {
    final sourceFile = File(job.sourcePath);
    final cached = await _readValidMetadata(sourceFile);
    if (cached != null) {
      return;
    }

    final sourceStat = await sourceFile.stat();
    if (sourceStat.type == FileSystemEntityType.notFound) {
      await _purgeEntry(job.sourcePath);
      return;
    }

    final bytes =
        isVideoPath(job.sourcePath)
            ? await _buildVideoThumbnailBytes(sourceFile)
            : await _buildImageThumbnailBytes(sourceFile);

    if (bytes == null || bytes.isEmpty) {
      return;
    }

    final thumbnailDirectory = await _ensureThumbnailDirectory();
    final thumbnailPath = pathinfo.join(
      thumbnailDirectory.path,
      '${_stableKey(job.sourcePath)}${isVideoPath(job.sourcePath) ? '.jpg' : '.png'}',
    );
    final thumbnailFile = File(thumbnailPath);
    await thumbnailFile.writeAsBytes(bytes, flush: true);

    final previousModel = _metadataBySourcePath[job.sourcePath];
    if (previousModel != null && previousModel.thumbnailPath != thumbnailPath) {
      await _deleteFileIfExists(previousModel.thumbnailPath);
    }

    final model = ThumbnailCacheModel(
      sourcePath: job.sourcePath,
      thumbnailPath: thumbnailPath,
      kind: isVideoPath(job.sourcePath) ? 'video' : 'image',
      sourceModifiedAt: sourceStat.modified,
      sourceSizeBytes: sourceStat.size,
      updatedAt: DateTime.now(),
    );

    await _repository.upsert(model);
    _metadataBySourcePath[job.sourcePath] = model;
    _setThumbnailPath(job.sourcePath, thumbnailPath);
  }

  Future<ThumbnailCacheModel?> _readValidMetadata(File sourceFile) async {
    final sourcePath = sourceFile.path;
    final sourceStat = await sourceFile.stat();
    if (sourceStat.type == FileSystemEntityType.notFound) {
      await _purgeEntry(sourcePath);
      return null;
    }

    final cached = await _loadMetadata(sourcePath);
    if (cached == null) {
      _setThumbnailPath(sourcePath, null);
      return null;
    }

    final thumbnailFile = File(cached.thumbnailPath);
    final isValid =
        await thumbnailFile.exists() &&
        cached.sourceModifiedAt.millisecondsSinceEpoch ==
            sourceStat.modified.millisecondsSinceEpoch &&
        cached.sourceSizeBytes == sourceStat.size;

    if (!isValid) {
      await _purgeEntry(sourcePath, thumbnailPath: cached.thumbnailPath);
      return null;
    }

    _setThumbnailPath(sourcePath, cached.thumbnailPath);
    return cached;
  }

  Future<ThumbnailCacheModel?> _loadMetadata(String sourcePath) async {
    if (_metadataBySourcePath.containsKey(sourcePath)) {
      return _metadataBySourcePath[sourcePath];
    }

    final metadata = await _repository.read(sourcePath);
    _metadataBySourcePath[sourcePath] = metadata;
    return metadata;
  }

  Future<void> _purgeEntry(String sourcePath, {String? thumbnailPath}) async {
    final cachedThumbnailPath =
        thumbnailPath ?? _metadataBySourcePath[sourcePath]?.thumbnailPath;
    await _repository.removePaths(<String>[sourcePath]);
    _metadataBySourcePath[sourcePath] = null;
    _setThumbnailPath(sourcePath, null);
    if (cachedThumbnailPath != null && cachedThumbnailPath.isNotEmpty) {
      await _deleteFileIfExists(cachedThumbnailPath);
    }
  }

  Future<Directory> _ensureThumbnailDirectory() async {
    final cachedDirectory = _thumbnailDirectory;
    if (cachedDirectory != null) {
      return cachedDirectory;
    }

    final baseDirectory = await getTemporaryDirectory();
    final thumbnailDirectory = Directory(
      pathinfo.join(baseDirectory.path, 'thumbnail_cache'),
    );
    if (!await thumbnailDirectory.exists()) {
      await thumbnailDirectory.create(recursive: true);
    }

    _thumbnailDirectory = thumbnailDirectory;
    return thumbnailDirectory;
  }

  Future<Uint8List?> _buildImageThumbnailBytes(File file) async {
    ui.Codec? codec;
    ui.Image? image;

    try {
      final sourceBytes = await file.readAsBytes();
      codec = await ui.instantiateImageCodec(
        sourceBytes,
        targetWidth: _thumbnailWidth,
      );
      final frame = await codec.getNextFrame();
      image = frame.image;
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      return byteData?.buffer.asUint8List();
    } catch (error) {
      debugPrint('Resim thumbnail olusturulamadi: ${file.path} -> $error');
      return null;
    } finally {
      image?.dispose();
      codec?.dispose();
    }
  }

  Future<Uint8List?> _buildVideoThumbnailBytes(File file) async {
    try {
      return await VideoThumbnail.thumbnailData(
        video: file.path,
        imageFormat: ImageFormat.JPEG,
        maxWidth: _thumbnailWidth,
        quality: _videoThumbnailQuality,
      );
    } catch (error) {
      debugPrint('Video thumbnail olusturulamadi: ${file.path} -> $error');
      return null;
    }
  }

  void _setThumbnailPath(String sourcePath, String? thumbnailPath) {
    final notifier = listenableFor(sourcePath);
    if (notifier.value == thumbnailPath) {
      return;
    }

    notifier.value = thumbnailPath;
  }

  Future<void> _deleteFileIfExists(String filePath) async {
    final file = File(filePath);
    if (!await file.exists()) {
      return;
    }

    await file.delete();
  }

  String _stableKey(String input) {
    var hash = 0xcbf29ce484222325;
    for (final codeUnit in input.codeUnits) {
      hash ^= codeUnit;
      hash = (hash * 0x100000001b3) & 0xFFFFFFFFFFFFFFFF;
    }

    return hash.toUnsigned(64).toRadixString(16).padLeft(16, '0');
  }
}

class _ThumbnailJob {
  const _ThumbnailJob(this.sourcePath);

  final String sourcePath;
}
