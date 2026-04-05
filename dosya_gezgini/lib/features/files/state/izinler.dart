import 'package:dosya_gezgini/core/constants/storage_paths.dart';
import 'package:dosya_gezgini/features/files/state/folderleragaci.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Izinler extends ChangeNotifier {
  Izinler() : fileTree = FileTree(storageRootPath) {
    fileTree.addListener(notifyListeners);
  }

  final FileTree fileTree;

  bool _izin = false;
  List<String>? _currentFolderPath;
  FolderNode? _currentFolder;

  final List<FolderNode> previousFolders = [];

  List<String>? get getcurrentFolderPath {
    if (_currentFolder == null) {
      _currentFolderPath = ['kok dizin'];
      return _currentFolderPath;
    }

    if (_currentFolder!.path.split('/').length < 3) {
      _currentFolderPath = ['kok dizin'];
      return _currentFolderPath;
    }

    _currentFolderPath = _currentFolder!.path.split('/').sublist(4);
    return _currentFolderPath;
  }

  FolderNode? get getCurrentFolder => _currentFolder;

  void klasorekle(FolderNode folder) {
    _currentFolder!.folderchildren.add(folder);
    notifyListeners();
  }

  Future<void> setCurrentFolder(FolderNode folder) async {
    if (_currentFolder != null && !previousFolders.contains(folder)) {
      previousFolders.add(_currentFolder!);
    }
    await fileTree.loadFolder(folder);
    _currentFolder = folder;
    notifyListeners();
  }

  void goBack() {
    if (previousFolders.isNotEmpty) {
      _currentFolder = previousFolders.removeLast();
      notifyListeners();
    }
  }

  Future<bool> get izin async {
    final pref = await SharedPreferences.getInstance();
    final izinverilmismi = pref.getBool('izinanahtari') ?? false;
    if (izinverilmismi) {
      _izin = true;
      return _izin;
    }

    _izin = await Permission.manageExternalStorage.status.isGranted;
    pref.setBool('izinanahtari', _izin);
    return _izin;
  }

  Future<void> setIzin(bool value) async {
    final pref = await SharedPreferences.getInstance();
    _izin = value;
    pref.setBool('izinanahtari', _izin);
    notifyListeners();
  }

  Future<void> requestAllStoragePermission() async {
    final status = await Permission.manageExternalStorage.status;

    if (status.isGranted) {
      await setIzin(true);
      await fileTree.buildTree();
      notifyListeners();
      return;
    }

    final newStatus = await Permission.manageExternalStorage.request();

    if (newStatus.isGranted) {
      await setIzin(true);
      await fileTree.buildTree();
      notifyListeners();
      return;
    }

    if (newStatus.isDenied) {
      await setIzin(false);
      return;
    }

    await openAppSettings();
    await setIzin(false);
  }

  @override
  void dispose() {
    fileTree.removeListener(notifyListeners);
    super.dispose();
  }
}
