import 'dart:math' as math;

import 'package:dosya_gezgini/data/models/indexed_file_model.dart';
import 'package:dosya_gezgini/data/models/search_page_result.dart';
import 'package:dosya_gezgini/data/repositories/file_index_repository.dart';
import 'package:path/path.dart' as pathinfo;

class SearchQueryService {
  SearchQueryService(this._fileIndexRepository);

  final FileIndexRepository _fileIndexRepository;

  Future<SearchPageResult> queryIndex({
    required String query,
    required int offset,
    required int limit,
  }) async {
    final normalizedQuery = query.trim().toLowerCase();
    if (normalizedQuery.isEmpty) {
      return const SearchPageResult(
        items: <IndexedFileModel>[],
        totalCount: 0,
        nextOffset: 0,
        hasMore: false,
      );
    }

    final allItems = await _fileIndexRepository.readAllIndexedEntries();
    final matchingItems =
        allItems
            .map(
              (item) => (item: item, score: _scoreMatch(item, normalizedQuery)),
            )
            .where((entry) => entry.score > 0)
            .toList()
          ..sort(_compareEntries);

    final safeOffset = math.min(offset, matchingItems.length);
    final endIndex = math.min(safeOffset + limit, matchingItems.length);

    return SearchPageResult(
      items: matchingItems
          .sublist(safeOffset, endIndex)
          .map((entry) => entry.item)
          .toList(growable: false),
      totalCount: matchingItems.length,
      nextOffset: endIndex,
      hasMore: endIndex < matchingItems.length,
    );
  }

  int _scoreMatch(IndexedFileModel item, String normalizedQuery) {
    final queryTerms = _tokenize(normalizedQuery);
    if (queryTerms.isEmpty) {
      return 0;
    }

    final normalizedName = item.name.toLowerCase();
    final normalizedExtension = item.extension.toLowerCase();
    final normalizedCategory = item.category.toLowerCase();
    final normalizedParentPath = item.parentPath.toLowerCase();
    final parentSegments = normalizedParentPath
        .split(RegExp(r'[\\/]'))
        .where((segment) => segment.isNotEmpty)
        .toList(growable: false);

    var totalScore = 0;
    for (final term in queryTerms) {
      final termScore = _scoreTerm(
        term,
        name: normalizedName,
        extension: normalizedExtension,
        category: normalizedCategory,
        parentPath: normalizedParentPath,
        parentSegments: parentSegments,
      );
      if (termScore == 0) {
        return 0;
      }
      totalScore += termScore;
    }

    if (normalizedName == normalizedQuery) {
      totalScore += 400;
    } else if (normalizedName.startsWith(normalizedQuery)) {
      totalScore += 200;
    }

    return totalScore;
  }

  int _scoreTerm(
    String term, {
    required String name,
    required String extension,
    required String category,
    required String parentPath,
    required List<String> parentSegments,
  }) {
    final normalizedTerm = term.trim().toLowerCase();
    if (normalizedTerm.isEmpty) {
      return 0;
    }

    final extensionWithoutDot =
        extension.startsWith('.') ? extension.substring(1) : extension;
    final parentBaseName = parentSegments.isEmpty ? '' : parentSegments.last;

    if (name == normalizedTerm) {
      return 1200;
    }
    if (name.startsWith(normalizedTerm)) {
      return 950;
    }
    if (_containsWordStart(name, normalizedTerm)) {
      return 800;
    }
    if (name.contains(normalizedTerm)) {
      return 650;
    }
    if (extension == normalizedTerm || extensionWithoutDot == normalizedTerm) {
      return 520;
    }
    if (category == normalizedTerm) {
      return 500;
    }
    if (parentBaseName == normalizedTerm) {
      return 260;
    }
    if (parentBaseName.startsWith(normalizedTerm)) {
      return 220;
    }
    if (parentSegments.any((segment) => segment == normalizedTerm)) {
      return 180;
    }
    if (parentSegments.any((segment) => segment.startsWith(normalizedTerm))) {
      return 140;
    }
    if (normalizedTerm.length >= 4 && parentPath.contains(normalizedTerm)) {
      return 80;
    }

    return 0;
  }

  bool _containsWordStart(String value, String query) {
    final segments = value.split(RegExp(r'[^a-z0-9]+'));
    for (final segment in segments) {
      if (segment.startsWith(query)) {
        return true;
      }
    }

    return false;
  }

  List<String> _tokenize(String query) {
    return query
        .split(RegExp(r'\s+'))
        .map((token) => token.trim())
        .where((token) => token.isNotEmpty)
        .toList(growable: false);
  }

  int _compareEntries(
    ({IndexedFileModel item, int score}) a,
    ({IndexedFileModel item, int score}) b,
  ) {
    final scoreCompare = b.score.compareTo(a.score);
    if (scoreCompare != 0) {
      return scoreCompare;
    }

    if (a.item.isDirectory != b.item.isDirectory) {
      return a.item.isDirectory ? -1 : 1;
    }

    final nameCompare = a.item.name.toLowerCase().compareTo(
      b.item.name.toLowerCase(),
    );
    if (nameCompare != 0) {
      return nameCompare;
    }

    return pathinfo
        .dirname(a.item.path)
        .toLowerCase()
        .compareTo(pathinfo.dirname(b.item.path).toLowerCase());
  }
}
