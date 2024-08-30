import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:mjworkmanagement/screens/task_details_screen.dart';
import 'package:mjworkmanagement/widgets/neu.dart';

import '../models/task.dart';

class TaskStatusPage extends StatefulWidget {
  @override
  _TaskStatusPageState createState() => _TaskStatusPageState();
}

class _TaskStatusPageState extends State<TaskStatusPage> {
  String filter = 'All';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFE0E5EC),

      body: Column(
        children: [
          // Filter Buttons
          Container(
            color: Color(0xFFE0E5EC),
            margin: EdgeInsets.symmetric(horizontal: 5,vertical: 5),
            height: 50,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterButton('Today'),
                  _buildFilterButton('7 Days'),
                  _buildFilterButton('28 Days'),
                  _buildFilterButton('All'),
                  _buildFilterButton('Pending'),
                ],
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('tasks')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return Center(child: CircularProgressIndicator());
                }

                final tasks = _filterTasks(snapshot.data!.docs);

                return ListView.builder(
                  itemCount: tasks.length,
                  itemBuilder: (context, index) {
                    final task = tasks[index];
                    return LayoutBuilder(
                      builder: (context, constraints) {
                        return _buildTaskCard(task, constraints.maxWidth, context);
                      },
                    );

                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterButton(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: NeuMo(
        height: 40,width: 105,
        widget: ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.transparent,elevation: 0),

          onPressed: () {
            setState(() {
              filter = text;
            });
          },
          child: Text(text,style: TextStyle(color: filter == text ? Colors.red : Colors.blueGrey ),),
        ),
      ),
    );
  }

  List<QueryDocumentSnapshot> _filterTasks(List<QueryDocumentSnapshot> tasks) {
    final now = DateTime.now();
    if (filter == 'Today') {
      return tasks.where((task) {
        final timestamp = task['timestamp'].toDate();
        return DateFormat('yyyy-MM-dd').format(timestamp) ==
            DateFormat('yyyy-MM-dd').format(now);
      }).toList();
    } else if (filter == '7 Days') {
      return tasks.where((task) {
        final timestamp = task['timestamp'].toDate();
        return now.difference(timestamp).inDays <= 7;
      }).toList();
    } else if (filter == '28 Days') {
      return tasks.where((task) {
        final timestamp = task['timestamp'].toDate();
        return now.difference(timestamp).inDays <= 28;
      }).toList();
    } else if (filter == 'Pending') {
      return tasks.where((task) {
        return task['invoiceSend'] == 'pending' ||
            task['packing'] == 'pending' ||
            task['dispatch'] == 'pending' ||
            task['delivery'] == 'pending';
      }).toList();
    } else {
      return tasks;
    }
  }

  Widget _buildTaskCard(QueryDocumentSnapshot task, double maxWidth, BuildContext context) {
    final taskName = task['taskName'];
    final timestamp = task['timestamp'].toDate();
    final formattedTime = DateFormat('dd-MM-yyyy HH:mm').format(timestamp);

    final invoiceSend = task['invoiceSend'];
    final packing = task['packing'];
    final dispatch = task['dispatch'];
    final delivery = task['delivery'];

    final allCompleted = invoiceSend == 'completed' &&
        packing == 'completed' &&
        dispatch == 'completed' &&
        delivery == 'completed';

    final cardColor = allCompleted ? Colors.lightGreen : Colors.orange;

    return GestureDetector(
      onTap: () async {
        final taskDoc = await FirebaseFirestore.instance
            .collection('tasks')
            .doc(task.id)
            .get();

        if (taskDoc.exists) {
          final taskData = taskDoc.data()!;
          final task = Task.fromMap(taskDoc.id, taskData);

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => TaskDetailsPage(task: task),
            ),
          );
        } else {
          // Handle case where the task does not exist
          print('Task not found');
        }
      },
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
        child: NeuMo(
          height: 150,
          widget: Card(
            color: Colors.transparent,elevation: 0,
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    taskName,
                    style: TextStyle(color: cardColor,fontWeight: FontWeight.w600,fontSize: 22),
                  ),
                  SizedBox(height: 8.0),
                  Text('Time: $formattedTime'),
                  SizedBox(height: 8.0),
                  Wrap(
                    spacing: 8.0,
                    runSpacing: 4.0,
                    children: [
                      _buildStatusLabel('Invoice', invoiceSend),
                      _buildStatusLabel('Packing', packing),
                      _buildStatusLabel('Dispatch', dispatch),
                      _buildStatusLabel('Delivery', delivery),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

  }

  Widget _buildStatusLabel(String label, String status) {
    Color color;
    if (status == 'pending') {
      color = Colors.yellow.shade900;
    } else if (status == 'completed') {
      color = Colors.green;
    } else if (status == 'outForDelivery') {
      color = Colors.blue;
    } else {
      color = Colors.grey;
    }

    return NeuMo(
      height: 40,width: 70,
      widget: Center(child: Text(label,style: TextStyle(color: color),)),


    );
  }
}

class TaskDetailsPages extends StatelessWidget {
  final String taskId;

  TaskDetailsPages({required this.taskId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFE0E5EC),
      appBar: AppBar(
        title: Text('Status'),backgroundColor: Color(0xFFE0E5EC),
      ),
      body: Center(
        child: Text('Details for Task ID: $taskId'),
      ),
    );
  }
}
