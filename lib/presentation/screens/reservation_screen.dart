// presentation/screens/reservation_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:qlnh_app/data/models/reservation_model.dart';
import 'package:qlnh_app/data/models/table_model.dart';
import 'package:qlnh_app/data/services/api_service.dart';
import 'package:qlnh_app/logic/blocs/order_cart/order_cart_bloc.dart';
import 'package:qlnh_app/logic/blocs/tables/table_bloc.dart';
import 'package:qlnh_app/presentation/screens/order_creation_screen.dart';

class ReservationScreen extends StatefulWidget {
  const ReservationScreen({super.key});

  @override
  State<ReservationScreen> createState() => _ReservationScreenState();
}

class _ReservationScreenState extends State<ReservationScreen> {
  List<ReservationModel> _reservations = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _reloadReservations();
  }

  // Reload reservations list
  Future<void> _reloadReservations() async {
    if (mounted) {
      setState(() => _isLoading = true);
      // Fetch tables to ensure dropdown is up-to-date
      context.read<TableBloc>().add(FetchTables());
    }

    try {
      final items = await context.read<ApiService>().getReservations();
      // Sort items based on status priority and then time
      items.sort((a, b) {
        int getSortOrder(String status) {
          switch (status) {
            case 'pending': return 1;
            case 'confirmed': return 2;
            case 'arrived': return 3;
            default: return 4; // 'seated', 'cancelled', others
          }
        }
        int compare = getSortOrder(a.status).compareTo(getSortOrder(b.status));
        if (compare == 0) {
          // If statuses are same priority, sort by reservation time (earlier first)
          return a.reservationTime.compareTo(b.reservationTime);
        }
        return compare; // Otherwise, sort by status priority
      });

      if (mounted) {
        setState(() {
          _reservations = items;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Lỗi tải danh sách: $e'),
            backgroundColor: Colors.red
        ));
      }
    }
  }

  // Show bottom sheet form for adding or editing a reservation
  void _showAddReservationForm({ReservationModel? reservation}) {
    final bool _isEditMode = reservation != null;
    final formKey = GlobalKey<FormState>();

    // Pre-fill controllers if editing
    final nameController = TextEditingController(text: reservation?.customerName);
    final phoneController = TextEditingController(text: reservation?.phoneNumber);
    final guestsController = TextEditingController(text: reservation?.numberOfGuests.toString());
    final notesController = TextEditingController(text: reservation?.notes);

    DateTime? selectedDate = reservation?.reservationTime.toLocal();
    TimeOfDay? selectedTime = reservation != null ? TimeOfDay.fromDateTime(reservation.reservationTime.toLocal()) : null;

    // *** STORE INITIAL TABLE ID OUTSIDE STATEFUL BUILDER ***
    int? initialSelectedTableId;
    if (_isEditMode && reservation!.tableId != null) {
      initialSelectedTableId = reservation.tableId;
    }
    // *** selectedTable object will be managed inside StatefulBuilder ***

    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Allows sheet to resize with keyboard
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        // *** USE SEPARATE VARIABLE FOR STATEFUL BUILDER'S STATE ***
        int? currentSelectedTableId = initialSelectedTableId; // Initialize with initial ID
        TableModel? currentSelectedTableObject; // Will hold the full object when found

        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {

            // *** FIND currentSelectedTableObject BASED ON ID ON EACH BUILD ***
            final tableStateForBuilder = context.watch<TableBloc>().state; // Use watch for latest state
            List<TableModel> allTablesFromBloc = []; // Store all tables from current state
            if (tableStateForBuilder is TableLoaded) {
              allTablesFromBloc = tableStateForBuilder.tables;
              if (currentSelectedTableId != null) {
                try {
                  // Find the full object based on the current ID
                  currentSelectedTableObject = allTablesFromBloc.firstWhere((t) => t.id == currentSelectedTableId);
                } catch (e) {
                  currentSelectedTableObject = null; // Table might have been deleted
                  // Optionally reset ID if table is gone
                  // currentSelectedTableId = null;
                }
              } else {
                currentSelectedTableObject = null; // Reset if ID is null
              }
            } else {
              currentSelectedTableObject = null; // Reset if tables haven't loaded
            }


            return SingleChildScrollView(
              // Padding includes space for keyboard
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(dialogContext).viewInsets.bottom,
                top: 24, left: 24, right: 24,
              ),
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Form Title (dynamic)
                    Text(
                        _isEditMode ? 'Sửa Lịch Đặt Bàn' : 'Tạo Lượt Đặt Bàn Mới',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)
                    ),
                    const SizedBox(height: 24),
                    // Customer Name Input
                    TextFormField(
                      controller: nameController,
                      decoration: const InputDecoration(labelText: 'Tên khách hàng*', prefixIcon: Icon(Icons.person_outline)),
                      validator: (v) => v!.isEmpty ? 'Không được bỏ trống' : null,
                    ),
                    const SizedBox(height: 16),
                    // Phone Number Input
                    TextFormField(
                      controller: phoneController,
                      decoration: const InputDecoration(labelText: 'Số điện thoại*', prefixIcon: Icon(Icons.phone_outlined)),
                      keyboardType: TextInputType.phone,
                      validator: (v) => v!.isEmpty ? 'Không được bỏ trống' : null,
                    ),
                    const SizedBox(height: 16),
                    // Number of Guests Input
                    TextFormField(
                      controller: guestsController,
                      decoration: const InputDecoration(labelText: 'Số lượng khách*', prefixIcon: Icon(Icons.group_outlined)),
                      keyboardType: TextInputType.number,
                      validator: (v) => v!.isEmpty ? 'Không được bỏ trống' : null,
                      onChanged: (value) {
                        // Reset selected table when guest count changes
                        setDialogState(() {
                          currentSelectedTableId = null; // Reset ID
                          currentSelectedTableObject = null;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    // Date and Time Pickers Row
                    Row(
                      children: [
                        Expanded( // Date Picker Button
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.calendar_today_outlined, size: 18),
                            label: Text(selectedDate == null ? 'Chọn ngày*' : DateFormat('dd/MM/yyyy').format(selectedDate!)),
                            onPressed: () async {
                              final date = await showDatePicker(
                                context: context,
                                initialDate: selectedDate ?? DateTime.now(),
                                firstDate: DateTime.now().subtract(const Duration(days: 1)), // Allow selection from yesterday
                                lastDate: DateTime.now().add(const Duration(days: 365)), // Up to one year ahead
                              );
                              if (date != null) setDialogState(() => selectedDate = date);
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded( // Time Picker Button
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.access_time_outlined, size: 18),
                            label: Text(selectedTime == null ? 'Chọn giờ*' : selectedTime!.format(context)),
                            onPressed: () async {
                              final time = await showTimePicker(
                                  context: context,
                                  initialTime: selectedTime ?? TimeOfDay.now() // Use selected time or now
                              );
                              if (time != null) setDialogState(() => selectedTime = time);
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // === DROPDOWN ĐÃ SỬA LOGIC LỌC ===
                    BlocBuilder<TableBloc, TableState>(
                      builder: (context, tableState) {
                        if (tableState is TableLoaded) {
                          final int guestCount = int.tryParse(guestsController.text) ?? 0;
                          final List<TableModel> currentTablesFromBloc = allTablesFromBloc; // Lấy danh sách gốc

                          // Lọc bàn available và đủ sức chứa
                          List<TableModel> filteredTables = currentTablesFromBloc.where((t) {
                            bool isAvailable = t.status == 'available';
                            bool hasCapacity = guestCount > 0 ? t.capacity >= guestCount : true;
                            return isAvailable && hasCapacity;
                          }).toList();

                          // Nếu đang sửa VÀ bàn đang chọn đủ sức chứa VÀ nó chưa có trong list -> thêm vào
                          if (_isEditMode &&
                              currentSelectedTableId != null &&
                              !filteredTables.any((t) => t.id == currentSelectedTableId))
                          {
                            try {
                              // Tìm bàn đang chọn trong danh sách gốc
                              final currentTable = currentTablesFromBloc.firstWhere((t)=> t.id == currentSelectedTableId);
                              // Chỉ thêm nếu nó đủ sức chứa
                              if (guestCount == 0 || currentTable.capacity >= guestCount) {
                                filteredTables.add(currentTable);
                              }
                            } catch(e) { /* Bỏ qua nếu bàn bị xoá */ }
                          }

                          // Sắp xếp lại (ưu tiên bàn đang chọn lên đầu, sau đó theo sức chứa)
                          filteredTables.sort((a, b) {
                            if (a.id == currentSelectedTableId) return -1;
                            if (b.id == currentSelectedTableId) return 1;
                            return a.capacity.compareTo(b.capacity);
                          });

                          // Bỏ đoạn kiểm tra an toàn cũ (vì logic mới đã xử lý)
                          // if (currentSelectedTableId != null && !filteredTables.any(...)) { ... }

                          return DropdownButtonFormField<int?>( // Dùng int? (ID)
                            hint: const Text('Chọn bàn (tùy chọn)'),
                            decoration: const InputDecoration(prefixIcon: Icon(Icons.table_restaurant_outlined)),
                            value: currentSelectedTableId, // Value là ID
                            isExpanded: true,
                            items: filteredTables.map((table) { // Dùng filteredTables đã sửa
                              return DropdownMenuItem<int?>( // Dùng int?
                                  value: table.id, // Value là ID
                                  // Hiển thị thêm status nếu không phải 'available'
                                  child: Text('${table.number} (${table.capacity} khách)${table.status != 'available' ? ' (${table.status})': ''}')
                              );
                            }).toList(),
                            onChanged: (tableId) { // Nhận về ID
                              setDialogState(() {
                                currentSelectedTableId = tableId; // Cập nhật ID
                                // Tìm object tương ứng sẽ được thực hiện ở đầu builder
                              });
                            },
                          );
                        }
                        // Fallback khi đang load
                        return const Padding(padding: EdgeInsets.all(8.0), child: Text('Đang tải danh sách bàn...'));
                      },
                    ),
                    // ===================================
                    const SizedBox(height: 16),
                    // Notes Input
                    TextFormField(
                      controller: notesController,
                      decoration: const InputDecoration(labelText: 'Ghi chú', prefixIcon: Icon(Icons.note_alt_outlined)),
                      maxLines: 2, // Allow multiple lines for notes
                    ),
                    const SizedBox(height: 24),
                    // Save Button
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                        onPressed: () async {
                          // Validation
                          if (formKey.currentState!.validate() && selectedDate != null && selectedTime != null) {
                            final reservationDateTime = DateTime(
                                selectedDate!.year, selectedDate!.month, selectedDate!.day,
                                selectedTime!.hour, selectedTime!.minute
                            );

                            // *** GỬI ID ĐÃ LƯU TRONG currentSelectedTableId ***
                            final data = {
                              'customerName': nameController.text,
                              'phoneNumber': phoneController.text,
                              'numberOfGuests': int.parse(guestsController.text),
                              'reservationTime': reservationDateTime.toIso8601String(),
                              'notes': notesController.text.isNotEmpty ? notesController.text : null,
                              'tableId': currentSelectedTableId, // Gửi ID đi
                            };

                            try {
                              // Call API based on mode
                              if (_isEditMode) {
                                await context.read<ApiService>().updateReservation(reservation!.id.toString(), data);
                              } else {
                                await context.read<ApiService>().createReservation(data);
                              }
                              Navigator.of(ctx).pop(); // Close sheet
                              _reloadReservations(); // Refresh list
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                  content: Text(_isEditMode ? 'Cập nhật thành công!' : 'Tạo đặt bàn thành công!'),
                                  backgroundColor: Colors.green
                              ));
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red));
                            }
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vui lòng điền đủ thông tin bắt buộc (*)'), backgroundColor: Colors.orange));
                          }
                        },
                        // Dynamic button text
                        child: Text(
                            _isEditMode ? 'LƯU THAY ĐỔI' : 'LƯU ĐẶT BÀN',
                            style: const TextStyle(fontWeight: FontWeight.bold)
                        ),
                      ),
                    ),
                    const SizedBox(height: 16), // Bottom padding
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }


  // (Function _updateStatus remains the same)
  Future<void> _updateStatus(ReservationModel reservation, String status) async {
    try {
      await context.read<ApiService>().updateReservationStatus(reservation.id.toString(), status);
      _reloadReservations();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cập nhật thành công!'), backgroundColor: Colors.green));
    } catch(e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red));
    }
  }

  // (Function _confirmDelete remains the same)
  void _confirmDelete(ReservationModel reservation) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: Text('Bạn có chắc chắn muốn xóa lịch đặt của "${reservation.customerName}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Hủy')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Xóa'),
            onPressed: () async {
              Navigator.of(ctx).pop();
              try {
                await context.read<ApiService>().deleteReservation(reservation.id.toString());
                _reloadReservations();
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã xóa thành công!'), backgroundColor: Colors.green));
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red));
              }
            },
          ),
        ],
      ),
    );
  }

  // (Function _confirmSeating remains the same)
  void _confirmSeating(ReservationModel reservation) {
    final tableState = context.read<TableBloc>().state;
    TableModel? targetTable;
    if (tableState is TableLoaded && reservation.tableNumber != null) {
      try {
        targetTable = tableState.tables.firstWhere((t) => t.number == reservation.tableNumber);
      } catch (e) {
        targetTable = null;
      }
    }

    if (targetTable == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Không tìm thấy bàn đã đặt hoặc bàn không còn trống.'), backgroundColor: Colors.red));
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xác nhận Xếp bàn'),
        content: Text('Xếp khách "${reservation.customerName}" vào ${targetTable!.number}?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Hủy')),
          FilledButton(
            child: const Text('Xác nhận'),
            onPressed: () async {
              Navigator.of(ctx).pop();
              try {
                await context.read<ApiService>().seatCustomer(reservation.id.toString());
                context.read<TableBloc>().add(FetchTables()); // Refresh tables after seating
                Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) =>
                    BlocProvider(
                      create: (context) => OrderCartBloc(apiService: context.read<ApiService>()),
                      child: OrderCreationScreen(table: targetTable!),
                    )
                ));
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red));
              }
            },
          ),
        ],
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lịch đặt bàn'),
      ),
      body: RefreshIndicator(
        onRefresh: _reloadReservations, // Allows pull-to-refresh
        child: _isLoading && _reservations.isEmpty
            ? const Center(child: CircularProgressIndicator()) // Show loading initially or when empty during load
            : _reservations.isEmpty
            ? const Center(child: Text('Chưa có lượt đặt bàn nào.')) // Show message if list is empty
        // Use ListView.builder for efficiency
            : ListView.builder(
          padding: const EdgeInsets.only(bottom: 80), // Padding to avoid FAB overlap
          itemCount: _reservations.length,
          itemBuilder: (context, index) {
            final reservation = _reservations[index];
            final status = reservation.status;

            // Determine card color, status color, and display text based on status
            Color cardColor;
            Color statusColor;
            String statusText;

            switch(status) {
              case 'pending':
                cardColor = Colors.orange.shade50; statusColor = Colors.orange.shade800; statusText = 'Đang chờ'; break;
              case 'confirmed':
                cardColor = Colors.white; statusColor = Colors.blue.shade800; statusText = 'Đã xác nhận'; break;
              case 'arrived':
                cardColor = Colors.lightBlue.shade50; statusColor = Colors.lightBlue.shade800; statusText = 'Đã đến'; break;
              case 'seated':
                cardColor = Colors.green.shade100; statusColor = Colors.green.shade800; statusText = 'Đã xếp bàn'; break;
              case 'cancelled':
                cardColor = Colors.red.shade100; statusColor = Colors.red.shade800; statusText = 'Đã hủy'; break;
              default: // Fallback for unknown statuses
                cardColor = Colors.grey.shade100; statusColor = Colors.grey.shade800; statusText = status.toUpperCase();
            }

            // Build the Card for each reservation item
            return Card(
              color: cardColor,
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: ListTile(
                // Leading avatar showing guest count
                leading: CircleAvatar(
                    backgroundColor: statusColor.withOpacity(0.2),
                    child: Text(
                      reservation.numberOfGuests.toString(),
                      style: TextStyle(fontWeight: FontWeight.bold, color: statusColor),
                    )
                ),
                // Title showing customer name
                title: Text(reservation.customerName, style: const TextStyle(fontWeight: FontWeight.bold)),
                // Subtitle showing time, phone, and table
                subtitle: Text(
                    '${DateFormat('HH:mm - dd/MM/yyyy').format(reservation.reservationTime.toLocal())}\nSĐT: ${reservation.phoneNumber} - Bàn: ${reservation.tableNumber ?? 'Chưa xếp'}'
                ),
                isThreeLine: true,
                // onTap to confirm seating only if status is 'arrived' and table is assigned
                onTap: (status == 'arrived' && reservation.tableNumber != null)
                    ? () => _confirmSeating(reservation)
                    : null,

                // Trailing popup menu for actions
                trailing: PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'edit') {
                      _showAddReservationForm(reservation: reservation); // Open edit form
                    } else if (value == 'delete') {
                      _confirmDelete(reservation); // Show delete confirmation
                    } else if (value.isNotEmpty) {
                      _updateStatus(reservation, value); // Update status action
                    }
                  },
                  itemBuilder: (BuildContext context) {
                    List<PopupMenuEntry<String>> menuItems = [];

                    // Add status update actions based on the current status
                    if (status == 'pending') {
                      menuItems.add(const PopupMenuItem<String>( value: 'confirmed', child: ListTile(leading: Icon(Icons.check_circle_outline, color: Colors.green), title: Text('Xác nhận')),));
                      menuItems.add(const PopupMenuItem<String>( value: 'cancelled', child: ListTile(leading: Icon(Icons.cancel_outlined, color: Colors.red), title: Text('Hủy')),));
                    }
                    else if (status == 'confirmed') {
                      menuItems.add(const PopupMenuItem<String>( value: 'arrived', child: ListTile(leading: Icon(Icons.check_circle_outline, color: Colors.blue), title: Text('Đã đến')),));
                      menuItems.add(const PopupMenuItem<String>( value: 'cancelled', child: ListTile(leading: Icon(Icons.cancel_outlined, color: Colors.red), title: Text('Hủy (Không đến)')),));
                    }
                    else { // For 'arrived', 'seated', 'cancelled' - show info only
                      menuItems.add(PopupMenuItem<String>( enabled: false, child: ListTile(leading: Icon(Icons.info_outline), title: Text(statusText)),));
                    }

                    // Add management actions (Edit, Delete)
                    menuItems.add(const PopupMenuDivider());
                    menuItems.add(const PopupMenuItem<String>( value: 'edit', child: ListTile(leading: Icon(Icons.edit_outlined), title: Text('Sửa thông tin')),));
                    // Allow deletion only if the customer hasn't been seated yet
                    if (status != 'seated') {
                      menuItems.add(const PopupMenuItem<String>( value: 'delete', child: ListTile(leading: Icon(Icons.delete_outline, color: Colors.red), title: Text('Xóa')),));
                    }

                    return menuItems;
                  },
                ),
              ),
            );
          },
        ),
      ),
      // Floating Action Button to add a new reservation
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddReservationForm, // Calls the form without pre-filled data
        tooltip: 'Tạo Lịch Đặt Bàn Mới',
        child: const Icon(Icons.add),
      ),
    );
  }
}