import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:webview_flutter_platform_interface/webview_flutter_platform_interface.dart';
import '../services/android_cookie_service.dart';
import '../services/auth_service.dart';
import '../services/diagnostic_service.dart';
import '../utils/constants.dart';

class MobileWebViewLoginScreen extends StatefulWidget {
  final void Function(String message)? onStatusUpdate;

  const MobileWebViewLoginScreen({
    super.key,
    this.onStatusUpdate,
  });

  @override
  State<MobileWebViewLoginScreen> createState() =>
      _MobileWebViewLoginScreenState();
}

class _MobileWebViewLoginScreenState extends State<MobileWebViewLoginScreen> {
  late final AndroidWebViewController _controller;
  late final PlatformWebViewWidget _webViewWidget;
  Timer? _pollTimer;
  double _progress = 0.0;
  String _status = 'Initializing secure Broadcom login...';
  bool _isCapturing = false;

  @override
  void initState() {
    super.initState();
    _initWebView();
  }

  void _initWebView() {
    _controller = AndroidWebViewController(
      AndroidWebViewControllerCreationParams(),
    );

    final delegate = AndroidNavigationDelegate(
      AndroidNavigationDelegateCreationParams.fromPlatformNavigationDelegateCreationParams(
        const PlatformNavigationDelegateCreationParams(),
      ),
    );
    delegate.setOnPageStarted((url) {
      if (mounted) {
        setState(() {
          _status = 'Loading Broadcom portal...';
          _progress = 0.15;
        });
      }
      widget.onStatusUpdate?.call('Loading page: $url');
    });
    delegate.setOnProgress((progress) {
      if (mounted) {
        setState(() {
          _progress = progress / 100.0;
        });
      }
    });
    delegate.setOnPageFinished((url) {
      if (mounted) {
        setState(() {
          _progress = 1.0;
        });
      }
      _checkLoginState(url);
    });

    _controller.setPlatformNavigationDelegate(delegate);
    _controller.setJavaScriptMode(JavaScriptMode.unrestricted);
    _controller.setUserAgent(
      'Mozilla/5.0 (Linux; Android 14; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/126.0.0.0 Mobile Safari/537.36',
    );
    _controller.loadRequest(
      LoadRequestParams(uri: Uri.parse(AppConstants.broadcomLoginUrl)),
    );

    _webViewWidget = AndroidWebViewWidget(
      AndroidWebViewWidgetCreationParams(controller: _controller),
    );

    // Poll periodically in case page undergoes SPA or background token transitions
    _pollTimer = Timer.periodic(const Duration(milliseconds: 1500), (_) async {
      if (_isCapturing || !mounted) return;
      try {
        final currentUrl = await _controller.currentUrl();
        await _checkLoginState(currentUrl);
      } catch (_) {}
    });
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<void> _checkLoginState(String? url) async {
    if (_isCapturing || url == null || !mounted) return;

    final uri = Uri.tryParse(url);
    if (uri == null) return;

    final host = uri.host.toLowerCase();
    final path = uri.path.toLowerCase();

    final isAccessSignIn = host.contains('access.broadcom.com') &&
        (path.contains('/signin') || path.contains('/login') || path.contains('/idp/'));
    final isLoginPage = isAccessSignIn ||
        path.contains('/login') ||
        path.contains('/signin') ||
        host.contains('okta.com');
    final isSupportPortal = host == 'support.broadcom.com';

    if (isLoginPage) {
      if (mounted && _status != 'Please complete sign-in in browser...') {
        setState(() {
          _status = 'Please complete sign-in in browser...';
        });
      }
      return;
    }

    // If user settled on access.broadcom.com after authentication, bridge to support portal for Liferay cookies
    if (host.contains('access.broadcom.com') && !isAccessSignIn) {
      if (mounted && _status != 'Sign-in verified! Connecting to Support Portal...') {
        setState(() {
          _status = 'Sign-in verified! Connecting to Support Portal...';
        });
      }
      _controller.loadRequest(
        LoadRequestParams(uri: Uri.parse(AppConstants.workstationPortalUrl)),
      );
      return;
    }

    if (!isSupportPortal) {
      return;
    }

    // On support portal, query page details via JavaScript
    String? extractedName;
    String? extractedCsrf;
    bool hasProducts = false;

    try {
      final jsResult = await _controller.runJavaScriptReturningResult('''
        (() => {
          const text = document.body ? document.body.innerText : '';
          let name = '';
          const nameEl = document.querySelector('.user-full-name, .user-name, [data-user-name]');
          if (nameEl) name = nameEl.innerText.trim();
          let csrf = (window.Liferay && window.Liferay.authToken) ? window.Liferay.authToken : '';
          if (!csrf && window.themeDisplay && typeof window.themeDisplay.getAuthToken === 'function') {
            csrf = window.themeDisplay.getAuthToken();
          }
          if (!csrf) {
            const m = document.documentElement.innerHTML.match(/Liferay\\.authToken\\s*=\\s*['"]([a-zA-Z0-9_-]+)['"]/);
            if (m) csrf = m[1];
          }
          return JSON.stringify({
            hasProducts: text.includes('VMware Workstation Pro') || text.includes('VMware Fusion') || text.includes('Product Download'),
            userName: name,
            csrf: csrf
          });
        })()
      ''');

      String raw = jsResult.toString();
      if (raw.startsWith('"') && raw.endsWith('"') && raw.length > 2) {
        try {
          raw = jsonDecode(raw).toString();
        } catch (_) {}
      }
      final parsed = jsonDecode(raw);
      if (parsed is Map) {
        hasProducts = parsed['hasProducts'] == true;
        final uName = parsed['userName']?.toString();
        if (uName != null && uName.isNotEmpty) extractedName = uName;
        final c = parsed['csrf']?.toString();
        if (c != null && c.isNotEmpty) extractedCsrf = c;
      }
    } catch (_) {}

    // Fetch cookies for support.broadcom.com
    try {
      final rawCookies =
          await AndroidCookieService.getCookies('https://support.broadcom.com');
      if (rawCookies == null || rawCookies.isEmpty) {
        return;
      }
      final cleanCookieHeader = AuthService.cleanCookieString(rawCookies);

      if (cleanCookieHeader.isEmpty ||
          !cleanCookieHeader.contains('JSESSIONID')) {
        return;
      }

      // Check whether session is active
      final hasAuth = (extractedName != null && extractedName.isNotEmpty && extractedName != 'Guest') || hasProducts;
      if (!hasAuth) {
        return;
      }

      _isCapturing = true;
      _pollTimer?.cancel();

      if (mounted) {
        setState(() {
          _status = 'Authentication successful! Verifying credentials...';
        });
      }
      widget.onStatusUpdate?.call('Session detected. Completing login...');

      DiagnosticService.instance.info(
        'Auth',
        'Android WebView captured session for ${extractedName ?? "Broadcom User"}',
      );

      final email = (extractedName != null && extractedName.isNotEmpty && extractedName != 'Guest')
          ? '${extractedName.replaceAll(" ", ".").toLowerCase()}@broadcom.user'
          : 'broadcom.member@broadcom.user';

      final session = await AuthService().authenticateManual(
        email: email,
        tokenOrCookie: cleanCookieHeader,
        displayName: extractedName ?? 'Broadcom User',
        csrfToken: extractedCsrf ?? 'YaLAJUoR',
      );

      if (mounted) {
        Navigator.of(context).pop(session);
      }
    } catch (e) {
      DiagnosticService.instance.warn('Auth', 'Error checking cookies on Android WebView: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Broadcom Account Login',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Text(
              _status,
              style: TextStyle(
                fontSize: 11,
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.normal,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          tooltip: 'Close',
          onPressed: () => Navigator.of(context).pop(null),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Reload',
            onPressed: () => _controller.reload(),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(2.5),
          child: _progress < 1.0
              ? LinearProgressIndicator(
                  value: _progress,
                  backgroundColor: colorScheme.surfaceContainerHighest,
                )
              : const SizedBox(height: 2.5),
        ),
      ),
      body: SafeArea(
        child: _webViewWidget.build(context),
      ),
    );
  }
}
