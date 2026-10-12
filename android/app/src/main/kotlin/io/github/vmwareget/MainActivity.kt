package io.github.vmwareget

import android.webkit.CookieManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val cookieChannel = "io.github.vmwareget/cookies"

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
    }
}
