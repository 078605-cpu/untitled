// lib/product_model.dart

class Product {
  String id;
  String name;
  String description;
  double price;
  String condition;
  String? imageUrl; // Making image URL nullable

  Product({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.condition,
    this.imageUrl,
  });
}
