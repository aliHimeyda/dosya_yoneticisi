// ignore_for_file: avoid_unnecessary_containers

import 'package:dosya_gezgini/app/router/app_router.dart';
import 'package:dosya_gezgini/core/localization/l10n_extensions.dart';
import 'package:dosya_gezgini/features/files/state/altislem_provider.dart';
import 'package:dosya_gezgini/features/files/state/dosyaislemleri.dart';
import 'package:dosya_gezgini/features/files/state/izinler.dart';
import 'package:dosya_gezgini/features/navigation/state/anasayfa_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class Anasayfa extends StatelessWidget {
  const Anasayfa({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<AnasayfaProvider>(
      create:
          (context) => AnasayfaProvider(
            navigationShell: navigationShell,
            izinler: context.read<Izinler>(),
            altIslemProvider: context.read<Altislemprovider>(),
            dosyaIslemleri: context.read<Dosyaislemleri>(),
          ),
      child: _AnasayfaView(navigationShell: navigationShell),
    );
  }
}

class _AnasayfaView extends StatelessWidget {
  const _AnasayfaView({required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    const icon = Icons.keyboard_arrow_up;
    final appTheme = Theme.of(context);
    final currentLocation = GoRouterState.of(context).uri.toString();
    final isSelectionMode = context.watch<Altislemprovider>().anahtar;
    final showFolderContextActions = Paths.isFolderContextLocation(
      currentLocation,
    );
    final provider = context.read<AnasayfaProvider>();

    provider.syncRouteState(currentLocation);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          return;
        }

        provider.handleRootPop(context, isSelectionMode: isSelectionMode);
      },
      child: Scaffold(
        bottomNavigationBar: _selectionActionBar(context, appTheme),
        backgroundColor: appTheme.scaffoldBackgroundColor,
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(
            kBottomNavigationBarHeight * 2.1,
          ),
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
                        _topNavigationBar(context, appTheme),
                        _locationAndActionsRow(context, appTheme),
                      ],
                    ),
                  )
                  : _topNavigationBar(context, appTheme),
        ),
        floatingActionButton: _cleanupButton(context),
        body: Stack(
          children: [
            navigationShell,
            Positioned(
              bottom: 0,
              right: 0,
              left: 0,
              child: Center(
                child: GestureDetector(
                  onTap: provider.handleSelectionHandleTap,
                  child: Container(
                    width: 40,
                    height: 20,
                    decoration: BoxDecoration(
                      color: appTheme.primaryColor,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(50),
                        topRight: Radius.circular(50),
                      ),
                    ),
                    child: const Center(child: Icon(icon)),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _selectionActionBar(BuildContext context, ThemeData appTheme) {
    final provider = context.read<AnasayfaProvider>();
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
                    _actionButton(
                      context,
                      icon: Icons.delete_outlined,
                      label: context.l10n.delete,
                      onTap: () => provider.showDeleteConfirmation(context),
                    ),
                    _actionButton(
                      context,
                      icon: Icons.copy_all_outlined,
                      label: context.l10n.copy,
                      onTap: () => provider.copySelection(context),
                    ),
                    _actionButton(
                      context,
                      icon: Icons.content_cut_outlined,
                      label: context.l10n.cut,
                      onTap: () => provider.cutSelection(context),
                    ),
                    _actionButton(
                      context,
                      icon: Icons.favorite_border_outlined,
                      label: context.l10n.save,
                      onTap: () => provider.saveSelection(context),
                    ),
                    _actionButton(
                      context,
                      icon: Icons.lock_outlined,
                      label: context.l10n.hide,
                      onTap: () => provider.hideSelection(context),
                    ),
                    _actionButton(
                      context,
                      icon: Icons.drive_file_rename_outline,
                      label: context.l10n.rename,
                      onTap: () => provider.showRenameSheet(context),
                    ),
                    Selector<Dosyaislemleri, bool>(
                      selector:
                          (_, dosyaIslemleri) =>
                              dosyaIslemleri.hasSelectedFiles,
                      builder: (context, hasSelectedFiles, _) {
                        return hasSelectedFiles
                            ? _actionButton(
                              context,
                              icon: Icons.share,
                              label: context.l10n.share,
                              onTap: provider.shareSelection,
                            )
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

  Widget _topNavigationBar(BuildContext context, ThemeData appTheme) {
    final provider = context.read<AnasayfaProvider>();
    final selectedNavigationIndex = provider.currentNavigationIndex;

    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(width: 4, color: appTheme.primaryColor),
        ),
      ),
      child: NavigationBar(
        labelBehavior: NavigationDestinationLabelBehavior.alwaysHide,
        indicatorColor: Colors.transparent,
        height: 60,
        selectedIndex: selectedNavigationIndex,
        onDestinationSelected: provider.goToBranch,
        destinations: [
          _bottomIcon(
            context,
            index: 0,
            currentIndex: selectedNavigationIndex,
            icon: Icons.menu,
            label: context.l10n.navigationMenu,
            appTheme: appTheme,
          ),
          _bottomIcon(
            context,
            index: 1,
            currentIndex: selectedNavigationIndex,
            icon: Icons.history,
            label: context.l10n.navigationRecent,
            appTheme: appTheme,
          ),
          _bottomIcon(
            context,
            index: 2,
            currentIndex: selectedNavigationIndex,
            icon: Icons.folder,
            label: context.l10n.navigationFolders,
            appTheme: appTheme,
          ),
          _bottomIcon(
            context,
            index: 3,
            currentIndex: selectedNavigationIndex,
            icon: Icons.search,
            label: context.l10n.navigationSearch,
            appTheme: appTheme,
          ),
        ],
      ),
    );
  }

  Widget _locationAndActionsRow(BuildContext context, ThemeData appTheme) {
    final provider = context.read<AnasayfaProvider>();

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        Container(
          width: (MediaQuery.of(context).size.width / 3) * 2,
          height: 35,
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.only(left: 10),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            controller: provider.pathScrollController,
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
        Selector<Dosyaislemleri, bool>(
          selector:
              (_, dosyaIslemleri) =>
                  dosyaIslemleri.kopyalananfolder.isNotEmpty ||
                  dosyaIslemleri.kopyalananfile.isNotEmpty,
          builder: (context, showPasteAction, _) {
            return Theme(
              data: appTheme.copyWith(
                popupMenuTheme: PopupMenuThemeData(
                  color: appTheme.secondaryHeaderColor,
                ),
              ),
              child: PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert),
                itemBuilder:
                    (context) => [
                      PopupMenuItem(
                        value: 'klasorolustur',
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Text(
                          context.l10n.createFolder,
                          style: TextStyle(
                            fontSize: appTheme.textTheme.bodyMedium!.fontSize,
                          ),
                        ),
                      ),
                      PopupMenuItem(
                        value: 'gizlidosyalar',
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Text(
                          context.l10n.hiddenFiles,
                          style: TextStyle(
                            fontSize: appTheme.textTheme.bodyMedium!.fontSize,
                          ),
                        ),
                      ),
                      PopupMenuItem(
                        value: 'kaydedilendosyalar',
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Text(
                          context.l10n.savedFiles,
                          style: TextStyle(
                            fontSize: appTheme.textTheme.bodyMedium!.fontSize,
                          ),
                        ),
                      ),
                      if (showPasteAction)
                        PopupMenuItem(
                          value: 'yapistir',
                          child: Text(
                            context.l10n.paste,
                            style: TextStyle(
                              fontSize: appTheme.textTheme.bodyMedium!.fontSize,
                            ),
                          ),
                        ),
                    ],
                onSelected:
                    (value) => provider.handleFolderMenuAction(context, value),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _cleanupButton(BuildContext context) {
    final provider = context.read<AnasayfaProvider>();
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(100)),
      child: FloatingActionButton(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
        onPressed: () => provider.openCleanupPage(context),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Center(
            child: Image.asset('assets/temizleyici.png', width: 30, height: 30),
          ),
        ),
      ),
    );
  }

  Widget _actionButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [Icon(icon, size: 30), Text(label)],
        ),
      ),
    );
  }

  Widget _bottomIcon(
    BuildContext context, {
    required int index,
    required int currentIndex,
    required IconData icon,
    required String label,
    required ThemeData appTheme,
  }) {
    return NavigationDestination(
      icon: Icon(
        icon,
        color:
            currentIndex == index
                ? appTheme.primaryColor
                : appTheme.iconTheme.color,
      ),
      label: label,
    );
  }
}
