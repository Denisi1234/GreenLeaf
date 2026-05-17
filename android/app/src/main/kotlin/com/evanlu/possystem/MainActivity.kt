package com.evanlu.possystem

import android.content.Intent
import android.content.pm.PackageManager
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
    }

    private fun shareReceiptToWhatsApp(
        filePath: String,
        text: String,
        result: MethodChannel.Result
    ) {
        try {
            val file = File(filePath)
            if (!file.exists()) {
                result.error("missing_file", "Receipt PDF file was not found", null)
                return
            }

            val uri = FileProvider.getUriForFile(
                this,
                "${applicationContext.packageName}.fileprovider",
                file
            )

            val whatsappPackages = listOf("com.whatsapp", "com.whatsapp.w4b")
            var targetPackage: String? = null

            for (pkg in whatsappPackages) {
                try {
                    packageManager.getPackageInfo(pkg, PackageManager.GET_ACTIVITIES)
                    targetPackage = pkg
                    break
                } catch (e: PackageManager.NameNotFoundException) {
                    // Package not found, try next one
                }
            }

            if (targetPackage == null) {
                result.success(false)
                return
            }

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

            startActivity(intent)
            result.success(true)
        } catch (error: Exception) {
            result.error("share_failed", error.message, null)
        }
    }
}
