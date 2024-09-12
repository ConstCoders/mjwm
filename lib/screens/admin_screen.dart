import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:mjworkmanagement/screens/employee.dart';

import 'package:mjworkmanagement/screens/payment.dart';

import 'package:mjworkmanagement/screens/prodetails.dart';

import 'package:mjworkmanagement/screens/register.dart';
import 'package:mjworkmanagement/screens/login_screen.dart';
import 'package:mjworkmanagement/models/task.dart';
import 'package:mjworkmanagement/screens/status.dart';


class AdminPanel extends StatefulWidget {
  @override
  _AdminPanelState createState() => _AdminPanelState();
}

class _AdminPanelState extends State<AdminPanel> {

  String selectedFilter = 'All Time';

  // Function to filter products based on the selected filter
  bool _filterByDate(Timestamp timestamp) {
    final date = timestamp.toDate();
    final now = DateTime.now();
    if (selectedFilter == 'Today') {
      return DateFormat('yyyy-MM-dd').format(date) ==
          DateFormat('yyyy-MM-dd').format(now);
    } else if (selectedFilter == '7 Days') {
      return now.difference(date).inDays <= 7;
    } else if (selectedFilter == '28 Days') {
      return now.difference(date).inDays <= 28;
    }
    return true; // 'All Time' shows all products
  }

  List<Task> tasks = [];
  bool isLoading = true; // Track loading state

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
    setState(() {
      isLoading = true;
    });

    try {
      var snapshot = await FirebaseFirestore.instance.collection('tasks').get();

      if (snapshot.docs.isEmpty) {
        setState(() {
          tasks = [];
          isLoading = false;
        });
        return;
      }

      // Use a proper null-safe mapping
      List<Task> taskList = snapshot.docs.map((doc) {
        var data = doc.data();
        print("Task Data: $data");

        // Check if the task has a valid timestamp
        if (data.containsKey('timestamp') && data['timestamp'] != null) {
          return Task.fromMap(doc.id, data); // Return the task if valid
        } else {
          print("Skipping task due to missing timestamp: ${doc.id}");
          return null; // Return null if timestamp is missing
        }
      }).where((task) => task != null).map((task) => task as Task).toList(); // Filter out null values

      // Sort tasks by newest update
      taskList.sort((a, b) => b.timestamp.compareTo(a.timestamp));

      setState(() {
        tasks = taskList;
        isLoading = false;
      });
    } catch (e) {
      print("Error loading tasks: $e");
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to load tasks: $e")),
      );
    }
  }


  void _updateTaskStatus(String taskId, String field, String value) async {
    try {
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

      await FirebaseFirestore.instance.collection('tasks').doc(taskId).update({
        field: value,
        'timestamp': DateTime.now(), // Update timestamp on status change
      });

      setState(() {
        // Trigger a UI update
      });
    } catch (e) {
      print("Error updating task status: $e");
      // Show error message to user
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to update task: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Admin Panel', style: TextStyle(fontWeight: FontWeight.w600),),
        backgroundColor: Color(0xFFE0E5EC),
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            DrawerHeader(

              decoration: BoxDecoration(
                color:Colors.grey[900],
              ),
              child: Text(
                'Admin Panel',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,fontWeight: FontWeight.bold
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
              leading: Icon(Icons.production_quantity_limits),
              title: Text('Products'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ProductListPage(),
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
                Navigator.push(
                    context, MaterialPageRoute(builder: (context) => RegisterScreen()));
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
      body: isLoading
          ? Center(child: CircularProgressIndicator()) // Show loading indicator
          : tasks.isEmpty
          ? Center(child: Text('No tasks available')) // Show this if no tasks are loaded
          : TaskStatusPage(),
    );
  }
  // Helper method to create filter buttons
  Widget _buildFilterButton(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 0),
      child: GestureDetector(
        onTap: () {
          setState(() {
            selectedFilter = title;
          });
        },
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: BoxDecoration(
            color: selectedFilter == title ? Colors.grey[300] : Colors.grey[200],
            borderRadius: BorderRadius.circular(20),

          ),
          child: Text(
            title,
            style: TextStyle(
              color: selectedFilter == title ? Colors.black : Colors.grey[800],
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}