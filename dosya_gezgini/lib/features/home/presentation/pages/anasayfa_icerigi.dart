import 'package:dosya_gezgini/app/router/app_router.dart';
import 'package:dosya_gezgini/core/localization/l10n_extensions.dart';
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
    final l10n = context.l10n;

    return Center(
      child: FutureBuilder<bool>(
        future: context.watch<Izinler>().izin,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return CircularProgressIndicator();
          } else if (snapshot.hasError) {
            return Text(l10n.errorOccurred);
          } else if (snapshot.hasData && snapshot.data == false) {
            return ElevatedButton(
              onPressed: () {
                agacitanima(context);
              },
              child: Text(l10n.tryAgain),
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
                              l10n.categoryFiles,
                              1,
                              context,
                            ),
                            katagoriiconu(
                              'assets/xls.png',
                              l10n.categoryExcel,
                              2,
                              context,
                            ),
                            katagoriiconu(
                              'assets/image.png',
                              l10n.categoryImages,
                              3,
                              context,
                            ),
                            katagoriiconu(
                              'assets/mp4.png',
                              l10n.categoryVideos,
                              4,
                              context,
                            ),
                            katagoriiconu(
                              'assets/mp3.png',
                              l10n.categoryAudio,
                              5,
                              context,
                            ),
                            katagoriiconu(
                              'assets/doc.png',
                              l10n.categoryWord,
                              6,
                              context,
                            ),
                            katagoriiconu(
                              'assets/ppt.png',
                              l10n.categoryPowerPoint,
                              7,
                              context,
                            ),
                            katagoriiconu(
                              'assets/zip.png',
                              l10n.categoryArchives,
                              8,
                              context,
                            ),
                            katagoriiconu(
                              'assets/pdf.png',
                              l10n.categoryPdf,
                              9,
                              context,
                            ),
                            katagoriiconu(
                              'assets/txt.png',
                              l10n.categoryText,
                              10,
                              context,
                            ),
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
                          l10n.recentlyVisited,
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
                            Text(l10n.noOpenedFolder),
                          ],
                        ),
                      );
                    }

                    return Column(
                      children: [
                        SizedBox(height: 10),
                        Center(
                          child: Text(l10n.listEnd),
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
      onTap: () async {
        final izinler = Provider.of<Izinler>(context, listen: false);
        if (index == 1) {
          await izinler.setCurrentFolder(izinler.fileTree.bilinmeyendosya);
          context.push(Paths.klasoricerigisayfasi);
        } else if (index == 2) {
          await izinler.setCurrentFolder(izinler.fileTree.exceldosya);
          context.push(Paths.klasoricerigisayfasi);
        } else if (index == 3) {
          await izinler.setCurrentFolder(izinler.fileTree.resimdosya);
          context.push(Paths.klasoricerigisayfasi);
        } else if (index == 4) {
          await izinler.setCurrentFolder(izinler.fileTree.videodosya);
          context.push(Paths.klasoricerigisayfasi);
        } else if (index == 5) {
          await izinler.setCurrentFolder(izinler.fileTree.sesdosya);
          context.push(Paths.klasoricerigisayfasi);
        } else if (index == 6) {
          await izinler.setCurrentFolder(izinler.fileTree.worddosya);
          context.push(Paths.klasoricerigisayfasi);
        } else if (index == 7) {
          await izinler.setCurrentFolder(izinler.fileTree.powerpointdosya);
          context.push(Paths.klasoricerigisayfasi);
        } else if (index == 8) {
          await izinler.setCurrentFolder(izinler.fileTree.zipdosya);
          context.push(Paths.klasoricerigisayfasi);
        } else if (index == 9) {
          await izinler.setCurrentFolder(izinler.fileTree.pdfdosya);
          context.push(Paths.klasoricerigisayfasi);
        } else if (index == 10) {
          await izinler.setCurrentFolder(izinler.fileTree.txtdosya);
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
