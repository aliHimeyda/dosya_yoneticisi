import 'package:dosya_gezgini/features/splash/state/logosayfasi_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class Logosayfasi extends StatelessWidget {
  const Logosayfasi({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<LogosayfasiProvider>(
      create: (_) => LogosayfasiProvider(),
      child: const _LogosayfasiView(),
    );
  }
}

class _LogosayfasiView extends StatelessWidget {
  const _LogosayfasiView();

  @override
  Widget build(BuildContext context) {
    context.read<LogosayfasiProvider>().start(context);

    return Scaffold(
      backgroundColor: const Color(0xFFffc4d2),
      body: Center(
        child: Image.asset('assets/logoresmi.png', fit: BoxFit.contain),
      ),
    );
  }
}
