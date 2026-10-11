import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/catalog_provider.dart';

class LoginDialog extends StatefulWidget {
  const LoginDialog({super.key});

  @override
  State<LoginDialog> createState() => _LoginDialogState();
}

class _LoginDialogState extends State<LoginDialog> {
  final _emailController = TextEditingController();
  final _tokenController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isSubmitting = false;
  bool _hasLocalTestSession = false;
  String? _inAppStatus;

  @override
  void initState() {
    super.initState();
    _checkLocalTestSession();
  }

  void _checkLocalTestSession() async {
    if (kIsWeb) return;
    try {
      final file = File('tools/.session.json');
      if (await file.exists()) {
        setState(() => _hasLocalTestSession = true);
      }
    } catch (_) {}
  }

  void _loginWithInApp() async {
    setState(() {
      _isSubmitting = true;
      _inAppStatus = 'Launching in-app secure portal...';
    });
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    final success = await authProvider.loginWithInAppWebView(
      onStatusUpdate: (msg) {
        if (mounted) setState(() => _inAppStatus = msg);
      },
    );

    if (mounted) {
      setState(() {
        _isSubmitting = false;
        _inAppStatus = null;
      });
      if (success) {
        final catalog = Provider.of<CatalogProvider>(context, listen: false);
        catalog.refreshFromOnline(authProvider.currentSession);
        Navigator.of(context).pop(true);
      } else if (authProvider.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(authProvider.errorMessage!),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _tokenController.dispose();
    super.dispose();
  }

  void _pasteFromClipboard() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text?.trim();
    if (text == null || text.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Clipboard is empty')),
        );
      }
      return;
    }

    setState(() {
      _tokenController.text = text;
      // Auto-extract email if present in cURL or text
      if (_emailController.text.isEmpty) {
        final emailMatch =
            RegExp(r'[\w\.-]+@[\w\.-]+\.\w+').firstMatch(text);
        if (emailMatch != null) {
          _emailController.text = emailMatch.group(0)!;
        } else {
          _emailController.text = 'engineer@developer.broadcom.com';
        }
      }
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Session payload pasted from clipboard!'),
          backgroundColor: Theme.of(context).colorScheme.primary,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _importFromPlaywrightSession() async {
    setState(() => _isSubmitting = true);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    final success = await authProvider.loadLocalTestSession();
    if (mounted) {
      setState(() => _isSubmitting = false);
      if (success) {
        final catalog = Provider.of<CatalogProvider>(context, listen: false);
        catalog.refreshFromOnline(authProvider.currentSession);
        Navigator.of(context).pop(true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(authProvider.errorMessage ??
                'No verified session found in tools/.session.json'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  void _copyCookieBookmarklet() async {
    const script =
        "javascript:navigator.clipboard.writeText(document.cookie);alert('Broadcom session cookies copied! Switch to VMwareGet and click Paste.');";
    await Clipboard.setData(const ClipboardData(text: script));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Cookie capture helper copied! Paste into browser console or bookmark bar on Broadcom page.',
          ),
          backgroundColor: Theme.of(context).colorScheme.tertiary,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    final success = await authProvider.loginWithManualToken(
      email: _emailController.text,
      token: _tokenController.text,
    );

    if (mounted) {
      setState(() => _isSubmitting = false);
      if (success) {
        final catalog = Provider.of<CatalogProvider>(context, listen: false);
        catalog.refreshFromOnline(authProvider.currentSession);
        Navigator.of(context).pop(true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(authProvider.errorMessage ?? 'Authentication failed'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  void _useQuickDemoSession() async {
    setState(() => _isSubmitting = true);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    await authProvider.loginWithManualToken(
      email: 'engineer@developer.broadcom.com',
      displayName: 'Broadcom Enterprise Member',
      token: 'session_live_oauth2_${DateTime.now().millisecondsSinceEpoch}',
    );

    if (mounted) {
      final catalog = Provider.of<CatalogProvider>(context, listen: false);
      catalog.refreshFromOnline(authProvider.currentSession);
      Navigator.of(context).pop(true);
    }
  }

  int _selectedTab = 0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final authProvider = Provider.of<AuthProvider>(context);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 510),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 20),
          child: ScrollConfiguration(
            behavior: const ScrollBehavior().copyWith(scrollbars: false),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(9),
                        decoration: BoxDecoration(
                          color: colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          Icons.vpn_key_rounded,
                          size: 20,
                          color: colorScheme.onPrimaryContainer,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Broadcom Authentication',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Connect your official Broadcom session',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Segmented Switcher for Login Method
                  SizedBox(
                    width: double.infinity,
                    child: SegmentedButton<int>(
                      segments: const [
                        ButtonSegment<int>(
                          value: 0,
                          icon: Icon(Icons.language_rounded, size: 16),
                          label: Text('In-App Browser'),
                        ),
                        ButtonSegment<int>(
                          value: 1,
                          icon: Icon(Icons.code_rounded, size: 16),
                          label: Text('Manual / cURL Import'),
                        ),
                      ],
                      selected: {_selectedTab},
                      onSelectionChanged: (newVal) {
                        setState(() => _selectedTab = newVal.first);
                      },
                      style: const ButtonStyle(
                        visualDensity: VisualDensity.compact,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  if (_selectedTab == 0)
                    _buildInAppBrowserTab(context, theme, colorScheme, authProvider)
                  else
                    _buildManualImportTab(context, theme, colorScheme, authProvider),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInAppBrowserTab(
    BuildContext context,
    ThemeData theme,
    ColorScheme colorScheme,
    AuthProvider authProvider,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                colorScheme.primaryContainer.withValues(alpha: 0.5),
                colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: colorScheme.primary.withValues(alpha: 0.25),
              width: 1.2,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: colorScheme.primary,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.language_rounded,
                      color: colorScheme.onPrimary,
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'In-App Browser Login',
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.green.shade700,
                                borderRadius: BorderRadius.circular(5),
                              ),
                              child: const Text(
                                'RECOMMENDED',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Opens secure WKWebView window & auto-captures session upon login',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (_inAppStatus != null) ...[
                const SizedBox(height: 12),
                LinearProgressIndicator(
                  backgroundColor: colorScheme.primary.withValues(alpha: 0.2),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const SizedBox(
                      width: 12,
                      height: 12,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _inAppStatus!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  icon: const Icon(Icons.open_in_browser_rounded, size: 18),
                  label: Text(
                    _isSubmitting
                        ? 'Authenticating in-app...'
                        : 'Sign In via In-App Browser',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  onPressed: _isSubmitting ? null : _loginWithInApp,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            TextButton.icon(
              icon: const Icon(Icons.bolt_rounded, size: 16),
              label: const Text('Instant Demo Session', style: TextStyle(fontSize: 12)),
              onPressed: _isSubmitting ? null : _useQuickDemoSession,
            ),
            const SizedBox(width: 4),
            TextButton.icon(
              icon: const Icon(Icons.launch_rounded, size: 14),
              label: const Text('External Browser', style: TextStyle(fontSize: 12)),
              onPressed: _isSubmitting
                  ? null
                  : () => authProvider.openBroadcomLoginPortal(),
            ),
            const Spacer(),
            TextButton(
              onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildManualImportTab(
    BuildContext context,
    ThemeData theme,
    ColorScheme colorScheme,
    AuthProvider authProvider,
  ) {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              OutlinedButton.icon(
                icon: const Icon(Icons.content_paste_rounded, size: 14),
                label: const Text('Paste from Clipboard', style: TextStyle(fontSize: 12)),
                style: OutlinedButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                ),
                onPressed: _pasteFromClipboard,
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                icon: const Icon(Icons.copy_rounded, size: 14),
                label: const Text('Copy Helper Snippet', style: TextStyle(fontSize: 12)),
                style: OutlinedButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                ),
                onPressed: _copyCookieBookmarklet,
              ),
            ],
          ),
          if (_hasLocalTestSession) ...[
            const SizedBox(height: 10),
            InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: _isSubmitting ? null : _importFromPlaywrightSession,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: colorScheme.secondaryContainer.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: colorScheme.secondary.withValues(alpha: 0.25),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.auto_awesome_rounded, size: 16, color: colorScheme.secondary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Import active session from local Playwright test cache',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSecondaryContainer,
                          fontWeight: FontWeight.w600,
                          fontSize: 11.5,
                        ),
                      ),
                    ),
                    Icon(Icons.arrow_forward_ios_rounded, size: 12, color: colorScheme.secondary),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 12),
          TextFormField(
            controller: _emailController,
            decoration: const InputDecoration(
              labelText: 'Account Email',
              prefixIcon: Icon(Icons.email_outlined, size: 18),
              border: OutlineInputBorder(),
              isDense: true,
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
            keyboardType: TextInputType.emailAddress,
            validator: (val) {
              if (val == null || val.trim().isEmpty) {
                return 'Please enter your email';
              }
              if (!val.contains('@')) {
                return 'Enter a valid email address';
              }
              return null;
            },
          ),
          const SizedBox(height: 10),
          TextFormField(
            controller: _tokenController,
            decoration: const InputDecoration(
              labelText: 'Broadcom Cookie String or cURL Command',
              hintText: 'Paste Cookie or cURL',
              prefixIcon: Icon(Icons.token_outlined, size: 18),
              border: OutlineInputBorder(),
              isDense: true,
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
            maxLines: 2,
            validator: (val) {
              if (val == null || val.trim().isEmpty) {
                return 'Please enter your session cookie or token';
              }
              return null;
            },
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              TextButton.icon(
                icon: const Icon(Icons.bolt_rounded, size: 16),
                label: const Text('Instant Demo Session', style: TextStyle(fontSize: 12)),
                onPressed: _isSubmitting ? null : _useQuickDemoSession,
              ),
              const Spacer(),
              TextButton(
                onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: _isSubmitting ? null : _submit,
                child: _isSubmitting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Connect Session'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
