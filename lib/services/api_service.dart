import 'package:http/http.dart' as http;
import 'package:dio/dio.dart';
import 'dart:convert';
import 'dart:async';
import '../models/auth_response.dart';
import '../models/login_request.dart';
import '../models/signup_request.dart';
import '../models/product.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart'; // Added for BuildContext and Navigator
import 'package:krishika/screens/order_success_screen.dart'; // Adjust the import based on your project structure

class ApiService {
  final String baseUrl;
  final http.Client _client = http.Client();
  final Dio dio;

  ApiService({required this.baseUrl})
      : dio = Dio(BaseOptions(
          baseUrl: baseUrl,
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
        ));

  final Map<String, String> _headers = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  String? token;

  Future<http.Response> _retryRequest(Future<http.Response> Function() request) async {
    int attempts = 0;
    const maxAttempts = 3;
    const initialDelay = Duration(seconds: 1);

    while (attempts < maxAttempts) {
      try {
        return await request();
      } catch (e) {
        attempts++;
        if (attempts == maxAttempts) rethrow;

        print('Request failed, attempt $attempts of $maxAttempts. Retrying...');
        await Future.delayed(initialDelay * attempts);
      }
    }

    throw Exception('Failed to connect after $maxAttempts attempts');
  }

  Future<AuthResponse> login(LoginRequest request) async {
    try {
      final uri = Uri.parse('$baseUrl/auth/login');
      final requestBody = jsonEncode(request.toJson());

      print('Attempting login to: $uri');
      print('Request body: $requestBody');

      final response = await _retryRequest(() => http.post(
            uri,
            headers: _headers,
            body: requestBody,
          ));

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final loginResponse = AuthResponse.fromJson(jsonDecode(response.body));
        // After successful login
        token = loginResponse.token;
        print('Token received: $token');

        // Save token
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('auth_token', loginResponse.token);
        await prefs.setString('user_name', loginResponse.name); // Replace with actual user name
        await prefs.setString('user_email', loginResponse.email); // Replace with actual email
        await prefs.setString('user_phone', loginResponse.phone); // Replace with actual phone
        await prefs.setString('user_id', loginResponse.userId); // Replace with actual user ID
        print('Token saved to SharedPreferences');

        return loginResponse;
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['message'] ?? 'Login failed');
      }
    } on http.ClientException catch (e) {
      print('Client exception: $e');
      throw Exception('Network error: Please check your internet connection');
    } on FormatException {
      throw Exception('Invalid response format from server');
    } catch (e) {
      throw Exception('Login failed: ${e.toString()}');
    }
  }

  Future<AuthResponse> signup(SignupRequest request) async {
    try {
      final uri = Uri.parse('$baseUrl/auth/signup');
      final requestBody = jsonEncode(request.toJson());

      print('Attempting signup to: $uri');
      print('Request body: $requestBody');

      final response = await _retryRequest(() => http.post(
            uri,
            headers: _headers,
            body: requestBody,
          ));

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        print('Signup Response: $data');
        return AuthResponse.fromJson(data);
      } else {
        print('Signup Error: ${response.body}');
        throw Exception('Signup failed: ${response.body}');
      }
    } catch (e) {
      print('Signup Exception: $e');
      throw Exception('Signup failed: $e');
    }
  }

  Future<List<Product>> getProducts() async {
    try {
      final uri = Uri.parse('$baseUrl/product');

      print('Fetching products from: $uri');

      final headers = {
        ..._headers,
        if (token != null) 'Authorization': 'Bearer $token',
      };

      final response = await _retryRequest(() => http.get(
            uri,
            headers: headers,
          ));

      print('Response Status Code: ${response.statusCode}');
      print('Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final List<dynamic> jsonList = jsonDecode(response.body);
        print('Parsed JSON: $jsonList');
        return jsonList.map((json) => Product.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load products: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching products: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> createOrder({
    required List<Product> products,
    required Map<String, String> deliveryDetails,
    required double subtotal,
    required double gst,
    required double deliveryFee,
    required double total,
    required BuildContext context,
  }) async {
    try {
      final token = await getStoredToken();
      
      if (token == null) {
        throw Exception('Authentication token is missing');
      }

      final orderData = {
        'items': products.map((product) => {
          'productId': product.id,
          'quantity': product.quantity,
          'price': product.price,
          'totalPrice': product.price * product.quantity,
        }).toList(),
        'total': total,
        'subtotal': subtotal,
        'gst': gst,
        'deliveryFee': deliveryFee,
        'orderStatus': 'Pending',
        'address': {
          'street': deliveryDetails['address'] ?? '',
          'city': deliveryDetails['city'] ?? '',
          'state': deliveryDetails['state'] ?? '',
          'pincode': deliveryDetails['pincode'] ?? '',
          'landmark': deliveryDetails['landmark'] ?? '',
        },
        'paymentStatus': 'Pending',
      };

      print('Debug - Order Data: ${json.encode(orderData)}');

      dio.options.headers['Authorization'] = 'Bearer $token';
      
      final response = await dio.post(
        '/order',
        data: orderData,
      );
      
      print('Order response: ${response.data}');

      if (response.statusCode == 201 || response.statusCode == 200) {
        // Get orderId directly from response.data
        final orderId = response.data['_id'] ?? 'Unknown';
        
        if (!context.mounted) return response.data;

        // Clear cart after successful order
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('cart_items');

        // Navigate directly to OrderSuccessScreen
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (context) => OrderSuccessScreen(orderId: orderId),
          ),
          (route) => false, // This removes all previous routes
        );
        
        return response.data;
      } else {
        throw Exception('Failed to create order');
      }
      
    } on DioException catch (e) {
      print('Order API error: ${e.message}');
      print('Response data: ${e.response?.data}');
      
      if (!context.mounted) throw Exception('Context no longer valid');
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to create order: ${e.message}'),
          backgroundColor: Colors.red,
        ),
      );
      
      throw Exception('Failed to create order: ${e.message}');
    }
  }

  Future<dynamic> get(String endpoint) async {
    try {
      final token = await getStoredToken();
      
      if (token == null) {
        throw Exception('Authentication token is missing');
      }

      dio.options.headers['Authorization'] = 'Bearer $token';
      
      final response = await dio.get(endpoint);
      
      if (response.statusCode == 200) {
        return response.data; // Return the data directly
      } else {
        throw Exception('Failed to fetch data: ${response.statusMessage}');
      }
    } on DioException catch (e) {
      print('API error: ${e.message}');
      print('Response data: ${e.response?.data}');
      throw Exception('Failed to fetch data: ${e.message}');
    }
  }

  Future<void> loadTokenOnAppStart() async {
    final prefs = await SharedPreferences.getInstance();
    token = prefs.getString('auth_token');
  }

  Future<String?> getStoredToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  void dispose() {
    _client.close();
    dio.close();
  }
}