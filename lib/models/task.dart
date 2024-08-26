import 'package:cloud_firestore/cloud_firestore.dart';

class Task {
  String id;
  String delivery;
  String dispatch;
  String invoiceSend;
  String packing;
  DateTime timestamp;
  String assignedTo;
  String completedBy;
  String voiceMessageUrl;
  String invoiceImage;
  String deliveryImage;

  Task({
    required this.id,
    required this.delivery,
    required this.dispatch,
    required this.invoiceSend,
    required this.packing,
    required this.timestamp,
    required this.assignedTo,
    required this.completedBy,
    required this.voiceMessageUrl,
    required this.invoiceImage,
    required this.deliveryImage,
  });

  factory Task.fromMap(String id, Map<String, dynamic> data) {
    return Task(
      id: id,
      delivery: data['delivery'],
      dispatch: data['dispatch'],
      invoiceSend: data['invoiceSend'],
      packing: data['packing'],
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      assignedTo: data['assignedTo'] ?? '',
      completedBy: data['completedBy'] ?? '',
      voiceMessageUrl: data['voiceMessageUrl'] ?? '',
      invoiceImage: data['image'] ?? '',
      deliveryImage: data['deliveredImage'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'delivery': delivery,
      'dispatch': dispatch,
      'invoiceSend': invoiceSend,
      'packing': packing,
      'timestamp': timestamp,
      'assignedTo': assignedTo,
      'completedBy': completedBy,
      'voiceMessageUrl': voiceMessageUrl,
      'Image': invoiceImage,
      'deliveryImage': deliveryImage,
    };
  }
}
