// ignore_for_file: avoid_unnecessary_containers
import 'dart:io';
import 'package:dosya_gezgini/core/localization/l10n_extensions.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:dosya_gezgini/app/router/app_router.dart';
import 'package:dosya_gezgini/features/files/state/izinler.dart';
import 'package:path/path.dart' as pathinfo;
import 'package:dosya_gezgini/features/files/state/altislem_provider.dart';
import 'package:dosya_gezgini/features/files/state/dosyaislemleri.dart';
import 'package:dosya_gezgini/features/files/state/folderleragaci.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class Anasayfa extends StatefulWidget {
  final StatefulNavigationShell navigationShell;
  const Anasayfa({super.key, required this.navigationShell});

  @override
  State<Anasayfa> createState() => _AnasayfaState();
}

class _AnasayfaState extends State<Anasayfa> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  GlobalKey<NavigatorState> get _currentBranchNavigatorKey {
    return navigatorKeyForBranchIndex(widget.navigationShell.currentIndex);
  }

  bool get _currentBranchCanPop {
    return _currentBranchNavigatorKey.currentState?.canPop() ?? false;
  }

  void _syncVisibleFolderWithRoute(String currentLocation) {
    if (!Paths.isFilesRootLocation(currentLocation)) {
      return;
    }

    final izinler = context.read<Izinler>();
    final rootFolder = izinler.fileTree.root;
    if (identical(izinler.currentFolder, rootFolder)) {
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }

      context.read<Izinler>().setVisibleFolder(rootFolder);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _clearSelectionMode() {
    final altIslemProvider = context.read<Altislemprovider>();
    if (!altIslemProvider.anahtar) {
      return;
    }

    altIslemProvider.setSelectionMode(false);
    context.read<Dosyaislemleri>().clearSelection();
  }

  @override
  Widget build(BuildContext context) {
    late IconData icon = Icons.keyboard_arrow_up;
    final currentLocation = GoRouterState.of(context).uri.toString();
    final isSelectionMode = context.watch<Altislemprovider>().anahtar;
    final showFolderContextActions = Paths.isFolderContextLocation(
      currentLocation,
    );

    _syncVisibleFolderWithRoute(currentLocation);

    if (showFolderContextActions) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || !_scrollController.hasClients) {
          return;
        }

        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: Duration(milliseconds: 150),
          curve: Curves.easeOut,
        );
      });
    }
    final appTheme = Theme.of(context);
    // Mevcut sayfanın yolunu al (Yeni yöntem)
    // final String currentPath = GoRouterState.of(context).uri.toString();

    // Eğer Ozelurunler sayfasındaysak, BottomNavigationBar'ı gösterme
    // bool showBottomNavBar = true;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          return;
        }

        if (isSelectionMode) {
          _clearSelectionMode();
          return;
        }

        if (_currentBranchCanPop) {
          _currentBranchNavigatorKey.currentState?.pop();
          return;
        }

        if (widget.navigationShell.currentIndex != Paths.homeBranchIndex) {
          widget.navigationShell.goBranch(Paths.homeBranchIndex);
          return;
        }

        if (Platform.isAndroid || Platform.isIOS) {
          SystemNavigator.pop();
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
        bottomNavigationBar: _selectionActionBar(context, appTheme),
        appBar: PreferredSize(
          preferredSize: Size.fromHeight(kBottomNavigationBarHeight * 2.1),
          child:
              showFolderContextActions
                  ? Container(
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          width: 0.5,
                          color: appTheme.iconTheme.color!,
                        ),
                      ),
                    ),
                    child: Column(
                      children: [
                        ustbutonlarseridi(context, appTheme),

                        konumvedigerislemseridi(context, appTheme),
                      ],
                    ),
                  )
                  : ustbutonlarseridi(context, appTheme),
        ),
        floatingActionButton: temizlemebutonu(),
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
                    final altIslemProvider = context.read<Altislemprovider>();
                    if (altIslemProvider.anahtar) {
                      _clearSelectionMode();
                      return;
                    }

                    altIslemProvider.setSelectionMode(true);
                  },
                  child: Container(
                    width: 40,
                    height: 20,
                    decoration: BoxDecoration(
                      color: appTheme.primaryColor,
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

  Widget _selectionActionBar(BuildContext context, appTheme) {
    return Selector<Altislemprovider, bool>(
      selector: (_, altIslemProvider) => altIslemProvider.anahtar,
      builder: (context, isSelectionMode, _) {
        if (!isSelectionMode) {
          return const SizedBox.shrink();
        }

        return SafeArea(
          child: Animate(
            effects: const [
              SlideEffect(
                begin: Offset(0, 2),
                delay: Duration(milliseconds: 200),
              ),
            ],
            child: Container(
              width: MediaQuery.of(context).size.width - 20,
              height: 70,
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                border: Border.all(width: 2, color: appTheme.primaryColor),
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
                    adlandirbutonu(context, appTheme),
                    Selector<Dosyaislemleri, bool>(
                      selector:
                          (_, dosyaIslemleri) =>
                              dosyaIslemleri.hasSelectedFiles,
                      builder: (context, hasSelectedFiles, _) {
                        return hasSelectedFiles
                            ? paylasbutonu()
                            : const SizedBox.shrink();
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Container ustbutonlarseridi(BuildContext context, appTheme) {
    final selectedNavigationIndex = widget.navigationShell.currentIndex;

    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(width: 4, color: appTheme.primaryColor),
        ),
      ),
      child: NavigationBar(
        labelBehavior:
            NavigationDestinationLabelBehavior
                .alwaysHide, // Label'ı gizle ve boşluğu kaldır
        indicatorColor: Colors.transparent,
        height: 60,
        selectedIndex: selectedNavigationIndex,
        onDestinationSelected: (index) {
          widget.navigationShell.goBranch(index);
        },
        destinations: [
          bottomicons(
            context,
            index: 0,
            currentindex: selectedNavigationIndex,
            icon: Icons.menu,
            label: context.l10n.navigationMenu,
            appTheme: appTheme,
          ),
          bottomicons(
            context,
            index: 1,
            currentindex: selectedNavigationIndex,
            icon: Icons.history,
            label: context.l10n.navigationRecent,
            appTheme: appTheme,
          ),
          bottomicons(
            context,
            index: 2,
            currentindex: selectedNavigationIndex,
            icon: Icons.folder,
            label: context.l10n.navigationFolders,
            appTheme: appTheme,
          ),
          bottomicons(
            context,
            index: 3,
            currentindex: selectedNavigationIndex,
            icon: Icons.search,
            label: context.l10n.navigationSearch,
            appTheme: appTheme,
          ),
        ],
      ),
    );
  }

  Row konumvedigerislemseridi(BuildContext context, appTheme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        Container(
          width: (MediaQuery.of(context).size.width / 3) * 2,
          height: 35,
          alignment: Alignment.centerLeft,
          padding: EdgeInsets.only(left: 10),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            controller: _scrollController,
            child: Selector<Izinler, List<String>>(
              selector: (_, izinler) => izinler.currentFolderPathSegments,
              builder: (context, pathSegments, _) {
                return Wrap(
                  alignment: WrapAlignment.start,
                  children: [
                    for (final path in pathSegments)
                      Row(
                        children: [Text(path), const Icon(Icons.chevron_right)],
                      ),
                  ],
                );
              },
            ),
          ),
        ),
        Theme(
          data: appTheme.copyWith(
            popupMenuTheme: PopupMenuThemeData(
              color: appTheme.secondaryHeaderColor, // Menü arka planı
            ),
          ),
          child: PopupMenuButton<String>(
            icon: Icon(Icons.more_vert),
            itemBuilder:
                (context) => [
                  PopupMenuItem(
                    value: 'klasorolustur',
                    padding: EdgeInsets.only(left: 20, right: 20),
                    child: Text(
                      context.l10n.createFolder,
                      style: TextStyle(
                        fontSize: appTheme.textTheme.bodyMedium!.fontSize,
                      ),
                    ),
                  ),
                  PopupMenuItem(
                    padding: EdgeInsets.only(left: 20, right: 20),
                    value: 'gizlidosyalar',
                    child: Text(
                      context.l10n.hiddenFiles,
                      style: TextStyle(
                        fontSize: appTheme.textTheme.bodyMedium!.fontSize,
                      ),
                    ),
                  ),
                  PopupMenuItem(
                    padding: EdgeInsets.only(left: 20, right: 20),
                    value: 'kaydedilendosyalar',
                    child: Text(
                      context.l10n.savedFiles,
                      style: TextStyle(
                        fontSize: appTheme.textTheme.bodyMedium!.fontSize,
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
                          context.l10n.paste,
                          style: TextStyle(
                            fontSize: appTheme.textTheme.bodyMedium!.fontSize,
                          ),
                        ),
                      )
                      : PopupMenuItem(height: 0, child: SizedBox()),
                ],
            onSelected: (value) {
              if (value == 'klasorolustur') {
                Provider.of<Dosyaislemleri>(context, listen: false).klasorekle(
                  Provider.of<Izinler>(context, listen: false).currentFolder!,
                  context,
                  context.l10n.newFolderDefaultName,
                );
              } else if (value == 'gizlidosyalar') {
                String sifre = '';
                gizlidosyalarsifresisorgulama(context, sifre, appTheme);
              } else if (value == 'yapistir') {
                Provider.of<Dosyaislemleri>(
                  context,
                  listen: false,
                ).yapistir(context);
              } else if (value == 'kaydedilendosyalar') {
                context.push(Paths.kaydedilendosyalar);
              }
            },
          ),
        ),
      ],
    );
  }

  Container temizlemebutonu() {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(100)),
      child: FloatingActionButton(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(50), // Köşeleri yuvarlat
        ),
        onPressed: () {
          context.push(Paths.temizliksayfasi);
        },
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Center(
            child: Image.asset('assets/temizleyici.png', width: 30, height: 30),
          ),
        ),
      ),
    );
  }

  Future<dynamic> gizlidosyalarsifresisorgulama(
    BuildContext context,
    String sifre,
    appTheme,
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
                            color: appTheme.iconTheme.color!,
                          ),
                          top: BorderSide(
                            width: 1,
                            color: appTheme.iconTheme.color!,
                          ),
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(10),
                        child: Row(
                          children: [
                            Icon(
                              Icons.lock,
                              color: appTheme.primaryColor,
                              size: 50,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: TextField(
                                controller: _controller,
                                decoration: InputDecoration(
                                  hintText: context.l10n.passwordHint,
                                  hintStyle: appTheme.textTheme.bodyLarge,
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
                            msg: context.l10n.incorrectPassword,
                            toastLength: Toast.LENGTH_SHORT,
                            gravity: ToastGravity.TOP,
                            timeInSecForIosWeb: 10,
                            backgroundColor: appTheme.secondaryHeaderColor,
                            textColor: appTheme.textTheme.labelLarge!.color,
                            fontSize: 16.0,
                          );
                        }
                      }, // Kapatma butonu
                      child: Text(context.l10n.ok),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        // Provider.of<Dosyaislemleri>(
                        //   context,
                        //   listen: false,
                        // ).sil();
                        Navigator.pop(context);
                      }, // Kapatma butonu
                      child: Text(context.l10n.cancel),
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
                      context.l10n.deleteWarning,
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
                      child: Text(context.l10n.ok),
                    ),
                  ],
                ),
              ),
        );
      },
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.delete_outlined, size: 30),
            Text(context.l10n.delete),
          ],
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
          children: [
            Icon(Icons.copy_all_outlined, size: 30),
            Text(context.l10n.copy),
          ],
        ),
      ),
    );
  }

  GestureDetector kesbutonu() {
    return GestureDetector(
      onTap: () {
        Provider.of<Dosyaislemleri>(context, listen: false).kes(context);
      },
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.content_cut_outlined, size: 30),
            Text(context.l10n.cut),
          ],
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
            Text(context.l10n.save),
          ],
        ),
      ),
    );
  }

  GestureDetector saklabutonu() {
    return GestureDetector(
      onTap: () {
        Provider.of<Dosyaislemleri>(context, listen: false).sakla(context);
      },
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.lock_outlined, size: 30),
            Text(context.l10n.hide),
          ],
        ),
      ),
    );
  }

  GestureDetector paylasbutonu() {
    return GestureDetector(
      onTap: () {
        Provider.of<Dosyaislemleri>(context, listen: false).dosyalaripaylas();
      },
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [Icon(Icons.share, size: 30), Text(context.l10n.share)],
        ),
      ),
    );
  }

  GestureDetector adlandirbutonu(BuildContext context, appTheme) {
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
                                    color: appTheme.iconTheme.color!,
                                  ),
                                  top: BorderSide(
                                    width: 1,
                                    color: appTheme.iconTheme.color!,
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
                                              appTheme.textTheme.bodyLarge,
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
                              child: Text(context.l10n.ok),
                            ),
                            ElevatedButton(
                              onPressed: () {
                                // Provider.of<Dosyaislemleri>(
                                //   context,
                                //   listen: false,
                                // ).sil();
                                Navigator.pop(context);
                              }, // Kapatma butonu
                              child: Text(context.l10n.cancel),
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
                                    color: appTheme.iconTheme.color!,
                                  ),
                                  top: BorderSide(
                                    width: 1,
                                    color: appTheme.iconTheme.color!,
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
                                              appTheme.textTheme.bodyLarge,
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
                              child: Text(context.l10n.ok),
                            ),
                            ElevatedButton(
                              onPressed: () {
                                // Provider.of<Dosyaislemleri>(
                                //   context,
                                //   listen: false,
                                // ).sil();
                                Navigator.pop(context);
                              }, // Kapatma butonu
                              child: Text(context.l10n.cancel),
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
            Text(context.l10n.rename),
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
    required String label,
    appTheme,
  }) {
    return NavigationDestination(
      icon: Icon(
        icon,
        color:
            currentindex == index
                ? appTheme.primaryColor
                : appTheme.iconTheme.color,
      ),
      label: label,
    );
  }
}
