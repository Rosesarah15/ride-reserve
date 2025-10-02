class BusModel {
  final String id;
  final String companyName;
  final String destination;
  final String departureTime;
  final String arrivalTime;
  final double fee;
  final int totalSeats;
  final int availableSeats;
  final String busNumberPlate;
  final double? rating;
  final List<String> amenities;
  final DateTime departureDate;

  BusModel({
    required this.id,
    required this.companyName,
    required this.destination,
    required this.departureTime,
    required this.arrivalTime,
    required this.fee,
    required this.totalSeats,
    required this.availableSeats,
    required this.busNumberPlate,
    this.rating,
    this.amenities = const [],
    required this.departureDate,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'companyName': companyName,
      'destination': destination,
      'departureTime': departureTime,
      'arrivalTime': arrivalTime,
      'fee': fee,
      'totalSeats': totalSeats,
      'availableSeats': availableSeats,
      'busNumberPlate': busNumberPlate,
      'rating': rating,
      'amenities': amenities,
      'departureDate': departureDate.toIso8601String(),
    };
  }

  factory BusModel.fromMap(Map<String, dynamic> map) {
    return BusModel(
      id: map['id'] ?? '',
      companyName: map['companyName'] ?? '',
      destination: map['destination'] ?? '',
      departureTime: map['departureTime'] ?? '',
      arrivalTime: map['arrivalTime'] ?? '',
      fee: (map['fee'] ?? 0.0).toDouble(),
      totalSeats: map['totalSeats'] ?? 0,
      availableSeats: map['availableSeats'] ?? 0,
      busNumberPlate: map['busNumberPlate'] ?? '',
      rating: map['rating']?.toDouble(),
      amenities: List<String>.from(map['amenities'] ?? []),
      departureDate: DateTime.parse(map['departureDate']),
    );
  }
}