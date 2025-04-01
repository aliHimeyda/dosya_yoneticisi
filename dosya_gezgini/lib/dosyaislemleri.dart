import 'dart:io';
import 'package:dosya_gezgini/altislemprovider.dart';
import 'package:dosya_gezgini/anasayfaicerigi.dart';
import 'package:dosya_gezgini/folderleragaci.dart';
import 'package:dosya_gezgini/main.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:path/path.dart' as path;
import 'package:provider/provider.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class Dosyaislemleri extends ChangeNotifier {
  late List<FolderNode> folderlistesi = [];
  late List<File> filelistesi = [];
  late List<FolderNode> kopyalananfolder = [];
  late List<File> kopyalananfile = [];
  late List<FileSystemEntity> gereksizdosyalar = [];
  late int gereksizdosyalartoplamboyutu = 0;
  late bool loading = false;
  late bool aramaloading = false;
  late bool gecicidosyalaralinmasi = false;
  late bool onbellekdosyalarialinmasi = false;

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

  Future<void> temizlenecekleritoplamaislemi(context) async {
    int silinecekboyut = 0;
    loading = true;
    notifyListeners();
    debugPrint('başladı');

    Directory tempDir = await getTemporaryDirectory();
    Directory cacheDir = await getApplicationCacheDirectory();

    await Future.delayed(Duration(seconds: 5));
    gecicidosyalaralinmasi = true;
    notifyListeners();
    debugPrint('geçici dosyalar alındı');

    List<FileSystemEntity> tempFiles = tempDir.listSync(recursive: true);
    List<FileSystemEntity> cacheFiles = cacheDir.listSync(recursive: true);

    List<FileSystemEntity> allFiles = [...tempFiles, ...cacheFiles];

    DateTime now = DateTime.now();
    Duration ageLimit = Duration(days: 30); // 30 gün
    int sizeLimit = 100 * 1024 * 1024; // 100 MB

    for (FileSystemEntity file in allFiles) {
      if (file is File) {
        try {
          DateTime lastModified = await file.lastModified();
          int fileSize = await file.length();

          if (now.difference(lastModified) > ageLimit || fileSize > sizeLimit) {
            gereksizdosyalar.add(file);
            silinecekboyut += fileSize;
            debugPrint("listeye alındı: ${file.path}");
          }
        } catch (e) {
          debugPrint("Hata oluştu: $e");
        }
      }
    }

    debugPrint("Temizlik için liste hazır!");
    gereksizdosyalartoplamboyutu = silinecekboyut;
    await Future.delayed(Duration(seconds: 5));
    onbellekdosyalarialinmasi = true;
    notifyListeners();
    debugPrint('önbellek dosyaları alındı');

    await Future.delayed(Duration(seconds: 2));
    loading = false;
    notifyListeners();
    debugPrint('işlem bitti');

    aramaloading = true;
    notifyListeners();
  }

  Future<void> gereksizdosyalaritemizle() async {
    loading = true;
    notifyListeners();
    for (FileSystemEntity file in gereksizdosyalar) {
      try {
        await file.delete();
      } catch (e) {
        debugPrint("Hata oluştu: $e");
      }
    }
    await Future.delayed(Duration(seconds: 5));
    aramaloading = false;
    loading = false;
    gecicidosyalaralinmasi = false;
    onbellekdosyalarialinmasi = false;

    notifyListeners();
    await Future.delayed(Duration(seconds: 2));
  }

  Future<void> sil(context) async {
    if (folderlistesi.isNotEmpty) {
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
    kopyalananfolder.clear();
    kopyalananfile.clear();
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
      Directory parentDir = Directory(
        Provider.of<Izinler>(context, listen: false).getCurrentFolder!.path,
      );
      if (await parentDir.exists()) {
        Directory yeniDir = Directory(
          path.join(
            Provider.of<Izinler>(context, listen: false).getCurrentFolder!.path,
            klasoradi,
          ),
        );
        if (!await yeniDir.exists()) {
          await yeniDir.create(recursive: true);
        }

        FolderNode yeniKlasor = FolderNode(
          klasoradi,
          yeniDir.path,
          [],
          [],
          Provider.of<Izinler>(context, listen: false).getCurrentFolder!,
        );

        Provider.of<Izinler>(
          context,
          listen: false,
        ).getCurrentFolder!.folderchildren.add(yeniKlasor);
        debugPrint('sayfa guncellenecek');
        Provider.of<Izinler>(context, listen: false).notifyListeners();
        debugPrint('sayfa guncellendi');

        debugPrint("Eklendi: ${yeniDir.path}");
      } else {
        debugPrint(
          "Klasör bulunamadı: ${Provider.of<Izinler>(context, listen: false).getCurrentFolder!.path}",
        );
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
    Provider.of<Izinler>(context, listen: false).notifyListeners();
    notifyListeners();
  }

  Future<void> fileekle(File file, context) async {
    try {
      Directory parentDir = Directory(
        Provider.of<Izinler>(context, listen: false).getCurrentFolder!.path,
      );

      if (await parentDir.exists()) {
        String yeniDosyaYolu = path.join(
          parentDir.path,
          path.basename(file.path),
        );
        File yeniDosya = File(yeniDosyaYolu);

        if (!await yeniDosya.exists()) {
          await file.copy(yeniDosyaYolu);
        }

        Provider.of<Izinler>(
          context,
          listen: false,
        ).getCurrentFolder!.filechildren.add(yeniDosya);

        debugPrint("Dosya eklendi: ${yeniDosyaYolu}");
        Provider.of<Izinler>(context, listen: false).notifyListeners();
      } else {
        debugPrint(
          "Klasör bulunamadı: ${Provider.of<Izinler>(context, listen: false).getCurrentFolder!.path}",
        );
      }
    } catch (e) {
      debugPrint("Dosya ekleme hatası: $e");
    }

    Fluttertoast.showToast(
      msg: "Yeni Dosya Eklendi",
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.TOP,
      timeInSecForIosWeb: 10,
      backgroundColor: Theme.of(context).secondaryHeaderColor,
      textColor: Theme.of(context).textTheme.labelLarge!.color,
      fontSize: 16.0,
    );

    Provider.of<Izinler>(context, listen: false).notifyListeners();
    notifyListeners(); // Eğer bu metod içinde bir ChangeNotifier varsa
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

  Future<void> kaydet(context) async {
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

  Future<void> sakla(context) async {
    try {
      if (folderlistesi.isNotEmpty) {
        for (FolderNode folder in folderlistesi) {
          Provider.of<Izinler>(
            context,
            listen: false,
          ).fileTree.gizlenenfolder.add(folder);
          Provider.of<Izinler>(
            context,
            listen: false,
          ).getCurrentFolder!.folderchildren.remove(folder);
        }
      }
      if (filelistesi.isNotEmpty) {
        for (File file in filelistesi) {
          Provider.of<Izinler>(
            context,
            listen: false,
          ).fileTree.gizlenenfile.add(file);
          Provider.of<Izinler>(
            context,
            listen: false,
          ).getCurrentFolder!.filechildren.remove(file);
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

  void yapistir(context) {
    if (kopyalananfolder.isNotEmpty) {
      for (FolderNode folder in kopyalananfolder) {
        klasorekle(folder, context, folder.name);
      }
    }
    if (kopyalananfile.isNotEmpty) {
      for (File file in kopyalananfile) {
        fileekle(file, context);
      }
    }
    kopyalananfolder.clear();
    kopyalananfile.clear();
    notifyListeners();
    debugPrint('yapistirma islemi yapildi');
  }

  Future<void> kes(context) async {
    //kopyalama islemi .....................

    kopyalananfolder.clear();
    kopyalananfile.clear();
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

      //silme islemi .................
      if (folderlistesi.isNotEmpty) {
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
    } catch (e) {
      debugPrint("kesme hatası: $e");
    }

    folderlistesi.clear();
    filelistesi.clear();
    Provider.of<Altislemprovider>(context, listen: false).changeanahtar();
    Provider.of<Izinler>(context, listen: false).notifyListeners();
    notifyListeners();
  }
}
