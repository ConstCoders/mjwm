import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import '../models/task.dart';

class TaskDetailsScreen extends StatelessWidget {
  final Task task;
  final AudioPlayer audioPlayer = AudioPlayer();

  TaskDetailsScreen({required this.task});

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
              Text('Task ID: ${task.id}', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              SizedBox(height: 10),
              _buildStatusDetail('Assigned To:', task.assignedTo),
              _buildStatusDetail('Completed By:', task.completedBy),
              _buildStatusDetail('Invoice Sent:', task.invoiceSend),
              _buildStatusDetail('Packing:', task.packing),
              _buildStatusDetail('Dispatch:', task.dispatch),
              _buildStatusDetail('Delivery:', task.delivery),
              SizedBox(height: 20),
              Text('Timestamp: ${task.timestamp}', style: TextStyle(color: Colors.grey)),
              SizedBox(height: 20),
              if (task.invoiceImage.isNotEmpty)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Invoice Image:', style: TextStyle(fontWeight: FontWeight.bold)),
                    SizedBox(height: 10),
                    Image.network(task.invoiceImage),
                    SizedBox(height: 20),
                  ],
                ),
              if (task.deliveryImage.isNotEmpty)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Delivery Image:', style: TextStyle(fontWeight: FontWeight.bold)),
                    SizedBox(height: 10),
                    Image.network(task.deliveryImage),
                    SizedBox(height: 20),
                  ],
                ),
              if (task.voiceMessageUrl.isNotEmpty)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Voice Message:', style: TextStyle(fontWeight: FontWeight.bold)),
                    SizedBox(height: 10),
                    IconButton(
                      icon: Icon(Icons.play_arrow),
                      onPressed: () async {
                        await audioPlayer.play(UrlSource(task.voiceMessageUrl));
                      },
                    ),
                    SizedBox(height: 20),
                  ],
                ),
              // Add other fields as necessary
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusDetail(String label, String? status) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Text(label, style: TextStyle(fontWeight: FontWeight.bold)),
          SizedBox(width: 10),
          Text(status ?? 'N/A'),
        ],
      ),
    );
  }
}
