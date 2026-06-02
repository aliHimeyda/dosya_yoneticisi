import 'package:hive_flutter/hive_flutter.dart';

class HiveService {
  Future<void> init() async {
    await Hive.initFlutter();
  }

  Future<Box<Map<dynamic, dynamic>>> openMapBox(String name) async {
    if (Hive.isBoxOpen(name)) {
      return Hive.box<Map<dynamic, dynamic>>(name);
    }

    return Hive.openBox<Map<dynamic, dynamic>>(name);
  }

  Future<Box<dynamic>> openBox(String name) async {
    if (Hive.isBoxOpen(name)) {
      return Hive.box<dynamic>(name);
    }

    return Hive.openBox<dynamic>(name);
  }

  Future<void> closeAll() async {
    await Hive.close();
  }
}
