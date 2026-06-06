import 'package:dosya_gezgini/core/localization/l10n_extensions.dart';
import 'package:dosya_gezgini/features/files/presentation/widgets/dosya_folder.dart';
import 'package:dosya_gezgini/features/files/state/folderleragaci.dart';
import 'package:dosya_gezgini/features/files/state/izinler.dart';
import 'package:dosya_gezgini/features/home/state/anasayfa_icerigi_provider.dart';
import 'package:dosya_gezgini/shared/widgets/app_skeleton.dart';
import 'package:dosya_gezgini/shared/widgets/category_grid_skeleton.dart';
import 'package:dosya_gezgini/shared/widgets/empty_state_widget.dart';
import 'package:dosya_gezgini/shared/widgets/error_state_widget.dart';
import 'package:dosya_gezgini/shared/widgets/file_item_skeleton.dart';
import 'package:dosya_gezgini/shared/widgets/folder_list_skeleton.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

class Anasayfaicerigi extends StatelessWidget {
  const Anasayfaicerigi({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<AnasayfaIcerigiProvider>(
      create:
          (context) =>
              AnasayfaIcerigiProvider(izinler: context.read<Izinler>()),
      child: const _AnasayfaIcerigiBody(),
    );
  }
}

class _AnasayfaIcerigiBody extends StatelessWidget {
  const _AnasayfaIcerigiBody();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final appTheme = Theme.of(context);
    final provider = context.watch<AnasayfaIcerigiProvider>();

    if (!provider.isPermissionReady) {
      return const _HomeLoadingView();
    }

    if (!provider.hasStoragePermission) {
      return ErrorStateWidget(
        message: l10n.errorOccurred,
        onRetry: provider.requestPermission,
        retryLabel: l10n.tryAgain,
      );
    }

    final fileTree = provider.fileTree;

    return Animate(
      effects: const [SlideEffect(begin: Offset(2, 0))],
      child: ListView(
        controller: provider.scrollController,
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          Padding(
            padding: const EdgeInsets.all(15),
            child: Center(
              child: Wrap(
                alignment: WrapAlignment.center,
                spacing: 3,
                runSpacing: 3,
                children: [
                  _categoryIcon(
                    'assets/file.png',
                    l10n.categoryFiles,
                    fileTree.bilinmeyendosya,
                    context,
                    provider,
                  ),
                  _categoryIcon(
                    'assets/xls.png',
                    l10n.categoryExcel,
                    fileTree.exceldosya,
                    context,
                    provider,
                  ),
                  _categoryIcon(
                    'assets/image.png',
                    l10n.categoryImages,
                    fileTree.resimdosya,
                    context,
                    provider,
                  ),
                  _categoryIcon(
                    'assets/mp4.png',
                    l10n.categoryVideos,
                    fileTree.videodosya,
                    context,
                    provider,
                  ),
                  _categoryIcon(
                    'assets/mp3.png',
                    l10n.categoryAudio,
                    fileTree.sesdosya,
                    context,
                    provider,
                  ),
                  _categoryIcon(
                    'assets/doc.png',
                    l10n.categoryWord,
                    fileTree.worddosya,
                    context,
                    provider,
                  ),
                  _categoryIcon(
                    'assets/ppt.png',
                    l10n.categoryPowerPoint,
                    fileTree.powerpointdosya,
                    context,
                    provider,
                  ),
                  _categoryIcon(
                    'assets/zip.png',
                    l10n.categoryArchives,
                    fileTree.zipdosya,
                    context,
                    provider,
                  ),
                  _categoryIcon(
                    'assets/pdf.png',
                    l10n.categoryPdf,
                    fileTree.pdfdosya,
                    context,
                    provider,
                  ),
                  _categoryIcon(
                    'assets/txt.png',
                    l10n.categoryText,
                    fileTree.txtdosya,
                    context,
                    provider,
                  ),
                ],
              ),
            ),
          ),
          Center(
            child: Container(
              width: MediaQuery.of(context).size.width - 50,
              height: 60,
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    width: 0.3,
                    color: appTheme.iconTheme.color!,
                  ),
                ),
              ),
              child: Text(
                l10n.recentlyVisited,
                style: appTheme.textTheme.bodyLarge,
              ),
            ),
          ),
          if (!provider.hasRecentEntries)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
              child: EmptyStateWidget(
                message: l10n.noOpenedFolder,
                icon: Icons.history_toggle_off_rounded,
              ),
            )
          else
            _PaginatedRecentSection(provider: provider),
        ],
      ),
    );
  }

  GestureDetector _categoryIcon(
    String imagePath,
    String label,
    FolderNode targetFolder,
    BuildContext context,
    AnasayfaIcerigiProvider provider,
  ) {
    return GestureDetector(
      onTap: () => provider.openFolder(context, targetFolder),
      child: SizedBox(
        width: 80,
        height: 100,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Image.asset(imagePath, width: 50, height: 50),
                Text(label),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PaginatedRecentSection extends StatelessWidget {
  const _PaginatedRecentSection({required this.provider});

  final AnasayfaIcerigiProvider provider;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final visibleFolders = provider.visibleRecentFolders;
    final visibleFiles = provider.visibleRecentFiles;

    return Column(
      children: [
        for (final folder in visibleFolders)
          Klasor(
            key: ValueKey(folder.path),
            name: folder.name,
            path: folder.path,
            klasor: folder,
          ),
        for (final file in visibleFiles)
          Dosya(key: ValueKey(file.path), file: file),
        if (provider.hasMoreRecent)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: FileItemSkeleton(),
          )
        else
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Center(child: Text(l10n.listEnd)),
          ),
      ],
    );
  }
}

class _HomeLoadingView extends StatelessWidget {
  const _HomeLoadingView();

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 24),
      children: const [
        CategoryGridSkeleton(),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          child: AppSkeleton(height: 18, width: 180),
        ),
        SizedBox(height: 8),
        FolderListSkeleton(
          itemCount: 4,
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
        ),
      ],
    );
  }
}
