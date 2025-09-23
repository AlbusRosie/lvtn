import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/table_provider.dart';
import '../../models/table.dart' as models;
import '../../widgets/table_card.dart';

class ReservationScreen extends StatefulWidget {
  const ReservationScreen({super.key});

  @override
  State<ReservationScreen> createState() => _ReservationScreenState();
}

class _ReservationScreenState extends State<ReservationScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TableProvider>().loadTables();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Đặt bàn'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
      ),
      body: Consumer<TableProvider>(
        builder: (context, tableProvider, child) {
          if (tableProvider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (tableProvider.tables.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.table_restaurant,
                    size: 64,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Không có bàn nào',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            );
          }

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Chọn bàn để đặt',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                
                // Table status legend
                Row(
                  children: [
                    _buildStatusIndicator(Colors.green, 'Có sẵn'),
                    const SizedBox(width: 16),
                    _buildStatusIndicator(Colors.red, 'Đang sử dụng'),
                    const SizedBox(width: 16),
                    _buildStatusIndicator(Colors.orange, 'Đã đặt'),
                    const SizedBox(width: 16),
                    _buildStatusIndicator(Colors.grey, 'Bảo trì'),
                  ],
                ),
                const SizedBox(height: 24),
                
                // Tables grid
                Expanded(
                  child: GridView.builder(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 1.2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                    ),
                    itemCount: tableProvider.tables.length,
                    itemBuilder: (context, index) {
                      final table = tableProvider.tables[index];
                      return TableCard(
                        table: table,
                        onTap: table.isAvailable
                            ? () {
                                _showReservationDialog(table);
                              }
                            : null,
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatusIndicator(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 12),
        ),
      ],
    );
  }

  void _showReservationDialog(models.Table table) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Đặt bàn ${table.tableNumber}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Sức chứa: ${table.capacity} người'),
            if (table.location != null) Text('Vị trí: ${table.location}'),
            const SizedBox(height: 16),
            const Text('Tính năng đặt bàn sẽ được phát triển trong phiên bản tiếp theo.'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }
}
