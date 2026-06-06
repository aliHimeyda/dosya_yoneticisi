import 'package:flutter/services.dart';

class NetworkBytesSnapshot {
  const NetworkBytesSnapshot({required this.rxBytes, required this.txBytes});

  final int rxBytes;
  final int txBytes;
}

class NetworkStatsService {
  const NetworkStatsService();

  static const MethodChannel _channel = MethodChannel(
    'com.dosya_gezgini/network_stats',
  );

  Future<NetworkBytesSnapshot?> getNetworkBytes() async {
    final result = await _channel.invokeMapMethod<String, dynamic>(
      'getNetworkBytes',
    );
    if (result == null) {
      return null;
    }

    final rxBytes = _parseBytes(result['rxBytes']);
    final txBytes = _parseBytes(result['txBytes']);
    if (rxBytes == null || txBytes == null) {
      return null;
    }

    return NetworkBytesSnapshot(rxBytes: rxBytes, txBytes: txBytes);
  }

  int? _parseBytes(dynamic value) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    if (value is String) {
      return int.tryParse(value);
    }
    return null;
  }
}
