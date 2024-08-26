import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';



class UserListPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Users'),
      ),
      body: StreamBuilder(
        stream: FirebaseFirestore.instance.collection('users').snapshots(),
        builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }

          var documents = snapshot.data!.docs;
          var users = documents.map((doc) {
            var data = doc.data() as Map<String, dynamic>;
            return User.fromMap(doc.id, data);
          }).toList();

          return ListView.builder(
            itemCount: users.length,
            itemBuilder: (context, index) {
              var user = users[index];
              return ListTile(
                title: Text(user.name),
                subtitle: Text(user.role),
              );
            },
          );
        },
      ),
    );
  }
}
class User {
  String id;
  String name;
  String role;

  User({required this.id, required this.name, required this.role});

  factory User.fromMap(String id, Map<String, dynamic> data) {
    return User(
      id: id,
      name: data['username'] ?? 'Unknown',
      role: data['role'] ?? 'Unknown',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'role': role,
    };
  }
}
