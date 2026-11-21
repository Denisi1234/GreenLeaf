package com.trackmauzo.app

import android.app.Activity
import com.google.mlkit.vision.barcode.common.Barcode
import com.google.mlkit.vision.codescanner.GmsBarcodeScannerOptions
import com.google.mlkit.vision.codescanner.GmsBarcodeScanning
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel

object BarcodeScannerChannel {
    private const val CHANNEL = "trackmauzo/barcode_scanner"

    fun register(messenger: BinaryMessenger, activity: Activity) {
        MethodChannel(messenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "scanBarcode" -> {
                    try {
                        val options = GmsBarcodeScannerOptions.Builder()
                            .setBarcodeFormats(Barcode.FORMAT_ALL_FORMATS)
                            .enableAutoZoom()
                            .build()
                        val scanner = GmsBarcodeScanning.getClient(activity, options)
                        scanner.startScan()
                            .addOnSuccessListener { barcode ->
                                result.success(barcode.rawValue)
                            }
                            .addOnCanceledListener {
                                result.success(null)
                            }
                            .addOnFailureListener { error ->
                                result.error("scan_unavailable", error.message, null)
                            }
                    } catch (e: Exception) {
                        result.error("scan_unavailable", e.message, null)
                    }
                }

                else -> result.notImplemented()
            }
        }
    }
}
