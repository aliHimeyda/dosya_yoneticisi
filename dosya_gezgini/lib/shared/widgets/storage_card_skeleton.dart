import 'package:dosya_gezgini/shared/widgets/app_skeleton.dart';
import 'package:flutter/material.dart';

class StorageCardSkeleton extends StatelessWidget {
  const StorageCardSkeleton({super.key, this.height = 50});

  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          width: 1,
          color: Theme.of(context).dividerColor.withValues(alpha: 0.3),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppSkeleton(height: 10, width: double.infinity),
          SizedBox(height: 8),
          AppSkeleton(height: 12, width: 120),
        ],
      ),
    );
  }
}
