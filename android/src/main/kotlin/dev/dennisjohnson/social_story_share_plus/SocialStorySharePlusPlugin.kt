package dev.dennisjohnson.social_story_share_plus

import android.Manifest
import android.app.Activity
import android.content.ActivityNotFoundException
import android.content.ComponentName
import android.content.ContentValues
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.graphics.BitmapFactory
import android.media.MediaScannerConnection
import android.net.Uri
import android.os.Build
import android.os.Environment
import android.os.Handler
import android.os.Looper
import android.provider.MediaStore
import android.webkit.MimeTypeMap
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import androidx.core.content.FileProvider
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.plugin.common.PluginRegistry
import java.io.File
import java.util.concurrent.ExecutorService
import java.util.concurrent.Executors

class SocialStorySharePlusPlugin :
    FlutterPlugin,
    MethodCallHandler,
    ActivityAware,
    PluginRegistry.RequestPermissionsResultListener {

    private lateinit var channel: MethodChannel
    private lateinit var context: Context
    private var activityBinding: ActivityPluginBinding? = null
    private var pendingSave: PendingSave? = null

    private val mainHandler by lazy { Handler(Looper.getMainLooper()) }
    private val executor: ExecutorService by lazy { Executors.newSingleThreadExecutor() }

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        context = binding.applicationContext
        channel = MethodChannel(binding.binaryMessenger, "social_story_share_plus")
        channel.setMethodCallHandler(this)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        try {
            when (call.method) {
                "shareToInstagramStories" -> shareToStory(call, result, INSTAGRAM, "com.instagram.share.ADD_TO_STORY", "source_application")
                "shareToFacebookStories" -> shareToStory(call, result, FACEBOOK, "com.facebook.stories.ADD_TO_STORY", "com.facebook.platform.extra.APPLICATION_ID")
                "shareToInstagramDirect" -> shareToInstagramDirect(call, result)
                "shareToWhatsAppStatus" -> shareToWhatsAppStatus(call, result)
                "saveToGallery" -> saveToGallery(call, result)
                "isInstagramInstalled" -> result.success(isInstalled(INSTAGRAM))
                "isFacebookInstalled" -> result.success(isInstalled(FACEBOOK))
                "isWhatsAppInstalled" -> result.success(isInstalled(WHATSAPP))
                else -> result.notImplemented()
            }
        } catch (e: ShareException) {
            result.error(e.code, e.message, null)
        } catch (e: Exception) {
            result.error(FAILED, e.message, null)
        }
    }

    private fun shareToStory(call: MethodCall, result: Result, app: String, action: String, appIdExtra: String) {
        val activity = requireActivity()
        val appId = requireArgument(call, "appId")
        requireInstalled(app)

        val shareDir = freshShareDir()
        val sticker = call.argument<String>("stickerPath")?.let { stage(it, shareDir) }
        val background = call.argument<String>("backgroundImagePath")?.let { stage(it, shareDir) }
        if (sticker == null && background == null) {
            throw ShareException(INVALID_ARGUMENT, "Provide a stickerPath, a backgroundImagePath, or both")
        }

        val intent = Intent(action).apply {
            setPackage(app)
            putExtra(appIdExtra, appId)
            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
            if (background != null) {
                setDataAndType(background, "image/*")
            } else {
                type = "image/*"
                call.argument<String>("backgroundTopColor")?.let { putExtra("top_background_color", it) }
                call.argument<String>("backgroundBottomColor")?.let { putExtra("bottom_background_color", it) }
            }
            sticker?.let { putExtra("interactive_asset_uri", it) }
        }
        listOfNotNull(sticker, background).forEach {
            activity.grantUriPermission(app, it, Intent.FLAG_GRANT_READ_URI_PERMISSION)
        }
        result.success(launch(activity, intent))
    }

    private fun shareToInstagramDirect(call: MethodCall, result: Result) {
        val activity = requireActivity()
        val text = requireArgument(call, "text")
        requireInstalled(INSTAGRAM)

        val intent = Intent(Intent.ACTION_SEND).apply {
            setPackage(INSTAGRAM)
            type = "text/plain"
            putExtra(Intent.EXTRA_TEXT, text)
        }
        result.success(launch(activity, intent))
    }

    private fun shareToWhatsAppStatus(call: MethodCall, result: Result) {
        val activity = requireActivity()
        val imagePath = requireArgument(call, "imagePath")
        requireInstalled(WHATSAPP)

        val image = stage(imagePath, freshShareDir())
        activity.grantUriPermission(WHATSAPP, image, Intent.FLAG_GRANT_READ_URI_PERMISSION)

        val intent = Intent(Intent.ACTION_SEND).apply {
            setPackage(WHATSAPP)
            type = "image/*"
            putExtra(Intent.EXTRA_STREAM, image)
            putExtra("jid", "status@broadcast")
            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
        }
        // ContactPicker is not a public entry point. If WhatsApp moves it, its regular share flow still honours the status jid.
        val statusIntent = Intent(intent).setComponent(ComponentName(WHATSAPP, "com.whatsapp.ContactPicker"))
        val launched = try {
            activity.startActivity(statusIntent)
            true
        } catch (e: ActivityNotFoundException) {
            launch(activity, intent)
        } catch (e: SecurityException) {
            launch(activity, intent)
        }
        result.success(launched)
    }

    private fun saveToGallery(call: MethodCall, result: Result) {
        val bytes = call.argument<ByteArray>("imageBytes")
            ?: throw ShareException(INVALID_ARGUMENT, "imageBytes is required")
        val mimeType = imageMimeType(bytes)
            ?: throw ShareException(INVALID_IMAGE, "imageBytes is not a supported image")
        val save = PendingSave(result) {
            writeToGallery(bytes, mimeType, call.argument("fileName"), call.argument("albumName"))
        }

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q ||
            ContextCompat.checkSelfPermission(context, Manifest.permission.WRITE_EXTERNAL_STORAGE) == PackageManager.PERMISSION_GRANTED
        ) {
            runInBackground(save)
            return
        }

        val activity = requireActivity()
        if (pendingSave != null) throw ShareException(FAILED, "A gallery permission request is already in progress")
        pendingSave = save
        ActivityCompat.requestPermissions(activity, arrayOf(Manifest.permission.WRITE_EXTERNAL_STORAGE), PERMISSION_REQUEST_CODE)
    }

    override fun onRequestPermissionsResult(requestCode: Int, permissions: Array<out String>, grantResults: IntArray): Boolean {
        if (requestCode != PERMISSION_REQUEST_CODE) return false
        val save = pendingSave ?: return true
        pendingSave = null
        if (grantResults.firstOrNull() == PackageManager.PERMISSION_GRANTED) {
            runInBackground(save)
        } else {
            save.result.error(PERMISSION_DENIED, "Storage permission was denied", null)
        }
        return true
    }

    private fun writeToGallery(bytes: ByteArray, mimeType: String, fileName: String?, albumName: String?) {
        val extension = MimeTypeMap.getSingleton().getExtensionFromMimeType(mimeType) ?: "png"
        val baseName = fileName?.substringBeforeLast('.')?.takeIf { it.isNotBlank() } ?: "IMG_${System.currentTimeMillis()}"
        val album = albumName?.takeIf { it.isNotBlank() }

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            val resolver = context.contentResolver
            val values = ContentValues().apply {
                put(MediaStore.Images.Media.DISPLAY_NAME, "$baseName.$extension")
                put(MediaStore.Images.Media.MIME_TYPE, mimeType)
                put(MediaStore.Images.Media.RELATIVE_PATH, listOfNotNull(Environment.DIRECTORY_PICTURES, album).joinToString(File.separator))
                put(MediaStore.Images.Media.IS_PENDING, 1)
            }
            val uri = resolver.insert(MediaStore.Images.Media.EXTERNAL_CONTENT_URI, values)
                ?: throw ShareException(FAILED, "The gallery refused the image")
            try {
                resolver.openOutputStream(uri)?.use { it.write(bytes) }
                    ?: throw ShareException(FAILED, "Could not open the gallery file for writing")
                resolver.update(uri, ContentValues().apply { put(MediaStore.Images.Media.IS_PENDING, 0) }, null, null)
            } catch (e: Exception) {
                resolver.delete(uri, null, null)
                throw e
            }
        } else {
            @Suppress("DEPRECATION")
            val pictures = Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_PICTURES)
            val directory = (if (album != null) File(pictures, album) else pictures).apply { mkdirs() }
            var file = File(directory, "$baseName.$extension")
            if (file.exists()) file = File(directory, "${baseName}_${System.currentTimeMillis()}.$extension")
            file.writeBytes(bytes)
            MediaScannerConnection.scanFile(context, arrayOf(file.absolutePath), arrayOf(mimeType), null)
        }
    }

    private fun runInBackground(save: PendingSave) {
        executor.execute {
            val outcome = runCatching(save.work)
            mainHandler.post {
                outcome.fold(
                    onSuccess = { save.result.success(true) },
                    onFailure = { e ->
                        val code = (e as? ShareException)?.code ?: FAILED
                        save.result.error(code, e.message, null)
                    },
                )
            }
        }
    }

    // Copies into the plugin's own cache folder so the FileProvider can serve
    // files from anywhere, including paths it could never be configured for.
    private fun stage(path: String, shareDir: File): Uri {
        val source = File(path)
        if (!source.isFile) throw ShareException(FILE_NOT_FOUND, "No file at $path")
        if (imageMimeType(source) == null) throw ShareException(INVALID_IMAGE, "$path is not a supported image")

        val index = shareDir.list()?.size ?: 0
        val target = source.copyTo(File(shareDir, "${index}_${source.name}"), overwrite = true)
        return FileProvider.getUriForFile(context, "${context.packageName}.social_story_share_plus.fileprovider", target)
    }

    private fun freshShareDir(): File = File(context.cacheDir, SHARE_DIRECTORY).apply {
        deleteRecursively()
        mkdirs()
    }

    private fun imageMimeType(bytes: ByteArray): String? {
        val options = BitmapFactory.Options().apply { inJustDecodeBounds = true }
        BitmapFactory.decodeByteArray(bytes, 0, bytes.size, options)
        return options.outMimeType
    }

    private fun imageMimeType(file: File): String? {
        val options = BitmapFactory.Options().apply { inJustDecodeBounds = true }
        BitmapFactory.decodeFile(file.absolutePath, options)
        return options.outMimeType
    }

    private fun launch(activity: Activity, intent: Intent): Boolean {
        if (intent.resolveActivity(activity.packageManager) == null) return false
        activity.startActivity(intent)
        return true
    }

    private fun isInstalled(packageName: String): Boolean = try {
        val packageManager = context.packageManager
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            packageManager.getPackageInfo(packageName, PackageManager.PackageInfoFlags.of(0))
        } else {
            @Suppress("DEPRECATION")
            packageManager.getPackageInfo(packageName, 0)
        }
        true
    } catch (e: PackageManager.NameNotFoundException) {
        false
    }

    private fun requireInstalled(packageName: String) {
        if (!isInstalled(packageName)) throw ShareException(APP_NOT_INSTALLED, "$packageName is not installed")
    }

    private fun requireActivity(): Activity =
        activityBinding?.activity ?: throw ShareException(UI_UNAVAILABLE, "No foreground activity to share from")

    private fun requireArgument(call: MethodCall, key: String): String =
        call.argument<String>(key)?.takeIf { it.isNotBlank() } ?: throw ShareException(INVALID_ARGUMENT, "$key is required")

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activityBinding = binding
        binding.addRequestPermissionsResultListener(this)
    }

    override fun onDetachedFromActivityForConfigChanges() = onDetachedFromActivity()

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) = onAttachedToActivity(binding)

    override fun onDetachedFromActivity() {
        activityBinding?.removeRequestPermissionsResultListener(this)
        activityBinding = null
    }

    private class PendingSave(val result: Result, val work: () -> Unit)

    private class ShareException(val code: String, message: String) : Exception(message)

    private companion object {
        const val INSTAGRAM = "com.instagram.android"
        const val FACEBOOK = "com.facebook.katana"
        const val WHATSAPP = "com.whatsapp"

        const val SHARE_DIRECTORY = "social_story_share_plus"
        const val PERMISSION_REQUEST_CODE = 0x5353

        const val APP_NOT_INSTALLED = "APP_NOT_INSTALLED"
        const val FILE_NOT_FOUND = "FILE_NOT_FOUND"
        const val INVALID_IMAGE = "INVALID_IMAGE"
        const val INVALID_ARGUMENT = "INVALID_ARGUMENT"
        const val UI_UNAVAILABLE = "UI_UNAVAILABLE"
        const val PERMISSION_DENIED = "PERMISSION_DENIED"
        const val FAILED = "FAILED"
    }
}
