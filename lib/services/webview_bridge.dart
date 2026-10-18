import 'dart:async';
import 'dart:convert';
import 'package:desktop_webview_window/desktop_webview_window.dart';
import 'diagnostic_service.dart';

/// Transparent Bridge to execute Broadcom API requests inside a live, genuine
/// native WebView browser context (WebKit on macOS, WebView2 on Windows, WebKitGTK on Linux).
/// This completely avoids Cloudflare WAF Managed Challenge (HTTP 403 "Just a moment..."),
/// as the requests inherit genuine browser TLS fingerprints, session cookies, and DOM context.
class WebviewBridge {
  WebviewBridge._();
  static final WebviewBridge instance = WebviewBridge._();

  Webview? _desktopWebview;
  bool _isDisposed = false;

  bool get isAvailable => _desktopWebview != null && !_isDisposed;

  void registerDesktopWebview(Webview webview) {
    _desktopWebview = webview;
    _isDisposed = false;
    DiagnosticService.instance.info(
      'WebviewBridge',
      'Registered live desktop WebView as active API request bridge.',
    );

    webview.onClose.then((_) {
      if (_desktopWebview == webview) {
        _desktopWebview = null;
        _isDisposed = true;
        DiagnosticService.instance.info(
          'WebviewBridge',
          'Active desktop WebView was closed; released bridge reference.',
        );
      }
    });
  }

  Future<void> hideDesktopWindow() async {
    if (_desktopWebview != null && !_isDisposed) {
      try {
        await _desktopWebview!.setWebviewWindowVisibility(false);
        DiagnosticService.instance.info(
          'WebviewBridge',
          'Hidden desktop WebView window to run seamlessly in the background.',
        );
      } catch (e) {
        DiagnosticService.instance.warn(
          'WebviewBridge',
          'Failed to hide desktop WebView window: $e',
        );
      }
    }
  }

  void dispose() {
    _isDisposed = true;
    try {
      _desktopWebview?.close();
    } catch (_) {}
    _desktopWebview = null;
  }

  /// Executes an asynchronous fetch call inside the live browser context,
  /// bypassing any non-browser TLS / Cloudflare WAF barriers.
  Future<Map<String, dynamic>?> bridgePostJson({
    required String url,
    required Map<String, dynamic> body,
    String? csrfToken,
    Duration timeout = const Duration(seconds: 25),
  }) async {
    final webview = _desktopWebview;
    if (webview == null || _isDisposed) {
      return null;
    }

    final reqId = DateTime.now().microsecondsSinceEpoch.toString();
    final jsonPayload = jsonEncode(body);
    final escapedUrl = jsonEncode(url);
    final escapedCsrf = jsonEncode(csrfToken ?? '');

    final script = '''
      (() => {
        window.__bg_fetch_res_$reqId = null;
        window.__bg_fetch_done_$reqId = false;

        (async () => {
          try {
            let csrf = $escapedCsrf;
            if (!csrf && window.Liferay && window.Liferay.authToken) {
              csrf = window.Liferay.authToken;
            }
            if (!csrf && window.themeDisplay && typeof window.themeDisplay.getAuthToken === 'function') {
              csrf = window.themeDisplay.getAuthToken();
            }

            const response = await fetch($escapedUrl, {
              method: 'POST',
              headers: {
                'Content-Type': 'application/json;charset=UTF-8',
                'Accept': 'application/json, text/plain, */*',
                'x-csrf-token': csrf
              },
              body: JSON.stringify($jsonPayload)
            });

            const text = await response.text();
            let parsed = null;
            try {
              parsed = JSON.parse(text);
            } catch (_) {}

            window.__bg_fetch_res_$reqId = JSON.stringify({
              status: response.status,
              data: parsed,
              rawText: parsed ? null : text
            });
          } catch (err) {
            window.__bg_fetch_res_$reqId = JSON.stringify({
              error: err.toString()
            });
          } finally {
            window.__bg_fetch_done_$reqId = true;
          }
        })();
        return 'started';
      })()
    ''';

    try {
      await webview.evaluateJavaScript(script);

      final sw = Stopwatch()..start();
      while (sw.elapsed < timeout) {
        await Future.delayed(const Duration(milliseconds: 100));
        if (_desktopWebview == null || _isDisposed) break;

        final isDone = await webview.evaluateJavaScript(
          'window.__bg_fetch_done_$reqId === true',
        );
        if (isDone == 'true') {
          final resStr = await webview.evaluateJavaScript(
            'window.__bg_fetch_res_$reqId',
          );
          // Clean up DOM variable
          webview.evaluateJavaScript(
            'delete window.__bg_fetch_res_$reqId; delete window.__bg_fetch_done_$reqId;',
          ).ignore();

          if (resStr != null && resStr.isNotEmpty && resStr != 'null') {
            String sanitized = resStr;
            if (sanitized.startsWith('"') && sanitized.endsWith('"') && sanitized.length > 2) {
              try {
                sanitized = jsonDecode(sanitized).toString();
              } catch (_) {}
            }
            final decoded = jsonDecode(sanitized);
            if (decoded is Map<String, dynamic>) {
              if (decoded['data'] is Map<String, dynamic>) {
                return decoded['data'] as Map<String, dynamic>;
              }
              return decoded;
            }
          }
          break;
        }
      }
    } catch (e) {
      DiagnosticService.instance.warn(
        'WebviewBridge',
        'bridgePostJson encountered error for $url: $e',
      );
    }

    return null;
  }

  /// Concurrently fetches SKU details for both Workstation Pro and Fusion
  /// Concurrently fetches full software catalog (SKU details AND all downloadable files)
  /// directly in the genuine browser context before the webview window exits.
  Future<Map<String, dynamic>?> fetchFullCatalogInBrowser(Webview webview) async {
    const script = '''
      (() => {
        window.__full_cat_done = false;
        window.__full_cat_res = null;

        (async () => {
          try {
            let csrf = window.Liferay?.authToken || '';
            if (!csrf && window.themeDisplay?.getAuthToken) {
              csrf = window.themeDisplay.getAuthToken();
            }

            async function postJson(url, payload) {
              try {
                const resp = await fetch(url, {
                  method: 'POST',
                  headers: {
                    'Content-Type': 'application/json;charset=UTF-8',
                    'Accept': 'application/json, text/plain, */*',
                    'x-csrf-token': csrf
                  },
                  body: JSON.stringify(payload)
                });
                return await resp.json();
              } catch (e) {
                return null;
              }
            }

            const [wsSku, fuSku] = await Promise.all([
              postJson('https://support.broadcom.com/group/ecx/productdownloads/-/productDownloadsList/getProductSkuDetails?pageNumber=0&pageSize=50', {
                subFamily: 'VMware Workstation Pro',
                searchVal: '',
                language: 'EN',
                freeDownloads: true
              }),
              postJson('https://support.broadcom.com/group/ecx/productdownloads/-/productDownloadsList/getProductSkuDetails?pageNumber=0&pageSize=50', {
                subFamily: 'VMware Fusion',
                searchVal: '',
                language: 'EN',
                freeDownloads: true
              })
            ]);

            if (!wsSku || !fuSku || wsSku.error || fuSku.error || wsSku.status === 401 || wsSku.status === 403 || (typeof wsSku === 'string' && wsSku.includes('login'))) {
              window.__full_cat_res = JSON.stringify({
                success: false,
                expired: true,
                error: 'Session expired or unauthenticated'
              });
              return;
            }

            function extractTargets(skuResp, subFamily) {
              const targets = [];
              const content = skuResp?.data?.productDetails?.content || [];
              for (const grp of content) {
                const displayGroup = grp.description || '';
                const phantoms = grp.phantomDetails || [];
                for (const ph of phantoms) {
                  const rel = ph.release;
                  const gen = ph.genLevel || ph.servicePk;
                  if (rel && gen) {
                    targets.push({
                      subFamily: subFamily,
                      displayGroup: displayGroup,
                      release: String(rel),
                      servicePk: String(gen)
                    });
                  }
                }
              }
              return targets;
            }

            const allTargets = [
              ...extractTargets(wsSku, 'VMware Workstation Pro'),
              ...extractTargets(fuSku, 'VMware Fusion')
            ];

            const fileResults = await Promise.all(allTargets.map(async (t) => {
              const filesResp = await postJson('https://support.broadcom.com/group/ecx/productfiles/-/productFiles/getDownloadableFiles?pageNumber=0&pageSize=50', {
                primaryDownloads: true,
                otherDownloads: '',
                searchQuery: '',
                freeDownloads: true,
                displayGroup: t.displayGroup,
                skuCode: '',
                release: t.release,
                genLevel: t.servicePk,
                language: 'EN',
                os: ''
              });

              const packlist = filesResp?.data?.packlistDetails?.content || [];
              await Promise.all(packlist.map(async (pack) => {
                const fileDetails = pack?.fileDetails || [];
                await Promise.all(fileDetails.map(async (f) => {
                  if (f && f.filePath) {
                    try {
                      const orderResp = await postJson('https://support.broadcom.com/group/ecx/productfiles/-/productFiles/createProductDownloadOrder', {
                        downloadType: 'HTTP',
                        productName: t.subFamily,
                        releaseDescription: f.releaseDesc || pack?.description || (t.subFamily === 'VMware Workstation Pro' ? 'VMware Workstation Pro (For Windows)' : 'VMware Fusion (for Intel-based and Apple silicon Macs)'),
                        skuCode: '',
                        displayGroup: t.displayGroup,
                        release: t.release,
                        genLevel: t.servicePk,
                        language: 'EN',
                        os: '',
                        eulaId: 17290717,
                        accessToken: false,
                        siteId: '105246',
                        orderedFiles: [{
                          filePath: f.filePath,
                          fileSize: f.fileSize
                        }]
                      });
                      if (orderResp && orderResp.data && orderResp.data.downloadUrl) {
                        f.directDownloadUrl = orderResp.data.downloadUrl;
                      }
                    } catch (_) {}
                  }
                }));
              }));

              return {
                target: t,
                filesData: filesResp
              };
            }));

            window.__full_cat_res = JSON.stringify({
              success: true,
              csrf: csrf,
              results: fileResults
            });
          } catch (err) {
            window.__full_cat_res = JSON.stringify({
              success: false,
              error: err.toString()
            });
          } finally {
            window.__full_cat_done = true;
          }
        })();
        return 'started';
      })()
    ''';

    try {
      await webview.evaluateJavaScript(script);
      final sw = Stopwatch()..start();
      while (sw.elapsed < const Duration(seconds: 25)) {
        await Future.delayed(const Duration(milliseconds: 100));
        final isDone = await webview.evaluateJavaScript('window.__full_cat_done === true');
        if (isDone == 'true') {
          final resStr = await webview.evaluateJavaScript('window.__full_cat_res');
          webview.evaluateJavaScript('delete window.__full_cat_res; delete window.__full_cat_done;').ignore();
          if (resStr != null && resStr.isNotEmpty && resStr != 'null') {
            String sanitized = resStr;
            if (sanitized.startsWith('"') && sanitized.endsWith('"') && sanitized.length > 2) {
              try {
                sanitized = jsonDecode(sanitized).toString();
              } catch (_) {}
            }
            final decoded = jsonDecode(sanitized);
            if (decoded is Map<String, dynamic>) {
              return decoded;
            }
          }
          break;
        }
      }
    } catch (e) {
      DiagnosticService.instance.warn('WebviewBridge', 'fetchFullCatalogInBrowser error: $e');
    }
    return null;
  }
}
