import 'package:dosya_gezgini/core/localization/l10n_extensions.dart';
import 'package:dosya_gezgini/core/localization/locale_provider.dart';
import 'package:dosya_gezgini/core/theme/app_theme.dart';
import 'package:dosya_gezgini/features/menu/state/localestoragebilgileri.dart';
import 'package:dosya_gezgini/features/menu/state/menu_provider.dart';
import 'package:dosya_gezgini/shared/widgets/app_skeleton.dart';
import 'package:dosya_gezgini/shared/widgets/storage_card_skeleton.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

class Menu extends StatelessWidget {
  const Menu({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<MenuProvider>(
      create: (_) => MenuProvider(),
      child: const _MenuView(),
    );
  }
}

class _MenuView extends StatelessWidget {
  const _MenuView();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final appTheme = Theme.of(context);
    final menuProvider = context.read<MenuProvider>();
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
                    Selector<AppTheme, IconData>(
                      selector: (_, appThemeProvider) => appThemeProvider.temaiconu,
                      builder: (context, themeIcon, _) {
                        return Icon(themeIcon, size: 30);
                      },
                    ),
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
                    Selector<AppTheme, bool>(
                      selector:
                          (_, appThemeProvider) => appThemeProvider.isdarkmode,
                      builder: (context, isDarkMode, _) {
                        return Switch(
                          value: isDarkMode,
                          onChanged: (_) => menuProvider.toggleTheme(context),
                          activeThumbColor: appTheme.primaryColor,
                          inactiveThumbColor: appTheme.primaryColor,
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
          dilSecimCubugu(context, appTheme, menuProvider),
          islemsecenegi(
            context,
            Icons.delete_sweep,
            l10n.deepCleanup,
            1,
            appTheme,
            menuProvider,
          ),
          islemsecenegi(
            context,
            Icons.lock,
            l10n.privateFiles,
            2,
            appTheme,
            menuProvider,
          ),
          islemsecenegi(
            context,
            Icons.favorite,
            l10n.savedFiles,
            3,
            appTheme,
            menuProvider,
          ),
        ],
      ),
    );
  }

  Widget dilSecimCubugu(
    BuildContext context,
    appTheme,
    MenuProvider menuProvider,
  ) {
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
              Selector<LocaleProvider, String>(
                selector: (_, localeProvider) => localeProvider.languageCode,
                builder: (context, languageCode, _) {
                  return SegmentedButton<String>(
                    showSelectedIcon: false,
                    segments: const [
                      ButtonSegment<String>(value: 'tr', label: Text('TR')),
                      ButtonSegment<String>(value: 'en', label: Text('EN')),
                      ButtonSegment<String>(value: 'ar', label: Text('AR')),
                    ],
                    selected: {languageCode},
                    onSelectionChanged: (selection) {
                      menuProvider.changeLanguage(context, selection.first);
                    },
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
    final menuProvider = context.read<MenuProvider>();
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
          stream: menuProvider.currentTimeStream,
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
    final menuProvider = context.read<MenuProvider>();
    return SizedBox(
      width: MediaQuery.of(context).size.width / 4,
      height: 50,
      child: Center(
        child: StreamBuilder<int>(
          stream: menuProvider.batteryLevelStream,
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
    MenuProvider menuProvider,
  ) {
    return GestureDetector(
      onTap: () => menuProvider.handleMenuAction(context, index),
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
}
