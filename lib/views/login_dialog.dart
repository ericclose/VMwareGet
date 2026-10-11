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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final authProvider = Provider.of<AuthProvider>(context);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.vpn_key_rounded,
                          color: colorScheme.onPrimaryContainer,
                        ),
                      ),
                      const SizedBox(width: 14),
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
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest
                          .withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color:
                            colorScheme.outlineVariant.withValues(alpha: 0.5),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Step 1: Authenticate in Browser',
                          style: theme.textTheme.labelMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                icon: const Icon(Icons.launch_rounded, size: 16),
                                label: const Text('Open Login Portal'),
                                onPressed: () =>
                                    authProvider.openBroadcomLoginPortal(),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: OutlinedButton.icon(
                                icon: const Icon(Icons.copy_rounded, size: 16),
                                label: const Text('Copy Helper Snippet'),
                                tooltip:
                                    'Copy JavaScript snippet to grab cookies from browser console',
                                onPressed: _copyCookieBookmarklet,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (_hasLocalTestSession) ...[
                    const SizedBox(height: 12),
                    InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: _isSubmitting ? null : _importFromPlaywrightSession,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: colorScheme.secondaryContainer
                              .withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: colorScheme.secondary.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.auto_awesome_rounded,
                                size: 18, color: colorScheme.secondary),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Verified Session Detected',
                                    style:
                                        theme.textTheme.labelMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: colorScheme.onSecondaryContainer,
                                    ),
                                  ),
                                  Text(
                                    'Import active session from local Playwright test cache',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: colorScheme.onSecondaryContainer
                                          .withValues(alpha: 0.8),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Icon(Icons.arrow_forward_ios_rounded,
                                size: 14, color: colorScheme.secondary),
                          ],
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Step 2: Session Payload',
                        style: theme.textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextButton.icon(
                        icon: const Icon(Icons.content_paste_rounded, size: 15),
                        label: const Text('Paste from Clipboard'),
                        style: TextButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                        ),
                        onPressed: _pasteFromClipboard,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _emailController,
                    decoration: const InputDecoration(
                      labelText: 'Account Email',
                      prefixIcon: Icon(Icons.email_outlined),
                      border: OutlineInputBorder(),
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
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _tokenController,
                    decoration: const InputDecoration(
                      labelText: 'Broadcom Cookie String or cURL Command',
                      hintText:
                          'Paste Cookie: SAML_SP_SESSION_KEY=... or full cURL',
                      prefixIcon: Icon(Icons.token_outlined),
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return 'Please enter your session cookie or token';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      TextButton.icon(
                        icon: const Icon(Icons.bolt_rounded, size: 16),
                        label: const Text('Instant Demo Session'),
                        onPressed: _isSubmitting ? null : _useQuickDemoSession,
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: _isSubmitting
                            ? null
                            : () => Navigator.of(context).pop(false),
                        child: const Text('Cancel'),
                      ),
                      const SizedBox(width: 8),
                      FilledButton(
                        onPressed: _isSubmitting ? null : _submit,
                        child: _isSubmitting
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text('Connect Session'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
