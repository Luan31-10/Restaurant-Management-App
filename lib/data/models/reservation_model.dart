// lib/data/models/reservation_model.dart
import 'package:equatable/equatable.dart';

class ReservationModel extends Equatable {
  final int id;
  final String customerName;
  final String phoneNumber;
  final int numberOfGuests;
  final DateTime reservationTime;
  final String? notes;
  final String status;
  final int? tableId;
  final String? tableNumber;

  const ReservationModel({
    required this.id,
    required this.customerName,
    required this.phoneNumber,
    required this.numberOfGuests,
    required this.reservationTime,
    this.notes,
    required this.status,
    this.tableId,
    this.tableNumber,
  });

  factory ReservationModel.fromJson(Map<String, dynamic> json) {
    // Helper functions (giữ nguyên)
    int safeParseInt(dynamic value, [int defaultValue = 0]) {
      return int.tryParse(value?.toString() ?? '') ?? defaultValue;
    }
    int? safeParseIntNullable(dynamic value) {
      return int.tryParse(value?.toString() ?? '');
    }
    DateTime safeParseDateTime(dynamic value) {
      if (value == null) return DateTime.now();
      return DateTime.tryParse(value.toString()) ?? DateTime.now();
    }

    // Print debug này dùng key đúng ('tableNumber')
    print('Parsing Reservation ID: ${json['id']}, tableNumber from JSON: ${json['tableNumber']}');


    return ReservationModel(
      id: safeParseInt(json['id']),
      customerName: json['customerName'] ?? '',
      phoneNumber: json['phoneNumber'] ?? '',
      numberOfGuests: safeParseInt(json['numberOfGuests']),
      reservationTime: safeParseDateTime(json['reservationTime']),
      notes: json['notes'],
      status: json['status'] ?? 'unknown',
      tableId: safeParseIntNullable(json['tableId']),
      tableNumber: json['tableNumber'] as String?,

    );
  }

  @override
  List<Object?> get props => [
    id,
    customerName,
    phoneNumber,
    numberOfGuests,
    reservationTime,
    notes,
    status,
    tableId,
    tableNumber,
  ];
}