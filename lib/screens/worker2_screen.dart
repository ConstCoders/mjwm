import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:intl/intl.dart';
import 'package:mjworkmanagement/widgets/neu.dart';
import 'package:photo_view/photo_view.dart';
import 'package:audioplayers/audioplayers.dart';

import 'login_screen.dart';

class Worker2Screen extends StatefulWidget {
  @override
  _Worker2ScreenState createState() => _Worker2ScreenState();
}

class _Worker2ScreenState extends State<Worker2Screen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;
  late String currentUserId;
  late AudioPlayer audioPlayer;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _initializeNotifications();
    _loadCurrentUser();
    audioPlayer = AudioPlayer();
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
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      setState(() {
        currentUserId = user.uid;
      });
    }
  }

  Future<void> _playAudio(String audioUrl) async {
    try {
      await audioPlayer.play(UrlSource(audioUrl));
    } catch (e) {
      print("Error playing audio: $e");
    }
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
                          text: 'Tasks',
                        ),
                        Tab(text: 'Completed'),
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
                      _buildTaskList('packing', 'pending'),
                      _buildTaskList('packing', 'completed'),
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

  Widget _buildTaskList(String taskType, String status) {
    return StreamBuilder(
      stream: status == 'completed'
          ? FirebaseFirestore.instance
              .collection('tasks')
              .where('completedBy', isEqualTo: currentUserId)
              .snapshots()
          : FirebaseFirestore.instance
              .collection('tasks')
              .where(taskType, isEqualTo: status)
              .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Center(child: CircularProgressIndicator());
        }
        var tasks = snapshot.data!.docs;
        return ListView.builder(
          itemCount: tasks.length,
          itemBuilder: (context, index) {
            var task = tasks[index];
            return Padding(
              padding: const EdgeInsets.all(8.0),
              child: NeuMo(
                height: 75,
                widget: ListTile(
                  leading: task['images'].isNotEmpty
                      ? GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => FullImageScreen(
                                    imageUrl: task['images'][
                                        0]), // Pass the first image for preview
                              ),
                            );
                          },
                          child: Container(
                            width: 50,
                            height: 50,
                            child: Image.network(
                              task['images']
                                  [0], // Display first image as thumbnail
                              fit: BoxFit.cover,
                            ),
                          ),
                        )
                      : Icon(Icons.image_not_supported),
                  title: Text(task['taskName'],style: TextStyle(fontSize: 18,fontWeight: FontWeight.w500),),
                  subtitle: Text(DateFormat('yyyy-MM-dd HH:mm')
                      .format(task['timestamp'].toDate())),
                  trailing: status != 'completed'
                      ? NeuMo(
                          height: 50,
                          widget: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                elevation: 0),
                            onPressed: () async {
                              await FirebaseFirestore.instance
                                  .collection('tasks')
                                  .doc(task.id)
                                  .update({
                                taskType: 'completed',
                                'completedBy': currentUserId
                              });
                              await FirebaseFirestore.instance
                                  .collection('users')
                                  .doc(currentUserId)
                                  .collection('completedTasks')
                                  .doc(task.id)
                                  .set(task.data());
                              _showNotification('Task Completed',
                                  'You have completed a task.');
                            },
                            child: Icon(
                              Icons.hourglass_empty,
                              color: Colors.red,
                            ),
                          ),
                        )
                      : NeuMo(
                          height: 50,
                          widget: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                elevation: 0),
                            onPressed: () async {
                              await FirebaseFirestore.instance
                                  .collection('tasks')
                                  .doc(task.id)
                                  .update({
                                taskType: 'pending',
                                'completedBy': FieldValue.delete()
                              });
                              await FirebaseFirestore.instance
                                  .collection('users')
                                  .doc(currentUserId)
                                  .collection('completedTasks')
                                  .doc(task.id)
                                  .delete();
                            },
                            child: Icon(
                              Icons.done_all,
                              color: Colors.green,
                            ),
                          ),
                        ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => TaskDetailsPage(
                            task: task), // Navigate to Task Details
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
}

class TaskDetailsPage extends StatelessWidget {
  final DocumentSnapshot task;

  TaskDetailsPage({required this.task});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFE0E5EC),
      appBar: AppBar(
        title: Text(
          task['taskName'],
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
        ),
        backgroundColor: Colors.blueAccent,
      ),
      body: ListView(
        padding: EdgeInsets.all(16.0),
        children: [
          Text('Task Details',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          SizedBox(height: 10),
          Text('Task Name: ${task['taskName']}'),
          SizedBox(height: 10),
          Text('Status: ${task['packing']}'),
          SizedBox(height: 10),
          Text('Uploaded on: ${task['timestamp'].toDate()}'),
          SizedBox(height: 10),
          NeuMo(
            height: 60,
            widget: ElevatedButton(
              style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20)),
                  elevation: 0,
                backgroundColor: Color(0xFFE0E5EC)),
              onPressed: () {
                // Play audio associated with the task
                AudioPlayer().play(UrlSource(task['audio']));
              },
              child: Text(
                'Play Audio',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue),
              ),
            ),
          ),
          SizedBox(height: 20),
          Text('Images:', style: TextStyle(fontSize: 18)),
          SizedBox(height: 10),
          for (var imageUrl in task['images']) // Loop through all images
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => FullImageScreen(imageUrl: imageUrl),
                  ),
                );
              },
              child: Container(
                margin: EdgeInsets.only(bottom: 10),
                height: 200,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.black12),
                ),
                child: Image.network(imageUrl, fit: BoxFit.cover),
              ),
            ),
        ],
      ),
    );
  }
}

class FullImageScreen extends StatelessWidget {
  final String imageUrl;

  FullImageScreen({required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Full Image'),
        backgroundColor: Colors.blueAccent,
      ),
      body: Center(
        child: PhotoView(
          imageProvider: NetworkImage(imageUrl),
        ),
      ),
    );
  }
}
