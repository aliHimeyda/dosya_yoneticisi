import 'package:dosya_gezgini/features/files/presentation/pages/cleaner_page.dart';
import 'package:dosya_gezgini/features/files/state/dosyaislemleri.dart';
import 'package:dosya_gezgini/features/files/state/temizliksayfasi_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class Temizliksayfasi extends StatelessWidget {
  const Temizliksayfasi({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<TemizliksayfasiProvider>(
      create:
          (context) =>
              TemizliksayfasiProvider(owner: context.read<Dosyaislemleri>())
                ..ensureScanStarted(),
      child: const CleanerPage(),
    );
  }
}
