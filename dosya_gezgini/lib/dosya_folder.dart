import 'dart:io';
import 'package:dosya_gezgini/folderleragaci.dart';
import 'package:dosya_gezgini/router.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:path/path.dart' as pathinfo;
import 'package:flutter_animate/flutter_animate.dart';

class Klasor extends StatelessWidget {
  final FolderNode klasor;
  final String name;
  final String path;
  const Klasor({
    super.key,
    required this.name,
    required this.path,
    required this.klasor,
  });

  // final FileStat olusturulmatarihi;
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Animate(
        effects: [FadeEffect(duration: Duration(milliseconds: 100))],
        child: GestureDetector(
          onTap: () {
            context.push(Paths.klasoricerigisayfasi, extra: klasor);
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
                  Image.asset('assets/folder.png', width: 40, height: 40),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          pathinfo.basename(path).length > 20
                              ? "${pathinfo.basename(path).substring(0, 20)}..."
                              : pathinfo.basename(path),
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                        klasor.olusumtarihi == null
                            ? Row(
                              children: [
                                Text(
                                  '${(klasor.filechildren.length + klasor.folderchildren.length)} | ',
                                ),
                                SizedBox(
                                  width: 15,
                                  height: 15,
                                  child: CircularProgressIndicator(),
                                ),
                              ],
                            )
                            : Text(
                              '${(klasor.filechildren.length + klasor.folderchildren.length)} | ${klasor.formatlanmistarih}',
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

class _DosyaState extends State<Dosya> {
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
  Widget build(BuildContext context) {
    String dosyauzantisi = pathinfo.extension(widget.file.path);

    return Center(
      child: Animate(
        effects: [FadeEffect(duration: Duration(milliseconds: 100))],
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
    );
  }
}

// class Dosya extends StatelessWidget {
//   final String name;
//   final String path;
//   final String
//   const Dosya({super.key, required this.name, required this.path});

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: Transform(
//         transform: Matrix4.translationValues(0, -20, 0),
//         child: Container(
//           width: MediaQuery.of(context).size.width - 20,
//           height: MediaQuery.of(context).size.height / 10,
//           decoration: BoxDecoration(
//             border: Border.all(width: 1, color: AppColors.koyuGri),
//           ),
//           child: Padding(
//             padding: const EdgeInsets.all(10),
//             child: Row(
//               children: [
//                 Image.asset('assets/folder.png', width: 40, height: 40),
//                 const SizedBox(width: 10),
//                 Expanded(
//                   child: Column(
//                     mainAxisAlignment: MainAxisAlignment.center,
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Text(
//                         'klasor ismi',
//                         style: Theme.of(context).textTheme.bodyLarge,
//                       ),
//                       Text('icindeki cocuk s. | olus. tarihi'),
//                     ],
//                   ),
//                 ),
//                 Icon(Icons.chevron_right),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }
