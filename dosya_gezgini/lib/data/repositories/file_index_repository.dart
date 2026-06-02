import 'package:dosya_gezgini/data/constants/hive_box_names.dart';
import 'package:dosya_gezgini/data/models/file_index_metadata.dart';
import 'package:dosya_gezgini/data/models/indexed_file_model.dart';
import 'package:dosya_gezgini/data/services/hive_service.dart';

class FileIndexRepository {
  FileIndexRepository(this._hiveService);

  static const String _metadataKey = 'active_file_index';

  final HiveService _hiveService;
  List<IndexedFileModel>? _memoryCache;

  Future<void> clearDraftIndex() async {
    final box = await _hiveService.openMapBox(HiveBoxNames.fileIndexDraft);
    await box.clear();
  }

  Future<void> appendDraftEntries(List<IndexedFileModel> entries) async {
    if (entries.isEmpty) {
      return;
    }

    final box = await _hiveService.openMapBox(HiveBoxNames.fileIndexDraft);
    final payload = <String, Map<String, dynamic>>{
      for (final entry in entries) entry.path: entry.toMap(),
    };
    await box.putAll(payload);
  }

  Future<void> activateDraftIndex({
    required String rootPath,
    required DateTime indexedAt,
    required int itemCount,
    required int schemaVersion,
  }) async {
    final activeBox = await _hiveService.openMapBox(HiveBoxNames.fileIndex);
    final draftBox = await _hiveService.openMapBox(HiveBoxNames.fileIndexDraft);
    final metadataBox = await _hiveService.openMapBox(
      HiveBoxNames.fileIndexMetadata,
    );

    await activeBox.clear();
    for (final key in draftBox.keys.cast<String>()) {
      final value = draftBox.get(key);
      if (value == null) {
        continue;
      }

      await activeBox.put(key, Map<dynamic, dynamic>.from(value));
    }
    await draftBox.clear();
    await metadataBox.put(
      _metadataKey,
      FileIndexMetadata(
        rootPath: rootPath,
        indexedAt: indexedAt,
        itemCount: itemCount,
        schemaVersion: schemaVersion,
      ).toMap(),
    );
    _memoryCache = null;
  }

  Future<List<IndexedFileModel>> readAllIndexedEntries() async {
    final cachedEntries = _memoryCache;
    if (cachedEntries != null) {
      return List<IndexedFileModel>.unmodifiable(cachedEntries);
    }

    final box = await _hiveService.openMapBox(HiveBoxNames.fileIndex);
    final entries = box.values
        .whereType<Map<dynamic, dynamic>>()
        .map(IndexedFileModel.fromMap)
        .toList(growable: false);
    _memoryCache = entries;
    return List<IndexedFileModel>.unmodifiable(entries);
  }

  Future<List<IndexedFileModel>> readAllIndexedFiles() {
    return readAllIndexedEntries();
  }

  Future<FileIndexMetadata?> readMetadata() async {
    final box = await _hiveService.openMapBox(HiveBoxNames.fileIndexMetadata);
    final rawMetadata = box.get(_metadataKey);
    if (rawMetadata == null) {
      return null;
    }

    return FileIndexMetadata.fromMap(rawMetadata);
  }

  Future<bool> hasActiveIndex() async {
    final box = await _hiveService.openMapBox(HiveBoxNames.fileIndex);
    return box.isNotEmpty;
  }
}
