import 'package:dosya_gezgini/data/constants/hive_box_names.dart';
import 'package:dosya_gezgini/data/models/thumbnail_cache_model.dart';
import 'package:dosya_gezgini/data/services/hive_service.dart';

class ThumbnailCacheRepository {
  ThumbnailCacheRepository(this._hiveService);

  final HiveService _hiveService;

  Future<ThumbnailCacheModel?> read(String sourcePath) async {
    final box = await _hiveService.openMapBox(
      HiveBoxNames.thumbnailCacheMetadata,
    );
    final rawValue = box.get(sourcePath);
    if (rawValue == null) {
      return null;
    }

    return ThumbnailCacheModel.fromMap(rawValue);
  }

  Future<void> upsert(ThumbnailCacheModel item) async {
    final box = await _hiveService.openMapBox(
      HiveBoxNames.thumbnailCacheMetadata,
    );
    await box.put(item.sourcePath, item.toMap());
  }

  Future<List<ThumbnailCacheModel>> readAll() async {
    final box = await _hiveService.openMapBox(
      HiveBoxNames.thumbnailCacheMetadata,
    );
    return box.values
        .map(ThumbnailCacheModel.fromMap)
        .where((item) => item.sourcePath.isNotEmpty)
        .toList(growable: false);
  }

  Future<void> removePaths(Iterable<String> sourcePaths) async {
    final uniquePaths = sourcePaths.toSet();
    if (uniquePaths.isEmpty) {
      return;
    }

    final box = await _hiveService.openMapBox(
      HiveBoxNames.thumbnailCacheMetadata,
    );
    await box.deleteAll(uniquePaths);
  }
}
