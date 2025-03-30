import 'dart:io';
import 'package:dosya_gezgini/altislemprovider.dart';
import 'package:dosya_gezgini/anasayfaicerigi.dart';
import 'package:dosya_gezgini/folderleragaci.dart';
import 'package:dosya_gezgini/main.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;
import 'package:provider/provider.dart';

class Dosyaislemleri extends ChangeNotifier {
  late List<FolderNode> folderlistesi = [];
  late List<File> filelistesi = [];
  late FolderNode? guncelparent;

  List<FolderNode>? getfolders() {
    if (folderlistesi.isNotEmpty) {
      return folderlistesi;
    } else {
      return null;
    }
  }

  List<File>? getfiles() {
    if (filelistesi.isNotEmpty) {
      return filelistesi;
    } else {
      return null;
    }
  }

  Future<void> sil(context) async {
    debugPrint('sil basladi');
    if (folderlistesi.isNotEmpty) {
      debugPrint('silinecek boyut: ${folderlistesi.length}');

      for (FolderNode folder in folderlistesi) {
        try {
          FileSystemEntity entity = Directory(folder.path);
          if (await entity.exists()) {
            await entity.delete(recursive: true);

            // Ağaçtan kaldır (güvenli şekilde)
            Provider.of<Izinler>(context, listen: false)
                .getCurrentFolder!
                .folderchildren
                .removeWhere((child) => child.path == folder.path);

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
            Provider.of<Izinler>(context, listen: false)
                .getCurrentFolder!
                .filechildren
                .removeWhere((child) => child.path == file.path);
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
    Provider.of<Altislemprovider>(context, listen: false).changeanahtar();
    getIt<Izinler>().fileTree.ekraniguncelle();
    notifyListeners();
  }

  void kopyala() {}
  Future<void> adlandir(String oldPath, String newName, context) async {
    String uzanti = '';
    try {
      FileSystemEntity entity;

      if (FileSystemEntity.typeSync(oldPath) ==
          FileSystemEntityType.directory) {
        entity = Directory(oldPath);
      } else {
        uzanti = path.extension(oldPath);
        entity = File(oldPath);
      }
      String newPath = path.join(path.dirname(oldPath), newName);

      await entity.rename(newPath);
      debugPrint("Yeniden adlandırıldı: $oldPath → $newPath");

      FolderNode? current =
          Provider.of<Izinler>(context, listen: false).getCurrentFolder;

      for (var folder in current!.folderchildren) {
        if (folder.path == oldPath) {
          folder.name = newName;
          folder.path = newPath;
          break;
        }
      }

      for (var file in current.filechildren) {
        if (file.path == oldPath) {
          int index = current.filechildren.indexOf(file);
          current.filechildren[index] = File(newPath);
          break;
        }
      }
    } catch (e) {
      debugPrint("Adlandırma hatası: $e");
    }

    if (filelistesi.isEmpty && folderlistesi.isEmpty) {
      Provider.of<Altislemprovider>(context, listen: false).changeanahtar();
    }
    notifyListeners();
  }

  void kaydet() {}
  void sakla() {}
  void yapistir() {}
  void kes() {}
}
