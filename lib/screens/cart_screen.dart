import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';
import '../models/product.dart';
import 'home_screen.dart';
import 'delivery_location_screen.dart';
import '../constants.dart';
import '../services/api_service.dart';

class CartScreen extends StatefulWidget {
  final List<Product> cartItems;

  const CartScreen({
    super.key,
    required this.cartItems,
  });

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final _couponController = TextEditingController();
  final _addressController = TextEditingController();
  List<Product> _items = [];
  final double _taxRate = 0.18; // 18% GST
  final double _deliveryCharge = 40.0; // Fixed delivery charge
  bool _isLoading = true; // Add loading state

  @override
  void initState() {
    super.initState();
    _loadCartItems();
  }

  Future<void> _loadCartItems() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      if (token == null) throw Exception('No auth token found');

      final api = ApiService(baseUrl: Constants.apiBaseUrl);

      // Get cart items
      final cartResponse = await api.dio.get(
        '/cart',  // Make sure this endpoint exists
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        ),
      );

      if (cartResponse.statusCode == 200) {
        final cartData = cartResponse.data;
        print('Cart Data from API: $cartData');

        List<Product> updatedItems = [];

        // Process each cart item
        for (var item in cartData['items'] as List) {
          try {
            // Get product details including stock
            final productResponse = await api.dio.get(
              '/product/${item['product']['_id']}',  // Updated endpoint
              options: Options(
                headers: {
                  'Authorization': 'Bearer $token',
                  'Content-Type': 'application/json',
                },
              ),
            );

            if (productResponse.statusCode == 200) {
              final productData = productResponse.data;
              
              // Create product with stock information
              final product = Product.fromJson({
                ...item['product'] as Map<String, dynamic>,
                'stock': productData['stock'] ?? 0,
                'quantity': item['quantity'] ?? 1
              });

              print('Product loaded: ${product.title.en}');
              print('Stock: ${product.stock}');
              print('Cart quantity: ${product.quantity}');

              updatedItems.add(product);
            }
          } catch (e) {
            print('Error loading product details: $e');
            // Create product with default stock if details fetch fails
            final product = Product.fromJson({
              ...item['product'] as Map<String, dynamic>,
              'quantity': item['quantity'] ?? 1
            });
            updatedItems.add(product);
          }
        }

        setState(() {
          _items = updatedItems..sort((a, b) => b.createdAt.compareTo(a.createdAt));
          _isLoading = false;
        });
      } else {
        throw Exception('Failed to load cart items: ${cartResponse.statusCode}');
      }
    } catch (e) {
      print('Error loading cart items: $e');
      setState(() {
        _isLoading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load cart: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> addToCart(String productId, int quantity) async {
    try {
      final product = _items.firstWhere((item) => item.id == productId);
      
      // Debug logs
      print('Updating quantity for ${product.title.en}');
      print('Current quantity: ${product.mutableQuantity}');
      print('New quantity: $quantity');
      print('Stock: ${product.stock}');

      if (quantity <= 0) {
        _showSnack('Quantity must be at least 1');
        return;
      }

      if (quantity > product.stock) {
        _showSnack('Only ${product.stock} items available');
        return;
      }

      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      if (token == null) throw Exception('No auth token found');

      final api = ApiService(baseUrl: Constants.apiBaseUrl);
      
      // Update to match backend route and structure
      final response = await api.dio.put(
        '/cart', // Changed to match backend route
        data: {
          'productId': productId,
          'quantity': quantity,
        },
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        ),
      );

      print('API Response: ${response.data}'); // Debug log

      if (response.statusCode == 200) {
        // Update local state with response data
        setState(() {
          final index = _items.indexWhere((item) => item.id == productId);
          if (index != -1) {
            _items[index].mutableQuantity = quantity;
          }
        });
        
        // Reload cart to ensure sync with server
        await _loadCartItems();
        
        _showSnack('Cart updated successfully');
      } else {
        // Revert the quantity change if API call fails
        setState(() {
          final index = _items.indexWhere((item) => item.id == productId);
          if (index != -1) {
            _items[index].mutableQuantity = product.quantity;
          }
        });
        throw Exception('Failed to update cart: ${response.statusCode}');
      }
    } catch (e) {
      print('Error updating cart: $e');
      _showSnack('Failed to update cart: $e');
      
      // Revert quantity on error
      setState(() {
        final index = _items.indexWhere((item) => item.id == productId);
        if (index != -1) {
          _items[index].mutableQuantity = _items[index].quantity;
        }
      });
    }
  }

  Future<void> _saveCartItems() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      if (token == null) {
        throw Exception('No auth token found');
      }

      // Save to backend
      final api = ApiService(baseUrl: Constants.apiBaseUrl);
      
      // Save each item to the backend
      for (var item in _items) {
        await api.dio.post(
          '/cart',
          data: {
            'productId': item.id,
            'quantity': item.quantity,
          },
          options: Options(
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
          ),
        );
      }

      // Save to local storage
      final saveList = _items.map((item) {
        print("Saving item with ID: ${item.id}"); // Debug log
        return jsonEncode(item.toJson());
      }).toList();
      await prefs.setStringList('cart_items', saveList);
      
    } catch (e) {
      print("Error saving cart items: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save cart: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      rethrow;
    }
  }

  Future<void> _deleteCartItem(String productId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      if (token == null) {
        throw Exception('No auth token found');
      }

      final api = ApiService(baseUrl: Constants.apiBaseUrl);
      final response = await api.dio.delete(
        '/cart/$productId',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        ),
      );

      if (response.statusCode == 200) {
        // Remove from local state
        setState(() {
          _items.removeWhere((item) => item.id == productId);
        });

        // Update local storage
        await _saveCartItems();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white),
                  const SizedBox(width: 8),
                  Text('product removed from cart'),
                ],
              ),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              margin: const EdgeInsets.all(8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          );
        }
      } else {
        throw Exception('Failed to delete item: ${response.statusCode}');
      }
    } catch (e) {
      print('Error deleting cart item: $e');
      // if (mounted) {
      //   ScaffoldMessenger.of(context).showSnackBar(
      //     SnackBar(
      //       content: Text('Failed to remove item: $e'),
      //       backgroundColor: Colors.red,
      //       behavior: SnackBarBehavior.floating,
      //     ),
      //   );
      // }
    }
  }

  double _calculateSubtotal() {
    return _items.fold(0.0, (sum, item) => 
      sum + (item.price * (1 - item.discountPercentage / 100) * item.quantity));
  }

  double _calculateTax(double subtotal) {
    return subtotal * _taxRate;
  }

  double _calculateTotal(double subtotal, double tax) {
    return subtotal + tax + _deliveryCharge;
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Widget _buildPriceDetails() {
    final subtotal = _calculateSubtotal();
    final tax = _calculateTax(subtotal);
    final total = _calculateTotal(subtotal, tax);

    return Card(
      elevation: 2,
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Price Details',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Divider(),
            _buildPriceRow('Subtotal', '₹${subtotal.toStringAsFixed(2)}'),
            _buildPriceRow('GST (18%)', '₹${tax.toStringAsFixed(2)}'),
            _buildPriceRow('Delivery Charge', '₹${_deliveryCharge.toStringAsFixed(2)}'),
            const Divider(),
            _buildPriceRow(
              'Total Amount', 
              '₹${total.toStringAsFixed(2)}',
              isBold: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPriceRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: isBold ? Theme.of(context).primaryColor : null,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Cart'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _items.isEmpty
              ? const Center(child: Text('Your cart is empty'))
              : Column(
                  children: [
                    // Cart Items List - Takes remaining space
                    Expanded(
                      child: ListView.builder(
                        itemCount: _items.length,
                        itemBuilder: (context, index) {
                          final item = _items[index];
                          final discountedPrice = item.price * (1 - item.discountPercentage / 100);
                          print("Rendering cart item with ID: ${item.id}"); // Debug log
                          return Container(
                            key: ValueKey(item.id), // Ensure unique key using ID
                            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Item number badge
                                Container(
                                  margin: const EdgeInsets.only(left: 12, top: 8),
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[200],
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    'Item ${index + 1}',
                                    style: TextStyle(
                                      color: Colors.grey[700],
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                                // Product details

                                Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // Product Image
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: Image.network(
                                          item.thumbnail,
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
                                              item.title.en,
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
                                                if (item.discountPercentage > 0) ...[
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
                                                      '${item.discountPercentage.round()}% OFF',
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
                                          ],
                                        ),
                                      ),
                                      // Delete button
                                      IconButton(
                                        icon: const Icon(Icons.delete_outline, color: Colors.red),
                                        onPressed: () => _deleteCartItem(item.id),
                                      ),
                                    ],
                                  ),
                                ),
                                // Quantity Controls

                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Container(
                                        decoration: BoxDecoration(
                                          border: Border.all(color: Colors.grey[300]!),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Row(
                                          children: [
                                            IconButton(
                                              icon: const Icon(Icons.remove),
                                              onPressed: () async {
                                                if (item.mutableQuantity > 1) {
                                                  final newQuantity = item.mutableQuantity - 1;
                                                  // Update UI immediately for responsiveness
                                                  setState(() {
                                                    item.mutableQuantity = newQuantity;
                                                  });
                                                  // Make API call to persist change
                                                  await addToCart(item.id, newQuantity);
                                                }
                                              },
                                              padding: EdgeInsets.zero,
                                              constraints: const BoxConstraints(),
                                              color: item.mutableQuantity > 1 ? Theme.of(context).primaryColor : Colors.grey,
                                            ),
                                            Padding(
                                              padding: const EdgeInsets.symmetric(horizontal: 12),
                                              child: Text(
                                                '${item.mutableQuantity}',
                                                style: const TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold
                                                ),
                                              ),
                                            ),
                                            IconButton(
                                              icon: const Icon(Icons.add),
                                              onPressed: () async {
                                                if (item.mutableQuantity < item.stock) {
                                                  final newQuantity = item.mutableQuantity + 1;
                                                  // Update UI immediately for responsiveness
                                                  setState(() {
                                                    item.mutableQuantity = newQuantity;
                                                  });
                                                  // Make API call to persist change
                                                  await addToCart(item.id, newQuantity);
                                                } else {
                                                  _showSnack('Only ${item.stock} items available');
                                                }
                                              },
                                              padding: EdgeInsets.zero,
                                              constraints: const BoxConstraints(),
                                              color: item.mutableQuantity < item.stock ? Theme.of(context).primaryColor : Colors.grey,
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Stock: ${item.stock}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: item.stock < 5 ? Colors.red : Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                    
                    // Order Summary Card
                    _buildPriceDetails(),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: ElevatedButton(
                        onPressed: _items.isEmpty ? null : () async {
                          final prefs = await SharedPreferences.getInstance();
                          final userName = prefs.getString('user_name');
                          final userPhone = prefs.getString('user_phone');
                          
                          if (userName == null || userPhone == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Please login first to proceed'),
                                backgroundColor: Colors.red,
                              ),
                            );
                            return;
                          }

                          final subtotal = _calculateSubtotal();
                          final tax = _calculateTax(subtotal);
                          final total = _calculateTotal(subtotal, tax);


                          // Navigate to DeliveryLocationScreen if order creation fails
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => DeliveryLocationScreen(
                                totalAmount: total,
                                products: _items,
                              ),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 50),
                          backgroundColor: Theme.of(context).primaryColor,
                          foregroundColor: Colors.white
                        ),
                        child: const Text(
                          'Proceed to Checkout',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _buildQuantityButton({
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(4),
      ),
      child: InkWell(
        onTap: onPressed,
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Icon(icon, size: 20),
        ),
      ),
    );
  }
}
