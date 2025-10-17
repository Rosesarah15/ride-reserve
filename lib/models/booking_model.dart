
class BookingModel {
  final String id;
  final String userId;
  final String scheduleId;
  final String seatNumber;
  final double fee;
  final String paymentMethod;
  final BookingStatus status;
  final DateTime bookingDate;

  BookingModel({
    required this.id,
    required this.userId,
    required this.scheduleId,
    required this.seatNumber,
    required this.fee,
    required this.paymentMethod,
    required this.status,
    required this.bookingDate,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'scheduleId': scheduleId,
      'seatNumber': seatNumber,
      'fee': fee,
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
      seatNumber: map['seatNumber'] ?? '',
      fee: (map['fee'] ?? 0.0).toDouble(),
      paymentMethod: map['paymentMethod'] ?? '',
      status: BookingStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => BookingStatus.confirmed,
      ),
      bookingDate: DateTime.parse(map['bookingDate']),
    );
  }
}

enum BookingStatus {
  confirmed,
  cancelled,
  completed,
  pending,
}
