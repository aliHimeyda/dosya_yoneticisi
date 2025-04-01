import 'package:dosya_gezgini/anasayfa.dart';
import 'package:dosya_gezgini/anasayfaicerigi.dart';
import 'package:dosya_gezgini/arama.dart';
import 'package:dosya_gezgini/dosyalar.dart';
import 'package:dosya_gezgini/gizlidosyalar.dart';
import 'package:dosya_gezgini/katagorikicerik.dart';
import 'package:dosya_gezgini/kaydedilendosyalar.dart';
import 'package:dosya_gezgini/klasoricerigisayfasi.dart';
import 'package:dosya_gezgini/menu.dart';
import 'package:dosya_gezgini/temizliksayfasi.dart';
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
  static const String gizlidosyalar = '/gizlidosyalar';
  static const String kaydedilendosyalar = '/kaydedilendosyalar';
  static const String temizliksayfasi = '/temizliksayfasi';
  static const String katagorikicerik = '/katagorikicerik';
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
                return Klasoricerigisayfasi();
              },
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: Paths.gizlidosyalar,
              builder: (context, state) {
                return Gizlidosyalar();
              },
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: Paths.kaydedilendosyalar,
              builder: (context, state) {
                return Kaydedilendosyalar();
              },
            ),
          ],
        ),
         StatefulShellBranch(
          routes: [
            GoRoute(
              path: Paths.temizliksayfasi,
              builder: (context, state) {
                return Temizliksayfasi();
              },
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: Paths.katagorikicerik,
              builder: (context, state) {
                return Katagorikicerik();
              },
            ),
          ],
        ),
      ],
    ),
  ],
);
