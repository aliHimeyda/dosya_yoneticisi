// ignore_for_file: avoid_unnecessary_containers
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

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
