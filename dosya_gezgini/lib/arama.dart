import 'package:dosya_gezgini/dosya_folder.dart';
import 'package:dosya_gezgini/folderleragaci.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:path/path.dart' as path;

class Arama extends StatefulWidget {
  const Arama({super.key});

  @override
  State<Arama> createState() => _AramaState();
}

class _AramaState extends State<Arama> {
  TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  List<String> filitrelenenkelimeler = []; // Filtrelenen kelimeler

  //  void oneribul(String query) {

  //     if (query.isEmpty) {
  //       filteredWords.value = [];
  //     } else {
  //       filteredWords.value =
  //           aramaonerileri
  //               .where((word) => word.toLowerCase().contains(query.toLowerCase()))
  //               .toList();
  //     }
  //   }
  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    context.watch<FileTree>().dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool anahtar = false;
    return ListView.builder(
      // filitrelenenkelimeler.length + 1
      itemCount:
          context.watch<FileTree>().arananfile.length +
          context.watch<FileTree>().arananfolder.length +
          2,
      itemBuilder: (context, index) {
        if (index == 0) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.only(top: 17, bottom: 17),
              child: Column(
                children: [
                  SizedBox(
                    width: MediaQuery.of(context).size.width - 30,
                    height: 35,
                    child: TextField(
                      controller: _controller,
                      focusNode: _focusNode,

                      onChanged: context.watch<FileTree>().agactaarama,
                      decoration: InputDecoration(
                        prefixIcon: IconButton(
                          icon: const Icon(Icons.search, size: 17),
                          onPressed: () async {
                            Provider.of<FileTree>(
                              context,
                              listen: false,
                            ).agactaarama(_controller.text);
                          },
                        ),
                        hintText: 'arama yap',
                        focusColor: Theme.of(context).primaryColor,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(7),
                        ),
                        filled: true,
                        fillColor: Theme.of(context).primaryColor,
                        contentPadding: const EdgeInsets.all(10),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        } else if (index == 1) {
          if (context.watch<FileTree>().arananfile.isEmpty &&
              context.watch<FileTree>().arananfolder.isEmpty) {
            return Center(
              child: Image.asset(
                'assets/empty.png',
                width: 100,
                height: 100,
                color: Theme.of(context).primaryColor,
              ),
            );
          }
        } else {
          for (var folder in context.watch<FileTree>().arananfolder) {
            return Klasor(name: folder.name, path: folder.path, klasor: folder);
          }
          for (var file in context.watch<FileTree>().arananfile) {
            return Dosya(file: file);
          }
        }
      },
    );
  }
}
