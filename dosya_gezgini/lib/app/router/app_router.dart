import 'package:dosya_gezgini/features/files/presentation/models/folder_route_data.dart';
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

final routerkey = GlobalKey<NavigatorState>(debugLabel: 'rootRouter');
final menuBranchNavigatorKey = GlobalKey<NavigatorState>(
  debugLabel: 'menuBranch',
);
final homeBranchNavigatorKey = GlobalKey<NavigatorState>(
  debugLabel: 'homeBranch',
);
final filesBranchNavigatorKey = GlobalKey<NavigatorState>(
  debugLabel: 'filesBranch',
);
final searchBranchNavigatorKey = GlobalKey<NavigatorState>(
  debugLabel: 'searchBranch',
);

GlobalKey<NavigatorState> navigatorKeyForBranchIndex(int index) {
  switch (index) {
    case Paths.menuBranchIndex:
      return menuBranchNavigatorKey;
    case Paths.homeBranchIndex:
      return homeBranchNavigatorKey;
    case Paths.filesBranchIndex:
      return filesBranchNavigatorKey;
    case Paths.searchBranchIndex:
      return searchBranchNavigatorKey;
    default:
      return homeBranchNavigatorKey;
  }
}

class Paths {
  Paths._();

  static const int menuBranchIndex = 0;
  static const int homeBranchIndex = 1;
  static const int filesBranchIndex = 2;
  static const int searchBranchIndex = 3;

  static const String logo = '/logo';
  static const String menu = '/menu';
  static const String anasayfa = '/';
  static const String dosyalar = '/dosyalar';
  static const String arama = '/arama';
  static const String folderPathQueryParameter = 'path';

  static const String temizliksayfasiSegment = 'temizliksayfasi';
  static const String kaydedilendosyalarSegment = 'kaydedilendosyalar';
  static const String gizlidosyalarSegment = 'gizlidosyalar';
  static const String katagorikicerikSegment = 'katagorikicerik';
  static const String klasoricerigisayfasiSegment = 'klasoricerigisayfasi';

  static const String temizliksayfasi = '$menu/$temizliksayfasiSegment';
  static const String kaydedilendosyalar = '$menu/$kaydedilendosyalarSegment';
  static const String gizlidosyalar = '$menu/$gizlidosyalarSegment';
  static const String katagorikicerik = '/$katagorikicerikSegment';
  static const String klasoricerigisayfasi = '/$klasoricerigisayfasiSegment';
  static const String dosyalarKlasoricerigisayfasi =
      '$dosyalar/$klasoricerigisayfasiSegment';
  static const String aramaKlasoricerigisayfasi =
      '$arama/$klasoricerigisayfasiSegment';

  static String menuChildLocation(String segment) => '$menu/$segment';

  static String categoryContentLocation(String folderPath) {
    return Uri(
      path: katagorikicerik,
      queryParameters: <String, String>{folderPathQueryParameter: folderPath},
    ).toString();
  }

  static String homeFolderContentLocation(String folderPath) {
    return Uri(
      path: klasoricerigisayfasi,
      queryParameters: <String, String>{folderPathQueryParameter: folderPath},
    ).toString();
  }

  static String filesFolderContentLocation(String folderPath) {
    return Uri(
      path: dosyalarKlasoricerigisayfasi,
      queryParameters: <String, String>{folderPathQueryParameter: folderPath},
    ).toString();
  }

  static String searchFolderContentLocation(String folderPath) {
    return Uri(
      path: aramaKlasoricerigisayfasi,
      queryParameters: <String, String>{folderPathQueryParameter: folderPath},
    ).toString();
  }

  static String folderContentLocationFor(
    String currentLocation,
    String folderPath,
  ) {
    if (isSearchLocation(currentLocation)) {
      return searchFolderContentLocation(folderPath);
    }

    if (isFilesLocation(currentLocation)) {
      return filesFolderContentLocation(folderPath);
    }

    return homeFolderContentLocation(folderPath);
  }

  static bool isCleanupLocation(String location) {
    return location == temizliksayfasi ||
        location.startsWith('$temizliksayfasi?');
  }

  static bool isMenuLocation(String location) {
    final path = _normalizeLocationPath(location);
    return path == menu || path.startsWith('$menu/');
  }

  static bool isHomeLocation(String location) {
    final path = _normalizeLocationPath(location);
    return path == anasayfa ||
        path == katagorikicerik ||
        path == klasoricerigisayfasi;
  }

  static bool isFilesLocation(String location) {
    final path = _normalizeLocationPath(location);
    return path == dosyalar || path.startsWith('$dosyalar/');
  }

  static bool isFilesRootLocation(String location) {
    return _normalizeLocationPath(location) == dosyalar;
  }

  static bool isSearchLocation(String location) {
    final path = _normalizeLocationPath(location);
    return path == arama || path.startsWith('$arama/');
  }

  static bool isFolderContextLocation(String location) {
    final path = _normalizeLocationPath(location);
    return path == dosyalar ||
        path == klasoricerigisayfasi ||
        path == katagorikicerik ||
        path == dosyalarKlasoricerigisayfasi ||
        path == aramaKlasoricerigisayfasi;
  }

  static String _normalizeLocationPath(String location) {
    if (location.isEmpty) {
      return anasayfa;
    }

    return Uri.tryParse(location)?.path ?? location;
  }
}

final router = GoRouter(
  navigatorKey: routerkey,
  initialLocation: Paths.logo,
  routes: [
    GoRoute(path: Paths.logo, builder: (context, state) => const Logosayfasi()),
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return Anasayfa(navigationShell: navigationShell);
      },
      branches: [
        StatefulShellBranch(
          navigatorKey: menuBranchNavigatorKey,
          routes: [
            GoRoute(
              path: Paths.menu,
              builder: (context, state) => const Menu(),
              routes: [
                GoRoute(
                  path: Paths.temizliksayfasiSegment,
                  builder: (context, state) => Temizliksayfasi(),
                ),
                GoRoute(
                  path: Paths.kaydedilendosyalarSegment,
                  builder: (context, state) => const Kaydedilendosyalar(),
                ),
                GoRoute(
                  path: Paths.gizlidosyalarSegment,
                  builder: (context, state) => const Gizlidosyalar(),
                ),
              ],
            ),
          ],
        ),
        StatefulShellBranch(
          navigatorKey: homeBranchNavigatorKey,
          routes: [
            GoRoute(
              path: Paths.anasayfa,
              builder: (context, state) => const Anasayfaicerigi(),
              routes: [
                GoRoute(
                  path: Paths.katagorikicerikSegment,
                  builder:
                      (context, state) => Katagorikicerik(
                        folder: FolderRouteData.fromState(state),
                      ),
                ),
                GoRoute(
                  path: Paths.klasoricerigisayfasiSegment,
                  builder:
                      (context, state) => Klasoricerigisayfasi(
                        folder: FolderRouteData.fromState(state),
                      ),
                ),
              ],
            ),
          ],
        ),
        StatefulShellBranch(
          navigatorKey: filesBranchNavigatorKey,
          routes: [
            GoRoute(
              path: Paths.dosyalar,
              builder: (context, state) => const Dosyalar(),
              routes: [
                GoRoute(
                  path: Paths.klasoricerigisayfasiSegment,
                  builder:
                      (context, state) => Klasoricerigisayfasi(
                        folder: FolderRouteData.fromState(state),
                      ),
                ),
              ],
            ),
          ],
        ),
        StatefulShellBranch(
          navigatorKey: searchBranchNavigatorKey,
          routes: [
            GoRoute(
              path: Paths.arama,
              builder: (context, state) => const Arama(),
              routes: [
                GoRoute(
                  path: Paths.klasoricerigisayfasiSegment,
                  builder:
                      (context, state) => Klasoricerigisayfasi(
                        folder: FolderRouteData.fromState(state),
                      ),
                ),
              ],
            ),
          ],
        ),
      ],
    ),
  ],
);
