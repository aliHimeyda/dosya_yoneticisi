import 'dart:async';
import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:dosya_gezgini/app/router/app_router.dart';
import 'package:dosya_gezgini/core/utils/file_formatters.dart';
import 'package:dosya_gezgini/data/models/file_metadata_model.dart';
import 'package:dosya_gezgini/data/services/file_metadata_service.dart';
import 'package:dosya_gezgini/data/services/thumbnail_cache_service.dart';
import 'package:dosya_gezgini/features/files/presentation/models/folder_route_data.dart';
import 'package:dosya_gezgini/features/files/state/altislem_provider.dart';
import 'package:dosya_gezgini/features/files/state/dosyaislemleri.dart';
import 'package:dosya_gezgini/features/files/state/folderleragaci.dart';
import 'package:dosya_gezgini/features/files/state/izinler.dart';
import 'package:dosya_gezgini/shared/widgets/app_skeleton.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path/path.dart' as pathinfo;
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';

class Klasor extends StatefulWidget {
  const Klasor({
    super.key,
    required this.name,
    required this.path,
    required this.klasor,
  });

  final FolderNode klasor;
  final String name;
  final String path;

  @override
  State<Klasor> createState() => _KlasorState();
}

class _KlasorState extends State<Klasor> with AutomaticKeepAliveClientMixin {
  String? _countRequestPath;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _ensureFolderCount();
  }

  @override
  void didUpdateWidget(covariant Klasor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.klasor, widget.klasor)) {
      final pathChanged = oldWidget.klasor.path != widget.klasor.path;
      _countRequestPath = null;
      _ensureFolderCount(force: pathChanged);
    }
  }

  void _ensureFolderCount({bool force = false}) {
    if (widget.klasor.isVirtual) {
      return;
    }

    if (!force && _countRequestPath == widget.klasor.path) {
      return;
    }

    _countRequestPath = widget.klasor.path;
    unawaited(
      context.read<Izinler>().ensureFolderCount(
        widget.klasor,
        refresh: force && widget.klasor.cachedTotalCount != null,
      ),
    );
  }

  void _openFolder(BuildContext context) {
    final routeData = FolderRouteData.fromFolderNode(widget.klasor);
    final currentLocation = GoRouterState.of(context).uri.toString();
    final destination = Paths.folderContentLocationFor(
      currentLocation,
      routeData.path,
    );

    if (currentLocation == destination) {
      return;
    }

    unawaited(context.read<Izinler>().addRecentFolderEntry(widget.klasor));
    context.push(destination, extra: routeData);
  }

  void _toggleSelection(BuildContext context) {
    context.read<Dosyaislemleri>().toggleFolderSelection(widget.klasor);
  }

  void _handleTap(BuildContext context, bool isSelectionMode) {
    if (isSelectionMode) {
      _toggleSelection(context);
      return;
    }

    _openFolder(context);
  }

  void _handleLongPress(BuildContext context) {
    context.read<Altislemprovider>().setSelectionMode(true);
    _toggleSelection(context);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Selector<Altislemprovider, bool>(
      selector: (_, altIslemProvider) => altIslemProvider.anahtar,
      builder: (context, isSelectionMode, _) {
        return Selector<Dosyaislemleri, bool>(
          selector:
              (_, dosyaIslemleri) =>
                  dosyaIslemleri.isFolderSelected(widget.klasor),
          builder: (context, isSelected, _) {
            return Center(
              child: Animate(
                effects: const [
                  FadeEffect(duration: Duration(milliseconds: 100)),
                ],
                child: GestureDetector(
                  onLongPress: () => _handleLongPress(context),
                  onTap: () => _handleTap(context, isSelectionMode),
                  child: Container(
                    width: MediaQuery.of(context).size.width - 20,
                    height: MediaQuery.of(context).size.height / 10,
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          width: 0.3,
                          color: Theme.of(context).iconTheme.color!,
                        ),
                        top: BorderSide(
                          width: 1,
                          color: Theme.of(context).iconTheme.color!,
                        ),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: ListenableBuilder(
                        listenable: widget.klasor,
                        builder: (context, _) {
                          final itemCountLabel = widget.klasor.itemCountLabel;

                          return Row(
                            children: [
                              if (isSelectionMode)
                                _SelectionIndicator(
                                  isSelected: isSelected,
                                  activeColor: Theme.of(context).primaryColor,
                                  borderColor:
                                      Theme.of(context).iconTheme.color!,
                                  onTap: () => _toggleSelection(context),
                                ),
                              Image.asset(
                                'assets/folder.png',
                                width: 40,
                                height: 40,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      pathinfo.basename(widget.path).length > 20
                                          ? '${pathinfo.basename(widget.path).substring(0, 20)}...'
                                          : pathinfo.basename(widget.path),
                                      style:
                                          Theme.of(context).textTheme.bodyLarge,
                                    ),
                                    widget.klasor.olusumtarihi == null
                                        ? Row(
                                          children: [
                                            Text('$itemCountLabel | '),
                                            const AppSkeleton(
                                              width: 72,
                                              height: 12,
                                              borderRadius: BorderRadius.all(
                                                Radius.circular(6),
                                              ),
                                            ),
                                          ],
                                        )
                                        : Text(
                                          '$itemCountLabel | ${widget.klasor.formatlanmistarih}',
                                        ),
                                  ],
                                ),
                              ),
                              const Icon(Icons.chevron_right),
                            ],
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class Dosya extends StatefulWidget {
  const Dosya({
    super.key,
    required this.file,
    this.initialMetadata,
  });

  final File file;
  final FileMetadataModel? initialMetadata;

  @override
  State<Dosya> createState() => _DosyaState();
}

class _DosyaState extends State<Dosya> with AutomaticKeepAliveClientMixin {
  static const double _previewSize = 40;
  static const Set<String> _imageExtensions = {
    '.png',
    '.jpg',
    '.jpeg',
    '.webp',
    '.gif',
    '.bmp',
    '.heic',
  };
  static const Set<String> _videoExtensions = {
    '.mp4',
    '.mkv',
    '.avi',
    '.mov',
    '.m4v',
    '.webm',
    '.3gp',
  };

  FileMetadataService? _fileMetadataService;
  ValueListenable<FileMetadataModel?>? _metadataListenable;
  bool _metadataPrimeQueued = false;
  ThumbnailCacheService? _thumbnailCacheService;
  ValueNotifier<String?>? _thumbnailPathListenable;
  Timer? _deferredThumbnailTimer;
  bool _thumbnailPrimeQueued = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final metadataService = context.read<FileMetadataService>();
    if (!identical(metadataService, _fileMetadataService)) {
      _fileMetadataService = metadataService;
      _bindMetadataListenable();
    }

    final service = context.read<ThumbnailCacheService>();
    if (!identical(service, _thumbnailCacheService)) {
      _thumbnailCacheService = service;
      _bindThumbnailListenable();
    }

    _scheduleMetadataPrime();
    _scheduleThumbnailPrime();
  }

  @override
  void didUpdateWidget(covariant Dosya oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.file.path == widget.file.path) {
      if (oldWidget.initialMetadata != widget.initialMetadata) {
        _scheduleMetadataPrime();
      }
      return;
    }

    _deferredThumbnailTimer?.cancel();
    _bindMetadataListenable();
    _bindThumbnailListenable();
    _scheduleMetadataPrime();
    _scheduleThumbnailPrime();
  }

  @override
  void dispose() {
    _deferredThumbnailTimer?.cancel();
    super.dispose();
  }

  @override
  bool get wantKeepAlive => true;

  String get _dosyaUzantisi =>
      pathinfo.extension(widget.file.path).toLowerCase();
  bool get _isImageFile => _imageExtensions.contains(_dosyaUzantisi);
  bool get _isVideoFile => _videoExtensions.contains(_dosyaUzantisi);
  bool get _supportsThumbnail => _isImageFile || _isVideoFile;

  void _bindMetadataListenable() {
    final service = _fileMetadataService;
    if (service == null) {
      _metadataListenable = null;
      return;
    }

    _metadataListenable = service.listenableFor(widget.file.path);
  }

  void _scheduleMetadataPrime() {
    if (_metadataPrimeQueued) {
      return;
    }

    final service = _fileMetadataService;
    if (service == null) {
      return;
    }

    final currentMetadata = service.currentMetadata(widget.file.path);
    if (currentMetadata != null && widget.initialMetadata == null) {
      return;
    }

    _metadataPrimeQueued = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _metadataPrimeQueued = false;
      if (!mounted) {
        return;
      }

      unawaited(
        service.prime(
          widget.file,
          fallbackModel: widget.initialMetadata,
        ),
      );
    });
  }

  void _bindThumbnailListenable() {
    final service = _thumbnailCacheService;
    if (service == null || !_supportsThumbnail) {
      _thumbnailPathListenable = null;
      return;
    }

    _thumbnailPathListenable = service.listenableFor(widget.file.path);
  }

  void _scheduleThumbnailPrime() {
    if (!_supportsThumbnail ||
        _thumbnailPrimeQueued ||
        (_deferredThumbnailTimer?.isActive ?? false)) {
      return;
    }

    final service = _thumbnailCacheService;
    if (service != null) {
      final thumbnailPath = service.currentThumbnailPath(widget.file.path);
      if ((thumbnailPath?.isNotEmpty ?? false) ||
          service.isPending(widget.file.path)) {
        return;
      }
    }

    _thumbnailPrimeQueued = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _thumbnailPrimeQueued = false;
      if (!mounted) {
        return;
      }

      unawaited(_primeThumbnail());
    });
  }

  Future<void> _primeThumbnail() async {
    final service = _thumbnailCacheService;
    if (service == null || !_supportsThumbnail) {
      return;
    }

    final shouldDefer = Scrollable.recommendDeferredLoadingForContext(context);
    await service.prime(widget.file, allowGeneration: !shouldDefer);
    if (shouldDefer) {
      _scheduleDeferredThumbnailRetry();
      return;
    }

    _deferredThumbnailTimer?.cancel();
  }

  void _scheduleDeferredThumbnailRetry() {
    if (_deferredThumbnailTimer?.isActive ?? false) {
      return;
    }

    _deferredThumbnailTimer = Timer(const Duration(milliseconds: 250), () {
      if (!mounted) {
        return;
      }

      _deferredThumbnailTimer = null;
      _scheduleThumbnailPrime();
    });
  }

  void _toggleSelection(BuildContext context) {
    context.read<Dosyaislemleri>().toggleFileSelection(widget.file);
  }

  void _handleLongPress(BuildContext context) {
    context.read<Altislemprovider>().setSelectionMode(true);
    _toggleSelection(context);
  }

  Future<void> _handleTap(BuildContext context, bool isSelectionMode) async {
    if (isSelectionMode) {
      _toggleSelection(context);
      return;
    }

    unawaited(context.read<Izinler>().addRecentFileEntry(widget.file));

    try {
      if (_dosyaUzantisi == '.zip') {
        await unzipFile(widget.file);
      } else {
        debugPrint('${widget.file.path} konumlu dosya aciliyor');
        await OpenFilex.open(widget.file.path);
      }
    } catch (e) {
      debugPrint('Dosya acilamadi: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final dosyauzantisi = _dosyaUzantisi;

    return Selector<Altislemprovider, bool>(
      selector: (_, altIslemProvider) => altIslemProvider.anahtar,
      builder: (context, isSelectionMode, _) {
        return Selector<Dosyaislemleri, bool>(
          selector:
              (_, dosyaIslemleri) => dosyaIslemleri.isFileSelected(widget.file),
          builder: (context, isSelected, _) {
            return Center(
              child: Animate(
                effects: const [
                  FadeEffect(duration: Duration(milliseconds: 100)),
                ],
                child: GestureDetector(
                  onLongPress: () => _handleLongPress(context),
                  onTap: () => _handleTap(context, isSelectionMode),
                  child: Container(
                    width: MediaQuery.of(context).size.width - 20,
                    height: MediaQuery.of(context).size.height / 10,
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          width: 0.3,
                          color: Theme.of(context).iconTheme.color!,
                        ),
                        top: BorderSide(
                          width: 1,
                          color: Theme.of(context).iconTheme.color!,
                        ),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: Row(
                        children: [
                          if (isSelectionMode)
                            _SelectionIndicator(
                              isSelected: isSelected,
                              activeColor: Theme.of(context).primaryColor,
                              borderColor: Theme.of(context).iconTheme.color!,
                              onTap: () => _toggleSelection(context),
                            ),
                          _buildDosyaOnizleme(dosyauzantisi),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  pathinfo.basename(widget.file.path).length >
                                          20
                                      ? '${pathinfo.basename(widget.file.path).substring(0, 20)}...'
                                      : pathinfo.basename(widget.file.path),
                                  style: Theme.of(context).textTheme.bodyLarge,
                                ),
                                _buildMetadataSubtitle(context),
                              ],
                            ),
                          ),
                          const Icon(Icons.chevron_right),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildDosyaOnizleme(String dosyauzantisi) {
    final thumbnailPathListenable = _thumbnailPathListenable;
    if (_supportsThumbnail && thumbnailPathListenable != null) {
      return ListenableBuilder(
        listenable: thumbnailPathListenable,
        builder: (context, _) {
          final thumbnailPath = thumbnailPathListenable.value;
          if (thumbnailPath == null || thumbnailPath.isEmpty) {
            _scheduleThumbnailPrime();
            return _buildVarsayilanIkon(dosyauzantisi);
          }

          return _buildThumbnailOnizleme(
            thumbnailPath: thumbnailPath,
            dosyauzantisi: dosyauzantisi,
          );
        },
      );
    }

    return _buildVarsayilanIkon(dosyauzantisi);
  }

  Widget _buildMetadataSubtitle(BuildContext context) {
    final metadataListenable = _metadataListenable;
    if (metadataListenable == null) {
      return const Text(unknownFileMetadataPlaceholder);
    }

    return ValueListenableBuilder<FileMetadataModel?>(
      valueListenable: metadataListenable,
      builder: (context, metadata, _) {
        final resolvedMetadata = metadata ?? widget.initialMetadata;
        final subtitle =
            resolvedMetadata == null
                ? unknownFileMetadataPlaceholder
                : formatFileSubtitle(
                  sizeBytes: resolvedMetadata.sizeBytes,
                  modifiedAt: resolvedMetadata.modifiedAt,
                );
        return Text(
          subtitle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.bodyMedium,
        );
      },
    );
  }

  Widget _buildThumbnailOnizleme({
    required String thumbnailPath,
    required String dosyauzantisi,
  }) {
    return Stack(
      alignment: Alignment.center,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: SizedBox(
            width: _previewSize,
            height: _previewSize,
            child: Image.file(
              File(thumbnailPath),
              fit: BoxFit.cover,
              cacheWidth: 120,
              cacheHeight: 120,
              errorBuilder: (context, error, stackTrace) {
                return _buildVarsayilanIkon(dosyauzantisi);
              },
            ),
          ),
        ),
        if (_isVideoFile)
          Container(
            width: 18,
            height: 18,
            decoration: BoxDecoration(
              color: Colors.black45,
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(Icons.play_arrow, color: Colors.white, size: 12),
          ),
      ],
    );
  }

  Widget _buildVarsayilanIkon(String dosyauzantisi) {
    final assetPath =
        dosyauzantisi == '.pdf'
            ? 'assets/pdf.png'
            : _imageExtensions.contains(dosyauzantisi)
            ? 'assets/image.png'
            : dosyauzantisi == '.doc' || dosyauzantisi == '.docx'
            ? 'assets/doc.png'
            : dosyauzantisi == '.xls' || dosyauzantisi == '.xlsx'
            ? 'assets/xls.png'
            : dosyauzantisi == '.ppt' || dosyauzantisi == '.pptx'
            ? 'assets/ppt.png'
            : dosyauzantisi == '.txt'
            ? 'assets/txt.png'
            : dosyauzantisi == '.mp3'
            ? 'assets/mp3.png'
            : _videoExtensions.contains(dosyauzantisi)
            ? 'assets/mp4.png'
            : dosyauzantisi == '.zip' ||
                dosyauzantisi == '.rar' ||
                dosyauzantisi == '.7z'
            ? 'assets/zip.png'
            : 'assets/file.png';

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Image.asset(
        assetPath,
        width: _previewSize,
        height: _previewSize,
        fit: BoxFit.cover,
      ),
    );
  }

  Future<void> unzipFile(File zipFile) async {
    final directory = await getExternalStorageDirectory();
    final targetPath = pathinfo.join(directory!.path, 'unzip');

    final targetDir = Directory(targetPath);
    if (!await targetDir.exists()) {
      await targetDir.create(recursive: true);
    }

    final bytes = await zipFile.readAsBytes();
    final archive = ZipDecoder().decodeBytes(bytes);

    for (final file in archive) {
      final filename = pathinfo.join(targetPath, file.name);
      if (file.isFile) {
        final outFile = File(filename);
        await outFile.create(recursive: true);
        await outFile.writeAsBytes(file.content as List<int>);
      } else {
        await Directory(filename).create(recursive: true);
      }
    }

    debugPrint('ZIP basariyla acildi: $targetPath');
  }
}

class _SelectionIndicator extends StatelessWidget {
  const _SelectionIndicator({
    required this.isSelected,
    required this.activeColor,
    required this.borderColor,
    required this.onTap,
  });

  final bool isSelected;
  final Color activeColor;
  final Color borderColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 25,
            height: 25,
            decoration: BoxDecoration(
              color: isSelected ? activeColor : Colors.transparent,
              border: Border.all(width: 3, color: borderColor),
              borderRadius: BorderRadius.circular(30),
            ),
          ),
          const SizedBox(width: 10),
        ],
      ),
    );
  }
}
