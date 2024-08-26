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
          borderRadius: BorderRadius.circular(20),
          color: Colors.grey[200],
          boxShadow: [
            BoxShadow(
                offset: Offset(8, 8),
                color: Colors.grey,blurRadius: 30
            ),
            BoxShadow(
                offset: Offset(-8, -8),
                color: Colors.white,blurRadius: 30
            )
          ]
      ),
      child: widget,
    );
  }
}
