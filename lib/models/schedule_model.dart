
import 'package:cloud_firestore/cloud_firestore.dart';

class ScheduleModel {
  final String id;
  final String routeId;
  final String busId;
  final DateTime departureTime;
  final DateTime arrivalTime;
  final double fee;

  ScheduleModel({
    required this.id,
    required this.routeId,
    required this.busId,
    required this.departureTime,
    required this.arrivalTime,
    required this.fee,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'routeId': routeId,
      'busId': busId,
      'departureTime': departureTime.toIso8601String(),
      'arrivalTime': arrivalTime.toIso8601String(),
      'fee': fee,
    };
  }

  factory ScheduleModel.fromMap(Map<String, dynamic> map) {
    return ScheduleModel(
      id: map['id'] ?? '',
      routeId: map['routeId'] ?? '',
      busId: map['busId'] ?? '',
      departureTime: _parseDate(map['departureTime']),
      arrivalTime: _parseDate(map['arrivalTime']),
      fee: (map['fee'] ?? 0.0).toDouble(),
    );
  }
}

DateTime _parseDate(dynamic date) {
  if (date is String) {
    return DateTime.parse(date);
  } else if (date is Timestamp) {
    return date.toDate();
  }
  // As a fallback, return the current time, though in a real app you might want to throw an error.
  return DateTime.now();
}
