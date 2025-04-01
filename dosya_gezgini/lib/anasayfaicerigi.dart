import 'package:dosya_gezgini/dosya_folder.dart';
import 'package:dosya_gezgini/folderleragaci.dart';
import 'package:dosya_gezgini/router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Izinler extends ChangeNotifier {
  final String rootPath = "/storage/emulated/0"; // Android'deki temel dizin
  late FileTree fileTree = FileTree(rootPath);
  late bool _izin;
  List<String>? _currentFolderPath;

  List<String>? get getcurrentFolderPath {
    List<String> konumlistesi =
        _currentFolder == null
            ? ['kok dizin']
            : _currentFolder!.path.split('/').sublist(4);
    _currentFolderPath = konumlistesi;
    return _currentFolderPath;
  }

  FolderNode? _currentFolder;
  List<FolderNode> previousFolders = [];

  FolderNode? get getCurrentFolder => _currentFolder;

  void klasorekle(FolderNode folder) {
    _currentFolder!.folderchildren.add(folder);
    notifyListeners();
  }

  void setCurrentFolder(FolderNode folder) {
    if (_currentFolder != null) {
      if (!previousFolders.contains(folder)) {
        previousFolders.add(_currentFolder!);
      }
    }
    _currentFolder = folder;
    notifyListeners();
  }

  void goBack() {
    if (previousFolders.isNotEmpty) {
      _currentFolder = previousFolders.removeLast();
      notifyListeners();
    }
  }

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
      print(" Tüm dosyalara erişim izni zaten verilmiş.");
      setIzin(true);
      notifyListeners();

      await fileTree.buildTree();
      // await fileTree.printTree();
      return;
    }

    var newStatus = await Permission.manageExternalStorage.request();

    if (newStatus.isGranted) {
      print(" İzin başarıyla alındı!");
      setIzin(true);
      notifyListeners();
      // String rootPath = "/storage/emulated/0"; // Android'deki temel dizin
      // FileTree fileTree = FileTree(rootPath);

      await fileTree.buildTree();
      // await fileTree.printTree();
    } else if (newStatus.isDenied) {
      print(" Kullanıcı izni reddetti!");
      setIzin(false);
      notifyListeners();
    } else {
      print(" Kullanıcı kalıcı olarak reddetti, ayarlara yönlendiriliyor...");
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
                            katagoriiconu(
                              'assets/file.png',
                              'file',
                              1,
                              context,
                            ),
                            katagoriiconu(
                              'assets/xls.png',
                              'excel',
                              2,
                              context,
                            ),
                            katagoriiconu(
                              'assets/image.png',
                              'resim',
                              3,
                              context,
                            ),
                            katagoriiconu(
                              'assets/mp4.png',
                              'video',
                              4,
                              context,
                            ),
                            katagoriiconu('assets/mp3.png', 'ses', 5, context),
                            katagoriiconu('assets/doc.png', 'word', 6, context),
                            katagoriiconu(
                              'assets/ppt.png',
                              'powerpoint',
                              7,
                              context,
                            ),
                            katagoriiconu('assets/zip.png', 'zip', 8, context),
                            katagoriiconu('assets/pdf.png', 'pdf', 9, context),
                            katagoriiconu('assets/txt.png', 'txt', 10, context),
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
                          key: ValueKey(index - 1),
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
                    }
                    if (context
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
                          key: ValueKey(index - 1),
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

  GestureDetector katagoriiconu(
    String resimyolu,
    String aciklama,
    int index,
    BuildContext context,
  ) {
    return GestureDetector(
      onTap: () {
        if (index == 1) {
          Provider.of<Izinler>(context, listen: false).setCurrentFolder(
            Provider.of<Izinler>(
              context,
              listen: false,
            ).fileTree.bilinmeyendosya,
          );
          context.push(Paths.klasoricerigisayfasi);
        } else if (index == 2) {
          debugPrint(
            'aciliyor.... ${Provider.of<Izinler>(context, listen: false).fileTree.exceldosya.filechildren.length}',
          );
          Provider.of<Izinler>(context, listen: false).setCurrentFolder(
            Provider.of<Izinler>(context, listen: false).fileTree.exceldosya,
          );
          context.push(Paths.klasoricerigisayfasi);
        } else if (index == 3) {
          debugPrint('aciliyor....');
          Provider.of<Izinler>(context, listen: false).setCurrentFolder(
            Provider.of<Izinler>(context, listen: false).fileTree.resimdosya,
          );
          context.push(Paths.klasoricerigisayfasi);
        } else if (index == 4) {
          debugPrint('aciliyor....');
          Provider.of<Izinler>(context, listen: false).setCurrentFolder(
            Provider.of<Izinler>(context, listen: false).fileTree.videodosya,
          );
          context.push(Paths.klasoricerigisayfasi);
        } else if (index == 5) {
          debugPrint('aciliyor....');
          Provider.of<Izinler>(context, listen: false).setCurrentFolder(
            Provider.of<Izinler>(context, listen: false).fileTree.sesdosya,
          );
          context.push(Paths.klasoricerigisayfasi);
        } else if (index == 6) {
          debugPrint('aciliyor....');
          Provider.of<Izinler>(context, listen: false).setCurrentFolder(
            Provider.of<Izinler>(context, listen: false).fileTree.worddosya,
          );
          context.push(Paths.klasoricerigisayfasi);
        } else if (index == 7) {
          debugPrint('aciliyor....');
          Provider.of<Izinler>(context, listen: false).setCurrentFolder(
            Provider.of<Izinler>(
              context,
              listen: false,
            ).fileTree.powerpointdosya,
          );
          context.push(Paths.klasoricerigisayfasi);
        } else if (index == 8) {
          debugPrint('aciliyor....');
          Provider.of<Izinler>(context, listen: false).setCurrentFolder(
            Provider.of<Izinler>(context, listen: false).fileTree.zipdosya,
          );
          context.push(Paths.klasoricerigisayfasi);
        } else if (index == 9) {
          debugPrint('aciliyor....');
          Provider.of<Izinler>(context, listen: false).setCurrentFolder(
            Provider.of<Izinler>(context, listen: false).fileTree.pdfdosya,
          );
          context.push(Paths.klasoricerigisayfasi);
        } else if (index == 10) {
          Provider.of<Izinler>(context, listen: false).setCurrentFolder(
            Provider.of<Izinler>(context, listen: false).fileTree.txtdosya,
          );
          context.push(Paths.klasoricerigisayfasi);
        }
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
