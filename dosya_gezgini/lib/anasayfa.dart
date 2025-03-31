// ignore_for_file: avoid_unnecessary_containers
import 'dart:io';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:dosya_gezgini/anasayfaicerigi.dart';
import 'package:dosya_gezgini/router.dart';
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
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    late IconData icon = Icons.keyboard_arrow_up;

    if (widget.navigationShell.currentIndex == 2) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: Duration(milliseconds: 150),
          curve: Curves.easeOut,
        );
      });
    }
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
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                )
                : SizedBox(),
        appBar: PreferredSize(
          preferredSize: Size.fromHeight(kBottomNavigationBarHeight * 2.1),
          child:
              widget.navigationShell.currentIndex == 2
                  ? Container(
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          width: 0.5,
                          color: Theme.of(context).iconTheme.color!,
                        ),
                      ),
                    ),
                    child: Column(
                      children: [
                        Container(
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
                            onDestinationSelected:
                                widget.navigationShell.goBranch,
                            destinations: [
                              bottomicons(
                                context,
                                index: 0,
                                currentindex:
                                    widget.navigationShell.currentIndex,
                                icon: Icons.menu,
                              ),
                              bottomicons(
                                context,
                                index: 1,
                                currentindex:
                                    widget.navigationShell.currentIndex,
                                icon: Icons.history,
                              ),
                              bottomicons(
                                context,
                                index: 2,
                                currentindex:
                                    widget.navigationShell.currentIndex,
                                icon: Icons.folder,
                              ),
                              bottomicons(
                                context,
                                index: 3,
                                currentindex:
                                    widget.navigationShell.currentIndex,
                                icon: Icons.search,
                              ),
                            ],
                          ),
                        ),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            Container(
                              width:
                                  (MediaQuery.of(context).size.width / 3) * 2,
                              height: 35,
                              alignment: Alignment.centerLeft,
                              padding: EdgeInsets.only(left: 10),
                              child: SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                controller: _scrollController,
                                child: Wrap(
                                  alignment: WrapAlignment.start,
                                  children: [
                                    for (String path
                                        in Provider.of<Izinler>(
                                          context,
                                          listen: false,
                                        ).getcurrentFolderPath!)
                                      Row(
                                        children: [
                                          Text(path),
                                          Icon(Icons.chevron_right),
                                        ],
                                      ),
                                  ],
                                ),
                              ),
                            ),
                            Theme(
                              data: Theme.of(context).copyWith(
                                popupMenuTheme: PopupMenuThemeData(
                                  color:
                                      Theme.of(
                                        context,
                                      ).secondaryHeaderColor, // Menü arka planı
                                ),
                              ),
                              child: PopupMenuButton<String>(
                                icon: Icon(Icons.more_vert),
                                itemBuilder:
                                    (context) => [
                                      PopupMenuItem(
                                        value: 'klasorolustur',
                                        padding: EdgeInsets.only(
                                          left: 20,
                                          right: 20,
                                        ),
                                        child: Text(
                                          'Klasor Olustur',
                                          style: TextStyle(
                                            fontSize:
                                                Theme.of(context)
                                                    .textTheme
                                                    .bodyMedium!
                                                    .fontSize,
                                          ),
                                        ),
                                      ),
                                      PopupMenuItem(
                                        padding: EdgeInsets.only(
                                          left: 20,
                                          right: 20,
                                        ),
                                        value: 'gizlidosyalar',
                                        child: Text(
                                          'Gizli Dosyalar',
                                          style: TextStyle(
                                            fontSize:
                                                Theme.of(context)
                                                    .textTheme
                                                    .bodyMedium!
                                                    .fontSize,
                                          ),
                                        ),
                                      ),
                                      PopupMenuItem(
                                        padding: EdgeInsets.only(
                                          left: 20,
                                          right: 20,
                                        ),
                                        value: 'kaydedilendosyalar',
                                        child: Text(
                                          'kaydedilen Dosyalar',
                                          style: TextStyle(
                                            fontSize:
                                                Theme.of(context)
                                                    .textTheme
                                                    .bodyMedium!
                                                    .fontSize,
                                          ),
                                        ),
                                      ),
                                      Provider.of<Dosyaislemleri>(
                                                context,
                                                listen: false,
                                              ).kopyalananfolder.isNotEmpty ||
                                              Provider.of<Dosyaislemleri>(
                                                context,
                                                listen: false,
                                              ).kopyalananfile.isNotEmpty
                                          ? PopupMenuItem(
                                            value: 'yapistir',
                                            child: Text(
                                              'yapistir',
                                              style: TextStyle(
                                                fontSize:
                                                    Theme.of(context)
                                                        .textTheme
                                                        .bodyMedium!
                                                        .fontSize,
                                              ),
                                            ),
                                          )
                                          : PopupMenuItem(
                                            height: 0,
                                            child: SizedBox(),
                                          ),
                                    ],
                                onSelected: (value) {
                                  if (value == 'klasorolustur') {
                                    Provider.of<Dosyaislemleri>(
                                      context,
                                      listen: false,
                                    ).klasorekle(
                                      Provider.of<Izinler>(
                                        context,
                                        listen: false,
                                      ).getCurrentFolder!,
                                      context,
                                      'yeni klasor',
                                    );
                                  } else if (value == 'gizlidosyalar') {
                                    String sifre = '';
                                    gizlidosyalarsifresisorgulama(
                                      context,
                                      sifre,
                                    );
                                  } else if (value == 'yapistir') {
                                    // Silme işlemi
                                  } else if (value == 'kaydedilendosyalar') {
                                    context.push(Paths.kaydedilendosyalar);
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  )
                  : Container(
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

  Future<dynamic> gizlidosyalarsifresisorgulama(
    BuildContext context,
    String sifre,
  ) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(20),
        ), // Köşeleri yuvarlat
      ),
      builder:
          (context) => Container(
            padding: EdgeInsets.only(
              top: 20,
              left: 20,
              right: 20,
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.8,
            ),
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
                            Icon(
                              Icons.lock,
                              color: Theme.of(context).primaryColor,
                              size: 50,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: TextField(
                                controller: _controller,
                                decoration: InputDecoration(
                                  hintText: 'Sifreyi Giriniz',
                                  hintStyle:
                                      Theme.of(context).textTheme.bodyLarge,
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
                        sifre = _controller.text;
                        _controller.text = '';
                        if (sifre == 'alihimeyda') {
                          context.push(Paths.gizlidosyalar);
                          Navigator.pop(context);
                        } else {
                          Navigator.pop(context);
                          Fluttertoast.showToast(
                            msg: "Sifre Hatali",
                            toastLength: Toast.LENGTH_SHORT,
                            gravity: ToastGravity.TOP,
                            timeInSecForIosWeb: 10,
                            backgroundColor:
                                Theme.of(context).secondaryHeaderColor,
                            textColor:
                                Theme.of(context).textTheme.labelLarge!.color,
                            fontSize: 16.0,
                          );
                        }
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
      onTap: () {
        Provider.of<Dosyaislemleri>(context, listen: false).kopyala(context);
      },
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
      onTap: () {
        Provider.of<Dosyaislemleri>(context, listen: false).kaydet(context);
      },
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
              isScrollControlled: true,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(20),
                ), // Köşeleri yuvarlat
              ),
              builder:
                  (context) => Container(
                    padding: EdgeInsets.only(
                      top: 20,
                      left: 20,
                      right: 20,
                      bottom: MediaQuery.of(context).viewInsets.bottom,
                    ),
                    constraints: BoxConstraints(
                      maxHeight: MediaQuery.of(context).size.height * 0.8,
                    ),
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
