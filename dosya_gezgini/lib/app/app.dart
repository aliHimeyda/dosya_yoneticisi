import 'package:dosya_gezgini/app/router/app_router.dart';
import 'package:dosya_gezgini/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class DosyaGezginiApp extends StatelessWidget {
  const DosyaGezginiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppTheme>(
      builder: (context, viewModel, child) {
        return MaterialApp.router(
          debugShowCheckedModeBanner: false,
          theme: viewModel.theme,
          routerConfig: router,
        );
      },
    );
  }
}
