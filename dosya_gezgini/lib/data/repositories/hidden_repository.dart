import 'package:dosya_gezgini/data/constants/hive_box_names.dart';
import 'package:dosya_gezgini/data/models/hidden_item_model.dart';
import 'package:dosya_gezgini/data/services/hive_service.dart';

class HiddenRepository {
  HiddenRepository(this._hiveService);

  final HiveService _hiveService;

  Future<void> upsertAll(Iterable<HiddenItemModel> items) async {
    final payload = <String, Map<String, dynamic>>{
      for (final item in items) item.path: item.toMap(),
    };
    if (payload.isEmpty) {
      return;
    }

    final box = await _hiveService.openMapBox(HiveBoxNames.hiddenItems);
    await box.putAll(payload);
  }

  Future<List<HiddenItemModel>> readAll() async {
    final box = await _hiveService.openMapBox(HiveBoxNames.hiddenItems);
    final items = box.values
        .whereType<Map<dynamic, dynamic>>()
        .map(HiddenItemModel.fromMap)
        .toList(growable: false)
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return List<HiddenItemModel>.unmodifiable(items);
  }

  Future<void> removePaths(Iterable<String> paths) async {
    final uniquePaths = paths.toSet();
    if (uniquePaths.isEmpty) {
      return;
    }

    final box = await _hiveService.openMapBox(HiveBoxNames.hiddenItems);
    await box.deleteAll(uniquePaths);
  }
}
