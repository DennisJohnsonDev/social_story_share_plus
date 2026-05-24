package io.github.dennisjohnsondev.social_story_share_plus

import android.app.Activity
import android.content.ComponentName
import android.content.ContentValues
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.net.Uri
import android.os.Build
import android.os.Environment
import android.provider.MediaStore
import android.util.Log
import androidx.core.content.FileProvider
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import java.io.File
import java.io.FileOutputStream

class SocialStorySharePlusPlugin : FlutterPlugin, MethodCallHandler, ActivityAware {

    private lateinit var channel: MethodChannel
    private lateinit var context: Context
    private var activity: Activity? = null

    companion object {
        private const val TAG = "SocialStorySharePlus"
        private const val INSTAGRAM_PACKAGE = "com.instagram.android"
        private const val FACEBOOK_PACKAGE = "com.facebook.katana"
        private const val WHATSAPP_PACKAGE = "com.whatsapp"
    }

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(binding.binaryMessenger, "social_story_share_plus")
        channel.setMethodCallHandler(this)
        context = binding.applicationContext
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activity = binding.activity
    }

    override fun onDetachedFromActivity() {
        activity = null
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        activity = binding.activity
    }

    override fun onDetachedFromActivityForConfigChanges() {
        activity = null
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "shareToInstagramStories" -> handleInstagramShare(call, result)
            "shareToInstagramDirect" -> shareToInstagramDirect(call.argument<String>("text"), result)
            "shareToFacebookStories" -> handleFacebookShare(call, result)
            "shareToWhatsAppStatus" -> {
                val imagePath = call.argument<String>("imagePath")
                if (imagePath == null) {
                    result.error("INVALID_ARGUMENTS", "Image path is required", null)
                    return
                }
                shareToWhatsAppStatus(imagePath, result)
            }
            "saveToGallery" -> handleSaveToGallery(call, result)
            "isInstagramInstalled" -> result.success(isPackageInstalled(INSTAGRAM_PACKAGE))
            "isFacebookInstalled" -> result.success(isPackageInstalled(FACEBOOK_PACKAGE))
            "isWhatsAppInstalled" -> result.success(isPackageInstalled(WHATSAPP_PACKAGE))
            else -> result.notImplemented()
        }
    }

    // --- App detection ---

    private fun isPackageInstalled(packageName: String): Boolean {
        return try {
            context.packageManager.getPackageInfo(packageName, 0)
            true
        } catch (e: PackageManager.NameNotFoundException) {
            false
        }
    }

    // --- Instagram Stories ---

    private fun handleInstagramShare(call: MethodCall, result: Result) {
        if (!isPackageInstalled(INSTAGRAM_PACKAGE)) {
            result.error("INSTAGRAM_NOT_INSTALLED", "Instagram is not installed", null)
            return
        }

        val stickerPath = call.argument<String>("stickerPath")
        if (stickerPath == null) {
            result.error("INVALID_ARGUMENTS", "Sticker path is required", null)
            return
        }

        val act = activity ?: run {
            result.error("ACTIVITY_NOT_AVAILABLE", "Activity is not available", null)
            return
        }

        try {
            val stickerUri = getUriForFile(stickerPath)
            val intent = Intent("com.instagram.share.ADD_TO_STORY").apply {
                flags = Intent.FLAG_GRANT_READ_URI_PERMISSION
                setPackage(INSTAGRAM_PACKAGE)
                putExtra("interactive_asset_uri", stickerUri)

                val backgroundImagePath = call.argument<String>("backgroundImagePath")
                if (backgroundImagePath != null) {
                    val backgroundUri = getUriForFile(backgroundImagePath)
                    setDataAndType(backgroundUri, "image/*")
                    act.grantUriPermission(INSTAGRAM_PACKAGE, backgroundUri, Intent.FLAG_GRANT_READ_URI_PERMISSION)
                } else {
                    type = "image/*"
                    putExtra("top_background_color", call.argument<String>("backgroundTopColor") ?: "#FFFFFF")
                    putExtra("bottom_background_color", call.argument<String>("backgroundBottomColor") ?: "#FFFFFF")
                }
            }

            act.grantUriPermission(INSTAGRAM_PACKAGE, stickerUri, Intent.FLAG_GRANT_READ_URI_PERMISSION)
            startActivity(intent, result)
        } catch (e: Exception) {
            result.error("SHARE_FAILED", e.message, null)
        }
    }

    // --- Instagram Direct ---

    private fun shareToInstagramDirect(text: String?, result: Result) {
        if (text.isNullOrEmpty()) {
            result.error("INVALID_ARGUMENTS", "No message to share", null)
            return
        }
        if (!isPackageInstalled(INSTAGRAM_PACKAGE)) {
            result.error("INSTAGRAM_NOT_INSTALLED", "Instagram is not installed", null)
            return
        }

        try {
            val intent = Intent(Intent.ACTION_SEND).apply {
                setPackage(INSTAGRAM_PACKAGE)
                type = "text/plain"
                putExtra(Intent.EXTRA_TEXT, text)
                putExtra(Intent.EXTRA_SUBJECT, "Check this out")
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            }
            startActivity(intent, result)
        } catch (e: Exception) {
            Log.e(TAG, "Failed to open Instagram Direct", e)
            result.error("SHARE_FAILED", "Failed to open Instagram Direct", null)
        }
    }

    // --- Facebook Stories ---

    private fun handleFacebookShare(call: MethodCall, result: Result) {
        if (!isPackageInstalled(FACEBOOK_PACKAGE)) {
            result.error("FACEBOOK_NOT_INSTALLED", "Facebook is not installed", null)
            return
        }

        val stickerPath = call.argument<String>("stickerPath")
        if (stickerPath == null) {
            result.error("INVALID_ARGUMENTS", "Sticker path is required", null)
            return
        }

        val appId = call.argument<String>("appId")
        if (appId.isNullOrEmpty()) {
            result.error("INVALID_ARGUMENTS", "Facebook appId is required", null)
            return
        }

        val act = activity ?: run {
            result.error("ACTIVITY_NOT_AVAILABLE", "Activity is not available", null)
            return
        }

        try {
            val stickerUri = getUriForFile(stickerPath)
            val intent = Intent("com.facebook.stories.ADD_TO_STORY").apply {
                flags = Intent.FLAG_GRANT_READ_URI_PERMISSION
                setPackage(FACEBOOK_PACKAGE)
                putExtra("interactive_asset_uri", stickerUri)
                putExtra("com.facebook.platform.extra.APPLICATION_ID", appId)

                val backgroundImagePath = call.argument<String>("backgroundImagePath")
                if (backgroundImagePath != null) {
                    val backgroundUri = getUriForFile(backgroundImagePath)
                    setDataAndType(backgroundUri, "image/*")
                    act.grantUriPermission(FACEBOOK_PACKAGE, backgroundUri, Intent.FLAG_GRANT_READ_URI_PERMISSION)
                } else {
                    type = "image/*"
                    putExtra("top_background_color", call.argument<String>("backgroundTopColor") ?: "#000000")
                    putExtra("bottom_background_color", call.argument<String>("backgroundBottomColor") ?: "#000000")
                }
            }

            act.grantUriPermission(FACEBOOK_PACKAGE, stickerUri, Intent.FLAG_GRANT_READ_URI_PERMISSION)
            startActivity(intent, result)
        } catch (e: Exception) {
            result.error("SHARE_FAILED", e.message, null)
        }
    }

    // --- WhatsApp Status ---

    private fun shareToWhatsAppStatus(imagePath: String, result: Result) {
        val act = activity ?: run {
            result.error("ACTIVITY_NOT_AVAILABLE", "Activity is not available", null)
            return
        }
        if (!isPackageInstalled(WHATSAPP_PACKAGE)) {
            result.error("WHATSAPP_NOT_INSTALLED", "WhatsApp is not installed on this device", null)
            return
        }

        try {
            val imageUri = getUriForFile(imagePath)
            act.grantUriPermission(WHATSAPP_PACKAGE, imageUri, Intent.FLAG_GRANT_READ_URI_PERMISSION)

            val statusIntent = Intent().apply {
                action = Intent.ACTION_SEND
                type = "image/*"
                flags = Intent.FLAG_GRANT_READ_URI_PERMISSION or Intent.FLAG_ACTIVITY_NEW_TASK
                putExtra(Intent.EXTRA_STREAM, imageUri)
                putExtra("jid", "status@broadcast")
                component = ComponentName(WHATSAPP_PACKAGE, "com.whatsapp.ContactPicker")
            }

            try {
                act.startActivity(statusIntent)
                result.success(true)
            } catch (e: Exception) {
                Log.d(TAG, "Component-targeted share failed, falling back: ${e.message}")
                val fallback = Intent().apply {
                    action = Intent.ACTION_SEND
                    type = "image/*"
                    flags = Intent.FLAG_GRANT_READ_URI_PERMISSION
                    setPackage(WHATSAPP_PACKAGE)
                    putExtra(Intent.EXTRA_STREAM, imageUri)
                    putExtra("jid", "status@broadcast")
                }
                act.startActivity(fallback)
                result.success(true)
            }
        } catch (e: Exception) {
            result.error("SHARE_FAILED", e.message, null)
        }
    }

    // --- Save to gallery ---

    private fun handleSaveToGallery(call: MethodCall, result: Result) {
        val imageBytes = call.argument<ByteArray>("imageBytes")
        val fileName = call.argument<String>("fileName")
        if (imageBytes == null || fileName == null) {
            result.error("INVALID_ARGUMENTS", "Image bytes and filename required", null)
            return
        }

        try {
            val bitmap = BitmapFactory.decodeByteArray(imageBytes, 0, imageBytes.size)
                ?: run {
                    result.error("IMAGE_ERROR", "Could not decode image bytes", null)
                    return
                }

            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                val values = ContentValues().apply {
                    put(MediaStore.Images.Media.DISPLAY_NAME, fileName)
                    put(MediaStore.Images.Media.MIME_TYPE, "image/png")
                    put(MediaStore.Images.Media.RELATIVE_PATH, Environment.DIRECTORY_PICTURES + "/SocialShare")
                    put(MediaStore.Images.Media.IS_PENDING, 1)
                }
                val resolver = context.contentResolver
                val uri = resolver.insert(MediaStore.Images.Media.EXTERNAL_CONTENT_URI, values)
                if (uri == null) {
                    result.error("SAVE_FAILED", "Failed to create MediaStore entry", null)
                    return
                }
                resolver.openOutputStream(uri)?.use { stream ->
                    bitmap.compress(Bitmap.CompressFormat.PNG, 100, stream)
                }
                values.clear()
                values.put(MediaStore.Images.Media.IS_PENDING, 0)
                resolver.update(uri, values, null, null)
                result.success(true)
            } else {
                @Suppress("DEPRECATION")
                val picturesDir = Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_PICTURES)
                val appDir = File(picturesDir, "SocialShare").apply {
                    if (!exists()) mkdirs()
                }
                val file = File(appDir, fileName)
                FileOutputStream(file).use { stream ->
                    bitmap.compress(Bitmap.CompressFormat.PNG, 100, stream)
                }
                @Suppress("DEPRECATION")
                val scanIntent = Intent(Intent.ACTION_MEDIA_SCANNER_SCAN_FILE).apply {
                    data = Uri.fromFile(file)
                }
                context.sendBroadcast(scanIntent)
                result.success(true)
            }
            bitmap.recycle()
        } catch (e: Exception) {
            result.error("SAVE_FAILED", e.message, null)
        }
    }

    // --- Helpers ---

    private fun getUriForFile(path: String): Uri {
        val file = File(path)
        return FileProvider.getUriForFile(context, "${context.packageName}.fileprovider", file)
    }

    private fun startActivity(intent: Intent, result: Result) {
        val act = activity ?: run {
            result.error("ACTIVITY_NOT_AVAILABLE", "Activity is not available", null)
            return
        }
        try {
            if (act.packageManager.resolveActivity(intent, 0) != null) {
                act.startActivity(intent)
                result.success(true)
            } else {
                result.error("ACTIVITY_NOT_FOUND", "No suitable activity found", null)
            }
        } catch (e: Exception) {
            result.error("START_ACTIVITY_FAILED", e.message, null)
        }
    }
}
