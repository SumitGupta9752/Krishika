import 'package:flutter/material.dart';
import 'order_success_screen.dart';
import '../models/product.dart';
import 'payment_screen.dart';
import '../services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants.dart';

class OrderSummaryScreen extends StatefulWidget {
  final List<Product> products;
  final double totalAmount;
  final Map<String, String> deliveryDetails;
  final String paymentMethod;

  const OrderSummaryScreen({
    Key? key,
    required this.products,
    required this.totalAmount,
    required this.deliveryDetails,
    required this.paymentMethod,
  }) : super(key: key);

  @override
  State<OrderSummaryScreen> createState() => _OrderSummaryScreenState();
}

class _OrderSummaryScreenState extends State<OrderSummaryScreen> {
  bool _isLoading = false;
  final _apiService = ApiService(baseUrl: Constants.apiBaseUrl);

  Future<void> _placeOrder() async {
    setState(() => _isLoading = true);

    try {
      final subtotal = _calculateSubtotal();
      final gst = subtotal * 0.18; // 18% GST
      final deliveryFee = 40.0;
      final total = subtotal + gst + deliveryFee;

      final result = await _apiService.createOrder(
        products: widget.products,
        deliveryDetails: widget.deliveryDetails,
        subtotal: subtotal,
        gst: gst,
        deliveryFee: deliveryFee,
        total: total,
        context: context,
      );

      if (!mounted) return;

      // Clear cart after successful order
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('cart_items');

      // Extract orderId safely with null checking
      String orderId = '';
      if (result is Map<String, dynamic>) {
        orderId = result['_id'] ?? // Try direct _id
                result['orderId'] ?? // Try orderId
                result['order']?['_id'] ?? // Try nested order._id
                'Unknown'; // Fallback value
      }

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => OrderSuccessScreen(
            orderId: orderId,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to place order: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Order Summary'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Order Details Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Order Items',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Divider(height: 24),
                      _buildOrderedProductsList(),
                      const Divider(height: 24),
                      // Price Summary
                      _buildDetailRow('Items (${widget.products.length})', '₹${_calculateSubtotal().toStringAsFixed(2)}'),
                      _buildDetailRow('Delivery Charge', '₹40.00'),
                      _buildDetailRow('Tax (18%)', '₹${(_calculateSubtotal() * 0.18).toStringAsFixed(2)}'),
                      const Divider(height: 16),
                      _buildDetailRow(
                        'Total Amount',
                        '₹${widget.totalAmount.toStringAsFixed(2)}',
                        isHighlighted: true,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Delivery Details Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Delivery Details',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Divider(height: 24),
                      _buildDetailRow('Name', widget.deliveryDetails['name'] ?? ''),
                      _buildDetailRow('Phone', widget.deliveryDetails['phone'] ?? ''),
                      if (widget.deliveryDetails['alternatePhone']?.isNotEmpty ?? false)
                        _buildDetailRow('Alternate Phone', widget.deliveryDetails['alternatePhone'] ?? ''),
                      const SizedBox(height: 8),
                      const Text(
                        'Delivery Address',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        widget.deliveryDetails['address'] ?? '',
                        style: const TextStyle(
                          fontSize: 15,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (widget.deliveryDetails['landmark']?.isNotEmpty ?? false)
                        Text(
                          'Landmark: ${widget.deliveryDetails['landmark']}',
                          style: const TextStyle(
                            fontSize: 15,
                            height: 1.5,
                          ),
                        ),
                      const SizedBox(height: 8),
                      Text(
                        'PIN Code: ${widget.deliveryDetails['pincode'] ?? ''}',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Payment Method Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Payment Method',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Divider(height: 24),
                      _buildDetailRow('Selected Method', widget.paymentMethod),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: _isLoading ? null : _placeOrder,
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).primaryColor,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),    
            minimumSize: const Size(double.infinity, 50),
          ),
          child: _isLoading
              ? const SizedBox(
                  height: 24,
                  width: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Text(
                  'Place Order',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
        ),
      ),
    );
  }

  double _calculateSubtotal() {
    return widget.products.fold(0.0, (sum, product) {
      final discountedPrice = product.price * (1 - product.discountPercentage / 100);
      return sum + discountedPrice * product.quantity;
    });
  }

  Widget _buildDetailRow(String label, String value, {bool isHighlighted = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: isHighlighted ? FontWeight.bold : FontWeight.normal,
              color: isHighlighted ? Colors.green : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderedProductsList() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: widget.products.length,
      itemBuilder: (context, index) {
        final product = widget.products[index];
        final discountedPrice = product.price * (1 - product.discountPercentage / 100);
        
        return Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Product Image
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  product.thumbnail,
                  width: 80,
                  height: 80,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(width: 12),
              // Product Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.title.en,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          '₹${discountedPrice.toStringAsFixed(2)}',
                          style: const TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (product.discountPercentage > 0) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.red[400],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '${product.discountPercentage.round()}% OFF',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Quantity: ${product.quantity}',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}