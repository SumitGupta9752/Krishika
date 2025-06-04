import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import '../models/product.dart';
import '../constants.dart';
import 'login_screen.dart';
import 'profile_screen.dart';
import 'product_details_screen.dart';
import 'cart_screen.dart';  // Add this import
import 'dart:convert'; // Add this import for jsonEncode and jsonDecode
import 'delivery_location_screen.dart';
import 'my_orders_screen.dart'; // Add this import
import 'about_screen.dart'; // Add this import
import 'customer_support_screen.dart'; // Add this import
import 'package:shimmer/shimmer.dart'; // Add this import
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart'; // Add this import for LanguageProvider
import '../providers/language_provider.dart'; // Add this import for LanguageProvider
import '../translations/app_translations.dart'; // Add this import for AppTranslations
import '../translations/app_translations.dart';
import 'language_settings_screen.dart';

export 'home_screen.dart' show HomeScreenState;

// Add the LoadingSkeleton class right after the imports and before the HomeScreen class
class LoadingSkeleton extends StatelessWidget {
  const LoadingSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Column(
        children: List.generate(
          6,
          (index) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Container(
              height: 100,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => HomeScreenState(); // Remove underscore
}

// Make HomeScreenState public by removing underscore
class HomeScreenState extends State<HomeScreen> {
  // Add these variables at the top of HomeScreenState class
  String? _userName;
  String? _userEmail;
  String? _userPhone;
  String? token;
  List<Product> products = [];
  bool isLoading = true;
  String? error;

  // Add cart items list
  List<Product> cartItems = [];

  // Add these variables at the top with other state variables
  List<Product> filteredProducts = [];
  final TextEditingController _searchController = TextEditingController();

  // Add this method to calculate total items in cart
  int get _cartItemCount {
    return cartItems.fold(0, (sum, item) => sum + item.quantity);
  }

  @override
  void initState() {
    super.initState();
    _loadToken();
    _fetchProducts();
    _loadCartItems();
    _loadUserData();
    // Remove this line as it's causing issues
    // filteredProducts = products; 
  }

  Future<void> _loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      token = prefs.getString('jwt_token');
    });
    if (token == null) {
      if (!mounted) return;
      _navigateToLogin();
    }
  }

  // Update the search method
  void _searchProducts(String query) {
    setState(() {
      if (query.isEmpty) {
        // When search is empty, show all products
        filteredProducts = List.from(products);
      } else {
        // Filter products based on search query
        filteredProducts = products.where((product) {
          final titleLower = product.title.en.toLowerCase();
          final descriptionLower = product.description.en.toLowerCase();
          final searchLower = query.toLowerCase();
          
          return titleLower.contains(searchLower) || 
                 descriptionLower.contains(searchLower);
        }).toList();
      }
    });
  }

  // Update the fetch products method
  Future<void> _fetchProducts() async {
    try {
      final api = ApiService(baseUrl: Constants.apiBaseUrl);
      final fetchedProducts = await api.getProducts();
      setState(() {
        products = fetchedProducts;
        // Initialize filtered products with all products
        filteredProducts = List.from(fetchedProducts);
        isLoading = false;
        error = null;
      });
    } catch (e) {
      setState(() {
        error = 'Failed to load products: $e';
        isLoading = false;
      });
    }
  }

  void _navigateToLogin() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('jwt_token');
    if (!mounted) return;
    _navigateToLogin();
  }

  // Update the addToCart method
  void addToCart(Product product, int quantity) async {
    try {
      // Check stock availability
      if (product.stock <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Sorry, this product is out of stock'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Check current cart quantity
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      if (token == null) throw Exception('No auth token found');

      final api = ApiService(baseUrl: Constants.apiBaseUrl);

      // Get current cart items
      final cartResponse = await api.dio.get(
        '/cart',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        ),
      );

      if (cartResponse.statusCode == 200) {
        final cartData = cartResponse.data;
        final cartItems = cartData['items'] as List;
        
        // Find if product already exists in cart
        final existingItem = cartItems.firstWhere(
          (item) => item['product']['_id'] == product.id,
          orElse: () => null,
        );

        // Calculate total quantity including existing cart quantity
        final existingQuantity = existingItem != null ? existingItem['quantity'] as int : 0;
        final totalQuantity = existingQuantity + quantity;

        // Check if total quantity exceeds stock
        if (totalQuantity > product.stock) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Cannot add more. Only ${product.stock} items available in stock'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }

        // Add to cart API call
        final response = await api.dio.post(
          '/cart',
          data: {
            'productId': product.id,
            'quantity': quantity,
          },
          options: Options(
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
          ),
        );

        if (response.statusCode == 200) {
          await _loadCartItems();
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Product added to cart successfully'),
                backgroundColor: Colors.green,
              ),
            );
          }
        } else {
          throw Exception('Failed to add to cart');
        }
      }
    } catch (e) {
      print('Error adding to cart: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to add to cart: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Update the load method to handle API response
  Future<void> _loadCartItems() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      if (token == null) {
        throw Exception('No auth token found');
      }

      final api = ApiService(baseUrl: Constants.apiBaseUrl);
      final response = await api.dio.get(
        '/cart',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        ),
      );

      if (response.statusCode == 200) {
        final cartData = response.data;
        print('Cart Data from API: $cartData'); // Debug log

        setState(() {
          cartItems = (cartData['items'] as List).map((item) {
            final product = Product.fromJson(item['product'] as Map<String, dynamic>);
            return product.copyWith(
              quantity: item['quantity'] as int? ?? 1
            );
          }).toList();
        });

        // Debug log cart items
        print('Loaded ${cartItems.length} items from cart');
        print('Total quantity in cart: $_cartItemCount');
        for (var item in cartItems) {
          print('Item: ${item.title.en}, Quantity: ${item.quantity}');
        }
      }
    } catch (e) {
      print('Error loading cart items: $e');
    }
  }

  void _navigateToCart() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CartScreen(cartItems: cartItems),
      ),
    );
    // Reload cart items when returning from cart screen
    _loadCartItems();
  }

  // Add this method to load user data
  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userName = prefs.getString('user_name');
      _userEmail = prefs.getString('user_email');
      _userPhone = prefs.getString('user_phone');
      
      // Debug log
      print('Loaded user data:');
      print('Name: $_userName');
      print('Email: $_userEmail');
      print('Phone: $_userPhone');
    });
  }

  // Add this method to refresh cart items after product details
  void _navigateToProductDetails(Product product) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProductDetailsScreen(product: product),
      ),
    );
    // Reload cart items when returning from product details
    _loadCartItems();
  }

  // sidescreen

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Consumer<LanguageProvider>(
          builder: (context, languageProvider, child) {
            return Text(
              AppTranslations.getText('appName', languageProvider.currentLanguage),
              style: const TextStyle(fontWeight: FontWeight.bold),
            );
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ProfileScreen()),
            ),
          ),
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.shopping_cart),
                onPressed: _navigateToCart,
              ),
              if (_cartItemCount > 0)
                Positioned(
                  right: 5,
                  top: 5,
                  child: Container(
                    padding: const EdgeInsets.all(1),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      _cartItemCount.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchProducts,
          ),
        ],
      ),
      drawer: Consumer<LanguageProvider>(
        builder: (context, languageProvider, child) {
          return Drawer(
            child: ListView(
              children: [
                UserAccountsDrawerHeader(
                  accountName: Text(_userName ?? 'User'),
                  accountEmail: Text(_userEmail ?? _userPhone ?? 'No contact info'),
                  currentAccountPicture: const CircleAvatar(
                    backgroundColor: Colors.white,
                    child: Icon(Icons.person, size: 35, color: Colors.green),
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor,
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.person),
                  title: Text(AppTranslations.getText('profile', languageProvider.currentLanguage)),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const ProfileScreen()),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.shopping_cart),
                  title: Text(AppTranslations.getText('cart', languageProvider.currentLanguage)),
                  onTap: () {
                    Navigator.pop(context);
                    _navigateToCart();
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.shopping_bag_outlined),
                  title: Text(AppTranslations.getText('myOrders', languageProvider.currentLanguage)),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const MyOrdersScreen(),
                      ),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.info_outline),
                  title: Text(AppTranslations.getText('aboutUs', languageProvider.currentLanguage)),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AboutScreen(),
                      ),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.support_agent),
                  title: Text(AppTranslations.getText('customerSupport', languageProvider.currentLanguage)),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const CustomerSupportScreen(),
                      ),
                    );
                  },
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.language),
                  title: Text(AppTranslations.getText('languageSettings', languageProvider.currentLanguage)),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const LanguageSettingsScreen(),
                      ),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.logout),
                  title: Text(AppTranslations.getText('logout', languageProvider.currentLanguage)),
                  onTap: _logout,
                ),
              ],
            ),
          );
        },
      ),
      body: error != null
          ? Center(child: Text(error!))
          : isLoading
              ? const LoadingSkeleton() // Replace CircularProgressIndicator with LoadingSkeleton
              : SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Search Bar
                        Container(
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(15),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.1),
                                spreadRadius: 1,
                                blurRadius: 4,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                          child: Consumer<LanguageProvider>(
                            builder: (context, languageProvider, child) {
                              return TextFormField(
                                controller: _searchController,
                                decoration: InputDecoration(
                                  hintText: AppTranslations.getText(
                                    'search',
                                    languageProvider.currentLanguage,
                                  ),
                                  hintStyle: TextStyle(
                                    color: Colors.grey[400],
                                    fontSize: 16,
                                  ),
                                  prefixIcon: Icon(
                                    Icons.search_rounded,
                                    color: Colors.grey[400],
                                    size: 24,
                                  ),
                                  suffixIcon: _searchController.text.isNotEmpty
                                      ? IconButton(
                                          icon: const Icon(Icons.clear),
                                          color: Colors.grey[400],
                                          onPressed: () {
                                            _searchController.clear();
                                            _searchProducts('');
                                          },
                                        )
                                      : null,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(15),
                                    borderSide: BorderSide.none,
                                  ),
                                  filled: true,
                                  fillColor: Colors.grey[50],
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(15),
                                    borderSide: BorderSide(
                                      color: Colors.grey[200]!,
                                      width: 1,
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(15),
                                    borderSide: BorderSide(
                                      color: Theme.of(context)
                                          .primaryColor
                                          .withOpacity(0.5),
                                      width: 1.5,
                                    ),
                                  ),
                                ),
                                onChanged: _searchProducts,
                                textInputAction: TextInputAction.search,
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: Colors.black87,
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Featured Banner
                        Container(
                          height: 160,
                          decoration: BoxDecoration(
                            color: Colors.green[50],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Consumer<LanguageProvider>(
                            builder: (context, languageProvider, child) {
                              return Row(
                                children: [
                                  Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.all(16.0),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            AppTranslations.getText('plantTreatment', languageProvider.currentLanguage),
                                            style: Theme.of(context).textTheme.titleLarge,
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            AppTranslations.getText('expertCare', languageProvider.currentLanguage),
                                            style: Theme.of(context).textTheme.titleMedium,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  Image.network(
                                    'https://ik.imagekit.io/znmlisjqg/download__1___Xv1H5OoD.jpeg',
                                    width: 120,
                                    fit: BoxFit.cover,
                                  ),
                                ],
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Popular Items Section
                        _buildSectionHeader('popularTreatments'),
                        SizedBox(
                          height: 220,
                          child: filteredProducts.isEmpty
                              ? const Center(child: Text('No products found'))
                              : ListView.builder(
                                  scrollDirection: Axis.horizontal,
                                  itemCount: filteredProducts.length,
                                  itemBuilder: (context, index) =>
                                    _buildPopularItemCard(filteredProducts[index]),
                                ),
                        ),
                        const SizedBox(height: 20),

                        // All Products Grid
                        _buildSectionHeader('allSolutions'),
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 0.60, // Increased from 0.58 to give more vertical space
                            mainAxisSpacing: 16,
                            crossAxisSpacing: 16,
                          ),
                          itemCount: filteredProducts.length,
                          itemBuilder: (context, index) => _buildProductCard(filteredProducts[index]),
                        ),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Consumer<LanguageProvider>(
      builder: (context, languageProvider, child) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                AppTranslations.getText(title, languageProvider.currentLanguage),
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              TextButton(
                onPressed: () {
                  // TODO: Show all items
                },
                child: Text(AppTranslations.getText('seeAll', languageProvider.currentLanguage)),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPopularItemCard(Product product) {
    return Container(
      width: 160,
      margin: const EdgeInsets.only(right: 16),
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: InkWell(
          onTap: () => _navigateToProductDetails(product),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(12)),
                child: Image.network(
                  product.thumbnail,
                  height: 120,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.title.en,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '₹${product.price}',
                      style: TextStyle(
                          color: Theme.of(context).primaryColor,
                          fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProductCard(Product product) {
    final discountedPrice = product.price * (1 - product.discountPercentage / 100);
    final isOutOfStock = product.stock <= 0;

    return Consumer<LanguageProvider>(
      builder: (context, languageProvider, child) {
        return Card(
          elevation: 2,
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: InkWell(
            onTap: () => _navigateToProductDetails(product),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image section with fixed height
                SizedBox(
                  height: 140,
                  width: double.infinity,
                  child: Stack(
                    children: [
                      Image.network(
                        product.thumbnail,
                        width: double.infinity,
                        height: double.infinity,
                        fit: BoxFit.cover,
                      ),
                      if (isOutOfStock)
                        Container(
                          color: Colors.black.withOpacity(0.6),
                          width: double.infinity,
                          height: double.infinity,
                          child: Center(
                            child: Text(
                              AppTranslations.getText('outOfStock', languageProvider.currentLanguage),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        )
                      else if (product.discountPercentage > 0)
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.green,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '${product.discountPercentage.toStringAsFixed(0)}% OFF',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                // Content section remains the same until the buttons
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        product.title.en,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        product.description.en,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 11,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Text(
                            '₹${discountedPrice.toStringAsFixed(0)}',
                            style: TextStyle(
                              color: Theme.of(context).primaryColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                          const Spacer(),
                          if (product.averageRating > 0) ...[
                            const Icon(Icons.star, size: 12, color: Colors.amber),
                            Text(
                              ' ${product.averageRating}',
                              style: const TextStyle(fontSize: 11),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 8),
                      // Modified buttons row
                      Row(
                        children: [
                          Expanded(
                            child: SizedBox(
                              height: 25,
                              child: ElevatedButton(
                                onPressed: isOutOfStock ? null : () => addToCart(product, 1),
                                style: ElevatedButton.styleFrom(
                                  padding: EdgeInsets.zero,
                                  backgroundColor: isOutOfStock ? Colors.grey[300] : Colors.grey[200],
                                  foregroundColor: isOutOfStock ? Colors.grey[500] : Colors.grey[800],
                                ),
                                child: Text(
                                  isOutOfStock 
                                    ? AppTranslations.getText('outOfStock', languageProvider.currentLanguage)
                                    : AppTranslations.getText('addToCart', languageProvider.currentLanguage),
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: SizedBox(
                              height: 25,
                              child: ElevatedButton(
                                onPressed: isOutOfStock ? null : () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => DeliveryLocationScreen(
                                        totalAmount: discountedPrice,
                                        products: [product],
                                      ),
                                    ),
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  padding: EdgeInsets.zero,
                                  backgroundColor: isOutOfStock ? Colors.grey[300] : Colors.purple[600],
                                  foregroundColor: isOutOfStock ? Colors.grey[500] : Colors.white,
                                ),
                                child: Text(
                                  AppTranslations.getText('buyNow', languageProvider.currentLanguage),
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}


