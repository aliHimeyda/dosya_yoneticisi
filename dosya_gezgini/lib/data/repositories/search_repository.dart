import 'package:dosya_gezgini/data/models/search_page_result.dart';
import 'package:dosya_gezgini/data/services/file_index_service.dart';
import 'package:dosya_gezgini/data/services/search_query_service.dart';

class SearchRepository {
  SearchRepository({
    required FileIndexService fileIndexService,
    required SearchQueryService searchQueryService,
  }) : _fileIndexService = fileIndexService,
       _searchQueryService = searchQueryService;

  final FileIndexService _fileIndexService;
  final SearchQueryService _searchQueryService;

  Future<IndexReadiness> ensureSearchReady({
    required String rootPath,
    bool forceRefresh = false,
  }) {
    return _fileIndexService.ensureReady(
      rootPath: rootPath,
      forceRefresh: forceRefresh,
    );
  }

  Future<SearchPageResult> getSearchPage({
    required String query,
    int offset = 0,
    int limit = 100,
  }) {
    return _searchQueryService.queryIndex(
      query: query,
      offset: offset,
      limit: limit,
    );
  }

  Future<void> refreshIndex({required String rootPath}) {
    return _fileIndexService.refreshIndex(rootPath: rootPath);
  }
}
