import 'package:dosya_gezgini/app/router/app_router.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LogosayfasiProvider extends ChangeNotifier {
  bool _started = false;
  bool _isDisposed = false;

  void start(BuildContext context) {
    if (_started) {
      return;
    }

    _started = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (_isDisposed) {
        return;
      }

      await _ensurePermissionFlag();
      if (_isDisposed) {
        return;
      }

      await Future<void>.delayed(const Duration(seconds: 2));
      if (_isDisposed || !context.mounted) {
        return;
      }

      context.go(Paths.anasayfa);
    });
  }

  Future<void> _ensurePermissionFlag() async {
    final pref = await SharedPreferences.getInstance();
    final izin = pref.getBool('izinanahtari');
    if (izin == null) {
      await pref.setBool('izinanahtari', false);
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }
}
