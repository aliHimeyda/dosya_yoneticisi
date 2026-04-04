import 'package:dosya_gezgini/app/router/app_router.dart';
import 'package:dosya_gezgini/features/files/presentation/widgets/dosya_folder.dart';
import 'package:dosya_gezgini/features/files/state/izinler.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

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
        future: context.watch<Izinler>().izin,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return CircularProgressIndicator();
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
                    context.watch<Izinler>().fileTree.ensongezilenfiles.length +
                    context
                        .watch<Izinler>()
                        .fileTree
                        .ensongezilenfolders
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
                  } else if (index == 1) {
                    return Center(
                      child: Container(
                        width: MediaQuery.of(context).size.width - 50,
                        height: 60,
                        padding: EdgeInsets.all(15),
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              width: 0.3,
                              color: Theme.of(context).iconTheme.color!,
                            ),
                          ),
                        ),
                        child: Text(
                          'En Son Gezilenler',
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                      ),
                    );
                  } else {
                    if (context
                        .watch<Izinler>()
                        .fileTree
                        .ensongezilenfolders
                        .isNotEmpty) {
                      if (index <=
                          context
                              .watch<Izinler>()
                              .fileTree
                              .ensongezilenfolders
                              .length) {
                        return Klasor(
                          key: ValueKey(index - 2),
                          name:
                              context
                                  .watch<Izinler>()
                                  .fileTree
                                  .ensongezilenfolders[index - 2]
                                  .name,
                          path:
                              context
                                  .watch<Izinler>()
                                  .fileTree
                                  .ensongezilenfolders[index - 1]
                                  .path,
                          klasor:
                              context
                                  .watch<Izinler>()
                                  .fileTree
                                  .ensongezilenfolders[index - 1],
                        );
                      }
                    }
                    if (context
                        .watch<Izinler>()
                        .fileTree
                        .ensongezilenfiles
                        .isNotEmpty) {
                      if (index >
                              context
                                  .watch<Izinler>()
                                  .fileTree
                                  .ensongezilenfolders
                                  .length &&
                          index -
                                  context
                                      .watch<Izinler>()
                                      .fileTree
                                      .ensongezilenfolders
                                      .length -
                                  1 <
                              context
                                  .watch<Izinler>()
                                  .fileTree
                                  .ensongezilenfiles
                                  .length) {
                        return Dosya(
                          key: ValueKey(index - 1),
                          file:
                              context
                                  .watch<Izinler>()
                                  .fileTree
                                  .ensongezilenfiles[index -
                                  context
                                      .watch<Izinler>()
                                      .fileTree
                                      .ensongezilenfolders
                                      .length -
                                  1],
                        );
                      }
                    }
                    if (context
                            .watch<Izinler>()
                            .fileTree
                            .ensongezilenfolders
                            .isEmpty &&
                        context
                            .watch<Izinler>()
                            .fileTree
                            .ensongezilenfiles
                            .isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Image.asset(
                              'assets/empty.png',
                              width: 50,
                              height: 50,
                              color: Theme.of(context).primaryColor,
                            ),
                            Text("Acilan Klasor Yok."),
                          ],
                        ),
                      );
                    }
                    return Column(
                      children: [
                        SizedBox(height: 10),
                        Center(
                          child: Text('----------  Liste Sonu  ----------'),
                        ),
                      ],
                    );
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
