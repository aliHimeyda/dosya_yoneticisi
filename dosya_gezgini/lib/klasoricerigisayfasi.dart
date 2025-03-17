import 'dart:io';
import 'package:dosya_gezgini/altislemprovider.dart';
import 'package:dosya_gezgini/anasayfaicerigi.dart';
import 'package:path/path.dart' as pathinfo;
import 'package:dosya_gezgini/dosya_folder.dart';
import 'package:dosya_gezgini/folderleragaci.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Klasoricerigisayfasi extends StatelessWidget {
  final FolderNode klasor;
  const Klasoricerigisayfasi({super.key, required this.klasor});

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop:
          !context
              .watch<Altislemprovider>()
              .anahtar, // Menü açıksa geri çıkışı engelle
      onPopInvoked: (didPop) {
        debugPrint('Geri tuşuna basıldı');
        if (context.read<Altislemprovider>().anahtar) {
          debugPrint('Menü kapatılıyor');
          context.read<Altislemprovider>().changeanahtar();
        }
      },
      child: Center(
        child: Animate(
          effects: [SlideEffect(begin: Offset(2, 0))],
          child: ListView.builder(
            itemCount:
                klasor.filechildren.length + klasor.folderchildren.length + 1,
            itemBuilder: (context, index) {
              debugPrint("index :${index.toString()}");
              if (klasor.filechildren.isEmpty &&
                  klasor.folderchildren.isEmpty) {
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
                if (klasor.folderchildren.isNotEmpty) {
                  if (index <= klasor.folderchildren.length - 1) {
                    return Klasor(
                      name: klasor.folderchildren[index].name,
                      path: klasor.folderchildren[index].path,
                      klasor: klasor.folderchildren[index],
                    );
                  }
                }
                if (klasor.filechildren.isNotEmpty) {
                  debugPrint(klasor.filechildren.length.toString());
                  if (index - klasor.folderchildren.length <=
                      klasor.filechildren.length - 1) {
                    return Dosya(
                      file:
                          klasor.filechildren[index -
                              klasor.folderchildren.length],
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
