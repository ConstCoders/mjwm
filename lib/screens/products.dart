import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:video_player/video_player.dart';

class ProductVideoPage extends StatefulWidget {
  @override
  _ProductVideoPageState createState() => _ProductVideoPageState();
}

class _ProductVideoPageState extends State<ProductVideoPage> {
  final _formKey = GlobalKey<FormState>();
  String? _partyName;
  File? _videoFile;
  String? _description;
  VideoPlayerController? _videoController;
  Future<void>? _initializeVideoPlayerFuture;

  // Method to pick video using image_picker
  Future<void> _pickVideo() async {
    final pickedFile = await ImagePicker().pickVideo(source: ImageSource.camera);
    if (pickedFile != null) {
      setState(() {
        _videoFile = File(pickedFile.path);
        _videoController?.dispose(); // Dispose previous controller
        _videoController = VideoPlayerController.file(_videoFile!);
        _initializeVideoPlayerFuture = _videoController!.initialize();
      });
    }
  }

  // Method to upload data to Firestore and video to Firebase Storage
  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate() && _videoFile != null) {
      _formKey.currentState!.save();

      try {
        // Upload the video to Firebase Storage
        String videoUrl = await _uploadVideo(_videoFile!);

        // Save the video URL and details to Firestore
        await FirebaseFirestore.instance.collection('products').add({
          'partyName': _partyName,
          'description': _description,
          'videoUrl': videoUrl,
          'timestamp': FieldValue.serverTimestamp(),
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Product submitted successfully')),
        );

        // Clear fields after successful submission
        setState(() {
          _partyName = null;
          _description = null;
          _videoFile = null;
          _videoController?.dispose();
          _videoController = null;
          _initializeVideoPlayerFuture = null;
          _formKey.currentState!.reset();
        });
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to upload video: $e')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please record a video and fill in all fields')),
      );
    }
  }

  // Upload video to Firebase Storage and return the download URL
  Future<String> _uploadVideo(File videoFile) async {
    final storageRef = FirebaseStorage.instance.ref().child('products_videos/${DateTime.now().millisecondsSinceEpoch}.mp4');
    UploadTask uploadTask = storageRef.putFile(videoFile);
    TaskSnapshot taskSnapshot = await uploadTask;
    return await taskSnapshot.ref.getDownloadURL();
  }

  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFE0E5EC),
      appBar: AppBar(
        title: Text('Record Product Video'),
        backgroundColor: Color(0xFFE0E5EC),
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: Color(0xFFE0E5EC),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.shade600,
                      offset: Offset(10, 10),
                      blurRadius: 20,
                    ),
                    BoxShadow(
                      color: Colors.white,
                      offset: Offset(-10, -10),
                      blurRadius: 20,
                    ),
                  ],
                ),
                child: TextFormField(
                  decoration: InputDecoration(
                    labelText: 'Party Name',
                    border: InputBorder.none,
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter party name';
                    }
                    return null;
                  },
                  onSaved: (value) {
                    _partyName = value;
                  },
                ),
              ),
              SizedBox(height: 16),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: Color(0xFFE0E5EC),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.shade600,
                      offset: Offset(10, 10),
                      blurRadius: 20,
                    ),
                    BoxShadow(
                      color: Colors.white,
                      offset: Offset(-10, -10),
                      blurRadius: 20,
                    ),
                  ],
                ),
                child: TextFormField(
                  decoration: InputDecoration(
                    labelText: 'Description',
                    border: InputBorder.none,
                  ),
                  onSaved: (value) {
                    _description = value;
                  },
                ),
              ),
              SizedBox(height: 16),


              SizedBox(height: 16),
              SizedBox(
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFFE0E5EC),
                    shadowColor: Colors.grey.shade600,
                    elevation: 10,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: _pickVideo,
                  child: Text(_videoFile == null ? 'RECORD VIDEO' : 'CHANGE VIDEO', style: TextStyle(color: Colors.blueAccent,fontSize: 20,letterSpacing: 2)),
                ),
              ),
              SizedBox(height: 16),
              SizedBox(
                height: 50,
                child: ElevatedButton(

                  style: ElevatedButton.styleFrom(

                    backgroundColor: Color(0xFFE0E5EC),
                    shadowColor: Colors.grey.shade600,
                    elevation: 10,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: _submitForm,
                  child: Text('SUBMIT', style: TextStyle(color: Colors.green,fontSize: 20,letterSpacing: 2)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}