import 'package:battery_plus/battery_plus.dart';
import 'package:dosya_gezgini/app/router/app_router.dart';
import 'package:dosya_gezgini/core/localization/l10n_extensions.dart';
import 'package:dosya_gezgini/core/localization/locale_provider.dart';
import 'package:dosya_gezgini/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class MenuProvider extends ChangeNotifier {
  MenuProvider();

  static const String _hiddenFilesPassword = 'alihimeyda';
  static final Battery _battery = Battery();

  final TextEditingController passwordController = TextEditingController();

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
    final pageContext = context;
    final appTheme = Theme.of(context);

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder:
          (sheetContext) => Container(
            padding: EdgeInsets.only(
              top: 20,
              left: 20,
              right: 20,
              bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 100,
            ),
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(sheetContext).size.height * 0.8,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(
                  child: Container(
                    width: MediaQuery.of(sheetContext).size.width - 20,
                    height: MediaQuery.of(sheetContext).size.height / 10,
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          width: 0.3,
                          color: appTheme.iconTheme.color!,
                        ),
                        top: BorderSide(
                          width: 1,
                          color: appTheme.iconTheme.color!,
                        ),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: Row(
                        children: [
                          Icon(
                            Icons.lock,
                            color: appTheme.primaryColor,
                            size: 50,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextField(
                              controller: passwordController,
                              decoration: InputDecoration(
                                hintText: sheetContext.l10n.passwordHint,
                                hintStyle: appTheme.textTheme.bodyLarge,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    ElevatedButton(
                      onPressed:
                          () => _submitHiddenFilesPassword(
                            pageContext: pageContext,
                            sheetContext: sheetContext,
                          ),
                      child: Text(sheetContext.l10n.ok),
                    ),
                    ElevatedButton(
                      onPressed: () => _closeHiddenFilesPasswordSheet(sheetContext),
                      child: Text(sheetContext.l10n.cancel),
                    ),
                  ],
                ),
              ],
            ),
          ),
    );
  }

  void _submitHiddenFilesPassword({
    required BuildContext pageContext,
    required BuildContext sheetContext,
  }) {
    final password = passwordController.text.trim();
    _closeHiddenFilesPasswordSheet(sheetContext);

    if (!pageContext.mounted) {
      return;
    }

    if (password == _hiddenFilesPassword) {
      pageContext.push(Paths.gizlidosyalar);
      return;
    }

    final appTheme = Theme.of(pageContext);
    Fluttertoast.showToast(
      msg: pageContext.l10n.incorrectPassword,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.TOP,
      timeInSecForIosWeb: 10,
      backgroundColor: appTheme.secondaryHeaderColor,
      textColor: appTheme.textTheme.labelLarge!.color,
      fontSize: 16,
    );
  }

  void _closeHiddenFilesPasswordSheet(BuildContext sheetContext) {
    passwordController.clear();
    Navigator.of(sheetContext).pop();
  }

  @override
  void dispose() {
    passwordController.dispose();
    super.dispose();
  }
}
