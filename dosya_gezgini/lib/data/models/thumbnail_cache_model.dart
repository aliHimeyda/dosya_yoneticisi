class ThumbnailCacheModel {
  const ThumbnailCacheModel({
    required this.sourcePath,
    required this.thumbnailPath,
    required this.kind,
    required this.sourceModifiedAt,
    required this.sourceSizeBytes,
    required this.updatedAt,
  });

  final String sourcePath;
  final String thumbnailPath;
  final String kind;
  final DateTime sourceModifiedAt;
  final int sourceSizeBytes;
  final DateTime updatedAt;

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'sourcePath': sourcePath,
      'thumbnailPath': thumbnailPath,
      'kind': kind,
      'sourceModifiedAt': sourceModifiedAt.millisecondsSinceEpoch,
      'sourceSizeBytes': sourceSizeBytes,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
    };
  }

  factory ThumbnailCacheModel.fromMap(Map<dynamic, dynamic> map) {
    return ThumbnailCacheModel(
      sourcePath: map['sourcePath'] as String? ?? '',
      thumbnailPath: map['thumbnailPath'] as String? ?? '',
      kind: map['kind'] as String? ?? 'unknown',
      sourceModifiedAt: DateTime.fromMillisecondsSinceEpoch(
        (map['sourceModifiedAt'] as num?)?.toInt() ?? 0,
      ),
      sourceSizeBytes: (map['sourceSizeBytes'] as num?)?.toInt() ?? 0,
      updatedAt: DateTime.fromMillisecondsSinceEpoch(
        (map['updatedAt'] as num?)?.toInt() ?? 0,
      ),
    );
  }
}
