import 'package:battery_plus/battery_plus.dart';
import 'package:dosya_gezgini/app/router/app_router.dart';
import 'package:dosya_gezgini/core/localization/locale_provider.dart';
import 'package:dosya_gezgini/core/theme/app_theme.dart';
import 'package:dosya_gezgini/features/files/presentation/widgets/hidden_password_bottom_sheet.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class MenuProvider extends ChangeNotifier {
  MenuProvider();

  static final Battery _battery = Battery();

  late final Stream<String> currentTimeStream = _createCurrentTimeStream();
  late final Stream<int> batteryLevelStream = _createBatteryLevelStream();

  Stream<String> _createCurrentTimeStream() async* {
    yield DateFormat('HH:mm:ss').format(DateTime.now());
    while (true) {
      await Future<void>.delayed(const Duration(seconds: 1));
      yield DateFormat('HH:mm:ss').format(DateTime.now());
    }
  }

  Stream<int> _createBatteryLevelStream() async* {
    yield await _battery.batteryLevel;
    while (true) {
      await Future<void>.delayed(const Duration(seconds: 1));
      yield await _battery.batteryLevel;
    }
  }

  void toggleTheme(BuildContext context) {
    context.read<AppTheme>().changetheme();
  }

  void changeLanguage(BuildContext context, String languageCode) {
    context.read<LocaleProvider>().setLanguageCode(languageCode);
  }

  Future<void> handleMenuAction(BuildContext context, int index) async {
    switch (index) {
      case 1:
        context.push(Paths.temizliksayfasi);
        return;
      case 2:
        await showHiddenFilesPasswordSheet(context);
        return;
      case 3:
        context.push(Paths.kaydedilendosyalar);
        return;
    }
  }

  Future<void> showHiddenFilesPasswordSheet(BuildContext context) async {
    final result = await showHiddenFilesPasswordFlow(context);
    if (context.mounted && result != null) {
      context.push(Paths.gizlidosyalar);
    }
  }
}
