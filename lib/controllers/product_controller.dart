import 'package:flutter/cupertino.dart';

import '../dao/product_dao.dart';
import '../models/product_model.dart';

class ProductController extends ChangeNotifier {
  final ProductDao _productDao = ProductDao();

  List<ProductModel> _products = [];
  List<ProductModel> _filteredProducts = [];
  bool _isLoading = false;
  String _searchTerm = '';
  String _selectedCategory = '';

  List<ProductModel> get products => _filteredProducts;
  bool get isLoading => _isLoading;
  String get searchTerm => _searchTerm;
  String get selectedCategory => _selectedCategory;

  Future<void> loadProducts() async {
    try {
      _isLoading = true;
      notifyListeners();

      _products = await _productDao.getAll();
      _filteredProducts = List.from(_products);

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      throw Exception('Erreur lors du chargement des produits: $e');
    }
  }

  void searchProducts(String searchTerm) {
    _searchTerm = searchTerm;
    _applyFilters();
  }

  void filterByCategory(String category) {
    _selectedCategory = category;
    _applyFilters();
  }

  Future<void> sortProductsByName({bool ascending = true}) async {
    try {
      _isLoading = true;
      notifyListeners();

      _products = await _productDao.getProductsSortedByName(ascending);
      _filteredProducts = List.from(_products);

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      throw Exception('Erreur lors du tri des produits par nom: $e');
    }
  }

  Future<void> sortProductsByPrice({bool ascending = true}) async {
    try {
      _isLoading = true;
      notifyListeners();

      _products = await _productDao.getProductsSortedByPrice(ascending);
      _filteredProducts = List.from(_products);

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      throw Exception('Erreur lors du tri des produits par prix: $e');
    }
  }

  void _applyFilters() {
    _filteredProducts = _products.where((product) {
      final matchesSearch = _searchTerm.isEmpty ||
          product.nom.toLowerCase().contains(_searchTerm.toLowerCase()) ||
          product.description.toLowerCase().contains(_searchTerm.toLowerCase());

      final matchesCategory = _selectedCategory.isEmpty ||
          product.categorie == _selectedCategory;

      return matchesSearch && matchesCategory;
    }).toList();

    notifyListeners();
  }

  Future<void> addProduct(ProductModel product) async {
    try {
      await _productDao.create(product);
      await loadProducts();
    } catch (e) {
      throw Exception('Erreur lors de l\'ajout du produit: $e');
    }
  }

  Future<void> updateProduct(String id, ProductModel product) async {
    try {
      await _productDao.update(id, product);
      await loadProducts();
    } catch (e) {
      throw Exception('Erreur lors de la mise à jour du produit: $e');
    }
  }

  Future<void> deleteProduct(String id) async {
    try {
      await _productDao.delete(id);
      await loadProducts();
    } catch (e) {
      throw Exception('Erreur lors de la suppression du produit: $e');
    }
  }
}
