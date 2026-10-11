import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/vmware_product.dart';
import '../providers/catalog_provider.dart';
import '../widgets/product_card.dart';
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
            const SizedBox(width: 12),
            if (catalog.selectedFamily == VMwareProductFamily.workstationPro)
              PopupMenuButton<TargetPlatform?>(
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
                    value: TargetPlatform.windows,
                    child: Text('Windows only'),
                  ),
                  const PopupMenuItem(
                    value: TargetPlatform.linux,
                    child: Text('Linux only'),
                  ),
                ],
              ),
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
                            ? Center(
                                child: Text(
                                  'No releases found matching query',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
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
                    ? Center(
                        child: Text(
                          'No releases found matching query',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      )
                    : releasesList,
              ),
            ],
          ),
        );
      },
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
