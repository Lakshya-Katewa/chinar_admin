import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/product.dart';
import '../services/firebase_service.dart';

final productsProvider = StreamProvider<List<Product>>((ref) {
  return FirebaseService.getProducts();
});

final productNotifierProvider = Provider<ProductNotifier>((ref) {
  return ProductNotifier();
});

class ProductNotifier {
  Future<void> addProduct(Product product) async {
    await FirebaseService.addProduct(product);
  }

  Future<void> updateProduct(Product product) async {
    await FirebaseService.updateProduct(product);
  }

  Future<void> deleteProduct(String productId) async {
    await FirebaseService.deleteProduct(productId);
  }
}
