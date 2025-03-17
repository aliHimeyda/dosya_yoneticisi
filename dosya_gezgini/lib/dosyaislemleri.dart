import 'dart:io';
import 'package:dosya_gezgini/folderleragaci.dart';
import 'package:dosya_gezgini/main.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;

class Dosyaislemleri extends ChangeNotifier {
  late List<FolderNode> folderlistesi = [];
  late List<File> filelistesi = [];

  Future<void> sil() async {
    debugPrint('sil basladi');
    if (folderlistesi.isNotEmpty) {
      debugPrint('silinecek boyut: ${folderlistesi.length}');

      for (FolderNode folder in folderlistesi) {
        try {
          FileSystemEntity entity = Directory(folder.path);
          if (await entity.exists()) {
            await entity.delete(recursive: true);
            await getIt<FileTree>().agactadugumarama(folder.name);
            debugPrint("Silindi: ${folder.path}");
          } else {
            debugPrint("Dosya veya klasör bulunamadı: ${folder.path}");
          }
        } catch (e) {
          debugPrint("Silme hatası: $e");
        }
      }
    }
    if (filelistesi.isNotEmpty) {
      for (File file in filelistesi) {
        try {
          FileSystemEntity entity = File(file.path);
          if (await entity.exists()) {
            await entity.delete(recursive: true);
            await getIt<FileTree>().agactadugumarama(path.basename(file.path));
            debugPrint("Silindi: ${file.path}");
          } else {
            debugPrint("Dosya veya klasör bulunamadı: ${file.path}");
          }
        } catch (e) {
          debugPrint("Silme hatası: $e");
        }
      }
    }
    debugPrint('ekran guncellendi');
    folderlistesi.clear();
    filelistesi.clear();
    getIt<FileTree>().ekraniguncelle();
    notifyListeners();
  }

  void kopyala() {}
  Future<void> adlandir(String oldPath, String newName) async {
    try {
      FileSystemEntity entity =
          FileSystemEntity.typeSync(oldPath) == FileSystemEntityType.directory
              ? Directory(oldPath)
              : File(oldPath);

      String newPath = path.join(path.dirname(oldPath), newName);
      await entity.rename(newPath);
      debugPrint("Yeniden adlandırıldı: $oldPath → $newPath");
    } catch (e) {
      debugPrint("Adlandırma hatası: $e");
    }
    notifyListeners();
  }

  void kaydet() {}
  void sakla() {}
  void yapistir() {}
  void kes() {}
}
