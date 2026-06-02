import 'package:dosya_gezgini/data/constants/file_category_constants.dart';
import 'package:dosya_gezgini/data/models/category_page_result.dart';
import 'package:dosya_gezgini/data/services/category_query_service.dart';
import 'package:dosya_gezgini/data/services/file_index_service.dart';

class CategoryRepository {
  CategoryRepository({
    required FileIndexService fileIndexService,
    required CategoryQueryService categoryQueryService,
  }) : _fileIndexService = fileIndexService,
       _categoryQueryService = categoryQueryService;

  final FileIndexService _fileIndexService;
  final CategoryQueryService _categoryQueryService;

  Future<IndexReadiness> ensureCategoryReady({
    required String rootPath,
    required String categoryPath,
    bool forceRefresh = false,
  }) async {
    _resolveCategoryId(categoryPath);
    return _fileIndexService.ensureReady(
      rootPath: rootPath,
      forceRefresh: forceRefresh,
    );
  }

  Future<CategoryPageResult> getCategoryPage({
    required String categoryPath,
    int offset = 0,
    int limit = 100,
  }) async {
    final categoryId = _resolveCategoryId(categoryPath);
    return _categoryQueryService.queryCategory(
      categoryId: categoryId,
      offset: offset,
      limit: limit,
    );
  }

  Future<void> refreshIndex({required String rootPath}) {
    return _fileIndexService.refreshIndex(rootPath: rootPath);
  }

  String _resolveCategoryId(String categoryPath) {
    final categoryId = FileCategoryConstants.categoryIdFromVirtualPath(
      categoryPath,
    );
    if (categoryId == null) {
      throw StateError('unknown_category_path');
    }

    return categoryId;
  }
}
