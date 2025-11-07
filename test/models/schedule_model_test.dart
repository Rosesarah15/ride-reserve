import 'package:bus_booking/models/schedule_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ScheduleModel', () {
    final departureTime = DateTime.now();
    final arrivalTime = departureTime.add(const Duration(hours: 2));
    final schedule = ScheduleModel(
      id: 'schedule1',
      routeId: 'route1',
      busId: 'bus1',
      departureTime: departureTime,
      arrivalTime: arrivalTime,
      fee: 25000,
    );

    test('fromMap creates a valid ScheduleModel from a map', () {
      final map = {
        'id': 'schedule1',
        'routeId': 'route1',
        'busId': 'bus1',
        'departureTime': Timestamp.fromDate(departureTime),
        'arrivalTime': Timestamp.fromDate(arrivalTime),
        'fee': 25000.0,
      };
      final result = ScheduleModel.fromMap(map);
      expect(result.id, schedule.id);
      expect(result.routeId, schedule.routeId);
      expect(result.busId, schedule.busId);
      expect(result.departureTime.difference(schedule.departureTime).inSeconds, 0);
      expect(result.arrivalTime.difference(schedule.arrivalTime).inSeconds, 0);
      expect(result.fee, schedule.fee);
    });
    test('fromMap handles string dates', () {
      final map = {
        'id': 'schedule1',
        'routeId': 'route1',
        'busId': 'bus1',
        'departureTime': departureTime.toIso8601String(),
        'arrivalTime': arrivalTime.toIso8601String(),
        'fee': 25000.0,
      };
      final result = ScheduleModel.fromMap(map);
      expect(result.departureTime.difference(schedule.departureTime).inSeconds, 0);
      expect(result.arrivalTime.difference(schedule.arrivalTime).inSeconds, 0);
    });
    test('toMap returns a valid map from a ScheduleModel', () {
      final result = schedule.toMap();
      expect(result['id'], schedule.id);
      expect(result['routeId'], schedule.routeId);
      expect(result['busId'], schedule.busId);
      expect(result['departureTime'], schedule.departureTime.toIso8601String());
      expect(result['arrivalTime'], schedule.arrivalTime.toIso8601String());
      expect(result['fee'], schedule.fee);
    });
    test('fromMap handles null and missing values gracefully', () {
      final map = <String, dynamic>{};
      final result = ScheduleModel.fromMap(map);
      expect(result.id, '');
      expect(result.routeId, '');
      expect(result.busId, '');
      expect(result.fee, 0.0);
      expect(DateTime.now().difference(result.departureTime).inSeconds, lessThan(5));
      expect(DateTime.now().difference(result.arrivalTime).inSeconds, lessThan(5));
    });
  });
}
