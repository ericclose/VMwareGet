import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/download_provider.dart';
import '../providers/theme_provider.dart';
import '../widgets/app_logo.dart';
import 'catalog_view.dart';
import 'downloads_view.dart';
import 'settings_view.dart';

class DashboardView extends StatefulWidget {
  const DashboardView({super.key});

  @override
  State<DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends State<DashboardView> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final downloadProvider = Provider.of<DownloadProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 720;

        final pages = [
          CatalogView(
            onNavigateToDownloads: () => setState(() => _currentIndex = 1),
          ),
          DownloadsView(
            onNavigateToCatalog: () => setState(() => _currentIndex = 0),
          ),
          const SettingsView(),
        ];

        final destinationList = [
          const NavigationDestination(
            icon: Icon(Icons.apps_outlined),
            selectedIcon: Icon(Icons.apps_rounded),
            label: 'Catalog',
          ),
          NavigationDestination(
            icon: downloadProvider.activeCount > 0
                ? Badge(
                    label: Text('${downloadProvider.activeCount}'),
                    child: const Icon(Icons.download_outlined),
                  )
                : const Icon(Icons.download_outlined),
            selectedIcon: downloadProvider.activeCount > 0
                ? Badge(
                    label: Text('${downloadProvider.activeCount}'),
                    child: const Icon(Icons.download_rounded),
                  )
                : const Icon(Icons.download_rounded),
            label: 'Downloads',
          ),
          const NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings_rounded),
            label: 'Settings',
          ),
        ];

        final railDestinations = [
          const NavigationRailDestination(
            icon: Icon(Icons.apps_outlined),
            selectedIcon: Icon(Icons.apps_rounded),
            label: Text('Catalog'),
          ),
          NavigationRailDestination(
            icon: downloadProvider.activeCount > 0
                ? Badge(
                    label: Text('${downloadProvider.activeCount}'),
                    child: const Icon(Icons.download_outlined),
                  )
                : const Icon(Icons.download_outlined),
            selectedIcon: downloadProvider.activeCount > 0
                ? Badge(
                    label: Text('${downloadProvider.activeCount}'),
                    child: const Icon(Icons.download_rounded),
                  )
                : const Icon(Icons.download_rounded),
            label: Text('Downloads'),
          ),
          const NavigationRailDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings_rounded),
            label: Text('Settings'),
          ),
        ];

        return Scaffold(
          appBar: AppBar(
            title: const AppLogo(size: 32, showText: true),
            actions: [
              IconButton(
                tooltip: themeProvider.isDarkMode
                    ? 'Switch to Light Theme'
                    : 'Switch to Dark Theme',
                icon: Icon(
                  themeProvider.isDarkMode
                      ? Icons.light_mode_rounded
                      : Icons.dark_mode_rounded,
                ),
                onPressed: () {
                  themeProvider.setThemeMode(
                    themeProvider.isDarkMode
                        ? ThemeMode.light
                        : ThemeMode.dark,
                  );
                },
              ),
              IconButton(
                tooltip: 'Account Settings',
                icon: const Icon(Icons.account_circle_outlined),
                onPressed: () => setState(() => _currentIndex = 2),
              ),
              const SizedBox(width: 8),
            ],
          ),
          body: Row(
            children: [
              if (isDesktop)
                NavigationRail(
                  selectedIndex: _currentIndex,
                  onDestinationSelected: (index) =>
                      setState(() => _currentIndex = index),
                  labelType: NavigationRailLabelType.all,
                  destinations: railDestinations,
                  trailing: Expanded(
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: IconButton(
                          tooltip: 'Sign Out',
                          icon: Icon(
                            Icons.logout_rounded,
                            color: colorScheme.outline,
                          ),
                          onPressed: () => authProvider.logout(),
                        ),
                      ),
                    ),
                  ),
                ),
              if (isDesktop) const VerticalDivider(thickness: 1, width: 1),
              Expanded(
                child: pages[_currentIndex],
              ),
            ],
          ),
          bottomNavigationBar: !isDesktop
              ? NavigationBar(
                  selectedIndex: _currentIndex,
                  onDestinationSelected: (index) =>
                      setState(() => _currentIndex = index),
                  destinations: destinationList,
                )
              : null,
        );
      },
    );
  }
}
