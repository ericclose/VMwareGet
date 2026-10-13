import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../providers/auth_provider.dart';
import '../providers/download_provider.dart';
import '../providers/locale_provider.dart';
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
    final l10n = AppLocalizations.of(context);
    final auth = Provider.of<AuthProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final localeProvider = Provider.of<LocaleProvider>(context);
    final downloadProvider = Provider.of<DownloadProvider>(context);
    final session = auth.currentSession;

    final isCompact = MediaQuery.of(context).size.width < 600;

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? 16 : 24,
        vertical: 20,
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.settingsAndAccount,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),

            // Account & Session Section
            Text(
              l10n.broadcomSession,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Card(
              child: Padding(
                padding: EdgeInsets.all(isCompact ? 16 : 20),
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
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                session?.displayName ?? 'Authenticated User',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                session?.email ?? 'No active session',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        FilledButton.tonal(
                          style: FilledButton.styleFrom(
                            foregroundColor: colorScheme.error,
                          ),
                          onPressed: () => auth.logout(),
                          child: Text(l10n.signOut),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 12),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Icon(
                            Icons.verified_rounded,
                            size: 16,
                            color: Colors.green.shade700,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text.rich(
                            TextSpan(
                              children: [
                                TextSpan(
                                  text: '${l10n.exportComplianceScreening}: ',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                TextSpan(
                                  text: l10n.complianceApproved,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: Colors.green.shade800,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Icon(
                            Icons.lock_clock_outlined,
                            size: 16,
                            color: colorScheme.outline,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text.rich(
                            TextSpan(
                              children: [
                                TextSpan(
                                  text: '${l10n.sessionPersistence}: ',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                TextSpan(
                                  text: l10n.encryptedStorageActive,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
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
              l10n.downloadStorageSection,
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
                                l10n.downloadDestinationDir,
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                l10n.downloadDirSubtitle,
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
                          label: Text(l10n.changeDirectory),
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
                                ? l10n.showInFinder
                                : l10n.openInFinderOrExplorer,
                          ),
                          onPressed: () async {
                            final success =
                                await downloadProvider.openDownloadDirectory();
                            if (!success && context.mounted) {
                              final dir = downloadProvider.downloadDirectory ??
                                  downloadProvider.defaultSystemDownloadDir;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(dir),
                                  action: SnackBarAction(
                                    label: 'Copy',
                                    onPressed: () {
                                      Clipboard.setData(ClipboardData(text: dir));
                                    },
                                  ),
                                ),
                              );
                            }
                          },
                        ),
                        if (downloadProvider.downloadDirectory !=
                            downloadProvider.defaultSystemDownloadDir)
                          TextButton.icon(
                            icon: const Icon(Icons.restore_rounded, size: 16),
                            label: Text(l10n.resetToDefault),
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
                    const SizedBox(height: 20),
                    const Divider(),
                    const SizedBox(height: 16),

                    // Multi-threading Range Engine
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: colorScheme.tertiaryContainer,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            Icons.bolt_rounded,
                            size: 22,
                            color: colorScheme.onTertiaryContainer,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                l10n.multiThreadingSection,
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                l10n.multiThreadingSubtitle,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '${downloadProvider.downloadThreads} ${l10n.threadsLabel}',
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: colorScheme.onPrimaryContainer,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        trackHeight: 6,
                        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
                      ),
                      child: Slider(
                        value: downloadProvider.downloadThreads.toDouble(),
                        min: AppConstants.minDownloadThreads.toDouble(),
                        max: AppConstants.maxDownloadThreads.toDouble(),
                        divisions: AppConstants.maxDownloadThreads - AppConstants.minDownloadThreads,
                        label: '${downloadProvider.downloadThreads} ${l10n.threadsLabel}',
                        onChanged: (val) {
                          downloadProvider.setDownloadThreads(val.round());
                        },
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '1',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: colorScheme.outline,
                          ),
                        ),
                        Text(
                          '16',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: colorScheme.outline,
                          ),
                        ),
                        Text(
                          '64',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: colorScheme.outline,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [4, 8, 16, 32, 64].map((threads) {
                        final isSelected = downloadProvider.downloadThreads == threads;
                        return ChoiceChip(
                          label: Text('$threads ${l10n.threadsLabel}'),
                          selected: isSelected,
                          onSelected: (_) {
                            downloadProvider.setDownloadThreads(threads);
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      l10n.multiThreadingHint,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Diagnostics Section
            Text(
              l10n.technicalDiagnosticsSection,
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
                                l10n.diagnosticLogsTitle,
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                l10n.diagnosticSubtitle,
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
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        FilledButton.tonalIcon(
                          icon: const Icon(Icons.analytics_outlined, size: 16),
                          label: Text(l10n.viewDiagnosticLogs),
                          onPressed: () => DiagnosticDialog.show(context),
                        ),
                        OutlinedButton.icon(
                          icon: const Icon(Icons.copy_rounded, size: 16),
                          label: Text(l10n.copyAllLogs),
                          onPressed: () {
                            final text = DiagnosticService.instance.exportFormattedLogs();
                            Clipboard.setData(ClipboardData(text: text));
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(l10n.diagnosticCopied),
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

            // Language Section
            Text(
              l10n.languageSection,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.translate_rounded,
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
                            l10n.displayLanguage,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _getLanguageSubtitle(localeProvider.locale.languageCode),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    PopupMenuButton<String>(
                      tooltip: l10n.displayLanguage,
                      elevation: 2,
                      shadowColor: Colors.black.withValues(alpha: 0.08),
                      surfaceTintColor: Colors.transparent,
                      color: colorScheme.surface,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                        side: BorderSide(
                          color: colorScheme.outlineVariant.withValues(alpha: 0.6),
                          width: 1,
                        ),
                      ),
                      position: PopupMenuPosition.under,
                      onSelected: (code) => localeProvider.setLocale(Locale(code)),
                      itemBuilder: (context) => [
                        _buildLanguageMenuItem(
                          value: 'en',
                          flag: '🇺🇸',
                          label: l10n.langEnglish,
                          isSelected: localeProvider.locale.languageCode == 'en',
                          theme: theme,
                        ),
                        _buildLanguageMenuItem(
                          value: 'zh',
                          flag: '🇨🇳',
                          label: l10n.langChinese,
                          isSelected: localeProvider.locale.languageCode == 'zh',
                          theme: theme,
                        ),
                        _buildLanguageMenuItem(
                          value: 'eo',
                          flag: '🌐',
                          label: l10n.langEsperanto,
                          isSelected: localeProvider.locale.languageCode == 'eo',
                          theme: theme,
                        ),
                      ],
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: colorScheme.surface,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: colorScheme.outlineVariant.withValues(alpha: 0.8),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _getLanguageFlag(localeProvider.locale.languageCode),
                              style: const TextStyle(fontSize: 16),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _getLanguageLabel(localeProvider.locale.languageCode, l10n),
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Icon(
                              Icons.unfold_more_rounded,
                              size: 16,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Appearance Section
            Text(
              l10n.appearanceSection,
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
                      l10n.materialThemeMode,
                      style: theme.textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SegmentedButton<ThemeMode>(
                      segments: [
                        ButtonSegment(
                          value: ThemeMode.system,
                          icon: const Icon(Icons.brightness_auto_rounded),
                          label: Text(l10n.themeModeSystem),
                        ),
                        ButtonSegment(
                          value: ThemeMode.light,
                          icon: const Icon(Icons.light_mode_rounded),
                          label: Text(l10n.themeModeLight),
                        ),
                        ButtonSegment(
                          value: ThemeMode.dark,
                          icon: const Icon(Icons.dark_mode_rounded),
                          label: Text(l10n.themeModeDark),
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
              l10n.appInformationSection,
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
                    _buildInfoRow(context, l10n.appIdentifier,
                        AppConstants.appId),
                    _buildInfoRow(
                        context, l10n.frameworkEngine, 'Flutter (v3.47.7 pinned)'),
                    _buildInfoRow(context, l10n.designSystem,
                        'Material Design 3 (Dynamic Color)'),
                    _buildInfoRow(context, l10n.targetPlatforms,
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

  String _getLanguageSubtitle(String code) {
    switch (code) {
      case 'zh':
        return '简体中文 (Simplified Chinese)';
      case 'eo':
        return 'Esperanto (Internacia Lingvo)';
      case 'en':
      default:
        return 'English (United States)';
    }
  }

  PopupMenuItem<String> _buildLanguageMenuItem({
    required String value,
    required String flag,
    required String label,
    required bool isSelected,
    required ThemeData theme,
  }) {
    final colorScheme = theme.colorScheme;
    return PopupMenuItem<String>(
      value: value,
      height: 38,
      child: Row(
        children: [
          Text(flag, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? colorScheme.primary : colorScheme.onSurface,
              ),
            ),
          ),
          if (isSelected) ...[
            const SizedBox(width: 8),
            Icon(Icons.check_rounded, size: 16, color: colorScheme.primary),
          ],
        ],
      ),
    );
  }

  String _getLanguageFlag(String code) {
    switch (code) {
      case 'zh':
        return '🇨🇳';
      case 'eo':
        return '🌐';
      case 'en':
      default:
        return '🇺🇸';
    }
  }

  String _getLanguageLabel(String code, AppLocalizations l10n) {
    switch (code) {
      case 'zh':
        return l10n.langChinese;
      case 'eo':
        return l10n.langEsperanto;
      case 'en':
      default:
        return l10n.langEnglish;
    }
  }
}
