import 'package:dosya_gezgini/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('uygulama temalari hazir geliyor', () {
    expect(AppTheme.lightMode.brightness, Brightness.light);
    expect(AppTheme.darkMode.brightness, Brightness.dark);
  });
}
