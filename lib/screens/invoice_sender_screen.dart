import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:intl/intl.dart';
import 'package:mjworkmanagement/widgets/neu.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:velocity_x/velocity_x.dart';

import 'login_screen.dart';

class InvoiceSenderScreen extends StatefulWidget {
  @override
  _InvoiceSenderScreenState createState() => _InvoiceSenderScreenState();
}

class _InvoiceSenderScreenState extends State<InvoiceSenderScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<XFile> _selectedImages = [];
  bool _uploading = false;
  FlutterSoundRecorder? _recorder;
  String? _recordedFilePath;
  bool _isRecording = false;
  TextEditingController _taskNameController = TextEditingController();

  final ImagePicker _picker = ImagePicker();
  @override
  void _logout() async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushReplacement(
      context as BuildContext,
      MaterialPageRoute(builder: (context) => LoginScreen()),
    );
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _recorder = FlutterSoundRecorder();
    _initializeRecorder();
  }

  Future<void> _initializeRecorder() async {
    try {
      var status = await Permission.microphone.request();
      if (status != PermissionStatus.granted) {
        Fluttertoast.showToast(
          msg: 'Microphone permission is required to record audio.',
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.BOTTOM,
        );
        return;
      }

      await _recorder!.openRecorder();

      Fluttertoast.showToast(
        msg: 'Recorder initialized successfully.',
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.BOTTOM,
      );
    } catch (e) {
      Fluttertoast.showToast(
        msg: 'Failed to initialize the recorder: $e',
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.BOTTOM,
      );
    }
  }

  void _toggleRecording() async {
    if (_isRecording) {
      // Stop recording
      await _recorder!.stopRecorder();
      setState(() {
        _isRecording = false;
      });
      Fluttertoast.showToast(
        msg: "Recording stopped",
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.BOTTOM,
      );
    } else {
      // Start recording
      Directory tempDir = await getTemporaryDirectory();
      String filePath = '${tempDir.path}/${DateTime.now().millisecondsSinceEpoch}.aac';
      await _recorder!.startRecorder(
        toFile: filePath,
      );
      setState(() {
        _isRecording = true;
        _recordedFilePath = filePath;
      });
      Fluttertoast.showToast(
        msg: 'Recording started',
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.BOTTOM,
      );
    }
  }

  void _stopRecording() async {
    if (_isRecording) {
      await _recorder!.stopRecorder();
      setState(() {
        _isRecording = false;
      });
    }
  }

  @override
  void dispose() {
    _recorder?.closeRecorder(); // Close the recorder if it is open
    _recorder = null; // Clean up the recorder instance
    super.dispose();
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
    if (_selectedImages.isEmpty ||
        _recordedFilePath == null ||
        _taskNameController.text.isEmpty) return;

    setState(() {
      _uploading = true;
    });

    try {
      await _ensureTasksCollectionExists();

      List<String> imageUrls = [];

      for (var image in _selectedImages) {
        File file = File(image.path);

        String imageFileName =
            '${DateTime.now().millisecondsSinceEpoch}_${basename(file.path)}';
        Reference storageRefImage =
            FirebaseStorage.instance.ref().child('uploads/$imageFileName');
        UploadTask uploadTaskImage = storageRefImage.putFile(file);
        TaskSnapshot taskSnapshotImage = await uploadTaskImage;
        String imageUrl = await taskSnapshotImage.ref.getDownloadURL();
        imageUrls.add(imageUrl);
      }

      String audioFileName = basename(_recordedFilePath!);
      Reference storageRefAudio =
          FirebaseStorage.instance.ref().child('uploads/$audioFileName');
      UploadTask uploadTaskAudio =
          storageRefAudio.putFile(File(_recordedFilePath!));
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
    CollectionReference tasksCollection =
        FirebaseFirestore.instance.collection('tasks');
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






  Widget _buildUploadImageTab() {
    return Padding(
      padding: const EdgeInsets.all(0),
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              height: 150,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18.0),
              child: NeuMo(
                height: 70,
                widget: TextField(
                  controller: _taskNameController,
                  decoration: InputDecoration(
                    labelText: 'Task Name',
                    labelStyle: TextStyle(),
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 15, vertical: 15),
                    border: InputBorder.none,
                  ),
                ),
              ),
            ),
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                NeuMo(
                  height: 60,
                  widget: IconButton(
                    icon: Icon(Icons.image, size: 30, color: Colors.teal[300]),
                    onPressed: _chooseImages,
                    padding: EdgeInsets.all(16), // Adjust as needed
                  ),
                ),
                SizedBox(height: 20),
                if (_isRecording)
                  NeuMo(
                    height: 60,
                    widget: IconButton(
                      icon: Icon(Icons.stop, size: 30, color: Colors.red),
                      onPressed: _stopRecording,
                      padding: EdgeInsets.all(16), // Adjust as needed
                    ),
                  )
                else
                  NeuMo(
                    height: 60,
                    widget: IconButton(
                      icon: Icon(Icons.mic, size: 30, color: Colors.blue),
                      onPressed: _toggleRecording,
                      padding: const EdgeInsets.all(16), // Adjust as needed
                    ),
                  ),
              ],
            ),
            SizedBox(height: 20),
            if (_uploading) CircularProgressIndicator(),
            if (_selectedImages.isNotEmpty && !_uploading)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18.0),
                child: NeuMo(
                  height: 60,
                  widget: ElevatedButton(
                    onPressed: _uploadImageAndAudio,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Upload Now ',
                          style:
                              TextStyle(color: Colors.green[800], fontSize: 18),
                        ),
                        Icon(
                          Icons.cloud_upload,
                          color: Colors.green,
                          size: 30,
                        )
                      ],
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFFE0E5EC),
                      minimumSize: Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),
                ),
              ),
            SizedBox(
              height: 150,
            ),
            Padding(
              padding: const EdgeInsets.all(18.0),
              child: NeuMo(
                height: 60,
                widget: ElevatedButton(
                  onPressed: () => _logout,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Logout ',
                        style: TextStyle(color: Colors.red[800], fontSize: 18),
                      ),
                      Icon(
                        Icons.logout,
                        color: Colors.red,
                        size: 20,
                      )
                    ],
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFFE0E5EC),
                    minimumSize: Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSentImagesTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('tasks')
          .orderBy('timestamp', descending: true)
          .snapshots(),
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
            return Padding(
              padding: const EdgeInsets.all(8.0),
              child: NeuMo(
                height: 90,
                widget: ListTile(
                  title: Text(
                    task['taskName'],
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text('Uploaded on ${task['timestamp'].toDate()}'),
                  leading: images.isNotEmpty
                      ? Image.network(images[0],
                          height: 50, width: 50, fit: BoxFit.cover)
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
                  trailing: NeuMo(
                    height: 50,
                    widget: IconButton(
                      icon: Icon(Icons.delete, color: Colors.red),
                      onPressed: () {
                        // Show confirmation dialog
                        showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return AlertDialog(
                              title: Text('Delete Task'),
                              content: Text(
                                  'Are you sure you want to delete this task?'),
                              actions: [
                                TextButton(
                                  child: Text('Cancel'),
                                  onPressed: () {
                                    Navigator.of(context)
                                        .pop(); // Close the dialog
                                  },
                                ),
                                TextButton(
                                  child: Text('Delete'),
                                  onPressed: () {
                                    // Perform the delete operation
                                    deleteTask(
                                        task.id); // Pass the task ID to delete
                                    Navigator.of(context)
                                        .pop(); // Close the dialog
                                  },
                                ),
                              ],
                            );
                          },
                        );
                      },
                    ),
                  ),
                ),
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
      backgroundColor: Color(0xFFE0E5EC),
      appBar: AppBar(
        backgroundColor: Color(0xFFE0E5EC),
        elevation: 0,
        centerTitle: true,
        title: Text(
          'Invoice Sender',
          style: TextStyle(
            fontWeight: FontWeight.w600,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(
              text: 'Upload Image',
              icon: Icon(Icons.upload_file),
            ),
            Tab(
              text: 'Sent Images',
              icon: Icon(Icons.photo_library),
            ),
          ],
          indicatorSize: TabBarIndicatorSize.tab,
          indicator: BoxDecoration(
            color: Colors.blueAccent,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.blueAccent.withOpacity(0.5),
                spreadRadius: 1,
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          labelColor: Colors.white,
          unselectedLabelColor: Colors.grey[600],
          labelStyle: TextStyle(fontWeight: FontWeight.bold),
          unselectedLabelStyle: TextStyle(fontWeight: FontWeight.normal),
        ),
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

  String formatTimestamp(DateTime dateTime) {
    return DateFormat('yyyy-MM-dd HH:mm').format(dateTime);
  }

  @override
  Widget build(BuildContext context) {
    List<String> images = List<String>.from(widget.invoice['images'] ?? []);
    String audioUrl = widget.invoice['audio'] ?? '';

    return Scaffold(
      backgroundColor: Color(0xFFE0E5EC), // Light grey background
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Color(0xFFE0E5EC),
        title: Text(
          'Invoice Details',
          style: TextStyle(
            color: Colors.black, // Dark text
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Task Name
            Text(
              'Task Name: ${widget.invoice['taskName']}',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.blueAccent, // Colorful text
              ),
            ),
            SizedBox(height: 10),

            // Timestamp without seconds
            Text(
              'Timestamp: ${formatTimestamp(widget.invoice['timestamp'].toDate())}',
              style: TextStyle(fontSize: 16, color: Colors.purple),
            ),
            SizedBox(height: 20),

            // Status in Table Format
            Table(
              columnWidths: {
                0: FlexColumnWidth(2),
                1: FlexColumnWidth(3),
              },
              children: [
                _buildTableRow(
                  'Invoice Status',
                  widget.invoice['invoiceSend'],
                ),
                _buildTableRow(
                  'Packing Status',
                  widget.invoice['packing'],
                ),
                _buildTableRow(
                  'Dispatch Status',
                  widget.invoice['dispatch'],
                ),
                _buildTableRow(
                  'Delivery Status',
                  widget.invoice['delivery'],
                ),
              ],
            ),
            SizedBox(height: 20),

            // Images in Vertical List
            Text(
              'Images:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            images.isNotEmpty
                ? Column(
                    children: images.map((image) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: NeuMo(
                          height: 200,
                          widget: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Image.network(
                              image,
                              fit: BoxFit.cover,
                              height: 200,
                              width: double.infinity,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  )
                : Text('No images available'),
            SizedBox(height: 20),

            // Audio Player
            Text(
              'Audio:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            audioUrl.isNotEmpty
                ? Padding(
                    padding: const EdgeInsets.all(18.0),
                    child: NeuMo(
                      height: 60,
                      widget: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          IconButton(
                            icon: Icon(
                              _isPlaying
                                  ? Icons.pause_circle_filled
                                  : Icons.play_circle_filled,
                              size: 40,
                              color:
                                  _isPlaying ? Colors.green : Colors.blueAccent,
                            ),
                            onPressed: () => _playAudio(audioUrl),
                          ),
                          SizedBox(width: 10),
                          Text(
                            _isPlaying ? 'Playing...' : 'Play Audio',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.black,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : Text('No audio available'),
          ],
        ).box.margin(EdgeInsets.symmetric(horizontal: 18)).make(),
      ),
    );
  }

  TableRow _buildTableRow(String label, String status) {
    Color statusColor =
        status.toLowerCase() == 'completed' ? Colors.green : Colors.red;

    return TableRow(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Text(
            status,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: statusColor,
            ),
          ),
        ),
      ],
    );
  }
}
