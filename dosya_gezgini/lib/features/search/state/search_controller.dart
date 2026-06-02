import 'dart:async';

import 'package:dosya_gezgini/core/constants/storage_paths.dart';
import 'package:dosya_gezgini/data/models/indexed_file_model.dart';
import 'package:dosya_gezgini/data/repositories/search_repository.dart';
import 'package:flutter/material.dart';

class SearchController extends ChangeNotifier {
  SearchController({
    required SearchRepository searchRepository,
    this.rootPath = storageRootPath,
  }) : _searchRepository = searchRepository;

  static const Duration debounceDuration = Duration(milliseconds: 400);
  static const int minimumQueryLength = 2;
  static const int pageSize = 100;

  final SearchRepository _searchRepository;
  final String rootPath;

  Timer? _debounce;
  int _searchGeneration = 0;

  String _typedQuery = '';
  String _activeQuery = '';
  List<IndexedFileModel> _results = const <IndexedFileModel>[];
  Object? _error;
  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _hasMore = false;
  int _nextOffset = 0;

  String get typedQuery => _typedQuery;
  String get activeQuery => _activeQuery;
  List<IndexedFileModel> get results =>
      List<IndexedFileModel>.unmodifiable(_results);
  Object? get error => _error;
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  bool get hasMore => _hasMore;
  bool get hasResults => _results.isNotEmpty;

  bool get hasTypedQuery => _typedQuery.trim().isNotEmpty;
  bool get isQueryTooShort =>
      hasTypedQuery && _typedQuery.trim().length < minimumQueryLength;

  void updateQuery(String value) {
    _typedQuery = value;
    _debounce?.cancel();
    _searchGeneration++;

    final trimmedQuery = value.trim();
    if (trimmedQuery.isEmpty) {
      _resetResults();
      notifyListeners();
      return;
    }

    if (trimmedQuery.length < minimumQueryLength) {
      _resetResults(clearTypedQuery: false);
      notifyListeners();
      return;
    }

    _error = null;
    _isLoading = true;
    _isLoadingMore = false;
    _results = const <IndexedFileModel>[];
    _hasMore = false;
    _nextOffset = 0;
    notifyListeners();

    final searchGeneration = _searchGeneration;
    _debounce = Timer(debounceDuration, () {
      unawaited(
        _performSearch(
          trimmedQuery,
          searchGeneration: searchGeneration,
          forceRefresh: false,
        ),
      );
    });
  }

  Future<void> submitCurrentQuery() async {
    _debounce?.cancel();
    final trimmedQuery = _typedQuery.trim();
    _searchGeneration++;

    if (trimmedQuery.isEmpty) {
      _resetResults();
      notifyListeners();
      return;
    }

    if (trimmedQuery.length < minimumQueryLength) {
      _resetResults(clearTypedQuery: false);
      notifyListeners();
      return;
    }

    _error = null;
    _isLoading = true;
    _isLoadingMore = false;
    notifyListeners();

    await _performSearch(
      trimmedQuery,
      searchGeneration: _searchGeneration,
      forceRefresh: false,
    );
  }

  Future<void> refresh() async {
    final trimmedQuery = _typedQuery.trim();
    if (trimmedQuery.length < minimumQueryLength) {
      return;
    }

    _debounce?.cancel();
    _searchGeneration++;
    _error = null;
    _isLoading = true;
    _isLoadingMore = false;
    notifyListeners();

    await _performSearch(
      trimmedQuery,
      searchGeneration: _searchGeneration,
      forceRefresh: true,
    );
  }

  Future<void> retry() async {
    if (_typedQuery.trim().length < minimumQueryLength) {
      return;
    }

    await submitCurrentQuery();
  }

  Future<void> loadMore() async {
    if (_activeQuery.isEmpty || _isLoading || _isLoadingMore || !_hasMore) {
      return;
    }

    final searchGeneration = _searchGeneration;
    _isLoadingMore = true;
    _error = null;
    notifyListeners();

    try {
      final nextPage = await _searchRepository.getSearchPage(
        query: _activeQuery,
        offset: _nextOffset,
        limit: pageSize,
      );

      if (!_isCurrentSearch(searchGeneration, _activeQuery)) {
        return;
      }

      _results = <IndexedFileModel>[..._results, ...nextPage.items];
      _nextOffset = nextPage.nextOffset;
      _hasMore = nextPage.hasMore;
    } catch (error) {
      if (!_isCurrentSearch(searchGeneration, _activeQuery)) {
        return;
      }

      _error = error;
    } finally {
      if (_isCurrentSearch(searchGeneration, _activeQuery)) {
        _isLoadingMore = false;
        notifyListeners();
      }
    }
  }

  Future<void> _performSearch(
    String query, {
    required int searchGeneration,
    required bool forceRefresh,
  }) async {
    try {
      final readiness = await _searchRepository.ensureSearchReady(
        rootPath: rootPath,
        forceRefresh: forceRefresh,
      );

      if (!_isCurrentSearch(searchGeneration, query)) {
        return;
      }

      final firstPage = await _searchRepository.getSearchPage(
        query: query,
        limit: pageSize,
      );

      if (!_isCurrentSearch(searchGeneration, query)) {
        return;
      }

      _activeQuery = query;
      _results = firstPage.items;
      _nextOffset = firstPage.nextOffset;
      _hasMore = firstPage.hasMore;
      _error = null;
      _isLoading = false;
      notifyListeners();

      if (readiness.needsBackgroundRefresh && !forceRefresh) {
        unawaited(
          _refreshInBackground(query, searchGeneration: searchGeneration),
        );
      }
    } catch (error) {
      if (!_isCurrentSearch(searchGeneration, query)) {
        return;
      }

      _activeQuery = query;
      _results = const <IndexedFileModel>[];
      _nextOffset = 0;
      _hasMore = false;
      _error = error;
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _refreshInBackground(
    String query, {
    required int searchGeneration,
  }) async {
    try {
      await _searchRepository.refreshIndex(rootPath: rootPath);
      if (!_isCurrentSearch(searchGeneration, query)) {
        return;
      }

      final refreshedPage = await _searchRepository.getSearchPage(
        query: query,
        limit: pageSize,
      );

      if (!_isCurrentSearch(searchGeneration, query)) {
        return;
      }

      _results = refreshedPage.items;
      _nextOffset = refreshedPage.nextOffset;
      _hasMore = refreshedPage.hasMore;
      _error = null;
      notifyListeners();
    } catch (_) {
      // Background refresh should not replace visible search results with an error.
    }
  }

  bool _isCurrentSearch(int searchGeneration, String query) {
    return _searchGeneration == searchGeneration &&
        _typedQuery.trim() == query &&
        (_activeQuery.isEmpty || _activeQuery == query || _isLoading);
  }

  void _resetResults({bool clearTypedQuery = true}) {
    if (clearTypedQuery) {
      _typedQuery = '';
    }
    _activeQuery = '';
    _results = const <IndexedFileModel>[];
    _error = null;
    _isLoading = false;
    _isLoadingMore = false;
    _hasMore = false;
    _nextOffset = 0;
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }
}
