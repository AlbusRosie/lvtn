import 'package:flutter/material.dart';

class TablesScreen extends StatelessWidget {
  const TablesScreen({super.key});

  static const String routeName = '/tables';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Đặt bàn'),
      ),
      body: Center(
        child: Text('Đặt bàn - Đang phát triển'),
      ),
    );
  }
}
