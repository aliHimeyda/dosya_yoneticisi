import 'dart:io';
import 'package:dosya_gezgini/altislemprovider.dart';
import 'package:dosya_gezgini/anasayfaicerigi.dart';
import 'package:dosya_gezgini/dosyaislemleri.dart';
import 'package:dosya_gezgini/folderleragaci.dart';
import 'package:dosya_gezgini/router.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:go_router/go_router.dart';
import 'package:path/path.dart' as pathinfo;
import 'package:flutter_animate/flutter_animate.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
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
          onTap: () {
            Provider.of<Izinler>(
              context,
              listen: false,
            ).fileTree.ensongezilenfolders.add(widget.klasor);
            Provider.of<Izinler>(
              context,
              listen: false,
            ).setCurrentFolder(widget.klasor);
            debugPrint(
              'acilan klasor : ${Provider.of<Izinler>(context, listen: false).getCurrentFolder!.name}',
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
  late List<String> dosyabilgisi = [];
  @override
  void initState() {
    bilgileriaktar();
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
  @override
  Widget build(BuildContext context) {
    if (!context.watch<Altislemprovider>().anahtar) {
      setState(() {
        secilmismi = false;
      });
    }
    super.build(context);
    String dosyauzantisi = pathinfo.extension(widget.file.path);

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
            Provider.of<Izinler>(
              context,
              listen: false,
            ).fileTree.ensongezilenfiles.add(widget.file);
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
                  dosyauzantisi == '.pdf'
                      ? Image.asset('assets/pdf.png', width: 40, height: 40)
                      : dosyauzantisi == '.png' || dosyauzantisi == '.jpg'
                      ? Image.asset('assets/image.png', width: 40, height: 40)
                      : dosyauzantisi == '.doc' || dosyauzantisi == '.docx'
                      ? Image.asset('assets/doc.png', width: 40, height: 40)
                      : dosyauzantisi == '.xls' || dosyauzantisi == '.xlsx'
                      ? Image.asset('assets/xls.png', width: 40, height: 40)
                      : dosyauzantisi == '.ppt' || dosyauzantisi == '.pptx'
                      ? Image.asset('assets/ppt.png', width: 40, height: 40)
                      : dosyauzantisi == '.txt'
                      ? Image.asset('assets/txt.png', width: 40, height: 40)
                      : dosyauzantisi == '.mp3'
                      ? Image.asset('assets/mp3.png', width: 40, height: 40)
                      : dosyauzantisi == '.mp4'
                      ? Image.asset('assets/mp4.png', width: 40, height: 40)
                      : dosyauzantisi == '.zip'
                      ? Image.asset('assets/zip.png', width: 40, height: 40)
                      : Image.asset('assets/file.png', width: 40, height: 40),
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
