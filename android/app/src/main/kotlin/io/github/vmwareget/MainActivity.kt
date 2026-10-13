package io.github.vmwareget

import android.app.DownloadManager
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.Environment
import android.provider.DocumentsContract
import android.webkit.CookieManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity : FlutterActivity() {
    private val cookieChannel = "io.github.vmwareget/cookies"
    private val platformChannel = "io.github.vmwareget/platform"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, cookieChannel).setMethodCallHandler { call, result ->
            when (call.method) {
                "getCookies" -> {
                    val url = call.argument<String>("url")
                    if (url != null) {
                        try {
                            val cookies = CookieManager.getInstance().getCookie(url)
                            result.success(cookies ?: "")
                        } catch (e: Exception) {
                            result.error("COOKIE_ERROR", e.localizedMessage, null)
                        }
                    } else {
                        result.error("INVALID_ARGS", "url parameter is required", null)
                    }
                }
                "clearCookies" -> {
                    try {
                        CookieManager.getInstance().removeAllCookies { success ->
                            CookieManager.getInstance().flush()
                            result.success(success)
                        }
                    } catch (e: Exception) {
                        result.error("COOKIE_ERROR", e.localizedMessage, null)
                    }
                }
                else -> result.notImplemented()
            }
        }

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, platformChannel).setMethodCallHandler { call, result ->
            when (call.method) {
                "openDirectory" -> {
                    val path = call.argument<String>("path")
                    if (path != null) {
                        val success = openDirectoryInFileManager(path)
                        result.success(success)
                    } else {
                        result.error("INVALID_ARGS", "path parameter is required", null)
                    }
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun openDirectoryInFileManager(dirPath: String): Boolean {
        try {
            val dir = File(dirPath)
            if (!dir.exists()) {
                dir.mkdirs()
            }
        } catch (_: Exception) {}

        // Calculate relative path for standard primary storage
        val primaryPrefix = "/storage/emulated/0/"
        val relativePath = if (dirPath.startsWith(primaryPrefix)) {
            dirPath.removePrefix(primaryPrefix)
        } else {
            val extPath = Environment.getExternalStorageDirectory()?.absolutePath
            if (extPath != null && dirPath.startsWith(extPath)) {
                dirPath.removePrefix(extPath).removePrefix("/")
            } else {
                null
            }
        }

        // 1. Try DocumentsContract buildDocumentUri with vnd.android.document/directory
        if (relativePath != null && Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            try {
                val docUri = DocumentsContract.buildDocumentUri(
                    "com.android.externalstorage.documents",
                    "primary:$relativePath"
                )
                val intent = Intent(Intent.ACTION_VIEW).apply {
                    setDataAndType(docUri, DocumentsContract.Document.MIME_TYPE_DIR)
                    addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_GRANT_READ_URI_PERMISSION)
                }
                startActivity(intent)
                return true
            } catch (_: Exception) {}
        }

        // 2. Try content URI with resource/folder MIME
        if (relativePath != null) {
            try {
                val contentUri = Uri.parse("content://com.android.externalstorage.documents/document/primary:" + Uri.encode(relativePath))
                val intent = Intent(Intent.ACTION_VIEW).apply {
                    setDataAndType(contentUri, "resource/folder")
                    addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                }
                startActivity(intent)
                return true
            } catch (_: Exception) {}
        }

        // 3. Try DocumentsContract buildRootUri
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            try {
                val rootUri = DocumentsContract.buildRootUri(
                    "com.android.externalstorage.documents",
                    "primary"
                )
                val intent = Intent(Intent.ACTION_VIEW).apply {
                    setDataAndType(rootUri, DocumentsContract.Document.MIME_TYPE_DIR)
                    addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_GRANT_READ_URI_PERMISSION)
                }
                startActivity(intent)
                return true
            } catch (_: Exception) {}
        }

        // 4. Try ACTION_VIEW_DOWNLOADS (standard system Downloads UI fallback)
        try {
            val intent = Intent(DownloadManager.ACTION_VIEW_DOWNLOADS).apply {
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            }
            startActivity(intent)
            return true
        } catch (_: Exception) {}

        return false
    }
}

