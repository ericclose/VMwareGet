import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../models/auth_session.dart';
import '../models/vmware_product.dart';
import '../services/catalog_service.dart';
import '../services/download_service.dart';
import '../views/login_dialog.dart';
import 'auth_provider.dart';

class CatalogProvider extends ChangeNotifier {
  final CatalogService _catalogService = CatalogService();

  VMwareProductFamily _selectedFamily = VMwareProductFamily.workstationPro;
  VMwareReleaseItem? _selectedRelease;
  VMwarePlatform? _platformFilter;
  String _searchQuery = '';
  bool _isSyncing = false;
  String? _syncStatusMessage;
  bool _isSessionExpired = false;

  CatalogProvider() {
    _syncStatusMessage = 'Please login or sync to load Broadcom catalog online.';
    _initCachedCatalog();
  }

  void _initCachedCatalog() async {
    final hasCached = await _catalogService.loadCachedCatalog();
    if (hasCached) {
      final items = _catalogService.getReleasesForFamily(_selectedFamily);
      if (items.isNotEmpty) {
        _selectedRelease = items.first;
      }
      _syncStatusMessage = 'Cached catalog loaded. Ready to sync online.';
      notifyListeners();
    }
  }

  VMwareProductFamily get selectedFamily => _selectedFamily;
  VMwareReleaseItem? get selectedRelease => _selectedRelease;
  VMwarePlatform? get platformFilter => _platformFilter;
  String get searchQuery => _searchQuery;
  bool get isSyncing => _isSyncing;
  String? get syncStatusMessage => _syncStatusMessage;
  bool get isSessionExpired => _isSessionExpired;
  CatalogService get catalogService => _catalogService;

  void clearSessionExpired() {
    if (_isSessionExpired) {
      _isSessionExpired = false;
      notifyListeners();
    }
  }

  List<VMwareReleaseItem> get filteredReleases {
    return _catalogService.searchReleases(
      family: _selectedFamily,
      query: _searchQuery,
      platform: _platformFilter,
    );
  }

  void selectFamily(VMwareProductFamily family) {
    if (_selectedFamily == family) return;
    _selectedFamily = family;
    _platformFilter = null;
    final items = _catalogService.getReleasesForFamily(family);
    _selectedRelease = items.isNotEmpty ? items.first : null;
    notifyListeners();
  }

  void selectRelease(VMwareReleaseItem release) {
    _selectedRelease = release;
    notifyListeners();
  }

  void setPlatformFilter(VMwarePlatform? platform) {
    _platformFilter = platform;
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void clearCatalog() async {
    await _catalogService.clearCatalog();
    _selectedRelease = null;
    _searchQuery = '';
    _isSessionExpired = false;
    _syncStatusMessage = 'Please login or sync to load Broadcom catalog online.';
    notifyListeners();
  }

  Future<void> refreshFromOnline(
    AuthSession? session, {
    BuildContext? context,
  }) async {
    if (session == null) {
      _syncStatusMessage = 'Broadcom session required to fetch online catalog.';
      notifyListeners();
      if (context != null && context.mounted) {
        final l10n = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.authRequiredDesc),
            action: SnackBarAction(
              label: l10n.signIn,
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (_) => const LoginDialog(),
                );
              },
            ),
          ),
        );
      }
      return;
    }
    _isSyncing = true;
    _syncStatusMessage = 'Connecting to Broadcom servers...';
    notifyListeners();

    try {
      final success = await _catalogService.syncOnlineCatalog(
        session,
        context: context,
        onStatusUpdate: (msg) {
          _syncStatusMessage = msg;
          notifyListeners();
        },
      );
      if (success) {
        _isSessionExpired = false;
        if (context != null && context.mounted) {
          try {
            Provider.of<AuthProvider>(context, listen: false).clearSessionExpired();
          } catch (_) {}
        }
        final items = _catalogService.getReleasesForFamily(_selectedFamily);
        _syncStatusMessage =
            'Catalog synced live from Broadcom (${items.length} releases, direct links ready)';
        if (items.isNotEmpty) {
          _selectedRelease = items.first;
        }
      } else {
        _syncStatusMessage = _catalogService.lastSyncError ??
            'Unable to fetch online catalog. Please verify session.';
      }
    } on BroadcomAuthExpiredException {
      _isSessionExpired = true;
      _syncStatusMessage = 'Broadcom session expired. Please log in again.';
      if (context != null && context.mounted) {
        try {
          Provider.of<AuthProvider>(context, listen: false).notifySessionExpired();
        } catch (_) {}
        final l10n = AppLocalizations.of(context);
        final colorScheme = Theme.of(context).colorScheme;
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: colorScheme.error,
            duration: const Duration(seconds: 8),
            content: Row(
              children: [
                const Icon(Icons.lock_clock_outlined, color: Colors.white, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    l10n.broadcomSessionExpiredTip,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
            action: SnackBarAction(
              label: l10n.reloginAction,
              textColor: Colors.amberAccent,
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (_) => const LoginDialog(),
                );
              },
            ),
          ),
        );
      }
    } catch (e) {
      _syncStatusMessage = 'Sync error: $e';
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }
}
