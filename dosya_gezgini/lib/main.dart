import 'package:dosya_gezgini/altislemprovider.dart';
import 'package:dosya_gezgini/anasayfaicerigi.dart';
import 'package:dosya_gezgini/dosyaislemleri.dart';
import 'package:dosya_gezgini/folderleragaci.dart';
import 'package:dosya_gezgini/localestoragebilgileri.dart';
import 'package:dosya_gezgini/logosayfasi.dart';
import 'package:dosya_gezgini/menu.dart';
import 'package:dosya_gezgini/renkler.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get_it/get_it.dart';
import 'package:provider/provider.dart';

final getIt = GetIt.instance; // GetIt örneğini oluştur

void setupLocator() {
  getIt.registerSingleton<Izinler>(Izinler()); // Provider'ı kaydet
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: AppColors.kuyupembe, // 🔥 Burayı değiştirebilirsin
      statusBarIconBrightness:
          Brightness.light, // 🔥 İkonları beyaz yapmak için
    ),
  );
  String rootPath = "/storage/emulated/0";
  setupLocator(); // Locator'ı kur
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => AppTheme()),
        ChangeNotifierProvider(create: (context) => Dosyaislemleri()),
        ChangeNotifierProvider(
          create: (context) => Altislemprovider()..anahtar,
        ),
        ChangeNotifierProvider(create: (context) => FileTree(rootPath)),
        ChangeNotifierProvider(
          create: (context) => FolderNode('name', rootPath, [], [], null),
        ),
        ChangeNotifierProvider(
          create: (context) => Izinler()..requestAllStoragePermission(),
        ),
        ChangeNotifierProvider(
          create:
              (context) => Localestoragebilgileri()..depolamabilgilernigetir(),
        ),
      ],
      child: const Program(),
    ),
  );
}

class Program extends StatelessWidget {
  const Program({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppTheme>(
      builder:
          (context, viewModel, child) => MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: viewModel.theme,
            home: Logosayfasi(),
          ),
    );
  }
}
