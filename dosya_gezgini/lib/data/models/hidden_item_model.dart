class HiddenItemModel {
  const HiddenItemModel({
    required this.path,
    required this.isDirectory,
    required this.updatedAt,
  });

  final String path;
  final bool isDirectory;
  final DateTime updatedAt;

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'path': path,
      'isDirectory': isDirectory,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
    };
  }

  factory HiddenItemModel.fromMap(Map<dynamic, dynamic> map) {
    return HiddenItemModel(
      path: map['path'] as String? ?? '',
      isDirectory: map['isDirectory'] as bool? ?? false,
      updatedAt: DateTime.fromMillisecondsSinceEpoch(
        (map['updatedAt'] as num?)?.toInt() ?? 0,
      ),
    );
  }
}
