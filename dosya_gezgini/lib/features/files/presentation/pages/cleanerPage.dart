import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class Temizliksayfasi extends StatelessWidget {
  const Temizliksayfasi({super.key});

  @override
  Widget build(BuildContext context) {
    return const CleanerPage();
  }
}

class CleanerPage extends StatefulWidget {
  const CleanerPage({super.key, this.onSettingsPressed, this.onStopPressed});

  final VoidCallback? onSettingsPressed;
  final VoidCallback? onStopPressed;

  @override
  State<CleanerPage> createState() => _CleanerPageState();
}

class _CleanerPageState extends State<CleanerPage> {
  static const String _pageTitle = 'Temizleyici';
  static const String _stopButtonText = 'Durdur';
  static const String _cleanButtonText = 'Temizle';

  final List<String> _mockScanningPackages = const [
    'com.spotify.music',
    'com.canva.editor',
    'com.instagram.android',
    'com.whatsapp',
    'com.google.android.youtube',
  ];

  late List<CleanerScanItem> _scanItems;

  Timer? _scanStepTimer;
  Timer? _packageNameTimer;

  int _activeScanIndex = 0;
  int _activePackageIndex = 0;

  double _totalCleanableSize = 0.86;
  bool _isScanning = true;

  @override
  void initState() {
    super.initState();

    _scanItems = const [
      CleanerScanItem(
        title: 'Önbellek dosyaları',
        status: CleanerScanStatus.scanning,
      ),
      CleanerScanItem(
        title: 'Kullanılmayan dosyalar',
        status: CleanerScanStatus.pending,
      ),
      CleanerScanItem(title: 'Paketler', status: CleanerScanStatus.pending),
      CleanerScanItem(
        title: 'Artık dosyalar',
        status: CleanerScanStatus.pending,
      ),
      CleanerScanItem(title: 'Bellek', status: CleanerScanStatus.pending),
    ];

    _startDemoScanningAnimation();
  }

  @override
  void dispose() {
    _scanStepTimer?.cancel();
    _packageNameTimer?.cancel();
    super.dispose();
  }

  void _startDemoScanningAnimation() {
    _packageNameTimer = Timer.periodic(900.ms, (_) {
      if (!_isScanning || !mounted) return;

      setState(() {
        _activePackageIndex =
            (_activePackageIndex + 1) % _mockScanningPackages.length;
      });
    });

    _scanStepTimer = Timer.periodic(1600.ms, (_) {
      if (!_isScanning || !mounted) return;

      setState(() {
        _completeCurrentScanItem();
      });
    });
  }

  void _completeCurrentScanItem() {
    if (_activeScanIndex >= _scanItems.length) {
      _finishScanning();
      return;
    }

    _scanItems[_activeScanIndex] = _scanItems[_activeScanIndex].copyWith(
      status: CleanerScanStatus.completed,
    );

    _totalCleanableSize += 0.48;

    final int nextIndex = _activeScanIndex + 1;

    if (nextIndex >= _scanItems.length) {
      _finishScanning();
      return;
    }

    _scanItems[nextIndex] = _scanItems[nextIndex].copyWith(
      status: CleanerScanStatus.scanning,
    );

    _activeScanIndex = nextIndex;
  }

  void _finishScanning() {
    _isScanning = false;
    _scanStepTimer?.cancel();
    _packageNameTimer?.cancel();
  }

  void _handleActionPressed() {
    if (_isScanning) {
      setState(() {
        _isScanning = false;
      });

      _scanStepTimer?.cancel();
      _packageNameTimer?.cancel();

      widget.onStopPressed?.call();
      return;
    }

    // Buraya gerçek temizleme işlemini bağlayabilirsin.
    // Örnek:
    // context.read<CleaningController>().cleanSelectedItems();
  }

  String get _totalSizeText {
    return _totalCleanableSize.toStringAsFixed(2).replaceAll('.', ',');
  }

  String get _currentScanningPackage {
    return _mockScanningPackages[_activePackageIndex];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CleanerColors.background,
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 160),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CleanerHeader(
                        title: _pageTitle,
                        onBackPressed: () => Navigator.of(context).maybePop(),
                        onSettingsPressed: widget.onSettingsPressed,
                      )
                      .animate()
                      .fadeIn(duration: 450.ms, curve: Curves.easeOut)
                      .slideY(
                        begin: -0.10,
                        end: 0,
                        duration: 450.ms,
                        curve: Curves.easeOutCubic,
                      ),

                  const SizedBox(height: 34),

                  Center(
                        child: CleanerScanCircle(
                          totalSizeText: _totalSizeText,
                          sizeUnit: 'GB',
                          currentScanningPackage: _currentScanningPackage,
                          isScanning: _isScanning,
                        ),
                      )
                      .animate()
                      .fadeIn(duration: 550.ms, delay: 100.ms)
                      .scale(
                        begin: const Offset(0.92, 0.92),
                        end: const Offset(1.0, 1.0),
                        duration: 550.ms,
                        curve: Curves.easeOutBack,
                      ),

                  const SizedBox(height: 64),

                  CleanerScanStatusList(scanItems: _scanItems)
                      .animate()
                      .fadeIn(duration: 500.ms, delay: 220.ms)
                      .slideY(
                        begin: 0.08,
                        end: 0,
                        duration: 500.ms,
                        curve: Curves.easeOutCubic,
                      ),
                ],
              ),
            ),

            CleanerBottomActionBar(
                  child: CleanerActionButton(
                    text: _isScanning ? _stopButtonText : _cleanButtonText,
                    onPressed: _handleActionPressed,
                  ),
                )
                .animate()
                .fadeIn(duration: 450.ms, delay: 300.ms)
                .slideY(
                  begin: 0.30,
                  end: 0,
                  duration: 450.ms,
                  curve: Curves.easeOutCubic,
                ),
          ],
        ),
      ),
    );
  }
}

class CleanerHeader extends StatelessWidget {
  const CleanerHeader({
    super.key,
    required this.title,
    required this.onBackPressed,
    this.onSettingsPressed,
  });

  final String title;
  final VoidCallback onBackPressed;
  final VoidCallback? onSettingsPressed;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            CleanerIconButton(
              icon: Icons.arrow_back_rounded,
              onPressed: onBackPressed,
            ),
            const Spacer(),
            CleanerIconButton(
              icon: Icons.settings_outlined,
              onPressed: onSettingsPressed,
            ),
          ],
        ),
        const SizedBox(height: 34),
        Text(
          title,
          style: const TextStyle(
            color: CleanerColors.primaryText,
            fontSize: 38,
            fontFamily: 'Hanken Grotesk',
            fontWeight: FontWeight.w600,
            height: 1.25,
            letterSpacing: -0.95,
          ),
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
    return IconButton(
      onPressed: onPressed,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
      icon: Icon(icon, color: CleanerColors.primaryText, size: 28),
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
  });

  final String totalSizeText;
  final String sizeUnit;
  final String currentScanningPackage;
  final bool isScanning;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 353,
      height: 353,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CleanerCircleGlow(isScanning: isScanning),

          CleanerCircleBorder(isScanning: isScanning),

          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CleanerSizeIndicator(sizeText: totalSizeText, unitText: sizeUnit),

              const SizedBox(height: 10),

              CleanerCurrentScanLabel(
                packageName: currentScanningPackage,
                isScanning: isScanning,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class CleanerCircleGlow extends StatelessWidget {
  const CleanerCircleGlow({super.key, required this.isScanning});

  final bool isScanning;

  @override
  Widget build(BuildContext context) {
    final Widget glow = Container(
      width: 353,
      height: 353,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          center: Alignment(0.50, 0.50),
          radius: 0.71,
          colors: [Color(0x7FFFC4D2), Color(0x26FFC4D2), Color(0x00FFC4D2)],
        ),
      ),
    );

    if (!isScanning) {
      return glow.animate().fadeIn(duration: 300.ms);
    }

    return glow
        .animate(onPlay: (controller) => controller.repeat(reverse: true))
        .scale(
          begin: const Offset(0.96, 0.96),
          end: const Offset(1.04, 1.04),
          duration: 1500.ms,
          curve: Curves.easeInOut,
        )
        .fade(
          begin: 0.55,
          end: 1.0,
          duration: 1500.ms,
          curve: Curves.easeInOut,
        );
  }
}

class CleanerCircleBorder extends StatelessWidget {
  const CleanerCircleBorder({super.key, required this.isScanning});

  final bool isScanning;

  @override
  Widget build(BuildContext context) {
    final Widget circle = Container(
      width: 269,
      height: 269,
      decoration: BoxDecoration(
        color: CleanerColors.background,
        shape: BoxShape.circle,
        border: Border.all(width: 2, color: CleanerColors.accent),
        boxShadow: [
          BoxShadow(
            color: CleanerColors.accent.withOpacity(0.12),
            blurRadius: 28,
            spreadRadius: 2,
          ),
        ],
      ),
    );

    if (!isScanning) {
      return circle;
    }

    return circle
        .animate(onPlay: (controller) => controller.repeat())
        .shimmer(
          duration: 1800.ms,
          color: CleanerColors.accent.withOpacity(0.28),
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
    return AnimatedSwitcher(
      duration: 350.ms,
      switchInCurve: Curves.easeOutBack,
      switchOutCurve: Curves.easeIn,
      transitionBuilder: (child, animation) {
        return FadeTransition(
          opacity: animation,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.92, end: 1.0).animate(animation),
            child: child,
          ),
        );
      },
      child: Row(
        key: ValueKey(sizeText),
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            sizeText,
            style: const TextStyle(
              color: CleanerColors.primaryText,
              fontSize: 72,
              fontFamily: 'Hanken Grotesk',
              fontWeight: FontWeight.w700,
              height: 1.0,
              letterSpacing: -3.60,
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 12, left: 4),
            child: Text(
              unitText,
              style: const TextStyle(
                color: CleanerColors.accent,
                fontSize: 16,
                fontFamily: 'Hanken Grotesk',
                fontWeight: FontWeight.w500,
                height: 1.50,
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
    required this.packageName,
    required this.isScanning,
  });

  final String packageName;
  final bool isScanning;

  static const String _scanningPrefix = 'Taranıyor: ';
  static const String _completedText = 'Tarama tamamlandı';

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: 350.ms,
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (child, animation) {
        final Animation<Offset> offsetAnimation = Tween<Offset>(
          begin: const Offset(0, 0.35),
          end: Offset.zero,
        ).animate(animation);

        return FadeTransition(
          opacity: animation,
          child: SlideTransition(position: offsetAnimation, child: child),
        );
      },
      child:
          isScanning
              ? Opacity(
                key: ValueKey(packageName),
                opacity: 0.70,
                child: RichText(
                      textAlign: TextAlign.center,
                      text: TextSpan(
                        children: [
                          const TextSpan(
                            text: _scanningPrefix,
                            style: TextStyle(
                              color: CleanerColors.accent,
                              fontSize: 17,
                              fontFamily: 'Hanken Grotesk',
                              fontWeight: FontWeight.w400,
                              height: 1.41,
                              letterSpacing: 0.17,
                            ),
                          ),
                          TextSpan(
                            text: packageName,
                            style: const TextStyle(
                              color: CleanerColors.accent,
                              fontSize: 12,
                              fontFamily: 'Geist',
                              fontWeight: FontWeight.w500,
                              height: 1.33,
                              letterSpacing: 0.60,
                            ),
                          ),
                        ],
                      ),
                    )
                    .animate(key: ValueKey('scan-$packageName'))
                    .fadeIn(duration: 250.ms)
                    .slideY(
                      begin: 0.30,
                      end: 0,
                      duration: 250.ms,
                      curve: Curves.easeOutCubic,
                    ),
              )
              : const Text(
                    _completedText,
                    key: ValueKey(_completedText),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: CleanerColors.accent,
                      fontSize: 16,
                      fontFamily: 'Hanken Grotesk',
                      fontWeight: FontWeight.w500,
                      height: 1.40,
                    ),
                  )
                  .animate()
                  .fadeIn(duration: 300.ms)
                  .scale(
                    begin: const Offset(0.96, 0.96),
                    end: const Offset(1.0, 1.0),
                    duration: 300.ms,
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
    return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 24),
          decoration: BoxDecoration(
            border:
                showDivider
                    ? Border(
                      bottom: BorderSide(
                        width: 1,
                        color: Colors.white.withOpacity(0.05),
                      ),
                    )
                    : null,
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  item.title,
                  style: TextStyle(
                    color:
                        item.status == CleanerScanStatus.pending
                            ? CleanerColors.secondaryText.withOpacity(0.62)
                            : CleanerColors.primaryText,
                    fontSize: 20,
                    fontFamily: 'Hanken Grotesk',
                    fontWeight: FontWeight.w600,
                    height: 1.50,
                  ),
                ),
              ),
              CleanerScanStatusIcon(status: item.status),
            ],
          ),
        )
        .animate()
        .fadeIn(duration: 350.ms, delay: (80 * animationIndex).ms)
        .slideX(
          begin: -0.05,
          end: 0,
          duration: 350.ms,
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
            scale: Tween<double>(begin: 0.55, end: 1.0).animate(animation),
            child: child,
          ),
        );
      },
      child: _buildIconByStatus(status),
    );
  }

  Widget _buildIconByStatus(CleanerScanStatus status) {
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
                  color: CleanerColors.secondaryText.withOpacity(0.25),
                ),
              ),
            )
            .animate()
            .fadeIn(duration: 220.ms)
            .scale(
              begin: const Offset(0.85, 0.85),
              end: const Offset(1.0, 1.0),
              duration: 220.ms,
            );

      case CleanerScanStatus.scanning:
        return const SizedBox(
              key: ValueKey('scanning'),
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2.2,
                color: CleanerColors.accent,
              ),
            )
            .animate(onPlay: (controller) => controller.repeat())
            .rotate(begin: 0, end: 1, duration: 1000.ms)
            .scale(
              begin: const Offset(0.92, 0.92),
              end: const Offset(1.08, 1.08),
              duration: 900.ms,
              curve: Curves.easeInOut,
            );

      case CleanerScanStatus.completed:
        return const Icon(
              Icons.check_rounded,
              key: ValueKey('completed'),
              color: CleanerColors.accent,
              size: 28,
            )
            .animate()
            .fadeIn(duration: 220.ms)
            .scale(
              begin: const Offset(0.20, 0.20),
              end: const Offset(1.0, 1.0),
              duration: 420.ms,
              curve: Curves.elasticOut,
            )
            .shimmer(
              delay: 120.ms,
              duration: 650.ms,
              color: Colors.white.withOpacity(0.35),
            );
    }
  }
}

class CleanerBottomActionBar extends StatelessWidget {
  const CleanerBottomActionBar({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: Container(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment(0.50, 1.00),
            end: Alignment(0.50, 0.00),
            colors: [
              CleanerColors.background,
              CleanerColors.background,
              Color(0x000E0E0E),
            ],
          ),
        ),
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
    final bool canPress = isEnabled && onPressed != null;

    return SizedBox(
          width: double.infinity,
          height: 64,
          child: Material(
            color:
                canPress
                    ? CleanerColors.actionButtonBackground
                    : CleanerColors.actionButtonBackground.withOpacity(0.55),
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
                        style: TextStyle(
                          color: Colors.white.withOpacity(
                            canPress ? 1.0 : 0.45,
                          ),
                          fontSize: 17,
                          fontFamily: 'Hanken Grotesk',
                          fontWeight: FontWeight.w600,
                          height: 1.50,
                          letterSpacing: 0.43,
                        ),
                      )
                      .animate(key: ValueKey('button-$text'))
                      .fadeIn(duration: 220.ms)
                      .slideY(
                        begin: 0.20,
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
          begin: const Offset(1.0, 1.0),
          end: const Offset(1.015, 1.015),
          duration: 1600.ms,
          curve: Curves.easeInOut,
        );
  }
}

class CleanerScanItem {
  const CleanerScanItem({required this.title, required this.status});

  final String title;
  final CleanerScanStatus status;

  CleanerScanItem copyWith({String? title, CleanerScanStatus? status}) {
    return CleanerScanItem(
      title: title ?? this.title,
      status: status ?? this.status,
    );
  }
}

enum CleanerScanStatus { pending, scanning, completed }

class CleanerColors {
  const CleanerColors._();

  static const Color background = Color(0xFF0E0E0E);
  static const Color primaryText = Color(0xFFE5E2E1);
  static const Color secondaryText = Color(0xFFB8B4B2);
  static const Color accent = Color(0xFFFFC4D2);
  static const Color actionButtonBackground = Color(0xFF353534);
}
