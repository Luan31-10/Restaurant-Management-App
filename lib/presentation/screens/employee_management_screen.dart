import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/models/user_model.dart';
import '../../data/services/api_service.dart';

class EmployeeManagementScreen extends StatefulWidget {
  const EmployeeManagementScreen({super.key});

  @override
  State<EmployeeManagementScreen> createState() => EmployeeManagementScreenState();
}

class EmployeeManagementScreenState extends State<EmployeeManagementScreen> {
  late Future<List<UserModel>> _usersFuture;

  @override
  void initState() {
    super.initState();
    _reloadUsers();
  }

  void _reloadUsers() {
    if (mounted) {
      setState(() {
        _usersFuture = context.read<ApiService>().getUsers();
      });
    }
  }

  void _confirmDeleteUser(UserModel user) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xác nhận Xóa'),
        content: Text('Bạn có chắc chắn muốn xóa nhân viên "${user.name}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Hủy')),
          TextButton(
            onPressed: () async {
              try {
                await context.read<ApiService>().deleteUser(user.id);
                Navigator.of(ctx).pop();
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Xóa nhân viên thành công!'), backgroundColor: Colors.green));
                _reloadUsers();
              } catch (e) {
                Navigator.of(ctx).pop();
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi khi xóa: $e'), backgroundColor: Colors.red));
              }
            },
            child: const Text('Xóa', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void showUserFormSheet({UserModel? user}) {
    final isEditing = user != null;
    final nameController = TextEditingController(text: isEditing ? user.name : '');
    final pinController = TextEditingController();
    String currentRole = isEditing ? user.role : 'waitstaff';
    final formKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (dialogContext, setDialogState) {
          return SingleChildScrollView(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom,
              top: 24, left: 24, right: 24,
            ),
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(isEditing ? 'Sửa thông tin Nhân viên' : 'Thêm Nhân viên Mới', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 24),
                  TextFormField(
                    controller: nameController,
                    decoration: const InputDecoration(labelText: 'Tên nhân viên*', prefixIcon: Icon(Icons.person_outline)),
                    validator: (value) => value!.isEmpty ? 'Vui lòng nhập tên' : null,
                  ),
                  if (!isEditing)
                    Padding(
                      padding: const EdgeInsets.only(top: 16.0),
                      child: TextFormField(
                        controller: pinController,
                        decoration: const InputDecoration(labelText: 'Mã PIN* (4 chữ số)', prefixIcon: Icon(Icons.password)),
                        keyboardType: TextInputType.number,
                        obscureText: true,
                        maxLength: 4,
                        validator: (value) => value!.length != 4 ? 'Mã PIN phải có 4 chữ số' : null,
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsets.only(top: 16.0),
                    child: DropdownButtonFormField<String>(
                      value: currentRole,
                      decoration: const InputDecoration(labelText: 'Vai trò', prefixIcon: Icon(Icons.work_outline)),
                      items: ['waitstaff', 'kitchen', 'admin']
                          .map((role) => DropdownMenuItem(value: role, child: Text(role)))
                          .toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setDialogState(() => currentRole = value);
                        }
                      },
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                      onPressed: () async {
                        if (formKey.currentState!.validate()) {
                          try {
                            final apiService = context.read<ApiService>();
                            if (isEditing) {
                              await apiService.updateUser(user.id, nameController.text, currentRole);
                            } else {
                              await apiService.createUser(nameController.text, pinController.text, currentRole);
                            }
                            Navigator.of(ctx).pop();
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${isEditing ? 'Cập nhật' : 'Thêm'} thành công!'), backgroundColor: Colors.green));
                            _reloadUsers();
                          } catch (e) {
                            Navigator.of(ctx).pop();
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Đã xảy ra lỗi: $e'), backgroundColor: Colors.red));
                          }
                        }
                      },
                      child: const Text('LƯU'),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // --- THAY ĐỔI: Bọc toàn bộ bằng Scaffold ---
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý Nhân viên'),
      ),
      body: FutureBuilder<List<UserModel>>(
        future: _usersFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Lỗi: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Không có nhân viên nào.'));
          }
          final users = snapshot.data!;

          return ListView.builder(
            padding: const EdgeInsets.all(8.0), // Giảm padding
            itemCount: users.length,
            itemBuilder: (context, index) {
              final user = users[index];
              return _UserCard(
                user: user,
                onEdit: () => showUserFormSheet(user: user),
                onDelete: () => _confirmDeleteUser(user),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => showUserFormSheet(),
        child: const Icon(Icons.add),
      ),
    );
  }
}

// --- THAY ĐỔI: Thiết kế lại thẻ nhân viên ---
class _UserCard extends StatelessWidget {
  final UserModel user;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _UserCard({required this.user, required this.onEdit, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: ListTile(
          leading: CircleAvatar(
            child: Text(user.name.isNotEmpty ? user.name[0].toUpperCase() : '?'),
          ),
          title: Text(user.name, style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text('Vai trò: ${user.role}'),
          trailing: PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'edit') {
                onEdit();
              } else if (value == 'delete') {
                onDelete();
              }
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              const PopupMenuItem<String>(
                value: 'edit',
                child: ListTile(
                  leading: Icon(Icons.edit),
                  title: Text('Sửa'),
                ),
              ),
              const PopupMenuItem<String>(
                value: 'delete',
                child: ListTile(
                  leading: Icon(Icons.delete, color: Colors.red),
                  title: Text('Xóa', style: TextStyle(color: Colors.red)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}