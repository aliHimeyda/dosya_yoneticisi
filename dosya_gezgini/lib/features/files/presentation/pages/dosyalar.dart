import 'package:dosya_gezgini/core/localization/l10n_extensions.dart';
import 'package:dosya_gezgini/features/files/state/izinler.dart';
import 'package:dosya_gezgini/shared/pagination/paginated_file_list.dart';
import 'package:dosya_gezgini/shared/widgets/empty_state_widget.dart';
import 'package:dosya_gezgini/shared/widgets/error_state_widget.dart';
import 'package:dosya_gezgini/shared/widgets/folder_list_skeleton.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

class Dosyalar extends StatelessWidget {
  const Dosyalar({super.key});

  Future<void> _requestPermission(BuildContext context) async {
    await context.read<Izinler>().requestAllStoragePermission();
  }

  Future<void> _refreshEntries(BuildContext context) async {
    await context.read<Izinler>().refreshRootEntries();
  }

  Widget _buildRefreshableState(BuildContext context, {required Widget child}) {
    return RefreshIndicator(
      color: Theme.of(context).primaryColor,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      onRefresh: () => _refreshEntries(context),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(height: MediaQuery.of(context).size.height * 0.25),
          Center(child: child),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Selector<Izinler, ({bool isReady, bool hasPermission})>(
      selector:
          (_, izinler) => (
            isReady: izinler.isPermissionStateReady,
            hasPermission: izinler.hasStoragePermission,
          ),
      builder: (context, permissionState, _) {
        if (!permissionState.isReady) {
          return const FolderListSkeleton();
        }

        if (!permissionState.hasPermission) {
          return Center(
            child: ErrorStateWidget(
              message: l10n.errorOccurred,
              onRetry: () => _requestPermission(context),
              retryLabel: l10n.tryAgain,
            ),
          );
        }

        return Selector<Izinler, FolderFileEntries>(
          selector: (_, izinler) => izinler.rootEntries,
          builder: (context, entries, _) {
            if (entries.isEmpty) {
              return _buildRefreshableState(
                context,
                child: EmptyStateWidget(message: l10n.folderEmpty),
              );
            }

            return Animate(
              effects: const [SlideEffect(begin: Offset(2, 0))],
              child: PaginatedFileListView(
                folders: entries.folders,
                files: entries.files,
                onRefresh: () => _refreshEntries(context),
              ),
            );
          },
        );
      },
    );
  }
}
