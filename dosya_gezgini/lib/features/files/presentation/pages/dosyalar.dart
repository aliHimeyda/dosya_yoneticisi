import 'package:dosya_gezgini/features/files/presentation/widgets/dosya_folder.dart';
import 'package:dosya_gezgini/features/files/state/izinler.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

class Dosyalar extends StatelessWidget {
  const Dosyalar({super.key});

  @override
  Widget build(BuildContext context) {
    final root = context.watch<Izinler>().fileTree.root;
    final folders = root.folderchildren;
    final files = root.filechildren;

    return Center(
      child: Animate(
        effects: [SlideEffect(begin: Offset(2, 0))],
        child: ListView.builder(
          itemCount: files.length + folders.length,
          itemBuilder: (context, index) {
            if (index < folders.length) {
              final folder = folders[index];
              return Klasor(
                name: folder.name,
                path: folder.path,
                klasor: folder,
              );
            }

            final fileIndex = index - folders.length;
            if (fileIndex < files.length) {
              return Dosya(file: files[fileIndex]);
            }

            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }
}
