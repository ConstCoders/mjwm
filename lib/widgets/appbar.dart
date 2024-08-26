import 'package:flutter/material.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  @override
  Size get preferredSize => Size.fromHeight(80.0); // Set your desired height here

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text('Custom AppBar'),
      centerTitle: true,
      backgroundColor: Colors.blueAccent,
      flexibleSpace: Container(
        height: preferredSize.height,
        child: Center(
          child: Text(
            'Custom AppBar Title',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }
}