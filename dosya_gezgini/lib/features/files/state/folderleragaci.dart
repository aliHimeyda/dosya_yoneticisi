import 'dart:io';

import 'package:dosya_gezgini/data/constants/file_category_constants.dart';
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

class FolderLoadResult {
  const FolderLoadResult.success() : error = null;
  const FolderLoadResult.failure(this.error);

  final Object? error;

  bool get hasError => error != null;
}

class FileTree extends ChangeNotifier {
  FileTree(this.rootPath) : root = FolderNode("Root", rootPath, [], [], null);

  static const int _progressChunkSize = 25;

  final String rootPath;
  final FolderNode root;
  Set<String> _hiddenPaths = <String>{};
  final List<FolderNode> kaydedilenfolder = [];
  final List<File> kaydedilenfile = [];
  final List<FolderNode> gizlenenfolder = [];
  final List<File> gizlenenfile = [];
  final List<FolderNode> ensongezilenfolders = [];
  final List<File> ensongezilenfiles = [];

  void addRecentFolder(FolderNode folder) {
    ensongezilenfolders.removeWhere((item) => item.path == folder.path);
    ensongezilenfolders.insert(0, folder);
    notifyListeners();
  }

  void addRecentFile(File file) {
    ensongezilenfiles.removeWhere((item) => item.path == file.path);
    ensongezilenfiles.insert(0, file);
    notifyListeners();
  }

  void setSavedItems({
    required List<FolderNode> folders,
    required List<File> files,
  }) {
    kaydedilenfolder
      ..clear()
      ..addAll(folders);
    kaydedilenfile
      ..clear()
      ..addAll(files);
    notifyListeners();
  }

  void setHiddenItems({
    required List<FolderNode> folders,
    required List<File> files,
  }) {
    gizlenenfolder
      ..clear()
      ..addAll(folders);
    gizlenenfile
      ..clear()
      ..addAll(files);
    notifyListeners();
  }

  void setRecentItems({
    required List<FolderNode> folders,
    required List<File> files,
  }) {
    ensongezilenfolders
      ..clear()
      ..addAll(folders);
    ensongezilenfiles
      ..clear()
      ..addAll(files);
    notifyListeners();
  }

  void setHiddenPaths(Set<String> hiddenPaths) {
    _hiddenPaths = Set<String>.from(hiddenPaths);
    notifyListeners();
  }

  late final FolderNode bilinmeyendosya = _createCategoryNode(
    FileCategoryConstants.unknown,
  );
  late final FolderNode exceldosya = _createCategoryNode(
    FileCategoryConstants.excel,
  );
  late final FolderNode resimdosya = _createCategoryNode(
    FileCategoryConstants.image,
  );
  late final FolderNode videodosya = _createCategoryNode(
    FileCategoryConstants.video,
  );
  late final FolderNode sesdosya = _createCategoryNode(
    FileCategoryConstants.audio,
  );
  late final FolderNode worddosya = _createCategoryNode(
    FileCategoryConstants.word,
  );
  late final FolderNode zipdosya = _createCategoryNode(
    FileCategoryConstants.archive,
  );
  late final FolderNode pdfdosya = _createCategoryNode(
    FileCategoryConstants.pdf,
  );
  late final FolderNode txtdosya = _createCategoryNode(
    FileCategoryConstants.text,
  );
  late final FolderNode powerpointdosya = _createCategoryNode(
    FileCategoryConstants.powerPoint,
  );

  List<FolderNode> get _virtualFolders => [
    bilinmeyendosya,
    exceldosya,
    resimdosya,
    videodosya,
    sesdosya,
    worddosya,
    zipdosya,
    pdfdosya,
    txtdosya,
    powerpointdosya,
  ];

  FolderNode _createCategoryNode(FileCategoryDefinition category) {
    return FolderNode(
      category.folderName,
      category.virtualPath,
      [],
      [],
      root,
      isVirtual: true,
      allowedExtensions: category.extensions,
    );
  }

  Future<FolderNode> buildTree() async {
    await loadFolder(root);
    return root;
  }

  FolderNode? findKnownFolder(String path) {
    if (root.path == path) {
      return root;
    }

    for (final folder in _virtualFolders) {
      if (folder.path == path) {
        return folder;
      }
    }

    return null;
  }

  Future<FolderLoadResult> loadFolder(
    FolderNode folder, {
    ValueChanged<FolderNode>? onProgress,
  }) async {
    if (folder.isVirtual) {
      _emitFolderSnapshot(
        folder,
        folders: folder.folderchildren,
        files: folder.filechildren,
        onProgress: onProgress,
      );
      notifyListeners();
      return const FolderLoadResult.success();
    }

    final result = await _loadDirectoryFolder(folder, onProgress: onProgress);
    notifyListeners();
    return result;
  }

  Future<FolderLoadResult> _loadDirectoryFolder(
    FolderNode folder, {
    ValueChanged<FolderNode>? onProgress,
  }) async {
    final dir = Directory(folder.path);
    if (!await dir.exists()) {
      folder.replaceChildren(folders: [], files: []);
      return const FolderLoadResult.failure('directory_not_found');
    }

    final folders = <FolderNode>[];
    final files = <File>[];

    try {
      var processedItems = 0;
      await for (final entity in dir.list(followLinks: false)) {
        if (_hiddenPaths.contains(entity.path)) {
          continue;
        }

        final name = pathinfo.basename(entity.path);
        if (entity is Directory) {
          folders.add(FolderNode(name, entity.path, [], [], folder));
        } else if (entity is File) {
          files.add(File(entity.path));
        }

        processedItems++;
        if (processedItems % _progressChunkSize == 0) {
          _emitFolderSnapshot(
            folder,
            folders: folders,
            files: files,
            onProgress: onProgress,
          );
        }
      }
    } catch (e) {
      debugPrint("Klasor okunamadi ${folder.path}: $e");
      if (folders.isEmpty && files.isEmpty) {
        folder.replaceChildren(folders: [], files: []);
      }
      return FolderLoadResult.failure(e);
    }

    _emitFolderSnapshot(
      folder,
      folders: folders,
      files: files,
      onProgress: onProgress,
    );
    return const FolderLoadResult.success();
  }

  void _emitFolderSnapshot(
    FolderNode folder, {
    required List<FolderNode> folders,
    required List<File> files,
    ValueChanged<FolderNode>? onProgress,
  }) {
    _sortEntries(folders, files);
    folder.replaceChildren(
      folders: List<FolderNode>.from(folders),
      files: List<File>.from(files),
    );
    onProgress?.call(folder);
  }

  void _sortEntries(List<FolderNode> folders, List<File> files) {
    folders.sort(
      (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
    );
    files.sort(
      (a, b) => pathinfo
          .basename(a.path)
          .toLowerCase()
          .compareTo(pathinfo.basename(b.path).toLowerCase()),
    );
  }

  void ekraniguncelle() {
    notifyListeners();
  }
}
