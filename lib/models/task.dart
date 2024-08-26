import 'package:cloud_firestore/cloud_firestore.dart';

class Task {
  String id;
  String? taskName;
  String? delivery;
  String? dispatch;
  String? invoiceSend;
  String? packing;
  DateTime timestamp;
  String? assignedTo;
  String? completedBy;
  String? voiceMessageUrl; // Renamed to audio to match Firestore
  List<String>? images; // Matches 'images' field in Firestore
  String? deliveredImage; // Matches 'deliveredImage' field in Firestore
  List<String>? dispatchImage; // Matches 'dispatchImage' field in Firestore
  String? dispatchAudio; // Matches 'dispatchAudio' field in Firestore

  Task({
    required this.id,
    this.taskName,
    this.delivery,
    this.dispatch,
    this.invoiceSend,
    this.packing,
    required this.timestamp,
    this.assignedTo,
    this.completedBy,
    this.voiceMessageUrl,
    this.images,
    this.deliveredImage,
    this.dispatchImage,
    this.dispatchAudio,
  });

  factory Task.fromMap(String id, Map<String, dynamic> data) {
    return Task(
      id: id,
      taskName: data['taskName'] as String?,
      delivery: data['delivery'] as String?,
      dispatch: data['dispatch'] as String?,
      invoiceSend: data['invoiceSend'] as String?,
      packing: data['packing'] as String?,
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      assignedTo: data['assignedTo'] as String?,
      completedBy: data['completedBy'] as String?,
      voiceMessageUrl: data['audio'] as String?, // Changed to 'audio'
      images: data['images'] != null
          ? List<String>.from(data['images'])
          : null,
      deliveredImage: data['deliveredImage'] as String?,
      dispatchImage: data['dispatchImage'] != null
          ? List<String>.from(data['dispatchImage'])
          : null,
      dispatchAudio: data['dispatchAudio'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'taskName': taskName,
      'delivery': delivery,
      'dispatch': dispatch,
      'invoiceSend': invoiceSend,
      'packing': packing,
      'timestamp': timestamp,
      'assignedTo': assignedTo,
      'completedBy': completedBy,
      'audio': voiceMessageUrl, // Changed to 'audio'
      'images': images,
      'deliveredImage': deliveredImage,
      'dispatchImage': dispatchImage,
      'dispatchAudio': dispatchAudio,
    };
  }
}
