import 'dart:io';
import 'package:dosya_gezgini/altislemprovider.dart';
import 'package:dosya_gezgini/anasayfaicerigi.dart';
import 'package:dosya_gezgini/dosyaislemleri.dart';
import 'package:path/path.dart' as pathinfo;
import 'package:dosya_gezgini/dosya_folder.dart';
import 'package:dosya_gezgini/folderleragaci.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Klasoricerigisayfasi extends StatelessWidget {
  const Klasoricerigisayfasi({super.key});

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
                Provider.of<Izinler>(
                  context,
                  listen: false,
                ).getCurrentFolder!.filechildren.length +
                Provider.of<Izinler>(
                  context,
                  listen: false,
                ).getCurrentFolder!.folderchildren.length +
                1,
            itemBuilder: (context, index) {
              debugPrint("index :${index.toString()}");
              if (Provider.of<Izinler>(
                    context,
                    listen: false,
                  ).getCurrentFolder!.filechildren.isEmpty &&
                  Provider.of<Izinler>(
                    context,
                    listen: false,
                  ).getCurrentFolder!.folderchildren.isEmpty) {
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
                if (Provider.of<Izinler>(
                  context,
                  listen: false,
                ).getCurrentFolder!.folderchildren.isNotEmpty) {
                  if (index <=
                      Provider.of<Izinler>(
                            context,
                            listen: false,
                          ).getCurrentFolder!.folderchildren.length -
                          1) {
                    return Klasor(
                      name:
                          Provider.of<Izinler>(
                            context,
                            listen: false,
                          ).getCurrentFolder!.folderchildren[index].name,
                      path:
                          Provider.of<Izinler>(
                            context,
                            listen: false,
                          ).getCurrentFolder!.folderchildren[index].path,
                      klasor:
                          Provider.of<Izinler>(
                            context,
                            listen: false,
                          ).getCurrentFolder!.folderchildren[index],
                    );
                  }
                }
                if (Provider.of<Izinler>(
                  context,
                  listen: false,
                ).getCurrentFolder!.filechildren.isNotEmpty) {
                  debugPrint(
                    Provider.of<Izinler>(
                      context,
                      listen: false,
                    ).getCurrentFolder!.filechildren.length.toString(),
                  );
                  if (index -
                          Provider.of<Izinler>(
                            context,
                            listen: false,
                          ).getCurrentFolder!.folderchildren.length <=
                      Provider.of<Izinler>(
                            context,
                            listen: false,
                          ).getCurrentFolder!.filechildren.length -
                          1) {
                    return Dosya(
                      file:
                          Provider.of<Izinler>(
                            context,
                            listen: false,
                          ).getCurrentFolder!.filechildren[index -
                              Provider.of<Izinler>(
                                context,
                                listen: false,
                              ).getCurrentFolder!.folderchildren.length],
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
