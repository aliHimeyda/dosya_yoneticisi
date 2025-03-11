// ignore_for_file: avoid_unnecessary_containers
import 'package:dosya_gezgini/altislemprovider.dart';
import 'package:dosya_gezgini/renkler.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class Anasayfa extends StatelessWidget {
  final StatefulNavigationShell navigationShell;
  const Anasayfa({super.key, required this.navigationShell});

  @override
  Widget build(BuildContext context) {
    // Mevcut sayfanın yolunu al (Yeni yöntem)
    // final String currentPath = GoRouterState.of(context).uri.toString();

    // Eğer Ozelurunler sayfasındaysak, BottomNavigationBar'ı gösterme
    // bool showBottomNavBar = true;
    return Scaffold(
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
                            Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.delete_outlined, size: 30),
                                  Text('sil'),
                                ],
                              ),
                            ),
                            Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.copy_all_outlined, size: 30),
                                  Text('kopyala'),
                                ],
                              ),
                            ),
                            Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.content_cut_outlined, size: 30),
                                  Text('kes'),
                                ],
                              ),
                            ),
                            Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.favorite_border_outlined,
                                    size: 30,
                                  ),
                                  Text('kaydet'),
                                ],
                              ),
                            ),
                            Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.lock_outlined, size: 30),
                                  Text('sakla'),
                                ],
                              ),
                            ),
                            Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.drive_file_rename_outline,
                                    size: 30,
                                  ),
                                  Text('adlandir'),
                                ],
                              ),
                            ),
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
            selectedIndex: navigationShell.currentIndex,
            onDestinationSelected: navigationShell.goBranch,
            destinations: [
              bottomicons(
                context,
                index: 0,
                currentindex: navigationShell.currentIndex,
                icon: Icons.menu,
              ),
              bottomicons(
                context,
                index: 1,
                currentindex: navigationShell.currentIndex,
                icon: Icons.history,
              ),
              bottomicons(
                context,
                index: 2,
                currentindex: navigationShell.currentIndex,
                icon: Icons.folder,
              ),
              bottomicons(
                context,
                index: 3,
                currentindex: navigationShell.currentIndex,
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
      body: navigationShell,
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
