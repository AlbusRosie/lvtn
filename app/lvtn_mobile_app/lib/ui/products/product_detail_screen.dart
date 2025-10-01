import 'package:flutter/material.dart';

class ProductDetailScreen extends StatelessWidget {
  final int productId;
  
  const ProductDetailScreen({super.key, required this.productId});

  static const String routeName = '/product-detail';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Chi tiết sản phẩm'),
      ),
      body: Center(
        child: Text('Chi tiết sản phẩm $productId - Đang phát triển'),
      ),
    );
  }
}
