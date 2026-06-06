import 'package:dosya_gezgini/core/localization/file_access_error_messages.dart';
import 'package:dosya_gezgini/core/localization/l10n_extensions.dart';
import 'package:dosya_gezgini/data/repositories/category_repository.dart';
import 'package:dosya_gezgini/features/files/presentation/models/folder_route_data.dart';
import 'package:dosya_gezgini/features/files/presentation/widgets/dosya_folder.dart';
import 'package:dosya_gezgini/features/files/state/altislem_provider.dart';
import 'package:dosya_gezgini/features/files/state/dosyaislemleri.dart';
import 'package:dosya_gezgini/features/files/state/folderleragaci.dart';
import 'package:dosya_gezgini/features/files/state/izinler.dart';
import 'package:dosya_gezgini/features/files/state/klasoricerigisayfasi_provider.dart';
import 'package:dosya_gezgini/shared/widgets/empty_state_widget.dart';
import 'package:dosya_gezgini/shared/widgets/error_state_widget.dart';
import 'package:dosya_gezgini/shared/widgets/file_item_skeleton.dart';
import 'package:dosya_gezgini/shared/widgets/folder_list_skeleton.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class Klasoricerigisayfasi extends StatelessWidget {
  const Klasoricerigisayfasi({super.key, this.folder});

  final FolderRouteData? folder;

  @override
  Widget build(BuildContext context) {
    final providerKey =
        folder?.path ??
        context.read<Izinler>().currentFolder?.path ??
        '__folder_content__';

    return ChangeNotifierProvider<KlasoricerigisayfasiProvider>(
      key: ValueKey(providerKey),
      create:
          (context) => KlasoricerigisayfasiProvider(
            izinler: context.read<Izinler>(),
            categoryRepository: context.read<CategoryRepository>(),
            routeData: folder,
          ),
      child: const _KlasoricerigiSayfaView(),
    );
  }
}

class _KlasoricerigiSayfaView extends StatelessWidget {
  const _KlasoricerigiSayfaView();

  Future<bool> _handleWillPop(BuildContext context) async {
    final altIslemProvider = context.read<Altislemprovider>();
    if (!altIslemProvider.anahtar) {
      return true;
    }

    altIslemProvider.setSelectionMode(false);
    context.read<Dosyaislemleri>().clearSelection();
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return Selector<Altislemprovider, bool>(
      selector: (_, altIslemProvider) => altIslemProvider.anahtar,
      builder: (context, isSelectionMode, child) {
        if (!isSelectionMode) {
          return child!;
        }

        // ignore: deprecated_member_use
        return WillPopScope(
          onWillPop: () => _handleWillPop(context),
          child: child!,
        );
      },
      child: _KlasoricerigiBody(),
    );
  }
}

class _KlasoricerigiBody extends StatelessWidget {
  const _KlasoricerigiBody();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<KlasoricerigisayfasiProvider>();
    return _buildBody(context, provider);
  }

  Widget _buildBody(
    BuildContext context,
    KlasoricerigisayfasiProvider provider,
  ) {
    final l10n = context.l10n;
    final folder = provider.folder;

    if (provider.loadError != null &&
        (folder == null || folder.childCount == 0)) {
      return _buildRefreshableState(
        context,
        provider: provider,
        child: ErrorStateWidget(
          message: resolveFileAccessErrorMessage(l10n, provider.loadError),
          onRetry:
              () =>
                  provider.loadFolder(forceRefresh: folder?.isVirtual ?? false),
          retryLabel: l10n.tryAgain,
        ),
      );
    }

    if (folder == null) {
      return const FolderListSkeleton();
    }

    if (folder.isVirtual && provider.isLoading && folder.childCount == 0) {
      return _buildCategoryLoadingState(context, provider, folder);
    }

    if (provider.isLoading && folder.childCount == 0) {
      return const FolderListSkeleton();
    }

    if (!provider.isLoading && folder.childCount == 0) {
      return _buildRefreshableState(
        context,
        provider: provider,
        child: EmptyStateWidget(message: l10n.folderEmpty),
      );
    }

    final folders = provider.visibleFolders;
    final files = provider.visibleFiles;
    final loadingPlaceholderCount = provider.loadingPlaceholderCount;

    return RefreshIndicator(
      color: Theme.of(context).primaryColor,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      onRefresh: () => _handleRefresh(context, provider),
      child: ListView.builder(
        controller: provider.scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: folders.length + files.length + loadingPlaceholderCount,
        itemBuilder: (context, index) {
          if (index < folders.length) {
            final childFolder = folders[index];
            return Klasor(
              key: ValueKey(childFolder.path),
              name: childFolder.name,
              path: childFolder.path,
              klasor: childFolder,
            );
          }

          final fileIndex = index - folders.length;
          if (fileIndex < files.length) {
            final file = files[fileIndex];
            return Dosya(key: ValueKey(file.path), file: file);
          }

          return const FileItemSkeleton();
        },
      ),
    );
  }

  Widget _buildCategoryLoadingState(
    BuildContext context,
    KlasoricerigisayfasiProvider provider,
    FolderNode folder,
  ) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 28, 16, 16),
      children: [
        Text(
          provider.categoryProgressLabel ??
              provider.buildCategoryProgressLabel(context.l10n, folder),
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 12),
        LinearProgressIndicator(color: Theme.of(context).primaryColor),
        const SizedBox(height: 20),
        const FolderListSkeleton(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          padding: EdgeInsets.zero,
          itemCount: 6,
        ),
      ],
    );
  }

  Widget _buildRefreshableState(
    BuildContext context, {
    required KlasoricerigisayfasiProvider provider,
    required Widget child,
  }) {
    return RefreshIndicator(
      color: Theme.of(context).primaryColor,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      onRefresh: () => _handleRefresh(context, provider),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(height: MediaQuery.of(context).size.height * 0.25),
          Center(child: child),
        ],
      ),
    );
  }

  Future<void> _handleRefresh(
    BuildContext context,
    KlasoricerigisayfasiProvider provider,
  ) async {
    final message = await provider.refreshFolderWithSync(context.l10n);
    if (!context.mounted || message == null) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}
