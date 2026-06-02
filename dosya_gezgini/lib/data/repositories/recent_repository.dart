import 'package:dosya_gezgini/data/constants/hive_box_names.dart';
import 'package:dosya_gezgini/data/models/recent_item_model.dart';
import 'package:dosya_gezgini/data/services/hive_service.dart';

class RecentRepository {
  RecentRepository(this._hiveService, {this.maxItems = 100});

  final HiveService _hiveService;
  final int maxItems;

  Future<void> upsert(RecentItemModel item) async {
    final box = await _hiveService.openMapBox(HiveBoxNames.recentItems);
    await box.put(item.path, item.toMap());
    await _trimExcess(box);
  }

  Future<List<RecentItemModel>> readAll() async {
    final box = await _hiveService.openMapBox(HiveBoxNames.recentItems);
    final items = box.values
        .whereType<Map<dynamic, dynamic>>()
        .map(RecentItemModel.fromMap)
        .toList(growable: false)
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return List<RecentItemModel>.unmodifiable(items);
  }

  Future<void> removePaths(Iterable<String> paths) async {
    final uniquePaths = paths.toSet();
    if (uniquePaths.isEmpty) {
      return;
    }

    final box = await _hiveService.openMapBox(HiveBoxNames.recentItems);
    await box.deleteAll(uniquePaths);
  }

  Future<void> _trimExcess(dynamic box) async {
    if (box.length <= maxItems) {
      return;
    }

    final items = box.values
        .whereType<Map<dynamic, dynamic>>()
        .map(RecentItemModel.fromMap)
        .toList(growable: false)
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

    if (items.length <= maxItems) {
      return;
    }

    final overflowPaths = items
        .skip(maxItems)
        .map((item) => item.path)
        .toList(growable: false);
    await box.deleteAll(overflowPaths);
  }
}
