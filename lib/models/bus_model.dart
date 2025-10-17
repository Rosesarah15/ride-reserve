
class BusModel {
  final String id;
  final String companyId;
  final String numberPlate;
  final BusType type;
  final int totalSeats;
  final List<String> amenities;

  BusModel({
    required this.id,
    required this.companyId,
    required this.numberPlate,
    required this.type,
    required this.totalSeats,
    required this.amenities,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'companyId': companyId,
      'numberPlate': numberPlate,
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
      type: BusType.values.firstWhere((e) => e.name == map['type'], orElse: () => BusType.standard),
      totalSeats: map['totalSeats'] ?? 0,
      amenities: List<String>.from(map['amenities'] ?? []),
    );
  }
}

enum BusType {
  standard,
  vip,
  luxury,
}
