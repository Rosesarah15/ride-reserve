import 'package:bus_booking/models/booking_model.dart';
import 'package:bus_booking/models/booking_status.dart';
import 'package:bus_booking/models/package_booking_model.dart';
import 'package:bus_booking/services/firebase_database_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DashboardTab extends StatefulWidget {
  const DashboardTab({super.key});

  @override
  State<DashboardTab> createState() => _DashboardTabState();
}

class _DashboardTabState extends State<DashboardTab> {
  final FirebaseDatabaseService _databaseService = FirebaseDatabaseService();
  DateTime _selectedDate = DateTime.now();

  Future<Map<String, dynamic>> _fetchDashboardData() async {
    final startOfDay = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
    );
    final endOfDay = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      23,
      59,
      59,
    );

    // Fetch passenger bookings
    final passengerBookingsSnapshot = await FirebaseFirestore.instance
        .collection('bookings')
        .where('bookingDate',
            isGreaterThanOrEqualTo: startOfDay.toIso8601String())
        .where('bookingDate', isLessThanOrEqualTo: endOfDay.toIso8601String())
        .get();

    final passengerBookings = passengerBookingsSnapshot.docs
        .map((doc) => BookingModel.fromMap(doc.data()))
        .toList();

    // Fetch package bookings
    final packageBookingsSnapshot = await FirebaseFirestore.instance
        .collection('package_bookings')
        .where('bookingDate',
            isGreaterThanOrEqualTo: startOfDay.toIso8601String())
        .where('bookingDate', isLessThanOrEqualTo: endOfDay.toIso8601String())
        .get();

    final packageBookings = packageBookingsSnapshot.docs
        .map((doc) => PackageBookingModel.fromMap(doc.data()))
        .toList();

    // Calculate totals
    final totalPassengerRevenue = passengerBookings.fold<double>(
      0,
      (sum, booking) => sum + booking.totalFee,
    );

    final totalPackageRevenue = packageBookings.fold<double>(
      0,
      (sum, booking) => sum + booking.totalPrice,
    );

    final totalRevenue = totalPassengerRevenue + totalPackageRevenue;
    final totalBookings = passengerBookings.length + packageBookings.length;

    return {
      'passengerBookings': passengerBookings,
      'packageBookings': packageBookings,
      'totalPassengerRevenue': totalPassengerRevenue,
      'totalPackageRevenue': totalPackageRevenue,
      'totalRevenue': totalRevenue,
      'totalBookings': totalBookings,
    };
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey.shade100,
            child: Row(
              children: [
                const Icon(Icons.calendar_today),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    DateFormat('EEEE, MMMM d, yyyy').format(_selectedDate),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () => _selectDate(context),
                  icon: const Icon(Icons.edit_calendar),
                  label: const Text('Change Date'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: FutureBuilder<Map<String, dynamic>>(
              key: ValueKey(_selectedDate),
              future: _fetchDashboardData(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text('Error: ${snapshot.error}'),
                  );
                }

                final data = snapshot.data!;
                final totalRevenue = data['totalRevenue'] as double;
                final totalBookings = data['totalBookings'] as int;
                final passengerBookings =
                    data['passengerBookings'] as List<BookingModel>;
                final packageBookings =
                    data['packageBookings'] as List<PackageBookingModel>;

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _SummaryCard(
                              title: 'Total Revenue',
                              value: 'UGX ${totalRevenue.toStringAsFixed(0)}',
                              icon: Icons.attach_money,
                              color: Colors.green,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _SummaryCard(
                              title: 'Total Bookings',
                              value: totalBookings.toString(),
                              icon: Icons.book_online,
                              color: Colors.blue,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _SummaryCard(
                              title: 'Passenger Bookings',
                              value: passengerBookings.length.toString(),
                              subtitle: 'UGX ${data['totalPassengerRevenue']}',
                              icon: Icons.person,
                              color: Colors.orange,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _SummaryCard(
                              title: 'Package Bookings',
                              value: packageBookings.length.toString(),
                              subtitle: 'UGX ${data['totalPackageRevenue']}',
                              icon: Icons.inventory_2,
                              color: Colors.purple,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'Recent Passenger Bookings',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (passengerBookings.isEmpty)
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Text(
                              'No passenger bookings today',
                              style: TextStyle(color: Colors.grey.shade600),
                            ),
                          ),
                        )
                      else
                        ...passengerBookings.map(
                          (booking) => _PassengerBookingCard(booking: booking),
                        ),
                      const SizedBox(height: 24),
                      const Text(
                        'Recent Package Bookings',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (packageBookings.isEmpty)
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Text(
                              'No package bookings today',
                              style: TextStyle(color: Colors.grey.shade600),
                            ),
                          ),
                        )
                      else
                        ...packageBookings.map(
                          (booking) => _PackageBookingCard(booking: booking),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final String? subtitle;
  final IconData icon;
  final Color color;

  const _SummaryCard({
    required this.title,
    required this.value,
    this.subtitle,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      color: Colors.grey.shade700,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 4),
              Text(
                subtitle!,
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 12,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _PassengerBookingCard extends StatelessWidget {
  final BookingModel booking;

  const _PassengerBookingCard({required this.booking});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.blue.shade100,
          child: const Icon(Icons.person, color: Colors.blue),
        ),
        title: Text(
          '${booking.passengerCount} Passenger(s)',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Seats: ${booking.seatNumbers.join(", ")}'),
            if (booking.hasLuggage)
              Text('Luggage: ${booking.luggageWeightInKg} kg'),
            Text(
              DateFormat('h:mm a').format(booking.bookingDate),
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              'UGX ${booking.totalFee.toStringAsFixed(0)}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 4),
            _StatusChip(status: booking.status),
          ],
        ),
      ),
    );
  }
}

class _PackageBookingCard extends StatelessWidget {
  final PackageBookingModel booking;

  const _PackageBookingCard({required this.booking});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.purple.shade100,
          child: Icon(
            booking.packageType == PackageType.parcel
                ? Icons.inventory_2
                : Icons.luggage,
            color: Colors.purple,
          ),
        ),
        title: Text(
          booking.packageType.name.toUpperCase(),
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('From: ${booking.senderName}'),
            Text('To: ${booking.receiverName}'),
            if (booking.weightInKg != null)
              Text('Weight: ${booking.weightInKg} kg'),
            Text(
              DateFormat('h:mm a').format(booking.bookingDate),
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              'UGX ${booking.totalPrice.toStringAsFixed(0)}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 4),
            _StatusChip(status: booking.status),
          ],
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final BookingStatus status;

  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final Color color = switch (status) {
      BookingStatus.confirmed => Colors.green,
      BookingStatus.pending => Colors.orange,
      BookingStatus.cancelled => Colors.red,
      BookingStatus.completed => Colors.blue,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status.name.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
