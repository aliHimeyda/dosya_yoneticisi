import 'dart:io';

import 'package:dosya_gezgini/anasayfaicerigi.dart';
import 'package:dosya_gezgini/dosya_folder.dart';
import 'package:dosya_gezgini/folderleragaci.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

class Dosyalar extends StatelessWidget {
  const Dosyalar({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Animate(
        effects: [SlideEffect(begin: Offset(2, 0))],
        child: ListView.builder(
          itemCount:
              context.watch<Izinler>().fileTree.root.filechildren.length +
              context.watch<Izinler>().fileTree.root.folderchildren.length,
          itemBuilder: (context, index) {
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
                  context.watch<Izinler>().fileTree.root.folderchildren.length -
                      1) {
                return Klasor(
                  name:
                      context
                          .watch<Izinler>()
                          .fileTree
                          .root
                          .folderchildren[index]
                          .name,
                  path:
                      context
                          .watch<Izinler>()
                          .fileTree
                          .root
                          .folderchildren[index]
                          .path,
                  klasor:
                      context
                          .watch<Izinler>()
                          .fileTree
                          .root
                          .folderchildren[index],
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
              if (index -
                      context
                          .watch<Izinler>()
                          .fileTree
                          .root
                          .folderchildren
                          .length <=
                  context.watch<Izinler>().fileTree.root.filechildren.length -
                      1) {
                return Dosya(
                  file:
                      context
                          .watch<Izinler>()
                          .fileTree
                          .root
                          .filechildren[index -
                          context
                              .watch<Izinler>()
                              .fileTree
                              .root
                              .folderchildren
                              .length],
                );
              }
            }
          },
        ),
      ),
    );
  }
}
