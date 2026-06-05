class CleaningConstants {
  CleaningConstants._();

  static const Duration staleFileAge = Duration(days: 30);
  static const int largeFileThresholdBytes = 100 * 1024 * 1024;
  static const int scanYieldEveryFiles = 40;
}
