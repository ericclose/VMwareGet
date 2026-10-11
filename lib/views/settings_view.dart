import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/download_provider.dart';
import '../providers/theme_provider.dart';
import '../services/diagnostic_service.dart';
import '../services/folder_picker_service.dart';
import '../utils/constants.dart';
import '../widgets/app_logo.dart';
import '../widgets/diagnostic_dialog.dart';

class SettingsView extends StatelessWidget {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final auth = Provider.of<AuthProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final downloadProvider = Provider.of<DownloadProvider>(context);
    final session = auth.currentSession;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Settings & Account',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),

            // Account & Session Section
            Text(
              'Broadcom Session',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 24,
                          backgroundColor: colorScheme.primaryContainer,
                          child: Icon(
                            Icons.person_rounded,
                            color: colorScheme.onPrimaryContainer,
                            size: 26,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                session?.displayName ?? 'Authenticated User',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                session?.email ?? 'No active session',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                        FilledButton.tonal(
                          style: FilledButton.styleFrom(
                            foregroundColor: colorScheme.error,
                          ),
                          onPressed: () => auth.logout(),
                          child: const Text('Sign Out'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Icon(
                          Icons.verified_rounded,
                          size: 16,
                          color: Colors.green.shade700,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Export Compliance Screening:',
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Approved (Global Free License Access)',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.green.shade800,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(
                          Icons.lock_clock_outlined,
                          size: 16,
                          color: colorScheme.outline,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Session Persistence:',
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Encrypted Storage Active',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Download Storage & Directory Section
            Text(
              'Download Storage & Directory (下载目录配置)',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            Icons.folder_special_rounded,
                            size: 22,
                            color: colorScheme.onPrimaryContainer,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Download Destination Directory',
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'Installer packages and disk images will be saved here',
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
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: colorScheme.outlineVariant.withValues(alpha: 0.5),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.folder_outlined,
                            size: 18,
                            color: colorScheme.primary,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: SelectableText(
                              downloadProvider.downloadDirectory ??
                                  downloadProvider.defaultSystemDownloadDir,
                              style: theme.textTheme.bodySmall?.copyWith(
                                fontFamily: 'monospace',
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        FilledButton.tonalIcon(
                          icon: const Icon(Icons.edit_location_alt_rounded, size: 16),
                          label: const Text('Change Directory (更改路径)'),
                          onPressed: () async {
                            final chosen = await FolderPickerService.pickDirectory(
                              prompt: 'Select VMware Downloads Folder',
                              initialDirectory: downloadProvider.downloadDirectory,
                            );
                            if (chosen != null && chosen.isNotEmpty) {
                              await downloadProvider.setDownloadDirectory(chosen);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Download directory updated to: $chosen'),
                                    backgroundColor: colorScheme.primary,
                                  ),
                                );
                              }
                            }
                          },
                        ),
                        OutlinedButton.icon(
                          icon: const Icon(Icons.folder_open_rounded, size: 16),
                          label: Text(
                            Platform.isMacOS
                                ? 'Open in Finder (打开目录)'
                                : 'Open Directory (打开目录)',
                          ),
                          onPressed: () => downloadProvider.openDownloadDirectory(),
                        ),
                        if (downloadProvider.downloadDirectory !=
                            downloadProvider.defaultSystemDownloadDir)
                          TextButton.icon(
                            icon: const Icon(Icons.restore_rounded, size: 16),
                            label: const Text('Reset to System Default (恢复系统默认)'),
                            onPressed: () async {
                              await downloadProvider.resetToDefaultDownloadDirectory();
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Reset to system default Downloads folder'),
                                  ),
                                );
                              }
                            },
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Diagnostics Section
            Text(
              'Technical Diagnostics & Live Logs',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: colorScheme.secondaryContainer,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            Icons.bug_report_rounded,
                            size: 22,
                            color: colorScheme.onSecondaryContainer,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Full-Pipeline Troubleshooting Logs',
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'Capture & inspect SSO cookies, CSRF tokens, and Broadcom REST endpoints',
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
                    Row(
                      children: [
                        FilledButton.tonalIcon(
                          icon: const Icon(Icons.analytics_outlined, size: 16),
                          label: const Text('View Diagnostic Logs (查看诊断)'),
                          onPressed: () => DiagnosticDialog.show(context),
                        ),
                        const SizedBox(width: 10),
                        OutlinedButton.icon(
                          icon: const Icon(Icons.copy_rounded, size: 16),
                          label: const Text('Copy All Logs (一键复制)'),
                          onPressed: () {
                            final text = DiagnosticService.instance.exportFormattedLogs();
                            Clipboard.setData(ClipboardData(text: text));
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: const Text('Diagnostic report copied to clipboard!'),
                                backgroundColor: Theme.of(context).colorScheme.primary,
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Appearance Section
            Text(
              'Appearance & Theme',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Material Design 3 Theme Mode',
                      style: theme.textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SegmentedButton<ThemeMode>(
                      segments: const [
                        ButtonSegment(
                          value: ThemeMode.system,
                          icon: Icon(Icons.brightness_auto_rounded),
                          label: Text('System'),
                        ),
                        ButtonSegment(
                          value: ThemeMode.light,
                          icon: Icon(Icons.light_mode_rounded),
                          label: Text('Light'),
                        ),
                        ButtonSegment(
                          value: ThemeMode.dark,
                          icon: Icon(Icons.dark_mode_rounded),
                          label: Text('Dark'),
                        ),
                      ],
                      selected: {themeProvider.themeMode},
                      onSelectionChanged: (set) {
                        if (set.isNotEmpty) {
                          themeProvider.setThemeMode(set.first);
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Application Information
            Text(
              'Application Information',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const AppLogo(size: 38, showText: false),
                        const SizedBox(width: 14),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              AppConstants.appName,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Version ${AppConstants.appVersion}',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 8),
                    _buildInfoRow(context, 'App Identifier / Bundle ID',
                        AppConstants.appId),
                    _buildInfoRow(
                        context, 'Framework Engine', 'Flutter (v3.47.7 pinned)'),
                    _buildInfoRow(context, 'Design System',
                        'Material Design 3 (Dynamic Color)'),
                    _buildInfoRow(context, 'Target Platforms',
                        'macOS, Windows, Linux, Android'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, String label, String value) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          Text(
            value,
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
