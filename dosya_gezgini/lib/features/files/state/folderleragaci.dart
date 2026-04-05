import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as pathinfo;

class FolderNode extends ChangeNotifier {
  FolderNode(
    this.name,
    this.path,
    List<FolderNode>? folderchildren,
    List<File>? filechildren,
    this.parent, {
    this.isVirtual = false,
    Set<String>? allowedExtensions,
  }) : folderchildren = folderchildren ?? [],
       filechildren = filechildren ?? [],
       allowedExtensions = allowedExtensions ?? const {} {
    if (!isVirtual) {
      _olusumtarihi();
    }
  }

  final bool isVirtual;
  final Set<String> allowedExtensions;

  String name;
  String path;
  List<FolderNode> folderchildren;
  List<File> filechildren;
  DateTime? olusumtarihi;
  FolderNode? parent;

  int get childCount => folderchildren.length + filechildren.length;

  String get formatlanmistarih {
    if (olusumtarihi == null) return "Bilinmiyor";
    return DateFormat('dd/MM/yyyy HH:mm').format(olusumtarihi!);
  }

  Future<void> _olusumtarihi() async {
    try {
      final stat = await FileStat.stat(path);
      olusumtarihi = stat.changed;
      notifyListeners();
    } catch (e) {
      debugPrint("Klasor tarihi okunamadi: $e");
    }
  }

  void replaceChildren({
    required List<FolderNode> folders,
    required List<File> files,
  }) {
    folderchildren = folders;
    filechildren = files;
    notifyListeners();
  }

  @override
  String toString() {
    return 'Folder: $name ($path)';
  }
}

class FileTree extends ChangeNotifier {
  FileTree(this.rootPath) : root = FolderNode("Root", rootPath, [], [], null);

  static const Set<String> _excelExtensions = {'.xls', '.xlsx'};
  static const Set<String> _imageExtensions = {'.jpg', '.jpeg', '.png'};
  static const Set<String> _videoExtensions = {'.mp4', '.mkv', '.avi', '.mov'};
  static const Set<String> _audioExtensions = {'.mp3', '.wav', '.aac', '.ogg'};
  static const Set<String> _wordExtensions = {'.doc', '.docx'};
  static const Set<String> _powerPointExtensions = {'.ppt', '.pptx'};
  static const Set<String> _zipExtensions = {'.zip', '.rar', '.7z'};
  static const Set<String> _pdfExtensions = {'.pdf'};
  static const Set<String> _txtExtensions = {'.txt'};
  static const Set<String> _knownExtensions = {
    ..._excelExtensions,
    ..._imageExtensions,
    ..._videoExtensions,
    ..._audioExtensions,
    ..._wordExtensions,
    ..._powerPointExtensions,
    ..._zipExtensions,
    ..._pdfExtensions,
    ..._txtExtensions,
  };

  final String rootPath;
  final FolderNode root;

  bool isSearching = false;

  final List<FolderNode> arananfolder = [];
  final List<File> arananfile = [];
  final List<FolderNode> kaydedilenfolder = [];
  final List<File> kaydedilenfile = [];
  final List<FolderNode> gizlenenfolder = [];
  final List<File> gizlenenfile = [];
  final List<FolderNode> ensongezilenfolders = [];
  final List<File> ensongezilenfiles = [];

  late final FolderNode bilinmeyendosya = _createCategoryNode(
    'bilinmeyen dosyalar',
  );
  late final FolderNode exceldosya = _createCategoryNode(
    'excel dosyalari',
    allowedExtensions: _excelExtensions,
  );
  late final FolderNode resimdosya = _createCategoryNode(
    'resim dosyalari',
    allowedExtensions: _imageExtensions,
  );
  late final FolderNode videodosya = _createCategoryNode(
    'video dosyalari',
    allowedExtensions: _videoExtensions,
  );
  late final FolderNode sesdosya = _createCategoryNode(
    'ses dosyalari',
    allowedExtensions: _audioExtensions,
  );
  late final FolderNode worddosya = _createCategoryNode(
    'word dosyalari',
    allowedExtensions: _wordExtensions,
  );
  late final FolderNode zipdosya = _createCategoryNode(
    'zip dosyalari',
    allowedExtensions: _zipExtensions,
  );
  late final FolderNode pdfdosya = _createCategoryNode(
    'pdf dosyalari',
    allowedExtensions: _pdfExtensions,
  );
  late final FolderNode txtdosya = _createCategoryNode(
    'txt dosyalari',
    allowedExtensions: _txtExtensions,
  );
  late final FolderNode powerpointdosya = _createCategoryNode(
    'powerpoint dosyalari',
    allowedExtensions: _powerPointExtensions,
  );

  FolderNode _createCategoryNode(
    String name, {
    Set<String> allowedExtensions = const {},
  }) {
    return FolderNode(
      name,
      'virtual:$name',
      [],
      [],
      root,
      isVirtual: true,
      allowedExtensions: allowedExtensions,
    );
  }

  Future<FolderNode> buildTree() async {
    await loadFolder(root);
    return root;
  }

  Future<void> loadFolder(FolderNode folder) async {
    if (folder.isVirtual) {
      await _loadCategoryFolder(folder);
    } else {
      await _loadDirectoryFolder(folder);
    }
    notifyListeners();
  }

  Future<void> _loadDirectoryFolder(FolderNode folder) async {
    final dir = Directory(folder.path);
    if (!await dir.exists()) {
      folder.replaceChildren(folders: [], files: []);
      return;
    }

    final folders = <FolderNode>[];
    final files = <File>[];

    try {
      await for (final entity in dir.list(followLinks: false)) {
        final name = pathinfo.basename(entity.path);
        if (entity is Directory) {
          folders.add(FolderNode(name, entity.path, [], [], folder));
        } else if (entity is File) {
          files.add(File(entity.path));
        }
      }
    } catch (e) {
      debugPrint("Klasor okunamadi ${folder.path}: $e");
    }

    folders.sort(
      (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
    );
    files.sort(
      (a, b) => pathinfo
          .basename(a.path)
          .toLowerCase()
          .compareTo(pathinfo.basename(b.path).toLowerCase()),
    );

    folder.replaceChildren(folders: folders, files: files);
  }

  Future<void> _loadCategoryFolder(FolderNode folder) async {
    final files = <File>[];
    final rootDirectory = Directory(rootPath);
    if (!await rootDirectory.exists()) {
      folder.replaceChildren(folders: [], files: []);
      return;
    }

    try {
      await for (final entity in rootDirectory.list(
        recursive: true,
        followLinks: false,
      )) {
        if (entity is! File) {
          continue;
        }

        final file = File(entity.path);
        final extension = pathinfo.extension(file.path).toLowerCase();
        final isUnknownCategory =
            identical(folder, bilinmeyendosya) &&
            !_knownExtensions.contains(extension);
        final isKnownCategory = folder.allowedExtensions.contains(extension);

        if (isUnknownCategory || isKnownCategory) {
          files.add(file);
        }
      }
    } catch (e) {
      debugPrint("Kategori taramasi basarisiz ${folder.name}: $e");
    }

    files.sort(
      (a, b) => pathinfo
          .basename(a.path)
          .toLowerCase()
          .compareTo(pathinfo.basename(b.path).toLowerCase()),
    );
    folder.replaceChildren(folders: [], files: files);
  }

  void ekraniguncelle() {
    notifyListeners();
  }

  Future<void> agactaarama(String aranan) async {
    isSearching = true;
    notifyListeners();

    arananfolder.clear();
    arananfile.clear();

    if (aranan.trim().isEmpty) {
      isSearching = false;
      notifyListeners();
      return;
    }

    final query = aranan.toLowerCase();
    final rootDirectory = Directory(rootPath);

    if (!await rootDirectory.exists()) {
      isSearching = false;
      notifyListeners();
      return;
    }

    try {
      await for (final entity in rootDirectory.list(
        recursive: true,
        followLinks: false,
      )) {
        final entityName = pathinfo.basename(entity.path);
        final lowerName = entityName.toLowerCase();

        if (entity is Directory && lowerName.contains(query)) {
          arananfolder.add(FolderNode(entityName, entity.path, [], [], null));
        } else if (entity is File && lowerName.startsWith(query)) {
          arananfile.add(File(entity.path));
        }
      }
    } catch (e) {
      debugPrint("Arama sirasinda hata olustu: $e");
    }

    arananfolder.sort(
      (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
    );
    arananfile.sort(
      (a, b) => pathinfo
          .basename(a.path)
          .toLowerCase()
          .compareTo(pathinfo.basename(b.path).toLowerCase()),
    );

    isSearching = false;
    notifyListeners();
  }
}
