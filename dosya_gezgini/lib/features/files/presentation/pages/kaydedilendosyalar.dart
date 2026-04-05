import 'package:dosya_gezgini/core/localization/l10n_extensions.dart';
import 'package:dosya_gezgini/features/files/presentation/widgets/dosya_folder.dart';
import 'package:dosya_gezgini/features/files/state/altislem_provider.dart';
import 'package:dosya_gezgini/features/files/state/dosyaislemleri.dart';
import 'package:dosya_gezgini/features/files/state/izinler.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

class Kaydedilendosyalar extends StatelessWidget {
  const Kaydedilendosyalar({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return PopScope(
      canPop: !context.watch<Altislemprovider>().anahtar,
      onPopInvoked: (didPop) {
        debugPrint('Geri tuşuna basıldı');

        final izinlerProvider = context.read<Izinler>();
        final altIslemProvider = context.read<Altislemprovider>();
        final dosyalisteleri = context.read<Dosyaislemleri>();

        if (altIslemProvider.anahtar) {
          debugPrint('Menü kapatılıyor');
          altIslemProvider.changeanahtar();
          dosyalisteleri.folderlistesi.clear();
          dosyalisteleri.filelistesi.clear();
          return;
        }

        if (izinlerProvider.previousFolders.isNotEmpty) {
          debugPrint('Önceki klasöre dönülüyor');
          izinlerProvider.goBack();
          return;
        }

        debugPrint('Çıkış yapılıyor');
      },
      child: Center(
        child: Animate(
          effects: [SlideEffect(begin: Offset(2, 0))],
          child: ListView.builder(
            itemCount:
                Provider.of<Izinler>(
                  context,
                  listen: false,
                ).fileTree.kaydedilenfile.length +
                Provider.of<Izinler>(
                  context,
                  listen: false,
                ).fileTree.kaydedilenfolder.length +
                1,
            itemBuilder: (context, index) {
              debugPrint('index :${index.toString()}');
              if (Provider.of<Izinler>(
                    context,
                    listen: false,
                  ).fileTree.kaydedilenfile.isEmpty &&
                  Provider.of<Izinler>(
                    context,
                    listen: false,
                  ).fileTree.kaydedilenfolder.isEmpty) {
                debugPrint('klasor bos');
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
                      Text(l10n.folderEmpty),
                    ],
                  ),
                );
              } else {
                if (Provider.of<Izinler>(
                  context,
                  listen: false,
                ).fileTree.kaydedilenfolder.isNotEmpty) {
                  if (index <=
                      Provider.of<Izinler>(
                            context,
                            listen: false,
                          ).fileTree.kaydedilenfolder.length -
                          1) {
                    return Klasor(
                      name:
                          Provider.of<Izinler>(
                            context,
                            listen: false,
                          ).fileTree.kaydedilenfolder[index].name,
                      path:
                          Provider.of<Izinler>(
                            context,
                            listen: false,
                          ).fileTree.kaydedilenfolder[index].path,
                      klasor:
                          Provider.of<Izinler>(
                            context,
                            listen: false,
                          ).fileTree.kaydedilenfolder[index],
                    );
                  }
                }
                if (Provider.of<Izinler>(
                  context,
                  listen: false,
                ).fileTree.kaydedilenfile.isNotEmpty) {
                  debugPrint(
                    Provider.of<Izinler>(
                      context,
                      listen: false,
                    ).fileTree.kaydedilenfile.length.toString(),
                  );
                  if (index -
                          Provider.of<Izinler>(
                            context,
                            listen: false,
                          ).fileTree.kaydedilenfolder.length <=
                      Provider.of<Izinler>(
                            context,
                            listen: false,
                          ).fileTree.kaydedilenfile.length -
                          1) {
                    return Dosya(
                      file:
                          Provider.of<Izinler>(
                            context,
                            listen: false,
                          ).fileTree.kaydedilenfile[index -
                              Provider.of<Izinler>(
                                context,
                                listen: false,
                              ).fileTree.kaydedilenfolder.length],
                    );
                  }
                }
              }
            },
          ),
        ),
      ),
    );
  }
}
