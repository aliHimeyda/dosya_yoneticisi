import 'dart:io';
import 'package:path/path.dart' as pathinfo;
import 'package:dosya_gezgini/dosya_folder.dart';
import 'package:dosya_gezgini/folderleragaci.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Izinler extends ChangeNotifier {
  final String rootPath = "/storage/emulated/0"; // Android'deki temel dizin
  late FileTree fileTree = FileTree(rootPath);
  late bool _izin;
  Future<bool> get izin async {
    final pref = await SharedPreferences.getInstance();
    bool izinverilmismi = pref.getBool('izinanahtari') ?? false;
    if (izinverilmismi) {
      _izin = true;
      return _izin;
    } else {
      _izin = await Permission.manageExternalStorage.status.isGranted;
      pref.setBool('izinanahtari', _izin);
      return _izin;
    }
  }

  void setIzin(bool value) async {
    final pref = await SharedPreferences.getInstance();
    _izin = value;
    pref.setBool('izinanahtari', _izin);
    notifyListeners();
  }

  Future<void> requestAllStoragePermission() async {
    debugPrint('girildi');
    // final prefs = await SharedPreferences.getInstance();
    // bool? izinverilmismi = prefs.getBool('izinanahtari');

    var status = await Permission.manageExternalStorage.status;

    if (status.isGranted) {
      print("✅ Tüm dosyalara erişim izni zaten verilmiş.");
      setIzin(true);
      notifyListeners();

      await fileTree.buildTree();
      // await fileTree.printTree();
      return;
    }

    var newStatus = await Permission.manageExternalStorage.request();

    if (newStatus.isGranted) {
      print("✅ İzin başarıyla alındı!");
      setIzin(true);
      notifyListeners();
      // String rootPath = "/storage/emulated/0"; // Android'deki temel dizin
      // FileTree fileTree = FileTree(rootPath);

      await fileTree.buildTree();
      // await fileTree.printTree();
    } else if (newStatus.isDenied) {
      print("⛔ Kullanıcı izni reddetti!");
      setIzin(false);
      notifyListeners();
    } else {
      print("🚫 Kullanıcı kalıcı olarak reddetti, ayarlara yönlendiriliyor...");
      await openAppSettings();
      if (newStatus.isGranted) {
        setIzin(true);
        notifyListeners();
        // String rootPath = "/storage/emulated/0"; // Android'deki temel dizin
        // FileTree fileTree = FileTree(rootPath);

        await fileTree.buildTree();
        // await fileTree.printTree();
      } else {
        setIzin(false);
        notifyListeners();
      }
    }
  }
}

class Anasayfaicerigi extends StatelessWidget {
  const Anasayfaicerigi({super.key});

  void agacitanima(BuildContext context) async {
    final izinProvider = Provider.of<Izinler>(context, listen: false);
    izinProvider.requestAllStoragePermission();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: FutureBuilder<bool>(
        future:
            context.watch<Izinler>().izin, // Future fonksiyonunu çağırıyoruz
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return CircularProgressIndicator(); // Yüklenme durumu
          } else if (snapshot.hasError) {
            return Text('Bir hata oluştu');
          } else if (snapshot.hasData && snapshot.data == false) {
            return ElevatedButton(
              onPressed: () {
                agacitanima(context);
              },
              child: Text('Ana Sayfa'),
            );
          } else {
            return Animate(
              effects: [SlideEffect(begin: Offset(2, 0))],
              child: ListView.builder(
                itemCount:
                    context.watch<Izinler>().fileTree.root.filechildren.length +
                    context
                        .watch<Izinler>()
                        .fileTree
                        .root
                        .folderchildren
                        .length +
                    2,
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return Padding(
                      padding: const EdgeInsets.all(15),
                      child: Center(
                        child: Wrap(
                          alignment: WrapAlignment.center,
                          spacing: 3,
                          runSpacing: 3,
                          children: [
                            // katagoriiconu('assets/temizleyici.png'),
                            katagoriiconu('assets/file.png', 'file'),
                            katagoriiconu('assets/xls.png', 'excel'),
                            katagoriiconu('assets/image.png', 'resim'),
                            katagoriiconu('assets/mp4.png', 'video'),
                            katagoriiconu('assets/mp3.png', 'ses'),
                            katagoriiconu('assets/doc.png', 'word'),
                            katagoriiconu('assets/ppt.png', 'powerpoint'),
                            katagoriiconu('assets/zip.png', 'zip'),
                            katagoriiconu('assets/pdf.png', 'pdf'),
                            katagoriiconu('assets/txt.png', 'txt'),
                          ],
                        ),
                      ),
                    );
                  } else {
                    if (context
                        .watch<Izinler>()
                        .fileTree
                        .root
                        .folderchildren
                        .isNotEmpty) {
                      debugPrint(
                        context
                            .watch<Izinler>()
                            .fileTree
                            .root
                            .folderchildren
                            .length
                            .toString(),
                      );
                      if (index <=
                          context
                              .watch<Izinler>()
                              .fileTree
                              .root
                              .folderchildren
                              .length) {
                        return Klasor(
                          name:
                              context
                                  .watch<Izinler>()
                                  .fileTree
                                  .root
                                  .folderchildren[index - 1]
                                  .name,
                          path:
                              context
                                  .watch<Izinler>()
                                  .fileTree
                                  .root
                                  .folderchildren[index - 1]
                                  .path,
                          klasor:
                              context
                                  .watch<Izinler>()
                                  .fileTree
                                  .root
                                  .folderchildren[index - 1],
                        );
                      }
                    }  if (context
                        .watch<Izinler>()
                        .fileTree
                        .root
                        .filechildren
                        .isNotEmpty) {
                      debugPrint(
                        context
                            .watch<Izinler>()
                            .fileTree
                            .root
                            .filechildren
                            .length
                            .toString(),
                      );
                      if (index <=
                          context
                              .watch<Izinler>()
                              .fileTree
                              .root
                              .filechildren
                              .length) {
                        return Dosya(
                          file:
                              context
                                  .watch<Izinler>()
                                  .fileTree
                                  .root
                                  .filechildren[index - 1],
                        );
                      }
                    }
                  }
                },
              ),
            );
          }
        },
      ),
    );
  }

  GestureDetector katagoriiconu(String resimyolu, String aciklama) {
    return GestureDetector(
      onTap: () {
        debugPrint('tiklandi');
      },
      child: SizedBox(
        width: 80,
        height: 100,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Image.asset(resimyolu, width: 50, height: 50),
                Text(aciklama),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
