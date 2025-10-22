class BusModel {
  final String id;
  final String companyId;
  final String numberPlate;
  final String driver;
  final BusType type;
  final int totalSeats;
  final List<String> amenities;

  BusModel({
    required this.id,
    required this.companyId,
    required this.numberPlate,
    required this.driver,
    required this.type,
    required this.totalSeats,
    required this.amenities,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'companyId': companyId,
      'numberPlate': numberPlate,
      'driver': driver,
      'type': type.name,
      'totalSeats': totalSeats,
      'amenities': amenities,
    };
  }

  factory BusModel.fromMap(Map<String, dynamic> map) {
    return BusModel(
      id: map['id'] ?? '',
      companyId: map['companyId'] ?? '',
      numberPlate: map['numberPlate'] ?? '',
      driver: map['driver'] ?? '',
      type: BusType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => BusType.ordinary,
      ),
      totalSeats: map['totalSeats'] ?? 0,
      amenities: List<String>.from(map['amenities'] ?? []),
    );
  }
}

enum BusType {
  ordinary,
  vip,
}
