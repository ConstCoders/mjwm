// import 'dart:io';
// import 'package:flutter/material.dart';
// import 'package:image_picker/image_picker.dart';
// import 'package:firebase_storage/firebase_storage.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
//
// class TaskCompletionPage extends StatefulWidget {
//   @override
//   _TaskCompletionPageState createState() => _TaskCompletionPageState();
// }
//
// class _TaskCompletionPageState extends State<TaskCompletionPage> {
//   File? _videoFile;
//   final ImagePicker _picker = ImagePicker();
//
//   Future<void> _pickVideo() async {
//     final XFile? pickedFile = await _picker.pickVideo(source: ImageSource.gallery);
//     if (pickedFile != null) {
//       setState(() {
//         _videoFile = File(pickedFile.path);
//       });
//       await _uploadVideo(_videoFile!);
//     }
//   }
//
//   Future<void> _uploadVideo(File videoFile) async {
//     try {
//       final storageRef = FirebaseStorage.instance.ref().child('videos/${DateTime.now().millisecondsSinceEpoch}.mp4');
//       UploadTask uploadTask = storageRef.putFile(videoFile);
//       TaskSnapshot taskSnapshot = await uploadTask;
//       String videoUrl = await taskSnapshot.ref.getDownloadURL();
//
//       // Update Firestore with video URL
//       await FirebaseFirestore.instance.collection('tasks').doc(task.id).update({
//         taskType: 'completed',
//         'videoUrl': videoUrl, // Add video URL to Firestore
//       });
//
//       await FirebaseFirestore.instance.collection('users').doc(currentUserId).collection('completedTasks').doc(task.id).set(task.data());
//
//       _showNotification('Task Completed', 'You have completed a task.');
//     } catch (e) {
//       print('Failed to upload video: $e');
//     }
//   }
//
//   void _showNotification(String title, String message) {
//     // Implement notification logic
//     print('$title: $message');
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: Text('Task Completion')),
//       body: Center(
//         child: ElevatedButton(
//           onPressed: _pickVideo,
//           child: Text('Pick Video'),
//         ),
//       ),
//     );
//   }
// }