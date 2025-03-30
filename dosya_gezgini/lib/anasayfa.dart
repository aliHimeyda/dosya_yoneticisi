// ignore_for_file: avoid_unnecessary_containers
import 'dart:io';
import 'package:path/path.dart' as pathinfo;
import 'package:dosya_gezgini/altislemprovider.dart';
import 'package:dosya_gezgini/dosyaislemleri.dart';
import 'package:dosya_gezgini/folderleragaci.dart';
import 'package:dosya_gezgini/renkler.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class Anasayfa extends StatefulWidget {
  final StatefulNavigationShell navigationShell;
  const Anasayfa({super.key, required this.navigationShell});

  @override
  State<Anasayfa> createState() => _AnasayfaState();
}

class _AnasayfaState extends State<Anasayfa> {
  TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    late IconData icon = Icons.keyboard_arrow_up;
    // Mevcut sayfanın yolunu al (Yeni yöntem)
    // final String currentPath = GoRouterState.of(context).uri.toString();

    // Eğer Ozelurunler sayfasındaysak, BottomNavigationBar'ı gösterme
    // bool showBottomNavBar = true;
    return PopScope(
      canPop:
          !context
              .watch<Altislemprovider>()
              .anahtar, // Menü açıksa geri çıkışı engelle
      onPopInvoked: (didPop) {
        debugPrint('Geri tuşuna basıldı');
        final dosyalisteleri = context.read<Dosyaislemleri>();
        if (context.read<Altislemprovider>().anahtar) {
          debugPrint('Menü kapatılıyor');
          context.read<Altislemprovider>().changeanahtar();
          dosyalisteleri.folderlistesi.clear();
          dosyalisteleri.filelistesi.clear();
        }
      },
      child: Scaffold(
        // appBar: AppBar(
        //   backgroundColor: Colors.transparent,
        //   leading: Padding(
        //     padding: EdgeInsets.only(left: 20),
        //     child: SizedBox(
        //       width: 200,
        //       child: TextField(
        //         onChanged: (value) {
        //           // Arama işlemleri burada yazılacak
        //         },
        //         decoration: InputDecoration(
        //           suffixIcon: IconButton(
        //             icon: Image.asset(
        //               'lib/icons/aramaiconu.png',
        //               width: 20,
        //               color: Renkler.kahverengi,
        //             ),
        //             onPressed: () {},
        //           ),
        //           hintText: 'Arama yap',
        //           border:
        //               OutlineInputBorder(borderRadius: BorderRadius.circular(5)),
        //           filled: true,
        //           fillColor: Renkler.kuyubeyaz,
        //           contentPadding: const EdgeInsets.symmetric(horizontal: 10),
        //         ),
        //       ),
        //     ),
        //   ),
        //   actions: const [
        //     Padding(
        //       padding: EdgeInsets.only(right: 10),
        //       child: Text('BelliBellu',
        //           style: TextStyle(fontSize: 20, color: Renkler.kahverengi)),
        //     ),
        //   ],
        // ),
        bottomNavigationBar:
            context.watch<Altislemprovider>().anahtar
                ? SafeArea(
                  child: Positioned(
                    bottom: 0,
                    child: Animate(
                      effects: [
                        SlideEffect(
                          begin: Offset(0, 2),
                          delay: Duration(milliseconds: 200),
                        ),
                      ],
                      child: Container(
                        width: MediaQuery.of(context).size.width - 20,
                        height: 70,
                        padding: EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          border: Border.all(
                            width: 2,
                            color: Theme.of(context).primaryColor,
                          ),
                        ),
                        child: Center(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              silbutonu(context),
                              kopyalabutonu(),
                              kesbutonu(),
                              kaydetbutonu(),
                              saklabutonu(),
                              adlandirbutonu(context),
                              yapistirbutonu(),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                )
                : SizedBox(),
        appBar: PreferredSize(
          preferredSize: Size.fromHeight(kBottomNavigationBarHeight),
          child: Container(
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  width: 4,
                  color: Theme.of(context).primaryColor,
                ),
              ),
            ),
            child: NavigationBar(
              labelBehavior:
                  NavigationDestinationLabelBehavior
                      .alwaysHide, // Label'ı gizle ve boşluğu kaldır
              indicatorColor: Colors.transparent,
              height: 60,
              selectedIndex: widget.navigationShell.currentIndex,
              onDestinationSelected: widget.navigationShell.goBranch,
              destinations: [
                bottomicons(
                  context,
                  index: 0,
                  currentindex: widget.navigationShell.currentIndex,
                  icon: Icons.menu,
                ),
                bottomicons(
                  context,
                  index: 1,
                  currentindex: widget.navigationShell.currentIndex,
                  icon: Icons.history,
                ),
                bottomicons(
                  context,
                  index: 2,
                  currentindex: widget.navigationShell.currentIndex,
                  icon: Icons.folder,
                ),
                bottomicons(
                  context,
                  index: 3,
                  currentindex: widget.navigationShell.currentIndex,
                  icon: Icons.search,
                ),
              ],
            ),
          ),
        ),
        floatingActionButton: Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(100)),
          child: FloatingActionButton(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(50), // Köşeleri yuvarlat
            ),
            onPressed: () {
              debugPrint('tiklandi');
            },
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Center(
                child: Image.asset(
                  'assets/temizleyici.png',
                  width: 30,
                  height: 30,
                ),
              ),
            ),
          ),
        ),
        // : null, // Eğer BottomNavigationBar gösterilmeyecekse, null döndür
        body: Stack(
          children: [
            widget.navigationShell,
            Positioned(
              bottom: 0,
              right: 0,
              left: 0,
              child: Center(
                child: GestureDetector(
                  onTap: () {
                    context.read<Altislemprovider>().changeanahtar();
                  },
                  child: Container(
                    width: 40,
                    height: 20,
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(50),
                        topRight: Radius.circular(50),
                      ),
                    ),
                    child: Center(child: Icon(icon)),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  GestureDetector silbutonu(BuildContext context) {
    return GestureDetector(
      onTap: () {
        showModalBottomSheet(
          context: context,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(20),
            ), // Köşeleri yuvarlat
          ),
          builder:
              (context) => Container(
                padding: EdgeInsets.all(20),
                height: 130,
                width: MediaQuery.of(context).size.width - 20,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "Dikkat , secimler silinecek !",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 10),
                    ElevatedButton(
                      onPressed: () {
                        Provider.of<Dosyaislemleri>(
                          context,
                          listen: false,
                        ).sil(context);
                        Navigator.pop(context);
                      }, // Kapatma butonu
                      child: Text("Tamam"),
                    ),
                  ],
                ),
              ),
        );
      },
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [Icon(Icons.delete_outlined, size: 30), Text('sil')],
        ),
      ),
    );
  }

  GestureDetector kopyalabutonu() {
    return GestureDetector(
      onTap: () {},
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [Icon(Icons.copy_all_outlined, size: 30), Text('kopyala')],
        ),
      ),
    );
  }

  GestureDetector kesbutonu() {
    return GestureDetector(
      onTap: () {},
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [Icon(Icons.content_cut_outlined, size: 30), Text('kes')],
        ),
      ),
    );
  }

  GestureDetector kaydetbutonu() {
    return GestureDetector(
      onTap: () {},
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.favorite_border_outlined, size: 30),
            Text('kaydet'),
          ],
        ),
      ),
    );
  }

  GestureDetector saklabutonu() {
    return GestureDetector(
      onTap: () {},
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [Icon(Icons.lock_outlined, size: 30), Text('sakla')],
        ),
      ),
    );
  }

  GestureDetector yapistirbutonu() {
    return GestureDetector(
      onTap: () {},
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [Icon(Icons.content_paste_go, size: 30), Text('yapistir')],
        ),
      ),
    );
  }

  GestureDetector adlandirbutonu(BuildContext context) {
    return GestureDetector(
      onTap: () {
        List<FolderNode> folders;
        List<File> files;
        if (context.read<Dosyaislemleri>().getfolders() == null) {
          folders = [];
        } else {
          folders = context.read<Dosyaislemleri>().getfolders()!;
        }
        if (context.read<Dosyaislemleri>().getfiles() == null) {
          files = [];
        } else {
          files = context.read<Dosyaislemleri>().getfiles()!;
        }
        if (folders.isNotEmpty) {
          for (FolderNode folder in folders) {
            String yeniad;
            showModalBottomSheet(
              context: context,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(20),
                ), // Köşeleri yuvarlat
              ),
              builder:
                  (context) => Container(
                    padding: EdgeInsets.all(20),
                    height: 200,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Center(
                          child: Animate(
                            effects: [
                              FadeEffect(duration: Duration(milliseconds: 100)),
                            ],
                            child: Container(
                              width: MediaQuery.of(context).size.width - 20,
                              height: MediaQuery.of(context).size.height / 10,
                              decoration: BoxDecoration(
                                border: Border(
                                  bottom: BorderSide(
                                    width: 0.3,
                                    color: Theme.of(context).iconTheme.color!,
                                  ),
                                  top: BorderSide(
                                    width: 1,
                                    color: Theme.of(context).iconTheme.color!,
                                  ),
                                ),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(10),
                                child: Row(
                                  children: [
                                    Image.asset(
                                      'assets/folder.png',
                                      width: 40,
                                      height: 40,
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: TextField(
                                        controller: _controller,
                                        decoration: InputDecoration(
                                          hintText: folder.name,
                                          hintStyle:
                                              Theme.of(
                                                context,
                                              ).textTheme.bodyLarge,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            ElevatedButton(
                              onPressed: () {
                                yeniad = _controller.text;
                                Provider.of<Dosyaislemleri>(
                                  context,
                                  listen: false,
                                ).adlandir(folder.path, yeniad, context);
                                _controller.text = '';
                                folders.remove(folder);
                                Navigator.pop(context);
                              }, // Kapatma butonu
                              child: Text("Tamam"),
                            ),
                            ElevatedButton(
                              onPressed: () {
                                // Provider.of<Dosyaislemleri>(
                                //   context,
                                //   listen: false,
                                // ).sil();
                                Navigator.pop(context);
                              }, // Kapatma butonu
                              child: Text("Iptal"),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
            );
          }
        }
        if (files.isNotEmpty) {
          for (File file in files) {
            String sadeceIsim = pathinfo.basenameWithoutExtension(file.path);
            String dosyauzantisi = pathinfo.extension(file.path);
            String yeniad;
            showModalBottomSheet(
              context: context,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(20),
                ), // Köşeleri yuvarlat
              ),
              builder:
                  (context) => Container(
                    padding: EdgeInsets.all(20),
                    height: 200,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Center(
                          child: Animate(
                            effects: [
                              FadeEffect(duration: Duration(milliseconds: 100)),
                            ],
                            child: Container(
                              width: MediaQuery.of(context).size.width - 20,
                              height: MediaQuery.of(context).size.height / 10,
                              decoration: BoxDecoration(
                                border: Border(
                                  bottom: BorderSide(
                                    width: 0.3,
                                    color: Theme.of(context).iconTheme.color!,
                                  ),
                                  top: BorderSide(
                                    width: 1,
                                    color: Theme.of(context).iconTheme.color!,
                                  ),
                                ),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(10),
                                child: Row(
                                  children: [
                                    dosyauzantisi == '.pdf'
                                        ? Image.asset(
                                          'assets/pdf.png',
                                          width: 40,
                                          height: 40,
                                        )
                                        : dosyauzantisi == '.png' ||
                                            dosyauzantisi == '.jpg'
                                        ? Image.asset(
                                          'assets/image.png',
                                          width: 40,
                                          height: 40,
                                        )
                                        : dosyauzantisi == '.doc' ||
                                            dosyauzantisi == '.docx'
                                        ? Image.asset(
                                          'assets/doc.png',
                                          width: 40,
                                          height: 40,
                                        )
                                        : dosyauzantisi == '.xls' ||
                                            dosyauzantisi == '.xlsx'
                                        ? Image.asset(
                                          'assets/xls.png',
                                          width: 40,
                                          height: 40,
                                        )
                                        : dosyauzantisi == '.ppt' ||
                                            dosyauzantisi == '.pptx'
                                        ? Image.asset(
                                          'assets/ppt.png',
                                          width: 40,
                                          height: 40,
                                        )
                                        : dosyauzantisi == '.txt'
                                        ? Image.asset(
                                          'assets/txt.png',
                                          width: 40,
                                          height: 40,
                                        )
                                        : dosyauzantisi == '.mp3'
                                        ? Image.asset(
                                          'assets/mp3.png',
                                          width: 40,
                                          height: 40,
                                        )
                                        : dosyauzantisi == '.mp4'
                                        ? Image.asset(
                                          'assets/mp4.png',
                                          width: 40,
                                          height: 40,
                                        )
                                        : dosyauzantisi == '.zip'
                                        ? Image.asset(
                                          'assets/zip.png',
                                          width: 40,
                                          height: 40,
                                        )
                                        : Image.asset(
                                          'assets/file.png',
                                          width: 40,
                                          height: 40,
                                        ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: TextField(
                                        controller: _controller,
                                        decoration: InputDecoration(
                                          hintText: sadeceIsim,
                                          hintStyle:
                                              Theme.of(
                                                context,
                                              ).textTheme.bodyLarge,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            ElevatedButton(
                              onPressed: () {
                                yeniad =
                                    _controller.text.trim() + dosyauzantisi;
                                Provider.of<Dosyaislemleri>(
                                  context,
                                  listen: false,
                                ).adlandir(file.path, yeniad, context);
                                _controller.text = '';
                                files.remove(file);
                                Navigator.pop(context);
                              }, // Kapatma butonu
                              child: Text("Tamam"),
                            ),
                            ElevatedButton(
                              onPressed: () {
                                // Provider.of<Dosyaislemleri>(
                                //   context,
                                //   listen: false,
                                // ).sil();
                                Navigator.pop(context);
                              }, // Kapatma butonu
                              child: Text("Iptal"),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
            );
          }
        }
      },
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.drive_file_rename_outline, size: 30),
            Text('adlandir'),
          ],
        ),
      ),
    );
  }

  Widget bottomicons(
    BuildContext context, {
    required int index,
    required int currentindex,
    required IconData icon,
  }) {
    return NavigationDestination(
      icon: Icon(
        icon,
        color:
            currentindex == index
                ? Theme.of(context).primaryColor
                : Theme.of(context).iconTheme.color,
      ),
      label: '',
    );
  }
}
