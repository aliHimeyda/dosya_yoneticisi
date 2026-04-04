import 'package:dosya_gezgini/features/files/presentation/pages/dosyalar.dart';
import 'package:dosya_gezgini/features/files/presentation/pages/gizlidosyalar.dart';
import 'package:dosya_gezgini/features/files/presentation/pages/katagorikicerik.dart';
import 'package:dosya_gezgini/features/files/presentation/pages/kaydedilendosyalar.dart';
import 'package:dosya_gezgini/features/files/presentation/pages/klasoricerigisayfasi.dart';
import 'package:dosya_gezgini/features/files/presentation/pages/temizliksayfasi.dart';
import 'package:dosya_gezgini/features/home/presentation/pages/anasayfa_icerigi.dart';
import 'package:dosya_gezgini/features/menu/presentation/pages/menu.dart';
import 'package:dosya_gezgini/features/navigation/presentation/pages/anasayfa.dart';
import 'package:dosya_gezgini/features/search/presentation/pages/arama.dart';
import 'package:dosya_gezgini/features/splash/presentation/pages/logosayfasi.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

final routerkey = GlobalKey<NavigatorState>();

class Paths {
  Paths._();

  static const String logo = '/logo';
  static const String anasayfa = '/';
  static const String arama = '/arama';
  static const String dosyalar = '/dosyalar';
  static const String menu = '/menu';
  static const String klasoricerigisayfasi = '/klasoricerigisayfasi';
  static const String gizlidosyalar = '/gizlidosyalar';
  static const String kaydedilendosyalar = '/kaydedilendosyalar';
  static const String temizliksayfasi = '/temizliksayfasi';
  static const String katagorikicerik = '/katagorikicerik';
}

final router = GoRouter(
  navigatorKey: routerkey,
  initialLocation: Paths.logo,
  routes: [
    GoRoute(
      path: Paths.logo,
      builder: (context, state) => const Logosayfasi(),
    ),
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return Anasayfa(navigationShell: navigationShell);
      },
      branches: [
        StatefulShellBranch(
          navigatorKey: GlobalKey<NavigatorState>(),
          routes: [
            GoRoute(
              path: Paths.menu,
              builder: (context, state) => const Menu(),
            ),
          ],
        ),
        StatefulShellBranch(
          navigatorKey: GlobalKey<NavigatorState>(),
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
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: Paths.arama,
              builder: (context, state) => Arama(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: Paths.klasoricerigisayfasi,
              builder: (context, state) => Klasoricerigisayfasi(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: Paths.gizlidosyalar,
              builder: (context, state) => Gizlidosyalar(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: Paths.kaydedilendosyalar,
              builder: (context, state) => Kaydedilendosyalar(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: Paths.temizliksayfasi,
              builder: (context, state) => Temizliksayfasi(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: Paths.katagorikicerik,
              builder: (context, state) => Katagorikicerik(),
            ),
          ],
        ),
      ],
    ),
  ],
);
