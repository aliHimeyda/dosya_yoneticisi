import 'package:dosya_gezgini/core/localization/l10n_extensions.dart';
import 'package:dosya_gezgini/features/files/presentation/widgets/dosya_folder.dart';
import 'package:dosya_gezgini/features/files/state/altislem_provider.dart';
import 'package:dosya_gezgini/features/files/state/dosyaislemleri.dart';
import 'package:dosya_gezgini/features/files/state/izinler.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

class Gizlidosyalar extends StatelessWidget {
  const Gizlidosyalar({super.key});

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
                ).fileTree.gizlenenfile.length +
                Provider.of<Izinler>(
                  context,
                  listen: false,
                ).fileTree.gizlenenfolder.length +
                1,
            itemBuilder: (context, index) {
              debugPrint('index :${index.toString()}');
              if (Provider.of<Izinler>(
                    context,
                    listen: false,
                  ).fileTree.gizlenenfile.isEmpty &&
                  Provider.of<Izinler>(
                    context,
                    listen: false,
                  ).fileTree.gizlenenfolder.isEmpty) {
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
                ).fileTree.gizlenenfolder.isNotEmpty) {
                  if (index <=
                      Provider.of<Izinler>(
                            context,
                            listen: false,
                          ).fileTree.gizlenenfolder.length -
                          1) {
                    return Klasor(
                      name:
                          Provider.of<Izinler>(
                            context,
                            listen: false,
                          ).fileTree.gizlenenfolder[index].name,
                      path:
                          Provider.of<Izinler>(
                            context,
                            listen: false,
                          ).fileTree.gizlenenfolder[index].path,
                      klasor:
                          Provider.of<Izinler>(
                            context,
                            listen: false,
                          ).fileTree.gizlenenfolder[index],
                    );
                  }
                }
                if (Provider.of<Izinler>(
                  context,
                  listen: false,
                ).fileTree.gizlenenfile.isNotEmpty) {
                  debugPrint(
                    Provider.of<Izinler>(
                      context,
                      listen: false,
                    ).fileTree.gizlenenfile.length.toString(),
                  );
                  if (index -
                          Provider.of<Izinler>(
                            context,
                            listen: false,
                          ).fileTree.gizlenenfolder.length <=
                      Provider.of<Izinler>(
                            context,
                            listen: false,
                          ).fileTree.gizlenenfile.length -
                          1) {
                    return Dosya(
                      file:
                          Provider.of<Izinler>(
                            context,
                            listen: false,
                          ).fileTree.gizlenenfile[index -
                              Provider.of<Izinler>(
                                context,
                                listen: false,
                              ).fileTree.gizlenenfolder.length],
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
