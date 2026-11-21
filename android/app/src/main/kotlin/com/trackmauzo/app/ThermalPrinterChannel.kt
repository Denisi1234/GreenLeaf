package com.trackmauzo.app

import android.Manifest
import android.annotation.SuppressLint
import android.app.Activity
import android.bluetooth.BluetoothAdapter
import android.bluetooth.BluetoothManager
import android.content.Context
import android.content.pm.PackageManager
import android.os.Build
import android.os.Handler
import android.os.Looper
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel
import java.io.IOException
import java.util.UUID
import java.util.concurrent.Executors

object ThermalPrinterChannel {
    private const val CHANNEL = "trackmauzo/thermal_printer"
    private const val PERMISSION_REQUEST_CODE = 4209
    private val SPP_UUID: UUID = UUID.fromString("00001101-0000-1000-8000-00805F9B34FB")
    private val executor = Executors.newSingleThreadExecutor()
    private val mainHandler = Handler(Looper.getMainLooper())
    private var pendingPermissionResult: MethodChannel.Result? = null

    fun register(messenger: BinaryMessenger, activity: Activity) {
        MethodChannel(messenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "isBluetoothAvailable" -> {
                    result.success(adapter(activity) != null)
                }

                "isBluetoothEnabled" -> {
                    val bt = adapter(activity)
                    result.success(bt != null && bt.isEnabled)
                }

                "requestPermissions" -> {
                    handlePermissionRequest(activity, result)
                }

                "listPairedPrinters" -> {
                    listPairedPrinters(activity, result)
                }

                "printBytes" -> {
                    val address = call.argument<String>("address")
                    val bytes = call.argument<ByteArray>("bytes")
                    if (address.isNullOrBlank() || bytes == null || bytes.isEmpty()) {
                        result.error("invalid_args", "Printer address and receipt bytes are required", null)
                        return@setMethodCallHandler
                    }
                    printBytes(activity, address, bytes, result)
                }

                else -> result.notImplemented()
            }
        }
    }

    fun onRequestPermissionsResult(
        requestCode: Int,
        grantResults: IntArray
    ): Boolean {
        if (requestCode != PERMISSION_REQUEST_CODE) return false
        val pending = pendingPermissionResult
        pendingPermissionResult = null
        if (pending != null) {
            val granted = grantResults.isNotEmpty() &&
                grantResults.all { it == PackageManager.PERMISSION_GRANTED }
            pending.success(granted)
        }
        return true
    }

    private fun adapter(context: Context): BluetoothAdapter? {
        val manager = context.getSystemService(Context.BLUETOOTH_SERVICE) as? BluetoothManager
        return manager?.adapter
    }

    private fun requiredPermissions(): Array<String> {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            arrayOf(
                Manifest.permission.BLUETOOTH_CONNECT,
                Manifest.permission.BLUETOOTH_SCAN
            )
        } else {
            emptyArray()
        }
    }

    private fun hasBluetoothPermissions(context: Context): Boolean {
        val perms = requiredPermissions()
        return perms.all {
            ContextCompat.checkSelfPermission(context, it) == PackageManager.PERMISSION_GRANTED
        }
    }

    private fun handlePermissionRequest(activity: Activity, result: MethodChannel.Result) {
        val perms = requiredPermissions()
        if (perms.isEmpty() || hasBluetoothPermissions(activity)) {
            result.success(true)
            return
        }
        if (pendingPermissionResult != null) {
            result.error("busy", "A Bluetooth permission prompt is already open", null)
            return
        }
        pendingPermissionResult = result
        ActivityCompat.requestPermissions(activity, perms, PERMISSION_REQUEST_CODE)
    }

    @SuppressLint("MissingPermission")
    private fun listPairedPrinters(activity: Activity, result: MethodChannel.Result) {
        if (!hasBluetoothPermissions(activity)) {
            result.error("permission_denied", "Bluetooth permission is required", null)
            return
        }
        val bt = adapter(activity)
        if (bt == null || !bt.isEnabled) {
            result.error("bluetooth_disabled", "Turn on Bluetooth to use a thermal printer", null)
            return
        }
        val bonded = bt.bondedDevices ?: emptySet()
        val printers = bonded
            .map { device ->
                mapOf(
                    "name" to (device.name?.takeIf { it.isNotBlank() } ?: device.address),
                    "address" to device.address
                )
            }
            .sortedBy { it["name"]?.lowercase().orEmpty() }
        result.success(printers)
    }

    @SuppressLint("MissingPermission")
    private fun printBytes(
        activity: Activity,
        address: String,
        bytes: ByteArray,
        result: MethodChannel.Result
    ) {
        if (!hasBluetoothPermissions(activity)) {
            result.error("permission_denied", "Bluetooth permission is required", null)
            return
        }
        val bt = adapter(activity)
        if (bt == null || !bt.isEnabled) {
            result.error("bluetooth_disabled", "Turn on Bluetooth to print", null)
            return
        }

        executor.execute {
            var socket: android.bluetooth.BluetoothSocket? = null
            try {
                if (bt.isDiscovering) {
                    bt.cancelDiscovery()
                }
                val device = bt.getRemoteDevice(address)
                socket = try {
                    device.createRfcommSocketToServiceRecord(SPP_UUID).apply { connect() }
                } catch (_: IOException) {
                    device.createInsecureRfcommSocketToServiceRecord(SPP_UUID).apply { connect() }
                }

                val out = socket.outputStream
                var offset = 0
                val chunkSize = 512
                while (offset < bytes.size) {
                    val end = minOf(offset + chunkSize, bytes.size)
                    out.write(bytes, offset, end - offset)
                    out.flush()
                    offset = end
                }
                Thread.sleep(150)
                mainHandler.post { result.success(true) }
            } catch (e: Exception) {
                mainHandler.post {
                    result.error(
                        "print_failed",
                        e.message ?: "Failed to print to Bluetooth printer",
                        null
                    )
                }
            } finally {
                try {
                    socket?.close()
                } catch (_: Exception) {
                }
            }
        }
    }
}
