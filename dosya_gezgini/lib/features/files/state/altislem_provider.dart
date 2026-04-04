import 'package:flutter/material.dart';

class Altislemprovider extends ChangeNotifier {
  late bool _anahtar = false;
  late bool secilmismi = false;
  bool get anahtar => _anahtar;
  void changeanahtar() {
    _anahtar = !_anahtar;
    notifyListeners();
  }
}
