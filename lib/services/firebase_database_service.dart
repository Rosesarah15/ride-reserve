import 'package:bus_booking/models/trip_search_result.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/bus_model.dart';
import '../models/booking_model.dart';
import '../models/booking_details_model.dart';
import '../models/booking_status.dart';
import '../models/company_model.dart';
import '../models/notification_model.dart';
import '../models/package_booking_model.dart';
import '../models/pricing_model.dart';
import '../models/route_model.dart';
import '../models/schedule_model.dart';

class FirebaseDatabaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<String>> getOrigins() async {
    try {
      final querySnapshot = await _firestore.collection('routes').get();
      final origins = querySnapshot.docs.map((doc) => doc.data()['origin'] as String).toSet().toList();
      return origins;
    } catch (e) {
      throw Exception('Failed to get origins: $e');
    }
  }

  Future<List<String>> getDestinations() async {
    try {
      final querySnapshot = await _firestore.collection('routes').get();
      final destinations = querySnapshot.docs.map((doc) => doc.data()['destination'] as String).toSet().toList();
      return destinations;
    } catch (e) {
      throw Exception('Failed to get destinations: $e');
    }
  }

  Future<List<TripSearchResult>> searchSchedules({
    required String origin,
    required String destination,
    required DateTime date,
  }) async {
    try {
      // 1. Find the route - get all routes and find matching one
      final allRoutesQuery = await _firestore.collection('routes').get();

      if (allRoutesQuery.docs.isEmpty) {
        throw Exception('No routes found in database');
      }

      // Find matching route (case-insensitive comparison)
      RouteModel? matchingRoute;
      for (var doc in allRoutesQuery.docs) {
        final routeData = doc.data();
        final routeOrigin = (routeData['origin'] as String).trim().toLowerCase();
        final routeDestination = (routeData['destination'] as String).trim().toLowerCase();

        if (routeOrigin == origin.trim().toLowerCase() &&
            routeDestination == destination.trim().toLowerCase()) {
          matchingRoute = RouteModel.fromMap(routeData);
          break;
        }
      }

      if (matchingRoute == null) {
        throw Exception('No route found for $origin to $destination');
      }

      // 2. Find schedules for that route
      final scheduleQuery = await _firestore.collection('schedules')
          .where('routeId', isEqualTo: matchingRoute.id)
          .get();

      if (scheduleQuery.docs.isEmpty) {
        throw Exception('No schedules found for this route');
      }

      // Filter schedules by the selected date
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);

      final schedules = scheduleQuery.docs
          .map((doc) => ScheduleModel.fromMap(doc.data()))
          .where((schedule) {
            // Check if the schedule's departure is on the selected date
            return schedule.departureTime.isAfter(startOfDay.subtract(const Duration(seconds: 1))) &&
                   schedule.departureTime.isBefore(endOfDay.add(const Duration(seconds: 1)));
          })
          .toList();

      if (schedules.isEmpty) {
        throw Exception('No buses available on ${date.day}/${date.month}/${date.year}');
      }

      // 3. Fetch bus and company details for each schedule
      List<TripSearchResult> results = [];
      for (final schedule in schedules) {
        final busDoc = await _firestore.collection('buses').doc(schedule.busId).get();
        if (!busDoc.exists) continue;
        final bus = BusModel.fromMap(busDoc.data()!);

        final companyDoc = await _firestore.collection('companies').doc(bus.companyId).get();
        if (!companyDoc.exists) continue;
        final company = CompanyModel.fromMap(companyDoc.data()!);

        results.add(TripSearchResult(
          schedule: schedule,
          route: matchingRoute,
          bus: bus,
          company: company,
        ));
      }

      return results;

    } catch (e) {
      throw Exception('Search failed: ${e.toString().replaceAll('Exception: ', '')}');
    }
  }

  Stream<List<String>> getBookedSeats(String scheduleId) {
    return _firestore
        .collection('bookings')
        .where('scheduleId', isEqualTo: scheduleId)
        .where('status', whereIn: [
          BookingStatus.confirmed.name,
          BookingStatus.pending.name
        ])
        .snapshots()
        .map((snapshot) {
      final List<String> allBookedSeats = [];
      for (final doc in snapshot.docs) {
        final data = doc.data();
        final seatNumbers = List<String>.from(data['seatNumbers'] ?? []);
        allBookedSeats.addAll(seatNumbers);
      }
      return allBookedSeats;
    });
  }

  // Booking operations
  Future<String> createBooking(BookingModel booking) async {
    try {
      final docRef = await _firestore.collection('bookings').add(booking.toMap());
      return docRef.id;
    } catch (e) {
      throw Exception('Failed to create booking: $e');
    }
  }

  Future<List<BookingModel>> getUserBookings(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection('bookings')
          .where('userId', isEqualTo: userId)
          .orderBy('bookingDate', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => BookingModel.fromMap(doc.data()))
          .toList();
    } catch (e) {
      throw Exception('Failed to get user bookings: $e');
    }
  }

  Future<List<BookingDetailsModel>> getUserBookingDetails(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection('bookings')
          .where('userId', isEqualTo: userId)
          .orderBy('bookingDate', descending: true)
          .get();

      List<BookingDetailsModel> bookingDetails = [];
      
      for (final doc in querySnapshot.docs) {
        final booking = BookingModel.fromMap(doc.data());
        
        // Fetch schedule details
        final scheduleDoc = await _firestore.collection('schedules').doc(booking.scheduleId).get();
        if (!scheduleDoc.exists) continue;
        final schedule = ScheduleModel.fromMap(scheduleDoc.data()!);
        
        // Fetch route details
        final routeDoc = await _firestore.collection('routes').doc(schedule.routeId).get();
        if (!routeDoc.exists) continue;
        final route = RouteModel.fromMap(routeDoc.data()!);
        
        // Fetch bus details
        final busDoc = await _firestore.collection('buses').doc(schedule.busId).get();
        if (!busDoc.exists) continue;
        final bus = BusModel.fromMap(busDoc.data()!);
        
        // Fetch company details
        final companyDoc = await _firestore.collection('companies').doc(bus.companyId).get();
        if (!companyDoc.exists) continue;
        final company = CompanyModel.fromMap(companyDoc.data()!);
        
        bookingDetails.add(BookingDetailsModel(
          booking: booking,
          schedule: schedule,
          route: route,
          bus: bus,
          company: company,
        ));
      }
      
      return bookingDetails;
    } catch (e) {
      throw Exception('Failed to get user booking details: $e');
    }
  }

  Future<void> updateBookingStatus(String bookingId, BookingStatus status) async {
    try {
      await _firestore
          .collection('bookings')
          .doc(bookingId)
          .update({'status': status.name});
    } catch (e) {
      throw Exception('Failed to update booking status: $e');
    }
  }

  // Notification operations
  Future<String> createNotification(NotificationModel notification) async {
    try {
      final docRef = await _firestore.collection('notifications').add(notification.toMap());
      return docRef.id;
    } catch (e) {
      throw Exception('Failed to create notification: $e');
    }
  }

  Future<List<NotificationModel>> getUserNotifications(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => NotificationModel.fromMap(doc.data()))
          .toList();
    } catch (e) {
      throw Exception('Failed to get user notifications: $e');
    }
  }

  Future<int> getUnreadNotificationCount(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .get();

      return querySnapshot.docs.length;
    } catch (e) {
      throw Exception('Failed to get unread notification count: $e');
    }
  }

  Future<void> markNotificationAsRead(String notificationId) async {
    try {
      await _firestore
          .collection('notifications')
          .doc(notificationId)
          .update({'isRead': true});
    } catch (e) {
      throw Exception('Failed to mark notification as read: $e');
    }
  }

  // Pricing operations
  Future<void> createOrUpdatePricing(PricingModel pricing) async {
    try {
      await _firestore
          .collection('pricing')
          .doc(pricing.id)
          .set(pricing.toMap());
    } catch (e) {
      throw Exception('Failed to create/update pricing: $e');
    }
  }

  Future<PricingModel?> getPricing({
    required String companyId,
    required String routeId,
    required String busType,
  }) async {
    try {
      final querySnapshot = await _firestore
          .collection('pricing')
          .where('companyId', isEqualTo: companyId)
          .where('routeId', isEqualTo: routeId)
          .where('busType', isEqualTo: busType)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) return null;
      return PricingModel.fromMap(querySnapshot.docs.first.data());
    } catch (e) {
      throw Exception('Failed to get pricing: $e');
    }
  }

  Stream<QuerySnapshot> getPricingStreamByCompany(String companyId) {
    return _firestore
        .collection('pricing')
        .where('companyId', isEqualTo: companyId)
        .snapshots();
  }

  Future<void> deletePricing(String pricingId) async {
    try {
      await _firestore.collection('pricing').doc(pricingId).delete();
    } catch (e) {
      throw Exception('Failed to delete pricing: $e');
    }
  }

  // Package booking operations
  Future<String> createPackageBooking(PackageBookingModel packageBooking) async {
    try {
      final docRef = await _firestore
          .collection('package_bookings')
          .add(packageBooking.toMap());
      return docRef.id;
    } catch (e) {
      throw Exception('Failed to create package booking: $e');
    }
  }

  Future<List<PackageBookingModel>> getUserPackageBookings(
    String userId,
  ) async {
    try {
      final querySnapshot = await _firestore
          .collection('package_bookings')
          .where('userId', isEqualTo: userId)
          .orderBy('bookingDate', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => PackageBookingModel.fromMap(doc.data()))
          .toList();
    } catch (e) {
      throw Exception('Failed to get user package bookings: $e');
    }
  }

  Future<void> updatePackageBookingStatus(
    String bookingId,
    BookingStatus status,
  ) async {
    try {
      await _firestore
          .collection('package_bookings')
          .doc(bookingId)
          .update({'status': status.name});
    } catch (e) {
      throw Exception('Failed to update package booking status: $e');
    }
  }

  Stream<QuerySnapshot> getAllPackageBookingsStream() {
    return _firestore
        .collection('package_bookings')
        .orderBy('bookingDate', descending: true)
        .snapshots();
  }

  // Admin functions
  Future<void> createRoute(RouteModel route) async {
    await _firestore.collection('routes').doc(route.id).set(route.toMap());
  }

  Stream<QuerySnapshot> getRoutesStream() {
    return _firestore.collection('routes').snapshots();
  }

  Future<void> createCompany(CompanyModel company) async {
    await _firestore.collection('companies').doc(company.id).set(company.toMap());
  }

  Stream<QuerySnapshot> getCompaniesStream() {
    return _firestore.collection('companies').snapshots();
  }

  Future<void> createBus(BusModel bus) async {
    await _firestore.collection('buses').doc(bus.id).set(bus.toMap());
  }

  Stream<QuerySnapshot> getBusesStream() {
    return _firestore.collection('buses').snapshots();
  }

  Stream<QuerySnapshot> getSchedulesStream() {
    return _firestore.collection('schedules').snapshots();
  }

  Future<void> createSchedules(List<ScheduleModel> schedules) async {
    final batch = _firestore.batch();
    for (final schedule in schedules) {
      final docRef = _firestore.collection('schedules').doc(schedule.id);
      batch.set(docRef, schedule.toMap());
    }
    await batch.commit();
  }

  // Initialize sample data
  Future<void> initializeSampleData() async {
    final batch = _firestore.batch();

    // Add sample companies
    final companies = [
      CompanyModel(
        id: 'company1',
        name: 'Post Bus Uganda',
        license: 'LIC-2024-001',
        logoUrl: '',
        rating: 4.5,
      ),
      CompanyModel(
        id: 'company2',
        name: 'Jaguar Executive',
        license: 'LIC-2024-002',
        logoUrl: '',
        rating: 4.2,
      ),
      CompanyModel(
        id: 'company3',
        name: 'Link Bus Services',
        license: 'LIC-2024-003',
        logoUrl: '',
        rating: 4.0,
      ),
    ];
    for (final company in companies) {
      batch.set(
        _firestore.collection('companies').doc(company.id),
        company.toMap(),
      );
    }

    // Add sample buses
    final buses = [
      BusModel(
        id: 'bus1',
        companyId: 'company1',
        numberPlate: 'UAA 123A',
        driver: 'John Mukasa',
        type: BusType.ordinary,
        totalSeats: 50,
        amenities: ['AC', 'Water'],
      ),
      BusModel(
        id: 'bus2',
        companyId: 'company2',
        numberPlate: 'UAB 456B',
        driver: 'Sarah Nakato',
        type: BusType.vip,
        totalSeats: 40,
        amenities: ['WiFi', 'AC', 'Snacks'],
      ),
      BusModel(
        id: 'bus3',
        companyId: 'company3',
        numberPlate: 'UAC 789C',
        driver: 'Peter Ouma',
        type: BusType.ordinary,
        totalSeats: 50,
        amenities: ['AC', 'Water'],
      ),
    ];
    for (final bus in buses) {
      batch.set(_firestore.collection('buses').doc(bus.id), bus.toMap());
    }

    // Add sample routes
    final routes = [
      RouteModel(id: 'route1', origin: 'Kampala', destination: 'Entebbe'),
      RouteModel(id: 'route2', origin: 'Kampala', destination: 'Jinja'),
      RouteModel(id: 'route3', origin: 'Kampala', destination: 'Mbarara'),
      RouteModel(id: 'route4', origin: 'Jinja', destination: 'Kampala'),
    ];
    for (final route in routes) {
      batch.set(_firestore.collection('routes').doc(route.id), route.toMap());
    }

    // Add sample schedules
    final now = DateTime.now();
    final schedules = [
      ScheduleModel(id: 'schedule1', routeId: 'route1', busId: 'bus1', departureTime: DateTime(now.year, now.month, now.day, 8), arrivalTime: DateTime(now.year, now.month, now.day, 10), fee: 15000),
      ScheduleModel(id: 'schedule2', routeId: 'route2', busId: 'bus2', departureTime: DateTime(now.year, now.month, now.day, 9, 30), arrivalTime: DateTime(now.year, now.month, now.day, 12, 30), fee: 25000),
      ScheduleModel(id: 'schedule3', routeId: 'route3', busId: 'bus3', departureTime: DateTime(now.year, now.month, now.day, 14), arrivalTime: DateTime(now.year, now.month, now.day, 18), fee: 40000),
      ScheduleModel(id: 'schedule4', routeId: 'route1', busId: 'bus2', departureTime: DateTime(now.year, now.month, now.day, 11), arrivalTime: DateTime(now.year, now.month, now.day, 13), fee: 20000),
    ];
    for (final schedule in schedules) {
      batch.set(_firestore.collection('schedules').doc(schedule.id), schedule.toMap());
    }

    // Add sample pricing
    final pricingList = [
      // Post Bus Uganda - Route 1 (Kampala to Entebbe)
      PricingModel(
        id: 'pricing1',
        companyId: 'company1',
        routeId: 'route1',
        busType: BusTypeForPricing.ordinary,
        passengerPrice: 15000,
        parcelStandardPrice: 5000,
        luggagePricePerKg: 500,
      ),
      // Jaguar Executive - Route 2 (Kampala to Jinja) - VIP
      PricingModel(
        id: 'pricing2',
        companyId: 'company2',
        routeId: 'route2',
        busType: BusTypeForPricing.vip,
        passengerPrice: 35000,
        parcelStandardPrice: 8000,
        luggagePricePerKg: 800,
      ),
      // Link Bus - Route 3 (Kampala to Mbarara)
      PricingModel(
        id: 'pricing3',
        companyId: 'company3',
        routeId: 'route3',
        busType: BusTypeForPricing.ordinary,
        passengerPrice: 40000,
        parcelStandardPrice: 10000,
        luggagePricePerKg: 1000,
      ),
    ];
    for (final pricing in pricingList) {
      batch.set(
        _firestore.collection('pricing').doc(pricing.id),
        pricing.toMap(),
      );
    }

    await batch.commit();
    print('Sample data initialization completed successfully');
  }
}