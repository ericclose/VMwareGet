import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/app_logo.dart';
import 'login_dialog.dart';

class OnboardingView extends StatelessWidget {
  const OnboardingView({super.key});

  void _showLoginDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => const LoginDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isCompact = constraints.maxHeight < 680;
          final isVeryCompact = constraints.maxHeight < 580;

          final logoSize = isVeryCompact ? 40.0 : (isCompact ? 48.0 : 60.0);
          final gapSmall = isCompact ? 8.0 : 14.0;
          final gapMedium = isCompact ? 14.0 : 22.0;
          final gapLarge = isCompact ? 16.0 : 28.0;

          return Center(
            child: ScrollConfiguration(
              behavior: const ScrollBehavior().copyWith(scrollbars: false),
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: isCompact ? 16 : 28,
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 580),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      AppLogo(size: logoSize, showText: true),
                      SizedBox(height: gapSmall),
                      Text(
                        'Welcome to VMwareGet',
                        style: (isCompact
                                ? theme.textTheme.headlineSmall
                                : theme.textTheme.headlineMedium)
                            ?.copyWith(
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'The modern cross-platform companion to authenticate, browse, and securely download official VMware Workstation Pro and VMware Fusion packages.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          height: 1.4,
                          fontSize: isCompact ? 13 : 14,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: gapMedium),

                      // Feature grid / highlights
                      Container(
                        padding: EdgeInsets.all(isCompact ? 14 : 20),
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainerHighest
                              .withValues(alpha: 0.4),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: colorScheme.outlineVariant
                                .withValues(alpha: 0.4),
                          ),
                        ),
                        child: Column(
                          children: [
                            _buildFeatureRow(
                              context,
                              icon: Icons.verified_user_rounded,
                              title: 'Official Broadcom Software Packages',
                              description:
                                  'Direct and authentic download channels for VMware Workstation Pro and VMware Fusion.',
                              isCompact: isCompact,
                            ),
                            SizedBox(height: isCompact ? 10 : 14),
                            _buildFeatureRow(
                              context,
                              icon: Icons.fingerprint_rounded,
                              title: 'SHA-256 & MD5 Checksum Integrity',
                              description:
                                  'Live and automated post-download verification against official published cryptographic hashes.',
                              isCompact: isCompact,
                            ),
                            SizedBox(height: isCompact ? 10 : 14),
                            _buildFeatureRow(
                              context,
                              icon: Icons.download_for_offline_rounded,
                              title: 'Advanced Download Manager',
                              description:
                                  'Chunked downloading, pause/resume capability, real-time speed metrics, and ETA tracking.',
                              isCompact: isCompact,
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: gapLarge),

                      // Action buttons
                      if (constraints.maxWidth < 420)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            FilledButton.icon(
                              style: FilledButton.styleFrom(
                                padding: EdgeInsets.symmetric(
                                  vertical: isCompact ? 12 : 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              icon: const Icon(Icons.login_rounded),
                              label: const Text(
                                'Log In with Broadcom',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              onPressed: () => _showLoginDialog(context),
                            ),
                            const SizedBox(height: 10),
                            OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                padding: EdgeInsets.symmetric(
                                  vertical: isCompact ? 12 : 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              icon: const Icon(Icons.open_in_browser_rounded),
                              label: const Text(
                                'Register Account',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              onPressed: () =>
                                  authProvider.openBroadcomRegistrationPortal(),
                            ),
                          ],
                        )
                      else
                        Row(
                          children: [
                            Expanded(
                              child: FilledButton.icon(
                                style: FilledButton.styleFrom(
                                  padding: EdgeInsets.symmetric(
                                    vertical: isCompact ? 12 : 16,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                                icon: const Icon(Icons.login_rounded),
                                label: const Text(
                                  'Log In with Broadcom',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                onPressed: () => _showLoginDialog(context),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  padding: EdgeInsets.symmetric(
                                    vertical: isCompact ? 12 : 16,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                                icon: const Icon(Icons.open_in_browser_rounded),
                                label: const Text(
                                  'Register Account',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                onPressed: () =>
                                    authProvider.openBroadcomRegistrationPortal(),
                              ),
                            ),
                          ],
                        ),
                      SizedBox(height: isCompact ? 8 : 14),

                      // Quick guest / explore mode
                      TextButton.icon(
                        icon: const Icon(Icons.bolt_rounded, size: 16),
                        label: const Text(
                          'Quick Demo Access (Explore without login)',
                          style: TextStyle(fontSize: 12),
                        ),
                        onPressed: () async {
                          await authProvider.loginWithManualToken(
                            email: 'guest@broadcom.local',
                            displayName: 'Guest Explorer',
                            token: 'guest_preview_token',
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFeatureRow(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String description,
    bool isCompact = false,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: EdgeInsets.all(isCompact ? 6 : 8),
          decoration: BoxDecoration(
            color: colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            size: isCompact ? 18 : 20,
            color: colorScheme.onPrimaryContainer,
          ),
        ),
        SizedBox(width: isCompact ? 10 : 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: (isCompact
                        ? theme.textTheme.labelLarge
                        : theme.textTheme.titleSmall)
                    ?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                description,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontSize: isCompact ? 11.5 : 12,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
