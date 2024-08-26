import 'package:flutter/material.dart';

import 'package:mjworkmanagement/screens/login_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';


class RoleScreen extends StatelessWidget {
  final String role;

  RoleScreen({required this.role});

  Future<void> _logout(BuildContext context) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('role');
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
            onPressed: () => _logout(context),
            icon: Icon(Icons.logout),
          ),
        ],
        title: Text('$role Dashboard'),
        backgroundColor: Colors.blueAccent,
      ),
      body: Center(
        child: Text('Welcome, $role!'),
      ),
    );
  }
}
