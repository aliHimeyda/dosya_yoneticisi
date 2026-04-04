import 'package:dosya_gezgini/app/router/app_router.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Logosayfasi extends StatefulWidget {
  const Logosayfasi({super.key});

  @override
  State<Logosayfasi> createState() => _LogosayfasiState();
}

class _LogosayfasiState extends State<Logosayfasi> {
  @override
  void initState() {
    super.initState();
    izinverilmismi();
    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) {
        return;
      }
      context.go(Paths.anasayfa);
    });
  }

  Future<void> izinverilmismi() async {
    final pref = await SharedPreferences.getInstance();
    final izin = pref.getBool('izinanahtari');
    if (izin == null) {
      await pref.setBool('izinanahtari', false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFffc4d2),
      body: Center(
        child: Image.asset('assets/logoresmi.png', fit: BoxFit.contain),
      ),
    );
  }
}
