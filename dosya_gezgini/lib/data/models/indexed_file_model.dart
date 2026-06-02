import 'dart:io';

class IndexedFileModel {
  const IndexedFileModel({
    required this.path,
    required this.name,
    required this.extension,
    required this.mimeType,
    required this.size,
    required this.modifiedAt,
    required this.parentPath,
    required this.isDirectory,
    required this.category,
    required this.indexedAt,
  });

  final String path;
  final String name;
  final String extension;
  final String mimeType;
  final int size;
  final DateTime modifiedAt;
  final String parentPath;
  final bool isDirectory;
  final String category;
  final DateTime indexedAt;

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'path': path,
      'name': name,
      'extension': extension,
      'mimeType': mimeType,
      'size': size,
      'modifiedAt': modifiedAt.millisecondsSinceEpoch,
      'parentPath': parentPath,
      'isDirectory': isDirectory,
      'category': category,
      'indexedAt': indexedAt.millisecondsSinceEpoch,
    };
  }

  factory IndexedFileModel.fromMap(Map<dynamic, dynamic> map) {
    return IndexedFileModel(
      path: map['path'] as String? ?? '',
      name: map['name'] as String? ?? '',
      extension: map['extension'] as String? ?? '',
      mimeType: map['mimeType'] as String? ?? 'application/octet-stream',
      size: (map['size'] as num?)?.toInt() ?? 0,
      modifiedAt: DateTime.fromMillisecondsSinceEpoch(
        (map['modifiedAt'] as num?)?.toInt() ?? 0,
      ),
      parentPath: map['parentPath'] as String? ?? '',
      isDirectory: map['isDirectory'] as bool? ?? false,
      category: map['category'] as String? ?? '',
      indexedAt: DateTime.fromMillisecondsSinceEpoch(
        (map['indexedAt'] as num?)?.toInt() ?? 0,
      ),
    );
  }

  File toFile() => File(path);
}
