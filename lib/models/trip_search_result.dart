
import 'package:bus_booking/models/bus_model.dart';
import 'package:bus_booking/models/company_model.dart';
import 'package:bus_booking/models/route_model.dart';
import 'package:bus_booking/models/schedule_model.dart';

class TripSearchResult {
  final ScheduleModel schedule;
  final RouteModel route;
  final BusModel bus;
  final CompanyModel company;

  TripSearchResult({
    required this.schedule,
    required this.route,
    required this.bus,
    required this.company,
  });
}
