import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/task.dart';

class TaskDetailsPage extends StatefulWidget {
  final Task task;

  const TaskDetailsPage({Key? key, required this.task}) : super(key: key);

  @override
  State<TaskDetailsPage> createState() => _TaskDetailsPageState();
}

class _TaskDetailsPageState extends State<TaskDetailsPage> {
  String userName = '';

  @override
  void initState() {
    super.initState();
    fetchUserName();
  }

  Future<void> fetchUserName() async {
    if (widget.task.completedBy != null) {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.task.completedBy)
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
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text(widget.task.taskName ?? 'Task Details',style: TextStyle(fontSize: 20,fontWeight: FontWeight.w600),),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            _buildDetailRow('Assigned To', widget.task.assignedTo),
            _buildDetailRow('Completed By', userName),
            _buildDetailRow('Invoice Send Status', widget.task.invoiceSend),
            _buildDetailRow('Packing Status', widget.task.packing),
            _buildDetailRow('Dispatch Status', widget.task.dispatch),
            _buildDetailRow('Delivery Status', widget.task.delivery),
            _buildDetailRow('Timestamp', widget.task.timestamp.toString()),

            const SizedBox(height: 16),
            _buildImagesSection('Invoice Images', widget.task.images),
            const SizedBox(height: 16),
            _buildSingleImageSection('Delivered Image', widget.task.deliveredImage),
            const SizedBox(height: 16),
            _buildImagesSection('Dispatch Images', widget.task.dispatchImage),

            const SizedBox(height: 16),
            _buildAudioSection('Voice Message', widget.task.voiceMessageUrl),
            _buildAudioSection('Dispatch Audio', widget.task.dispatchAudio),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          Expanded(
            child: Text(
              value ?? 'N/A',
              style: TextStyle(color: Colors.black),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImagesSection(String label, List<String>? imageUrls) {
    if (imageUrls == null || imageUrls.isEmpty) {
      return _buildDetailRow(label, 'No images');
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$label:',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8.0,
          runSpacing: 8.0,
          children: imageUrls.map((url) {
            return GestureDetector(
              onTap: () {
                // Implement image full screen view
              },
              child: Image.network(
                url,
                height: 100,
                width: 100,
                fit: BoxFit.cover,
                loadingBuilder: (BuildContext context, Widget child,
                    ImageChunkEvent? loadingProgress) {
                  if (loadingProgress == null) return child;
                  return SizedBox(
                    height: 100,
                    width: 100,
                    child: Center(
                      child: CircularProgressIndicator(
                        value: loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded /
                            loadingProgress.expectedTotalBytes!
                            : null,
                      ),
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: 100,
                    width: 100,
                    color: Colors.grey[200],
                    child: Icon(Icons.broken_image, color: Colors.grey),
                  );
                },
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildSingleImageSection(String label, String? imageUrl) {
    if (imageUrl == null) {
      return _buildDetailRow(label, 'No image');
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$label:',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () {
            // Implement full screen image view logic
          },
          child: Image.network(
            imageUrl,
            height: 150,
            width: double.infinity,
            fit: BoxFit.cover,
            loadingBuilder: (BuildContext context, Widget child,
                ImageChunkEvent? loadingProgress) {
              if (loadingProgress == null) return child;
              return SizedBox(
                height: 150,
                child: Center(
                  child: CircularProgressIndicator(
                    value: loadingProgress.expectedTotalBytes != null
                        ? loadingProgress.cumulativeBytesLoaded /
                        loadingProgress.expectedTotalBytes!
                        : null,
                  ),
                ),
              );
            },
            errorBuilder: (context, error, stackTrace) {
              return Container(
                height: 150,
                color: Colors.grey[200],
                child: Icon(Icons.broken_image, color: Colors.grey),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildAudioSection(String label, String? audioUrl) {
    if (audioUrl == null) {
      return _buildDetailRow(label, 'No audio');
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$label:',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        IconButton(
          icon: Icon(Icons.play_arrow),
          onPressed: () {
            // Implement audio playback logic here
          },
        ),
      ],
    );
  }
}

