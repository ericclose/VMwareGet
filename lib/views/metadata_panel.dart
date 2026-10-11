import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
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
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label copied to clipboard!'),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
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
              'Select a release to inspect technical metadata',
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
                    Row(
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
                        const SizedBox(width: 8),
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
                      '${item.platformLabel} • Build ${item.buildNumber} • ${item.fileSize}',
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
          if (downloadItem == null)
            FilledButton.icon(
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.download_rounded),
              label: const Text(
                'Download Installer Package',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
              ),
              onPressed: () async {
                final confirmed = await DownloadDirDialog.showIfNeeded(context);
                if (!confirmed) return;
                downloadProvider.startDownload(
                  release: item,
                  session: authSession,
                  sessionCookie: authSession?.cookieJar ??
                      authSession?.sessionToken,
                );
                onNavigateToDownloads();
              },
            )
          else ...[
            Container(
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
                              ? 'Package Downloaded'
                              : 'Downloading (${(downloadItem.progress * 100).toStringAsFixed(0)}%)',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          downloadItem.status == DownloadStatus.completed
                              ? 'Verified against SHA256 & MD5'
                              : downloadItem.formattedSpeed,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (downloadItem.status == DownloadStatus.completed) ...[
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                      ),
                      icon: const Icon(Icons.folder_open_rounded, size: 16),
                      label: const Text('Show in Finder (定位文件)'),
                      onPressed: () =>
                          downloadProvider.openContainingFolder(downloadItem.id),
                    ),
                    const SizedBox(width: 8),
                  ],
                  FilledButton.tonal(
                    onPressed: onNavigateToDownloads,
                    child: const Text('View Manager'),
                  ),
                ],
              ),
            ),
          ],

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
                'Technical Metadata Specification',
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
            title: 'File Name',
            value: item.fileName,
            action: IconButton(
              tooltip: 'Copy File Name',
              icon: const Icon(Icons.copy_rounded, size: 16),
              onPressed: () =>
                  _copyToClipboard(context, 'File Name', item.fileName),
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
                  title: 'Release Date',
                  value: item.releaseDate,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildMetadataCard(
                  context,
                  icon: Icons.update_rounded,
                  title: 'Last Updated',
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
                'Cryptographic Checksums',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // SHA-256 Checksum Badge
          ChecksumBadge(
            label: 'SHA2 (SHA-256)',
            checksum: item.sha256,
            icon: Icons.shield_outlined,
          ),
          const SizedBox(height: 8),

          // MD5 Checksum Badge
          ChecksumBadge(
            label: 'MD5 Checksum',
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
                        'Licensing & Entitlement Note',
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
            label: const Text('View on Broadcom Support Portal'),
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
