import 'package:battery_plus/battery_plus.dart';
import 'package:dosya_gezgini/app/router/app_router.dart';
import 'package:dosya_gezgini/core/localization/l10n_extensions.dart';
import 'package:dosya_gezgini/core/localization/locale_provider.dart';
import 'package:dosya_gezgini/core/theme/app_theme.dart';
import 'package:dosya_gezgini/features/menu/state/localestoragebilgileri.dart';
import 'package:dosya_gezgini/shared/widgets/app_skeleton.dart';
import 'package:dosya_gezgini/shared/widgets/storage_card_skeleton.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class Pil {
  static final Battery pil = Battery();
}

class Menu extends StatefulWidget {
  const Menu({super.key});

  @override
  State<Menu> createState() => _MenuState();
}

class _MenuState extends State<Menu> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Stream<String> zamanigetir() async* {
    while (true) {
      await Future.delayed(const Duration(seconds: 1));
      yield DateFormat('HH:mm:ss').format(DateTime.now());
    }
  }

  Stream<String> depolamaalanigetir() async* {
    while (true) {
      await Future.delayed(const Duration(seconds: 1));
      yield Battery().batteryLevel.toString();
    }
  }

  Stream<int> pildurumugetir() async* {
    while (true) {
      await Future.delayed(const Duration(seconds: 1));
      final pildurumu = await Pil.pil.batteryLevel;
      yield pildurumu;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final appTheme = Theme.of(context);
    return Center(
      child: Column(
        children: [
          Container(
            height: 50,
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(width: 2, color: appTheme.primaryColor),
              ),
            ),
            child: Row(
              children: [
                saatbox(context, appTheme),
                depolamaDurumuBox(context, appTheme),
                pilDurumuBox(context, appTheme),
              ],
            ),
          ),
          Wrap(
            children: [
              kareislemsecenegi(context, l10n.actionLabel, Icons.abc, appTheme),
              kareislemsecenegi(context, l10n.actionLabel, Icons.abc, appTheme),
              kareislemsecenegi(context, l10n.actionLabel, Icons.abc, appTheme),
              kareislemsecenegi(context, l10n.actionLabel, Icons.abc, appTheme),
            ],
          ),
          Animate(
            effects: [FadeEffect(duration: const Duration(milliseconds: 100))],
            child: Container(
              width: MediaQuery.of(context).size.width - 20,
              height: MediaQuery.of(context).size.height / 10,
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(width: 0.3, color: AppColors.koyuGri),
                  top: BorderSide(width: 1, color: AppColors.koyuGri),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Row(
                  children: [
                    Icon(context.watch<AppTheme>().temaiconu, size: 30),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.themeMode,
                            style: appTheme.textTheme.bodyLarge,
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: context.watch<AppTheme>().isdarkmode,
                      onChanged: (value) {
                        context.read<AppTheme>().changetheme();
                      },
                      activeThumbColor: appTheme.primaryColor,
                      inactiveThumbColor: appTheme.primaryColor,
                    ),
                  ],
                ),
              ),
            ),
          ),
          dilSecimCubugu(context, appTheme),
          islemsecenegi(
            context,
            Icons.delete_sweep,
            l10n.deepCleanup,
            1,
            appTheme,
          ),
          islemsecenegi(context, Icons.lock, l10n.privateFiles, 2, appTheme),
          islemsecenegi(context, Icons.favorite, l10n.savedFiles, 3, appTheme),
        ],
      ),
    );
  }

  Widget dilSecimCubugu(BuildContext context, appTheme) {
    final localeProvider = context.watch<LocaleProvider>();
    return Animate(
      effects: [FadeEffect(duration: const Duration(milliseconds: 100))],
      child: Container(
        width: MediaQuery.of(context).size.width - 20,
        height: MediaQuery.of(context).size.height / 10,
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(width: 0.3, color: AppColors.koyuGri),
            top: BorderSide(width: 1, color: AppColors.koyuGri),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            children: [
              const Icon(Icons.translate, size: 30),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.l10n.languageLabel,
                      style: appTheme.textTheme.bodyLarge,
                    ),
                  ],
                ),
              ),
              SegmentedButton<String>(
                showSelectedIcon: false,
                segments: const [
                  ButtonSegment<String>(value: 'tr', label: Text('TR')),
                  ButtonSegment<String>(value: 'en', label: Text('EN')),
                  ButtonSegment<String>(value: 'ar', label: Text('AR')),
                ],
                selected: {localeProvider.languageCode},
                onSelectionChanged: (selection) {
                  context.read<LocaleProvider>().setLanguageCode(
                    selection.first,
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Container saatbox(BuildContext context, appTheme) {
    return Container(
      width: MediaQuery.of(context).size.width / 4,
      height: 50,
      decoration: BoxDecoration(
        border: Border(
          right: BorderSide(width: 2, color: appTheme.primaryColor),
        ),
      ),
      child: Center(
        child: StreamBuilder<String>(
          stream: zamanigetir(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const AppSkeleton(
                width: 48,
                height: 18,
                borderRadius: BorderRadius.all(Radius.circular(6)),
              );
            }

            return Text(
              snapshot.data!,
              style: const TextStyle(fontWeight: FontWeight.bold),
            );
          },
        ),
      ),
    );
  }

  Container depolamaDurumuBox(BuildContext context, appTheme) {
    final storage = context.watch<Localestoragebilgileri>();
    return Container(
      width: MediaQuery.of(context).size.width / 2,
      height: 50,
      decoration: BoxDecoration(
        border: Border(
          right: BorderSide(width: 2, color: appTheme.primaryColor),
        ),
      ),
      child:
          storage.usedspace != 0
              ? Stack(
                children: [
                  LinearProgressIndicator(
                    value: storage.usedspace / storage.totalspace,
                    backgroundColor: appTheme.scaffoldBackgroundColor,
                    color: appTheme.secondaryHeaderColor,
                    minHeight: 50,
                  ).animate().custom(
                    duration: 1.seconds,
                    begin: 0.0,
                    end: storage.usedspace / storage.totalspace,
                    builder:
                        (context, value, child) => LinearProgressIndicator(
                          value: value,
                          backgroundColor: appTheme.scaffoldBackgroundColor,
                          color: appTheme.secondaryHeaderColor,
                          minHeight: 50,
                        ),
                  ),
                  Center(
                    child: Text(
                      '${storage.usedspace.toStringAsFixed(2)} | ${storage.totalspace.toStringAsFixed(2)} GB',
                    ),
                  ),
                ],
              )
              : const StorageCardSkeleton(height: 50),
    );
  }

  SizedBox pilDurumuBox(BuildContext context, appTheme) {
    return SizedBox(
      width: MediaQuery.of(context).size.width / 4,
      height: 50,
      child: Center(
        child: StreamBuilder<int>(
          stream: pildurumugetir(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const AppSkeleton(
                width: 52,
                height: 18,
                borderRadius: BorderRadius.all(Radius.circular(6)),
              );
            }

            return Stack(
              children: [
                LinearProgressIndicator(
                  value: snapshot.data! / 100,
                  backgroundColor: appTheme.scaffoldBackgroundColor,
                  color: appTheme.secondaryHeaderColor,
                  minHeight: 50,
                ).animate().custom(
                  duration: 1.seconds,
                  begin: 0.0,
                  end: snapshot.data! / 100,
                  builder:
                      (context, value, child) => LinearProgressIndicator(
                        value: value,
                        backgroundColor: appTheme.scaffoldBackgroundColor,
                        color: appTheme.secondaryHeaderColor,
                        minHeight: 50,
                      ),
                ),
                Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.earbuds_battery),
                      Text(
                        snapshot.data!.toString(),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  GestureDetector kareislemsecenegi(
    BuildContext context,
    String islem,
    IconData icon,
    appTheme,
  ) {
    return GestureDetector(
      onTap: () {},
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Container(
          width: MediaQuery.of(context).size.width / 2 - 60,
          height: 60,
          decoration: BoxDecoration(
            border: Border.all(width: 0.8, color: appTheme.iconTheme.color!),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Row(
                spacing: 4,
                children: [
                  Icon(icon, size: 30),
                  Expanded(
                    child: Text(
                      islem,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  const Icon(Icons.chevron_right),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  GestureDetector islemsecenegi(
    BuildContext context,
    IconData icon,
    String hizmet,
    int index,
    appTheme,
  ) {
    return GestureDetector(
      onTap: () {
        if (index == 1) {
          context.push(Paths.temizliksayfasi);
        } else if (index == 2) {
          gizlidosyalarsifresisorgulama(context, '', appTheme);
        } else if (index == 3) {
          context.push(Paths.kaydedilendosyalar);
        }
      },
      child: Animate(
        effects: [FadeEffect(duration: const Duration(milliseconds: 100))],
        child: Container(
          width: MediaQuery.of(context).size.width - 20,
          height: MediaQuery.of(context).size.height / 10,
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(width: 0.3, color: appTheme.iconTheme.color!),
              top: BorderSide(width: 1, color: appTheme.iconTheme.color!),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              children: [
                Icon(icon, size: 30),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(hizmet, style: appTheme.textTheme.bodyLarge),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<dynamic> gizlidosyalarsifresisorgulama(
    BuildContext context,
    String sifre,
    appTheme,
  ) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder:
          (context) => Container(
            padding: EdgeInsets.only(
              top: 20,
              left: 20,
              right: 20,
              bottom: MediaQuery.of(context).viewInsets.bottom + 100,
            ),
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.8,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(
                  child: Animate(
                    effects: [
                      FadeEffect(duration: const Duration(milliseconds: 100)),
                    ],
                    child: Container(
                      width: MediaQuery.of(context).size.width - 20,
                      height: MediaQuery.of(context).size.height / 10,
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
                                controller: _controller,
                                decoration: InputDecoration(
                                  hintText: context.l10n.passwordHint,
                                  hintStyle: appTheme.textTheme.bodyLarge,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        sifre = _controller.text;
                        _controller.text = '';
                        if (sifre == 'alihimeyda') {
                          context.push(Paths.gizlidosyalar);
                          Navigator.pop(context);
                        } else {
                          Navigator.pop(context);
                          Fluttertoast.showToast(
                            msg: context.l10n.incorrectPassword,
                            toastLength: Toast.LENGTH_SHORT,
                            gravity: ToastGravity.TOP,
                            timeInSecForIosWeb: 10,
                            backgroundColor: appTheme.secondaryHeaderColor,
                            textColor: appTheme.textTheme.labelLarge!.color,
                            fontSize: 16,
                          );
                        }
                      },
                      child: Text(context.l10n.ok),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: Text(context.l10n.cancel),
                    ),
                  ],
                ),
              ],
            ),
          ),
    );
  }
}
