import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mjworkmanagement/screens/image_list_screen.dart';
import 'package:mjworkmanagement/screens/payment.dart';
import 'package:mjworkmanagement/screens/payment_status.dart';
import 'employee.dart';
import 'register.dart';
import 'login_screen.dart';
import '../models/task.dart';
import '../widgets/task_progress_tracker.dart';
import 'task_details_screen.dart';


class AdminPanel extends StatefulWidget {
  @override
  _AdminPanelState createState() => _AdminPanelState();
}

class _AdminPanelState extends State<AdminPanel> {
  List<Task> tasks = [];

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => LoginScreen()),
    );
  }

  Future<void> _loadTasks() async {
    try {
      var snapshot = await FirebaseFirestore.instance.collection('tasks').get();
      var taskList = snapshot.docs.map((doc) {
        var data = doc.data();
        return Task.fromMap(doc.id, data);
      }).toList();

      // Sort tasks by newest update
      taskList.sort((a, b) {
        return b.timestamp.compareTo(a.timestamp);
      });

      setState(() {
        tasks = taskList;
        print("Tasks loaded: ${tasks.length}"); // Debug statement
      });
    } catch (e) {
      print("Error loading tasks: $e"); // Debug statement
    }
  }

  void _updateTaskStatus(String taskId, String field, String value) {
    setState(() {
      Task task = tasks.firstWhere((task) => task.id == taskId);
      switch (field) {
        case 'delivery':
          task.delivery = value;
          break;
        case 'dispatch':
          task.dispatch = value;
          break;
        case 'invoiceSend':
          task.invoiceSend = value;
          break;
        case 'packing':
          task.packing = value;
          break;
      }

      FirebaseFirestore.instance.collection('tasks').doc(taskId).update({
        field: value,
        'timestamp': DateTime.now(),
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Admin Panel'),
        backgroundColor: Colors.blueAccent,
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.blue,
              ),
              child: Text(
                'Admin Panel',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                ),
              ),
            ),
            ListTile(
              leading: Icon(Icons.dashboard),
              title: Text('Dashboard'),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: Icon(Icons.payment),
              title: Text('Payments'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PaymentsPages(),
                  ),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.image),
              title: Text('Employees'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => UserListPage(),
                  ),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.supervised_user_circle),
              title: Text('Users'),
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => RegisterScreen()));
              },
            ),
            ListTile(
              leading: Icon(Icons.logout),
              title: Text('Logout'),
              onTap: _logout,
            ),
          ],
        ),
      ),
      body: ListView.builder(
        itemCount: tasks.length,
        itemBuilder: (context, index) {
          Task task = tasks[index];
          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => TaskDetailsScreen(task: task),
                ),
              );
            },
            child: TaskProgressTracker(task: task),
          );
        },
      ),
    );
  }
}



