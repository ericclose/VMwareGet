import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/catalog_provider.dart';
import '../providers/download_provider.dart';
import '../providers/theme_provider.dart';
import '../widgets/app_logo.dart';
import 'catalog_view.dart';
import 'downloads_view.dart';
import 'login_dialog.dart';
import 'settings_view.dart';

class DashboardView extends StatefulWidget {
  const DashboardView({super.key});

  @override
  State<DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends State<DashboardView> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      if (auth.isAuthenticated && auth.currentSession != null) {
        final catalog = Provider.of<CatalogProvider>(context, listen: false);
        catalog.refreshFromOnline(auth.currentSession);
      }
    });
  }

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
            label: const Text('Downloads'),
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
              const SizedBox(width: 4),

              // Quick Account & Session Menu with Fast Sign-out
              if (authProvider.isAuthenticated) ...[
                PopupMenuButton<String>(
                  tooltip: 'Account & Session Options',
                  offset: const Offset(0, 48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  icon: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircleAvatar(
                        radius: 14,
                        backgroundColor: colorScheme.primaryContainer,
                        child: Text(
                          ((authProvider.currentSession?.displayName.isNotEmpty ?? false)
                                  ? authProvider.currentSession!.displayName[0]
                                  : 'U')
                              .toUpperCase(),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onPrimaryContainer,
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.keyboard_arrow_down_rounded,
                        size: 18,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ],
                  ),
                  onSelected: (value) async {
                    if (value == 'settings') {
                      setState(() => _currentIndex = 2);
                    } else if (value == 'logout') {
                      final confirmed = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Sign Out / 注销登录'),
                          content: const Text(
                            'Are you sure you want to sign out? Your cached Broadcom session and access tokens will be cleared.',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(ctx).pop(false),
                              child: const Text('Cancel'),
                            ),
                            FilledButton(
                              style: FilledButton.styleFrom(
                                backgroundColor: Theme.of(ctx).colorScheme.error,
                              ),
                              onPressed: () => Navigator.of(ctx).pop(true),
                              child: const Text('Sign Out'),
                            ),
                          ],
                        ),
                      );
                      if (confirmed == true) {
                        await authProvider.logout();
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Signed out successfully. Session cleared.'),
                            ),
                          );
                        }
                      }
                    }
                  },
                  itemBuilder: (ctx) => [
                    PopupMenuItem<String>(
                      enabled: false,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            authProvider.currentSession?.displayName ?? 'Authenticated User',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            authProvider.currentSession?.email ?? '',
                            style: TextStyle(
                              fontSize: 12,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const PopupMenuDivider(),
                    const PopupMenuItem<String>(
                      value: 'settings',
                      child: Row(
                        children: [
                          Icon(Icons.manage_accounts_rounded, size: 18),
                          SizedBox(width: 10),
                          Text('Session Details (会话详情)'),
                        ],
                      ),
                    ),
                    PopupMenuItem<String>(
                      value: 'logout',
                      child: Row(
                        children: [
                          Icon(Icons.logout_rounded, size: 18, color: colorScheme.error),
                          const SizedBox(width: 10),
                          Text(
                            'Sign Out (注销登录)',
                            style: TextStyle(color: colorScheme.error, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ] else ...[
                FilledButton.tonalIcon(
                  style: FilledButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                  ),
                  icon: const Icon(Icons.login_rounded, size: 16),
                  label: const Text('Sign In (登录)'),
                  onPressed: () => showDialog(
                    context: context,
                    builder: (_) => const LoginDialog(),
                  ),
                ),
              ],
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
