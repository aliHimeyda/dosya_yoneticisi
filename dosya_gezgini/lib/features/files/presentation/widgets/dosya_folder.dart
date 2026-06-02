import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive_io.dart';
import 'package:dosya_gezgini/app/router/app_router.dart';
import 'package:dosya_gezgini/features/files/presentation/models/folder_route_data.dart';
import 'package:dosya_gezgini/features/files/state/altislem_provider.dart';
import 'package:dosya_gezgini/features/files/state/dosyaislemleri.dart';
import 'package:dosya_gezgini/features/files/state/folderleragaci.dart';
import 'package:dosya_gezgini/features/files/state/izinler.dart';
import 'package:dosya_gezgini/shared/widgets/app_skeleton.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path/path.dart' as pathinfo;
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:video_thumbnail/video_thumbnail.dart';

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
  @override
  bool get wantKeepAlive => true;

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
                      child: Row(
                        children: [
                          if (isSelectionMode)
                            _SelectionIndicator(
                              isSelected: isSelected,
                              activeColor: Theme.of(context).primaryColor,
                              borderColor: Theme.of(context).iconTheme.color!,
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
                                  style: Theme.of(context).textTheme.bodyLarge,
                                ),
                                widget.klasor.olusumtarihi == null
                                    ? Row(
                                      children: [
                                        Text('${widget.klasor.childCount} | '),
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
                                      '${widget.klasor.childCount} | ${widget.klasor.formatlanmistarih}',
                                    ),
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
}

class Dosya extends StatefulWidget {
  const Dosya({super.key, required this.file});

  final File file;

  @override
  State<Dosya> createState() => _DosyaState();
}

class _DosyaState extends State<Dosya> with AutomaticKeepAliveClientMixin {
  static const double _previewSize = 40;
  static final Map<String, Future<Uint8List?>> _videoThumbnailCache = {};
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

  late List<String> dosyabilgisi = [];
  Future<Uint8List?>? _videoThumbnailFuture;

  @override
  void initState() {
    super.initState();
    bilgileriaktar();
    if (_isVideoFile) {
      _videoThumbnailFuture = _videoThumbnailCache.putIfAbsent(
        widget.file.path,
        () => VideoThumbnail.thumbnailData(
          video: widget.file.path,
          imageFormat: ImageFormat.JPEG,
          maxWidth: 128,
          quality: 60,
        ),
      );
    }
  }

  void bilgileriaktar() async {
    dosyabilgisi = await dosyabilgileri(widget.file.path);
  }

  Future<List<String>> dosyabilgileri(String dosyayolu) async {
    final stat = await FileStat.stat(dosyayolu);
    return [
      (stat.size / (1024 * 1024 * 1024)).toString(),
      stat.modified.toString(),
    ];
  }

  @override
  bool get wantKeepAlive => true;

  String get _dosyaUzantisi =>
      pathinfo.extension(widget.file.path).toLowerCase();
  bool get _isImageFile => _imageExtensions.contains(_dosyaUzantisi);
  bool get _isVideoFile => _videoExtensions.contains(_dosyaUzantisi);

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
                                const Text(' GB | '),
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
    if (_isImageFile) {
      return _buildResimOnizleme();
    }

    if (_isVideoFile && _videoThumbnailFuture != null) {
      return _buildVideoOnizleme();
    }

    return _buildVarsayilanIkon(dosyauzantisi);
  }

  Widget _buildResimOnizleme() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        width: _previewSize,
        height: _previewSize,
        child: Image.file(
          widget.file,
          fit: BoxFit.cover,
          cacheWidth: 120,
          cacheHeight: 120,
          frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
            if (wasSynchronouslyLoaded || frame != null) {
              return child;
            }
            return _buildVarsayilanIkon(_dosyaUzantisi);
          },
          errorBuilder: (context, error, stackTrace) {
            return _buildVarsayilanIkon(_dosyaUzantisi);
          },
        ),
      ),
    );
  }

  Widget _buildVideoOnizleme() {
    return FutureBuilder<Uint8List?>(
      future: _videoThumbnailFuture,
      builder: (context, snapshot) {
        final thumbnail = snapshot.data;
        if (snapshot.connectionState != ConnectionState.done ||
            thumbnail == null) {
          return _buildVarsayilanIkon(_dosyaUzantisi);
        }

        return Stack(
          alignment: Alignment.center,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.memory(
                thumbnail,
                width: _previewSize,
                height: _previewSize,
                fit: BoxFit.cover,
                cacheWidth: 120,
                cacheHeight: 120,
              ),
            ),
            Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                color: Colors.black45,
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Icon(
                Icons.play_arrow,
                color: Colors.white,
                size: 12,
              ),
            ),
          ],
        );
      },
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
