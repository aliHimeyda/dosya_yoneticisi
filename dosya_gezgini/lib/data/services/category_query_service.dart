import 'dart:math' as math;

import 'package:dosya_gezgini/data/models/category_page_result.dart';
import 'package:dosya_gezgini/data/repositories/file_index_repository.dart';

class CategoryQueryService {
  CategoryQueryService(this._fileIndexRepository);

  final FileIndexRepository _fileIndexRepository;

  Future<CategoryPageResult> queryCategory({
    required String categoryId,
    required int offset,
    required int limit,
  }) async {
    final allItems = await _fileIndexRepository.readAllIndexedEntries();
    final categoryItems =
        allItems
            .where((item) => !item.isDirectory && item.category == categoryId)
            .toList()
          ..sort(
            (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
          );

    final safeOffset = math.min(offset, categoryItems.length);
    final endIndex = math.min(safeOffset + limit, categoryItems.length);

    return CategoryPageResult(
      items: categoryItems.sublist(safeOffset, endIndex),
      totalCount: categoryItems.length,
      nextOffset: endIndex,
      hasMore: endIndex < categoryItems.length,
    );
  }
}
