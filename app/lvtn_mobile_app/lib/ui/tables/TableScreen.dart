import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/branch.dart';
import '../../services/TableService.dart';
import '../../services/FloorService.dart';
import '../../services/ReservationService.dart';
import '../cart/CartProvider.dart';
import '../cart/CartScreen.dart';
import '../widgets/AppBottomNav.dart';

class TableScreen extends StatefulWidget {
  final Branch branch;
  final String? prefilledDate;
  final String? prefilledTime;
  final int? prefilledGuestCount;
  final String? prefilledNote;

  const TableScreen({
    super.key, 
    required this.branch,
    this.prefilledDate,
    this.prefilledTime,
    this.prefilledGuestCount,
    this.prefilledNote,
  });

  static const String routeName = '/tables';

  @override
  State<TableScreen> createState() => _TableScreenState();
}

class _TableScreenState extends State<TableScreen> {
  final TableService _tableService = TableService();
  final FloorService _floorService = FloorService();
  List<Map<String, dynamic>> _allTables = [];
  List<Map<String, dynamic>> _filteredTables = [];
  String _statusFilter = 'all';
  String _search = '';
  int? _minCapacity;
  bool _isLoading = true;
  String? _error;


  List<Map<String, dynamic>> _floors = [];
  int? _selectedFloorId; // null means all floors

  @override
  void initState() {
    super.initState();
    _fetchInitial();
  }

  Future<void> _fetchInitial() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final tables = await _tableService.getTablesByBranch(widget.branch.id);
      final normalized = tables.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      _allTables = normalized.where((t) => (t['branch_id'] ?? t['branchId']) == widget.branch.id).toList();

      final floors = await _floorService.getFloorsByBranch(widget.branch.id);
      _floors = floors.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    } catch (e) {
      _error = e.toString();
    }
    _applyFilters();
    if (mounted) setState(() { _isLoading = false; });
  }

  void _applyFilters() {
    List<Map<String, dynamic>> result = List.from(_allTables);
    if (_selectedFloorId != null) {
      result = result.where((t) => (t['floor_id'] ?? t['floorId']) == _selectedFloorId).toList();
    }
    if (_statusFilter != 'all') {
      result = result.where((t) => (t['status'] ?? '').toString() == _statusFilter).toList();
    }
    if (_minCapacity != null) {
      result = result.where((t) => (t['capacity'] ?? 0) >= _minCapacity!).toList();
    }
    if (_search.isNotEmpty) {
      result = result.where((t) => (t['table_number'] ?? '').toString().toLowerCase().contains(_search.toLowerCase())).toList();
    }
    _filteredTables = result;
    if (mounted) setState(() {});
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'available':
        return Colors.green;
      case 'occupied':
        return Colors.red;
      case 'reserved':
        return Colors.orange;
      case 'maintenance':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'available':
        return Icons.check_circle;
      case 'occupied':
        return Icons.cancel;
      case 'reserved':
        return Icons.access_time;
      case 'maintenance':
        return Icons.build;
      default:
        return Icons.help;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Reserve Table',
          style: TextStyle(
            color: Colors.grey[900],
            fontSize: 18,
            fontWeight: FontWeight.bold,
            fontFamily: 'Inter',
          ),
        ),
        foregroundColor: Colors.grey[900],
        centerTitle: true,
        actions: [
          Consumer<CartProvider>(
            builder: (context, cartProvider, child) {
              return Padding(
                padding: EdgeInsets.only(right: 16, top: 8, bottom: 8),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    GestureDetector(
                      onTap: () => _showCartBottomSheet(cartProvider),
                      child: Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: Color(0xFF2C2C2C),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.shopping_bag_outlined, color: Colors.white, size: 24),
                      ),
                    ),
                    if (cartProvider.itemCount > 0)
                      Positioned(
                        right: 0,
                        top: 0,
                        child: Container(
                          padding: EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.orange,
                            shape: BoxShape.circle,
                          ),
                          constraints: BoxConstraints(
                            minWidth: 20,
                            minHeight: 20,
                          ),
                          child: Text(
                            '${cartProvider.itemCount}',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [

            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.08),
                    blurRadius: 12,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFFFF9800), Color(0xFFFF6F00)],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(color: Colors.orange.withOpacity(0.3), blurRadius: 8, offset: Offset(0, 3)),
                      ],
                    ),
                    child: Icon(Icons.restaurant, color: Colors.white, size: 24),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.branch.name,
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey[900], fontFamily: 'Inter'),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 2),
                        Text(
                          '${_filteredTables.length} tables available',
                          style: TextStyle(fontSize: 13, color: Colors.grey[600], fontFamily: 'Inter'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            if (_isLoading)
              Expanded(child: Center(child: CircularProgressIndicator(color: Colors.orange)))
            else if (_error != null)
              Expanded(child: Center(child: Text('Could not load table list')))
            else if (_allTables.isEmpty)
              Expanded(child: Center(child: Text('No tables available')))
            else
              Expanded(
                child: Column(
                  children: [

                    Container(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [

                          Row(
                            children: [
                              Expanded(
                                flex: 3,
                                child: Container(
                                  height: 50,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(color: Colors.grey[200]!),
                                    boxShadow: [
                                      BoxShadow(color: Colors.grey.withOpacity(0.05), blurRadius: 10, offset: Offset(0, 2)),
                                    ],
                                  ),
                                  child: TextField(
                                    decoration: InputDecoration(
                                      hintText: 'Search table number...',
                                      hintStyle: TextStyle(color: Colors.grey[400], fontFamily: 'Inter', fontSize: 12),
                                      prefixIcon: Icon(Icons.search, color: Colors.orange, size: 18),
                                      border: InputBorder.none,
                                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                    ),
                                    style: TextStyle(fontSize: 12, color: Colors.grey[900], fontFamily: 'Inter'),
                                    onChanged: (v) { _search = v; _applyFilters(); },
                                  ),
                                ),
                              ),
                              SizedBox(width: 10),
                              Expanded(
                                flex: 2,
                                child: Container(
                                  height: 44,
                                  padding: EdgeInsets.symmetric(horizontal: 12),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: Colors.grey[200]!),
                                  ),
                                  child: DropdownButtonHideUnderline(
                                    child: DropdownButton<int?>(
                                      value: _selectedFloorId,
                                      isExpanded: true,
                                      icon: Icon(Icons.arrow_drop_down, color: Colors.orange),
                                      style: TextStyle(fontSize: 12, color: Colors.grey[900], fontFamily: 'Inter'),
                                      items: [
                                        DropdownMenuItem<int?>(value: null, child: Text('All Floors', style: TextStyle(fontSize: 12))),
                                        ..._floors.map((f) => DropdownMenuItem<int?>(
                                          value: f['id'] as int,
                                          child: Text(
                                            f['name']?.toString() ?? 'Floor ${f['floor_number'] ?? ''}',
                                            style: TextStyle(fontSize: 12),
                                          ),
                                        )),
                                      ],
                                      onChanged: (v) { setState(() { _selectedFloorId = v; }); _applyFilters(); },
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 10),

                          Row(
                            children: [
                              Expanded(
                                flex: 1,
                                child: Container(
                                  height: 44,
                                  padding: EdgeInsets.symmetric(horizontal: 12),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: Colors.grey[200]!),
                                  ),
                                  child: DropdownButtonHideUnderline(
                                    child: DropdownButton<String>(
                                      value: _statusFilter,
                                      isExpanded: true,
                                      icon: Icon(Icons.arrow_drop_down, color: Colors.orange),
                                      style: TextStyle(fontSize: 12, color: Colors.grey[900], fontFamily: 'Inter'),
                                      items: const [
                                        DropdownMenuItem(value: 'all', child: Text('All', style: TextStyle(fontSize: 12))),
                                        DropdownMenuItem(value: 'available', child: Text('Available', style: TextStyle(fontSize: 12))),
                                        DropdownMenuItem(value: 'occupied', child: Text('Occupied', style: TextStyle(fontSize: 12))),
                                        DropdownMenuItem(value: 'reserved', child: Text('Reserved', style: TextStyle(fontSize: 12))),
                                        DropdownMenuItem(value: 'maintenance', child: Text('Maintenance', style: TextStyle(fontSize: 12))),
                                      ],
                                      onChanged: (v) { setState(() { _statusFilter = v ?? 'all'; }); _applyFilters(); },
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(width: 10),
                              Expanded(
                                flex: 2,
                                child: Container(
                                  height: 44,
                                  padding: EdgeInsets.symmetric(horizontal: 12),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: Colors.grey[200]!),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(Icons.people_outline, size: 18, color: Colors.orange),
                                      SizedBox(width: 6),
                                      Expanded(
                                        child: TextField(
                                          decoration: InputDecoration(
                                            hintText: 'Min',
                                            hintStyle: TextStyle(fontSize: 12, color: Colors.grey[400]),
                                            border: InputBorder.none,
                                            contentPadding: EdgeInsets.zero,
                                            isDense: true,
                                          ),
                                          keyboardType: TextInputType.number,
                                          style: TextStyle(fontSize: 12),
                                          onChanged: (v) { _minCapacity = int.tryParse(v); _applyFilters(); },
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    Expanded(
                      child: _filteredTables.isEmpty
                          ? Center(child: Text('No table found matching your criteria'))
                          : GridView.builder(
                              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                crossAxisSpacing: 12,
                                mainAxisSpacing: 12,
                                childAspectRatio: 1.4,
                              ),
                              itemCount: _filteredTables.length,
                              itemBuilder: (context, index) {
                                final t = _filteredTables[index] as Map<String, dynamic>;
                                final status = (t['status'] ?? 'available').toString();
                                final statusColor = _getStatusColor(status);
                                final statusIcon = _getStatusIcon(status);
                                return _TableCard(
                                  table: t,
                                  status: status,
                                  statusColor: statusColor,
                                  statusIcon: statusIcon,
                                  onTap: () {
                                    if (status.toLowerCase() != 'available') {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text('This table is not available'),
                                          backgroundColor: Colors.red,
                                        ),
                                      );
                                      return;
                                    }
                                    _openReservationSheet(t);
                                  },
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
      bottomNavigationBar: AppBottomNav(
        currentIndex: 1,
      ),
    );
  }

  void _openReservationSheet(Map<String, dynamic> table) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        DateTime? selectedDate;
        TimeOfDay? selectedTime;
        List<Map<String, dynamic>> tableSchedule = [];
        bool isLoadingSchedule = false;
        String selectedDateFilter = 'week'; // today, tomorrow, week
        return StatefulBuilder(
          builder: (context, setSheetState) {
            Future<void> doLoadSchedule() async {
              setSheetState(() => isLoadingSchedule = true);
              
              try {

                final today = DateTime.now();
                List<DateTime> datesToShow = [];
                
                switch (selectedDateFilter) {
                  case 'today':
                    datesToShow = [today];
                    break;
                  case 'tomorrow':
                    datesToShow = [today.add(Duration(days: 1))];
                    break;
                  case 'week':
                    for (int i = 0; i < 7; i++) {
                      datesToShow.add(today.add(Duration(days: i)));
                    }
                    break;
                  case 'nextWeek':
                    for (int i = 7; i < 14; i++) {
                      datesToShow.add(today.add(Duration(days: i)));
                    }
                    break;
                }
                

                final startDate = datesToShow.first;
                final endDate = datesToShow.last;
                final reservations = await ReservationService.getReservationsByDateRange(
                  startDate: '${startDate.year}-${startDate.month.toString().padLeft(2,'0')}-${startDate.day.toString().padLeft(2,'0')}',
                  endDate: '${endDate.year}-${endDate.month.toString().padLeft(2,'0')}-${endDate.day.toString().padLeft(2,'0')}',
                );
                
                for (var r in reservations) {
                }
                

                final tableReservations = reservations.where((reservation) {
                  final tableId = table['id'];
                  final reservationTableId = reservation['table_id'];
                  

                  final tableIdInt = tableId is int ? tableId : int.tryParse(tableId.toString());
                  final reservationTableIdInt = reservationTableId is int ? reservationTableId : int.tryParse(reservationTableId.toString());
                  
                  final isMatch = tableIdInt == reservationTableIdInt;
                  if (isMatch) {
                  }
                  
                  return isMatch;
                }).toList();
                
                

                final timeSlots = ReservationService.generateTimeSlots();
                

                tableSchedule = [];
                for (final date in datesToShow) {
                  final dateStr = '${date.year}-${date.month.toString().padLeft(2,'0')}-${date.day.toString().padLeft(2,'0')}';
                  

                  final mergedSlots = ReservationService.mergeTimeSlots(
                    timeSlots: timeSlots,
                    reservations: tableReservations,
                    date: dateStr,
                  );
                  

                  for (final slot in mergedSlots) {
                    tableSchedule.add({
                      'date': dateStr,
                      'time': slot['time'],
                      'status': slot['status'],
                      'start': slot['start'],
                      'end': slot['end'],
                    });
                  }
                }
                
                setSheetState(() {
                  isLoadingSchedule = false;
                });
                
              } catch (e) {
                setSheetState(() {
                  isLoadingSchedule = false;
                });
              }
            }


            List<Map<String, dynamic>> getMergedTimeSlotsForDate(String dateStr) {

              final daySlots = tableSchedule.where((slot) => slot['date'] == dateStr).toList();
              return daySlots;
            }


            if (tableSchedule.isEmpty && !isLoadingSchedule) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                doLoadSchedule();
              });
            }

            Future<void> pickDate() async {
              final now = DateTime.now();
              final DateTime? d = await showDatePicker(
                context: context,
                initialDate: now,
                firstDate: now,
                lastDate: now.add(Duration(days: 60)),
                helpText: 'Select reservation date',
                builder: (context, child) {
                  return Theme(
                    data: Theme.of(context).copyWith(
                      colorScheme: ColorScheme.light(
                        primary: Colors.orange,
                        onPrimary: Colors.white,
                        surface: Colors.white,
                        onSurface: Colors.grey[800]!,
                        secondary: Colors.orange.shade100,
                        onSecondary: Colors.orange.shade800,
                      ),
                      textTheme: Theme.of(context).textTheme.copyWith(
                        headlineSmall: TextStyle(
                          color: Colors.grey[800],
                          fontWeight: FontWeight.w700,
                          fontSize: 20,
                        ),
                        bodyLarge: TextStyle(
                          color: Colors.grey[700],
                          fontWeight: FontWeight.w500,
                        ),
                        bodyMedium: TextStyle(
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      dialogBackgroundColor: Colors.white,
                      dialogTheme: DialogThemeData(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        elevation: 8,
                      ),
                    ),
                    child: child!,
                  );
                },
              );
              if (d != null) setSheetState(() => selectedDate = d);
            }
            Future<void> pickTime() async {
              final TimeOfDay? t = await showTimePicker(
                context: context,
                initialTime: TimeOfDay.now(),
                helpText: 'Select reservation time',
                builder: (context, child) {
                  return Theme(
                    data: Theme.of(context).copyWith(
                      colorScheme: ColorScheme.light(
                        primary: Colors.orange,
                        onPrimary: Colors.white,
                        surface: Colors.white,
                        onSurface: Colors.grey[800]!,
                        secondary: Colors.orange.shade100,
                        onSecondary: Colors.orange.shade800,
                      ),
                      textTheme: Theme.of(context).textTheme.copyWith(
                        headlineSmall: TextStyle(
                          color: Colors.grey[800],
                          fontWeight: FontWeight.w700,
                          fontSize: 20,
                        ),
                        bodyLarge: TextStyle(
                          color: Colors.grey[700],
                          fontWeight: FontWeight.w500,
                        ),
                        bodyMedium: TextStyle(
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      dialogBackgroundColor: Colors.white,
                      dialogTheme: DialogThemeData(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        elevation: 8,
                      ),
                    ),
                    child: child!,
                  );
                },
              );
              if (t != null) setSheetState(() => selectedTime = t);
            }

            void confirm() async {
              if (selectedDate == null || selectedTime == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Please select date and time')),
                );
                return;
              }
              

              setSheetState(() {
                isLoadingSchedule = true;
              });
              
              try {
                final reservationDate = '${selectedDate!.year}-${selectedDate!.month.toString().padLeft(2,'0')}-${selectedDate!.day.toString().padLeft(2,'0')}';
                final reservationTime = '${selectedTime!.hour.toString().padLeft(2,'0')}:${selectedTime!.minute.toString().padLeft(2,'0')}:00';
                

                final reservation = await ReservationService.createReservation(
                  userId: 2, // TODO: Lấy từ user hiện tại
                  branchId: widget.branch.id,
                  tableId: table['id'],
                  reservationDate: reservationDate,
                  reservationTime: reservationTime,
                  guestCount: table['capacity'] ?? 2,
                  specialRequests: 'Đặt bàn qua app',
                );
                
                if (reservation != null) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Đặt bàn thành công! Bàn ${table['table_number']} • ${reservationDate} ${selectedTime!.format(context)}'),
                      backgroundColor: Colors.green,
                      duration: Duration(seconds: 3),
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Đặt bàn thất bại. Vui lòng thử lại.'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Có lỗi xảy ra. Vui lòng thử lại.'),
                    backgroundColor: Colors.red,
                  ),
                );
              } finally {
                setSheetState(() {
                  isLoadingSchedule = false;
                });
              }
            }

            return Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
                        ),
                      ),
                      SizedBox(height: 12),
                      Text('Reserve Table ${table['table_number']}', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                      SizedBox(height: 12),

                      Row(
                        children: [
                          Text('View:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.grey[700])),
                          SizedBox(width: 8),
                          Expanded(
                            child: Container(
                              height: 32,
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: selectedDateFilter,
                                  isExpanded: true,
                                  icon: Icon(Icons.arrow_drop_down, size: 16),
                                  style: TextStyle(fontSize: 12, color: Colors.grey[900]),
                                  items: const [
                                    DropdownMenuItem(value: 'today', child: Text('Today')),
                                    DropdownMenuItem(value: 'tomorrow', child: Text('Tomorrow')),
                                    DropdownMenuItem(value: 'week', child: Text('This Week')),
                                    DropdownMenuItem(value: 'nextWeek', child: Text('Next Week')),
                                  ],
                                  onChanged: (v) {
                                    setSheetState(() {
                                      selectedDateFilter = v ?? 'week';

                                      doLoadSchedule();
                                    });
                                  },
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      if (isLoadingSchedule)
                        Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator(color: Colors.orange)))
                      else if (tableSchedule.isNotEmpty) ...[
                        Text('Table Schedule', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.grey[800])),
                        SizedBox(height: 8),
                        Container(
                          height: 300,
                          padding: EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey[200]!),
                          ),
                          child: Column(
                            children: [

                              Expanded(
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [

                                    Container(
                                      width: 60,
                                      child: Column(
                                        children: List.generate(8, (index) {
                                          final hour = 7 + (index * 2);
                                          return Expanded(
                                            child: Center(
                                              child: Text(
                                                '${hour.toString().padLeft(2,'0')}:00',
                                                style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                                              ),
                                            ),
                                          );
                                        }),
                                      ),
                                    ),
                                    SizedBox(width: 8),

                                    Expanded(
                                      child: Column(
                                        children: [

                                          Container(
                                            height: 20,
                                            child: Row(
                                              children: selectedDateFilter == 'week' 
                                                ? List.generate(7, (dayIndex) {
                                                    final date = DateTime.now().add(Duration(days: dayIndex));
                                                    return Expanded(
                                                      child: Center(
                                                        child: Text(
                                                          '${date.day}/${date.month}',
                                                          style: TextStyle(fontSize: 9, color: Colors.grey[600], fontWeight: FontWeight.w500),
                                                        ),
                                                      ),
                                                    );
                                                  })
                                                : selectedDateFilter == 'nextWeek'
                                                  ? List.generate(7, (dayIndex) {
                                                      final date = DateTime.now().add(Duration(days: dayIndex + 7));
                                                      return Expanded(
                                                        child: Center(
                                                          child: Text(
                                                            '${date.day}/${date.month}',
                                                            style: TextStyle(fontSize: 9, color: Colors.grey[600], fontWeight: FontWeight.w500),
                                                          ),
                                                        ),
                                                      );
                                                  })
                                                : [
                                                    Expanded(
                                                      child: Center(
                                                        child: Text(
                                                          selectedDateFilter == 'today' ? 'Today' : 'Tomorrow',
                                                          style: TextStyle(fontSize: 9, color: Colors.grey[600]),
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                            ),
                                          ),
                                          SizedBox(height: 4),

                                          Expanded(
                                            child: Row(
                                              children: selectedDateFilter == 'week' 
                                                ? List.generate(7, (dayIndex) {
                                                    return Expanded(
                                                      child: Column(
                                                        children: getMergedTimeSlotsForDate('${DateTime.now().add(Duration(days: dayIndex)).year}-${DateTime.now().add(Duration(days: dayIndex)).month.toString().padLeft(2,'0')}-${DateTime.now().add(Duration(days: dayIndex)).day.toString().padLeft(2,'0')}').map((slot) {
                                                          final isReserved = slot['status'] == 'reserved';
                                                          
                                                          return Expanded(
                                                            child: Container(
                                                              margin: EdgeInsets.all(1),
                                                              decoration: BoxDecoration(
                                                                color: isReserved ? Colors.red.withOpacity(0.7) : Colors.green.withOpacity(0.3),
                                                                borderRadius: BorderRadius.circular(2),
                                                                border: Border.all(color: Colors.grey[300]!, width: 0.5),
                                                              ),
                                                              child: Center(
                                                                child: Icon(
                                                                  isReserved ? Icons.event_busy : Icons.event_available,
                                                                  size: 8,
                                                                  color: isReserved ? Colors.white : Colors.green[700],
                                                                ),
                                                              ),
                                                            ),
                                                          );
                                                        }).toList(),
                                                      ),
                                                    );
                                                  })
                                                : selectedDateFilter == 'nextWeek'
                                                  ? List.generate(7, (dayIndex) {
                                                      return Expanded(
                                                        child: Column(
                                                        children: getMergedTimeSlotsForDate('${DateTime.now().add(Duration(days: dayIndex + 7)).year}-${DateTime.now().add(Duration(days: dayIndex + 7)).month.toString().padLeft(2,'0')}-${DateTime.now().add(Duration(days: dayIndex + 7)).day.toString().padLeft(2,'0')}').map((slot) {
                                                          final isReserved = slot['status'] == 'reserved';
                                                            
                                                            return Expanded(
                                                              child: Container(
                                                                margin: EdgeInsets.all(1),
                                                                decoration: BoxDecoration(
                                                                  color: isReserved ? Colors.red.withOpacity(0.7) : Colors.green.withOpacity(0.3),
                                                                  borderRadius: BorderRadius.circular(2),
                                                                  border: Border.all(color: Colors.grey[300]!, width: 0.5),
                                                                ),
                                                                child: Center(
                                                                  child: Icon(
                                                                    isReserved ? Icons.event_busy : Icons.event_available,
                                                                    size: 8,
                                                                    color: isReserved ? Colors.white : Colors.green[700],
                                                                  ),
                                                                ),
                                                              ),
                                                            );
                                                          }).toList(),
                                                        ),
                                                      );
                                                    })
                                                  : [

                                                        Expanded(
                                                          child: Column(
                                                        children: getMergedTimeSlotsForDate('${DateTime.now().add(Duration(days: selectedDateFilter == 'tomorrow' ? 1 : 0)).year}-${DateTime.now().add(Duration(days: selectedDateFilter == 'tomorrow' ? 1 : 0)).month.toString().padLeft(2,'0')}-${DateTime.now().add(Duration(days: selectedDateFilter == 'tomorrow' ? 1 : 0)).day.toString().padLeft(2,'0')}').map((slot) {
                                                          final isReserved = slot['status'] == 'reserved';
                                                              
                                                              return Expanded(
                                                                child: Container(
                                                                  margin: EdgeInsets.all(1),
                                                                  decoration: BoxDecoration(
                                                                    color: isReserved ? Colors.red.withOpacity(0.7) : Colors.green.withOpacity(0.3),
                                                                    borderRadius: BorderRadius.circular(2),
                                                                    border: Border.all(color: Colors.grey[300]!, width: 0.5),
                                                                  ),
                                                                  child: Center(
                                                                    child: Icon(
                                                                      isReserved ? Icons.event_busy : Icons.event_available,
                                                                      size: 12,
                                                                      color: isReserved ? Colors.white : Colors.green[700],
                                                                    ),
                                                                  ),
                                                                ),
                                                              );
                                                            }).toList(),
                                                          ),
                                                        ),
                                                      ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(height: 8),

                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Row(
                                    children: [
                                      Container(width: 12, height: 12, decoration: BoxDecoration(color: Colors.green.withOpacity(0.3), borderRadius: BorderRadius.circular(2))),
                                      SizedBox(width: 4),
                                      Text('Available', style: TextStyle(fontSize: 10, color: Colors.grey[600])),
                                    ],
                                  ),
                                  SizedBox(width: 16),
                                  Row(
                                    children: [
                                      Container(width: 12, height: 12, decoration: BoxDecoration(color: Colors.red.withOpacity(0.7), borderRadius: BorderRadius.circular(2))),
                                      SizedBox(width: 4),
                                      Text('Reserved', style: TextStyle(fontSize: 10, color: Colors.grey[600])),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 12),
                      ],
                      Row(
                        children: [
                          Expanded(
                            child: _buildDateTimeButton(
                              icon: Icons.event,
                              label: selectedDate == null ? 'Pick Date' : '${selectedDate!.year}-${selectedDate!.month.toString().padLeft(2,'0')}-${selectedDate!.day.toString().padLeft(2,'0')}',
                              onTap: pickDate,
                            ),
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: _buildDateTimeButton(
                              icon: Icons.access_time,
                              label: selectedTime == null ? 'Pick Time' : selectedTime!.format(context),
                              onTap: pickTime,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        height: 44,
                        child: ElevatedButton(
                          onPressed: confirm,
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), elevation: 0),
                          child: Text('Confirm', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  String _getStatusText(String status) {
    switch (status.toLowerCase()) {
      case 'available':
        return 'Available';
      case 'occupied':
        return 'Occupied';
      case 'reserved':
        return 'Reserved';
      case 'maintenance':
        return 'Maintenance';
      default:
        return status;
    }
  }

  Widget _buildDateTimeButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 16, horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.orange.shade200, width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: Colors.orange.shade700,
                  size: 18,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.grey[800],
                    letterSpacing: 0.5,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showCartBottomSheet(CartProvider cartProvider) {
    final currentBranchId = cartProvider.currentBranchId ?? widget.branch.id;
    final currentBranchName = cartProvider.currentBranchName ?? widget.branch.name;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.9,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: CartScreen(
            branchId: currentBranchId,
            branchName: currentBranchName,
          ),
        );
      },
    );
  }
}

class _TableCard extends StatelessWidget {
  final Map<String, dynamic> table;
  final String status;
  final Color statusColor;
  final IconData statusIcon;
  final VoidCallback onTap;

  const _TableCard({
    required this.table,
    required this.status,
    required this.statusColor,
    required this.statusIcon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 10, offset: Offset(0, 4), spreadRadius: -2),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(Icons.event_seat, color: Colors.orange, size: 22),
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Table ${table['table_number']?.toString() ?? '-'}',
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.grey[900], fontFamily: 'Inter'),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: 4),
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(color: statusColor.withOpacity(0.12), borderRadius: BorderRadius.circular(6)),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(statusIcon, size: 12, color: statusColor),
                                SizedBox(width: 4),
                                Text(
                                  _statusText(status),
                                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: statusColor, fontFamily: 'Inter'),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.people_outline, size: 14, color: Colors.grey[500]),
                    SizedBox(width: 4),
                    Text('${table['capacity'] ?? '-'} people', style: TextStyle(fontSize: 12, color: Colors.grey[600], fontFamily: 'Inter')),
                  ],
                ),
                if ((table['location'] ?? '').toString().isNotEmpty) ...[
                  SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.location_on_outlined, size: 14, color: Colors.grey[500]),
                      SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          (table['location'] ?? '').toString(),
                          style: TextStyle(fontSize: 12, color: Colors.grey[600], fontFamily: 'Inter'),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _statusText(String status) {
    switch (status.toLowerCase()) {
      case 'available':
        return 'available';
      case 'occupied':
        return 'Reserved';
      case 'reserved':
        return 'Reserved';
      case 'maintenance':
        return 'Maintenance';
      default:
        return status;
    }
  }
}
