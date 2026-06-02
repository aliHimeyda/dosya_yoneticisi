class FileIndexMetadata {
  const FileIndexMetadata({
    required this.rootPath,
    required this.indexedAt,
    required this.itemCount,
    required this.schemaVersion,
  });

  final String rootPath;
  final DateTime indexedAt;
  final int itemCount;
  final int schemaVersion;

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'rootPath': rootPath,
      'indexedAt': indexedAt.millisecondsSinceEpoch,
      'itemCount': itemCount,
      'schemaVersion': schemaVersion,
    };
  }

  factory FileIndexMetadata.fromMap(Map<dynamic, dynamic> map) {
    return FileIndexMetadata(
      rootPath: map['rootPath'] as String? ?? '',
      indexedAt: DateTime.fromMillisecondsSinceEpoch(
        (map['indexedAt'] as num?)?.toInt() ?? 0,
      ),
      itemCount: (map['itemCount'] as num?)?.toInt() ?? 0,
      schemaVersion: (map['schemaVersion'] as num?)?.toInt() ?? 0,
    );
  }
}
