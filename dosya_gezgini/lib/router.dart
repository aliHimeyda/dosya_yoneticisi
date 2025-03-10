import 'package:dosya_gezgini/anasayfa.dart';
import 'package:dosya_gezgini/anasayfaicerigi.dart';
import 'package:dosya_gezgini/arama.dart';
import 'package:dosya_gezgini/dosyalar.dart';
import 'package:dosya_gezgini/folderleragaci.dart';
import 'package:dosya_gezgini/klasoricerigisayfasi.dart';
import 'package:dosya_gezgini/menu.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

final routerkey = GlobalKey<NavigatorState>();

class Paths {
  Paths._();
  static const String anasayfa = '/';
  static const String anasayfaicerigi = '/anasayfaicerigi';
  static const String arama = '/arama';
  static const String dosyalar = '/dosyalar';
  static const String menu = '/menu';
  static const String klasoricerigisayfasi = '/klasoricerigisayfasi';
}

// ignore: non_constant_identifier_names
final router = GoRouter(
  navigatorKey: routerkey,

  initialLocation: Paths.anasayfa,
  routes: [
    StatefulShellRoute.indexedStack(
      builder:
          (context, state, navigationShell) =>
              Anasayfa(navigationShell: navigationShell),
      branches: [
        StatefulShellBranch(
          navigatorKey:
              GlobalKey<NavigatorState>(), // Alt navigator için yeni key
          routes: [
            GoRoute(
              path: Paths.menu,
              builder: (context, state) => const Menu(),
            ),
          ],
        ),
        StatefulShellBranch(
          navigatorKey:
              GlobalKey<NavigatorState>(), // Alt navigator için yeni key
          routes: [
            GoRoute(
              path: Paths.anasayfa,
              builder: (context, state) => const Anasayfaicerigi(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: Paths.dosyalar,
              builder: (context, state) => const Dosyalar(),
            ),
          ],
        ),

        // StatefulShellBranch(
        //   routes: [
        //     GoRoute(
        //       path: Paths.urundetaylari,
        //       builder: (context, state) {
        //         final data =
        //             state.extra
        //                 as Map<String, Object>; // Extra ile gelen veriyi al
        //         final urun = data['urun'] as Urunler; // Urun nesnesini al
        //         final seridler = data['seridler'] as List<Serid>;

        //         return Urunkartiicerigi(
        //           urun: urun,
        //           seridler: seridler,
        //         ); // Sayfaya nesneyi geçir
        //       },
        //     ),
        //   ],
        // ),
        StatefulShellBranch(
          routes: [
            GoRoute(path: Paths.arama, builder: (context, state) => Arama()),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: Paths.klasoricerigisayfasi,
              builder: (context, state) {
                final klasor = state.extra as FolderNode;
                return Klasoricerigisayfasi(klasor: klasor);
              },
            ),
          ],
        ),
      ],
    ),
  ],
);
