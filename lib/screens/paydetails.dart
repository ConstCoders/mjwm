import 'package:cloud_firestore/cloud_firestore.dart'; // For Firestore's Timestamp class
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class PaymentDetailsPage extends StatelessWidget {
  final Map<String, dynamic> data;

  PaymentDetailsPage({required this.data});

  @override
  Widget build(BuildContext context) {
    // Use a custom format for parsing and formatting the timestamp
    final DateFormat displayFormat = DateFormat('dd MMM yyyy, HH:mm'); // For display (e.g., 01 Aug 2024, 11:28)

    // Convert Firestore Timestamps to DateTime
    DateTime? promiseDate = _convertToDateTime(data['promiseDate']);
    DateTime? timestamp = _convertToDateTime(data['timestamp']);

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Container(
          alignment: Alignment.center,
          height: 45,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.shade500,
                  offset: Offset(4, 4),
                  blurRadius: 15,
                  spreadRadius: 1,
                ),
                BoxShadow(
                  color: Colors.white,
                  offset: Offset(-4, -4),
                  blurRadius: 15,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Text('Payment Details',textAlign: TextAlign.center,)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.shade500,
                offset: Offset(4, 4),
                blurRadius: 15,
                spreadRadius: 1,
              ),
              BoxShadow(
                color: Colors.white,
                offset: Offset(-4, -4),
                blurRadius: 15,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDetailText('Buyer Name', data['buyerName']),
                SizedBox(height: 8),
                _buildDetailText('Amount', '₹${data['amount']}'),
                SizedBox(height: 8),
                _buildDetailText('Phone', data['phone']),
                SizedBox(height: 8),
                _buildDetailText('Promise Date', promiseDate != null ? displayFormat.format(promiseDate) : 'N/A'),
                SizedBox(height: 8),
                _buildDetailText('Status', data['status']),
                SizedBox(height: 8),
                _buildDetailText('Timestamp', timestamp != null ? displayFormat.format(timestamp) : 'N/A'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailText(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$label: ',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(fontSize: 16),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  // Convert Firestore Timestamp or String to DateTime
  DateTime? _convertToDateTime(dynamic timestamp) {
    if (timestamp is Timestamp) {
      // It's a Firestore Timestamp, convert it to DateTime
      return timestamp.toDate();
    } else if (timestamp is String) {
      // Try to parse the string into a DateTime
      try {
        return DateFormat('d MMMM yyyy \'at\' HH:mm:ss \'UTC\'z').parse(timestamp);
      } catch (e) {
        print('Error parsing timestamp string: $e');
        return null;
      }
    } else {
      // Handle unexpected type
      print('Unexpected timestamp type: ${timestamp.runtimeType}');
      return null;
    }
  }
}