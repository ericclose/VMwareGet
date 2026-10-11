import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/vmware_product.dart';
import '../providers/auth_provider.dart';
import '../providers/catalog_provider.dart';
import '../widgets/product_card.dart';
import 'login_dialog.dart';
import 'metadata_panel.dart';

class CatalogView extends StatelessWidget {
  final VoidCallback onNavigateToDownloads;

  const CatalogView({
    super.key,
    required this.onNavigateToDownloads,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final catalog = Provider.of<CatalogProvider>(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 840;

        final productSelector = Center(
          child: SegmentedButton<VMwareProductFamily>(
            segments: const [
              ButtonSegment<VMwareProductFamily>(
                value: VMwareProductFamily.workstationPro,
                label: Text('VMware Workstation Pro'),
                icon: Icon(Icons.computer_rounded),
              ),
              ButtonSegment<VMwareProductFamily>(
                value: VMwareProductFamily.fusion,
                label: Text('VMware Fusion'),
                icon: Icon(Icons.laptop_mac_rounded),
              ),
            ],
            selected: {catalog.selectedFamily},
            onSelectionChanged: (set) {
              if (set.isNotEmpty) {
                catalog.selectFamily(set.first);
              }
            },
          ),
        );

        final searchAndFilters = Row(
          children: [
            Expanded(
              child: SearchBar(
                hintText: 'Search version, build, file name...',
                leading: const Icon(Icons.search_rounded, size: 20),
                elevation: const WidgetStatePropertyAll(0),
                backgroundColor: WidgetStatePropertyAll(
                  colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                ),
                shape: WidgetStatePropertyAll(
                  RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: colorScheme.outlineVariant.withValues(alpha: 0.4),
                    ),
                  ),
                ),
                padding: const WidgetStatePropertyAll(
                  EdgeInsets.symmetric(horizontal: 14),
                ),
                onChanged: (val) => catalog.setSearchQuery(val),
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filledTonal(
              tooltip: 'Sync Online from Broadcom',
              icon: catalog.isSyncing
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.cloud_sync_rounded, size: 20),
              onPressed: catalog.isSyncing
                  ? null
                  : () {
                      final session = Provider.of<AuthProvider>(context, listen: false).currentSession;
                      catalog.refreshFromOnline(session);
                    },
            ),
            if (catalog.selectedFamily == VMwareProductFamily.workstationPro) ...[
              const SizedBox(width: 4),
              PopupMenuButton<VMwarePlatform?>(
                tooltip: 'Filter Platform',
                initialValue: catalog.platformFilter,
                icon: Icon(
                  Icons.filter_list_rounded,
                  color: catalog.platformFilter != null
                      ? colorScheme.primary
                      : colorScheme.onSurfaceVariant,
                ),
                onSelected: (p) => catalog.setPlatformFilter(p),
                itemBuilder: (ctx) => [
                  const PopupMenuItem(
                    value: null,
                    child: Text('All Platforms'),
                  ),
                  const PopupMenuItem(
                    value: VMwarePlatform.windows,
                    child: Text('Windows only'),
                  ),
                  const PopupMenuItem(
                    value: VMwarePlatform.linux,
                    child: Text('Linux only'),
                  ),
                ],
              ),
            ],
          ],
        );

        final releasesList = ListView.builder(
          itemCount: catalog.filteredReleases.length,
          itemBuilder: (ctx, i) {
            final rel = catalog.filteredReleases[i];
            final isSelected = rel.id == catalog.selectedRelease?.id;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: ProductCard(
                release: rel,
                isSelected: isSelected,
                onTap: () {
                  catalog.selectRelease(rel);
                  if (!isWide) {
                    _showMobileDetailsSheet(context, rel);
                  }
                },
              ),
            );
          },
        );

        if (isWide) {
          return Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                productSelector,
                const SizedBox(height: 16),
                searchAndFilters,
                const SizedBox(height: 16),
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Left column: releases list
                      Expanded(
                        flex: 4,
                        child: catalog.filteredReleases.isEmpty
                            ? _buildEmptyState(
                                context,
                                catalog,
                                theme,
                                colorScheme,
                              )
                            : releasesList,
                      ),
                      const SizedBox(width: 16),
                      // Right column: detailed metadata panel
                      Expanded(
                        flex: 5,
                        child: Card(
                          margin: EdgeInsets.zero,
                          child: MetadataPanel(
                            release: catalog.selectedRelease,
                            onNavigateToDownloads: onNavigateToDownloads,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }

        // Mobile compact view
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              productSelector,
              const SizedBox(height: 12),
              searchAndFilters,
              const SizedBox(height: 12),
              Expanded(
                child: catalog.filteredReleases.isEmpty
                    ? _buildEmptyState(
                        context,
                        catalog,
                        theme,
                        colorScheme,
                      )
                    : releasesList,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(
    BuildContext context,
    CatalogProvider catalog,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    if (catalog.isSyncing) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 32,
              height: 32,
              child: CircularProgressIndicator(strokeWidth: 3),
            ),
            const SizedBox(height: 16),
            Text(
              'Fetching releases live from Broadcom...',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    if (catalog.searchQuery.trim().isNotEmpty) {
      return Center(
        child: Text(
          'No releases found matching "${catalog.searchQuery}"',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_sync_outlined, size: 48, color: colorScheme.outline),
            const SizedBox(height: 12),
            Text(
              'No Online Releases Loaded',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              catalog.syncStatusMessage ??
                  'Please sign in to your Broadcom account to fetch the live product catalog.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              icon: const Icon(Icons.sync_rounded, size: 18),
              label: const Text('Sync Online Catalog'),
              onPressed: () {
                final auth =
                    Provider.of<AuthProvider>(context, listen: false);
                if (auth.isAuthenticated) {
                  catalog.refreshFromOnline(auth.currentSession);
                } else {
                  showDialog(
                    context: context,
                    builder: (_) => const LoginDialog(),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showMobileDetailsSheet(BuildContext context, VMwareReleaseItem rel) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.85,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (_, controller) {
            return MetadataPanel(
              release: rel,
              onNavigateToDownloads: () {
                Navigator.of(ctx).pop();
                onNavigateToDownloads();
              },
            );
          },
        );
      },
    );
  }
}
