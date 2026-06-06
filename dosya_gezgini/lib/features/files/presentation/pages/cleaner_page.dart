import 'package:dosya_gezgini/core/localization/l10n_extensions.dart';
import 'package:dosya_gezgini/core/theme/app_theme.dart';
import 'package:dosya_gezgini/data/models/cleaning_models.dart';
import 'package:dosya_gezgini/features/files/state/temizliksayfasi_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

class CleanerPage extends StatelessWidget {
  const CleanerPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottomSafeArea = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      backgroundColor: theme.cleanerSurface,
      body: SafeArea(
        child: Stack(
          children: [
            LayoutBuilder(
              builder: (context, constraints) {
                final horizontalPadding =
                    constraints.maxWidth >= 720 ? 32.0 : 24.0;
                return SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(
                    horizontalPadding,
                    20,
                    horizontalPadding,
                    160 + bottomSafeArea,
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 720),
                      child: const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _CleanerHeaderSection(),
                          SizedBox(height: 20),
                          _CleanerCircleSection(),
                          SizedBox(height: 5),
                          _CleanerStatusSection(),
                          SizedBox(height: 20),
                          _CleanerDetailsSection(),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
            const _CleanerBottomBarSection(),
          ],
        ),
      ),
    );
  }
}

class _CleanerHeaderSection extends StatelessWidget {
  const _CleanerHeaderSection();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Selector<TemizliksayfasiProvider, bool>(
      selector: (_, provider) => provider.canRetryFromHeader,
      builder: (context, canRetry, _) {
        return CleanerHeader(
              title: l10n.cleanerTitle,
              onBackPressed: () => Navigator.of(context).maybePop(),
              onSecondaryPressed:
                  canRetry
                      ? () =>
                          context
                              .read<TemizliksayfasiProvider>()
                              .handleHeaderAction()
                      : null,
              secondaryIcon: Icons.refresh_rounded,
            )
            .animate()
            .fadeIn(duration: 420.ms, curve: Curves.easeOutCubic)
            .slideY(
              begin: -0.08,
              end: 0,
              duration: 420.ms,
              curve: Curves.easeOutCubic,
            );
      },
    );
  }
}

class _CleanerCircleSection extends StatelessWidget {
  const _CleanerCircleSection();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Selector<
      TemizliksayfasiProvider,
      ({
        String totalSizeText,
        String sizeUnit,
        String currentLabel,
        bool isScanning,
        bool isCleaning,
      })
    >(
      selector:
          (_, provider) => (
            totalSizeText: provider.totalSizeText,
            sizeUnit: provider.sizeUnit,
            currentLabel: provider.resolveCurrentScanLabel(l10n),
            isScanning: provider.isScanning,
            isCleaning: provider.isCleaning,
          ),
      builder: (context, state, _) {
        return Center(
              child: CleanerScanCircle(
                totalSizeText: state.totalSizeText,
                sizeUnit: state.sizeUnit,
                currentScanningPackage: state.currentLabel,
                isScanning: state.isScanning,
                isCleaning: state.isCleaning,
                scanningPrefixText: l10n.cleanerScanningPrefix,
              ),
            )
            .animate()
            .fadeIn(duration: 520.ms, delay: 90.ms)
            .scale(
              begin: const Offset(0.94, 0.94),
              end: const Offset(1, 1),
              duration: 520.ms,
              curve: Curves.easeOutBack,
            );
      },
    );
  }
}

class _CleanerStatusSection extends StatelessWidget {
  const _CleanerStatusSection();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Selector<TemizliksayfasiProvider, List<CleanerScanItem>>(
      selector: (_, provider) => provider.buildScanItems(l10n),
      builder: (context, scanItems, _) {
        return CleanerScanStatusList(scanItems: scanItems)
            .animate()
            .fadeIn(duration: 460.ms, delay: 170.ms)
            .slideY(
              begin: 0.06,
              end: 0,
              duration: 460.ms,
              curve: Curves.easeOutCubic,
            );
      },
    );
  }
}

class _CleanerDetailsSection extends StatelessWidget {
  const _CleanerDetailsSection();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final provider = context.watch<TemizliksayfasiProvider>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CleanerInfoCard(
          title:
              provider.isCleaning
                  ? l10n.cleanerCleaningSummaryTitle
                  : l10n.cleanerScanSummaryTitle,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _MetricRow(
                text: l10n.cleanupScannedFiles(provider.processedFiles),
              ),
              _MetricRow(
                text: l10n.cleanupCandidatesFound(
                  provider.scannedCandidateCount,
                ),
              ),
              _MetricRow(
                text: l10n.cleanupRecoverableSpace(
                  provider.reclaimableSizeText,
                ),
              ),
            ],
          ),
        ),
        if (provider.deleteResult != null) ...[
          const SizedBox(height: 16),
          CleanerInfoCard(
            title: l10n.cleanupReportTitle,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _MetricRow(
                  text: l10n.cleanupDeletedCount(
                    provider.deleteResult!.deletedCount,
                  ),
                ),
                _MetricRow(
                  text: l10n.cleanupFailedCount(
                    provider.deleteResult!.issues.length,
                  ),
                ),
                _MetricRow(
                  text: l10n.cleanupFreedSpace(
                    provider.formatBytes(provider.deleteResult!.deletedBytes),
                  ),
                ),
              ],
            ),
          ),
        ],
        if (provider.cleanupError != null) ...[
          const SizedBox(height: 16),
          CleanerInfoCard(
            title: l10n.errorOccurred,
            child: Text(provider.errorMessage),
          ),
        ],
        if (provider.scanIssues.isNotEmpty) ...[
          const SizedBox(height: 16),
          CleanerIssueCard(
            title: l10n.cleanupScanIssues(provider.scanIssues.length),
            issues: provider.scanIssues,
          ),
        ],
        if (provider.deleteIssues.isNotEmpty) ...[
          const SizedBox(height: 16),
          CleanerIssueCard(
            title: l10n.cleanupDeleteIssues(provider.deleteIssues.length),
            issues: provider.deleteIssues,
          ),
        ],
      ],
    );
  }
}

class _CleanerBottomBarSection extends StatelessWidget {
  const _CleanerBottomBarSection();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final bottomPadding = MediaQuery.paddingOf(context).bottom;

    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: CleanerBottomActionBar(
            bottomPadding: bottomPadding,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 720),
                child: Selector<
                  TemizliksayfasiProvider,
                  ({String text, bool enabled})
                >(
                  selector:
                      (_, provider) => (
                        text: provider.resolveActionButtonText(l10n),
                        enabled: provider.isActionEnabled,
                      ),
                  builder: (context, state, _) {
                    return CleanerActionButton(
                      text: state.text,
                      isEnabled: state.enabled,
                      onPressed:
                          state.enabled
                              ? () => context
                                  .read<TemizliksayfasiProvider>()
                                  .handleMainAction(context)
                              : null,
                    );
                  },
                ),
              ),
            ),
          )
          .animate()
          .fadeIn(duration: 440.ms, delay: 260.ms)
          .slideY(
            begin: 0.24,
            end: 0,
            duration: 440.ms,
            curve: Curves.easeOutCubic,
          ),
    );
  }
}

class CleanerHeader extends StatelessWidget {
  const CleanerHeader({
    super.key,
    required this.title,
    required this.onBackPressed,
    required this.secondaryIcon,
    this.onSecondaryPressed,
  });

  final String title;
  final VoidCallback onBackPressed;
  final VoidCallback? onSecondaryPressed;
  final IconData secondaryIcon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            CleanerIconButton(
              icon: Icons.arrow_back_rounded,
              onPressed: onBackPressed,
            ),
            Text(
              title,
              style: theme.textTheme.headlineMedium?.copyWith(
                color: theme.cleanerPrimaryText,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.8,
              ),
            ),
            CleanerIconButton(
              icon: secondaryIcon,
              onPressed: onSecondaryPressed,
            ),
          ],
        ),
      ],
    );
  }
}

class CleanerIconButton extends StatelessWidget {
  const CleanerIconButton({super.key, required this.icon, this.onPressed});

  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEnabled = onPressed != null;
    return IconButton(
      onPressed: onPressed,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
      icon: Icon(
        icon,
        size: 28,
        color:
            isEnabled
                ? theme.cleanerPrimaryText
                : theme.cleanerSecondaryText.withValues(alpha: 0.45),
      ),
    );
  }
}

class CleanerScanCircle extends StatelessWidget {
  const CleanerScanCircle({
    super.key,
    required this.totalSizeText,
    required this.sizeUnit,
    required this.currentScanningPackage,
    required this.isScanning,
    required this.isCleaning,
    required this.scanningPrefixText,
  });

  final String totalSizeText;
  final String sizeUnit;
  final String currentScanningPackage;
  final bool isScanning;
  final bool isCleaning;
  final String scanningPrefixText;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth =
            constraints.maxWidth.isFinite ? constraints.maxWidth : 360.0;
        final circleSize = availableWidth.clamp(240.0, 360.0);
        final borderSize = circleSize * 0.76;

        return SizedBox(
          width: circleSize,
          height: circleSize,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CleanerCircleBorder(
                size: borderSize,
                isActive: isScanning || isCleaning,
              ),
              ConstrainedBox(
                constraints: BoxConstraints(maxWidth: borderSize * 0.74),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CleanerSizeIndicator(
                      sizeText: totalSizeText,
                      unitText: sizeUnit,
                    ),
                    const SizedBox(height: 12),
                    CleanerCurrentScanLabel(
                      label: currentScanningPackage,
                      isScanning: isScanning,
                      scanningPrefixText: scanningPrefixText,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class CleanerCircleGlow extends StatelessWidget {
  const CleanerCircleGlow({
    super.key,
    required this.size,
    required this.isActive,
  });

  final double size;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final glow = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          center: const Alignment(0.5, 0.5),
          radius: 0.72,
          colors: <Color>[
            theme.cleanerGlow,
            theme.cleanerGlow.withValues(alpha: 0.08),
            theme.cleanerGlow.withValues(alpha: 0),
          ],
        ),
      ),
    );

    if (!isActive) {
      return glow.animate().fadeIn(duration: 280.ms);
    }

    return glow
        .animate(onPlay: (controller) => controller.repeat(reverse: true))
        .scale(
          begin: const Offset(0.96, 0.96),
          end: const Offset(1.04, 1.04),
          duration: 1500.ms,
          curve: Curves.easeInOut,
        )
        .fade(begin: 0.62, end: 1, duration: 1500.ms, curve: Curves.easeInOut);
  }
}

class CleanerCircleBorder extends StatelessWidget {
  const CleanerCircleBorder({
    super.key,
    required this.size,
    required this.isActive,
  });

  final double size;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final circle = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: theme.cleanerSurface,
        shape: BoxShape.circle,
        border: Border.all(width: 2, color: theme.cleanerAccent),
        boxShadow: [
          BoxShadow(
            color: theme.cleanerGlow.withValues(alpha: 0.16),
            blurRadius: 28,
            spreadRadius: 2,
          ),
        ],
      ),
    );

    if (!isActive) {
      return circle;
    }

    return circle
        .animate(onPlay: (controller) => controller.repeat())
        .shimmer(
          duration: 1800.ms,
          color: theme.cleanerAccent.withValues(alpha: 0.20),
        );
  }
}

class CleanerSizeIndicator extends StatelessWidget {
  const CleanerSizeIndicator({
    super.key,
    required this.sizeText,
    required this.unitText,
  });

  final String sizeText;
  final String unitText;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AnimatedSwitcher(
      duration: 340.ms,
      switchInCurve: Curves.easeOutBack,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (child, animation) {
        return FadeTransition(
          opacity: animation,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.92, end: 1).animate(animation),
            child: child,
          ),
        );
      },
      child: Row(
        key: ValueKey('$sizeText-$unitText'),
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Flexible(
            child: Text(
              sizeText,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.displaySmall?.copyWith(
                color: theme.cleanerPrimaryText,
                fontWeight: FontWeight.w700,
                letterSpacing: -3.2,
                height: 1,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 10, left: 6),
            child: Text(
              unitText,
              style: theme.textTheme.labelLarge?.copyWith(
                color: theme.cleanerAccent,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class CleanerCurrentScanLabel extends StatelessWidget {
  const CleanerCurrentScanLabel({
    super.key,
    required this.label,
    required this.isScanning,
    required this.scanningPrefixText,
  });

  final String label;
  final bool isScanning;
  final String scanningPrefixText;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AnimatedSwitcher(
      duration: 340.ms,
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (child, animation) {
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.28),
              end: Offset.zero,
            ).animate(animation),
            child: child,
          ),
        );
      },
      child:
          isScanning
              ? RichText(
                    key: ValueKey(label),
                    textAlign: TextAlign.center,
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: '$scanningPrefixText ',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.cleanerAccent,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.18,
                          ),
                        ),
                        TextSpan(
                          text: label,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.cleanerSecondaryText,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.38,
                          ),
                        ),
                      ],
                    ),
                  )
                  .animate(key: ValueKey('scan-$label'))
                  .fadeIn(duration: 240.ms)
                  .slideY(
                    begin: 0.24,
                    end: 0,
                    duration: 240.ms,
                    curve: Curves.easeOutCubic,
                  )
              : Text(
                    label,
                    key: ValueKey(label),
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.cleanerAccent,
                      fontWeight: FontWeight.w700,
                    ),
                  )
                  .animate()
                  .fadeIn(duration: 280.ms)
                  .scale(
                    begin: const Offset(0.96, 0.96),
                    end: const Offset(1, 1),
                    duration: 280.ms,
                    curve: Curves.easeOutBack,
                  ),
    );
  }
}

class CleanerScanStatusList extends StatelessWidget {
  const CleanerScanStatusList({super.key, required this.scanItems});

  final List<CleanerScanItem> scanItems;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (int index = 0; index < scanItems.length; index++)
          CleanerScanStatusItem(
            item: scanItems[index],
            showDivider: index != scanItems.length - 1,
            animationIndex: index,
          ),
      ],
    );
  }
}

class CleanerScanStatusItem extends StatelessWidget {
  const CleanerScanStatusItem({
    super.key,
    required this.item,
    required this.showDivider,
    required this.animationIndex,
  });

  final CleanerScanItem item;
  final bool showDivider;
  final int animationIndex;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provider = context.read<TemizliksayfasiProvider>();
    final sizeLabel =
        item.foundSizeBytes > 0
            ? provider.formatBytes(item.foundSizeBytes)
            : null;

    return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            border:
                showDivider
                    ? Border(
                      bottom: BorderSide(width: 1, color: theme.cleanerDivider),
                    )
                    : null,
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color:
                            item.status == CleanerScanStatus.pending
                                ? theme.cleanerSecondaryText
                                : theme.cleanerPrimaryText,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (sizeLabel != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        sizeLabel,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.cleanerSecondaryText,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 12),
              CleanerScanStatusIcon(status: item.status),
            ],
          ),
        )
        .animate()
        .fadeIn(duration: 340.ms, delay: (80 * animationIndex).ms)
        .slideX(
          begin: -0.04,
          end: 0,
          duration: 340.ms,
          delay: (80 * animationIndex).ms,
          curve: Curves.easeOutCubic,
        );
  }
}

class CleanerScanStatusIcon extends StatelessWidget {
  const CleanerScanStatusIcon({super.key, required this.status});

  final CleanerScanStatus status;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: 320.ms,
      switchInCurve: Curves.easeOutBack,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (child, animation) {
        return FadeTransition(
          opacity: animation,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.55, end: 1).animate(animation),
            child: child,
          ),
        );
      },
      child: _buildIconByStatus(context),
    );
  }

  Widget _buildIconByStatus(BuildContext context) {
    final theme = Theme.of(context);
    switch (status) {
      case CleanerScanStatus.pending:
        return Container(
              key: const ValueKey('pending'),
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  width: 2,
                  color: theme.cleanerSecondaryText.withValues(alpha: 0.26),
                ),
              ),
            )
            .animate()
            .fadeIn(duration: 220.ms)
            .scale(
              begin: const Offset(0.86, 0.86),
              end: const Offset(1, 1),
              duration: 220.ms,
            );
      case CleanerScanStatus.scanning:
        return SizedBox(
              key: const ValueKey('scanning'),
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2.2,
                color: theme.cleanerAccent,
              ),
            )
            .animate(onPlay: (controller) => controller.repeat(reverse: true))
            .scale(
              begin: const Offset(0.92, 0.92),
              end: const Offset(1.08, 1.08),
              duration: 900.ms,
              curve: Curves.easeInOut,
            );
      case CleanerScanStatus.completed:
        return Icon(
              Icons.check_rounded,
              key: const ValueKey('completed'),
              color: theme.cleanerAccent,
              size: 28,
            )
            .animate()
            .fadeIn(duration: 220.ms)
            .scale(
              begin: const Offset(0.2, 0.2),
              end: const Offset(1, 1),
              duration: 420.ms,
              curve: Curves.elasticOut,
            )
            .shimmer(
              delay: 120.ms,
              duration: 650.ms,
              color: theme.cleanerPrimaryText.withValues(alpha: 0.32),
            );
      case CleanerScanStatus.failed:
        return Icon(
          Icons.error_outline_rounded,
          key: const ValueKey('failed'),
          color: theme.cleanerError,
          size: 26,
        );
    }
  }
}

class CleanerBottomActionBar extends StatelessWidget {
  const CleanerBottomActionBar({
    super.key,
    required this.child,
    required this.bottomPadding,
  });

  final Widget child;
  final double bottomPadding;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: <Color>[
            theme.cleanerSurface,
            theme.cleanerSurface,
            theme.cleanerSurface.withValues(alpha: 0),
          ],
        ),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(24, 24, 24, 24 + bottomPadding),
        child: child,
      ),
    );
  }
}

class CleanerActionButton extends StatelessWidget {
  const CleanerActionButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isEnabled = true,
  });

  final String text;
  final VoidCallback? onPressed;
  final bool isEnabled;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final canPress = isEnabled && onPressed != null;

    return SizedBox(
          width: double.infinity,
          height: 62,
          child: Material(
            color:
                canPress
                    ? theme.primaryColor
                    : theme.primaryColor.withValues(alpha: 0.55),
            borderRadius: BorderRadius.circular(9999),
            child: InkWell(
              onTap: canPress ? onPressed : null,
              borderRadius: BorderRadius.circular(9999),
              child: Center(
                child: AnimatedSwitcher(
                  duration: 260.ms,
                  child: Text(
                        text,
                        key: ValueKey(text),
                        style: theme.textTheme.titleMedium?.copyWith(
                          color:
                              canPress
                                  ? theme.cleanerPrimaryText
                                  : theme.cleanerSecondaryText.withValues(
                                    alpha: 0.56,
                                  ),
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.32,
                        ),
                      )
                      .animate(key: ValueKey('button-$text'))
                      .fadeIn(duration: 220.ms)
                      .slideY(
                        begin: 0.18,
                        end: 0,
                        duration: 220.ms,
                        curve: Curves.easeOutCubic,
                      ),
                ),
              ),
            ),
          ),
        )
        .animate(
          onPlay: (controller) {
            if (canPress) {
              controller.repeat(reverse: true);
            }
          },
        )
        .scale(
          begin: const Offset(1, 1),
          end: const Offset(1.015, 1.015),
          duration: 1500.ms,
          curve: Curves.easeInOut,
        );
  }
}

class CleanerInfoCard extends StatelessWidget {
  const CleanerInfoCard({super.key, required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      color: theme.scaffoldBackgroundColor,
      shape: Border.all(
        width: 1,
        color: theme.primaryColor.withValues(alpha: 0.8),
      ),

      child: Padding(
        padding: const EdgeInsets.all(16),
        child: SizedBox(
          width: 350,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.cleanerPrimaryText,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              child,
            ],
          ),
        ),
      ),
    );
  }
}

class CleanerIssueCard extends StatelessWidget {
  const CleanerIssueCard({
    super.key,
    required this.title,
    required this.issues,
  });

  final String title;
  final List<CleaningIssue> issues;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      color: theme.cardColor,
      child: ExpansionTile(
        title: Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            color: theme.cleanerPrimaryText,
            fontWeight: FontWeight.w700,
          ),
        ),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: issues
            .map(
              (issue) => Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _basename(issue.path),
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: theme.cleanerPrimaryText,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      issue.path,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.cleanerSecondaryText,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      issue.message,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.cleanerError,
                      ),
                    ),
                  ],
                ),
              ),
            )
            .toList(growable: false),
      ),
    );
  }

  String _basename(String value) {
    final segments = value.split(RegExp(r'[\\/]'));
    return segments.isEmpty ? value : segments.last;
  }
}

class _MetricRow extends StatelessWidget {
  const _MetricRow({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: Theme.of(
          context,
        ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
      ),
    );
  }
}
