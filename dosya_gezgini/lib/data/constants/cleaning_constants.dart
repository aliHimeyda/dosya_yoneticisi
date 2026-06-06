class CleaningConstants {
  CleaningConstants._();

  static const Duration staleFileAge = Duration(days: 30);
  static const Duration unusedFileAge = Duration(days: 120);
  static const int largeFileThresholdBytes = 100 * 1024 * 1024;
  static const int scanYieldEveryFiles = 40;
  static const List<String> packageExtensions = <String>[
    '.apk',
    '.xapk',
    '.apks',
  ];
  static const List<String> residualExtensions = <String>[
    '.tmp',
    '.temp',
    '.log',
    '.old',
    '.bak',
  ];
  static const List<String> userScanDirectoryNames = <String>[
    'Download',
    'Documents',
  ];
}
