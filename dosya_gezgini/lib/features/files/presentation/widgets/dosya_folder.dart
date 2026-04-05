import 'dart:io';
import 'dart:typed_data';
import 'package:dosya_gezgini/app/router/app_router.dart';
import 'package:dosya_gezgini/features/files/state/altislem_provider.dart';
import 'package:dosya_gezgini/features/files/state/dosyaislemleri.dart';
import 'package:dosya_gezgini/features/files/state/folderleragaci.dart';
import 'package:dosya_gezgini/features/files/state/izinler.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:go_router/go_router.dart';
import 'package:path/path.dart' as pathinfo;
import 'package:flutter_animate/flutter_animate.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:video_thumbnail/video_thumbnail.dart';
import 'package:open_filex/open_filex.dart';
import 'package:archive/archive_io.dart';

class Klasor extends StatefulWidget {
  final FolderNode klasor;
  final String name;
  final String path;

  Klasor({
    super.key,
    required this.name,
    required this.path,
    required this.klasor,
  });
  @override
  State<Klasor> createState() => _KlasorState();
}

class _KlasorState extends State<Klasor> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  late bool secilmismi = false;
  // final FileStat olusturulmatarihi;
  @override
  Widget build(BuildContext context) {
    if (!context.watch<Altislemprovider>().anahtar) {
      setState(() {
        secilmismi = false;
      });
    }
    super.build(context);
    return Center(
      child: Animate(
        effects: [FadeEffect(duration: Duration(milliseconds: 100))],
        child: GestureDetector(
          onLongPress: () {
            Provider.of<Altislemprovider>(
              context,
              listen: false,
            ).changeanahtar();
            secilmismi = !secilmismi;
            if (secilmismi) {
              if (!context.read<Dosyaislemleri>().folderlistesi.contains(
                widget.klasor,
              )) {
                context.read<Dosyaislemleri>().folderlistesi.add(widget.klasor);
              }
            }
          },
          onTap: () async {
            final izinler = Provider.of<Izinler>(context, listen: false);
            izinler.fileTree.ensongezilenfolders.add(widget.klasor);
            await izinler.setCurrentFolder(widget.klasor);
            debugPrint(
              'acilan klasor : ${izinler.getCurrentFolder!.name}',
            );

            context.push(Paths.klasoricerigisayfasi);
          },
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
                  context.watch<Altislemprovider>().anahtar
                      ? GestureDetector(
                        onTap: () {
                          setState(() {
                            secilmismi = !secilmismi;
                          });
                          if (secilmismi) {
                            if (!context
                                .read<Dosyaislemleri>()
                                .folderlistesi
                                .contains(widget.klasor)) {
                              context.read<Dosyaislemleri>().folderlistesi.add(
                                widget.klasor,
                              );
                            }
                          } else if (context
                              .read<Dosyaislemleri>()
                              .folderlistesi
                              .contains(widget.klasor)) {
                            context.read<Dosyaislemleri>().folderlistesi.remove(
                              widget.klasor,
                            );
                          }
                          debugPrint('tiklandi');
                        },
                        child: Row(
                          children: [
                            Container(
                              width: 25,
                              height: 25,
                              decoration: BoxDecoration(
                                color:
                                    secilmismi
                                        ? Theme.of(context).primaryColor
                                        : Colors.transparent,
                                border: Border.all(
                                  width: 3,
                                  color: Theme.of(context).iconTheme.color!,
                                ),

                                borderRadius: BorderRadius.circular(30),
                              ),
                            ),
                            SizedBox(width: 10),
                          ],
                        ),
                      )
                      : SizedBox(),

                  Image.asset('assets/folder.png', width: 40, height: 40),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          pathinfo.basename(widget.path).length > 20
                              ? "${pathinfo.basename(widget.path).substring(0, 20)}..."
                              : pathinfo.basename(widget.path),
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                        widget.klasor.olusumtarihi == null
                            ? Row(
                              children: [
                                Text(
                                  '${(widget.klasor.filechildren.length + widget.klasor.folderchildren.length)} | ',
                                ),
                                SizedBox(
                                  width: 15,
                                  height: 15,
                                  child: CircularProgressIndicator(),
                                ),
                              ],
                            )
                            : Text(
                              '${(widget.klasor.filechildren.length + widget.klasor.folderchildren.length)} | ${widget.klasor.formatlanmistarih}',
                            ),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class Dosya extends StatefulWidget {
  final File file;
  const Dosya({super.key, required this.file});

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
    super.initState();
  }

  void bilgileriaktar() async {
    dosyabilgisi = await dosyabilgileri(widget.file.path);
  }

  Future<List<String>> dosyabilgileri(String dosyayolu) async {
    FileStat stat = await FileStat.stat(dosyayolu);
    return [
      (stat.size / (1024 * 1024 * 1024)).toString(),
      stat.modified.toString(),
    ];
  }

  @override
  bool get wantKeepAlive => true;

  late bool secilmismi = false;
  String get _dosyaUzantisi => pathinfo.extension(widget.file.path).toLowerCase();
  bool get _isImageFile => _imageExtensions.contains(_dosyaUzantisi);
  bool get _isVideoFile => _videoExtensions.contains(_dosyaUzantisi);

  @override
  Widget build(BuildContext context) {
    if (!context.watch<Altislemprovider>().anahtar) {
      setState(() {
        secilmismi = false;
      });
    }
    super.build(context);
    final dosyauzantisi = _dosyaUzantisi;

    return Center(
      child: Animate(
        effects: [FadeEffect(duration: Duration(milliseconds: 100))],
        child: GestureDetector(
          onLongPress: () {
            Provider.of<Altislemprovider>(
              context,
              listen: false,
            ).changeanahtar();
            secilmismi = !secilmismi;
            if (secilmismi) {
              if (!context.read<Dosyaislemleri>().filelistesi.contains(
                widget.file,
              )) {
                context.read<Dosyaislemleri>().filelistesi.add(widget.file);
              }
            }
          },
          onTap: () async {
            final izinler = Provider.of<Izinler>(context, listen: false);
            izinler.fileTree.ensongezilenfiles.add(widget.file);
            izinler.fileTree.ekraniguncelle();
            try {
              if (dosyauzantisi == '.zip') {
                await unzipFile(widget.file);
              } else {
                debugPrint('${widget.file.path} konumlu dosya aciliyor');
                await OpenFilex.open(widget.file.path);
              }
            } catch (e) {
              debugPrint('Dosya açılamadı : $e');
            }
          },
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
                  context.watch<Altislemprovider>().anahtar
                      ? GestureDetector(
                        onTap: () {
                          setState(() {
                            secilmismi = !secilmismi;
                          });
                          if (secilmismi) {
                            if (!context
                                .read<Dosyaislemleri>()
                                .filelistesi
                                .contains(widget.file)) {
                              context.read<Dosyaislemleri>().filelistesi.add(
                                widget.file,
                              );
                            }
                          } else if (context
                              .read<Dosyaislemleri>()
                              .filelistesi
                              .contains(widget.file)) {
                            context.read<Dosyaislemleri>().filelistesi.remove(
                              widget.file,
                            );
                          }
                          debugPrint(
                            'tiklandi  boyut : ${context.read<Dosyaislemleri>().filelistesi.length}',
                          );
                        },
                        child: Row(
                          children: [
                            Container(
                              width: 25,
                              height: 25,
                              decoration: BoxDecoration(
                                color:
                                    secilmismi
                                        ? Theme.of(context).primaryColor
                                        : Colors.transparent,
                                border: Border.all(
                                  width: 3,
                                  color: Theme.of(context).iconTheme.color!,
                                ),

                                borderRadius: BorderRadius.circular(30),
                              ),
                            ),
                            SizedBox(width: 10),
                          ],
                        ),
                      )
                      : SizedBox(),
                  _buildDosyaOnizleme(dosyauzantisi),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          pathinfo.basename(widget.file.path).length > 20
                              ? "${pathinfo.basename(widget.file.path).substring(0, 20)}..."
                              : pathinfo.basename(widget.file.path),
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                        Text(' GB | '),
                        // ${dosyabilgisi[1]}
                        // ${dosyabilgisi[0] ?? 0}
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right),
                ],
              ),
            ),
          ),
        ),
      ),
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
    final targetPath = pathinfo.join(directory!.path, "unzip");

    // Eğer klasör yoksa oluştur
    final targetDir = Directory(targetPath);
    if (!await targetDir.exists()) {
      await targetDir.create(recursive: true);
    }

    // ZIP dosyasını oku
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

    print("ZIP başarıyla açıldı: $targetPath");
  }
}
