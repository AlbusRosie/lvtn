import 'package:flutter/material.dart';
import '../models/table.dart' as models;

class TableCard extends StatelessWidget {
  final models.Table table;
  final VoidCallback? onTap;

  const TableCard({
    super.key,
    required this.table,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Color statusColor;
    IconData statusIcon;
    
    switch (table.status) {
      case 'available':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      case 'occupied':
        statusColor = Colors.red;
        statusIcon = Icons.person;
        break;
      case 'reserved':
        statusColor = Colors.orange;
        statusIcon = Icons.schedule;
        break;
      case 'maintenance':
        statusColor = Colors.grey;
        statusIcon = Icons.build;
        break;
      default:
        statusColor = Colors.grey;
        statusIcon = Icons.help;
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: onTap != null ? null : Colors.grey.shade100,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Table Icon
              Icon(
                Icons.table_restaurant,
                size: 48,
                color: onTap != null ? statusColor : Colors.grey,
              ),
              const SizedBox(height: 8),
              
              // Table Number
              Text(
                'Bàn ${table.tableNumber}',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: onTap != null ? null : Colors.grey,
                ),
              ),
              const SizedBox(height: 4),
              
              // Capacity
              Text(
                '${table.capacity} người',
                style: TextStyle(
                  fontSize: 14,
                  color: onTap != null ? Colors.grey.shade600 : Colors.grey,
                ),
              ),
              const SizedBox(height: 8),
              
              // Status
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    statusIcon,
                    size: 16,
                    color: statusColor,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    table.statusText,
                    style: TextStyle(
                      fontSize: 12,
                      color: statusColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              
              // Location
              if (table.location != null) ...[
                const SizedBox(height: 4),
                Text(
                  table.location!,
                  style: TextStyle(
                    fontSize: 10,
                    color: onTap != null ? Colors.grey.shade500 : Colors.grey,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
