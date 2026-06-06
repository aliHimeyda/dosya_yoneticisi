import 'dart:io';
import 'dart:isolate';

import 'package:dosya_gezgini/core/constants/storage_paths.dart';

class DownloadsStatusService {
  DownloadsStatusService({String? downloadsPath})
    : _downloadsPath = downloadsPath ?? '$storageRootPath/Download';

  final String _downloadsPath;

  String get downloadsPath => _downloadsPath;

  Future<int> getDownloadsSizeBytes() async {
    final downloadsDirectory = Directory(_downloadsPath);
    if (!await downloadsDirectory.exists()) {
      return 0;
    }

    return Isolate.run<int>(() => _computeDownloadsSize(_downloadsPath));
  }
}

Future<int> _computeDownloadsSize(String downloadsPath) async {
  final downloadsDirectory = Directory(downloadsPath);
  if (!await downloadsDirectory.exists()) {
    return 0;
  }

  var totalBytes = 0;

  await for (final entity in downloadsDirectory.list(
    recursive: true,
    followLinks: false,
  )) {
    if (entity is! File) {
      continue;
    }

    try {
      totalBytes += await entity.length();
    } on FileSystemException {
      // Skip files that disappear or become unreadable during traversal.
    }
  }

  return totalBytes;
}
