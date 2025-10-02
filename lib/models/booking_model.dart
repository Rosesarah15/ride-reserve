class BookingModel {
  final String id;
  final String userId;
  final String busId;
  final String destination;
  final String busCompanyName;
  final String busNumberPlate;
  final String departureTime;
  final String? seatNumber;
  final double fee;
  final String paymentMethod;
  final String paymentStatus;
  final String receiptNumber;
  final DateTime bookingDate;
  final DateTime departureDate;
  final BookingStatus status;

  BookingModel({
    required this.id,
    required this.userId,
    required this.busId,
    required this.destination,
    required this.busCompanyName,
    required this.busNumberPlate,
    required this.departureTime,
    this.seatNumber,
    required this.fee,
    required this.paymentMethod,
    required this.paymentStatus,
    required this.receiptNumber,
    required this.bookingDate,
    required this.departureDate,
    required this.status,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'busId': busId,
      'destination': destination,
      'busCompanyName': busCompanyName,
      'busNumberPlate': busNumberPlate,
      'departureTime': departureTime,
      'seatNumber': seatNumber,
      'fee': fee,
      'paymentMethod': paymentMethod,
      'paymentStatus': paymentStatus,
      'receiptNumber': receiptNumber,
      'bookingDate': bookingDate.toIso8601String(),
      'departureDate': departureDate.toIso8601String(),
      'status': status.name,
    };
  }

  factory BookingModel.fromMap(Map<String, dynamic> map) {
    return BookingModel(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      busId: map['busId'] ?? '',
      destination: map['destination'] ?? '',
      busCompanyName: map['busCompanyName'] ?? '',
      busNumberPlate: map['busNumberPlate'] ?? '',
      departureTime: map['departureTime'] ?? '',
      seatNumber: map['seatNumber'],
      fee: (map['fee'] ?? 0.0).toDouble(),
      paymentMethod: map['paymentMethod'] ?? '',
      paymentStatus: map['paymentStatus'] ?? '',
      receiptNumber: map['receiptNumber'] ?? '',
      bookingDate: DateTime.parse(map['bookingDate']),
      departureDate: DateTime.parse(map['departureDate']),
      status: BookingStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => BookingStatus.confirmed,
      ),
    );
  }
}

enum BookingStatus {
  confirmed,
  cancelled,
  completed,
  pending,
}