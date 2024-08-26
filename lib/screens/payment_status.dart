import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:mjworkmanagement/screens/paydetails.dart';

class PendingPaymentsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('payments')
            .where('status', isEqualTo: 'pending')
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            // Log the error for debugging purposes
            print('Error: ${snapshot.error}');
            return Center(child: Text('Error loading data: ${snapshot.error}'));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text('No pending payments'));
          }

          var documents = snapshot.data!.docs;

          return ListView.builder(
            itemCount: documents.length,
            itemBuilder: (context, index) {
              var data = documents[index].data() as Map<String, dynamic>?;
              if (data == null) {
                print('Error: data is null for document with ID ${documents[index].id}');
                return SizedBox.shrink(); // Return an empty widget if data is null
              }

              if (!data.containsKey('buyerName') || !data.containsKey('amount')) {
                print('Error: Missing expected fields in document with ID ${documents[index].id}');
                return SizedBox.shrink(); // Return an empty widget if required fields are missing
              }

              return _buildNeumorphicPaymentCard(context, documents[index].id, data);
            },
          );
        },
      ),
    );
  }

  // Neumorphic Card Widget
  Widget _buildNeumorphicPaymentCard(BuildContext context, String documentId, Map<String, dynamic> data) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey[200],
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
        child: ListTile(
          title: Text(
            data['buyerName'] ?? 'Unknown Buyer',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: Text('Amount: ₹${data['amount'] ?? 'N/A'}'),
          trailing: IconButton(
            icon: Icon(Icons.check_circle_outline, color: Colors.green[600]),
            onPressed: () {
              _markAsCompleted(documentId);
            },
          ),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => PaymentDetailsPage(data: data),
              ),
            );
          },
        ),
      ),
    );
  }

  void _markAsCompleted(String documentId) {
    FirebaseFirestore.instance
        .collection('payments')
        .doc(documentId)
        .update({'status': 'completed'}).then((_) {
      print('Payment marked as completed');
    }).catchError((error) {
      print('Failed to update status: $error');
    });
  }
}