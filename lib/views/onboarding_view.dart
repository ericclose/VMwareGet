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
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 580),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const AppLogo(size: 64, showText: true),
                const SizedBox(height: 24),
                Text(
                  'Welcome to VMwareGet',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'The modern cross-platform companion to authenticate, browse, and securely download official VMware Workstation Pro and VMware Fusion packages.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),

                // Feature grid / highlights
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest
                        .withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: colorScheme.outlineVariant.withValues(alpha: 0.4),
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
                      ),
                      const SizedBox(height: 16),
                      _buildFeatureRow(
                        context,
                        icon: Icons.fingerprint_rounded,
                        title: 'SHA-256 & MD5 Checksum Integrity',
                        description:
                            'Live and automated post-download verification against official published cryptographic hashes.',
                      ),
                      const SizedBox(height: 16),
                      _buildFeatureRow(
                        context,
                        icon: Icons.download_for_offline_rounded,
                        title: 'Advanced Download Manager',
                        description:
                            'Chunked downloading, pause/resume capability, real-time speed metrics, and ETA tracking.',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 36),

                // Action buttons
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        icon: const Icon(Icons.login_rounded),
                        label: const Text(
                          'Log In with Broadcom',
                          style: TextStyle(
                            fontSize: 15,
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
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        icon: const Icon(Icons.open_in_browser_rounded),
                        label: const Text(
                          'Register Account',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        onPressed: () =>
                            authProvider.openBroadcomRegistrationPortal(),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Quick guest / explore mode
                TextButton.icon(
                  icon: const Icon(Icons.bolt_rounded, size: 18),
                  label: const Text(
                    'Quick Demo Access (Explore without login)',
                    style: TextStyle(fontSize: 13),
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
  }

  Widget _buildFeatureRow(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String description,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            size: 20,
            color: colorScheme.onPrimaryContainer,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                description,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
