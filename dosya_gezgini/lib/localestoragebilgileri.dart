import 'package:disk_space_2/disk_space_2.dart';
import 'package:flutter/material.dart';

class Localestoragebilgileri extends ChangeNotifier {
  late double totalspace = 0;
  late double freespace = 0;
  late double usedspace = 0;

  Future<void> depolamabilgilernigetir() async {
    try {
      double? total = await DiskSpace.getTotalDiskSpace;
      double? free = await DiskSpace.getFreeDiskSpace;
      if (total != null && free != null) {
        totalspace = total / 1024;
        freespace = free / 1024;
        usedspace = (total - free) / 1024;
        notifyListeners();
      }
    } catch (e) {
      totalspace = 0;
      freespace = 0;
      usedspace = 0;
      notifyListeners();
      print('hata $e');
    }
  }
}
