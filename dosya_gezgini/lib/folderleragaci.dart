import 'dart:io';
import 'package:dosya_gezgini/anasayfaicerigi.dart';
import 'package:dosya_gezgini/dosya_folder.dart';
import 'package:dosya_gezgini/main.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
// ignore: depend_on_referenced_packages
import 'package:path/path.dart' as pathinfo;
import 'package:provider/provider.dart';

class FolderNode extends ChangeNotifier {
  String name;
  String path;
  List<FolderNode> folderchildren;
  List<File> filechildren;
  DateTime? olusumtarihi;
  FolderNode? parent;
  String get formatlanmistarih {
    if (olusumtarihi == null) return "Bilinmiyor";
    return DateFormat('dd/MM/yyyy HH:mm').format(olusumtarihi!);
  }

  FolderNode(
    this.name,
    this.path,
    this.folderchildren,
    this.filechildren,
    this.parent,
  ) {
    _olusumtarihi();
    debugPrint('$name isimli klasör $path konumuna yerleştirildi');
  }

  Future<void> _olusumtarihi() async {
    try {
      FileStat stat = await FileStat.stat(path);
      olusumtarihi = stat.changed;
      notifyListeners(); // Değişiklikleri bildir
    } catch (e) {
      debugPrint("Klasörün oluşturulma tarihi alınamadı: $e");
    }
  }

  void addfolderChild(FolderNode child) {
    if (folderchildren.contains(child)) {
      throw Exception('Bu klasör zaten mevcut !!!');
    } else {
      folderchildren.add(child);
      debugPrint(
        '${child.name} isimli klasor $name klasor icine eklendi !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!1',
      );
      notifyListeners();
    }
  }

  bool removeNode(String targetPath) {
    // 🔥 Eğer silinmek istenen bir alt klasörse, onu bulup kaldır
    folderchildren.removeWhere((folder) => folder.path == targetPath);

    // 🔥 Eğer silinmek istenen bir dosyaysa, onu bulup kaldır
    filechildren.removeWhere((file) => file.path == targetPath);

    return true; // 📌 Silme başarılı oldu
  }

  void removefolderChild(FolderNode child) {
    folderchildren.remove(child);
    notifyListeners();
    throw Exception('Klasör silindi');
  }

  void addfileChild(File child) {
    if (filechildren.contains(child)) {
      throw Exception('Bu dosya zaten mevcut !!!');
    } else {
      String named = pathinfo.basename(child.path);
      filechildren.add(child);
      debugPrint(
        '$named isimli dosya $name klasor icine eklendi !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!1',
      );

      notifyListeners();
    }
  }

  void removefileChild(File child) {
    filechildren.remove(child);
    notifyListeners();
  }

  @override
  String toString() {
    return 'Folder: $name ($path), Created At: $olusumtarihi';
  }
}

class FileTree extends ChangeNotifier {
  FolderNode root;
  FileTree(String rootPath) : root = FolderNode("Root", rootPath, [], [], null);
  bool isSearching = false; //  Yüklenme durumu icin

  late List<Klasor> arananfolder = [];
  late List<Dosya> arananfile = [];

  Future<FolderNode> buildTree() async {
    await _buildTree(root);
    return root;
  }

  Future<void> agactadugumarama(String silinecek) async {
    await _agactansil(root, silinecek);
  }

  void ekraniguncelle() {
    notifyListeners();
  }

  Future<void> _agactansil(FolderNode node, String silinecek) async {
    if (node.filechildren.isNotEmpty) {
      for (File child in node.filechildren) {
        if (pathinfo
            .basename(child.path)
            .toLowerCase()
            .startsWith(silinecek.toLowerCase())) {
          node.filechildren.remove(child);
          notifyListeners();
        }
      }
    }
    if (node.folderchildren.isNotEmpty) {
      for (FolderNode child in node.folderchildren) {
        if (child.name.toLowerCase().startsWith(silinecek.toLowerCase())) {
          node.folderchildren.remove(child);
          notifyListeners();
        }
        await _agactansil(child, silinecek);
      }
    }
  }

  Future<FolderNode?> parentiguncelle(
    FolderNode node,
    String parentismi,
  ) async {
    if (node.name.toLowerCase().startsWith(parentismi.toLowerCase())) {
      return node;
    } else if (node.folderchildren.isNotEmpty) {
      for (FolderNode child in node.folderchildren) {
        await parentiguncelle(child, parentismi);
      }
    }
  }

  Future<void> agactaarama(String aranan) async {
    isSearching = true;
    notifyListeners();

    if (aranan.isEmpty) {
      arananfolder.clear();
      arananfile.clear();
      isSearching = false;
      notifyListeners();
      return;
    }
    arananfolder.clear();
    arananfile.clear();
    await _agactaarama(root, aranan);
    isSearching = false;
    notifyListeners();
  }

  Future<void> _agactaarama(FolderNode node, String aranan) async {
    if (node.name.toLowerCase().startsWith(aranan.toLowerCase())) {
      arananfolder.add(Klasor(name: node.name, path: node.path, klasor: node));
    }

    for (File child in node.filechildren) {
      if (pathinfo
          .basename(child.path)
          .toLowerCase()
          .startsWith(aranan.toLowerCase())) {
        arananfile.add(Dosya(file: child));
      }
    }

    for (FolderNode child in node.folderchildren) {
      await _agactaarama(child, aranan);
    }
  }

  Future<void> _buildTree(FolderNode node) async {
    Directory dir = Directory(node.path);
    if (!dir.existsSync()) return;
    try {
      List<FileSystemEntity> entities = dir.listSync();
      for (var entity in entities) {
        String name = pathinfo.basename(entity.path);
        if (entity is Directory) {
          FolderNode folder = FolderNode(name, entity.path, [], [], node);
          node.addfolderChild(folder);
          _buildTree(folder);
        } else if (entity is File) {
          File file = File(entity.path);
          node.addfileChild(file);
        }
      }
    } catch (e) {
      debugPrint("Error reading ${node.path}: $e");
    }
  }

  // Future<void> printTree([FolderNode? node, int level = 0]) async {
  //   node ??= root;
  //   debugPrint('$level- ${node.name}');
  //   for (var child in node.children) {
  //     await printTree(child, level + 1);
  //   }
  // }

  // void agacitanima(BuildContext context) async {
  //   final izinProvider = Provider.of<Izinler>(context, listen: false);
  //   izinProvider.requestAllStoragePermission();

  // }
}
