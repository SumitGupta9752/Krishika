import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'payment_screen.dart';
import '../models/product.dart'; // Import Product model
import 'order_summary_screen.dart'; // Import OrderSummaryScreen

class DeliveryLocationScreen extends StatefulWidget {
  final double totalAmount;
  final List<Product> products; // Add this

  const DeliveryLocationScreen({
    Key? key,
    required this.totalAmount,
    required this.products, // Add this
  }) : super(key: key);

  @override
  State<DeliveryLocationScreen> createState() => _DeliveryLocationScreenState();
}

class _DeliveryLocationScreenState extends State<DeliveryLocationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _landmarkController = TextEditingController();
  final _pincodeController = TextEditingController();
  final _alternatePhoneController = TextEditingController();
  final _cityController = TextEditingController(); // Add city controller
  final _stateController = TextEditingController(); // Add state controller
  String? _userId; // Add this line to declare _userId
  bool _isLoadingLocation = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadSavedAddress(); // Add this line
  }

  // Update the existing _loadUserData method
  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _nameController.text = prefs.getString('user_name') ?? '';
      _phoneController.text = prefs.getString('user_phone') ?? '';
      _userId = prefs.getString('user_id');

      // Load saved address for this user
      if (_userId != null) {
        _addressController.text = prefs.getString('${_userId}_address') ?? '';
        _landmarkController.text = prefs.getString('${_userId}_landmark') ?? '';
        _pincodeController.text = prefs.getString('${_userId}_pincode') ?? '';
        _alternatePhoneController.text = prefs.getString('${_userId}_alternate_phone') ?? '';
      }

      // Debug log
      print('Loaded user data and address:');
      print('Name: ${_nameController.text}');
      print('Phone: ${_phoneController.text}');
      print('User ID: $_userId');
      print('Address: ${_addressController.text}');
      print('Landmark: ${_landmarkController.text}');
      print('Pincode: ${_pincodeController.text}');
    });
  }

  // Add this new method to load saved address
  Future<void> _loadSavedAddress() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        _addressController.text = prefs.getString('saved_address') ?? '';
        _landmarkController.text = prefs.getString('saved_landmark') ?? '';
        _pincodeController.text = prefs.getString('saved_pincode') ?? '';
        _alternatePhoneController.text = prefs.getString('saved_alternate_phone') ?? '';
        _cityController.text = prefs.getString('saved_city') ?? '';
        _stateController.text = prefs.getString('saved_state') ?? '';
      });
      
      print('Loaded saved address data:'); // Debug log
      print('Address: ${_addressController.text}');
      print('City: ${_cityController.text}');
      print('State: ${_stateController.text}');
    } catch (e) {
      print('Error loading saved address: $e');
    }
  }

  // Add this method to save address
  Future<void> _saveAddressToPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('saved_address', _addressController.text);
      await prefs.setString('saved_landmark', _landmarkController.text);
      await prefs.setString('saved_pincode', _pincodeController.text);
      await prefs.setString('saved_alternate_phone', _alternatePhoneController.text);
      await prefs.setString('saved_city', _cityController.text);
      await prefs.setString('saved_state', _stateController.text);

      print('Saved address data successfully'); // Debug log
    } catch (e) {
      print('Error saving address: $e');
    }
  }

  // Add method to handle location permission and fetching
  Future<void> _getCurrentLocation() async {
    setState(() => _isLoadingLocation = true);

    try {
      // Check location permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Location permission denied');
        }
      }

      // Show loading dialog
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const Center(
            child: Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Detecting location...'),
                  ],
                ),
              ),
            ),
          ),
        );
      }

      // Get current position
      final position = await Geolocator.getCurrentPosition();
      
      // Get address from coordinates
      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        
        // Create separate address components
        String street = place.street ?? '';
        String city = place.locality ?? '';
        String state = place.administrativeArea ?? '';
        String pincode = place.postalCode ?? '';
        String landmark = place.name ?? '';

        // Format street address with village/post if available
        if (place.subLocality?.isNotEmpty ?? false) {
          street = 'Village- ${place.subLocality}, ${street}';
        }
        if (place.thoroughfare?.isNotEmpty ?? false) {
          street = '${street}, Post- ${place.thoroughfare}';
        }

        // Create formatted complete address
        final formattedAddress = [
          street,
          city,
          state,
          pincode
        ].where((part) => part.isNotEmpty).join(', ');

        print('Formatted Address: $formattedAddress'); // Debug log

        setState(() {
          _addressController.text = formattedAddress;
          _pincodeController.text = pincode;
          _landmarkController.text = landmark;

          // Store individual components for API
          _cityController.text = city;
          _stateController.text = state;
        });

        // Save the address components for API use
        final addressComponents = {
          'address': street,
          'city': city,
          'state': state,
          'pincode': pincode,
          'landmark': landmark,
        };

        print('Address Components: $addressComponents'); // Debug log
      }

      // Close loading dialog
      if (mounted) Navigator.pop(context);

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Location detected successfully!'),
          backgroundColor: Colors.green,
        ),
      );

    } catch (e) {
      // Close loading dialog if open
      if (mounted && Navigator.canPop(context)) {
        Navigator.pop(context);
      }

      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to detect location: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoadingLocation = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Delivery Location'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Contact Information Section
                _buildSectionTitle('Contact Information'),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Full Name',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person),
                  ),
                  enabled: false,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _phoneController,
                  decoration: const InputDecoration(
                    labelText: 'Primary Phone Number',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.phone),
                  ),
                  enabled: false,
                ),
                const SizedBox(height: 16),
                // Add alternate phone number field
                TextFormField(
                  controller: _alternatePhoneController,
                  decoration: const InputDecoration(
                    labelText: 'Alternate Phone Number (Optional)',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.phone_android),
                    hintText: 'Enter alternate contact number',
                  ),
                  keyboardType: TextInputType.phone,
                  validator: (value) {
                    if (value != null && value.isNotEmpty) {
                      // Only validate if a value is provided
                      if (value.length != 10) {
                        return 'Phone number must be 10 digits';
                      }
                      if (!RegExp(r'^[0-9]+$').hasMatch(value)) {
                        return 'Please enter only numbers';
                      }
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 24),
                
                // Address Section
                _buildSectionTitle('Delivery Address'),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _addressController,
                  decoration: InputDecoration(
                    labelText: 'Complete Address',
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.home),
                    suffixIcon: IconButton(
                      icon: Icon(
                        Icons.my_location,
                        color: _isLoadingLocation ? Colors.grey : Colors.blue,
                      ),
                      onPressed: _isLoadingLocation ? null : _getCurrentLocation,
                      tooltip: 'Detect my location',
                    ),
                  ),
                  maxLines: 3,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your address';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _landmarkController,
                  decoration: const InputDecoration(
                    labelText: 'Landmark (Optional)',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.location_on),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _pincodeController,
                  decoration: const InputDecoration(
                    labelText: 'Pincode',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.location_city),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter pincode';
                    }
                    if (value.length != 6) {
                      return 'Pincode must be 6 digits';
                    }
                    return null;
                  },
                ),
                
                const SizedBox(height: 32),
                
                // Order Summary
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Order Summary',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Total Amount:'),
                          Text(
                            '₹${widget.totalAmount.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
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
          onPressed: () async {
            if (_formKey.currentState!.validate()) {
              await _saveAddressToPrefs(); // Add this line to save address
              
              if (!mounted) return;
              
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => PaymentScreen(
                    totalAmount: widget.totalAmount,
                    deliveryDetails: {
                      'name': _nameController.text,
                      'phone': _phoneController.text,
                      'address': _addressController.text,
                      'landmark': _landmarkController.text,
                      'pincode': _pincodeController.text,
                      'alternatePhone': _alternatePhoneController.text,
                      'city': _cityController.text,
                      'state': _stateController.text,
                    },
                    products: widget.products,
                  ),
                ),
              );
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).primaryColor,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
          child: const Text(
            'PROCEED TO PAYMENT',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.bold,
        color: Colors.grey[800],
      ),
    );
  }

  @override
  void dispose() {
    _alternatePhoneController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _landmarkController.dispose();
    _pincodeController.dispose();
    _cityController.dispose(); // Dispose city controller
    _stateController.dispose(); // Dispose state controller
    super.dispose();
  }
}