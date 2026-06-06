import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:dosya_gezgini/features/files/state/izinler.dart';
import 'package:dosya_gezgini/features/menu/data/services/downloads_status_service.dart';
import 'package:dosya_gezgini/features/menu/data/services/network_stats_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class MenuStatusProvider extends ChangeNotifier {
  MenuStatusProvider({
    required Izinler izinler,
    required DownloadsStatusService downloadsStatusService,
    required NetworkStatsService networkStatsService,
  }) : _izinler = izinler,
       _downloadsStatusService = downloadsStatusService,
       _networkStatsService = networkStatsService;

  static const String permissionDeniedError = 'permission_denied';
  static const String unreadableError = 'unreadable';
  static const String networkUnavailableError = 'network_unavailable';

  final Izinler _izinler;
  final DownloadsStatusService _downloadsStatusService;
  final NetworkStatsService _networkStatsService;

  bool _didInitialize = false;
  bool _isRouteVisible = true;
  Timer? _networkTimer;
  NetworkBytesSnapshot? _previousNetworkSnapshot;

  int _downloadsSizeBytes = 0;
  bool _isLoadingDownloadsSize = false;
  String? _downloadsSizeError;

  String _downloadSpeedText = '0 KB/s';
  String _uploadSpeedText = '0 KB/s';
  bool _isNetworkStatsAvailable = true;
  String? _networkStatsError;

  int get downloadsSizeBytes => _downloadsSizeBytes;
  String get downloadsSizeText => formatBytes(_downloadsSizeBytes);
  bool get isLoadingDownloadsSize => _isLoadingDownloadsSize;
  String? get downloadsSizeError => _downloadsSizeError;

  String get downloadSpeedText => _downloadSpeedText;
  String get uploadSpeedText => _uploadSpeedText;
  bool get isNetworkStatsAvailable => _isNetworkStatsAvailable;
  String? get networkStatsError => _networkStatsError;

  void initialize() {
    if (_didInitialize) {
      return;
    }

    _didInitialize = true;
    unawaited(loadDownloadsSize());
    startNetworkSpeedTracking();
  }

  void syncRouteVisibility(bool isVisible) {
    if (_isRouteVisible == isVisible) {
      return;
    }

    _isRouteVisible = isVisible;
    if (isVisible) {
      startNetworkSpeedTracking();
      return;
    }

    stopNetworkSpeedTracking(resetSpeeds: false);
  }

  Future<void> loadDownloadsSize() async {
    if (_isLoadingDownloadsSize) {
      return;
    }

    if (!_izinler.hasStoragePermission) {
      _updateDownloadsState(
        isLoading: false,
        error: permissionDeniedError,
      );
      return;
    }

    _updateDownloadsState(isLoading: true, error: null);

    try {
      final bytes = await _downloadsStatusService.getDownloadsSizeBytes();
      _updateDownloadsState(sizeBytes: bytes, isLoading: false, error: null);
    } on FileSystemException catch (error) {
      debugPrint('loadDownloadsSize hata: $error');
      _updateDownloadsState(
        isLoading: false,
        error: _resolveDownloadsError(error),
      );
    } catch (error) {
      debugPrint('loadDownloadsSize beklenmeyen hata: $error');
      _updateDownloadsState(isLoading: false, error: unreadableError);
    }
  }

  void startNetworkSpeedTracking() {
    if (_networkTimer != null || !_isRouteVisible) {
      return;
    }

    unawaited(_sampleNetworkStats());
    _networkTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      unawaited(_sampleNetworkStats());
    });
  }

  void stopNetworkSpeedTracking({bool resetSpeeds = true}) {
    _networkTimer?.cancel();
    _networkTimer = null;
    _previousNetworkSnapshot = null;

    if (resetSpeeds) {
      _updateNetworkState(
        downloadSpeedText: '0 KB/s',
        uploadSpeedText: '0 KB/s',
        isAvailable: _isNetworkStatsAvailable,
        error: _networkStatsError,
      );
    }
  }

  Future<void> _sampleNetworkStats() async {
    try {
      final snapshot = await _networkStatsService.getNetworkBytes();
      if (snapshot == null) {
        _markNetworkUnavailable();
        return;
      }

      if (_previousNetworkSnapshot == null) {
        _previousNetworkSnapshot = snapshot;
        _updateNetworkState(
          downloadSpeedText: '0 KB/s',
          uploadSpeedText: '0 KB/s',
          isAvailable: true,
          error: null,
        );
        return;
      }

      final previousSnapshot = _previousNetworkSnapshot!;
      _previousNetworkSnapshot = snapshot;

      final rxDelta = math.max(0, snapshot.rxBytes - previousSnapshot.rxBytes);
      final txDelta = math.max(0, snapshot.txBytes - previousSnapshot.txBytes);

      _updateNetworkState(
        downloadSpeedText: formatSpeedBytesPerSecond(rxDelta),
        uploadSpeedText: formatSpeedBytesPerSecond(txDelta),
        isAvailable: true,
        error: null,
      );
    } on MissingPluginException catch (error) {
      debugPrint('Network stats plugin eksik: $error');
      _markNetworkUnavailable(stopTracking: true);
    } on PlatformException catch (error) {
      debugPrint('Network stats platform hatasi: $error');
      _markNetworkUnavailable(stopTracking: true);
    } catch (error) {
      debugPrint('Network stats beklenmeyen hata: $error');
      _markNetworkUnavailable();
    }
  }

  void _markNetworkUnavailable({bool stopTracking = false}) {
    _previousNetworkSnapshot = null;
    _updateNetworkState(
      downloadSpeedText: '0 KB/s',
      uploadSpeedText: '0 KB/s',
      isAvailable: false,
      error: networkUnavailableError,
    );
    if (stopTracking) {
      stopNetworkSpeedTracking(resetSpeeds: false);
    }
  }

  String _resolveDownloadsError(FileSystemException error) {
    final osErrorMessage = error.osError?.message.toLowerCase() ?? '';
    if (osErrorMessage.contains('permission') ||
        osErrorMessage.contains('izin')) {
      return permissionDeniedError;
    }

    return unreadableError;
  }

  String formatBytes(int bytes) {
    const kb = 1024;
    const mb = kb * 1024;
    const gb = mb * 1024;

    if (bytes >= gb) {
      return '${_formatCompact(bytes / gb)} GB';
    }
    if (bytes >= mb) {
      return '${_formatCompact(bytes / mb)} MB';
    }
    if (bytes >= kb) {
      return '${_formatCompact(bytes / kb)} KB';
    }

    return '$bytes B';
  }

  String formatSpeedBytesPerSecond(int bytesPerSecond) {
    const kb = 1024;
    const mb = kb * 1024;

    if (bytesPerSecond >= mb) {
      return '${_formatCompact(bytesPerSecond / mb)} MB/s';
    }

    return '${_formatCompact(bytesPerSecond / kb)} KB/s';
  }

  String _formatCompact(double value) {
    final formatted = value.toStringAsFixed(1);
    if (formatted.endsWith('.0')) {
      return formatted.substring(0, formatted.length - 2);
    }
    return formatted;
  }

  void _updateDownloadsState({
    int? sizeBytes,
    bool? isLoading,
    String? error,
  }) {
    var didChange = false;

    if (sizeBytes != null && _downloadsSizeBytes != sizeBytes) {
      _downloadsSizeBytes = sizeBytes;
      didChange = true;
    }
    if (isLoading != null && _isLoadingDownloadsSize != isLoading) {
      _isLoadingDownloadsSize = isLoading;
      didChange = true;
    }
    if (_downloadsSizeError != error) {
      _downloadsSizeError = error;
      didChange = true;
    }

    if (didChange) {
      notifyListeners();
    }
  }

  void _updateNetworkState({
    required String downloadSpeedText,
    required String uploadSpeedText,
    required bool isAvailable,
    required String? error,
  }) {
    var didChange = false;

    if (_downloadSpeedText != downloadSpeedText) {
      _downloadSpeedText = downloadSpeedText;
      didChange = true;
    }
    if (_uploadSpeedText != uploadSpeedText) {
      _uploadSpeedText = uploadSpeedText;
      didChange = true;
    }
    if (_isNetworkStatsAvailable != isAvailable) {
      _isNetworkStatsAvailable = isAvailable;
      didChange = true;
    }
    if (_networkStatsError != error) {
      _networkStatsError = error;
      didChange = true;
    }

    if (didChange) {
      notifyListeners();
    }
  }

  @override
  void dispose() {
    stopNetworkSpeedTracking();
    super.dispose();
  }
}
