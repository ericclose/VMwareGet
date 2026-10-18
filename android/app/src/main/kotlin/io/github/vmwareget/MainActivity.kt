package io.github.vmwareget

import android.app.DownloadManager
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.Environment
import android.os.StrictMode
import android.provider.DocumentsContract
import android.util.Log
import android.webkit.CookieManager
import android.webkit.MimeTypeMap
import androidx.core.content.FileProvider
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity : FlutterActivity() {
    private val tag = "VMwareGet-Native"
    private val cookieChannel = "io.github.vmwareget/cookies"
    private val platformChannel = "io.github.vmwareget/platform"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // Ensure CookieManager is accepting cookies
        try {
            CookieManager.getInstance().setAcceptCookie(true)
            Log.i(tag, "CookieManager.getInstance().setAcceptCookie(true) initialized")
        } catch (e: Exception) {
            Log.w(tag, "Failed to enable CookieManager acceptCookie: ${e.localizedMessage}")
        }

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, cookieChannel).setMethodCallHandler { call, result ->
            when (call.method) {
                "getCookies" -> {
                    val url = call.argument<String>("url")
                    if (url != null) {
                        try {
                            CookieManager.getInstance().flush()
                            val cookies = CookieManager.getInstance().getCookie(url) ?: ""
                            val hasJSession = cookies.contains("JSESSIONID")
                            val count = if (cookies.isNotEmpty()) cookies.split(";").size else 0
                            Log.i(tag, "getCookies for [$url]: count=$count, hasJSESSIONID=$hasJSession, rawLength=${cookies.length}")
                            result.success(cookies)
                        } catch (e: Exception) {
                            Log.e(tag, "getCookies error for [$url]: ${e.localizedMessage}", e)
                            result.error("COOKIE_ERROR", e.localizedMessage, null)
                        }
                    } else {
                        result.error("INVALID_ARGS", "url parameter is required", null)
                    }
                }
                "getAllCookies" -> {
                    try {
                        CookieManager.getInstance().flush()
                        val cm = CookieManager.getInstance()
                        val supportCookies = cm.getCookie("https://support.broadcom.com") ?: ""
                        val accessCookies = cm.getCookie("https://access.broadcom.com") ?: ""
                        val rootCookies = cm.getCookie("https://broadcom.com") ?: ""

                        val cookieList = mutableListOf<String>()
                        if (supportCookies.isNotEmpty()) cookieList.add(supportCookies)
                        if (accessCookies.isNotEmpty()) cookieList.add(accessCookies)
                        if (rootCookies.isNotEmpty()) cookieList.add(rootCookies)

                        val combined = cookieList.joinToString("; ")
                        Log.i(
                            tag,
                            "getAllCookies: supportLen=${supportCookies.length}, accessLen=${accessCookies.length}, rootLen=${rootCookies.length}, combinedLen=${combined.length}, hasJSESSIONID=${combined.contains("JSESSIONID")}"
                        )
                        result.success(combined)
                    } catch (e: Exception) {
                        Log.e(tag, "getAllCookies error: ${e.localizedMessage}", e)
                        result.error("COOKIE_ERROR", e.localizedMessage, null)
                    }
                }
                "clearCookies" -> {
                    try {
                        Log.i(tag, "clearCookies requested")
                        CookieManager.getInstance().removeAllCookies { success ->
                            CookieManager.getInstance().flush()
                            Log.i(tag, "clearCookies completed: success=$success")
                            result.success(success)
                        }
                    } catch (e: Exception) {
                        Log.e(tag, "clearCookies error: ${e.localizedMessage}", e)
                        result.error("COOKIE_ERROR", e.localizedMessage, null)
                    }
                }
                "setCookie" -> {
                    val url = call.argument<String>("url")
                    val cookie = call.argument<String>("cookie")
                    if (url != null && cookie != null) {
                        try {
                            CookieManager.getInstance().setCookie(url, cookie)
                            CookieManager.getInstance().flush()
                            result.success(true)
                        } catch (e: Exception) {
                            Log.e(tag, "setCookie error: ${e.localizedMessage}", e)
                            result.error("COOKIE_ERROR", e.localizedMessage, null)
                        }
                    } else {
                        result.error("INVALID_ARGS", "url and cookie are required", null)
                    }
                }
                "setCookies" -> {
                    val cookies = call.argument<List<Map<String, Any>>>("cookies")
                    if (cookies != null) {
                        try {
                            val cm = CookieManager.getInstance()
                            for (item in cookies) {
                                val name = item["name"] as? String ?: continue
                                val value = item["value"] as? String ?: continue
                                val domain = item["domain"] as? String ?: "support.broadcom.com"
                                val path = item["path"] as? String ?: "/"
                                val isSecure = item["isSecure"] as? Boolean ?: true

                                val cleanDomain = domain.trimStart('.')
                                val url = "https://$cleanDomain"
                                val cookieBuilder = StringBuilder()
                                    .append("$name=$value; ")
                                    .append("domain=$cleanDomain; ")
                                    .append("path=$path; ")
                                    .append("Max-Age=2592000; ") // 30 days
                                if (isSecure) {
                                    cookieBuilder.append("Secure; ")
                                }
                                cm.setCookie(url, cookieBuilder.toString())
                            }
                            cm.flush()
                            Log.i(tag, "setCookies successfully injected ${cookies.size} cookies with 30-day persistence")
                            result.success(true)
                        } catch (e: Exception) {
                            Log.e(tag, "setCookies error: ${e.localizedMessage}", e)
                            result.error("COOKIE_ERROR", e.localizedMessage, null)
                        }
                    } else {
                        result.error("INVALID_ARGS", "cookies parameter is required", null)
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
                "openFile" -> {
                    val path = call.argument<String>("path")
                    if (path != null) {
                        val success = openFileInSystem(path)
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
        Log.i(tag, "openDirectory requested for dirPath: $dirPath")
        try {
            val dir = File(dirPath)
            if (!dir.exists()) {
                dir.mkdirs()
            }
        } catch (e: Exception) {
            Log.w(tag, "Failed to create directory if missing: ${e.localizedMessage}")
        }

        // Disable death on file URI exposure so standard file managers can accept direct file:// URIs
        try {
            val method = StrictMode::class.java.getMethod("disableDeathOnFileUriExposure")
            method.invoke(null)
        } catch (_: Exception) {
            try {
                StrictMode.setVmPolicy(StrictMode.VmPolicy.Builder().build())
            } catch (_: Exception) {}
        }

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

        val dir = File(dirPath)
        val fileUri = Uri.fromFile(dir)

        // 1. Try launching dedicated file managers (Solid Explorer, MiXplorer, ES, FX, etc.) using resource/folder
        try {
            val intent = Intent(Intent.ACTION_VIEW).apply {
                setDataAndType(fileUri, "resource/folder")
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            }
            if (intent.resolveActivity(packageManager) != null) {
                startActivity(intent)
                Log.i(tag, "openDirectory: Successfully opened via resource/folder file URI: $dirPath")
                return true
            }
        } catch (e: Exception) {
            Log.w(tag, "openDirectory attempt 1 (resource/folder) failed: ${e.localizedMessage}")
        }

        // 2. Try DocumentsUI with properly percent-encoded Document ID
        if (relativePath != null) {
            val cleanRelative = relativePath.trim('/').replace("\\", "/")
            val encodedPath = cleanRelative.split("/").filter { it.isNotEmpty() }.joinToString("%2F")
            val docUri = Uri.parse("content://com.android.externalstorage.documents/document/primary%3A$encodedPath")

            try {
                val intent = Intent(Intent.ACTION_VIEW).apply {
                    setDataAndType(docUri, DocumentsContract.Document.MIME_TYPE_DIR)
                    putExtra(DocumentsContract.EXTRA_INITIAL_URI, docUri)
                    addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_GRANT_READ_URI_PERMISSION)
                }
                if (intent.resolveActivity(packageManager) != null) {
                    startActivity(intent)
                    Log.i(tag, "openDirectory: Successfully opened via DocumentsUI documentUri: $docUri")
                    return true
                }
            } catch (e: Exception) {
                Log.w(tag, "openDirectory attempt 2 (DocumentsUI document) failed: ${e.localizedMessage}")
            }

            // 3. Try DocumentsUI Tree Document URI
            try {
                val treeDocUri = Uri.parse("content://com.android.externalstorage.documents/tree/primary%3A$encodedPath/document/primary%3A$encodedPath")
                val intent = Intent(Intent.ACTION_VIEW).apply {
                    setDataAndType(treeDocUri, DocumentsContract.Document.MIME_TYPE_DIR)
                    putExtra(DocumentsContract.EXTRA_INITIAL_URI, treeDocUri)
                    addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_GRANT_READ_URI_PERMISSION)
                }
                if (intent.resolveActivity(packageManager) != null) {
                    startActivity(intent)
                    Log.i(tag, "openDirectory: Successfully opened via DocumentsUI treeDocUri: $treeDocUri")
                    return true
                }
            } catch (e: Exception) {
                Log.w(tag, "openDirectory attempt 3 (DocumentsUI tree) failed: ${e.localizedMessage}")
            }
        }

        // 4. Try FileProvider content URI with vnd.android.document/directory
        try {
            val contentUri = FileProvider.getUriForFile(
                this,
                "$packageName.fileprovider",
                dir
            )
            val intent = Intent(Intent.ACTION_VIEW).apply {
                setDataAndType(contentUri, DocumentsContract.Document.MIME_TYPE_DIR)
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_GRANT_READ_URI_PERMISSION)
            }
            if (intent.resolveActivity(packageManager) != null) {
                startActivity(intent)
                Log.i(tag, "openDirectory: Successfully opened via FileProvider URI: $contentUri")
                return true
            }
        } catch (e: Exception) {
            Log.w(tag, "openDirectory attempt 4 (FileProvider) failed: ${e.localizedMessage}")
        }

        // 5. Try ACTION_VIEW with direct file URI and vnd.android.document/directory
        try {
            val intent = Intent(Intent.ACTION_VIEW).apply {
                setDataAndType(fileUri, DocumentsContract.Document.MIME_TYPE_DIR)
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            }
            if (intent.resolveActivity(packageManager) != null) {
                startActivity(intent)
                Log.i(tag, "openDirectory: Successfully opened via direct fileUri: $fileUri")
                return true
            }
        } catch (e: Exception) {
            Log.w(tag, "openDirectory attempt 5 failed: ${e.localizedMessage}")
        }

        // 6. Fallback to system Downloads UI
        try {
            val intent = Intent(DownloadManager.ACTION_VIEW_DOWNLOADS).apply {
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            }
            startActivity(intent)
            Log.i(tag, "openDirectory: Fallback to ACTION_VIEW_DOWNLOADS")
            return true
        } catch (e: Exception) {
            Log.e(tag, "openDirectory fallback failed: ${e.localizedMessage}")
        }

        return false
    }

    private fun openFileInSystem(filePath: String): Boolean {
        Log.i(tag, "openFile requested for path: $filePath")
        try {
            val file = File(filePath)
            if (!file.exists()) {
                Log.w(tag, "File does not exist: $filePath")
                return false
            }

            // Disable death on file URI exposure
            try {
                val method = StrictMode::class.java.getMethod("disableDeathOnFileUriExposure")
                method.invoke(null)
            } catch (_: Exception) {
                try {
                    StrictMode.setVmPolicy(StrictMode.VmPolicy.Builder().build())
                } catch (_: Exception) {}
            }

            val ext = file.extension.lowercase()
            val mime = MimeTypeMap.getSingleton().getMimeTypeFromExtension(ext) ?: "*/*"

            // 1. Try FileProvider
            try {
                val contentUri = FileProvider.getUriForFile(
                    this,
                    "$packageName.fileprovider",
                    file
                )
                val intent = Intent(Intent.ACTION_VIEW).apply {
                    setDataAndType(contentUri, mime)
                    addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_GRANT_READ_URI_PERMISSION)
                }
                startActivity(intent)
                Log.i(tag, "openFile: Successfully opened via FileProvider: $contentUri ($mime)")
                return true
            } catch (e: Exception) {
                Log.w(tag, "openFile via FileProvider failed: ${e.localizedMessage}")
            }

            // 2. Try file URI
            val fileUri = Uri.fromFile(file)
            val intent = Intent(Intent.ACTION_VIEW).apply {
                setDataAndType(fileUri, mime)
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            }
            startActivity(intent)
            Log.i(tag, "openFile: Successfully opened via fileUri: $fileUri ($mime)")
            return true
        } catch (e: Exception) {
            Log.e(tag, "openFile error: ${e.localizedMessage}", e)
            return false
        }
    }
}
