import 'package:flutter/material.dart';
import '../models/vmware_product.dart';
import '../services/catalog_service.dart';

class CatalogProvider extends ChangeNotifier {
  final CatalogService _catalogService = CatalogService();

  VMwareProductFamily _selectedFamily = VMwareProductFamily.workstationPro;
  VMwareReleaseItem? _selectedRelease;
  TargetPlatform? _platformFilter;
  String _searchQuery = '';

  CatalogProvider() {
    // Select first release by default
    final initialList = _catalogService.getReleasesForFamily(_selectedFamily);
    if (initialList.isNotEmpty) {
      _selectedRelease = initialList.first;
    }
  }

  VMwareProductFamily get selectedFamily => _selectedFamily;
  VMwareReleaseItem? get selectedRelease => _selectedRelease;
  TargetPlatform? get platformFilter => _platformFilter;
  String get searchQuery => _searchQuery;

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

  void setPlatformFilter(TargetPlatform? platform) {
    _platformFilter = platform;
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }
}
