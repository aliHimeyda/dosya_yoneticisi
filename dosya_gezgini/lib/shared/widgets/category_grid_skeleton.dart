import 'package:dosya_gezgini/shared/widgets/app_skeleton.dart';
import 'package:flutter/material.dart';

class CategoryGridSkeleton extends StatelessWidget {
  const CategoryGridSkeleton({super.key, this.itemCount = 10});

  final int itemCount;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: 8,
        runSpacing: 12,
        children: List.generate(
          itemCount,
          (_) => const _CategoryCardSkeleton(),
        ),
      ),
    );
  }
}

class _CategoryCardSkeleton extends StatelessWidget {
  const _CategoryCardSkeleton();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: 80,
      height: 100,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          AppSkeleton(
            width: 50,
            height: 50,
            borderRadius: BorderRadius.all(Radius.circular(14)),
          ),
          AppSkeleton(height: 12, width: 56),
        ],
      ),
    );
  }
}
