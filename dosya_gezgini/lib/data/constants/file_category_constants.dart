import 'package:path/path.dart' as pathinfo;

class FileCategoryIds {
  FileCategoryIds._();

  static const String unknown = 'unknown';
  static const String excel = 'excel';
  static const String image = 'image';
  static const String video = 'video';
  static const String audio = 'audio';
  static const String word = 'word';
  static const String powerPoint = 'powerpoint';
  static const String archive = 'archive';
  static const String pdf = 'pdf';
  static const String text = 'text';
}

class FileCategoryDefinition {
  const FileCategoryDefinition({
    required this.id,
    required this.folderName,
    required this.virtualPath,
    required this.extensions,
  });

  final String id;
  final String folderName;
  final String virtualPath;
  final Set<String> extensions;
}

class FileCategoryConstants {
  FileCategoryConstants._();

  static const FileCategoryDefinition unknown = FileCategoryDefinition(
    id: FileCategoryIds.unknown,
    folderName: 'bilinmeyen dosyalar',
    virtualPath: 'virtual:bilinmeyen dosyalar',
    extensions: <String>{},
  );

  static const FileCategoryDefinition excel = FileCategoryDefinition(
    id: FileCategoryIds.excel,
    folderName: 'excel dosyalari',
    virtualPath: 'virtual:excel dosyalari',
    extensions: <String>{'.xls', '.xlsx'},
  );

  static const FileCategoryDefinition image = FileCategoryDefinition(
    id: FileCategoryIds.image,
    folderName: 'resim dosyalari',
    virtualPath: 'virtual:resim dosyalari',
    extensions: <String>{'.jpg', '.jpeg', '.png', '.webp', '.gif', '.bmp'},
  );

  static const FileCategoryDefinition video = FileCategoryDefinition(
    id: FileCategoryIds.video,
    folderName: 'video dosyalari',
    virtualPath: 'virtual:video dosyalari',
    extensions: <String>{'.mp4', '.mkv', '.avi', '.mov', '.m4v', '.webm'},
  );

  static const FileCategoryDefinition audio = FileCategoryDefinition(
    id: FileCategoryIds.audio,
    folderName: 'ses dosyalari',
    virtualPath: 'virtual:ses dosyalari',
    extensions: <String>{'.mp3', '.wav', '.aac', '.ogg', '.flac'},
  );

  static const FileCategoryDefinition word = FileCategoryDefinition(
    id: FileCategoryIds.word,
    folderName: 'word dosyalari',
    virtualPath: 'virtual:word dosyalari',
    extensions: <String>{'.doc', '.docx'},
  );

  static const FileCategoryDefinition powerPoint = FileCategoryDefinition(
    id: FileCategoryIds.powerPoint,
    folderName: 'powerpoint dosyalari',
    virtualPath: 'virtual:powerpoint dosyalari',
    extensions: <String>{'.ppt', '.pptx'},
  );

  static const FileCategoryDefinition archive = FileCategoryDefinition(
    id: FileCategoryIds.archive,
    folderName: 'zip dosyalari',
    virtualPath: 'virtual:zip dosyalari',
    extensions: <String>{'.zip', '.rar', '.7z', '.tar', '.gz'},
  );

  static const FileCategoryDefinition pdf = FileCategoryDefinition(
    id: FileCategoryIds.pdf,
    folderName: 'pdf dosyalari',
    virtualPath: 'virtual:pdf dosyalari',
    extensions: <String>{'.pdf'},
  );

  static const FileCategoryDefinition text = FileCategoryDefinition(
    id: FileCategoryIds.text,
    folderName: 'txt dosyalari',
    virtualPath: 'virtual:txt dosyalari',
    extensions: <String>{'.txt', '.md', '.json', '.csv', '.log'},
  );

  static const List<FileCategoryDefinition> definitions = <FileCategoryDefinition>[
    unknown,
    excel,
    image,
    video,
    audio,
    word,
    powerPoint,
    archive,
    pdf,
    text,
  ];

  static final Map<String, FileCategoryDefinition> _byVirtualPath =
      <String, FileCategoryDefinition>{
        for (final definition in definitions) definition.virtualPath: definition,
      };

  static final Map<String, FileCategoryDefinition> _byId =
      <String, FileCategoryDefinition>{
        for (final definition in definitions) definition.id: definition,
      };

  static final Map<String, String> _extensionToCategory =
      <String, String>{
        for (final definition in definitions.where(
          (item) => item.id != FileCategoryIds.unknown,
        ))
          for (final extension in definition.extensions) extension: definition.id,
      };

  static String? categoryIdFromVirtualPath(String virtualPath) {
    return _byVirtualPath[virtualPath]?.id;
  }

  static FileCategoryDefinition? definitionForCategoryId(String categoryId) {
    return _byId[categoryId];
  }

  static String resolveCategoryFromPath(String filePath) {
    final extension = pathinfo.extension(filePath).toLowerCase();
    return _extensionToCategory[extension] ?? FileCategoryIds.unknown;
  }

  static String resolveMimeType(String filePath) {
    final extension = pathinfo.extension(filePath).toLowerCase();
    switch (extension) {
      case '.jpg':
      case '.jpeg':
        return 'image/jpeg';
      case '.png':
        return 'image/png';
      case '.webp':
        return 'image/webp';
      case '.gif':
        return 'image/gif';
      case '.bmp':
        return 'image/bmp';
      case '.mp4':
        return 'video/mp4';
      case '.mkv':
        return 'video/x-matroska';
      case '.avi':
        return 'video/x-msvideo';
      case '.mov':
        return 'video/quicktime';
      case '.m4v':
        return 'video/x-m4v';
      case '.webm':
        return 'video/webm';
      case '.mp3':
        return 'audio/mpeg';
      case '.wav':
        return 'audio/wav';
      case '.aac':
        return 'audio/aac';
      case '.ogg':
        return 'audio/ogg';
      case '.flac':
        return 'audio/flac';
      case '.pdf':
        return 'application/pdf';
      case '.doc':
      case '.docx':
        return 'application/msword';
      case '.xls':
      case '.xlsx':
        return 'application/vnd.ms-excel';
      case '.ppt':
      case '.pptx':
        return 'application/vnd.ms-powerpoint';
      case '.zip':
      case '.rar':
      case '.7z':
      case '.tar':
      case '.gz':
        return 'application/zip';
      case '.txt':
      case '.md':
      case '.json':
      case '.csv':
      case '.log':
        return 'text/plain';
      default:
        return 'application/octet-stream';
    }
  }
}
