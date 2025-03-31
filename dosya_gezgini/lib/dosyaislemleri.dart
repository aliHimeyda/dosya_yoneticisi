import 'dart:io';
import 'package:dosya_gezgini/altislemprovider.dart';
import 'package:dosya_gezgini/anasayfaicerigi.dart';
import 'package:dosya_gezgini/folderleragaci.dart';
import 'package:dosya_gezgini/main.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:path/path.dart' as path;
import 'package:provider/provider.dart';

class Dosyaislemleri extends ChangeNotifier {
  late List<FolderNode> folderlistesi = [];
  late List<File> filelistesi = [];
  late List<FolderNode> kopyalananfolder = [];
  late List<File> kopyalananfile = [];

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
    Fluttertoast.showToast(
      msg: "Silme Islemi Basarili :)",
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.TOP,
      timeInSecForIosWeb: 10,
      backgroundColor: Theme.of(context).secondaryHeaderColor,
      textColor: Theme.of(context).textTheme.labelLarge!.color,
      fontSize: 16.0,
    );
    folderlistesi.clear();
    filelistesi.clear();
    Provider.of<Altislemprovider>(context, listen: false).changeanahtar();
    getIt<Izinler>().fileTree.ekraniguncelle();
    notifyListeners();
  }

  void kopyala(context) {
    try {
      if (folderlistesi.isNotEmpty) {
        for (FolderNode folder in folderlistesi) {
          kopyalananfolder.add(folder);
        }
      }
      if (filelistesi.isNotEmpty) {
        for (File file in filelistesi) {
          kopyalananfile.add(file);
        }
      }
      debugPrint(
        'kopyalanan folder boyutu : ${kopyalananfolder.length}, kopyalanan file boyutu: ${kopyalananfile.length}',
      );
    } catch (e) {
      debugPrint("Kopyalama hatası: $e");
    }
    Fluttertoast.showToast(
      msg: "Kopyalandi",
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.TOP,
      timeInSecForIosWeb: 10,
      backgroundColor: Theme.of(context).secondaryHeaderColor,
      textColor: Theme.of(context).textTheme.labelLarge!.color,
      fontSize: 16.0,
    );
    folderlistesi.clear();
    filelistesi.clear();
    Provider.of<Altislemprovider>(context, listen: false).changeanahtar();
    notifyListeners();
  }

  Future<void> klasorekle(FolderNode folder, context, String klasoradi) async {
    try {
      Directory parentDir = Directory(folder.path);
      if (await parentDir.exists()) {
        Directory yeniDir = Directory(path.join(folder.path, klasoradi));
        if (!await yeniDir.exists()) {
          await yeniDir.create(recursive: true);
        }

        FolderNode yeniKlasor = FolderNode(
          klasoradi,
          yeniDir.path,
          [],
          [],
          folder,
        );

        folder.folderchildren.add(yeniKlasor);

        debugPrint("Eklendi: ${yeniDir.path}");
      } else {
        debugPrint("Klasör bulunamadı: ${folder.path}");
      }
    } catch (e) {
      debugPrint("Ekleme hatası: $e");
    }
    Fluttertoast.showToast(
      msg: "Yeni Klasor Olusturuldu",
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.TOP,
      timeInSecForIosWeb: 10,
      backgroundColor: Theme.of(context).secondaryHeaderColor,
      textColor: Theme.of(context).textTheme.labelLarge!.color,
      fontSize: 16.0,
    );
    notifyListeners();
  }

  Future<void> fileekle(File file) async {
    try {
      FileSystemEntity entity = File(file.path);
    } catch (e) {}
  }

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
    Fluttertoast.showToast(
      msg: "Adlandırma Islemi Basarili :)",
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.TOP,
      timeInSecForIosWeb: 10,
      backgroundColor: Theme.of(context).secondaryHeaderColor,
      textColor: Theme.of(context).textTheme.labelLarge!.color,
      fontSize: 16.0,
    );
    notifyListeners();
  }

  void kaydet(context) {
    try {
      if (folderlistesi.isNotEmpty) {
        for (FolderNode folder in folderlistesi) {
          Provider.of<Izinler>(
            context,
            listen: false,
          ).fileTree.kaydedilenfolder.add(folder);
        }
      }
      if (filelistesi.isNotEmpty) {
        for (File file in filelistesi) {
          Provider.of<Izinler>(
            context,
            listen: false,
          ).fileTree.kaydedilenfile.add(file);
        }
      }
      debugPrint(
        'kaydedilen folder boyutu : ${Provider.of<Izinler>(context, listen: false).fileTree.kaydedilenfolder.length}, kaydedilen file boyutu: ${Provider.of<Izinler>(context, listen: false).fileTree.kaydedilenfile.length}',
      );
    } catch (e) {
      debugPrint("kaydetme hatası: $e");
    }
    Fluttertoast.showToast(
      msg: "Kaydedildi",
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.TOP,
      timeInSecForIosWeb: 10,
      backgroundColor: Theme.of(context).secondaryHeaderColor,
      textColor: Theme.of(context).textTheme.labelLarge!.color,
      fontSize: 16.0,
    );
    folderlistesi.clear();
    filelistesi.clear();
    Provider.of<Altislemprovider>(context, listen: false).changeanahtar();
    notifyListeners();
  }

  void sakla(context) {
    try {
      if (folderlistesi.isNotEmpty) {
        for (FolderNode folder in folderlistesi) {
          Provider.of<Izinler>(
            context,
            listen: false,
          ).fileTree.gizlenenfolder.add(folder);
        }
      }
      if (filelistesi.isNotEmpty) {
        for (File file in filelistesi) {
          Provider.of<Izinler>(
            context,
            listen: false,
          ).fileTree.gizlenenfile.add(file);
        }
      }
      debugPrint(
        'Gizlenen folder boyutu : ${Provider.of<Izinler>(context, listen: false).fileTree.gizlenenfolder.length}, Gizlenen file boyutu: ${Provider.of<Izinler>(context, listen: false).fileTree.gizlenenfile.length}',
      );
    } catch (e) {
      debugPrint("Gizleme hatası: $e");
    }
    Fluttertoast.showToast(
      msg: "Saklandi :)",
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.TOP,
      timeInSecForIosWeb: 10,
      backgroundColor: Theme.of(context).secondaryHeaderColor,
      textColor: Theme.of(context).textTheme.labelLarge!.color,
      fontSize: 16.0,
    );
    folderlistesi.clear();
    filelistesi.clear();
    Provider.of<Altislemprovider>(context, listen: false).changeanahtar();
    notifyListeners();
  }

  void yapistir(context) {}
  void kes(context) {}
}
