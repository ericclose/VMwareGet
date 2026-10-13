import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../l10n/app_localizations.dart';
import '../models/auth_session.dart';
import '../models/download_item.dart';
import '../models/vmware_product.dart';
import '../providers/auth_provider.dart';
import '../providers/download_provider.dart';
import '../widgets/checksum_badge.dart';
import '../widgets/download_dir_dialog.dart';

class MetadataPanel extends StatelessWidget {
  final VMwareReleaseItem? release;
  final VoidCallback onNavigateToDownloads;

  const MetadataPanel({
    super.key,
    required this.release,
    required this.onNavigateToDownloads,
  });

  void _copyToClipboard(BuildContext context, String label, String text) {
    final l10n = AppLocalizations.of(context);
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l10n.copiedToClipboard(label)),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _copyDownloadLink(
    BuildContext context,
    VMwareReleaseItem release,
    AuthSession? session,
    DownloadProvider downloadProvider,
  ) async {
    final l10n = AppLocalizations.of(context);
    final scaffold = ScaffoldMessenger.of(context);

    scaffold.showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 10),
            Text(l10n.generatingDownloadLink),
          ],
        ),
        duration: const Duration(milliseconds: 600),
        behavior: SnackBarBehavior.floating,
      ),
    );

    final url = await downloadProvider.resolveDownloadUrl(
      release: release,
      session: session,
    );

    await Clipboard.setData(ClipboardData(text: url));

    scaffold.hideCurrentSnackBar();
    scaffold.showSnackBar(
      SnackBar(
        content: Text(l10n.copyDirectDownloadLinkSuccess),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final l10n = AppLocalizations.of(context);
    final downloadProvider = Provider.of<DownloadProvider>(context);
    final authSession =
        Provider.of<AuthProvider>(context, listen: false).currentSession;

    if (release == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.inventory_2_outlined,
              size: 48,
              color: colorScheme.outlineVariant,
            ),
            const SizedBox(height: 12),
            Text(
              l10n.selectReleaseToInspect,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    final item = release!;
    final downloadItem = downloadProvider.getItemForRelease(item.id);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title & Header
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        Text(
                          item.family == VMwareProductFamily.workstationPro
                              ? 'VMware Workstation Pro'
                              : 'VMware Fusion',
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            letterSpacing: -0.5,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'v${item.version}',
                            style: theme.textTheme.labelMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: colorScheme.onPrimaryContainer,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${item.platformLabel} • ${l10n.buildNumber} ${item.buildNumber} • ${item.fileSize}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Download Action Banner / Button
          LayoutBuilder(
            builder: (context, constraints) {
              final isCompact = constraints.maxWidth < 460;
              if (downloadItem == null) {
                if (isCompact) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      FilledButton.icon(
                        style: FilledButton.styleFrom(
                          minimumSize: const Size.fromHeight(48),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        icon: const Icon(Icons.download_rounded),
                        label: Text(
                          l10n.downloadPackage,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        onPressed: () async {
                          final confirmed =
                              await DownloadDirDialog.showIfNeeded(context);
                          if (!confirmed) return;
                          downloadProvider.startDownload(
                            release: item,
                            session: authSession,
                            sessionCookie: authSession?.cookieJar ??
                                authSession?.sessionToken,
                          );
                          onNavigateToDownloads();
                        },
                      ),
                      const SizedBox(height: 8),
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(44),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        icon: const Icon(Icons.link_rounded, size: 20),
                        label: Text(l10n.copyDirectDownloadLink),
                        onPressed: () => _copyDownloadLink(
                          context,
                          item,
                          authSession,
                          downloadProvider,
                        ),
                      ),
                    ],
                  );
                }
                return Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        style: FilledButton.styleFrom(
                          minimumSize: const Size.fromHeight(48),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        icon: const Icon(Icons.download_rounded),
                        label: Text(
                          l10n.downloadPackage,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        onPressed: () async {
                          final confirmed =
                              await DownloadDirDialog.showIfNeeded(context);
                          if (!confirmed) return;
                          downloadProvider.startDownload(
                            release: item,
                            session: authSession,
                            sessionCookie: authSession?.cookieJar ??
                                authSession?.sessionToken,
                          );
                          onNavigateToDownloads();
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(0, 48),
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: const Icon(Icons.link_rounded, size: 20),
                      label: Text(l10n.copyDirectDownloadLink),
                      onPressed: () => _copyDownloadLink(
                        context,
                        item,
                        authSession,
                        downloadProvider,
                      ),
                    ),
                  ],
                );
              }

              // downloadItem != null
              if (isCompact) {
                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: downloadItem.status == DownloadStatus.completed
                        ? Colors.green.withValues(alpha: 0.15)
                        : colorScheme.primaryContainer.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: downloadItem.status == DownloadStatus.completed
                          ? Colors.green.withValues(alpha: 0.5)
                          : colorScheme.primary.withValues(alpha: 0.5),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Icon(
                            downloadItem.status == DownloadStatus.completed
                                ? Icons.check_circle_rounded
                                : Icons.downloading_rounded,
                            color: downloadItem.status == DownloadStatus.completed
                                ? Colors.green
                                : colorScheme.primary,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  downloadItem.status == DownloadStatus.completed
                                      ? l10n.packageDownloaded
                                      : '${l10n.statusDownloading} (${(downloadItem.progress * 100).toStringAsFixed(0)}%)',
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  downloadItem.status == DownloadStatus.completed
                                      ? l10n.verifiedAgainstChecksums
                                      : downloadItem.formattedSpeed,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            tooltip: l10n.copyDirectDownloadLink,
                            icon: const Icon(Icons.link_rounded),
                            onPressed: () => _copyDownloadLink(
                              context,
                              item,
                              authSession,
                              downloadProvider,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        alignment: WrapAlignment.end,
                        spacing: 8,
                        runSpacing: 6,
                        children: [
                          if (downloadItem.status == DownloadStatus.completed)
                            OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                visualDensity: VisualDensity.compact,
                              ),
                              icon: const Icon(Icons.folder_open_rounded, size: 16),
                              label: Text(
                                Platform.isMacOS
                                    ? l10n.showInFinder
                                    : l10n.showInFolder,
                              ),
                              onPressed: () => downloadProvider
                                  .openContainingFolder(downloadItem.id),
                            ),
                          FilledButton.tonal(
                            style: FilledButton.styleFrom(
                              visualDensity: VisualDensity.compact,
                            ),
                            onPressed: onNavigateToDownloads,
                            child: Text(l10n.viewManager),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              }

              return Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: downloadItem.status == DownloadStatus.completed
                      ? Colors.green.withValues(alpha: 0.15)
                      : colorScheme.primaryContainer.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: downloadItem.status == DownloadStatus.completed
                        ? Colors.green.withValues(alpha: 0.5)
                        : colorScheme.primary.withValues(alpha: 0.5),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      downloadItem.status == DownloadStatus.completed
                          ? Icons.check_circle_rounded
                          : Icons.downloading_rounded,
                      color: downloadItem.status == DownloadStatus.completed
                          ? Colors.green
                          : colorScheme.primary,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            downloadItem.status == DownloadStatus.completed
                                ? l10n.packageDownloaded
                                : '${l10n.statusDownloading} (${(downloadItem.progress * 100).toStringAsFixed(0)}%)',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            downloadItem.status == DownloadStatus.completed
                                ? l10n.verifiedAgainstChecksums
                                : downloadItem.formattedSpeed,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: l10n.copyDirectDownloadLink,
                      icon: const Icon(Icons.link_rounded),
                      onPressed: () => _copyDownloadLink(
                        context,
                        item,
                        authSession,
                        downloadProvider,
                      ),
                    ),
                    const SizedBox(width: 4),
                    if (downloadItem.status == DownloadStatus.completed) ...[
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                        ),
                        icon: const Icon(Icons.folder_open_rounded, size: 16),
                        label: Text(
                          Platform.isMacOS
                              ? l10n.showInFinder
                              : l10n.showInFolder,
                        ),
                        onPressed: () => downloadProvider
                            .openContainingFolder(downloadItem.id),
                      ),
                      const SizedBox(width: 8),
                    ],
                    FilledButton.tonal(
                      onPressed: onNavigateToDownloads,
                      child: Text(l10n.viewManager),
                    ),
                  ],
                ),
              );
            },
          ),

          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 16),

          // Technical Details Section Header
          Row(
            children: [
              Icon(
                Icons.data_object_rounded,
                size: 20,
                color: colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                l10n.techMetadataSpec,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // File Name Row
          _buildMetadataCard(
            context,
            icon: Icons.insert_drive_file_outlined,
            title: l10n.fileName,
            value: item.fileName,
            action: IconButton(
              tooltip: l10n.copyLabel(l10n.fileName),
              icon: const Icon(Icons.copy_rounded, size: 16),
              onPressed: () =>
                  _copyToClipboard(context, l10n.fileName, item.fileName),
            ),
          ),
          const SizedBox(height: 8),

          // Direct Download Link Row
          _buildMetadataCard(
            context,
            icon: Icons.link_rounded,
            title: l10n.copyDirectDownloadLink,
            value: item.filePath != null
                ? '${item.fileName} (Direct CDN Link)'
                : item.officialDownloadUrl,
            action: IconButton(
              tooltip: l10n.copyDirectDownloadLink,
              icon: const Icon(Icons.copy_rounded, size: 16),
              onPressed: () => _copyDownloadLink(
                context,
                item,
                authSession,
                downloadProvider,
              ),
            ),
          ),
          const SizedBox(height: 8),

          // Release Date & Last Updated Grid
          Row(
            children: [
              Expanded(
                child: _buildMetadataCard(
                  context,
                  icon: Icons.calendar_today_rounded,
                  title: l10n.releaseDate,
                  value: item.releaseDate,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildMetadataCard(
                  context,
                  icon: Icons.update_rounded,
                  title: l10n.lastUpdated,
                  value: item.lastUpdated,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Checksums Header
          Row(
            children: [
              Icon(
                Icons.verified_rounded,
                size: 20,
                color: Colors.green.shade700,
              ),
              const SizedBox(width: 8),
              Text(
                l10n.cryptographicChecksums,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // SHA-256 Checksum Badge
          ChecksumBadge(
            label: l10n.sha256Checksum,
            checksum: item.sha256,
            icon: Icons.shield_outlined,
          ),
          const SizedBox(height: 8),

          // MD5 Checksum Badge
          ChecksumBadge(
            label: l10n.md5Checksum,
            checksum: item.md5,
            icon: Icons.fingerprint_outlined,
          ),
          const SizedBox(height: 20),

          // Notes / Licensing Banner
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: colorScheme.outlineVariant.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  size: 20,
                  color: colorScheme.primary,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.licensingNote,
                        style: theme.textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        item.notes,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // External Portal Link
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(40),
            ),
            icon: const Icon(Icons.open_in_new_rounded, size: 16),
            label: Text(l10n.viewOnBroadcomPortal),
            onPressed: () {
              final uri = Uri.parse(item.officialDownloadUrl);
              launchUrl(uri, mode: LaunchMode.externalApplication);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMetadataCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String value,
    Widget? action,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: colorScheme.onSurfaceVariant),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  value,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (action != null) action,
        ],
      ),
    );
  }
}
