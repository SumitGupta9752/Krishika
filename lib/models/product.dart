import 'package:uuid/uuid.dart';

class LocalizedText {
  final String en;
  final String? hi;

  LocalizedText({
    required this.en,
    this.hi,
  });

  factory LocalizedText.fromJson(Map<String, dynamic> json) {
    return LocalizedText(
      en: json['en'] ?? '',
      hi: json['hi'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'en': en,
      'hi': hi,
    };
  }
}


class Product {
  final String id;
  final LocalizedText title;
  final LocalizedText description;
  final double price;
  final double discountPercentage;
  final int stock;
  final String thumbnail;
  final double averageRating;
  final int _quantity; // Keep the final quantity
  int mutableQuantity; // Add a mutable quantity
  final DateTime createdAt;

  Product({
    String? id,
    required this.title,
    required this.description,
    required this.price,
    required this.discountPercentage,
    required this.stock,
    required this.thumbnail,
    required this.averageRating,
    int quantity = 1,
    required this.createdAt,
  }) : id = id ?? const Uuid().v4(),
       _quantity = quantity,
       mutableQuantity = quantity;

  // Getter for quantity that returns the mutable value
  int get quantity => mutableQuantity;

  // Equality based on ID
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Product &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  Product copyWith({
    String? id,
    LocalizedText? title,
    LocalizedText? description,
    double? price,
    double? discountPercentage,
    int? stock,
    String? thumbnail,
    double? averageRating,
    int? quantity,
    DateTime? createdAt,
    int? mutableQuantity,  // Add this line
  }) {
    return Product(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      price: price ?? this.price,
      discountPercentage: discountPercentage ?? this.discountPercentage,
      stock: stock ?? this.stock,
      thumbnail: thumbnail ?? this.thumbnail,
      averageRating: averageRating ?? this.averageRating,
      quantity: quantity ?? _quantity,
      createdAt: createdAt ?? this.createdAt,
    )..mutableQuantity = mutableQuantity ?? this.mutableQuantity;  // Add this line
  }

  factory Product.fromJson(Map<String, dynamic> json) {
    try {
      print('Parsing JSON data: $json'); // Print incoming JSON

      final product = Product(
        id: json['_id'] as String? ?? json['id'] as String?,
        title: LocalizedText.fromJson(json['title']),
        description: LocalizedText.fromJson(json['description']),
        price: (json['price'] as num?)?.toDouble() ?? 0.0,
        discountPercentage: (json['discountPercentage'] as num?)?.toDouble() ?? 0.0,
        stock: json['stock'] as int? ?? 0,
        thumbnail: json['thumbnail'] as String? ?? '',
        averageRating: (json['averageRating'] as num?)?.toDouble() ?? 0.0,
        quantity: json['quantity'] as int? ?? 1,
        createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      );

      print('Created Product object:');
      print('ID: ${product.id}');
      print('Title: ${product.title.en}');
      print('Price: ${product.price}');
      print('Quantity: ${product.quantity}');
      print('Thumbnail: ${product.thumbnail}');

      return product;
    } catch (e) {
      print('Error parsing product: $e');
      print('JSON data: $json');
      rethrow;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title.toJson(),
      'description': description.toJson(),
      'price': price,
      'discountPercentage': discountPercentage,
      'stock': stock,
      'thumbnail': thumbnail,
      'averageRating': averageRating,
      'quantity': quantity,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  @override
  String toString() {
    return 'Product{id: $id, title: ${title.en}, quantity: $quantity, createdAt: $createdAt}';
  }
}



// Example usage
// void main() {    \
//   final product = Product(
//     id: '123',
//     title: LocalizedText(en: 'Sample Product', hi: 'नमूना उत्पाद'),
//     description: LocalizedText(en: 'This is a sample product.', hi: 'यह एक नमूना उत्पाद है।'),
//     price: 29.99,
//     discountPercentage: 10.0,
//     stock: 100,
//     thumbnail: 'https://example.com/image.jpg',
//     averageRating: 4.5,
//     quantity: 1,
//     createdAt: DateTime.now(),
//   );