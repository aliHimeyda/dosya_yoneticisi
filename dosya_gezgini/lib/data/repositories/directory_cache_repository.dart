import 'package:dosya_gezgini/data/constants/hive_box_names.dart';
import 'package:dosya_gezgini/data/models/directory_cache_model.dart';
import 'package:dosya_gezgini/data/services/hive_service.dart';

class DirectoryCacheRepository {
  DirectoryCacheRepository(this._hiveService);

  final HiveService _hiveService;

  Future<DirectoryCacheModel?> read(String path) async {
    final box = await _hiveService.openMapBox(HiveBoxNames.directoryCache);
    final rawValue = box.get(path);
    if (rawValue == null) {
      return null;
    }

    return DirectoryCacheModel.fromMap(rawValue);
  }

  Future<void> upsert(DirectoryCacheModel item) async {
    final box = await _hiveService.openMapBox(HiveBoxNames.directoryCache);
    await box.put(item.path, item.toMap());
  }

  Future<void> removePaths(Iterable<String> paths) async {
    final uniquePaths = paths.toSet();
    if (uniquePaths.isEmpty) {
      return;
    }

    final box = await _hiveService.openMapBox(HiveBoxNames.directoryCache);
    await box.deleteAll(uniquePaths);
  }
}
