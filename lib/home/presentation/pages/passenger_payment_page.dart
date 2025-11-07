import 'package:bus_booking/models/booking_model.dart';
import 'package:bus_booking/models/booking_status.dart';
import 'package:bus_booking/models/notification_model.dart';
import 'package:bus_booking/models/trip_search_result.dart';
import 'package:bus_booking/services/firebase_database_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

class PassengerPaymentPage extends StatefulWidget {
  final TripSearchResult trip;
  final List<String> selectedSeats;
  final double passengerFee;
  final bool hasLuggage;
  final double? luggageWeightInKg;
  final double? luggageFee;

  const PassengerPaymentPage({
    super.key,
    required this.trip,
    required this.selectedSeats,
    required this.passengerFee,
    this.hasLuggage = false,
    this.luggageWeightInKg,
    this.luggageFee,
  });

  @override
  State<PassengerPaymentPage> createState() => _PassengerPaymentPageState();
}

class _PassengerPaymentPageState extends State<PassengerPaymentPage> {
  final FirebaseDatabaseService _databaseService = FirebaseDatabaseService();
  String _selectedPaymentMethod = 'MTN Mobile Money';
  bool _isProcessing = false;

  double get _totalPassengerFee =>
      widget.passengerFee * widget.selectedSeats.length;

  double get _totalFee => _totalPassengerFee + (widget.luggageFee ?? 0);

  Future<void> _processPayment() async {
    setState(() => _isProcessing = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('You must be logged in to book.');
      }

      final booking = BookingModel(
        id: const Uuid().v4(),
        userId: user.uid,
        scheduleId: widget.trip.schedule.id,
        seatNumbers: widget.selectedSeats,
        passengerCount: widget.selectedSeats.length,
        passengerFee: _totalPassengerFee,
        hasLuggage: widget.hasLuggage,
        luggageWeightInKg: widget.luggageWeightInKg,
        luggageFee: widget.luggageFee,
        totalFee: _totalFee,
        paymentMethod: _selectedPaymentMethod,
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
          'passengerCount': booking.passengerCount,
          'paymentMethod': booking.paymentMethod,
          'totalFee': booking.totalFee,
          'hasLuggage': booking.hasLuggage,
          'luggageWeightInKg': booking.luggageWeightInKg,
          'luggageFee': booking.luggageFee,
          'departureTime': widget.trip.schedule.departureTime.toIso8601String(),
          'arrivalTime': widget.trip.schedule.arrivalTime.toIso8601String(),
          'origin': widget.trip.route.origin,
          'destination': widget.trip.route.destination,
          'company': widget.trip.company.name,
          'busNumberPlate': widget.trip.bus.numberPlate,
        },
      );

      await _databaseService.createNotification(notification);

      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green, size: 32),
                SizedBox(width: 12),
                Text('Booking Successful'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Your booking has been confirmed!',
                  style: TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Booking ID',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        booking.id.substring(0, 8).toUpperCase(),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Seats: ${widget.selectedSeats.join(", ")}',
                  style: const TextStyle(fontSize: 14),
                ),
              ],
            ),
            actions: [
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).popUntil((route) => route.isFirst);
                },
                child: const Text('Done'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Booking failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Trip Details',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _DetailRow(
                      icon: Icons.route,
                      label: 'Route',
                      value:
                          '${widget.trip.route.origin} → ${widget.trip.route.destination}',
                    ),
                    const Divider(height: 24),
                    _DetailRow(
                      icon: Icons.business,
                      label: 'Company',
                      value: widget.trip.company.name,
                    ),
                    const Divider(height: 24),
                    _DetailRow(
                      icon: Icons.directions_bus,
                      label: 'Bus',
                      value:
                          '${widget.trip.bus.numberPlate} (${widget.trip.bus.type.name.toUpperCase()})',
                    ),
                    const Divider(height: 24),
                    _DetailRow(
                      icon: Icons.event_seat,
                      label: 'Seats',
                      value: widget.selectedSeats.join(', '),
                    ),
                    const Divider(height: 24),
                    _DetailRow(
                      icon: Icons.access_time,
                      label: 'Departure',
                      value: DateFormat('MMM d, yyyy • h:mm a')
                          .format(widget.trip.schedule.departureTime),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Price Breakdown',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _PriceRow(
                      label:
                          'Passengers (${widget.selectedSeats.length})',
                      amount: _totalPassengerFee,
                    ),
                    if (widget.hasLuggage && widget.luggageFee != null) ...[
                      const SizedBox(height: 12),
                      _PriceRow(
                        label:
                            'Luggage (${widget.luggageWeightInKg} kg)',
                        amount: widget.luggageFee!,
                      ),
                    ],
                    const Divider(height: 24),
                    _PriceRow(
                      label: 'Total',
                      amount: _totalFee,
                      isTotal: true,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Payment Method',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 16),
            _PaymentMethodOption(
              title: 'MTN Mobile Money',
              icon: Icons.phone_android,
              isSelected: _selectedPaymentMethod == 'MTN Mobile Money',
              onTap: () {
                setState(() {
                  _selectedPaymentMethod = 'MTN Mobile Money';
                });
              },
            ),
            const SizedBox(height: 12),
            _PaymentMethodOption(
              title: 'Airtel Money',
              icon: Icons.phone_iphone,
              isSelected: _selectedPaymentMethod == 'Airtel Money',
              onTap: () {
                setState(() {
                  _selectedPaymentMethod = 'Airtel Money';
                });
              },
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue.shade700),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'You will receive a payment prompt on your phone',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.blue.shade700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: ElevatedButton(
            onPressed: _isProcessing ? null : _processPayment,
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 50),
            ),
            child: _isProcessing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Text('Pay UGX ${_totalFee.toStringAsFixed(0)}'),
          ),
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey.shade600),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PriceRow extends StatelessWidget {
  final String label;
  final double amount;
  final bool isTotal;

  const _PriceRow({
    required this.label,
    required this.amount,
    this.isTotal = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isTotal ? 16 : 14,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            color: isTotal ? Colors.black : Colors.grey.shade700,
          ),
        ),
        Text(
          'UGX ${amount.toStringAsFixed(0)}',
          style: TextStyle(
            fontSize: isTotal ? 18 : 14,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _PaymentMethodOption extends StatelessWidget {
  final String title;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _PaymentMethodOption({
    required this.title,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: isSelected ? 4 : 1,
      color: isSelected ? Colors.black : Colors.white,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(
                icon,
                color: isSelected ? Colors.white : Colors.black,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: isSelected ? Colors.white : Colors.black,
                  ),
                ),
              ),
              if (isSelected)
                const Icon(
                  Icons.check_circle,
                  color: Colors.white,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
