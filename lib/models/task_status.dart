import 'package:cloud_firestore/cloud_firestore.dart';

class Task {
  String id;
  String delivery;
  String dispatch;
  List<String> invoiceImages; // List of invoice image URLs
  String packing;
  DateTime timestamp;
  String voiceMessageUrl; // URL for voice message
  List<String> dispatchImages; // List of dispatch image URLs

  Task({
    required this.id,
    required this.delivery,
    required this.dispatch,
    required this.invoiceImages,
    required this.packing,
    required this.timestamp,
    required this.voiceMessageUrl,
    required this.dispatchImages,
  });

  factory Task.fromMap(String id, Map<String, dynamic> data) {
    return Task(
      id: id,
      delivery: data['delivery'],
      dispatch: data['dispatch'],
      invoiceImages: List<String>.from(data['invoiceImages'] ?? []), // Convert to List<String>
      packing: data['packing'],
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      voiceMessageUrl: data['voiceMessageUrl'] ?? '',
      dispatchImages: List<String>.from(data['dispatchImages'] ?? []), // Convert to List<String>
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'delivery': delivery,
      'dispatch': dispatch,
      'invoiceImages': invoiceImages, // Store as List<String>
      'packing': packing,
      'timestamp': timestamp,
      'voiceMessageUrl': voiceMessageUrl,
      'dispatchImages': dispatchImages, // Store as List<String>
    };
  }
}
