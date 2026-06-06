import 'dart:io';

import 'package:dosya_gezgini/data/models/indexed_file_model.dart';

class FileMetadataModel {
  const FileMetadataModel({
    required this.path,
    required this.name,
    required this.sizeBytes,
    required this.modifiedAt,
    required this.updatedAt,
    required this.exists,
    required this.extension,
    required this.parentPath,
  });

  final String path;
  final String name;
  final int sizeBytes;
  final DateTime modifiedAt;
  final DateTime updatedAt;
  final bool exists;
  final String extension;
  final String parentPath;

  bool matchesFileStat(FileStat stat) {
    return exists &&
        stat.type == FileSystemEntityType.file &&
        sizeBytes == stat.size &&
        modifiedAt.millisecondsSinceEpoch == stat.modified.millisecondsSinceEpoch;
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'path': path,
      'name': name,
      'sizeBytes': sizeBytes,
      'modifiedAt': modifiedAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
      'exists': exists,
      'extension': extension,
      'parentPath': parentPath,
    };
  }

  factory FileMetadataModel.fromMap(Map<dynamic, dynamic> map) {
    return FileMetadataModel(
      path: map['path'] as String? ?? '',
      name: map['name'] as String? ?? '',
      sizeBytes: (map['sizeBytes'] as num?)?.toInt() ?? 0,
      modifiedAt: DateTime.fromMillisecondsSinceEpoch(
        (map['modifiedAt'] as num?)?.toInt() ?? 0,
      ),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(
        (map['updatedAt'] as num?)?.toInt() ?? 0,
      ),
      exists: map['exists'] as bool? ?? true,
      extension: map['extension'] as String? ?? '',
      parentPath: map['parentPath'] as String? ?? '',
    );
  }

  factory FileMetadataModel.fromIndexedFile(IndexedFileModel item) {
    return FileMetadataModel(
      path: item.path,
      name: item.name,
      sizeBytes: item.size,
      modifiedAt: item.modifiedAt,
      updatedAt: item.indexedAt,
      exists: true,
      extension: item.extension,
      parentPath: item.parentPath,
    );
  }
}
