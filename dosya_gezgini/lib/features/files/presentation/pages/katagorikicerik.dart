import 'package:dosya_gezgini/features/files/presentation/models/folder_route_data.dart';
import 'package:dosya_gezgini/features/files/presentation/pages/klasoricerigisayfasi.dart';
import 'package:flutter/material.dart';

class Katagorikicerik extends StatelessWidget {
  const Katagorikicerik({super.key, this.folder});

  final FolderRouteData? folder;

  @override
  Widget build(BuildContext context) {
    return Klasoricerigisayfasi(folder: folder);
  }
}
