import 'package:flutter/material.dart';
import '../models/auth_session.dart';
import '../models/vmware_product.dart';
import '../services/catalog_service.dart';

class CatalogProvider extends ChangeNotifier {
  final CatalogService _catalogService = CatalogService();

  VMwareProductFamily _selectedFamily = VMwareProductFamily.workstationPro;
  VMwareReleaseItem? _selectedRelease;
  VMwarePlatform? _platformFilter;
  String _searchQuery = '';
  bool _isSyncing = false;
  String? _syncStatusMessage;

  CatalogProvider() {
    _syncStatusMessage = 'Please login or sync to load Broadcom catalog online.';
  }

  VMwareProductFamily get selectedFamily => _selectedFamily;
  VMwareReleaseItem? get selectedRelease => _selectedRelease;
  VMwarePlatform? get platformFilter => _platformFilter;
  String get searchQuery => _searchQuery;
  bool get isSyncing => _isSyncing;
  String? get syncStatusMessage => _syncStatusMessage;
  CatalogService get catalogService => _catalogService;

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

  void clearCatalog() {
    _catalogService.clearCatalog();
    _selectedRelease = null;
    _searchQuery = '';
    _syncStatusMessage = 'Please login or sync to load Broadcom catalog online.';
    notifyListeners();
  }

  Future<void> refreshFromOnline(AuthSession? session) async {
    if (session == null) {
      _syncStatusMessage = 'Broadcom session required to fetch online catalog.';
      notifyListeners();
      return;
    }
    _isSyncing = true;
    _syncStatusMessage = 'Connecting to Broadcom servers...';
    notifyListeners();

    try {
      final success = await _catalogService.syncOnlineCatalog(session);
      if (success) {
        _syncStatusMessage = 'Catalog synced live from Broadcom';
        final items = _catalogService.getReleasesForFamily(_selectedFamily);
        if (items.isNotEmpty) {
          _selectedRelease = items.first;
        }
      } else {
        _syncStatusMessage = 'Unable to fetch online catalog. Please verify session.';
      }
    } catch (e) {
      _syncStatusMessage = 'Sync error: $e';
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }
}
