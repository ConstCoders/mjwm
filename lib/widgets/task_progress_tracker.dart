import 'package:flutter/material.dart';
import '../models/task.dart';
import '../screens/task_details_screen.dart';

class TaskProgressTracker extends StatelessWidget {
  final Task task;

  TaskProgressTracker({required this.task});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TaskDetailsPage(task: task),
          ),
        );
      },
      child: Card(
        elevation: 3,
        margin: EdgeInsets.symmetric(vertical: 10, horizontal: 15),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            ListTile(
              title: Text('Task: ${task.taskName ?? task.id}', style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text('Timestamp: ${task.timestamp}'),
            ),
            _buildTaskTable(),
          ],
        ),
      ),
    );
  }

  Widget _buildTaskTable() {
    return Table(
      border: TableBorder.all(color: Colors.grey.withOpacity(0)),
      columnWidths: const {
        0: FlexColumnWidth(2),
        1: FlexColumnWidth(1.5),
        2: FlexColumnWidth(1.5),
        3: FlexColumnWidth(1.5),
        4: FlexColumnWidth(1.5),
        5: FlexColumnWidth(1.5),
      },
      children: [
        TableRow(
          decoration: BoxDecoration(color: Colors.grey[300]),
          children: [
            _buildTableCell('Task', isHeader: true),
            _buildTableCell('Invoice Sent', isHeader: true),
            _buildTableCell('Packing', isHeader: true),
            _buildTableCell('Dispatch', isHeader: true),
            _buildTableCell('Delivery', isHeader: true),
            _buildTableCell('Status', isHeader: true),
          ],
        ),
        TableRow(
          children: [
            _buildTableCell(task.taskName ?? task.id),
            _buildStatusCell(task.invoiceSend),
            _buildStatusCell(task.packing),
            _buildStatusCell(task.dispatch),
            _buildStatusCell(task.delivery),
            _buildOverallStatusCell(),
          ],
        ),
      ],
    );
  }

  Widget _buildTableCell(String content, {bool isHeader = false, Color? backgroundColor}) {
    return Container(
      color: backgroundColor ?? (isHeader ? Colors.grey.shade300 : Colors.white),
      padding: EdgeInsets.all(8.0),
      child: Text(
        content,
        style: TextStyle(
          fontWeight: isHeader ? FontWeight.bold : FontWeight.normal,
          color: isHeader ? Colors.black : Colors.black87,
        ),
      ),
    );
  }

  Widget _buildStatusCell(String? status) {
    String displayStatus = status ?? 'unknown';
    Color bgColor;

    switch (displayStatus) {
      case 'completed':
        bgColor = Colors.green;
        break;
      case 'pending':
        bgColor = Colors.yellow;
        break;
      case 'outForDelivery':
        bgColor = Colors.blue;
        break;
      default:
        bgColor = Colors.red;
    }

    return Container(
      color: bgColor,
      padding: const EdgeInsets.all(8.0),
      child: Text(
        displayStatus,
        textAlign: TextAlign.center,
        style: TextStyle(color: Colors.white),
      ),
    );
  }

  Widget _buildOverallStatusCell() {
    String overallStatus = _computeOverallStatus();

    Color bgColor;
    switch (overallStatus) {
      case 'completed':
        bgColor = Colors.green;
        break;
      case 'processing':
        bgColor = Colors.orange;
        break;
      default:
        bgColor = Colors.red;
    }

    return Container(
      color: bgColor,
      padding: const EdgeInsets.all(8.0),
      child: Text(
        overallStatus,
        textAlign: TextAlign.center,
        style: TextStyle(color: Colors.white),
      ),
    );
  }

  String _computeOverallStatus() {
    int completedCount = 0;

    if (task.invoiceSend == 'completed') completedCount++;
    if (task.packing == 'completed') completedCount++;
    if (task.dispatch == 'completed') completedCount++;
    if (task.delivery == 'completed') completedCount++;

    if (completedCount == 4) {
      return 'completed';
    } else if (completedCount > 0) {
      return 'processing';
    } else {
      return 'pending';
    }
  }
}