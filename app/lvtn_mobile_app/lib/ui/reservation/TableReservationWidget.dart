import 'package:flutter/material.dart';
import '../../models/cart.dart';
import '../../services/CartService.dart';
import '../../services/AuthService.dart';

class TableReservationWidget extends StatefulWidget {
  final Cart cart;
  final Function(Cart) onReservationUpdated;

  const TableReservationWidget({
    Key? key,
    required this.cart,
    required this.onReservationUpdated,
  }) : super(key: key);

  @override
  State<TableReservationWidget> createState() => _TableReservationWidgetState();
}

class _TableReservationWidgetState extends State<TableReservationWidget> {
  final _formKey = GlobalKey<FormState>();
  final _tableController = TextEditingController();
  final _guestController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();

  @override
  void initState() {
    super.initState();
    if (widget.cart.hasTableReservation) {
      _tableController.text = widget.cart.tableIdDisplay?.toString() ?? '';
      _guestController.text = widget.cart.guestCount?.toString() ?? '';
      if (widget.cart.reservationDate != null) {
        _selectedDate = DateTime.parse(widget.cart.reservationDate!);
      }
      if (widget.cart.reservationTime != null) {
        final timeParts = widget.cart.reservationTime!.split(':');
        _selectedTime = TimeOfDay(
          hour: int.parse(timeParts[0]),
          minute: int.parse(timeParts[1]),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.all(16),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.table_restaurant, color: Colors.orange),
                  SizedBox(width: 8),
                  Text(
                    'Table Reservation',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              
              SizedBox(height: 16),
              

              TextFormField(
                controller: _tableController,
                decoration: InputDecoration(
                  labelText: 'Table Number',
                  hintText: 'Enter table number',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.table_restaurant),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter table number';
                  }
                  return null;
                },
              ),
              
              SizedBox(height: 16),
              

              TextFormField(
                controller: _guestController,
                decoration: InputDecoration(
                  labelText: 'Number of Guests',
                  hintText: 'Enter number of guests',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.people),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter number of guests';
                  }
                  final count = int.tryParse(value);
                  if (count == null || count <= 0) {
                    return 'Please enter a valid number';
                  }
                  return null;
                },
              ),
              
              SizedBox(height: 16),
              

              Row(
                children: [
                  Expanded(
                    child: ListTile(
                      leading: Icon(Icons.calendar_today),
                      title: Text('Date'),
                      subtitle: Text('${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}'),
                      onTap: _selectDate,
                    ),
                  ),
                  
                  SizedBox(width: 16),
                  
                  Expanded(
                    child: ListTile(
                      leading: Icon(Icons.access_time),
                      title: Text('Time'),
                      subtitle: Text(_selectedTime.format(context)),
                      onTap: _selectTime,
                    ),
                  ),
                ],
              ),
              
              SizedBox(height: 24),
              

              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: widget.cart.hasTableReservation ? _cancelReservation : _makeReservation,
                      icon: Icon(widget.cart.hasTableReservation ? Icons.cancel : Icons.check),
                      label: Text(widget.cart.hasTableReservation ? 'Cancel Reservation' : 'Make Reservation'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: widget.cart.hasTableReservation ? Colors.red : Colors.green,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(Duration(days: 30)),
    );
    
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _selectTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    
    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  Future<void> _makeReservation() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      final token = AuthService().token;
      if (token == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Please log in to make reservation')),
        );
        return;
      }

      final tableId = int.parse(_tableController.text);
      final guestCount = int.parse(_guestController.text);
      final reservationDate = '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}';
      final reservationTime = '${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}';

      final updatedCart = await CartService.reserveTable(
        token: token,
        cartId: widget.cart.id,
        tableId: tableId,
        reservationDate: reservationDate,
        reservationTime: reservationTime,
        guestCount: guestCount,
      );

      widget.onReservationUpdated(updatedCart);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Table reserved successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to reserve table: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _cancelReservation() async {
    try {
      final token = AuthService().token;
      if (token == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Please log in to cancel reservation')),
        );
        return;
      }

      final updatedCart = await CartService.cancelTableReservation(
        token: token,
        cartId: widget.cart.id,
      );

      widget.onReservationUpdated(updatedCart);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Reservation cancelled successfully!'),
          backgroundColor: Colors.orange,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to cancel reservation: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  void dispose() {
    _tableController.dispose();
    _guestController.dispose();
    super.dispose();
  }
}
