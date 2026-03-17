// table_model.dart
import 'package:equatable/equatable.dart';
import 'active_order_model.dart';

class TableModel extends Equatable {
  final int id;
  final String number;
  final int capacity;
  final String status;
  final ActiveOrderModel? activeOrder;

  const TableModel({
    required this.id,
    required this.number,
    required this.capacity,
    required this.status,
    this.activeOrder,
  });

  factory TableModel.fromJson(Map<String, dynamic> json) {
    return TableModel(
      id: int.parse(json['id'].toString()),
      number: json['number'],
      capacity: int.parse(json['capacity'].toString()),
      status: json['status'],
      activeOrder: json['activeOrder'] != null
          ? ActiveOrderModel.fromJson(json['activeOrder'])
          : null,
    );
  }


  @override
  List<Object?> get props => [id, number, capacity, status, activeOrder];


}