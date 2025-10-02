import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/bus_model.dart';
import '../models/booking_model.dart';
import '../models/notification_model.dart';

class FirebaseDatabaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Bus operations
  Future<List<BusModel>> searchBuses({
    required String destination,
    DateTime? departureDate,
  }) async {
    try {
      Query query = _firestore.collection('buses')
          .where('destination', isEqualTo: destination);

      if (departureDate != null) {
        final startOfDay = DateTime(departureDate.year, departureDate.month, departureDate.day);
        final endOfDay = DateTime(departureDate.year, departureDate.month, departureDate.day, 23, 59, 59);
        
        query = query
            .where('departureDate', isGreaterThanOrEqualTo: startOfDay)
            .where('departureDate', isLessThanOrEqualTo: endOfDay);
      }

      final querySnapshot = await query.get();
      return querySnapshot.docs
          .map((doc) => BusModel.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to search buses: $e');
    }
  }

  Future<List<String>> getDestinations() async {
    try {
      print('Fetching destinations from Firestore...');
      final querySnapshot = await _firestore.collection('destinations').get();
      final destinations = querySnapshot.docs.map((doc) => doc.id).toList();
      print('Found ${destinations.length} destinations: $destinations');
      return destinations;
    } catch (e) {
      print('Error fetching destinations: $e');
      throw Exception('Failed to get destinations: $e');
    }
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

  // Initialize sample data
  Future<void> initializeSampleData() async {
    try {
      print('Initializing sample data...');
      
      // Add sample destinations
      final destinations = [
        'Kampala',
        'Entebbe',
        'Jinja',
        'Masaka',
        'Mbarara',
        'Gulu',
        'Lira',
        'Arua',
        'Fort Portal',
        'Kabale',
        'Mbale',
        'Soroti',
        'Kasese',
        'Busia',
        'Koboko',
        'Nebbi',
        'Pakwach',
        'Moroto',
        'Iganga',
      ];

      print('Adding ${destinations.length} destinations...');
      for (String destination in destinations) {
        await _firestore.collection('destinations').doc(destination).set({
          'name': destination,
          'createdAt': DateTime.now().toIso8601String(),
        });
        print('Added destination: $destination');
      }
      print('Destinations added successfully');

      // Add sample buses
      final buses = [
        BusModel(
          id: 'bus1',
          companyName: 'Post Bus Uganda',
          destination: 'Kampala',
          departureTime: '08:00',
          arrivalTime: '10:00',
          fee: 15000.0,
          totalSeats: 50,
          availableSeats: 35,
          busNumberPlate: 'UAA 123A',
          rating: 4.5,
          amenities: ['WiFi', 'AC', 'Water'],
          departureDate: DateTime.now().add(const Duration(days: 1)),
        ),
        BusModel(
          id: 'bus2',
          companyName: 'Jaguar Executive',
          destination: 'Entebbe',
          departureTime: '09:30',
          arrivalTime: '11:00',
          fee: 12000.0,
          totalSeats: 40,
          availableSeats: 28,
          busNumberPlate: 'UAB 456B',
          rating: 4.2,
          amenities: ['WiFi', 'AC'],
          departureDate: DateTime.now().add(const Duration(days: 1)),
        ),
        BusModel(
          id: 'bus3',
          companyName: 'Link Bus Services',
          destination: 'Jinja',
          departureTime: '14:00',
          arrivalTime: '16:30',
          fee: 18000.0,
          totalSeats: 45,
          availableSeats: 42,
          busNumberPlate: 'UAC 789C',
          rating: 4.0,
          amenities: ['AC', 'Water'],
          departureDate: DateTime.now().add(const Duration(days: 1)),
        ),
      ];

      print('Adding ${buses.length} sample buses...');
      for (BusModel bus in buses) {
        await _firestore.collection('buses').doc(bus.id).set(bus.toMap());
        print('Added bus: ${bus.companyName} to ${bus.destination}');
      }
      print('Sample data initialization completed successfully');
    } catch (e) {
      print('Error in initializeSampleData: $e');
      throw Exception('Failed to initialize sample data: $e');
    }
  }
}