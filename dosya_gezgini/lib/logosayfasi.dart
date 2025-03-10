import 'package:dosya_gezgini/anasayfaicerigi.dart';
import 'package:dosya_gezgini/renkler.dart';
import 'package:dosya_gezgini/router.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Logosayfasi extends StatefulWidget {
  const Logosayfasi({super.key});

  @override
  State<Logosayfasi> createState() => _LogosayfasiState();
}

class _LogosayfasiState extends State<Logosayfasi> {
  late bool izinbilgisi = false;
  @override
  void initState() {
    izinverilmismi();
    Future.delayed(const Duration(seconds: 3), () {
      Navigator.pushReplacement(
        // ignore: use_build_context_synchronously
        context,
        MaterialPageRoute(
          builder:
              (context) => Consumer<AppTheme>(
                builder:
                    (context, Viewmodel, child) => MaterialApp.router(
                      theme: Viewmodel.theme,
                      routerConfig: router,
                      debugShowCheckedModeBanner: false,
                    ),
              ),
        ),
      );
    });

    super.initState();
  }

  Future<void> izinverilmismi() async {
    final pref = await SharedPreferences.getInstance();
    bool? izin = pref.getBool('izinanahtari');
    if (izin == null) {
      pref.setBool('izinanahtari', false);
      izinbilgisi = false;
    } else {
      izinbilgisi = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFffc4d2),
      body: Center(
        child: Image.asset('assets/logoresmi.png', fit: BoxFit.contain),
      ),
    );
  }
}
