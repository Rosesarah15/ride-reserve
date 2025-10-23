import 'package:bus_booking/models/booking_model.dart';
import 'package:bus_booking/models/booking_status.dart';
import 'package:bus_booking/models/package_booking_model.dart';
import 'package:bus_booking/services/firebase_database_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

enum DateFilter { today, yesterday, last7Days }

class DashboardTab extends StatefulWidget {
  const DashboardTab({super.key});

  @override
  State<DashboardTab> createState() => _DashboardTabState();
}

class _DashboardTabState extends State<DashboardTab> {
  final FirebaseDatabaseService _databaseService = FirebaseDatabaseService();
  DateFilter _selectedFilter = DateFilter.today;

  DateTime get _startDate {
    final now = DateTime.now();
    switch (_selectedFilter) {
      case DateFilter.today:
        return DateTime(now.year, now.month, now.day);
      case DateFilter.yesterday:
        final yesterday = now.subtract(const Duration(days: 1));
        return DateTime(yesterday.year, yesterday.month, yesterday.day);
      case DateFilter.last7Days:
        return DateTime(now.year, now.month, now.day).subtract(const Duration(days: 6));
    }
  }

  DateTime get _endDate {
    final now = DateTime.now();
    switch (_selectedFilter) {
      case DateFilter.today:
        return DateTime(now.year, now.month, now.day, 23, 59, 59);
      case DateFilter.yesterday:
        final yesterday = now.subtract(const Duration(days: 1));
        return DateTime(yesterday.year, yesterday.month, yesterday.day, 23, 59, 59);
      case DateFilter.last7Days:
        return DateTime(now.year, now.month, now.day, 23, 59, 59);
    }
  }

  Future<Map<String, dynamic>> _fetchDashboardData() async {
    final startOfDay = _startDate;
    final endOfDay = _endDate;

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard', style: TextStyle(fontSize: 18)),
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey.shade50,
            child: CupertinoSegmentedControl<DateFilter>(
              children: {
                DateFilter.today: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  child: Text(
                    'Today',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: _selectedFilter == DateFilter.today
                          ? Colors.white
                          : Colors.black,
                    ),
                  ),
                ),
                DateFilter.yesterday: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  child: Text(
                    'Yesterday',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: _selectedFilter == DateFilter.yesterday
                          ? Colors.white
                          : Colors.black,
                    ),
                  ),
                ),
                DateFilter.last7Days: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  child: Text(
                    'Last 7 Days',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: _selectedFilter == DateFilter.last7Days
                          ? Colors.white
                          : Colors.black,
                    ),
                  ),
                ),
              },
              groupValue: _selectedFilter,
              onValueChanged: (DateFilter value) {
                setState(() {
                  _selectedFilter = value;
                });
              },
              selectedColor: Colors.black,
              unselectedColor: Colors.white,
              borderColor: Colors.grey.shade300,
              pressedColor: Colors.grey.shade200,
            ),
          ),
          Expanded(
            child: FutureBuilder<Map<String, dynamic>>(
              key: ValueKey(_selectedFilter),
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
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Recent Passenger Bookings',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (passengerBookings.isNotEmpty)
                            TextButton.icon(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => AllPassengerBookingsPage(
                                      startDate: _startDate,
                                      endDate: _endDate,
                                    ),
                                  ),
                                );
                              },
                              icon: const Text(
                                'View All',
                                style: TextStyle(fontSize: 13),
                              ),
                              label: const Icon(Icons.arrow_forward, size: 16),
                              style: TextButton.styleFrom(
                                foregroundColor: Colors.black,
                              ),
                            ),
                        ],
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
                        ...passengerBookings.take(2).map(
                          (booking) => _PassengerBookingCard(booking: booking),
                        ),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Recent Package Bookings',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (packageBookings.isNotEmpty)
                            TextButton.icon(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => AllPackageBookingsPage(
                                      startDate: _startDate,
                                      endDate: _endDate,
                                    ),
                                  ),
                                );
                              },
                              icon: const Text(
                                'View All',
                                style: TextStyle(fontSize: 13),
                              ),
                              label: const Icon(Icons.arrow_forward, size: 16),
                              style: TextButton.styleFrom(
                                foregroundColor: Colors.black,
                              ),
                            ),
                        ],
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
                        ...packageBookings.take(2).map(
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
    // Parse value to extract currency and amount
    final hasUGX = value.startsWith('UGX ');
    final displayValue = hasUGX ? value.substring(4) : value;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: Colors.grey.shade300,
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon and title
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 11,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.3,
              ),
            ),
            const SizedBox(height: 6),
            // Main value
            if (hasUGX)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      'UGX ',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      displayValue,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        height: 1.0,
                      ),
                    ),
                  ),
                ],
              )
            else
              Text(
                displayValue,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  height: 1.0,
                ),
              ),
            if (subtitle != null) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: _buildSubtitle(subtitle!),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSubtitle(String subtitle) {
    final hasUGX = subtitle.startsWith('UGX ');
    final displayValue = hasUGX ? subtitle.substring(4) : subtitle;

    if (hasUGX) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            'UGX ',
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey.shade600,
            ),
          ),
          Text(
            displayValue,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade700,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      );
    }

    return Text(
      subtitle,
      style: TextStyle(
        color: Colors.grey.shade600,
        fontSize: 11,
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
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: Colors.grey.shade300,
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row with icon, title, and status
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.person, color: Colors.blue.shade700, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Passenger Booking',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${booking.passengerCount} ${booking.passengerCount == 1 ? "Passenger" : "Passengers"}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                ),
                _StatusChip(status: booking.status),
              ],
            ),
            const SizedBox(height: 16),
            // Details section
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  _InfoRow(
                    icon: Icons.event_seat,
                    label: 'Seats',
                    value: booking.seatNumbers.join(", "),
                  ),
                  if (booking.hasLuggage) ...[
                    const SizedBox(height: 8),
                    _InfoRow(
                      icon: Icons.luggage,
                      label: 'Luggage',
                      value: '${booking.luggageWeightInKg} kg',
                    ),
                  ],
                  const SizedBox(height: 8),
                  _InfoRow(
                    icon: Icons.access_time,
                    label: 'Time',
                    value: DateFormat('h:mm a').format(booking.bookingDate),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            // Amount section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total Amount',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'UGX ',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      booking.totalFee.toStringAsFixed(0),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ],
                ),
              ],
            ),
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
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: Colors.grey.shade300,
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row with icon, title, and status
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.purple.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    booking.packageType == PackageType.parcel
                        ? Icons.inventory_2
                        : Icons.luggage,
                    color: Colors.purple.shade700,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Package Booking',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        booking.packageType.name.toUpperCase(),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                ),
                _StatusChip(status: booking.status),
              ],
            ),
            const SizedBox(height: 16),
            // Sender and Receiver section
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  _InfoRow(
                    icon: Icons.person_outline,
                    label: 'Sender',
                    value: booking.senderName,
                  ),
                  const SizedBox(height: 8),
                  _InfoRow(
                    icon: Icons.person,
                    label: 'Receiver',
                    value: booking.receiverName,
                  ),
                  if (booking.weightInKg != null) ...[
                    const SizedBox(height: 8),
                    _InfoRow(
                      icon: Icons.scale,
                      label: 'Weight',
                      value: '${booking.weightInKg} kg',
                    ),
                  ],
                  const SizedBox(height: 8),
                  _InfoRow(
                    icon: Icons.access_time,
                    label: 'Time',
                    value: DateFormat('h:mm a').format(booking.bookingDate),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            // Amount section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total Amount',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'UGX ',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      booking.totalPrice.toStringAsFixed(0),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          icon,
          size: 14,
          color: Colors.grey.shade600,
        ),
        const SizedBox(width: 8),
        Text(
          '$label:',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
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

// All Passenger Bookings Page
class AllPassengerBookingsPage extends StatelessWidget {
  final DateTime startDate;
  final DateTime endDate;

  const AllPassengerBookingsPage({
    super.key,
    required this.startDate,
    required this.endDate,
  });

  Future<List<BookingModel>> _fetchPassengerBookings() async {
    final startOfDay = startDate;
    final endOfDay = endDate;

    final snapshot = await FirebaseFirestore.instance
        .collection('bookings')
        .where('bookingDate', isGreaterThanOrEqualTo: startOfDay.toIso8601String())
        .where('bookingDate', isLessThanOrEqualTo: endOfDay.toIso8601String())
        .get();

    return snapshot.docs
        .map((doc) => BookingModel.fromMap(doc.data()))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Passenger Bookings', style: TextStyle(fontSize: 16)),
      ),
      body: FutureBuilder<List<BookingModel>>(
        future: _fetchPassengerBookings(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error}'),
            );
          }

          final bookings = snapshot.data ?? [];

          if (bookings.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.person_outline, size: 64, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  const Text(
                    'No Passenger Bookings',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'No passenger bookings found for this date',
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: bookings.length,
            itemBuilder: (context, index) {
              return _PassengerBookingCard(booking: bookings[index]);
            },
          );
        },
      ),
    );
  }
}

// All Package Bookings Page
class AllPackageBookingsPage extends StatelessWidget {
  final DateTime startDate;
  final DateTime endDate;

  const AllPackageBookingsPage({
    super.key,
    required this.startDate,
    required this.endDate,
  });

  Future<List<PackageBookingModel>> _fetchPackageBookings() async {
    final startOfDay = startDate;
    final endOfDay = endDate;

    final snapshot = await FirebaseFirestore.instance
        .collection('package_bookings')
        .where('bookingDate', isGreaterThanOrEqualTo: startOfDay.toIso8601String())
        .where('bookingDate', isLessThanOrEqualTo: endOfDay.toIso8601String())
        .get();

    return snapshot.docs
        .map((doc) => PackageBookingModel.fromMap(doc.data()))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Package Bookings', style: TextStyle(fontSize: 16)),
      ),
      body: FutureBuilder<List<PackageBookingModel>>(
        future: _fetchPackageBookings(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error}'),
            );
          }

          final bookings = snapshot.data ?? [];

          if (bookings.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  const Text(
                    'No Package Bookings',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'No package bookings found for this date',
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: bookings.length,
            itemBuilder: (context, index) {
              return _PackageBookingCard(booking: bookings[index]);
            },
          );
        },
      ),
    );
  }
}
