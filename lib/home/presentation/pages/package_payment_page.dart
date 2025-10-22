import 'package:bus_booking/models/booking_status.dart';
import 'package:bus_booking/models/package_booking_model.dart';
import 'package:bus_booking/models/trip_search_result.dart';
import 'package:bus_booking/services/firebase_database_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

class PackagePaymentPage extends StatefulWidget {
  final TripSearchResult trip;
  final PackageType packageType;
  final String senderName;
  final String senderPhone;
  final String receiverName;
  final String receiverPhone;
  final String description;
  final double? weightInKg;
  final double totalPrice;

  const PackagePaymentPage({
    super.key,
    required this.trip,
    required this.packageType,
    required this.senderName,
    required this.senderPhone,
    required this.receiverName,
    required this.receiverPhone,
    required this.description,
    this.weightInKg,
    required this.totalPrice,
  });

  @override
  State<PackagePaymentPage> createState() => _PackagePaymentPageState();
}

class _PackagePaymentPageState extends State<PackagePaymentPage> {
  final FirebaseDatabaseService _databaseService = FirebaseDatabaseService();
  String _selectedPaymentMethod = 'MTN Mobile Money';
  bool _isProcessing = false;

  Future<void> _processPayment() async {
    setState(() => _isProcessing = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('You must be logged in to book.');
      }

      final packageBooking = PackageBookingModel(
        id: const Uuid().v4(),
        userId: user.uid,
        scheduleId: widget.trip.schedule.id,
        packageType: widget.packageType,
        weightInKg: widget.weightInKg,
        totalPrice: widget.totalPrice,
        paymentMethod: _selectedPaymentMethod,
        status: BookingStatus.confirmed,
        bookingDate: DateTime.now(),
        senderName: widget.senderName,
        senderPhone: widget.senderPhone,
        receiverName: widget.receiverName,
        receiverPhone: widget.receiverPhone,
        description: widget.description.isEmpty ? null : widget.description,
      );

      await _databaseService.createPackageBooking(packageBooking);

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
                  'Your package booking has been confirmed.',
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
                        packageBooking.id.substring(0, 8).toUpperCase(),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
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
              'Package Details',
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
                      icon: Icons.inventory_2,
                      label: 'Package Type',
                      value: widget.packageType.name.toUpperCase(),
                    ),
                    if (widget.weightInKg != null) ...[
                      const Divider(height: 24),
                      _DetailRow(
                        icon: Icons.scale,
                        label: 'Weight',
                        value: '${widget.weightInKg} kg',
                      ),
                    ],
                    const Divider(height: 24),
                    _DetailRow(
                      icon: Icons.route,
                      label: 'Route',
                      value:
                          '${widget.trip.route.origin} → ${widget.trip.route.destination}',
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
              'Contact Details',
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
                      icon: Icons.person,
                      label: 'Sender',
                      value: '${widget.senderName} (${widget.senderPhone})',
                    ),
                    const Divider(height: 24),
                    _DetailRow(
                      icon: Icons.person_outline,
                      label: 'Receiver',
                      value:
                          '${widget.receiverName} (${widget.receiverPhone})',
                    ),
                    if (widget.description.isNotEmpty) ...[
                      const Divider(height: 24),
                      _DetailRow(
                        icon: Icons.description,
                        label: 'Description',
                        value: widget.description,
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Payment',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Total Amount',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'UGX ${widget.totalPrice.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
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
                : Text('Pay UGX ${widget.totalPrice.toStringAsFixed(0)}'),
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
      crossAxisAlignment: CrossAxisAlignment.start,
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
