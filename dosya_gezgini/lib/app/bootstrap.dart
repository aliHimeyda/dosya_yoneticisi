import 'package:dosya_gezgini/app/app.dart';
import 'package:dosya_gezgini/core/localization/locale_provider.dart';
import 'package:dosya_gezgini/core/theme/app_theme.dart';
import 'package:dosya_gezgini/features/files/state/altislem_provider.dart';
import 'package:dosya_gezgini/features/files/state/dosyaislemleri.dart';
import 'package:dosya_gezgini/features/files/state/izinler.dart';
import 'package:dosya_gezgini/features/menu/state/localestoragebilgileri.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

Future<void> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: AppColors.kuyupembe,
      statusBarIconBrightness: Brightness.light,
    ),
  );

  runApp(buildApp());
}

Widget buildApp() {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (_) => AppTheme()),
      ChangeNotifierProvider(create: (_) => LocaleProvider()..loadSavedLocale()),
      ChangeNotifierProvider(create: (_) => Dosyaislemleri()),
      ChangeNotifierProvider(create: (_) => Altislemprovider()),
      ChangeNotifierProvider(
        create: (_) => Izinler()..requestAllStoragePermission(),
      ),
      ChangeNotifierProvider(
        create: (_) => Localestoragebilgileri()..depolamabilgilernigetir(),
      ),
    ],
    child: const DosyaGezginiApp(),
  );
}
