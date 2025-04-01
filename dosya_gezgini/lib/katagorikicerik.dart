import 'package:dosya_gezgini/altislemprovider.dart';
import 'package:dosya_gezgini/anasayfaicerigi.dart';
import 'package:dosya_gezgini/dosyaislemleri.dart';
import 'package:dosya_gezgini/dosya_folder.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

class Katagorikicerik extends StatelessWidget {
  const Katagorikicerik({super.key});

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop:
          !context
              .watch<Altislemprovider>()
              .anahtar, // Menü açıksa geri çıkışı engelle
      onPopInvoked: (didPop) {
        debugPrint('Geri tuşuna basıldı');

        final izinlerProvider = context.read<Izinler>();
        final altIslemProvider = context.read<Altislemprovider>();
        final dosyalisteleri = context.read<Dosyaislemleri>();

        // Eğer menü açıksa önce onu kapat
        if (altIslemProvider.anahtar) {
          debugPrint('Menü kapatılıyor');
          altIslemProvider.changeanahtar();
          dosyalisteleri.folderlistesi.clear();
          dosyalisteleri.filelistesi.clear();
          return; // İşlemi burada bitir
        }

        // Eğer önceki klasör varsa geri dön
        if (izinlerProvider.previousFolders.isNotEmpty) {
          debugPrint('Önceki klasöre dönülüyor');
          izinlerProvider.goBack();
          return; // İşlemi burada bitir, çıkış yapılmaz
        }

        // Eğer önceki klasör yoksa normal pop işlemi gerçekleşsin
        debugPrint('Çıkış yapılıyor');
      },
      child: Center(
        child: Animate(
          effects: [SlideEffect(begin: Offset(2, 0))],
          child: ListView.builder(
            itemCount:
                context.watch<Izinler>().getCurrentFolder!.filechildren.length +
                context
                    .watch<Izinler>()
                    .getCurrentFolder!
                    .folderchildren
                    .length +
                1,
            itemBuilder: (context, index) {
              debugPrint("index :${index.toString()}");
              if (context
                      .watch<Izinler>()
                      .getCurrentFolder!
                      .filechildren
                      .isEmpty &&
                  context
                      .watch<Izinler>()
                      .getCurrentFolder!
                      .folderchildren
                      .isEmpty) {
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
                      Text("Bu klasörde hiç dosya veya dizin yok."),
                    ],
                  ),
                );
              } else {
                if (context
                    .watch<Izinler>()
                    .getCurrentFolder!
                    .folderchildren
                    .isNotEmpty) {
                  if (index <=
                      context
                              .watch<Izinler>()
                              .getCurrentFolder!
                              .folderchildren
                              .length -
                          1) {
                    return Klasor(
                      name:
                          context
                              .watch<Izinler>()
                              .getCurrentFolder!
                              .folderchildren[index]
                              .name,
                      path:
                          context
                              .watch<Izinler>()
                              .getCurrentFolder!
                              .folderchildren[index]
                              .path,
                      klasor:
                          context
                              .watch<Izinler>()
                              .getCurrentFolder!
                              .folderchildren[index],
                    );
                  }
                }
                if (context
                    .watch<Izinler>()
                    .getCurrentFolder!
                    .filechildren
                    .isNotEmpty) {
                  debugPrint(
                    context
                        .watch<Izinler>()
                        .getCurrentFolder!
                        .filechildren
                        .length
                        .toString(),
                  );
                  if (index -
                          context
                              .watch<Izinler>()
                              .getCurrentFolder!
                              .folderchildren
                              .length <=
                      context
                              .watch<Izinler>()
                              .getCurrentFolder!
                              .filechildren
                              .length -
                          1) {
                    return Dosya(
                      file:
                          context
                              .watch<Izinler>()
                              .getCurrentFolder!
                              .filechildren[index -
                              context
                                  .watch<Izinler>()
                                  .getCurrentFolder!
                                  .folderchildren
                                  .length],
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
