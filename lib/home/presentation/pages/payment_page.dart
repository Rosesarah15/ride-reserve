import 'package:bus_booking/models/booking_model.dart';
import 'package:bus_booking/models/booking_status.dart';
import 'package:bus_booking/models/notification_model.dart';
import 'package:bus_booking/models/trip_search_result.dart';
import 'package:bus_booking/services/firebase_database_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

class PaymentPage extends StatefulWidget {
  final TripSearchResult trip;
  final String selectedSeat;

  const PaymentPage({super.key, required this.trip, required this.selectedSeat});

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  final FirebaseDatabaseService _databaseService = FirebaseDatabaseService();
  bool _isProcessing = false;

  Future<void> _createBooking(String paymentMethod) async {
    setState(() {
      _isProcessing = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('You must be logged in to book.');
      }

      final booking = BookingModel(
        id: const Uuid().v4(),
        userId: user.uid,
        scheduleId: widget.trip.schedule.id,
        seatNumbers: [widget.selectedSeat],
        passengerCount: 1,
        passengerFee: widget.trip.schedule.fee,
        totalFee: widget.trip.schedule.fee,
        paymentMethod: paymentMethod,
        status: BookingStatus.confirmed,
        bookingDate: DateTime.now(),
      );

      await _databaseService.createBooking(booking);

      final notification = NotificationModel(
        id: const Uuid().v4(),
        userId: user.uid,
        title: 'Booking Confirmed',
        message:
            '${widget.trip.route.origin} → ${widget.trip.route.destination} on ${DateFormat('MMM d, yyyy • h:mm a').format(widget.trip.schedule.departureTime)}',
        type: NotificationType.booking,
        createdAt: DateTime.now(),
        data: {
          'bookingId': booking.id,
          'seatNumbers': booking.seatNumbers,
          'paymentMethod': booking.paymentMethod,
          'totalFee': booking.totalFee,
          'departureTime': widget.trip.schedule.departureTime.toIso8601String(),
          'arrivalTime': widget.trip.schedule.arrivalTime.toIso8601String(),
          'origin': widget.trip.route.origin,
          'destination': widget.trip.route.destination,
          'company': widget.trip.company.name,
          'busNumberPlate': widget.trip.bus.numberPlate,
        },
      );

      await _databaseService.createNotification(notification);

      // Show success dialog
      if (mounted) {
        await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Booking Successful'),
            content: const Text('Your booking has been confirmed. A receipt has been sent to your email.'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('OK'),
              ),
            ],
          ),
        );

        // Navigate back to the home page
        if (mounted) {
          Navigator.of(context).popUntil((route) => route.isFirst);
        }
      }

    } catch (e) {
      // Show error dialog
      if (mounted) {
        await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Booking Failed'),
            content: Text(e.toString()),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final trip = widget.trip;
    final summary = {
      'Origin': trip.route.origin,
      'Destination': trip.route.destination,
      'Date': DateFormat('EEE, MMM d, yyyy').format(trip.schedule.departureTime),
      'Time': DateFormat('h:mm a').format(trip.schedule.departureTime),
      'Company': trip.company.name,
      'Bus Type': trip.bus.type.name.toUpperCase(),
      'Seat': widget.selectedSeat,
      'Amount': 'UGX ${trip.schedule.fee.toStringAsFixed(0)}',
    };

    return Scaffold(
      appBar: AppBar(
        title: const Text('Confirm and Pay'),
      ),
      body: _isProcessing
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Booking Summary', style: Theme.of(context).textTheme.headlineSmall),
                  const SizedBox(height: 16),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: summary.entries.map((entry) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(entry.key, style: const TextStyle(fontWeight: FontWeight.bold)),
                                Text(entry.value),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  Text('Select Payment Method', style: Theme.of(context).textTheme.headlineSmall),
                  const SizedBox(height: 16),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => _createBooking('MTN'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: Colors.yellow[700],
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Pay with MTN'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => _createBooking('Airtel'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: Colors.red[600],
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Pay with Airtel'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => _createBooking('Card'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: Colors.blue[600],
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Pay with Card'),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
