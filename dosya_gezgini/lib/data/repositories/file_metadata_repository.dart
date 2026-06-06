import 'package:dosya_gezgini/data/constants/hive_box_names.dart';
import 'package:dosya_gezgini/data/models/file_metadata_model.dart';
import 'package:dosya_gezgini/data/services/hive_service.dart';

class FileMetadataRepository {
  FileMetadataRepository(this._hiveService);

  final HiveService _hiveService;

  Future<FileMetadataModel?> getByPath(String path) async {
    final box = await _hiveService.openMapBox(HiveBoxNames.fileMetadataCache);
    final rawValue = box.get(path);
    if (rawValue == null) {
      return null;
    }

    return FileMetadataModel.fromMap(rawValue);
  }

  Future<List<FileMetadataModel>> getManyByPaths(List<String> paths) async {
    if (paths.isEmpty) {
      return const <FileMetadataModel>[];
    }

    final box = await _hiveService.openMapBox(HiveBoxNames.fileMetadataCache);
    final items = <FileMetadataModel>[];
    for (final path in paths) {
      final rawValue = box.get(path);
      if (rawValue == null) {
        continue;
      }

      items.add(FileMetadataModel.fromMap(rawValue));
    }
    return List<FileMetadataModel>.unmodifiable(items);
  }

  Future<List<FileMetadataModel>> readAll() async {
    final box = await _hiveService.openMapBox(HiveBoxNames.fileMetadataCache);
    final items = box.values
        .whereType<Map<dynamic, dynamic>>()
        .map(FileMetadataModel.fromMap)
        .toList(growable: false)
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return List<FileMetadataModel>.unmodifiable(items);
  }

  Future<void> upsert(FileMetadataModel model) async {
    final box = await _hiveService.openMapBox(HiveBoxNames.fileMetadataCache);
    await box.put(model.path, model.toMap());
  }

  Future<void> deleteByPath(String path) async {
    final box = await _hiveService.openMapBox(HiveBoxNames.fileMetadataCache);
    await box.delete(path);
  }

  Future<void> deleteManyByPaths(List<String> paths) async {
    final uniquePaths = paths.toSet();
    if (uniquePaths.isEmpty) {
      return;
    }

    final box = await _hiveService.openMapBox(HiveBoxNames.fileMetadataCache);
    await box.deleteAll(uniquePaths);
  }

  Future<bool> exists(String path) async {
    final box = await _hiveService.openMapBox(HiveBoxNames.fileMetadataCache);
    return box.containsKey(path);
  }

  Future<void> clear() async {
    final box = await _hiveService.openMapBox(HiveBoxNames.fileMetadataCache);
    await box.clear();
  }
}
