import 'booking_status.dart';

/// Model for package/freight bookings (parcels and luggage)
/// This is separate from passenger bookings as packages don't require seats
class PackageBookingModel {
  final String id;
  final String userId;
  final String scheduleId;
  final PackageType packageType;
  final double? weightInKg;
  final double totalPrice;
  final String paymentMethod;
  final BookingStatus status;
  final DateTime bookingDate;
  final String senderName;
  final String senderPhone;
  final String receiverName;
  final String receiverPhone;
  final String? description;

  PackageBookingModel({
    required this.id,
    required this.userId,
    required this.scheduleId,
    required this.packageType,
    this.weightInKg,
    required this.totalPrice,
    required this.paymentMethod,
    required this.status,
    required this.bookingDate,
    required this.senderName,
    required this.senderPhone,
    required this.receiverName,
    required this.receiverPhone,
    this.description,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'scheduleId': scheduleId,
      'packageType': packageType.name,
      'weightInKg': weightInKg,
      'totalPrice': totalPrice,
      'paymentMethod': paymentMethod,
      'status': status.name,
      'bookingDate': bookingDate.toIso8601String(),
      'senderName': senderName,
      'senderPhone': senderPhone,
      'receiverName': receiverName,
      'receiverPhone': receiverPhone,
      'description': description,
    };
  }

  factory PackageBookingModel.fromMap(Map<String, dynamic> map) {
    return PackageBookingModel(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      scheduleId: map['scheduleId'] ?? '',
      packageType: PackageType.values.firstWhere(
        (e) => e.name == map['packageType'],
        orElse: () => PackageType.parcel,
      ),
      weightInKg: map['weightInKg']?.toDouble(),
      totalPrice: (map['totalPrice'] ?? 0.0).toDouble(),
      paymentMethod: map['paymentMethod'] ?? '',
      status: BookingStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => BookingStatus.pending,
      ),
      bookingDate: DateTime.parse(map['bookingDate']),
      senderName: map['senderName'] ?? '',
      senderPhone: map['senderPhone'] ?? '',
      receiverName: map['receiverName'] ?? '',
      receiverPhone: map['receiverPhone'] ?? '',
      description: map['description'],
    );
  }

  PackageBookingModel copyWith({
    String? id,
    String? userId,
    String? scheduleId,
    PackageType? packageType,
    double? weightInKg,
    double? totalPrice,
    String? paymentMethod,
    BookingStatus? status,
    DateTime? bookingDate,
    String? senderName,
    String? senderPhone,
    String? receiverName,
    String? receiverPhone,
    String? description,
  }) {
    return PackageBookingModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      scheduleId: scheduleId ?? this.scheduleId,
      packageType: packageType ?? this.packageType,
      weightInKg: weightInKg ?? this.weightInKg,
      totalPrice: totalPrice ?? this.totalPrice,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      status: status ?? this.status,
      bookingDate: bookingDate ?? this.bookingDate,
      senderName: senderName ?? this.senderName,
      senderPhone: senderPhone ?? this.senderPhone,
      receiverName: receiverName ?? this.receiverName,
      receiverPhone: receiverPhone ?? this.receiverPhone,
      description: description ?? this.description,
    );
  }
}

enum PackageType {
  parcel,
  luggage,
}
