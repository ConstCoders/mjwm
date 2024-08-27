import 'dart:ffi';

import 'package:flutter/material.dart';

class NeuMo extends StatelessWidget {
  const NeuMo({super.key, required this.widget, required this.height, this.width});
  final Widget widget;
  final double? height;
  final double? width;

  @override
  Widget build(BuildContext context) {
    return Container(

      height: height ,width: width,

      decoration: BoxDecoration(
        color: Color(0xFFE0E5EC),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade600,
            offset: Offset(10, 10),
            blurRadius: 20,
          ),
          BoxShadow(
            color: Colors.white,
            offset: Offset(-10, -10),
            blurRadius: 20,
          ),
        ],
      ),
      child: widget,
    );
  }
}
