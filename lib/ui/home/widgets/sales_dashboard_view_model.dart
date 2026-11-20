import 'package:flutter/foundation.dart';
import '../../models/product_item.dart';
import '../../../service/pos_local_store.dart';

/// Clean View Model managing search, filtering, category selection and sorting for Sales.
class SalesDashboardViewModel extends ChangeNotifier {
  SalesDashboardViewModel({required this.store}) {
    store.addListener(_onStoreChanged);
  }

  final PosLocalStore store;

  String _searchQuery = '';
  String _selectedCategory = 'All';
  bool _inStockOnly = false;
  String _sortBy = 'name';
  String? _successMessage;

  String get searchQuery => _searchQuery;
  String get selectedCategory => _selectedCategory;
  bool get inStockOnly => _inStockOnly;
  String get sortBy => _sortBy;
  String? get successMessage => _successMessage;

  void _onStoreChanged() {
    notifyListeners();
  }

  @override
  void dispose() {
    store.removeListener(_onStoreChanged);
    super.dispose();
  }

  void setSearchQuery(String query) {
    if (_searchQuery != query) {
      _searchQuery = query;
      notifyListeners();
    }
  }

  void setSelectedCategory(String category) {
    if (_selectedCategory != category) {
      _selectedCategory = category;
      notifyListeners();
    }
  }

  void setInStockOnly(bool value) {
    if (_inStockOnly != value) {
      _inStockOnly = value;
      notifyListeners();
    }
  }

  void setSortBy(String sort) {
    if (_sortBy != sort) {
      _sortBy = sort;
      notifyListeners();
    }
  }

  void setSuccessMessage(String? message) {
    _successMessage = message;
    notifyListeners();
  }

  void resetFilters() {
    _searchQuery = '';
    _selectedCategory = 'All';
    _inStockOnly = false;
    _sortBy = 'name';
    notifyListeners();
  }

  List<String> get availableCategories {
    final categories = <String>{'All'};
    for (final product in store.products) {
      final category = product.category?.trim();
      if (category != null && category.isNotEmpty) {
        categories.add(category);
      }
    }
    return categories.toList();
  }

  List<ProductItem> get filteredProducts {
    final query = _searchQuery.trim().toLowerCase();
    var list = store.products.where((product) {
      if (_selectedCategory != 'All') {
        final category = product.category?.trim().toLowerCase();
        if (category != _selectedCategory.toLowerCase()) return false;
      }

      if (_inStockOnly && store.availableStockForProduct(product) <= 0) {
        return false;
      }

      if (query.isEmpty) return true;

      final name = product.name.toLowerCase();
      final category = (product.category ?? '').toLowerCase();
      final code = (product.code ?? '').toLowerCase();
      return name.contains(query) || category.contains(query) || code.contains(query);
    }).toList();

    switch (_sortBy) {
      case 'price-low':
        list.sort((a, b) => a.priceValue.compareTo(b.priceValue));
        break;
      case 'price-high':
        list.sort((a, b) => b.priceValue.compareTo(a.priceValue));
        break;
      case 'name':
      default:
        list.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
        break;
    }

    return list;
  }
}
