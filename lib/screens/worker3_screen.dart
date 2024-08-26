import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'login_screen.dart';

class Worker3Screen extends StatefulWidget {
  @override
  _Worker3ScreenState createState() => _Worker3ScreenState();
}

class _Worker3ScreenState extends State<Worker3Screen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;
  late String currentUserId;
  late User currentUser;
  FlutterSoundRecorder _recorder = FlutterSoundRecorder();
  Map<String, bool> _isRecordingMap = {};
  Map<String, String?> _voiceMessagePathMap = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _initializeNotifications();
    _loadCurrentUser();
    _initializeRecorder();
  }

  Future<void> _initializeNotifications() async {
    flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

    const AndroidInitializationSettings initializationSettingsAndroid =
    AndroidInitializationSettings('app_icon');

    final InitializationSettings initializationSettings =
    InitializationSettings(android: initializationSettingsAndroid);

    await flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  Future<void> _showNotification(String title, String body) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
    AndroidNotificationDetails(
      'your channel id',
      'your channel name',
      importance: Importance.max,
      priority: Priority.high,
      ticker: 'ticker',
    );

    const NotificationDetails platformChannelSpecifics =
    NotificationDetails(android: androidPlatformChannelSpecifics);

    await flutterLocalNotificationsPlugin.show(
      0,
      title,
      body,
      platformChannelSpecifics,
    );
  }

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => LoginScreen()),
    );
  }

  Future<void> _loadCurrentUser() async {
    currentUser = FirebaseAuth.instance.currentUser!;
    setState(() {
      currentUserId = currentUser.uid;
    });
  }

  Future<void> _initializeRecorder() async {
    await _recorder.openAudioSession();
    _recorder.setSubscriptionDuration(Duration(milliseconds: 10));
  }

  @override
  void dispose() {
    _recorder.closeAudioSession();
    super.dispose();
  }

  Future<void> _startRecording(String taskId) async {
    Directory tempDir = await getTemporaryDirectory();
    String tempPath = '${tempDir.path}/voice_message_$taskId.aac';

    await _recorder.startRecorder(
      toFile: tempPath,
      codec: Codec.aacADTS,
    );

    setState(() {
      _isRecordingMap[taskId] = true;
      _voiceMessagePathMap[taskId] = tempPath;
    });
  }

  Future<void> _stopRecording(String taskId) async {
    await _recorder.stopRecorder();

    setState(() {
      _isRecordingMap[taskId] = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(onPressed: _logout, icon: Icon(Icons.logout))
        ],
        title: Text('Worker 3 Dashboard'),
        backgroundColor: Colors.blueAccent,
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: "New Tasks"),
            Tab(text: "Completed Tasks"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildTaskList('New Tasks'),
          _buildTaskList('Completed Tasks'),
        ],
      ),
    );
  }

  Widget _buildTaskList(String tabType) {
    Stream<QuerySnapshot> stream;
    if (tabType == 'New Tasks') {
      stream = FirebaseFirestore.instance
          .collection('tasks')
          .where('packing', isEqualTo: 'completed')
          .where('dispatch', isEqualTo: 'pending')
          .snapshots();
    } else {
      stream = FirebaseFirestore.instance
          .collection('tasks')
          .where('packing', isEqualTo: 'completed')
          .where('dispatch', isEqualTo: 'completed')
          .snapshots();
    }

    return StreamBuilder(
      stream: stream,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Center(child: CircularProgressIndicator());
        }
        var tasks = snapshot.data!.docs;
        return ListView.builder(
          itemCount: tasks.length,
          itemBuilder: (context, index) {
            var task = tasks[index];
            var taskId = task.id;
            var timestamp = task['timestamp']?.toDate();
            var formattedTimestamp = timestamp != null
                ? "${timestamp.toLocal().toString().split(' ')[0]} ${timestamp.toLocal().toString().split(' ')[1].substring(0, 5)}"
                : 'Unknown time';

            return ListTile(
              leading: task['images'] != null && task['images'].length > 0
                  ? GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => FullImageScreen(
                        imageUrls: List<String>.from(task['images']),
                      ),
                    ),
                  );
                },
                child: Container(
                  width: 50,
                  height: 50,
                  child: Image.network(
                    task['images'][0], // Display the first image as a preview
                    fit: BoxFit.cover,
                  ),
                ),
              )
                  : null,
              title: Text('Task received at $formattedTimestamp'),
              subtitle: Text(taskId, style: TextStyle(fontSize: 10)),
              trailing: tabType == 'New Tasks'
                  ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    onPressed: () async {
                      await _assignTaskToWorker4(taskId);
                    },
                    icon: Icon(Icons.check),
                    tooltip: 'Complete',
                  ),
                  SizedBox(height: 8),
                  IconButton(
                    onPressed: _isRecordingMap[taskId] == true
                        ? () => _stopRecording(taskId)
                        : () => _startRecording(taskId),
                    icon: Icon(_isRecordingMap[taskId] == true
                        ? Icons.stop
                        : Icons.mic),
                    tooltip: _isRecordingMap[taskId] == true
                        ? 'Stop Recording'
                        : 'Start Recording',
                  ),
                ],
              )
                  : Text('Assigned to: ${task['assignedTo'] ?? 'N/A'}'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => TaskDetailScreen(task: task),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Future<void> _assignTaskToWorker4(String taskId) async {
    User? assignedUser;

    // Fetch users with the role of Worker 4
    var worker4Users = await FirebaseFirestore.instance
        .collection('users')
        .where('role', isEqualTo: 'Worker4')
        .get();

    if (worker4Users.docs.isNotEmpty) {
      var selectedUser = await showDialog<Map<String, dynamic>>(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text('Select Worker 4'),
            content: Container(
              width: double.minPositive,
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: worker4Users.docs.length,
                itemBuilder: (context, index) {
                  var user = worker4Users.docs[index];
                  return ListTile(
                    title: Text(user['username'] ?? user['email']),
                    onTap: () {
                      Navigator.of(context).pop({
                        'uid': user.id,
                        'name': user['username'] ?? user['email'],
                      });
                    },
                  );
                },
              ),
            ),
          );
        },
      );

      if (selectedUser != null) {
        var selectedUserId = selectedUser['uid'];
        var selectedUserName = selectedUser['name'];

        // Update the task document with the assigned user's ID and name
        await FirebaseFirestore.instance
            .collection('tasks')
            .doc(taskId)
            .update({
          'dispatch': 'completed',
          'assignedTo': selectedUserName,
        });

        // Add the task ID to the tasks array in the assigned user's document
        await FirebaseFirestore.instance
            .collection('users')
            .doc(selectedUserId)
            .update({
          'tasks': FieldValue.arrayUnion([taskId]),
        });

        if (_voiceMessagePathMap[taskId] != null) {
          String filePath =
              'voice_messages/${DateTime.now().millisecondsSinceEpoch}.aac';
          File voiceMessageFile = File(_voiceMessagePathMap[taskId]!);
          await FirebaseStorage.instance.ref(filePath).putFile(voiceMessageFile);
          String downloadUrl =
          await FirebaseStorage.instance.ref(filePath).getDownloadURL();

          await FirebaseFirestore.instance
              .collection('tasks')
              .doc(taskId)
              .update({
            'voiceMessageUrl': downloadUrl,
          });
        }

        await _showNotification(
            'Task Assigned', 'Task assigned to $selectedUserName');
      }
    }
  }
}

class FullImageScreen extends StatelessWidget {
  final List<String> imageUrls;
  FullImageScreen({required this.imageUrls});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Full Images'),
      ),
      body: Center(
        child: ListView.builder(
          itemCount: imageUrls.length,
          itemBuilder: (context, index) {
            return Padding(
              padding: const EdgeInsets.all(8.0),
              child: Image.network(
                imageUrls[index],
                height: 200,
                fit: BoxFit.cover,
              ),
            );
          },
        ),
      ),
    );
  }
}





class TaskDetailScreen extends StatefulWidget {
  final dynamic task;

  TaskDetailScreen({required this.task});

  @override
  _TaskDetailScreenState createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends State<TaskDetailScreen> {
  List<File> _capturedImages = [];
  String? _audioFilePath;
  final FlutterSoundRecorder _recorder = FlutterSoundRecorder();
  bool _isRecording = false;

  @override
  void initState() {
    super.initState();
    _initializeRecorder();
  }

  Future<void> _initializeRecorder() async {
    await _recorder.openAudioSession();
  }

  @override
  void dispose() {
    _recorder.closeAudioSession();
    super.dispose();
  }

  Future<void> _captureImages() async {
    final picker = ImagePicker();
    final pickedFiles = await picker.pickMultiImage();
    if (pickedFiles != null) {
      setState(() {
        _capturedImages = pickedFiles.map((file) => File(file.path)).toList();
      });
    }
  }

  Future<void> _startRecording() async {
    Directory tempDir = await getTemporaryDirectory();
    String tempPath = '${tempDir.path}/dispatch_audio.aac';

    await _recorder.startRecorder(
      toFile: tempPath,
      codec: Codec.aacADTS,
    );

    setState(() {
      _isRecording = true;
      _audioFilePath = tempPath;
    });
  }

  Future<void> _stopRecording() async {
    await _recorder.stopRecorder();
    setState(() {
      _isRecording = false;
    });
  }

  Future<void> _uploadImagesAndAudio(String taskId) async {
    List<String> imageUrls = [];

    // Upload captured images to Firebase Storage
    for (var image in _capturedImages) {
      String filePath =
          'dispatch_images/$taskId/${DateTime.now().millisecondsSinceEpoch}.jpg';
      await FirebaseStorage.instance.ref(filePath).putFile(image);
      String downloadUrl =
      await FirebaseStorage.instance.ref(filePath).getDownloadURL();
      imageUrls.add(downloadUrl);
    }

    // Upload audio if recorded
    String? audioUrl;
    if (_audioFilePath != null) {
      String audioFilePath =
          'dispatch_audio/$taskId/${DateTime.now().millisecondsSinceEpoch}.aac';
      File audioFile = File(_audioFilePath!);
      await FirebaseStorage.instance.ref(audioFilePath).putFile(audioFile);
      audioUrl =
      await FirebaseStorage.instance.ref(audioFilePath).getDownloadURL();
    }

    // Update task document with dispatch images and audio
    await FirebaseFirestore.instance.collection('tasks').doc(taskId).update({
      'dispatchImage': imageUrls,
      'dispatchAudio': audioUrl,
    });

    // Clear the captured images and audio file path
    setState(() {
      _capturedImages.clear();
      _audioFilePath = null;
    });

    // Show confirmation message
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Images and Audio uploaded successfully')));
  }

  Future<void> _assignTaskToWorker4(String taskId) async {
    User? assignedUser;

    // Fetch users with the role of Worker 4
    var worker4Users = await FirebaseFirestore.instance
        .collection('users')
        .where('role', isEqualTo: 'Worker4')
        .get();

    if (worker4Users.docs.isNotEmpty) {
      var selectedUser = await showDialog<Map<String, dynamic>>(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text('Select Worker 4'),
            content: Container(
              width: double.minPositive,
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: worker4Users.docs.length,
                itemBuilder: (context, index) {
                  var user = worker4Users.docs[index];
                  return ListTile(
                    title: Text(user['username'] ?? user['email']),
                    onTap: () {
                      Navigator.of(context).pop({
                        'uid': user.id,
                        'name': user['username'] ?? user['email'],
                      });
                    },
                  );
                },
              ),
            ),
          );
        },
      );

      if (selectedUser != null) {
        var selectedUserId = selectedUser['uid'];
        var selectedUserName = selectedUser['name'];

        // Update the task document with the assigned user's ID and name
        await FirebaseFirestore.instance
            .collection('tasks')
            .doc(taskId)
            .update({
          'dispatch': 'completed',
          'assignedTo': selectedUserName,
        });

        // Add the task ID to the tasks array in the assigned user's document
        await FirebaseFirestore.instance
            .collection('users')
            .doc(selectedUserId)
            .update({
          'tasks': FieldValue.arrayUnion([taskId]),
        });

        await _uploadImagesAndAudio(taskId);

        // Show confirmation notification
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Task assigned to Worker 4 successfully')),
        );
      }
    } else {
      print('No users with Worker 4 role found.');
    }
  }

  @override
  Widget build(BuildContext context) {
    var imageUrls = List<String>.from(widget.task['images'] ?? []);
    var taskId = widget.task.id;

    return Scaffold(
      appBar: AppBar(
        title: Text('Task Details'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (imageUrls.isNotEmpty)
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          FullImageScreen(imageUrls: imageUrls),
                    ),
                  );
                },
                child: Container(
                  width: double.infinity,
                  height: 200,
                  child: Image.network(
                    imageUrls[0], // Show first image as preview
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            SizedBox(height: 16),
            Text('Task ID: $taskId'),
            // SizedBox(height: 8),
            // Text('Assigned To: ${widget.task['assignedTo'] ?? 'N/A'}'),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: _captureImages,
              child: Text('Capture Images'),
            ),
            SizedBox(height: 16),
            if (_capturedImages.isNotEmpty)
              Wrap(
                spacing: 8,
                children: _capturedImages
                    .map((image) => Image.file(image, height: 100))
                    .toList(),
              ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: _isRecording ? _stopRecording : _startRecording,
              child: Text(_isRecording ? 'Stop Recording' : 'Record Audio'),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _assignTaskToWorker4(taskId),
              child: Text('Assign to Worker 4'),
            ),
          ],
        ),
      ),
    );
  }
}
