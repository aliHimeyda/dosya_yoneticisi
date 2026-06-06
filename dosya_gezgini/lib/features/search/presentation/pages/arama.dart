import 'dart:io';

import 'package:dosya_gezgini/core/localization/l10n_extensions.dart';
import 'package:dosya_gezgini/data/models/file_metadata_model.dart';
import 'package:dosya_gezgini/data/models/indexed_file_model.dart';
import 'package:dosya_gezgini/features/files/presentation/widgets/dosya_folder.dart';
import 'package:dosya_gezgini/features/files/state/folderleragaci.dart';
import 'package:dosya_gezgini/features/search/state/arama_provider.dart';
import 'package:dosya_gezgini/features/search/state/search_controller.dart'
    as search_state;
import 'package:dosya_gezgini/shared/widgets/empty_state_widget.dart';
import 'package:dosya_gezgini/shared/widgets/error_state_widget.dart';
import 'package:dosya_gezgini/shared/widgets/file_item_skeleton.dart';
import 'package:dosya_gezgini/shared/widgets/folder_list_skeleton.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class Arama extends StatelessWidget {
  const Arama({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<AramaProvider>(
      create:
          (context) => AramaProvider(
            searchController: context.read<search_state.SearchController>(),
          ),
      child: const _AramaView(),
    );
  }
}

class _AramaView extends StatelessWidget {
  const _AramaView();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final searchController = context.watch<search_state.SearchController>();
    final provider = context.read<AramaProvider>();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(15, 5, 15, 8),
          child: SizedBox(
            height: 40,
            child: TextField(
              controller: provider.textController,
              focusNode: provider.focusNode,
              onChanged: provider.updateQuery,
              onSubmitted: (_) => provider.submitCurrentQuery(),
              decoration: InputDecoration(
                prefixIcon: IconButton(
                  icon: const Icon(Icons.search, size: 18),
                  onPressed: provider.submitCurrentQuery,
                ),
                hintText: l10n.searchHint,
                focusColor: Theme.of(context).primaryColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(7),
                ),
                filled: true,
                fillColor: Theme.of(context).primaryColor,
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),
        ),
        Expanded(child: _buildBody(context, searchController)),
      ],
    );
  }

  Widget _buildBody(
    BuildContext context,
    search_state.SearchController searchController,
  ) {
    final l10n = context.l10n;

    if (searchController.isLoading && !searchController.hasResults) {
      return const FolderListSkeleton();
    }

    if (searchController.error != null && !searchController.hasResults) {
      return _buildRefreshableState(
        context,
        ErrorStateWidget(
          message: l10n.errorOccurred,
          onRetry: searchController.retry,
          retryLabel: l10n.tryAgain,
        ),
      );
    }

    if (!searchController.hasTypedQuery) {
      return _buildCenteredState(
        context,
        EmptyStateWidget(message: l10n.searchHint, icon: Icons.search_rounded),
      );
    }

    if (searchController.isQueryTooShort) {
      return _buildCenteredState(
        context,
        EmptyStateWidget(
          message: l10n.searchMinCharacters(
            search_state.SearchController.minimumQueryLength,
          ),
          icon: Icons.keyboard_alt_outlined,
        ),
      );
    }

    if (!searchController.hasResults) {
      return _buildRefreshableState(
        context,
        EmptyStateWidget(
          message: l10n.noSearchResults,
          icon: Icons.search_off_rounded,
        ),
      );
    }

    final results = searchController.results;
    final showFooterError =
        searchController.error != null && results.isNotEmpty;
    final loadingPlaceholders = searchController.isLoadingMore ? 3 : 0;
    final footerErrorCount = showFooterError ? 1 : 0;

    return RefreshIndicator(
      color: Theme.of(context).primaryColor,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      onRefresh: context.read<AramaProvider>().refresh,
      child: ListView.builder(
        controller: context.read<AramaProvider>().scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: results.length + loadingPlaceholders + footerErrorCount,
        itemBuilder: (context, index) {
          if (index < results.length) {
            return _buildResultItem(results[index]);
          }

          final loadingIndex = index - results.length;
          if (loadingIndex < loadingPlaceholders) {
            return const FileItemSkeleton();
          }

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: ErrorStateWidget(
              message: l10n.errorOccurred,
              onRetry: context.read<AramaProvider>().loadMore,
              retryLabel: l10n.tryAgain,
            ),
          );
        },
      ),
    );
  }

  Widget _buildResultItem(IndexedFileModel item) {
    if (item.isDirectory) {
      final folder = FolderNode(item.name, item.path, [], [], null);
      return Klasor(
        key: ValueKey(item.path),
        name: folder.name,
        path: folder.path,
        klasor: folder,
      );
    }

    return Dosya(
      key: ValueKey(item.path),
      file: File(item.path),
      initialMetadata: FileMetadataModel.fromIndexedFile(item),
    );
  }

  Widget _buildCenteredState(BuildContext context, Widget child) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(height: MediaQuery.of(context).size.height * 0.25),
        Center(child: child),
      ],
    );
  }

  Widget _buildRefreshableState(BuildContext context, Widget child) {
    return RefreshIndicator(
      color: Theme.of(context).primaryColor,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      onRefresh: context.read<AramaProvider>().refresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(height: MediaQuery.of(context).size.height * 0.25),
          Center(child: child),
        ],
      ),
    );
  }
}
