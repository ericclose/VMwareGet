import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../providers/download_provider.dart';
import '../widgets/download_progress_tile.dart';

class DownloadsView extends StatelessWidget {
  final VoidCallback onNavigateToCatalog;

  const DownloadsView({
    super.key,
    required this.onNavigateToCatalog,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final l10n = AppLocalizations.of(context);
    final downloadProvider = Provider.of<DownloadProvider>(context);

    final downloads = downloadProvider.allDownloads;

    final isCompact = MediaQuery.of(context).size.width < 600;

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? 14 : 20,
        vertical: isCompact ? 14 : 20,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header banner with directory path
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: colorScheme.outlineVariant.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.folder_special_rounded,
                  size: 22,
                  color: colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.downloadDirectoryLabel,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        downloadProvider.downloadDirectory ??
                            l10n.resolvingLocalPath,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontFamily: 'monospace',
                          fontSize: 12,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.folder_open_rounded, size: 20),
                  tooltip: l10n.openInFinderOrExplorer,
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
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Download stats header
          LayoutBuilder(
            builder: (context, constraints) {
              final isCompact = constraints.maxWidth < 460;
              return Row(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Flexible(
                          child: Text(
                            l10n.activeRecentTransfers,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (downloadProvider.activeCount > 0) ...[
                          const SizedBox(width: 8),
                          Badge(
                            label: Text(
                                l10n.activeCountBadge(downloadProvider.activeCount)),
                            backgroundColor: colorScheme.primary,
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (downloadProvider.completedCount > 0)
                    isCompact
                        ? IconButton(
                            tooltip: l10n.clearCompletedDownloads,
                            icon: const Icon(Icons.clear_all_rounded),
                            visualDensity: VisualDensity.compact,
                            onPressed: () =>
                                downloadProvider.clearCompletedDownloads(),
                          )
                        : TextButton.icon(
                            style: TextButton.styleFrom(
                              visualDensity: VisualDensity.compact,
                            ),
                            icon: const Icon(Icons.clear_all_rounded, size: 16),
                            label: Text(l10n.clearCompletedDownloads),
                            onPressed: () =>
                                downloadProvider.clearCompletedDownloads(),
                          ),
                ],
              );
            },
          ),
          const SizedBox(height: 8),

          // Main list or empty state
          Expanded(
            child: downloads.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.download_done_rounded,
                          size: 56,
                          color: colorScheme.outlineVariant,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          l10n.noDownloadsYet,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          l10n.noDownloadsDesc,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 16),
                        FilledButton.tonalIcon(
                          icon: const Icon(Icons.explore_rounded, size: 18),
                          label: Text(l10n.browseCatalog),
                          onPressed: onNavigateToCatalog,
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: downloads.length,
                    itemBuilder: (ctx, i) {
                      return DownloadProgressTile(item: downloads[i]);
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
