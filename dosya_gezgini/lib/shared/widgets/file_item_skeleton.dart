import 'package:dosya_gezgini/shared/widgets/app_skeleton.dart';
import 'package:flutter/material.dart';

class FileItemSkeleton extends StatelessWidget {
  const FileItemSkeleton({
    super.key,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
  });

  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: const [
          AppSkeleton(
            width: 40,
            height: 40,
            borderRadius: BorderRadius.all(Radius.circular(10)),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppSkeleton(height: 14, width: 160),
                SizedBox(height: 8),
                AppSkeleton(height: 12, width: 120),
              ],
            ),
          ),
          SizedBox(width: 12),
          AppSkeleton(
            width: 18,
            height: 18,
            borderRadius: BorderRadius.all(Radius.circular(12)),
          ),
        ],
      ),
    );
  }
}
