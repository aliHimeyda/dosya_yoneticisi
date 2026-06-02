import 'package:dosya_gezgini/data/constants/hive_box_names.dart';
import 'package:dosya_gezgini/data/models/saved_item_model.dart';
import 'package:dosya_gezgini/data/services/hive_service.dart';

class SavedRepository {
  SavedRepository(this._hiveService);

  final HiveService _hiveService;

  Future<void> upsertAll(Iterable<SavedItemModel> items) async {
    final payload = <String, Map<String, dynamic>>{
      for (final item in items) item.path: item.toMap(),
    };
    if (payload.isEmpty) {
      return;
    }

    final box = await _hiveService.openMapBox(HiveBoxNames.savedItems);
    await box.putAll(payload);
  }

  Future<List<SavedItemModel>> readAll() async {
    final box = await _hiveService.openMapBox(HiveBoxNames.savedItems);
    final items = box.values
        .whereType<Map<dynamic, dynamic>>()
        .map(SavedItemModel.fromMap)
        .toList(growable: false)
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return List<SavedItemModel>.unmodifiable(items);
  }

  Future<void> removePaths(Iterable<String> paths) async {
    final uniquePaths = paths.toSet();
    if (uniquePaths.isEmpty) {
      return;
    }

    final box = await _hiveService.openMapBox(HiveBoxNames.savedItems);
    await box.deleteAll(uniquePaths);
  }
}
