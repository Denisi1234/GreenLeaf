package com.trackmauzo.app

import android.content.Context
import android.security.keystore.KeyGenParameterSpec
import android.security.keystore.KeyProperties
import android.util.Base64
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel
import java.nio.charset.StandardCharsets
import java.security.KeyStore
import javax.crypto.Cipher
import javax.crypto.KeyGenerator
import javax.crypto.SecretKey
import javax.crypto.spec.GCMParameterSpec

object SecureTokenChannel {
    private const val CHANNEL = "trackmauzo/secure_storage"
    private const val ANDROID_KEYSTORE = "AndroidKeyStore"
    private const val KEY_ALIAS = "trackmauzo_session_key_v1"
    private const val PREFS_NAME = "trackmauzo_secure_vault"
    private const val TRANSFORMATION = "AES/GCM/NoPadding"
    private const val GCM_TAG_LENGTH_BITS = 128

    fun register(messenger: BinaryMessenger, context: Context) {
        val appContext = context.applicationContext
        MethodChannel(messenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "write" -> {
                    val key = call.argument<String>("key")
                    val value = call.argument<String>("value")
                    if (key.isNullOrBlank() || value == null) {
                        result.error("invalid_args", "Key and value are required", null)
                        return@setMethodCallHandler
                    }
                    try {
                        writeEncrypted(appContext, key, value)
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("secure_write_failed", e.message, null)
                    }
                }

                "read" -> {
                    val key = call.argument<String>("key")
                    if (key.isNullOrBlank()) {
                        result.error("invalid_args", "Key is required", null)
                        return@setMethodCallHandler
                    }
                    try {
                        result.success(readDecrypted(appContext, key))
                    } catch (e: Exception) {
                        result.error("secure_read_failed", e.message, null)
                    }
                }

                "delete" -> {
                    val key = call.argument<String>("key")
                    if (key.isNullOrBlank()) {
                        result.error("invalid_args", "Key is required", null)
                        return@setMethodCallHandler
                    }
                    appContext
                        .getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
                        .edit()
                        .remove(key)
                        .apply()
                    result.success(true)
                }

                else -> result.notImplemented()
            }
        }
    }

    private fun getOrCreateKey(): SecretKey {
        val keyStore = KeyStore.getInstance(ANDROID_KEYSTORE).apply { load(null) }
        val existing = keyStore.getEntry(KEY_ALIAS, null) as? KeyStore.SecretKeyEntry
        if (existing != null) return existing.secretKey

        val keyGenerator = KeyGenerator.getInstance(
            KeyProperties.KEY_ALGORITHM_AES,
            ANDROID_KEYSTORE
        )
        val spec = KeyGenParameterSpec.Builder(
            KEY_ALIAS,
            KeyProperties.PURPOSE_ENCRYPT or KeyProperties.PURPOSE_DECRYPT
        )
            .setBlockModes(KeyProperties.BLOCK_MODE_GCM)
            .setEncryptionPaddings(KeyProperties.ENCRYPTION_PADDING_NONE)
            .setKeySize(256)
            .build()
        keyGenerator.init(spec)
        return keyGenerator.generateKey()
    }

    private fun writeEncrypted(context: Context, key: String, value: String) {
        val cipher = Cipher.getInstance(TRANSFORMATION)
        cipher.init(Cipher.ENCRYPT_MODE, getOrCreateKey())
        val encrypted = cipher.doFinal(value.toByteArray(StandardCharsets.UTF_8))
        val ivEncoded = Base64.encodeToString(cipher.iv, Base64.NO_WRAP)
        val cipherEncoded = Base64.encodeToString(encrypted, Base64.NO_WRAP)
        context
            .getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            .edit()
            .putString(key, "$ivEncoded:$cipherEncoded")
            .apply()
    }

    private fun readDecrypted(context: Context, key: String): String? {
        val stored = context
            .getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            .getString(key, null)
            ?: return null

        val parts = stored.split(':', limit = 2)
        if (parts.size != 2) return null

        return try {
            val iv = Base64.decode(parts[0], Base64.NO_WRAP)
            val ciphertext = Base64.decode(parts[1], Base64.NO_WRAP)
            val cipher = Cipher.getInstance(TRANSFORMATION)
            cipher.init(
                Cipher.DECRYPT_MODE,
                getOrCreateKey(),
                GCMParameterSpec(GCM_TAG_LENGTH_BITS, iv)
            )
            String(cipher.doFinal(ciphertext), StandardCharsets.UTF_8)
        } catch (_: Exception) {
            null
        }
    }
}
