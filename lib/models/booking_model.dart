import 'booking_status.dart';

/// Model for passenger bookings with seat selection
class BookingModel {
  final String id;
  final String userId;
  final String scheduleId;
  final List<String> seatNumbers;
  final int passengerCount;
  final double passengerFee;
  final bool hasLuggage;
  final double? luggageWeightInKg;
  final double? luggageFee;
  final double totalFee;
  final String paymentMethod;
  final BookingStatus status;
  final DateTime bookingDate;

  BookingModel({
    required this.id,
    required this.userId,
    required this.scheduleId,
    required this.seatNumbers,
    required this.passengerCount,
    required this.passengerFee,
    this.hasLuggage = false,
    this.luggageWeightInKg,
    this.luggageFee,
    required this.totalFee,
    required this.paymentMethod,
    required this.status,
    required this.bookingDate,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'scheduleId': scheduleId,
      'seatNumbers': seatNumbers,
      'passengerCount': passengerCount,
      'passengerFee': passengerFee,
      'hasLuggage': hasLuggage,
      'luggageWeightInKg': luggageWeightInKg,
      'luggageFee': luggageFee,
      'totalFee': totalFee,
      'paymentMethod': paymentMethod,
      'status': status.name,
      'bookingDate': bookingDate.toIso8601String(),
    };
  }

  factory BookingModel.fromMap(Map<String, dynamic> map) {
    return BookingModel(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      scheduleId: map['scheduleId'] ?? '',
      seatNumbers: List<String>.from(map['seatNumbers'] ?? []),
      passengerCount: map['passengerCount'] ?? 1,
      passengerFee: (map['passengerFee'] ?? 0.0).toDouble(),
      hasLuggage: map['hasLuggage'] ?? false,
      luggageWeightInKg: map['luggageWeightInKg']?.toDouble(),
      luggageFee: map['luggageFee']?.toDouble(),
      totalFee: (map['totalFee'] ?? 0.0).toDouble(),
      paymentMethod: map['paymentMethod'] ?? '',
      status: BookingStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => BookingStatus.pending,
      ),
      bookingDate: DateTime.parse(map['bookingDate']),
    );
  }

  BookingModel copyWith({
    String? id,
    String? userId,
    String? scheduleId,
    List<String>? seatNumbers,
    int? passengerCount,
    double? passengerFee,
    bool? hasLuggage,
    double? luggageWeightInKg,
    double? luggageFee,
    double? totalFee,
    String? paymentMethod,
    BookingStatus? status,
    DateTime? bookingDate,
  }) {
    return BookingModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      scheduleId: scheduleId ?? this.scheduleId,
      seatNumbers: seatNumbers ?? this.seatNumbers,
      passengerCount: passengerCount ?? this.passengerCount,
      passengerFee: passengerFee ?? this.passengerFee,
      hasLuggage: hasLuggage ?? this.hasLuggage,
      luggageWeightInKg: luggageWeightInKg ?? this.luggageWeightInKg,
      luggageFee: luggageFee ?? this.luggageFee,
      totalFee: totalFee ?? this.totalFee,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      status: status ?? this.status,
      bookingDate: bookingDate ?? this.bookingDate,
    );
  }
}
