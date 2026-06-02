import 'dart:io';

import 'package:dosya_gezgini/data/constants/file_category_constants.dart';
import 'package:dosya_gezgini/data/models/indexed_file_model.dart';
import 'package:path/path.dart' as pathinfo;

class FileSystemService {
  Stream<IndexedFileModel> scanEntries(String rootPath) async* {
    final rootDirectory = Directory(rootPath);
    if (!await rootDirectory.exists()) {
      throw FileSystemException('scan_root_not_found', rootPath);
    }

    final entityStream = rootDirectory
        .list(recursive: true, followLinks: false)
        .handleError((Object error, StackTrace stackTrace) {
          // Some Android system folders reject recursive traversal.
          // Skip those branches and continue indexing the rest of storage.
        }, test: (dynamic error) => error is FileSystemException);

    await for (final entity in entityStream) {
      try {
        final stat = await entity.stat();
        final isDirectory = entity is Directory;
        final now = DateTime.now();
        yield IndexedFileModel(
          path: entity.path,
          name: pathinfo.basename(entity.path),
          extension:
              isDirectory ? '' : pathinfo.extension(entity.path).toLowerCase(),
          mimeType:
              isDirectory
                  ? 'inode/directory'
                  : FileCategoryConstants.resolveMimeType(entity.path),
          size: stat.size,
          modifiedAt: stat.modified,
          parentPath: pathinfo.dirname(entity.path),
          isDirectory: isDirectory,
          category:
              isDirectory
                  ? ''
                  : FileCategoryConstants.resolveCategoryFromPath(entity.path),
          indexedAt: now,
        );
      } on FileSystemException {
        continue;
      }
    }
  }
}
