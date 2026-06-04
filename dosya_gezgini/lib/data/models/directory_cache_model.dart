class DirectoryCacheModel {
  const DirectoryCacheModel({
    required this.path,
    required this.folderPaths,
    required this.filePaths,
    required this.directoryModifiedAt,
    required this.updatedAt,
  });

  final String path;
  final List<String> folderPaths;
  final List<String> filePaths;
  final DateTime directoryModifiedAt;
  final DateTime updatedAt;

  int get totalCount => folderPaths.length + filePaths.length;

  bool isExpired(Duration maxAge, DateTime now) =>
      now.difference(updatedAt) > maxAge;

  bool matchesDirectoryModifiedAt(DateTime value) =>
      directoryModifiedAt.millisecondsSinceEpoch ==
      value.millisecondsSinceEpoch;

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'path': path,
      'folderPaths': folderPaths,
      'filePaths': filePaths,
      'directoryModifiedAt': directoryModifiedAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
    };
  }

  factory DirectoryCacheModel.fromMap(Map<dynamic, dynamic> map) {
    return DirectoryCacheModel(
      path: map['path'] as String? ?? '',
      folderPaths:
          (map['folderPaths'] as List<dynamic>? ?? const <dynamic>[])
              .whereType<String>()
              .toList(growable: false),
      filePaths:
          (map['filePaths'] as List<dynamic>? ?? const <dynamic>[])
              .whereType<String>()
              .toList(growable: false),
      directoryModifiedAt: DateTime.fromMillisecondsSinceEpoch(
        (map['directoryModifiedAt'] as num?)?.toInt() ?? 0,
      ),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(
        (map['updatedAt'] as num?)?.toInt() ?? 0,
      ),
    );
  }
}
