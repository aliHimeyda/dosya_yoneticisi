import 'package:dosya_gezgini/data/constants/hive_box_names.dart';
import 'package:dosya_gezgini/data/models/folder_count_model.dart';
import 'package:dosya_gezgini/data/services/hive_service.dart';

class FolderCountRepository {
  FolderCountRepository(this._hiveService);

  final HiveService _hiveService;

  Future<FolderCountModel?> read(String path) async {
    final box = await _hiveService.openMapBox(HiveBoxNames.folderCountCache);
    final rawValue = box.get(path);
    if (rawValue == null) {
      return null;
    }

    return FolderCountModel.fromMap(rawValue);
  }

  Future<void> upsert(FolderCountModel item) async {
    final box = await _hiveService.openMapBox(HiveBoxNames.folderCountCache);
    await box.put(item.path, item.toMap());
  }

  Future<void> removePaths(Iterable<String> paths) async {
    final uniquePaths = paths.toSet();
    if (uniquePaths.isEmpty) {
      return;
    }

    final box = await _hiveService.openMapBox(HiveBoxNames.folderCountCache);
    await box.deleteAll(uniquePaths);
  }
}
