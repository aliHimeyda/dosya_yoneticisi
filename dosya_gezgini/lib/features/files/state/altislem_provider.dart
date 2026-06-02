import 'package:flutter/material.dart';

class Altislemprovider extends ChangeNotifier {
  late bool _anahtar = false;
  late bool secilmismi = false;
  bool get anahtar => _anahtar;

  void setSelectionMode(bool value) {
    if (_anahtar == value) {
      return;
    }

    _anahtar = value;
    notifyListeners();
  }

  void changeanahtar() {
    setSelectionMode(!_anahtar);
  }
}
