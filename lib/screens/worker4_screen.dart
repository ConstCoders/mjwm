import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:audioplayers/audioplayers.dart';
import 'login_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';

class Worker4Screen extends StatefulWidget {
  @override
  _Worker4ScreenState createState() => _Worker4ScreenState();
}

class _Worker4ScreenState extends State<Worker4Screen>
    with SingleTickerProviderStateMixin {
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
                .where((doc) =>
            doc['packing'] == 'completed' &&
                doc['dispatch'] == 'completed' &&
                doc['delivery'] == 'pending')
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


  Future<void> _markAsDelivered(String taskId) async {
    final XFile? image = await _picker.pickImage(source: ImageSource.camera);
    if (image != null) {
      try {
        String filePath = 'delivered/${DateTime.now().millisecondsSinceEpoch}.jpg';
        Reference storageRef = FirebaseStorage.instance.ref(filePath);
        await storageRef.putFile(File(image.path));
        String imageUrl = await storageRef.getDownloadURL();

        FirebaseFirestore.instance.collection('tasks').doc(taskId).update({
          'delivery': 'completed',
          'deliveredImage': imageUrl,
        });

        Fluttertoast.showToast(msg: 'Image successfully stored');
      } catch (e) {
        // Handle any errors during the upload and update process
        print('Error uploading image: $e');
        Fluttertoast.showToast(msg: 'Error uploading image: $e');
      }
    }
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


  Widget _buildTaskList(List<Map<String, dynamic>> tasks, bool isDelivery, bool isDelivered) {
    return ListView.builder(
      itemCount: tasks.length,
      itemBuilder: (context, index) {
        var task = tasks[index];
        return ListTile(
          leading: task['image'] != null
              ? ClipRRect(
            borderRadius: BorderRadius.circular(8.0),
            child: Image.network(
              task['image'],
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
          title: GestureDetector(
            onTap: () {
              if (task['voiceMessageUrl'] != null) {
                _playVoiceMessage(task['voiceMessageUrl']);
              } else {
                Fluttertoast.showToast(msg: 'No voice message available.');
              }
            },
            child: Text(
              "Task received at ${task['timestamp'].toDate().toLocal().toString().split(' ')[0] + ' ' + task['timestamp'].toDate().toLocal().toString().split(' ')[1].substring(0, 5)}",
            ),
          ),
          subtitle: Text('${task['id']}'),
          trailing: isDelivery
              ? ElevatedButton(
            onPressed: isDelivered ? null : () => _markAsDelivered(task['id']),
            style: ElevatedButton.styleFrom(
              backgroundColor: isDelivered ? Colors.green : Colors.blueAccent,
            ),
            child: Icon(
              isDelivered ? Icons.done : Icons.camera_alt_sharp,
              color: Colors.white,
            ),
          )
              : ElevatedButton(
            onPressed: () async {
              await FirebaseFirestore.instance
                  .collection('tasks')
                  .doc(task['id'])
                  .update({'delivery': 'outForDelivery'});
              Fluttertoast.showToast(msg: 'Task marked as Out for Delivery');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
            ),
            child: Text('OFD'),
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
          _buildTaskList(_tasks, false, false),
          _buildTaskList(_outForDeliveryTasks, true, false),
          _buildTaskList(_deliveredTasks, true, true),
        ],
      ),
    );
  }
}
