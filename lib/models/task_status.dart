import 'package:cloud_firestore/cloud_firestore.dart';

class Task {
  String id;
  String delivery;
  String dispatch;
  String image;
  String invoiceSend;
  String packing;
  DateTime timestamp;

  Task({
    required this.id,
    required this.delivery,
    required this.dispatch,
    required this.image,
    required this.invoiceSend,
    required this.packing,
    required this.timestamp,
  });

  factory Task.fromMap(String id, Map<String, dynamic> data) {
    return Task(
      id: id,
      delivery: data['delivery'],
      dispatch: data['dispatch'],
      image: data['image'],
      invoiceSend: data['invoiceSend'],
      packing: data['packing'],
      timestamp: (data['timestamp'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'delivery': delivery,
      'dispatch': dispatch,
      'image': image,
      'invoiceSend': invoiceSend,
      'packing': packing,
      'timestamp': timestamp,
    };
  }
}
