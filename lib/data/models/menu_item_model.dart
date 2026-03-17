import 'package:equatable/equatable.dart';

class MenuItemModel extends Equatable {
  final int id;
  final String name;
  final String? description;
  final double price;
  final String category;
  final bool isAvailable;
  final String imageUrl;

  const MenuItemModel({
    required this.id,
    required this.name,
    this.description,
    required this.price,
    required this.category,
    required this.isAvailable,
    required this.imageUrl,
  });

  MenuItemModel copyWith({
    int? id,
    String? name,
    String? description,
    double? price,
    String? category,
    bool? isAvailable,
    String? imageUrl,
  }) {
    return MenuItemModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      category: category ?? this.category,
      isAvailable: isAvailable ?? this.isAvailable,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }



  factory MenuItemModel.fromJson(Map<String, dynamic> json) {
    return MenuItemModel(

      id: int.parse(json['id'].toString()),
      name: json['name'] ?? 'Tên không xác định',
      description: json['description'],
      price: double.tryParse(json['price'].toString()) ?? 0.0,
      category: json['category'] ?? 'Chưa phân loại',
      isAvailable: json['isAvailable'] ?? false,
      imageUrl: json['imageUrl'] ?? '',
    );
  }

  @override
  List<Object?> get props => [id, name, description, price, category, isAvailable, imageUrl];
}