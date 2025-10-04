import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/product.dart';
import '../../models/branch.dart';
import '../../providers/CategoryProvider.dart';

class ProductDetailScreen extends StatefulWidget {
  static const String routeName = '/product-detail';

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  String _getImageUrl(String? imagePath) {
    if (imagePath == null || imagePath.isEmpty) {
      return 'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=800&auto=format&fit=crop';
    }
    if (imagePath.startsWith('http')) {
      return imagePath;
    }
    if (imagePath.startsWith('/public')) {
      return 'http://10.0.2.2:3000$imagePath';
    }
    return 'http://10.0.2.2:3000/public/uploads/$imagePath';
  }

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    final Product product = args['product'];
    final Branch branch = args['branch'];

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: Column(
          children: [
            Container(
              height: MediaQuery.of(context).size.height * 0.5,
              child: Stack(
                children: [
                   Container(
                     height: MediaQuery.of(context).size.height * 0.32,
                    decoration: BoxDecoration(
                       gradient: LinearGradient(
                         begin: Alignment.topCenter,
                         end: Alignment.bottomCenter,
                         colors: [
                           Colors.orange,
                           Colors.orange.shade400,
                         ],
                      ),
                       borderRadius: BorderRadius.only(
                         bottomLeft: Radius.circular(150),
                         bottomRight: Radius.circular(150),
                       ),
                    ),
                  ),

                  Positioned(
                    top: 16,
                    left: 16,
                    right: 16,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.3),
                            shape: BoxShape.circle,
                          ),
                          child: IconButton(
                            icon: Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
                            padding: EdgeInsets.zero,
                            onPressed: () => Navigator.pop(context),
                          ),
                        ),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.white.withOpacity(0.3)),
                          ),
                          child: Consumer<CategoryProvider>(
                            builder: (context, categoryProvider, child) {
                              String categoryName = 'Category';
                              try {
                                final category = categoryProvider.categories
                                    .firstWhere((cat) => cat.id == product.categoryId);
                                categoryName = category.name;
                              } catch (e) {
                                categoryName = 'Category';
                              }
                              
                              return Text(
                                categoryName,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                  fontFamily: 'Inter',
                                ),
                              );
                            },
                          ),
                        ),
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.3),
                            shape: BoxShape.circle,
                          ),
                          child: IconButton(
                            icon: Icon(Icons.shopping_cart_outlined, color: Colors.white, size: 22),
                            padding: EdgeInsets.zero,
                            onPressed: () {},
                          ),
                        ),
                      ],
                    ),
                  ),


                   Positioned(
                     bottom: -40,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                           Container(
                             width: 450,
                             height: 450,
                             decoration: BoxDecoration(
                               shape: BoxShape.circle,
                               gradient: RadialGradient(
                                 colors: [
                                   Colors.orange.shade100.withOpacity(0.4),
                                   Colors.orange.shade50.withOpacity(0.2),
                                   Colors.transparent,
                                 ],
                               ),
                             ),
                           ),
                           Container(
                             width: 400,
                             height: 400,
                             decoration: BoxDecoration(
                               shape: BoxShape.circle,
                               gradient: RadialGradient(
                                 colors: [
                                   Colors.orange.shade100.withOpacity(0.3),
                                   Colors.orange.shade50.withOpacity(0.1),
                                   Colors.transparent,
                                 ],
                               ),
                             ),
                           ),
                          Container(
                            width: 300,
                            height: 300,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                          ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(160),
                              child: Image.network(
                                _getImageUrl(product.image),
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    color: Colors.grey[200],
                                    child: Icon(Icons.food_bank, size: 80, color: Colors.grey),
                                  );
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

             Expanded(
               child: Padding(
                 padding: EdgeInsets.symmetric(horizontal: 24),
                 child: Column(
                   children: [
                     SizedBox(height: 24),

                    Text(
                      product.name,
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
                        fontFamily: 'Inter',
                      ),
                      textAlign: TextAlign.center,
                    ),

                    SizedBox(height: 8),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Large',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                            fontFamily: 'Inter',
                          ),
                        ),
                        SizedBox(width: 8),
                        Text(
                          '|',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[400],
                          ),
                        ),
                        SizedBox(width: 8),
                        Text(
                          product.formattedPrice,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[800],
                            fontFamily: 'Inter',
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: 12),

                    Text(
                      product.description ?? 'Tomato, Mozzarella, Green basil, Olives, Bell pepper',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                        fontFamily: 'Inter',
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    SizedBox(height: 24),

                    Container(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                               content: Text('Added ${product.name} to cart'),
                               backgroundColor: Colors.orange,
                              duration: Duration(seconds: 2),
                            ),
                          );
                        },
                         style: ElevatedButton.styleFrom(
                           backgroundColor: Colors.orange,
                           shape: RoundedRectangleBorder(
                             borderRadius: BorderRadius.circular(28),
                           ),
                           elevation: 0,
                         ),
                        child: Text(
                          'Add to cart',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                            fontFamily: 'Inter',
                          ),
                        ),
                      ),
                    ),

                     SizedBox(height: 16),

                     Container(
                       child: Column(
                         children: [
                           Row(
                             mainAxisAlignment: MainAxisAlignment.center,
                             children: [
                               _buildRelatedProductCard('Chicken', product.image),
                               SizedBox(width: 16),
                               _buildRelatedProductCard('Framhouse', product.image),
                               SizedBox(width: 16),
                               _buildRelatedProductCard('Tomato', product.image),
                             ],
                           ),
                         ],
                       ),
                     ),
                     
                     SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRelatedProductCard(String name, String? image) {
    return Container(
      width: 100,
      child: Column(
        children: [
          Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.orange, width: 3),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(45),
              child: Image.network(
                _getImageUrl(image),
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Colors.grey[200],
                    child: Icon(Icons.food_bank, size: 40, color: Colors.grey),
                  );
                },
              ),
            ),
          ),
          SizedBox(height: 8),
          Text(
            name,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
              fontFamily: 'Inter',
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}