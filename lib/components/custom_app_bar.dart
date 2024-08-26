import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../screens/login_screen.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final bool showLogoutButton;

  CustomAppBar({required this.title, this.showLogoutButton = true});

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
    return AppBar(
      actions: showLogoutButton
          ? [
        IconButton(
          onPressed: () => _logout(context),
          icon: Icon(Icons.logout),
        ),
      ]
          : null,
      title: Text(title),
      backgroundColor: Colors.blueAccent,
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(kToolbarHeight);
}
