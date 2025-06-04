class Review {
  final String id;
  final String productId;
  final String userId;
  final String userName;
  final double rating;
  final String review;
  final DateTime createdAt;

  Review({
    required this.id,
    required this.productId,
    required this.userId,
    this.userName = 'Unknown User',
    required this.rating,
    required this.review,
    required this.createdAt,
  });

  factory Review.fromJson(Map<String, dynamic> json) {
    return Review(
      id: json['_id'] ?? '',
      productId: json['productId'] ?? '',
      userId: json['userId'] ?? '',
      rating: double.parse((json['rating'] ?? 0).toString()),
      review: json['review'] ?? '',
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
    );
  }
}