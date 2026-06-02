import 'package:dosya_gezgini/core/localization/l10n_extensions.dart';
import 'package:dosya_gezgini/features/files/state/altislem_provider.dart';
import 'package:dosya_gezgini/features/files/state/dosyaislemleri.dart';
import 'package:dosya_gezgini/features/files/state/izinler.dart';
import 'package:dosya_gezgini/shared/pagination/paginated_file_list.dart';
import 'package:dosya_gezgini/shared/widgets/empty_state_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

class Gizlidosyalar extends StatelessWidget {
  const Gizlidosyalar({super.key});

  Future<void> _refreshEntries(BuildContext context) async {
    await context.read<Izinler>().refreshHiddenEntries();
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
        return PopScope(
          canPop: !isSelectionMode,
          onPopInvokedWithResult: (didPop, result) {
            if (didPop) {
              return;
            }
            _clearSelectionMode(context);
          },
          child: child!,
        );
      },
      child: Selector<Izinler, FolderFileEntries>(
        selector: (_, izinler) => izinler.hiddenEntries,
        builder: (context, entries, _) {
          if (entries.isEmpty) {
            return _buildRefreshableState(
              context,
              child: EmptyStateWidget(
                message: l10n.folderEmpty,
                icon: Icons.visibility_off_rounded,
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
