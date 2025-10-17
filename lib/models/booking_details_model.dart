import 'package:bus_booking/models/booking_model.dart';
import 'package:bus_booking/models/schedule_model.dart';
import 'package:bus_booking/models/route_model.dart';
import 'package:bus_booking/models/bus_model.dart';
import 'package:bus_booking/models/company_model.dart';

class BookingDetailsModel {
  final BookingModel booking;
  final ScheduleModel schedule;
  final RouteModel route;
  final BusModel bus;
  final CompanyModel company;

  BookingDetailsModel({
    required this.booking,
    required this.schedule,
    required this.route,
    required this.bus,
    required this.company,
  });

  // Convenience getters for commonly used properties
  String get receiptNumber => booking.id;
  String get destination => route.destination;
  String get origin => route.origin;
  String get busCompanyName => company.name;
  String get busNumberPlate => bus.numberPlate;
  DateTime get departureTime => schedule.departureTime;
  DateTime get arrivalTime => schedule.arrivalTime;
  double get fee => schedule.fee;
  String get seatNumber => booking.seatNumber;
  String get paymentMethod => booking.paymentMethod;
  BookingStatus get status => booking.status;
  DateTime get bookingDate => booking.bookingDate;
}

