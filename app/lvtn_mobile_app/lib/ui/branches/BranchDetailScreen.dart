import 'package:flutter/material.dart';

class BranchDetailScreen extends StatelessWidget {
  final int branchId;
  
  const BranchDetailScreen({super.key, required this.branchId});

  static const String routeName = '/branch-detail';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Chi tiết chi nhánh'),
      ),
      body: Center(
        child: Text('Chi tiết chi nhánh $branchId - Đang phát triển'),
      ),
    );
  }
}
