import 'dart:io';
import 'package:audioplayers/audioplayers.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import '../widgets/neu.dart';
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
backgroundColor: Color(0xFFE0E5EC),
      body: DefaultTabController(
        length: 2,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(18.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Hi',
                            style: TextStyle(
                                color: Colors.grey[700],
                                fontSize: 22,
                                fontWeight: FontWeight.w500),
                          ),
                          FutureBuilder<DocumentSnapshot>(
                            future: FirebaseFirestore.instance
                                .collection('users')
                                .doc(FirebaseAuth.instance.currentUser!.uid)
                                .get(),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return CircularProgressIndicator(
                                    color: Colors.white);
                              }
                              if (snapshot.hasData && snapshot.data!.exists) {
                                String userName =
                                    snapshot.data!['username'] ?? 'User';
                                return Text('$userName',
                                    style: TextStyle(
                                        color: Colors.grey[900],
                                        fontSize: 26,
                                        fontWeight: FontWeight.w700));
                              }
                              return Text('Welcome',
                                  style: TextStyle(fontSize: 18));
                            },
                          ),
                        ],
                      ),
                      NeuMo(
                        widget: IconButton(
                            onPressed: () {},
                            icon: Icon(
                              Icons.notifications,
                              size: 30,
                              color: Colors.cyan,
                            )),
                        height: 60,
                        width: 60,
                      )
                    ],
                  ),
                ),
                NeuMo(
                  height: 60,
                  widget: Container(
                    // Customize color to match the design
                    child: TabBar(
                      indicatorSize: TabBarIndicatorSize.tab,
                      controller: _tabController,
                      indicator: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        color: Colors.blueAccent.shade100,
                      ),
                      labelColor: Colors.blue[800],
                      labelStyle:
                      TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
                      unselectedLabelColor: Colors.grey.shade600,
                      tabs: [
                        Tab(
                          text: "Packages",
                        ),
                        Tab(text: "Dispatched"),
                      ],
                    ),
                  ),
                ),
                SizedBox(
                  height: 10,
                ),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildTaskList('Packages'),
                      _buildTaskList('Dispatched'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: NeuMo(
        widget: IconButton(
            onPressed: _logout,
            icon: Icon(
              Icons.power_settings_new_outlined,
              size: 25,
              color: Colors.orange,
            )),
        height: 60,
        width: 60,
      ),
    );
  }
  Widget _buildTaskList(String tabType) {
    Stream<QuerySnapshot> stream;
    if (tabType == 'Packages') {
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
            var task = tasks[index]; // No need to cast, as 'task' is dynamic
            var taskId = task.id;
            var timestamp = task['timestamp']?.toDate();
            var formattedTimestamp = timestamp != null
                ? "${timestamp.toLocal().toString().split(' ')[0]} ${timestamp.toLocal().toString().split(' ')[1].substring(0, 5)}"
                : 'Unknown time';

            return Padding(
              padding: const EdgeInsets.all(8.0),
              child: NeuMo(
                height: 70,
                widget: ListTile(
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
                  subtitle: Text(DateFormat('yyyy-MM-dd HH:mm')
                      .format(task['timestamp'].toDate())),
                  title: Text(task['taskName'], style: TextStyle(fontSize: 18,fontWeight: FontWeight.w500)),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => tabType == 'Packages'
                            ? TaskDetailScreen(task: task) // Pass dynamic task
                            : CompletedTaskDetailScreen(task: task), // Pass dynamic task
                      ),
                    );
                  },


                ),
              ),
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
    var name = widget.task['taskName'];

    return Scaffold(
      backgroundColor: Color(0xFFE0E5EC),
      appBar: AppBar(
        backgroundColor: Color(0xFFE0E5EC),
        title: Text('Task Details',style: TextStyle(fontWeight: FontWeight.w500)),
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
            Text('Task Name: $name',style: TextStyle(fontWeight: FontWeight.w500,fontSize: 18,color: Colors.blueAccent)),
            // SizedBox(height: 8),
            // Text('Assigned To: ${widget.task['assignedTo'] ?? 'N/A'}'),
            SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                NeuMo(
                  height: 60,width: 60,
                  widget: IconButton(


                    onPressed: _captureImages,
                    icon: Icon(Icons.image,size: 30,color: Colors.orange,),
                  ),
                ),
                NeuMo(
                  height: 60,width: 60,
                  widget: IconButton(


                    onPressed: _isRecording ? _stopRecording : _startRecording

                    ,
                    icon: Icon(_isRecording ? Icons.stop_circle : Icons.mic,size: 30,color: Colors.teal,),
                  ),
                ),
                NeuMo(
                  height: 60,width: 60,
                  widget: IconButton(


    onPressed: () => _assignTaskToWorker4(taskId),
                    icon: Icon(Icons.send,size: 30,color: Colors.lightGreen,),
                  ),
                ),

              ],
            ),
            SizedBox(height: 16),
            if (_capturedImages.isNotEmpty)
              Wrap(
                spacing: 8,
                children: _capturedImages
                    .map((image) => Image.file(image, height: 100,width: 100,fit: BoxFit.cover,))
                    .toList(),
              ),
            SizedBox(height: 16),

          ],
        ),
      ),
    );
  }
}



class CompletedTaskDetailScreen extends StatelessWidget {
  final dynamic task;

  CompletedTaskDetailScreen({required this.task});

  @override
  Widget build(BuildContext context) {
    var imageUrls = List<String>.from(task['dispatchImage'] ?? []);
    var audioUrl = task['dispatchAudio'];
    var taskId = task.id;
    var assignedTo = task['assignedTo'] ?? 'N/A';
    var taskName = task['taskName'] ?? 'N/A';

    return Scaffold(
      backgroundColor: Color(0xFFE0E5EC),
      appBar: AppBar(
        backgroundColor: Color(0xFFE0E5EC),
        title: Text('Dispatched Details',style: TextStyle(fontWeight: FontWeight.w500),),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Task Name: $taskName'
                '',style: TextStyle(fontWeight: FontWeight.w500,fontSize: 18,color: Colors.teal)),
            SizedBox(height: 8),
            Text('Assigned To: $assignedTo',style: TextStyle(fontWeight: FontWeight.w500,fontSize: 18,color: Colors.blueAccent)),
            SizedBox(height: 16),
            if (imageUrls.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Dispatch Images:', style: TextStyle(fontWeight: FontWeight.bold,fontSize: 16)),
                  SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: imageUrls
                        .map((imageUrl) => GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                FullImageScreen(imageUrls: imageUrls),
                          ),
                        );
                      },
                      child: Image.network(
                        imageUrl,
                        height: 100,
                        fit: BoxFit.cover,
                      ),
                    ))
                        .toList(),
                  ),
                ],
              ),
            SizedBox(height: 16),
            if (audioUrl != null)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Dispatch Audio:', style: TextStyle(fontWeight: FontWeight.bold,fontSize: 16)),
                  SizedBox(height: 12),
                  AudioPlayerWidget(audioUrl: audioUrl),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class AudioPlayerWidget extends StatefulWidget {
  final String audioUrl;

  AudioPlayerWidget({required this.audioUrl});

  @override
  _AudioPlayerWidgetState createState() => _AudioPlayerWidgetState();
}

class _AudioPlayerWidgetState extends State<AudioPlayerWidget> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool isPlaying = false;

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _togglePlayPause() async {
    if (isPlaying) {
      await _audioPlayer.pause();
    } else {
      await _audioPlayer.play(UrlSource(widget.audioUrl));
    }
    setState(() {
      isPlaying = !isPlaying;
    });
  }

  @override
  Widget build(BuildContext context) {
    return NeuMo(
      height: 60,
      widget: Row(
        children: [
          IconButton(
            icon: Icon(isPlaying ? Icons.pause : Icons.play_arrow),
            onPressed: _togglePlayPause,
          ),
          Text(isPlaying ? 'Pause' : 'Play',style: TextStyle(fontWeight: FontWeight.w500,fontSize: 18,color: Colors.green)),
        ],
      ),
    );
  }
}
