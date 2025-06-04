import 'package:flutter/material.dart';
import 'order_summary_screen.dart';
import '../models/product.dart';

class PaymentScreen extends StatefulWidget {
  final double totalAmount;
  final Map<String, String> deliveryDetails;
  final List<Product> products; // Add this line

  const PaymentScreen({
    Key? key,
    required this.totalAmount,
    required this.deliveryDetails,
    required this.products, // Add this line
  }) : super(key: key);

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  String? _selectedPaymentMethod;

  final List<Map<String, dynamic>> _paymentMethods = [
    {
      'title': 'UPI Payment',
      'subtitle': 'Pay using any UPI app',
      'icon': Icons.payment,
      'value': 'UPI'
    },
    {
      'title': 'Cash on Delivery',
      'subtitle': 'Pay when you receive the order',
      'icon': Icons.money,
      'value': 'COD'
    },
    {
      'title': 'Credit/Debit Card',
      'subtitle': 'Pay using credit or debit card',
      'icon': Icons.credit_card,
      'value': 'CARD'
    },
    {
      'title': 'EMI',
      'subtitle': 'Convert payment to monthly installments',
      'icon': Icons.calendar_month,
      'value': 'EMI'
    },
  ];

  void _proceedToOrderSummary() {
    if (_selectedPaymentMethod == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a payment method')),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => OrderSummaryScreen(
          totalAmount: widget.totalAmount,
          deliveryDetails: widget.deliveryDetails,
          paymentMethod: _selectedPaymentMethod!,
          products: widget.products, // Add this line
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Payment Method'),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Amount Card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Amount to Pay',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '₹${widget.totalAmount.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).primaryColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                
                // Payment Methods
                Card(
                  child: Column(
                    children: _paymentMethods.map((method) {
                      return RadioListTile<String>(
                        value: method['value'],
                        groupValue: _selectedPaymentMethod,
                        onChanged: (value) {
                          setState(() {
                            _selectedPaymentMethod = value;
                          });
                        },
                        title: Text(
                          method['title'],
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(method['subtitle']),
                        secondary: Icon(
                          method['icon'],
                          color: Theme.of(context).primaryColor,
                        ),
                        activeColor: Theme.of(context).primaryColor,
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
          
          // Bottom Button
          Container(
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
              onPressed: () {
                if (_selectedPaymentMethod != null) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => OrderSummaryScreen(
                        products: widget.products, // Pass the products list
                        totalAmount: widget.totalAmount,
                        deliveryDetails: widget.deliveryDetails,
                        paymentMethod: _selectedPaymentMethod!,
                      ),
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                minimumSize: const Size(double.infinity, 50),
              ),
              child: const Text(
                'PROCEED',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}