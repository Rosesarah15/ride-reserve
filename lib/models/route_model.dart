
class RouteModel {
  final String id;
  final String origin;
  final String destination;

  RouteModel({
    required this.id,
    required this.origin,
    required this.destination,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'origin': origin,
      'destination': destination,
    };
  }

  factory RouteModel.fromMap(Map<String, dynamic> map) {
    return RouteModel(
      id: map['id'] ?? '',
      origin: map['origin'] ?? '',
      destination: map['destination'] ?? '',
    );
  }
}
