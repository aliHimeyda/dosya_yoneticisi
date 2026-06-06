import 'package:dosya_gezgini/core/localization/file_sync_messages.dart';
import 'package:dosya_gezgini/core/localization/l10n_extensions.dart';
import 'package:dosya_gezgini/features/files/state/altislem_provider.dart';
import 'package:dosya_gezgini/features/files/state/dosyaislemleri.dart';
import 'package:dosya_gezgini/features/files/state/izinler.dart';
import 'package:dosya_gezgini/shared/pagination/paginated_file_list.dart';
import 'package:dosya_gezgini/shared/widgets/empty_state_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

class Kaydedilendosyalar extends StatelessWidget {
  const Kaydedilendosyalar({super.key});

  Future<void> _refreshEntries(BuildContext context) async {
    final result = await context.read<Izinler>().refreshSavedEntries();
    if (!context.mounted) {
      return;
    }

    final message = buildFileSyncNoticeMessage(context.l10n, result);
    if (message == null) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  void _clearSelectionMode(BuildContext context) {
    final altIslemProvider = context.read<Altislemprovider>();
    if (!altIslemProvider.anahtar) {
      return;
    }

    altIslemProvider.setSelectionMode(false);
    context.read<Dosyaislemleri>().clearSelection();
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

    return Selector<Altislemprovider, bool>(
      selector: (_, altIslemProvider) => altIslemProvider.anahtar,
      builder: (context, isSelectionMode, child) {
        if (!isSelectionMode) {
          return child!;
        }

        // ignore: deprecated_member_use
        return WillPopScope(
          onWillPop: () async {
            _clearSelectionMode(context);
            return false;
          },
          child: child!,
        );
      },
      child: Selector<Izinler, FolderFileEntries>(
        selector: (_, izinler) => izinler.savedEntries,
        builder: (context, entries, _) {
          if (entries.isEmpty) {
            return _buildRefreshableState(
              context,
              child: EmptyStateWidget(
                message: l10n.folderEmpty,
                icon: Icons.bookmark_border_rounded,
              ),
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
      ),
    );
  }
}
