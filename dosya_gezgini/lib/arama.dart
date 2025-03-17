import 'package:dosya_gezgini/anasayfaicerigi.dart';
import 'package:dosya_gezgini/folderleragaci.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

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
    return StatefulBuilder(
      builder: (context, setState) {
        return Stack(
          alignment: Alignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 40),
              child: StatefulBuilder(
                builder: (context, setState) {
                  if (context.watch<Izinler>().fileTree.isSearching) {
                    return Center(child: CircularProgressIndicator());
                  }

                  if (context.watch<Izinler>().fileTree.arananfolder.isEmpty &&
                      context.watch<Izinler>().fileTree.arananfile.isEmpty) {
                    return Center(
                      child: Image.asset(
                        'assets/empty.png',
                        width: 100,
                        height: 100,
                        color: Theme.of(context).primaryColor,
                      ),
                    );
                  }

                  return ListView.builder(
                    itemCount:
                        context.watch<Izinler>().fileTree.arananfolder.length +
                        context.watch<Izinler>().fileTree.arananfile.length,
                    itemBuilder: (context, index) {
                      if (index <
                          context
                              .watch<Izinler>()
                              .fileTree
                              .arananfolder
                              .length) {
                        return context
                            .watch<Izinler>()
                            .fileTree
                            .arananfolder[index];
                      } else {
                        int fileIndex =
                            index -
                            context
                                .watch<Izinler>()
                                .fileTree
                                .arananfolder
                                .length;
                        return context
                            .watch<Izinler>()
                            .fileTree
                            .arananfile[fileIndex];
                      }
                    },
                  );
                },
              ),
            ),
            Positioned(
              top: 5,
              child: SizedBox(
                width: MediaQuery.of(context).size.width - 30,
                height: 35,
                child: TextField(
                  controller: _controller,
                  focusNode: _focusNode,
                  onChanged: (text) {
                    setState(() {
                      context.read<Izinler>().fileTree.agactaarama(text);
                    });
                  },
                  decoration: InputDecoration(
                    prefixIcon: IconButton(
                      icon: const Icon(Icons.search, size: 17),
                      onPressed: () {
                        setState(() {
                          context.read<Izinler>().fileTree.agactaarama(
                            _controller.text,
                          );
                        });
                      },
                    ),
                    hintText: 'Arama yap',
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
            ),
          ],
        );
      },
    );
  }
}
