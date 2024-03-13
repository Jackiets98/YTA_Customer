import 'dart:async';

import 'package:flutter/material.dart';

class RotatingLoadingWidget extends StatefulWidget {
  @override
  _RotatingLoadingWidgetState createState() => _RotatingLoadingWidgetState();
}

class _RotatingLoadingWidgetState extends State<RotatingLoadingWidget> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(seconds: 1),
    )..repeat();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.rotate(
          angle: _controller.value * 2 * 3.1415, // 2 * pi
          child: Icon(
            Icons.refresh, // You can replace this with any other circular loading icon
            size: 36,
            color: Colors.blue, // You can adjust the color as needed
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
