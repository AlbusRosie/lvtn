import 'package:flutter/material.dart';
import '../../models/cart.dart';
import '../../models/table.dart';
import '../../services/TableService.dart';

class TableReservationWidget extends StatefulWidget {
  final Cart cart;
  final Function({
    required int tableId,
    required String reservationDate,
    required String reservationTime,
    required int guestCount,
  }) onReserveTable;
  final VoidCallback onCancelReservation;

  const TableReservationWidget({
    Key? key,
    required this.cart,
    required this.onReserveTable,
    required this.onCancelReservation,
  }) : super(key: key);

  @override
  State<TableReservationWidget> createState() => _TableReservationWidgetState();
}

class _TableReservationWidgetState extends State<TableReservationWidget> {
  List<Table> _availableTables = [];
  bool _isLoadingTables = false;
  int? _selectedTableId;
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();
  int _guestCount = 2;

  @override
  void initState() {
    super.initState();
    _loadAvailableTables();
  }

  Future<void> _loadAvailableTables() async {
    setState(() {
      _isLoadingTables = true;
    });

    try {
      final tables = await TableService.getAvailableTables(widget.cart.branchId);
      setState(() {
        _availableTables = tables;
        if (tables.isNotEmpty && _selectedTableId == null) {
          _selectedTableId = tables.first.id;
        }
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading tables: $e')),
        );
      }
    } finally {
      setState(() {
        _isLoadingTables = false;
      });
    }
  }

  Future<void> _selectDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (date != null) {
      setState(() {
        _selectedDate = date;
      });
    }
  }

  Future<void> _selectTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (time != null) {
      setState(() {
        _selectedTime = time;
      });
    }
  }

  void _reserveTable() {
    if (_selectedTableId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a table')),
      );
      return;
    }

    final reservationDate = _selectedDate.toIso8601String().split('T')[0];
    final reservationTime = '${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}';

    widget.onReserveTable(
      tableId: _selectedTableId!,
      reservationDate: reservationDate,
      reservationTime: reservationTime,
      guestCount: _guestCount,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.table_restaurant, color: Colors.orange),
              const SizedBox(width: 8),
              Text(
                'Table Reservation',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          if (widget.cart.hasTableReservation) ...[
            // Show current reservation
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green[50],
                border: Border.all(color: Colors.green[200]!),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.green[600], size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Table Reserved',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.green[700],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text('Table: ${widget.cart.tableNumber}'),
                  Text('Date: ${widget.cart.reservationDate}'),
                  Text('Time: ${widget.cart.reservationTime}'),
                  Text('Guests: ${widget.cart.guestCount}'),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: widget.onCancelReservation,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red[400],
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Cancel Reservation'),
                  ),
                ],
              ),
            ),
          ] else ...[
            // Show reservation form
            Column(
              children: [
                // Date selection
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Date'),
                          const SizedBox(height: 4),
                          InkWell(
                            onTap: _selectDate,
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey[300]!),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.calendar_today, size: 20, color: Colors.grey[600]),
                                  const SizedBox(width: 8),
                                  Text(
                                    '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Time'),
                          const SizedBox(height: 4),
                          InkWell(
                            onTap: _selectTime,
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey[300]!),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.access_time, size: 20, color: Colors.grey[600]),
                                  const SizedBox(width: 8),
                                  Text(_selectedTime.format(context)),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Guest count
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Number of Guests'),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.remove_circle_outline),
                          onPressed: _guestCount > 1 ? () => setState(() => _guestCount--) : null,
                          color: Colors.orange,
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey[300]!),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '$_guestCount',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add_circle_outline),
                          onPressed: () => setState(() => _guestCount++),
                          color: Colors.orange,
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Table selection
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Select Table'),
                    const SizedBox(height: 4),
                    if (_isLoadingTables)
                      const Center(child: CircularProgressIndicator())
                    else if (_availableTables.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.red[50],
                          border: Border.all(color: Colors.red[200]!),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text('No tables available'),
                      )
                    else
                      Container(
                        height: 120,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: _availableTables.length,
                          itemBuilder: (context, index) {
                            final table = _availableTables[index];
                            final isSelected = _selectedTableId == table.id;
                            return GestureDetector(
                              onTap: () => setState(() => _selectedTableId = table.id),
                              child: Container(
                                width: 80,
                                margin: const EdgeInsets.only(right: 8),
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: isSelected ? Colors.orange : Colors.grey[100],
                                  border: Border.all(
                                    color: isSelected ? Colors.orange : Colors.grey[300]!,
                                    width: isSelected ? 2 : 1,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.table_restaurant,
                                      color: isSelected ? Colors.white : Colors.grey[600],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      table.tableNumber,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: isSelected ? Colors.white : Colors.black,
                                      ),
                                    ),
                                    Text(
                                      '${table.capacity} seats',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: isSelected ? Colors.white : Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 16),

                // Reserve button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _reserveTable,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('Reserve Table'),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
