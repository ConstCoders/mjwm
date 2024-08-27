import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:image_picker/image_picker.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:velocity_x/velocity_x.dart';
import '../widgets/neu.dart';
import 'login_screen.dart';

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
      userDoc =
          FirebaseFirestore.instance.collection('users').doc(currentUser!.uid);
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
          taskIds = (data['tasks'] as List<dynamic>)
              .map((e) => e.toString())
              .toList();
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
            doc['packing'] == 'completed' && doc['dispatch'] == 'completed' &&
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
  Widget _buildTaskList(List<Map<String, dynamic>> tasks, bool isOutForDelivery,
      bool isDelivered) {
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
                builder: (context) => DeliveryDetailsPage(
                    task: task), // Redirect to DeliveryDetailsPage
              ),
            );
          }
              : () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                isOutForDelivery
                    ? OFDDetailsPage(
                    task: task) // Redirect to OFDDetailsPage for Out for Delivery tasks
                    : TaskDetailsPage(
                    task: task), // Redirect to TaskDetailsPage for other tasks
              ),
            );
          },
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
            padding: const EdgeInsets.all(16.0),
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
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 8.0),
                      Text(
                        "Received: ${task['timestamp'].toDate()
                            .toLocal()
                            .toString()
                            .split(' ')[0]} ${task['timestamp'].toDate()
                            .toLocal().toString()
                            .split(' ')[1].substring(0, 5)}",
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
                      TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                      unselectedLabelColor: Colors.grey.shade600,
                      tabs: [
                        Tab(text: "Packages"),
                        Tab(text: "OFD"),
                        Tab(text: "Delivered"),
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
                      _buildTaskList(_tasks, false, false),

                      // Out for Delivery Tab
                      _buildTaskList(_outForDeliveryTasks, true, false),

                      // Delivered Tab
                      _buildTaskList(_deliveredTasks, false, true),

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
      await FirebaseFirestore.instance.collection('tasks').doc(
          widget.task['id']).update({
        'delivery': 'outForDelivery',
        'timestamp': FieldValue.serverTimestamp(), // Update timestamp
      });

      Fluttertoast.showToast(msg: 'Task marked as Out for Delivery.');
      Navigator.pop(context); // Go back to the previous screen
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
        backgroundColor: Color(0xFFE0E5EC),
        appBar: AppBar(
          backgroundColor: Color(0xFFE0E5EC),
          title: Text('Task Details'),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: SingleChildScrollView(
              physics: BouncingScrollPhysics(),
              child: Column(

                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [


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
                value: widget.task['delivery'] == 'outForDelivery'
                    ? "Out for Delivery"
                    : "Pending",
              ),
              SizedBox(height: 20),

              // Show dispatch images if they exist
              if (widget.task['dispatchImage'] !=
              null && widget.task['dispatchImage'].isNotEmpty)
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
        NeuMo(
          height: 60,
          widget: ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent, elevation: 0
            ),
            onPressed: () => _playAudio(widget.task['dispatchAudio']),
            child: Text('Play Audio',
              style: TextStyle(color: Colors.green, fontSize: 18),),
          ),
        ),
      ],
    )
    ,
    SizedBox(height: 30),

    // Out for Delivery Button
    Center(
    child: NeuMo(
    height: 60,
    widget: ElevatedButton(
    style: ElevatedButton.styleFrom(
    backgroundColor: Colors.transparent,elevation: 0
    ),
    onPressed: _isUpdating ? null : _markAsOutForDelivery,

    child: _isUpdating
    ? CircularProgressIndicator(color: Colors.white)
        : Text('Mark as Out for Delivery',style: TextStyle(color: Colors.blueAccent, fontSize: 18)),
    ),
    ),

    ),
                    SizedBox(height: 8,)
    ]
    ),
    ),
        ));
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
                width: 300,
                height: 300,
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
      var storageRef = FirebaseStorage.instance.ref().child('images/${DateTime
          .now()
          .millisecondsSinceEpoch}.png');
      var uploadTask = storageRef.putFile(File(image.path));
      await uploadTask.whenComplete(() async {
        var downloadUrl = await storageRef.getDownloadURL();

        await FirebaseFirestore.instance.collection('tasks').doc(
            widget.task['id']).update({
          'delivery': 'completed',
          'deliveredImage': downloadUrl,
          'timestamp': FieldValue.serverTimestamp(), // Update timestamp
        });

        Fluttertoast.showToast(
            msg: 'Delivered image captured and task marked as Delivered.');
        Navigator.pop(context); // Go back to the previous screen
      });
    } catch (e) {
      print('Error capturing delivered image: $e');
      Fluttertoast.showToast(msg: 'Error capturing delivered image.');
    }

    setState(() {
      _isUpdating = false;
    });
  }

  String userName = '';

  @override
  void initState() {
    super.initState();
    fetchUserName();
  }

  Future<void> fetchUserName() async {
    if (widget.task['completedBy'] != null) {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.task['completedBy'])
          .get();

      if (userDoc.exists) {
        setState(() {
          userName = userDoc.data()?['username'] ?? 'Unknown User';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFE0E5EC),
      appBar: AppBar(
        backgroundColor: Color(0xFFE0E5EC),
        title: Text('Out for Delivery Details', style: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
        ),),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          physics: BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Table(
                  columnWidths: const {
                    0: IntrinsicColumnWidth(),
                    1: FlexColumnWidth(),
                  },
                  defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                  children: [
                    _buildTableRow(
                        'Task Name:', widget.task['taskName'] ?? 'N/A',
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.blueAccent),
                    _buildTableRow(
                        'Delivery Status:', widget.task['delivery'] ?? 'N/A',
                        color: getStatusColor(widget.task['delivery'])),
                    _buildTableRow(
                        'Dispatch Status:', widget.task['dispatch'] ?? 'N/A',
                        color: getStatusColor(widget.task['dispatch'])),
                    _buildTableRow(
                        'Packing Status:', widget.task['packing'] ?? 'N/A',
                        color: getStatusColor(widget.task['packing'])),
                    _buildTableRow(
                        'Invoice Sent:', widget.task['invoiceSend'] ?? 'N/A',
                        color: getStatusColor(widget.task['invoiceSend'])),
                    _buildTableRow(
                        'Assigned To:', widget.task['assignedTo'] ?? 'N/A'),
                    _buildTableRow('Packed By:', userName),
                  ],
                ),
              ),
              SizedBox(height: 16.0),


              // Show dispatch images if available
              if (widget.task['dispatchImage'] != null &&
                  (widget.task['dispatchImage'] as List).isNotEmpty)
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
                      height: 300.0,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: (widget.task['dispatchImage'] as List)
                            .length,
                        itemBuilder: (context, index) {
                          var imageUrl = widget.task['dispatchImage'][index];
                          return Container(
                            margin: EdgeInsets.only(right: 8.0),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8.0),
                              child: Image.network(
                                imageUrl,
                                width: 300,
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
                    NeuMo(
                      height: 60,
                      widget: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFFE0E5EC), elevation: 0
                        ),
                        onPressed: () =>
                            _playAudio(widget.task['dispatchAudio']),
                        child: Text('Play Audio', style: TextStyle(
                          fontSize: 16, color: Colors.green,
                          fontWeight: FontWeight.bold,
                        ),),
                      ),
                    ),
                  ],
                ),
              SizedBox(height: 24.0),

              // Show invoice images if available
              if (widget.task['invoiceImages'] != null &&
                  (widget.task['invoiceImages'] as List).isNotEmpty)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Invoice Images:",
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
                        itemCount: (widget.task['invoiceImages'] as List)
                            .length,
                        itemBuilder: (context, index) {
                          var imageUrl = widget.task['invoiceImages'][index];
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

              // Show delivered image if available
              if (widget.task['deliveredImage'] != null)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Delivered Image:",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8.0),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8.0),
                      child: Image.network(
                        widget.task['deliveredImage'],
                        height: 200.0,
                        fit: BoxFit.cover,
                      ),
                    ),
                    SizedBox(height: 16.0),
                  ],
                ),

              Center(
                child: NeuMo(
                  height: 60,
                  widget: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent, elevation: 0
                    ),
                    onPressed: _captureDeliveredImage,
                    child: _isUpdating
                        ? CircularProgressIndicator()
                        : Text('Capture Delivered Image', style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold, color: Colors.blue
                    ),),
                  ),
                ),
              ),
              SizedBox(height: 12,)
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
      backgroundColor: Color(0xFFE0E5EC),
      appBar: AppBar(
        backgroundColor: Color(0xFFE0E5EC),
        title: Text('Delivery Details', style: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
        ),),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
      
          SizedBox(height: 16.0),
          Text("Task Name: ${task['taskName'] ?? 'N/A'}", style: TextStyle(
            fontSize: 18,color: Colors.teal,
            fontWeight: FontWeight.bold,
          ),),
      
          Text("Status: ${task['delivery'] ?? 'N/A'}", style: TextStyle(
            fontSize: 18,color: Colors.green,
            fontWeight: FontWeight.bold,
          ),),
          SizedBox(height: 16.0),
          if (task['deliveredImage'] != null)
            Image.network(task['deliveredImage']),
        ],
      ).box.margin(EdgeInsets.symmetric(horizontal: 18)).make(),
    );
  }
}

Color getStatusColor(String? status) {
  switch (status?.toLowerCase()) {
    case 'completed':
      return Colors.green;
    case 'pending':
      return Colors.red;
    case 'in progress':
      return Colors.orange;
    default:
      return Colors.orange;
  }
}


TableRow _buildTableRow(String heading, String value,
    {Color color = Colors
        .black, double fontSize = 16, FontWeight fontWeight = FontWeight
        .normal}) {
  return TableRow(
    children: [
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Text(
          heading,
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: fontSize),
        ),
      ),
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Text(
          value,
          style: TextStyle(
              color: color, fontSize: fontSize, fontWeight: fontWeight),
        ),
      ),
    ],
  );
}
