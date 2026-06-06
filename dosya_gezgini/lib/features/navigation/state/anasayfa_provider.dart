import 'dart:io';

import 'package:dosya_gezgini/app/router/app_router.dart';
import 'package:dosya_gezgini/core/localization/l10n_extensions.dart';
import 'package:dosya_gezgini/features/files/state/altislem_provider.dart';
import 'package:dosya_gezgini/features/files/state/dosyaislemleri.dart';
import 'package:dosya_gezgini/features/files/state/folderleragaci.dart';
import 'package:dosya_gezgini/features/files/state/izinler.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:go_router/go_router.dart';
import 'package:path/path.dart' as pathinfo;

class AnasayfaProvider extends ChangeNotifier {
  AnasayfaProvider({
    required StatefulNavigationShell navigationShell,
    required Izinler izinler,
    required Altislemprovider altIslemProvider,
    required Dosyaislemleri dosyaIslemleri,
  }) : _navigationShell = navigationShell,
       _izinler = izinler,
       _altIslemProvider = altIslemProvider,
       _dosyaIslemleri = dosyaIslemleri;

  static const String _hiddenFilesPassword = 'alihimeyda';

  final StatefulNavigationShell _navigationShell;
  final Izinler _izinler;
  final Altislemprovider _altIslemProvider;
  final Dosyaislemleri _dosyaIslemleri;

  final TextEditingController textController = TextEditingController();
  final ScrollController pathScrollController = ScrollController();

  String? _lastSyncedLocation;
  bool _isDisposed = false;

  int get currentNavigationIndex => _navigationShell.currentIndex;

  GlobalKey<NavigatorState> get _currentBranchNavigatorKey {
    return navigatorKeyForBranchIndex(_navigationShell.currentIndex);
  }

  bool get _currentBranchCanPop {
    return _currentBranchNavigatorKey.currentState?.canPop() ?? false;
  }

  void syncRouteState(String currentLocation) {
    if (_lastSyncedLocation == currentLocation) {
      return;
    }
    _lastSyncedLocation = currentLocation;

    if (Paths.isFilesRootLocation(currentLocation)) {
      final rootFolder = _izinler.fileTree.root;
      if (!identical(_izinler.currentFolder, rootFolder)) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_isDisposed) {
            return;
          }

          _izinler.setVisibleFolder(rootFolder);
        });
      }
    }

    if (Paths.isFolderContextLocation(currentLocation)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_isDisposed || !pathScrollController.hasClients) {
          return;
        }

        pathScrollController.animateTo(
          pathScrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOut,
        );
      });
    }
  }

  void clearSelectionMode() {
    if (!_altIslemProvider.anahtar) {
      return;
    }

    _altIslemProvider.setSelectionMode(false);
    _dosyaIslemleri.clearSelection();
  }

  void handleSelectionHandleTap() {
    if (_altIslemProvider.anahtar) {
      clearSelectionMode();
      return;
    }

    _altIslemProvider.setSelectionMode(true);
  }

  void handleRootPop(BuildContext context, {required bool isSelectionMode}) {
    if (isSelectionMode) {
      clearSelectionMode();
      return;
    }

    if (_currentBranchCanPop) {
      _currentBranchNavigatorKey.currentState?.pop();
      return;
    }

    if (_navigationShell.currentIndex != Paths.homeBranchIndex) {
      _navigationShell.goBranch(Paths.homeBranchIndex);
      return;
    }

    if (Platform.isAndroid || Platform.isIOS) {
      SystemNavigator.pop();
    }
  }

  void goToBranch(int index) {
    _navigationShell.goBranch(index);
  }

  Future<void> handleFolderMenuAction(
    BuildContext context,
    String value,
  ) async {
    switch (value) {
      case 'klasorolustur':
        final currentFolder = _izinler.currentFolder;
        if (currentFolder == null) {
          return;
        }
        await _dosyaIslemleri.klasorekle(
          currentFolder,
          context,
          context.l10n.newFolderDefaultName,
        );
        return;
      case 'gizlidosyalar':
        await showHiddenFilesPasswordSheet(context);
        return;
      case 'yapistir':
        await _dosyaIslemleri.yapistir(context);
        return;
      case 'kaydedilendosyalar':
        context.push(Paths.kaydedilendosyalar);
        return;
    }
  }

  void openCleanupPage(BuildContext context) {
    context.push(Paths.temizliksayfasi);
  }

  Future<void> showHiddenFilesPasswordSheet(BuildContext context) async {
    final appTheme = Theme.of(context);
    final pageContext = context;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder:
          (sheetContext) => Container(
            padding: EdgeInsets.only(
              top: 20,
              left: 20,
              right: 20,
              bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
            ),
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(sheetContext).size.height * 0.8,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(
                  child: Container(
                    width: MediaQuery.of(sheetContext).size.width - 20,
                    height: MediaQuery.of(sheetContext).size.height / 10,
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
                              controller: textController,
                              decoration: InputDecoration(
                                hintText: sheetContext.l10n.passwordHint,
                                hintStyle: appTheme.textTheme.bodyLarge,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    ElevatedButton(
                      onPressed:
                          () => _submitHiddenFilesPassword(
                            pageContext: pageContext,
                            sheetContext: sheetContext,
                            appTheme: appTheme,
                          ),
                      child: Text(sheetContext.l10n.ok),
                    ),
                    ElevatedButton(
                      onPressed: () => _closeSheet(sheetContext),
                      child: Text(sheetContext.l10n.cancel),
                    ),
                  ],
                ),
              ],
            ),
          ),
    );
  }

  void _submitHiddenFilesPassword({
    required BuildContext pageContext,
    required BuildContext sheetContext,
    required ThemeData appTheme,
  }) {
    final password = textController.text.trim();
    _closeSheet(sheetContext);

    if (!pageContext.mounted) {
      return;
    }

    if (password == _hiddenFilesPassword) {
      pageContext.push(Paths.gizlidosyalar);
      return;
    }

    Fluttertoast.showToast(
      msg: pageContext.l10n.incorrectPassword,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.TOP,
      timeInSecForIosWeb: 10,
      backgroundColor: appTheme.secondaryHeaderColor,
      textColor: appTheme.textTheme.labelLarge!.color,
      fontSize: 16,
    );
  }

  Future<void> showDeleteConfirmation(BuildContext context) async {
    final pageContext = context;
    await showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder:
          (sheetContext) => Container(
            padding: const EdgeInsets.all(20),
            height: 180,
            width: MediaQuery.of(sheetContext).size.width - 20,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  sheetContext.l10n.deleteWarning,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: () async {
                    Navigator.of(sheetContext).pop();
                    await _dosyaIslemleri.sil(pageContext);
                  },
                  child: Text(sheetContext.l10n.ok),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => Navigator.of(sheetContext).pop(),
                  child: Text(sheetContext.l10n.cancel),
                ),
              ],
            ),
          ),
    );
  }

  void copySelection(BuildContext context) {
    _dosyaIslemleri.kopyala(context);
  }

  void cutSelection(BuildContext context) {
    _dosyaIslemleri.kes(context);
  }

  void saveSelection(BuildContext context) {
    _dosyaIslemleri.kaydet(context);
  }

  void hideSelection(BuildContext context) {
    _dosyaIslemleri.sakla(context);
  }

  void shareSelection() {
    _dosyaIslemleri.dosyalaripaylas();
  }

  Future<void> showRenameSheet(BuildContext context) async {
    final folders = _dosyaIslemleri.getfolders() ?? <FolderNode>[];
    final files = _dosyaIslemleri.getfiles() ?? <File>[];

    if (folders.isNotEmpty) {
      for (final folder in List<FolderNode>.from(folders)) {
        await _showFolderRenameSheet(context, folder);
        if (!context.mounted) {
          return;
        }
      }
    }

    if (files.isNotEmpty) {
      for (final file in List<File>.from(files)) {
        await _showFileRenameSheet(context, file);
        if (!context.mounted) {
          return;
        }
      }
    }
  }

  Future<void> _showFolderRenameSheet(
    BuildContext context,
    FolderNode folder,
  ) async {
    final appTheme = Theme.of(context);
    final pageContext = context;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder:
          (sheetContext) => Container(
            padding: EdgeInsets.only(
              top: 20,
              left: 20,
              right: 20,
              bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
            ),
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(sheetContext).size.height * 0.8,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(
                  child: Container(
                    width: MediaQuery.of(sheetContext).size.width - 20,
                    height: MediaQuery.of(sheetContext).size.height / 10,
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
                              controller: textController,
                              decoration: InputDecoration(
                                hintText: folder.name,
                                hintStyle: appTheme.textTheme.bodyLarge,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    ElevatedButton(
                      onPressed: () async {
                        final newName = textController.text.trim();
                        Navigator.of(sheetContext).pop();
                        await _dosyaIslemleri.adlandir(
                          folder.path,
                          newName,
                          pageContext,
                        );
                        textController.clear();
                      },
                      child: Text(sheetContext.l10n.ok),
                    ),
                    ElevatedButton(
                      onPressed: () => _closeSheet(sheetContext),
                      child: Text(sheetContext.l10n.cancel),
                    ),
                  ],
                ),
              ],
            ),
          ),
    );
  }

  Future<void> _showFileRenameSheet(BuildContext context, File file) async {
    final appTheme = Theme.of(context);
    final pageContext = context;
    final fileBaseName = pathinfo.basenameWithoutExtension(file.path);
    final fileExtension = pathinfo.extension(file.path);

    await showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder:
          (sheetContext) => Container(
            padding: const EdgeInsets.all(20),
            height: 200,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(
                  child: Container(
                    width: MediaQuery.of(sheetContext).size.width - 20,
                    height: MediaQuery.of(sheetContext).size.height / 10,
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
                            _assetForExtension(fileExtension),
                            width: 40,
                            height: 40,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextField(
                              controller: textController,
                              decoration: InputDecoration(
                                hintText: fileBaseName,
                                hintStyle: appTheme.textTheme.bodyLarge,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    ElevatedButton(
                      onPressed: () async {
                        final newName =
                            '${textController.text.trim()}$fileExtension';
                        Navigator.of(sheetContext).pop();
                        await _dosyaIslemleri.adlandir(
                          file.path,
                          newName,
                          pageContext,
                        );
                        textController.clear();
                      },
                      child: Text(sheetContext.l10n.ok),
                    ),
                    ElevatedButton(
                      onPressed: () => _closeSheet(sheetContext),
                      child: Text(sheetContext.l10n.cancel),
                    ),
                  ],
                ),
              ],
            ),
          ),
    );
  }

  String _assetForExtension(String extension) {
    return switch (extension.toLowerCase()) {
      '.pdf' => 'assets/pdf.png',
      '.png' || '.jpg' || '.jpeg' => 'assets/image.png',
      '.doc' || '.docx' => 'assets/doc.png',
      '.xls' || '.xlsx' => 'assets/xls.png',
      '.ppt' || '.pptx' => 'assets/ppt.png',
      '.txt' => 'assets/txt.png',
      '.mp3' => 'assets/mp3.png',
      '.mp4' => 'assets/mp4.png',
      '.zip' => 'assets/zip.png',
      _ => 'assets/file.png',
    };
  }

  void _closeSheet(BuildContext sheetContext) {
    textController.clear();
    Navigator.of(sheetContext).pop();
  }

  @override
  void dispose() {
    _isDisposed = true;
    textController.dispose();
    pathScrollController.dispose();
    super.dispose();
  }
}
