class FolderCountModel {
  const FolderCountModel({
    required this.path,
    required this.folderCount,
    required this.fileCount,
    required this.totalCount,
    required this.isLoaded,
    required this.updatedAt,
  });

  final String path;
  final int folderCount;
  final int fileCount;
  final int totalCount;
  final bool isLoaded;
  final DateTime updatedAt;

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'path': path,
      'folderCount': folderCount,
      'fileCount': fileCount,
      'totalCount': totalCount,
      'isLoaded': isLoaded,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
    };
  }

  factory FolderCountModel.fromMap(Map<dynamic, dynamic> map) {
    final resolvedFolderCount = (map['folderCount'] as num?)?.toInt() ?? 0;
    final resolvedFileCount = (map['fileCount'] as num?)?.toInt() ?? 0;
    final resolvedTotalCount =
        (map['totalCount'] as num?)?.toInt() ??
        resolvedFolderCount + resolvedFileCount;

    return FolderCountModel(
      path: map['path'] as String? ?? '',
      folderCount: resolvedFolderCount,
      fileCount: resolvedFileCount,
      totalCount: resolvedTotalCount,
      isLoaded: map['isLoaded'] as bool? ?? false,
      updatedAt: DateTime.fromMillisecondsSinceEpoch(
        (map['updatedAt'] as num?)?.toInt() ?? 0,
      ),
    );
  }
}
