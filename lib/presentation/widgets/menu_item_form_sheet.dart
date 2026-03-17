import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:qlnh_app/data/models/menu_item_model.dart';
import 'package:qlnh_app/data/services/api_service.dart';

class MenuItemFormSheet extends StatefulWidget {
  final MenuItemModel? item;
  final VoidCallback onSuccess;

  const MenuItemFormSheet({super.key, this.item, required this.onSuccess});

  @override
  State<MenuItemFormSheet> createState() => _MenuItemFormSheetState();
}

class _MenuItemFormSheetState extends State<MenuItemFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _priceController;

  // --- THAY ĐỔI: Bỏ category controller và thêm biến cho dropdown ---
  String? _selectedCategory;
  File? _selectedImageFile;
  String? _networkImageUrl;
  bool _isLoading = false;

  // --- THAY ĐỔI: Định nghĩa danh sách các danh mục ---
  final List<String> _categories = [
    'Món chính',
    'Món khai vị',
    'Đồ uống',
    'Tráng miệng',
    'Món phụ',
  ];

  @override
  void initState() {
    super.initState();
    final isEditing = widget.item != null;
    _nameController = TextEditingController(text: isEditing ? widget.item!.name : '');
    _descriptionController = TextEditingController(text: isEditing ? widget.item!.description : '');
    _priceController = TextEditingController(text: isEditing ? widget.item!.price.toStringAsFixed(0) : '');
    _networkImageUrl = isEditing ? widget.item!.imageUrl : null;

    // --- THAY ĐỔI: Gán giá trị ban đầu cho dropdown ---
    if (isEditing) {
      _selectedCategory = widget.item!.category;
      // Đảm bảo danh mục của món ăn cũ có trong danh sách
      if (!_categories.contains(_selectedCategory)) {
        _categories.add(_selectedCategory!);
      }
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    final ImagePicker picker = ImagePicker();
    final XFile? pickedFile = await picker.pickImage(source: source, imageQuality: 80);
    if (pickedFile != null) {
      setState(() {
        _selectedImageFile = File(pickedFile.path);
      });
    }
  }

  void _showImageSourceActionSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: <Widget>[
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Chọn từ thư viện'),
              onTap: () {
                _pickImage(ImageSource.gallery);
                Navigator.of(ctx).pop();
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera),
              title: const Text('Chụp ảnh mới'),
              onTap: () {
                _pickImage(ImageSource.camera);
                Navigator.of(ctx).pop();
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      final apiService = context.read<ApiService>();
      String finalImageUrl = _networkImageUrl ?? '';
      bool isSuccess = false;

      try {
        if (_selectedImageFile != null) {
          finalImageUrl = await apiService.uploadImage(_selectedImageFile!);
        }

        final data = {
          'name': _nameController.text,
          'description': _descriptionController.text,
          'price': double.tryParse(_priceController.text) ?? 0,
          // --- THAY ĐỔI: Lấy giá trị từ dropdown ---
          'category': _selectedCategory,
          'imageUrl': finalImageUrl,
        };

        if (widget.item != null) {
          await apiService.updateMenuItem(widget.item!.id, data);
        } else {
          await apiService.createMenuItem(data);
        }

        isSuccess = true;

      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Đã xảy ra lỗi: $e'), backgroundColor: Colors.red));
        }
      } finally {
        if (mounted) {
          Navigator.of(context).pop();
          if (isSuccess) {
            widget.onSuccess();
          }
          setState(() => _isLoading = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.item != null;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.only(top: 24, left: 24, right: 24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(isEditing ? 'Sửa Món Ăn' : 'Thêm Món Ăn Mới', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 24),
              Center(
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 60,
                      backgroundColor: Colors.grey.shade200,
                      backgroundImage: _selectedImageFile != null
                          ? FileImage(_selectedImageFile!) as ImageProvider
                          : (_networkImageUrl != null && _networkImageUrl!.isNotEmpty
                          ? NetworkImage(_networkImageUrl!)
                          : null),
                      child: (_selectedImageFile == null && (_networkImageUrl == null || _networkImageUrl!.isEmpty))
                          ? Icon(Icons.fastfood_outlined, color: Colors.grey.shade800, size: 40)
                          : null,
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: IconButton.filled(
                        icon: const Icon(Icons.edit),
                        onPressed: () => _showImageSourceActionSheet(context),
                      ),
                    )
                  ],
                ),
              ),
              const SizedBox(height: 24),
              TextFormField(controller: _nameController, decoration: const InputDecoration(labelText: 'Tên món ăn*'), validator: (v) => v!.isEmpty ? 'Không được bỏ trống' : null),
              const SizedBox(height: 16),
              TextFormField(controller: _descriptionController, decoration: const InputDecoration(labelText: 'Mô tả')),
              const SizedBox(height: 16),
              TextFormField(controller: _priceController, decoration: const InputDecoration(labelText: 'Giá*'), keyboardType: TextInputType.number, validator: (v) => v!.isEmpty ? 'Không được bỏ trống' : null),
              const SizedBox(height: 16),

              // --- THAY ĐỔI: Thay thế TextFormField bằng DropdownButtonFormField ---
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                decoration: const InputDecoration(labelText: 'Danh mục*'),
                items: _categories.map((String category) {
                  return DropdownMenuItem<String>(
                    value: category,
                    child: Text(category),
                  );
                }).toList(),
                onChanged: (newValue) {
                  setState(() {
                    _selectedCategory = newValue;
                  });
                },
                validator: (value) => value == null ? 'Vui lòng chọn danh mục' : null,
              ),

              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                  onPressed: _isLoading ? null : _submitForm,
                  child: _isLoading ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3,)) : const Text('LƯU'),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}