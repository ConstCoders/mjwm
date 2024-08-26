import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:image_picker/image_picker.dart';
import 'package:audioplayers/audioplayers.dart';
import 'login_screen.dart';

class Worker4Screen extends StatefulWidget {
  @override
  _Worker4ScreenState createState() => _Worker4ScreenState();
}

class _Worker4ScreenState extends State<Worker4Screen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Map<String, dynamic>> _tasks = [];
  List<Map<String, dynamic>> _outForDeliveryTasks = [];
  List<Map<String, dynamic>> _deliveredTasks = [];
  final ImagePicker _picker = ImagePicker();
  late User? currentUser;
  late DocumentReference userDoc;
  late AudioPlayer _audioPlayer;
  String? _currentPlayingUrl;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      userDoc = FirebaseFirestore.instance.collection('users').doc(currentUser!.uid);
      _loadTasks();
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => LoginScreen()),
      );
    }
    _audioPlayer = AudioPlayer();
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => LoginScreen()),
    );
  }

  void _loadTasks() {
    userDoc.snapshots().listen((snapshot) {
      var taskIds = <String>[];
      if (snapshot.exists && snapshot.data() != null) {
        var data = snapshot.data() as Map<String, dynamic>;
        if (data.containsKey('tasks')) {
          taskIds = (data['tasks'] as List<dynamic>).map((e) => e.toString()).toList();
        }
      }

      if (taskIds.isNotEmpty) {
        FirebaseFirestore.instance
            .collection('tasks')
            .where(FieldPath.documentId, whereIn: taskIds)
            .snapshots()
            .listen((taskSnapshot) {
          setState(() {
            _tasks = taskSnapshot.docs
                .where((doc) => doc['packing'] == 'completed' && doc['dispatch'] == 'completed' && doc['delivery'] == 'pending')
                .map((doc) {
              var data = doc.data() as Map<String, dynamic>;
              data['id'] = doc.id;
              return data;
            }).toList();

            _outForDeliveryTasks = taskSnapshot.docs
                .where((doc) => doc['delivery'] == 'outForDelivery')
                .map((doc) {
              var data = doc.data() as Map<String, dynamic>;
              data['id'] = doc.id;
              return data;
            }).toList();

            _deliveredTasks = taskSnapshot.docs
                .where((doc) => doc['delivery'] == 'completed')
                .map((doc) {
              var data = doc.data() as Map<String, dynamic>;
              data['id'] = doc.id;
              return data;
            }).toList();
          });
        });
      } else {
        setState(() {
          _tasks = [];
          _outForDeliveryTasks = [];
          _deliveredTasks = [];
        });
      }
    });
  }

  Future<void> _playVoiceMessage(String url) async {
    if (_currentPlayingUrl != url) {
      await _audioPlayer.stop();
      await _audioPlayer.play(UrlSource(url));
      _currentPlayingUrl = url;
    } else {
      if (_audioPlayer.state == PlayerState.playing) {
        await _audioPlayer.pause();
      } else {
        await _audioPlayer.resume();
      }
    }
  }

  // Build list for Tasks Tab
  Widget _buildTaskList(List<Map<String, dynamic>> tasks, bool isOutForDelivery, bool isDelivered) {
    return ListView.builder(
      itemCount: tasks.length,
      itemBuilder: (context, index) {
        var task = tasks[index];

        return GestureDetector(
          onTap: isDelivered
              ? () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => DeliveryDetailsPage(task: task), // Redirect to DeliveryDetailsPage
              ),
            );
          }
              : () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => isOutForDelivery
                    ? OFDDetailsPage(task: task)  // Redirect to OFDDetailsPage for Out for Delivery tasks
                    : TaskDetailsPage(task: task),  // Redirect to TaskDetailsPage for other tasks
              ),
            );
          },
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12.0),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.4),
                  offset: Offset(4, 4),
                  blurRadius: 6,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Row(
              children: [
                task['images'] != null
                    ? ClipRRect(
                  borderRadius: BorderRadius.circular(8.0),
                  child: Image.network(
                    task['images'][0],
                    width: 50,
                    height: 50,
                    fit: BoxFit.cover,
                  ),
                )
                    : ClipRRect(
                  borderRadius: BorderRadius.circular(8.0),
                  child: Image.asset(
                    'assets/images/logo.png',
                    width: 50,
                    height: 50,
                    fit: BoxFit.cover,
                  ),
                ),
                SizedBox(width: 16.0),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        task['taskName'] ?? 'No Task Name',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 8.0),
                      Text(
                        "Received: ${task['timestamp'].toDate().toLocal().toString().split(' ')[0]} ${task['timestamp'].toDate().toLocal().toString().split(' ')[1].substring(0, 5)}",
                        style: TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
            onPressed: _logout,
            icon: Icon(Icons.logout),
          ),
        ],
        title: Text('Worker 4 Dashboard'),
        backgroundColor: Colors.blueAccent,
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: "Tasks"),
            Tab(text: "Out for Delivery"),
            Tab(text: "Delivered"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Tasks Tab
          _buildTaskList(_tasks, false, false),

          // Out for Delivery Tab
          _buildTaskList(_outForDeliveryTasks, true, false),

          // Delivered Tab
          _buildTaskList(_deliveredTasks, false, true),
        ],
      ),
    );
  }
}



class TaskDetailsPage extends StatefulWidget {
  final Map<String, dynamic> task;

  TaskDetailsPage({required this.task});

  @override
  _TaskDetailsPageState createState() => _TaskDetailsPageState();
}

class _TaskDetailsPageState extends State<TaskDetailsPage> {
  final ImagePicker _picker = ImagePicker();
  bool _isUpdating = false;
  AudioPlayer _audioPlayer = AudioPlayer();
  String? _currentAudioUrl;

  Future<void> _markAsOutForDelivery() async {
    setState(() {
      _isUpdating = true;
    });

    try {
      await FirebaseFirestore.instance.collection('tasks').doc(widget.task['id']).update({
        'delivery': 'outForDelivery',
        'timestamp': FieldValue.serverTimestamp(),  // Update timestamp
      });

      Fluttertoast.showToast(msg: 'Task marked as Out for Delivery.');
      Navigator.pop(context);  // Go back to the previous screen
    } catch (e) {
      print('Error updating task status: $e');
      Fluttertoast.showToast(msg: 'Error updating task status.');
    }

    setState(() {
      _isUpdating = false;
    });
  }

  Future<void> _playAudio(String url) async {
    if (_currentAudioUrl != url) {
      await _audioPlayer.stop();
      await _audioPlayer.play(UrlSource(url));
      _currentAudioUrl = url;
    } else {
      if (_audioPlayer.state == PlayerState.playing) {
        await _audioPlayer.pause();
      } else {
        await _audioPlayer.resume();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Task Details'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Task Details",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 20),
              _buildDetailRow(
                title: "Task Name",
                value: widget.task['taskName'] ?? "N/A",
              ),
              SizedBox(height: 10),
              _buildDetailRow(
                title: "Task ID",
                value: widget.task['id'] ?? "N/A",
              ),
              SizedBox(height: 10),
              _buildDetailRow(
                title: "Status",
                value: widget.task['delivery'] == 'outForDelivery' ? "Out for Delivery" : "Pending",
              ),
              SizedBox(height: 20),

              // Show dispatch images if they exist
              if (widget.task['dispatchImage'] != null && widget.task['dispatchImage'].isNotEmpty)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Dispatch Images",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 10),
                    _buildImageList(List<String>.from(widget.task['dispatchImage'])),
                  ],
                ),
              SizedBox(height: 20),

              // Show dispatch audio if it exists
              if (widget.task['dispatchAudio'] != null)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Dispatch Audio",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 10),
                    ElevatedButton(
                      onPressed: () => _playAudio(widget.task['dispatchAudio']),
                      child: Text('Play Audio'),
                    ),
                  ],
                ),
              SizedBox(height: 30),

              // Out for Delivery Button
              Center(
                child: ElevatedButton(
                  onPressed: _isUpdating ? null : _markAsOutForDelivery,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                  ),
                  child: _isUpdating
                      ? CircularProgressIndicator(color: Colors.white)
                      : Text('Mark as Out for Delivery'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow({required String title, required String value}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
        ),
        Text(
          value,
          style: TextStyle(fontSize: 18, color: Colors.black54),
        ),
      ],
    );
  }

  Widget _buildImageList(List<String> imageUrls) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: imageUrls.map((imageUrl) {
          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8.0),
              child: Image.network(
                imageUrl,
                width: 100,
                height: 100,
                fit: BoxFit.cover,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class OFDDetailsPage extends StatefulWidget {
  final Map<String, dynamic> task;

  OFDDetailsPage({required this.task});

  @override
  _OFDDetailsPageState createState() => _OFDDetailsPageState();
}



class _OFDDetailsPageState extends State<OFDDetailsPage> {
  final ImagePicker _picker = ImagePicker();
  bool _isUpdating = false;

  Future<void> _captureDeliveredImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.camera);
    if (image == null) return;

    setState(() {
      _isUpdating = true;
    });

    try {
      var storageRef = FirebaseStorage.instance.ref().child('images/${DateTime.now().millisecondsSinceEpoch}.png');
      var uploadTask = storageRef.putFile(File(image.path));
      await uploadTask.whenComplete(() async {
        var downloadUrl = await storageRef.getDownloadURL();

        await FirebaseFirestore.instance.collection('tasks').doc(widget.task['id']).update({
          'delivery': 'completed',
          'deliveredImage': downloadUrl,
          'timestamp': FieldValue.serverTimestamp(),  // Update timestamp
        });

        Fluttertoast.showToast(msg: 'Delivered image captured and task marked as Delivered.');
        Navigator.pop(context);  // Go back to the previous screen
      });
    } catch (e) {
      print('Error capturing delivered image: $e');
      Fluttertoast.showToast(msg: 'Error capturing delivered image.');
    }

    setState(() {
      _isUpdating = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Out for Delivery Details'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Out for Delivery Details",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 16.0),
              Text("Task Name: ${widget.task['taskName'] ?? 'N/A'}"),
              Text("Description: ${widget.task['description'] ?? 'N/A'}"),
              Text("Status: ${widget.task['delivery'] ?? 'N/A'}"),
              SizedBox(height: 16.0),

              // Show dispatch images if available
              if (widget.task['dispatchImages'] != null && (widget.task['dispatchImages'] as List).isNotEmpty)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Dispatch Images:",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8.0),
                    Container(
                      height: 200.0,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: (widget.task['dispatchImages'] as List).length,
                        itemBuilder: (context, index) {
                          var imageUrl = widget.task['dispatchImages'][index];
                          return Container(
                            margin: EdgeInsets.only(right: 8.0),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8.0),
                              child: Image.network(
                                imageUrl,
                                width: 150,
                                fit: BoxFit.cover,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    SizedBox(height: 16.0),
                  ],
                ),

              // Show dispatch audio if available
              if (widget.task['dispatchAudio'] != null)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Dispatch Audio:",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8.0),
                    ElevatedButton(
                      onPressed: () => _playAudio(widget.task['dispatchAudio']),
                      child: Text('Play Audio'),
                    ),
                  ],
                ),
              SizedBox(height: 16.0),

              ElevatedButton(
                onPressed: _captureDeliveredImage,
                child: _isUpdating ? CircularProgressIndicator() : Text('Capture Delivered Image'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _playAudio(String url) async {
    final player = AudioPlayer();
    await player.play(UrlSource(url));
  }
}


class DeliveryDetailsPage extends StatelessWidget {
  final Map<String, dynamic> task;

  DeliveryDetailsPage({required this.task});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Delivery Details'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Delivery Details",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16.0),
            Text("Task Name: ${task['taskName'] ?? 'N/A'}"),
            Text("Description: ${task['description'] ?? 'N/A'}"),
            Text("Status: ${task['delivery'] ?? 'N/A'}"),
            SizedBox(height: 16.0),
            if (task['deliveredImage'] != null)
              Image.network(task['deliveredImage']),
          ],
        ),
      ),
    );
  }
}
