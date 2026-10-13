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
  DateTime? _lastBridgeAttempt;
  int _accessSettledTicks = 0;

  @override
  void initState() {
    super.initState();
    _initWebView();
  }

  void _initWebView() {
    _controller = AndroidWebViewController(
      AndroidWebViewControllerCreationParams(),
    );

    // Enable cross-subdomain third-party cookies for Broadcom SSO exchange
    try {
      AndroidWebViewCookieManager(
        const PlatformWebViewCookieManagerCreationParams(),
      ).setAcceptThirdPartyCookies(_controller, true);
      DiagnosticService.instance.info(
        'Auth-Android',
        'setAcceptThirdPartyCookies enabled on AndroidWebViewController',
      );
    } catch (e) {
      DiagnosticService.instance.warn(
        'Auth-Android',
        'Failed to set acceptThirdPartyCookies: $e',
      );
    }

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
      DiagnosticService.instance.info('Auth-Android', 'Page started: $url');
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
      DiagnosticService.instance.info('Auth-Android', 'Page finished: $url');
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

    // Poll periodically to monitor login and session transitions
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

  Future<void> _manualCapture() async {
    if (_isCapturing || !mounted) return;
    try {
      final currentUrl = await _controller.currentUrl();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Inspecting portal session and capturing cookies...'),
            duration: Duration(seconds: 2),
          ),
        );
      }
      await _checkLoginState(currentUrl, force: true);
    } catch (e) {
      DiagnosticService.instance.warn('Auth-Android', 'Manual capture error: $e');
    }
  }

  Future<void> _checkLoginState(String? url, {bool force = false}) async {
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
    final isSupportPortal = host.contains('support.broadcom.com');

    if (isLoginPage) {
      _accessSettledTicks = 0;
      if (mounted && _status != 'Please complete sign-in in browser...') {
        setState(() {
          _status = 'Please complete sign-in in browser...';
        });
      }
      return;
    }

    // Handle access.broadcom.com after user finishes credentials/MFA
    if (host.contains('access.broadcom.com') && !isAccessSignIn) {
      _accessSettledTicks++;
      // Wait at least 3 poll intervals (~4.5s) to allow natural SSO redirects to occur
      final now = DateTime.now();
      final canBridge = _accessSettledTicks >= 3 &&
          (_lastBridgeAttempt == null ||
              now.difference(_lastBridgeAttempt!) > const Duration(seconds: 15));

      if (canBridge) {
        _lastBridgeAttempt = now;
        _accessSettledTicks = 0;
        DiagnosticService.instance.info(
          'Auth-Android',
          'Bridging settled access session ($url) to Support Portal...',
        );
        if (mounted) {
          setState(() {
            _status = 'Sign-in verified! Connecting to Support Portal...';
          });
        }
        _controller.loadRequest(
          LoadRequestParams(uri: Uri.parse(AppConstants.workstationPortalUrl)),
        );
      }
      return;
    }

    if (!isSupportPortal && !force) {
      return;
    }

    // Inspect support portal DOM & JavaScript session state
    String? extractedName;
    String? extractedEmail;
    String? extractedCsrf;
    bool isSignedIn = false;
    bool hasProducts = false;
    bool hasSignOut = false;

    try {
      final jsResult = await _controller.runJavaScriptReturningResult('''
        (() => {
          try {
            // Dismiss cookie consent dialog if active
            const cookieBtn = document.querySelector('#onetrust-accept-btn-handler') ||
                              document.querySelector('#onetrust-reject-all-handler') ||
                              document.querySelector('button#onetrust-accept-btn-handler') ||
                              document.querySelector('.cookie-consent-allow');
            if (cookieBtn && typeof cookieBtn.click === 'function') {
              cookieBtn.click();
            }
          } catch (_) {}

          const text = document.body ? document.body.innerText : '';
          let name = '';
          let email = '';
          let signedIn = false;

          if (window.themeDisplay) {
            if (typeof window.themeDisplay.isSignedIn === 'function') {
              signedIn = window.themeDisplay.isSignedIn() === true;
            }
            if (typeof window.themeDisplay.getUserName === 'function') {
              name = (window.themeDisplay.getUserName() || '').trim();
            }
            if (typeof window.themeDisplay.getUserEmailAddress === 'function') {
              email = (window.themeDisplay.getUserEmailAddress() || '').trim();
            }
          }

          if (!name || name === 'Guest') {
            const nameEl = document.querySelector('.user-full-name, .user-name, [data-user-name], .profile-name, .my-account-user');
            if (nameEl) name = nameEl.innerText.trim();
          }

          const signOutEl = document.querySelector('a[href*="logout"], a[href*="sign-out"], a[href*="signout"], .sign-out, .logout');
          const hasSignOut = !!signOutEl;
          if (hasSignOut) {
            signedIn = true;
          }

          const hasProducts = text.includes('VMware Workstation Pro') ||
                              text.includes('VMware Fusion') ||
                              text.includes('Product Download') ||
                              text.includes('My Downloads');

          let csrf = (window.Liferay && window.Liferay.authToken) ? window.Liferay.authToken : '';
          if (!csrf && window.themeDisplay && typeof window.themeDisplay.getAuthToken === 'function') {
            csrf = window.themeDisplay.getAuthToken();
          }
          if (!csrf) {
            const m = document.documentElement.innerHTML.match(/Liferay\\.authToken\\s*=\\s*['"]([a-zA-Z0-9_-]+)['"]/);
            if (m) csrf = m[1];
          }

          return JSON.stringify({
            isSignedIn: signedIn,
            hasProducts: hasProducts,
            hasSignOut: hasSignOut,
            userName: name,
            userEmail: email,
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
        isSignedIn = parsed['isSignedIn'] == true;
        hasProducts = parsed['hasProducts'] == true;
        hasSignOut = parsed['hasSignOut'] == true;
        final uName = parsed['userName']?.toString();
        if (uName != null && uName.isNotEmpty && uName != 'Guest') {
          extractedName = uName;
        }
        final uMail = parsed['userEmail']?.toString();
        if (uMail != null && uMail.isNotEmpty) {
          extractedEmail = uMail;
        }
        final c = parsed['csrf']?.toString();
        if (c != null && c.isNotEmpty) {
          extractedCsrf = c;
        }
      }
    } catch (e) {
      DiagnosticService.instance.warn('Auth-Android', 'Error running JS extraction: $e');
    }

    // Fetch multi-domain cookies across support, access, and broadcom.com
    try {
      final rawCookies = await AndroidCookieService.getAllCookies() ??
          await AndroidCookieService.getCookies('https://support.broadcom.com');
      if (rawCookies == null || rawCookies.isEmpty) {
        return;
      }
      final cleanCookieHeader = AuthService.cleanCookieString(rawCookies);

      DiagnosticService.instance.info(
        'Auth-Android',
        'State check on $url: cookiesLen=${cleanCookieHeader.length}, hasJSESSIONID=${cleanCookieHeader.contains('JSESSIONID')}, isSignedIn=$isSignedIn, hasProducts=$hasProducts, hasSignOut=$hasSignOut, user=${extractedName ?? "none"}',
      );

      final hasAuthIndicators = force ||
          isSignedIn ||
          hasSignOut ||
          (extractedName != null && extractedName.isNotEmpty) ||
          hasProducts;

      final hasCookies = cleanCookieHeader.isNotEmpty &&
          (cleanCookieHeader.contains('JSESSIONID') ||
              cleanCookieHeader.contains('sspsession') ||
              cleanCookieHeader.length > 50 ||
              force);

      if (!hasAuthIndicators || !hasCookies) {
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

      final displayName = extractedName ?? 'Broadcom User';
      final email = (extractedEmail != null &&
              extractedEmail.isNotEmpty &&
              extractedEmail.contains('@'))
          ? extractedEmail
          : (displayName != 'Broadcom User'
              ? '${displayName.replaceAll(" ", ".").toLowerCase()}@broadcom.user'
              : 'broadcom.member@broadcom.user');

      DiagnosticService.instance.info(
        'Auth-Android',
        'Creating authenticated session for $displayName ($email) with ${cleanCookieHeader.length} cookie bytes',
      );

      final session = await AuthService().authenticateManual(
        email: email,
        tokenOrCookie: cleanCookieHeader,
        displayName: displayName,
        csrfToken: extractedCsrf,
      );

      if (mounted) {
        Navigator.of(context).pop(session);
      }
    } catch (e) {
      _isCapturing = false;
      DiagnosticService.instance.warn('Auth-Android', 'Error capturing cookies on Android: $e');
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
            icon: const Icon(Icons.check_circle_outline_rounded),
            tooltip: 'Capture Session',
            onPressed: _isCapturing ? null : _manualCapture,
          ),
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
