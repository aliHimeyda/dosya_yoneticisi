package com.example.dosya_gezgini

import android.net.TrafficStats
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterFragmentActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            NETWORK_STATS_CHANNEL
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                GET_NETWORK_BYTES_METHOD -> {
                    val rxBytes = TrafficStats.getTotalRxBytes()
                    val txBytes = TrafficStats.getTotalTxBytes()

                    if (rxBytes == TrafficStats.UNSUPPORTED.toLong() ||
                        txBytes == TrafficStats.UNSUPPORTED.toLong()
                    ) {
                        result.error(
                            "UNAVAILABLE",
                            "Network statistics are unavailable on this device.",
                            null
                        )
                    } else {
                        result.success(
                            mapOf(
                                "rxBytes" to rxBytes,
                                "txBytes" to txBytes,
                            )
                        )
                    }
                }

                else -> result.notImplemented()
            }
        }
    }

    companion object {
        private const val NETWORK_STATS_CHANNEL = "com.dosya_gezgini/network_stats"
        private const val GET_NETWORK_BYTES_METHOD = "getNetworkBytes"
    }
}
