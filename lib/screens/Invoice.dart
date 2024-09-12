import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:mjworkmanagement/screens/login_screen.dart';
import 'package:mjworkmanagement/screens/worker3_screen.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:permission_handler/permission_handler.dart';
import 'package:velocity_x/velocity_x.dart';

import '../widgets/neu.dart';

class TaskUploaderScreen extends StatefulWidget {
  @override
  _TaskUploaderScreenState createState() => _TaskUploaderScreenState();
}

class _TaskUploaderScreenState extends State<TaskUploaderScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  FlutterSoundRecorder? _recorder;
  bool _isRecording = false;
  XFile? _selectedImage;
  bool _uploading = false;
  String? _audioPath;
  final ImagePicker _picker = ImagePicker();
  TextEditingController _taskNameController = TextEditingController();
  String? _selectedWorkerId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _recorder = FlutterSoundRecorder();
    _initializeRecorder();
  }

  Future<void> _initializeRecorder() async {
    var status = await Permission.microphone.request();
    if (status != PermissionStatus.granted) {
      Fluttertoast.showToast(msg: 'Microphone permission required.', toastLength: Toast.LENGTH_LONG);
      return;
    }
    await _recorder!.openRecorder();
  }

  Future<void> _pickImage() async {
    final pickedImage = await _picker.pickImage(source: ImageSource.camera);
    setState(() {
      _selectedImage = pickedImage;
    });
  }

  Future<void> _startRecording() async {
    try {
      if (_isRecording) return;

      Directory tempDir = await getTemporaryDirectory();
      String path = '${tempDir.path}/temp_audio.aac';

      await _recorder!.startRecorder(toFile: path);
      setState(() {
        _isRecording = true;
        _audioPath = path;
      });
    } catch (e) {
      print('Error starting recording: $e');
    }
  }

  Future<void> _stopRecording() async {
    try {
      if (!_isRecording) return;

      await _recorder!.stopRecorder();
      setState(() {
        _isRecording = false;
      });
    } catch (e) {
      print('Error stopping recording: $e');
    }
  }

  Future<void> _uploadTask() async {
    if (_selectedImage == null || _audioPath == null || _taskNameController.text.isEmpty || _selectedWorkerId == null) {
      Fluttertoast.showToast(msg: 'Complete all fields before uploading.');
      return;
    }

    setState(() {
      _uploading = true;
    });

    String imageUrl = await _uploadImage();
    String audioUrl = await _uploadAudio();

    FirebaseFirestore.instance.collection('tasks').add({
      'taskName': _taskNameController.text,
      'image': imageUrl,
      'audio': audioUrl,
      'timestamp': Timestamp.now(),
      'invoiceSend': 'completed',
      'packing': 'pending',
      'dispatch': 'pending',
      'delivery': 'pending',
      'completedBy': _selectedWorkerId,
    });

    Fluttertoast.showToast(msg: 'Task uploaded successfully!');
    setState(() {
      _uploading = false;
      _taskNameController.clear();
      _selectedImage = null;
      _audioPath = null;
    });
  }

  Future<String> _uploadImage() async {
    File file = File(_selectedImage!.path);
    Reference ref = FirebaseStorage.instance.ref().child('images/${DateTime.now().millisecondsSinceEpoch}.jpg');
    UploadTask uploadTask = ref.putFile(file);
    TaskSnapshot snapshot = await uploadTask;
    return await snapshot.ref.getDownloadURL();
  }

  Future<String> _uploadAudio() async {
    File file = File(_audioPath!);
    Reference ref = FirebaseStorage.instance.ref().child('audios/${DateTime.now().millisecondsSinceEpoch}.aac');
    UploadTask uploadTask = ref.putFile(file);
    TaskSnapshot snapshot = await uploadTask;
    return await snapshot.ref.getDownloadURL();
  }

  Future<void> _showWorkerDialog() async {
    QuerySnapshot workersSnapshot = await FirebaseFirestore.instance.collection('users').where('role', isEqualTo: 'Worker2').get();
    List<QueryDocumentSnapshot> workers = workersSnapshot.docs;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Assign Task to Worker2"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: workers.map((worker) {
              return ListTile(
                title: Text(worker['username']),
                onTap: () {
                  setState(() {
                    _selectedWorkerId = worker.id;
                  });
                  Navigator.of(context).pop();
                },
              );
            }).toList(),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _recorder!.closeRecorder(); // Close the recorder only
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Task Uploader'),
        actions: [
          IconButton(icon: Icon(Icons.notifications), onPressed: () {}),
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (context)=> LoginScreen()));
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: 'Upload Task'),
            Tab(text: 'Uploaded Tasks'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _uploadTaskTab(),
          _uploadedTasksTab(),
        ],
      ),
    );
  }

  Widget _uploadTaskTab() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          TextField(
            controller: _taskNameController,
            decoration: InputDecoration(labelText: 'Task Name'),
          ),
          SizedBox(height: 20),
          ElevatedButton(
            onPressed: _pickImage,
            child: Text('Capture Image'),
          ),
          ElevatedButton(
            onPressed: _isRecording ? _stopRecording : _startRecording,
            child: Text(_isRecording ? 'Stop Recording' : 'Start Recording'),
          ),
          SizedBox(height: 20),
          ElevatedButton(
            onPressed: _uploading ? null : () async {
              await _showWorkerDialog();
              _uploadTask();
            },
            child: _uploading ? CircularProgressIndicator() : Text('Upload Task'),
          ),
        ],
      ),
    );
  }

  Widget _uploadedTasksTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('tasks').orderBy('timestamp', descending: true).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return Center(child: CircularProgressIndicator());

        List<QueryDocumentSnapshot> tasks = snapshot.data!.docs;

        return ListView.builder(
          itemCount: tasks.length,
          itemBuilder: (context, index) {
            var task = tasks[index];

            // Fetch the worker's username from the 'users' collection
            return FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance.collection('users').doc(task['completedBy']).get(),
              builder: (context, userSnapshot) {
                if (!userSnapshot.hasData) return CircularProgressIndicator();

                String workerName = userSnapshot.data!['username'];
                String taskImageUrl = task['image'];

                return ListTile(
                  leading: taskImageUrl != null
                      ? Image.network(taskImageUrl, width: 50, height: 50, fit: BoxFit.cover)
                      : Icon(Icons.image),
                  title: Text(task['taskName']),
                  subtitle: Text('Assigned to: $workerName'),
                  onTap: () {
                    // Navigate to task detail screen
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => InvoiceDetailsPage(invoice: task),
                      ),
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }
}

// New TaskDetailScreen to show detailed task info
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

    String? image = widget.invoice['image'];
    // List<String> image = List<String>.from(widget.invoice['image'] ?? []);
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
            image!=null
                ?  Padding(
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