import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
// ignore: depend_on_referenced_packages
import 'package:path/path.dart' as pathinfo;

class FolderNode extends ChangeNotifier {
  String name;
  String path;
  List<FolderNode> folderchildren;
  List<File> filechildren;
  DateTime? olusumtarihi;
  String get formatlanmistarih {
    if (olusumtarihi == null) return "Bilinmiyor";
    return DateFormat('dd/MM/yyyy HH:mm').format(olusumtarihi!);
  }

  FolderNode(this.name, this.path, this.folderchildren, this.filechildren) {
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
  FileTree(String rootPath) : root = FolderNode("Root", rootPath, [], []);

  late List<FolderNode> arananfolder = [];
  late List<File> arananfile = [];

  Future<FolderNode> buildTree() async {
    await _buildTree(root);
    return root;
  }

  Future<void> agactaarama(String aranan) async {
    await _agactaarama(root, aranan);
  }

  Future<void> _agactaarama(FolderNode node, String aranan) async {
    debugPrint('Arama çalıştı: $aranan');

    if (aranan.isEmpty) {
      arananfolder = [];
      arananfile = [];
      debugPrint('Arama listesi temizlendi');
      notifyListeners();
      return; // **Boş aramayı hemen bitir**
    }

    if (node.name.toLowerCase().contains(aranan.toLowerCase())) {
      debugPrint('Eşleşen klasör: ${node.name}');
      arananfolder.add(node);
      notifyListeners();
    }

    // **Dosyaları kontrol et**
    for (File child in node.filechildren) {
      if (pathinfo
          .basename(child.path)
          .toLowerCase()
          .contains(aranan.toLowerCase())) {
        debugPrint('Eşleşen dosya: ${pathinfo.basename(child.path)}');
        arananfile.add(child);
        notifyListeners();
      }
    }

    // **Alt klasörleri kontrol et**
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
          FolderNode folder = FolderNode(name, entity.path, [], []);
          node.addfolderChild(folder);
          _buildTree(folder); // Recursive call for subfolders
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
