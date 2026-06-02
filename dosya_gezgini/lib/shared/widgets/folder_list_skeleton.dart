import 'package:dosya_gezgini/shared/widgets/file_item_skeleton.dart';
import 'package:flutter/material.dart';

class FolderListSkeleton extends StatelessWidget {
  const FolderListSkeleton({
    super.key,
    this.itemCount = 8,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    this.shrinkWrap = false,
    this.physics = const AlwaysScrollableScrollPhysics(),
  });

  final int itemCount;
  final EdgeInsetsGeometry padding;
  final bool shrinkWrap;
  final ScrollPhysics physics;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      physics: physics,
      padding: padding,
      shrinkWrap: shrinkWrap,
      itemCount: itemCount,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder:
          (context, index) => const FileItemSkeleton(padding: EdgeInsets.zero),
    );
  }
}
