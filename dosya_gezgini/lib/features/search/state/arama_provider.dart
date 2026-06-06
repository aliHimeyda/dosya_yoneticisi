import 'package:dosya_gezgini/features/search/state/search_controller.dart'
    as search_state;
import 'package:flutter/material.dart';

class AramaProvider extends ChangeNotifier {
  AramaProvider({required search_state.SearchController searchController})
    : _searchController = searchController {
    textController.text = _searchController.typedQuery;
    scrollController.addListener(_handleScroll);
  }

  final search_state.SearchController _searchController;

  final TextEditingController textController = TextEditingController();
  final FocusNode focusNode = FocusNode();
  final ScrollController scrollController = ScrollController();

  void updateQuery(String value) {
    _searchController.updateQuery(value);
  }

  Future<void> submitCurrentQuery() {
    return _searchController.submitCurrentQuery();
  }

  Future<void> refresh() {
    return _searchController.refresh();
  }

  Future<void> retry() {
    return _searchController.retry();
  }

  Future<void> loadMore() {
    return _searchController.loadMore();
  }

  void _handleScroll() {
    if (!scrollController.hasClients) {
      return;
    }

    if (scrollController.position.extentAfter > 320) {
      return;
    }

    loadMore();
  }

  @override
  void dispose() {
    scrollController.removeListener(_handleScroll);
    textController.dispose();
    focusNode.dispose();
    scrollController.dispose();
    super.dispose();
  }
}
