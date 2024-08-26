import 'dart:typed_data';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

import 'login_screen.dart';

class InvoiceSenderScreen extends StatefulWidget {
  @override
  _InvoiceSenderScreenState createState() => _InvoiceSenderScreenState();
}

class _InvoiceSenderScreenState extends State<InvoiceSenderScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<XFile> _selectedImages = [];
  bool _uploading = false;
  FlutterSoundRecorder? _recorder;
  String? _recordedFilePath;
  bool _isRecording = false;
  TextEditingController _taskNameController = TextEditingController();

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _recorder = FlutterSoundRecorder();
    _initializeRecorder();
  }

  Future<void> _initializeRecorder() async {
    await _recorder!.openAudioSession();
    var status = await Permission.microphone.request();
    if (status != PermissionStatus.granted) {
      Fluttertoast.showToast(
        msg: 'Microphone permission is required to record audio.',
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.BOTTOM,
      );
    }
  }

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushReplacement(
      context as BuildContext,
      MaterialPageRoute(builder: (context) => LoginScreen()),
    );
  }

  Future<void> _chooseImages() async {
    try {
      final List<XFile>? pickedFiles = await _picker.pickMultiImage();

      if (pickedFiles != null && pickedFiles.isNotEmpty) {
        setState(() {
          _selectedImages = pickedFiles;
        });
      }
    } catch (e) {
      print("Error selecting images: $e");
    }
  }
  Future<void> deleteTask(String taskId) async {
    try {
      await FirebaseFirestore.instance.collection('tasks').doc(taskId).delete();
      print("Task deleted successfully.");
    } catch (e) {
      print("Error deleting task: $e");
    }
  }

  Future<void> _uploadImageAndAudio() async {
    if (_selectedImages.isEmpty || _recordedFilePath == null || _taskNameController.text.isEmpty) return;

    setState(() {
      _uploading = true;
    });

    try {
      await _ensureTasksCollectionExists();

      List<String> imageUrls = [];

      for (var image in _selectedImages) {
        File file = File(image.path);

        String imageFileName = '${DateTime.now().millisecondsSinceEpoch}_${basename(file.path)}';
        Reference storageRefImage = FirebaseStorage.instance.ref().child('uploads/$imageFileName');
        UploadTask uploadTaskImage = storageRefImage.putFile(file);
        TaskSnapshot taskSnapshotImage = await uploadTaskImage;
        String imageUrl = await taskSnapshotImage.ref.getDownloadURL();
        imageUrls.add(imageUrl);
      }

      String audioFileName = basename(_recordedFilePath!);
      Reference storageRefAudio = FirebaseStorage.instance.ref().child('uploads/$audioFileName');
      UploadTask uploadTaskAudio = storageRefAudio.putFile(File(_recordedFilePath!));
      TaskSnapshot taskSnapshotAudio = await uploadTaskAudio;
      String audioUrl = await taskSnapshotAudio.ref.getDownloadURL();

      await FirebaseFirestore.instance.collection('tasks').add({
        'taskName': _taskNameController.text,
        'images': imageUrls,
        'audio': audioUrl,
        'timestamp': Timestamp.now(),
        'invoiceSend': 'completed',
        'packing': 'pending',
        'dispatch': 'pending',
        'delivery': 'pending',
      });

      _notifyWorker2();

      setState(() {
        _uploading = false;
        _selectedImages = [];
        _recordedFilePath = null;
        _taskNameController.clear();
      });

      _showUploadSuccess();
    } catch (e) {
      print('Error uploading image and audio: $e');
      setState(() {
        _uploading = false;
        _selectedImages = [];
        _recordedFilePath = null;
      });
      _showUploadFailure();
    }
  }

  Future<void> _ensureTasksCollectionExists() async {
    CollectionReference tasksCollection = FirebaseFirestore.instance.collection('tasks');
    var snapshot = await tasksCollection.get();
    if (snapshot.size == 0) {
      await tasksCollection.doc().set({
        'placeholder': 'This document ensures the collection exists',
      });
      print('Collection "tasks" created.');
    }
  }

  void _notifyWorker2() {
    Fluttertoast.showToast(
      msg: 'Worker 2 has been notified of the new task.',
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
    );
  }

  void _showUploadSuccess() {
    Fluttertoast.showToast(
      msg: 'Image and audio uploaded successfully!',
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
    );
  }

  void _showUploadFailure() {
    Fluttertoast.showToast(
      msg: 'Failed to upload image and audio. Please try again.',
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
    );
  }

  void _startRecording() async {
    if (await Permission.microphone.request().isGranted) {
      String path = '${(await getTemporaryDirectory()).path}/${DateTime.now().millisecondsSinceEpoch}.aac';
      await _recorder!.startRecorder(
        toFile: path,
        codec: Codec.aacADTS,
      );
      setState(() {
        _isRecording = true;
        _recordedFilePath = path;
      });
    } else {
      Fluttertoast.showToast(
        msg: 'Microphone permission is required to record audio.',
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
      );
    }
  }

  void _stopRecording() async {
    await _recorder!.stopRecorder();
    setState(() {
      _isRecording = false;
    });
  }

  @override
  void dispose() {
    _recorder!.closeAudioSession();
    _recorder = null;
    super.dispose();
  }

  Widget _buildUploadImageTab() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          TextField(
            controller: _taskNameController,
            decoration: InputDecoration(
              labelText: 'Task Name',
              border: OutlineInputBorder(),
            ),
          ),
          SizedBox(height: 20),
          ElevatedButton(
            onPressed: _chooseImages,
            child: Text('Choose Multiple Images'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blueAccent,
              minimumSize: Size(double.infinity, 50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          SizedBox(height: 20),
          if (_isRecording)
            ElevatedButton(
              onPressed: _stopRecording,
              child: Text('Stop Recording'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                minimumSize: Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            )
          else
            ElevatedButton(
              onPressed: _startRecording,
              child: Text('Record Voice Message'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.greenAccent,
                minimumSize: Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          SizedBox(height: 20),
          if (_uploading) CircularProgressIndicator(),
          if (_selectedImages.isNotEmpty && !_uploading)
            ElevatedButton(
              onPressed: _uploadImageAndAudio,
              child: Text('Upload Image and Audio'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                minimumSize: Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSentImagesTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('tasks').orderBy('timestamp', descending: true).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Center(
            child: CircularProgressIndicator(),
          );
        }
        List<DocumentSnapshot> docs = snapshot.data!.docs;

        return ListView.builder(
          itemCount: docs.length,
          itemBuilder: (context, index) {

            var task = docs[index];
            var images = List<String>.from(task['images'] ?? []);
            return ListTile(
              title: Text(task['taskName']),
              subtitle: Text('Uploaded on ${task['timestamp'].toDate()}'),
              leading: images.isNotEmpty
                  ? Image.network(images[0], height: 50, width: 50, fit: BoxFit.cover)
                  : Icon(Icons.image_not_supported),
              onTap: () {
                // Redirect to the InvoiceDetailsPage
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => InvoiceDetailsPage(invoice: task),
                  ),
                );
              },
              trailing: IconButton(
                icon: Icon(Icons.delete, color: Colors.red),
                onPressed: () {
                  // Show confirmation dialog
                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: Text('Delete Task'),
                        content: Text('Are you sure you want to delete this task?'),
                        actions: [
                          TextButton(
                            child: Text('Cancel'),
                            onPressed: () {
                              Navigator.of(context).pop(); // Close the dialog
                            },
                          ),
                          TextButton(
                            child: Text('Delete'),
                            onPressed: () {
                              // Perform the delete operation
                              deleteTask(task.id); // Pass the task ID to delete
                              Navigator.of(context).pop(); // Close the dialog
                            },
                          ),
                        ],
                      );
                    },
                  );
                },
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Invoice Sender'),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: 'Upload Image'),
            Tab(text: 'Sent Images'),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: _logout,
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildUploadImageTab(),
          _buildSentImagesTab(),
        ],
      ),
    );
  }
}






class InvoiceDetailsPage extends StatefulWidget {
  final DocumentSnapshot invoice;

  const InvoiceDetailsPage({Key? key, required this.invoice}) : super(key: key);

  @override
  _InvoiceDetailsPageState createState() => _InvoiceDetailsPageState();
}

class _InvoiceDetailsPageState extends State<InvoiceDetailsPage> {
  late AudioPlayer _audioPlayer;
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  void _playAudio(String url) async {
    if (_isPlaying) {
      await _audioPlayer.stop();
      setState(() {
        _isPlaying = false;
      });
    } else {
      await _audioPlayer.play(UrlSource(url));
      // 1 indicates success
        setState(() {
          _isPlaying = true;
        });

    }
  }

  @override
  Widget build(BuildContext context) {
    List<String> images = List<String>.from(widget.invoice['images'] ?? []);
    String audioUrl = widget.invoice['audio'] ?? '';

    return Scaffold(
      appBar: AppBar(
        title: Text('Invoice Details'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Task Name: ${widget.invoice['taskName']}',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),
              Text('Timestamp: ${widget.invoice['timestamp'].toDate()}'),
              SizedBox(height: 10),
              Text('Invoice Status: ${widget.invoice['invoiceSend']}'),
              Text('Packing Status: ${widget.invoice['packing']}'),
              Text('Dispatch Status: ${widget.invoice['dispatch']}'),
              Text('Delivery Status: ${widget.invoice['delivery']}'),
              SizedBox(height: 20),
              Text('Images:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              SizedBox(height: 10),
              images.isNotEmpty
                  ? SizedBox(
                height: 100,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: images.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.all(4.0),
                      child: Image.network(
                        images[index],
                        height: 100,
                        width: 100,
                        fit: BoxFit.cover,
                      ),
                    );
                  },
                ),
              )
                  : Text('No images available'),
              SizedBox(height: 20),
              Text('Audio:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              SizedBox(height: 10),
              audioUrl.isNotEmpty
                  ? IconButton(
                icon: Icon(_isPlaying ? Icons.stop : Icons.play_arrow),
                onPressed: () {
                  _playAudio(audioUrl);
                },
              )
                  : Text('No audio available'),
            ],
          ),
        ),
      ),
    );
  }
}
