import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
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
    final l10n = AppLocalizations.of(context);
    final catalog = Provider.of<CatalogProvider>(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 840;

        final isNarrow = constraints.maxWidth < 430;

        final productSelector = Center(
          child: SegmentedButton<VMwareProductFamily>(
            segments: [
              ButtonSegment<VMwareProductFamily>(
                value: VMwareProductFamily.workstationPro,
                label: Text(
                  isNarrow ? 'Workstation' : 'VMware Workstation Pro',
                ),
                icon: const Icon(Icons.computer_rounded),
              ),
              ButtonSegment<VMwareProductFamily>(
                value: VMwareProductFamily.fusion,
                label: Text(
                  isNarrow ? 'Fusion' : 'VMware Fusion',
                ),
                icon: const Icon(Icons.laptop_mac_rounded),
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
                hintText: l10n.searchPlaceholder,
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
              tooltip: l10n.syncOnlineCatalog,
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
              PopupMenuButton<String>(
                tooltip: l10n.filterPlatform,
                icon: Icon(
                  Icons.filter_list_rounded,
                  color: catalog.platformFilter != null
                      ? colorScheme.primary
                      : colorScheme.onSurfaceVariant,
                ),
                onSelected: (val) {
                  if (val == 'windows') {
                    catalog.setPlatformFilter(VMwarePlatform.windows);
                  } else if (val == 'linux') {
                    catalog.setPlatformFilter(VMwarePlatform.linux);
                  } else {
                    catalog.setPlatformFilter(null);
                  }
                },
                itemBuilder: (ctx) => [
                  PopupMenuItem<String>(
                    value: 'all',
                    child: Row(
                      children: [
                        Icon(
                          catalog.platformFilter == null
                              ? Icons.radio_button_checked_rounded
                              : Icons.radio_button_unchecked_rounded,
                          size: 16,
                          color: catalog.platformFilter == null
                              ? colorScheme.primary
                              : colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 8),
                        Text(l10n.allPlatforms),
                      ],
                    ),
                  ),
                  PopupMenuItem<String>(
                    value: 'windows',
                    child: Row(
                      children: [
                        Icon(
                          catalog.platformFilter == VMwarePlatform.windows
                              ? Icons.radio_button_checked_rounded
                              : Icons.radio_button_unchecked_rounded,
                          size: 16,
                          color: catalog.platformFilter == VMwarePlatform.windows
                              ? colorScheme.primary
                              : colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 8),
                        Text(l10n.windowsOnly),
                      ],
                    ),
                  ),
                  PopupMenuItem<String>(
                    value: 'linux',
                    child: Row(
                      children: [
                        Icon(
                          catalog.platformFilter == VMwarePlatform.linux
                              ? Icons.radio_button_checked_rounded
                              : Icons.radio_button_unchecked_rounded,
                          size: 16,
                          color: catalog.platformFilter == VMwarePlatform.linux
                              ? colorScheme.primary
                              : colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 8),
                        Text(l10n.linuxOnly),
                      ],
                    ),
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
                        flex: 5,
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
                        flex: 6,
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
    final l10n = AppLocalizations.of(context);

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
              l10n.fetchingReleases,
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
              l10n.noOnlineReleasesLoaded,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              catalog.syncStatusMessage ?? l10n.authRequiredDesc,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              alignment: WrapAlignment.center,
              children: [
                FilledButton.icon(
                  icon: const Icon(Icons.sync_rounded, size: 18),
                  label: Text(l10n.syncOnlineCatalog),
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
                OutlinedButton.icon(
                  icon: const Icon(Icons.vpn_key_rounded, size: 16),
                  label: Text(l10n.reauthenticate),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (_) => const LoginDialog(),
                    );
                  },
                ),
              ],
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
