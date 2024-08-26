import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class PaymentDetailsPage extends StatelessWidget {
  final Map<String, dynamic> data;

  PaymentDetailsPage({required this.data});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Payment Details'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 4,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Buyer Name: ${data['buyerName']}', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                SizedBox(height: 8),
                Text('Amount: ₹${data['amount']}', style: TextStyle(fontSize: 16)),
                SizedBox(height: 8),
                Text('Phone: ${data['phone']}', style: TextStyle(fontSize: 16)),
                SizedBox(height: 8),
                Text('Promise Date: ${data['promiseDate']}', style: TextStyle(fontSize: 16)),
                SizedBox(height: 8),
                Text('Status: ${data['status']}', style: TextStyle(fontSize: 16)),
                SizedBox(height: 8),
                Text('Timestamp: ${data['timestamp']}', style: TextStyle(fontSize: 16)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
