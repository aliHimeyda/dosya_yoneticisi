import 'package:dosya_gezgini/core/localization/l10n_extensions.dart';
import 'package:dosya_gezgini/core/localization/locale_provider.dart';
import 'package:dosya_gezgini/core/theme/app_theme.dart';
import 'package:dosya_gezgini/features/files/state/izinler.dart';
import 'package:dosya_gezgini/features/menu/data/services/downloads_status_service.dart';
import 'package:dosya_gezgini/features/menu/data/services/network_stats_service.dart';
import 'package:dosya_gezgini/features/menu/state/localestoragebilgileri.dart';
import 'package:dosya_gezgini/features/menu/state/menu_provider.dart';
import 'package:dosya_gezgini/features/menu/state/menu_status_provider.dart';
import 'package:dosya_gezgini/shared/widgets/app_skeleton.dart';
import 'package:dosya_gezgini/shared/widgets/storage_card_skeleton.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

class Menu extends StatelessWidget {
  const Menu({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<MenuProvider>(create: (_) => MenuProvider()),
        ChangeNotifierProvider<MenuStatusProvider>(
          create:
              (context) => MenuStatusProvider(
                izinler: context.read<Izinler>(),
                downloadsStatusService: DownloadsStatusService(),
                networkStatsService: const NetworkStatsService(),
              )..initialize(),
        ),
      ],
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
    final isCurrentRoute = ModalRoute.of(context)?.isCurrent ?? true;

    context.read<MenuStatusProvider>().syncRouteVisibility(isCurrentRoute);

    return Center(
      child: Column(
        children: [
          Container(
            height: 50,
            width: MediaQuery.of(context).size.width,
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(width: 2, color: appTheme.primaryColor),
              ),
            ),
            child: depolamaDurumuBox(context, appTheme),
          ),
          Wrap(
            children: [
              saatIslemKutusu(context, appTheme),
              pilDurumuIslemKutusu(context, appTheme),
              indirilenlerIslemKutusu(context, appTheme),
              internetKullanimiIslemKutusu(context, appTheme),
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
                      selector:
                          (_, appThemeProvider) => appThemeProvider.temaiconu,
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
    ThemeData appTheme,
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
                    style: ButtonStyle(
                      backgroundColor: WidgetStateProperty.resolveWith<Color?>((
                        states,
                      ) {
                        if (states.contains(WidgetState.selected)) {
                          return Theme.of(context).primaryColor;
                        }
                        return Colors.transparent;
                      }),
                      foregroundColor: WidgetStateProperty.resolveWith<Color?>((
                        states,
                      ) {
                        if (states.contains(WidgetState.selected)) {
                          return Colors.white;
                        }
                        return Theme.of(context).colorScheme.onSurface;
                      }),
                    ),
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

  Widget saatIslemKutusu(BuildContext context, ThemeData appTheme) {
    final menuProvider = context.read<MenuProvider>();
    return bilgiKutusuCercevesi(
      context,
      appTheme,
      child: StreamBuilder<String>(
        stream: menuProvider.currentTimeStream,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const AppSkeleton(
              width: 72,
              height: 18,
              borderRadius: BorderRadius.all(Radius.circular(6)),
            );
          }

          return Row(
            children: [
              Icon(Icons.schedule, size: 24, color: appTheme.primaryColor),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  snapshot.data!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: bilgiDegeriTextStyle(appTheme),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget pilDurumuIslemKutusu(BuildContext context, ThemeData appTheme) {
    final menuProvider = context.read<MenuProvider>();
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Container(
        width: MediaQuery.of(context).size.width / 2 - 60,
        height: 60,
        decoration: BoxDecoration(
          border: Border.all(width: 0.8, color: appTheme.iconTheme.color!),
          borderRadius: BorderRadius.circular(10),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(9.2),
          child: StreamBuilder<int>(
            stream: menuProvider.batteryLevelStream,
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(
                  child: AppSkeleton(
                    width: 72,
                    height: 18,
                    borderRadius: BorderRadius.all(Radius.circular(6)),
                  ),
                );
              }

              final batteryLevel = snapshot.data!.clamp(0, 100);
              final batteryProgress = batteryLevel / 100;

              return Stack(
                children: [
                  Positioned.fill(
                    child: LinearProgressIndicator(
                      value: batteryProgress,
                      backgroundColor: appTheme.scaffoldBackgroundColor,
                      color: appTheme.secondaryHeaderColor,
                      minHeight: 60,
                    ).animate().custom(
                      duration: 1.seconds,
                      begin: 0.0,
                      end: batteryProgress,
                      builder:
                          (context, value, child) => LinearProgressIndicator(
                            value: value,
                            backgroundColor: appTheme.scaffoldBackgroundColor,
                            color: appTheme.secondaryHeaderColor,
                            minHeight: 60,
                          ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Row(
                        children: [
                          Icon(
                            Icons.battery_6_bar,
                            size: 24,
                            color: appTheme.primaryColor,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '$batteryLevel%',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: bilgiDegeriTextStyle(appTheme),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget depolamaDurumuBox(BuildContext context, ThemeData appTheme) {
    final storage = context.watch<Localestoragebilgileri>();
    final totalSpace = storage.totalspace <= 0 ? 1 : storage.totalspace;

    return SizedBox(
      width: MediaQuery.of(context).size.width,
      height: 50,
      child:
          storage.usedspace != 0
              ? Stack(
                children: [
                  LinearProgressIndicator(
                    value: storage.usedspace / totalSpace,
                    backgroundColor: appTheme.scaffoldBackgroundColor,
                    color: appTheme.secondaryHeaderColor,
                    minHeight: 50,
                  ).animate().custom(
                    duration: 1.seconds,
                    begin: 0.0,
                    end: storage.usedspace / totalSpace,
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
                      style: bilgiDegeriTextStyle(appTheme),
                    ),
                  ),
                ],
              )
              : const StorageCardSkeleton(height: 50),
    );
  }

  Widget indirilenlerIslemKutusu(BuildContext context, ThemeData appTheme) {
    final l10n = context.l10n;
    return bilgiKutusuCercevesi(
      context,
      appTheme,
      child: Selector<
        MenuStatusProvider,
        ({bool isLoading, String sizeText, String? error})
      >(
        selector:
            (_, provider) => (
              isLoading: provider.isLoadingDownloadsSize,
              sizeText: provider.downloadsSizeText,
              error: provider.downloadsSizeError,
            ),
        builder: (context, state, _) {
          if (state.isLoading) {
            return const AppSkeleton(
              width: 88,
              height: 28,
              borderRadius: BorderRadius.all(Radius.circular(6)),
            );
          }

          final displayText = switch (state.error) {
            MenuStatusProvider.permissionDeniedError =>
              l10n.permissionDeniedShort,
            MenuStatusProvider.unreadableError => l10n.unreadableShort,
            _ => state.sizeText,
          };

          return Row(
            children: [
              Icon(
                Icons.download_rounded,
                size: 24,
                color: appTheme.primaryColor,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.downloadsLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: bilgiEtiketiTextStyle(appTheme),
                    ),
                    Text(
                      displayText,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: bilgiDegeriTextStyle(appTheme),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget internetKullanimiIslemKutusu(
    BuildContext context,
    ThemeData appTheme,
  ) {
    return bilgiKutusuCercevesi(
      context,
      appTheme,
      child: Selector<
        MenuStatusProvider,
        ({String downloadText, String uploadText, bool isAvailable})
      >(
        selector:
            (_, provider) => (
              downloadText: provider.downloadSpeedText,
              uploadText: provider.uploadSpeedText,
              isAvailable: provider.isNetworkStatsAvailable,
            ),
        builder: (context, state, _) {
          final downloadText =
              state.isAvailable ? state.downloadText : '0 KB/s';
          final uploadText = state.isAvailable ? state.uploadText : '0 KB/s';

          return Row(
            children: [
              Icon(Icons.wifi_rounded, size: 24, color: appTheme.primaryColor),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.download_rounded,
                          size: 16,
                          color: appTheme.primaryColor,
                        ),
                        const SizedBox(width: 1),
                        Text(
                          downloadText,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: bilgiDegeriTextStyle(appTheme),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Icon(
                          Icons.upload_rounded,
                          size: 16,
                          color: appTheme.primaryColor,
                        ),
                        const SizedBox(width: 1),
                        Text(
                          uploadText,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: bilgiAltDegerTextStyle(appTheme),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget bilgiKutusuCercevesi(
    BuildContext context,
    ThemeData appTheme, {
    required Widget child,
  }) {
    return Padding(
      padding: const EdgeInsets.all(10),
      child: Container(
        width: MediaQuery.of(context).size.width / 2 - 60,
        height: 60,
        decoration: BoxDecoration(
          border: Border.all(width: 0.8, color: appTheme.iconTheme.color!),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: child,
          ),
        ),
      ),
    );
  }

  TextStyle bilgiDegeriTextStyle(ThemeData appTheme) {
    return (appTheme.textTheme.bodyLarge ?? const TextStyle()).copyWith(
      fontWeight: FontWeight.w700,
      color: appTheme.textTheme.bodyLarge?.color,
    );
  }

  TextStyle bilgiAltDegerTextStyle(ThemeData appTheme) {
    return (appTheme.textTheme.bodyMedium ?? const TextStyle()).copyWith(
      fontWeight: FontWeight.w600,
      color: appTheme.textTheme.bodyMedium?.color,
    );
  }

  TextStyle bilgiEtiketiTextStyle(ThemeData appTheme) {
    return (appTheme.textTheme.bodyMedium ?? const TextStyle()).copyWith(
      fontWeight: FontWeight.w600,
      color: (appTheme.textTheme.bodyMedium?.color ?? appTheme.iconTheme.color)
          ?.withValues(alpha: 0.76),
    );
  }

  GestureDetector islemsecenegi(
    BuildContext context,
    IconData icon,
    String hizmet,
    int index,
    ThemeData appTheme,
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
