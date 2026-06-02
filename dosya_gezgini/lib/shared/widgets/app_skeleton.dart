import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class AppSkeleton extends StatelessWidget {
  const AppSkeleton({
    super.key,
    required this.height,
    this.width = double.infinity,
    this.margin,
    this.borderRadius = const BorderRadius.all(Radius.circular(12)),
  });

  final double height;
  final double width;
  final EdgeInsetsGeometry? margin;
  final BorderRadius borderRadius;

  @override
  Widget build(BuildContext context) {
    final baseColor = Theme.of(
      context,
    ).colorScheme.onSurface.withValues(alpha: 0.08);

    return Animate(
      onPlay: (controller) => controller.repeat(reverse: true),
      effects: [FadeEffect(begin: 0.35, end: 0.85, duration: 700.ms)],
      child: Container(
        width: width,
        height: height,
        margin: margin,
        decoration: BoxDecoration(color: baseColor, borderRadius: borderRadius),
      ),
    );
  }
}
