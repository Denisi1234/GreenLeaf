package com.evanlu.possystem

import android.util.Log

import android.content.ContentValues
import android.content.ClipData
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import android.os.Environment
import android.provider.MediaStore
import androidx.core.content.FileProvider
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity: FlutterFragmentActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "possystem/share"
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "shareReceiptToWhatsApp" -> {
                    val filePath = call.argument<String>("filePath")
                    val text = call.argument<String>("text").orEmpty()

                    if (filePath.isNullOrBlank()) {
                        result.error("invalid_args", "File path is required", null)
                        return@setMethodCallHandler
                    }

                    shareReceiptToWhatsApp(filePath, text, result)
                }

                else -> result.notImplemented()
            }
        }

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "possystem/report_downloads"
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "savePdfToDownloads" -> {
                    val fileName = call.argument<String>("fileName")
                    val bytes = call.argument<ByteArray>("bytes")

                    if (fileName.isNullOrBlank()) {
                        result.error("invalid_args", "File name is required", null)
                        return@setMethodCallHandler
                    }

                    if (bytes == null || bytes.isEmpty()) {
                        result.error("invalid_args", "PDF bytes are required", null)
                        return@setMethodCallHandler
                    }

                    savePdfToDownloads(fileName, bytes, result)
                }

                else -> result.notImplemented()
            }
        }

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "possystem/report_share"
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "sharePdfFromBytes" -> {
                    val fileName = call.argument<String>("fileName")
                    val bytes = call.argument<ByteArray>("bytes")
                    val subject = call.argument<String>("subject").orEmpty()
                    val text = call.argument<String>("text").orEmpty()

                    if (fileName.isNullOrBlank()) {
                        result.error("invalid_args", "File name is required", null)
                        return@setMethodCallHandler
                    }

                    if (bytes == null || bytes.isEmpty()) {
                        result.error("invalid_args", "PDF bytes are required", null)
                        return@setMethodCallHandler
                    }

                    sharePdfFromBytes(fileName, bytes, subject, text, result)
                }

                else -> result.notImplemented()
            }
        }
    }

    private fun savePdfToDownloads(
        fileName: String,
        bytes: ByteArray,
        result: MethodChannel.Result
    ) {
        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                val resolver = applicationContext.contentResolver
                val collection = MediaStore.Downloads.getContentUri(MediaStore.VOLUME_EXTERNAL_PRIMARY)
                val contentValues = ContentValues().apply {
                    put(MediaStore.MediaColumns.DISPLAY_NAME, fileName)
                    put(MediaStore.MediaColumns.MIME_TYPE, "application/pdf")
                    put(MediaStore.MediaColumns.RELATIVE_PATH, Environment.DIRECTORY_DOWNLOADS)
                }

                val uri = resolver.insert(collection, contentValues)
                    ?: throw IllegalStateException("Unable to create download entry")

                resolver.openOutputStream(uri)?.use { output ->
                    output.write(bytes)
                    output.flush()
                } ?: throw IllegalStateException("Unable to open download stream")

                result.success("Downloads/$fileName")
                return
            }

            val downloadsDirectory = Environment.getExternalStoragePublicDirectory(
                Environment.DIRECTORY_DOWNLOADS
            )
            if (!downloadsDirectory.exists()) {
                downloadsDirectory.mkdirs()
            }
            val targetFile = File(downloadsDirectory, fileName)
            targetFile.outputStream().use { output ->
                output.write(bytes)
                output.flush()
            }
            result.success(targetFile.absolutePath)
        } catch (error: Exception) {
            Log.e("ReportDownload", "Unable to save report PDF", error)
            result.error("save_failed", error.message, null)
        }
    }

    private fun shareReceiptToWhatsApp(
        filePath: String,
        text: String,
        result: MethodChannel.Result
    ) {
        Log.d("ReceiptShare", "shareReceiptToWhatsApp called with filePath: $filePath, text length: ${text.length}")
        try {
            val file = File(filePath)
            if (!file.exists()) {
                Log.e("ReceiptShare", "File does not exist: $filePath")
                result.error("missing_file", "Receipt PDF file was not found", null)
                return
            }
            Log.d("ReceiptShare", "File exists: $filePath")

            val uri = FileProvider.getUriForFile(
                this,
                "${applicationContext.packageName}.fileprovider",
                file
            )
            Log.d("ReceiptShare", "FileProvider URI: $uri")

            val whatsappPackages = listOf("com.whatsapp", "com.whatsapp.w4b")
            var targetPackage: String? = null

            for (pkg in whatsappPackages) {
                try {
                    packageManager.getPackageInfo(pkg, PackageManager.GET_ACTIVITIES)
                    targetPackage = pkg
                    break
                } catch (e: PackageManager.NameNotFoundException) {
                    Log.d("ReceiptShare", "$pkg not found.")
                    // Package not found, try next one
                }
            }

            if (targetPackage == null) {
                Log.e("ReceiptShare", "No WhatsApp package found.")
                result.success(false)
                return
            }
            Log.d("ReceiptShare", "Target WhatsApp package found: $targetPackage")

            val intent = Intent(Intent.ACTION_SEND).apply {
                setDataAndType(uri, "application/pdf")
                `package` = targetPackage
                putExtra(Intent.EXTRA_STREAM, uri)
                putExtra(Intent.EXTRA_TEXT, text)
                addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            }

            grantUriPermission(
                targetPackage,
                uri,
                Intent.FLAG_GRANT_READ_URI_PERMISSION
            )
            Log.d("ReceiptShare", "URI permission granted to $targetPackage for $uri")

            startActivity(intent)
            Log.d("ReceiptShare", "WhatsApp activity started successfully.")
            result.success(true)
        } catch (error: Exception) {
            Log.e("ReceiptShare", "Error sharing receipt to WhatsApp: ${error.message}", error)
            result.error("share_failed", error.message, null)
        }
    }

    private fun sharePdfFromBytes(
        fileName: String,
        bytes: ByteArray,
        subject: String,
        text: String,
        result: MethodChannel.Result
    ) {
        try {
            val shareDir = File(cacheDir, "shared_reports")
            if (!shareDir.exists()) {
                shareDir.mkdirs()
            }

            val targetFile = File(shareDir, fileName)
            targetFile.outputStream().use { output ->
                output.write(bytes)
                output.flush()
            }

            val uri = FileProvider.getUriForFile(
                this,
                "${applicationContext.packageName}.fileprovider",
                targetFile
            )

            val intent = Intent(Intent.ACTION_SEND).apply {
                type = "application/pdf"
                putExtra(Intent.EXTRA_STREAM, uri)
                putExtra(Intent.EXTRA_SUBJECT, subject)
                putExtra(Intent.EXTRA_TEXT, text)
                addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                clipData = ClipData.newRawUri(fileName, uri)
            }

            val chooser = Intent.createChooser(intent, "Share Store Report").apply {
                addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
            }

            startActivity(chooser)
            result.success(true)
        } catch (error: Exception) {
            Log.e("ReportShare", "Unable to share report PDF", error)
            result.error("share_failed", error.message, null)
        }
    }
}
