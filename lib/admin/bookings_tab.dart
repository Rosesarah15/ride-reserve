import 'package:bus_booking/models/booking_details_model.dart';
import 'package:bus_booking/models/booking_model.dart';
import 'package:bus_booking/models/booking_status.dart';
import 'package:bus_booking/models/bus_model.dart';
import 'package:bus_booking/models/company_model.dart';
import 'package:bus_booking/models/route_model.dart';
import 'package:bus_booking/models/schedule_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class BookingsTab extends StatefulWidget {
  const BookingsTab({super.key});

  @override
  State<BookingsTab> createState() => _BookingsTabState();
}

class _BookingsTabState extends State<BookingsTab> {
  String _selectedStatus = 'All';

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // Status filter
          Row(
            children: [
              const Text('Filter by Status: '),
              const SizedBox(width: 16),
              DropdownButton<String>(
                value: _selectedStatus,
                items: const [
                  DropdownMenuItem(value: 'All', child: Text('All')),
                  DropdownMenuItem(value: 'confirmed', child: Text('Confirmed')),
                  DropdownMenuItem(value: 'pending', child: Text('Pending')),
                  DropdownMenuItem(value: 'cancelled', child: Text('Cancelled')),
                  DropdownMenuItem(value: 'completed', child: Text('Completed')),
                ],
                onChanged: (value) => setState(() => _selectedStatus = value!),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('bookings')
                  .orderBy('bookingDate', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.data == null || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('No bookings found'));
                }

                final bookings = snapshot.data!.docs
                    .map((doc) => BookingModel.fromMap(doc.data() as Map<String, dynamic>))
                    .toList();

                // Filter by status
                final filteredBookings = _selectedStatus == 'All'
                    ? bookings
                    : bookings.where((booking) => booking.status.name == _selectedStatus).toList();

                return ListView.builder(
                  itemCount: filteredBookings.length,
                  itemBuilder: (context, index) {
                    final booking = filteredBookings[index];
                    return FutureBuilder<BookingDetailsModel?>(
                      future: _getBookingDetails(booking),
                      builder: (context, detailsSnapshot) {
                        if (detailsSnapshot.connectionState == ConnectionState.waiting) {
                          return const ListTile(
                            leading: CircularProgressIndicator(),
                            title: Text('Loading...'),
                          );
                        }

                        final details = detailsSnapshot.data;
                        if (details == null) {
                          return ListTile(
                            title: Text('Booking ID: ${booking.id}'),
                            subtitle: const Text('Unable to load details'),
                          );
                        }

                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: _getStatusColor(booking.status),
                              child: Icon(
                                _getStatusIcon(booking.status),
                                color: Colors.white,
                              ),
                            ),
                            title: Text('${details.origin} → ${details.destination}'),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('${details.busCompanyName} - Seats ${details.seatNumbers.join(", ")}'),
                                Text('${DateFormat('MMM d, yyyy h:mm a').format(details.departureTime)}'),
                                Text('Receipt: ${details.receiptNumber.substring(0, 8)}...'),
                              ],
                            ),
                            trailing: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  booking.status.name.toUpperCase(),
                                  style: TextStyle(
                                    color: _getStatusColor(booking.status),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text('UGX ${details.fee.toStringAsFixed(0)}'),
                              ],
                            ),
                            onTap: () => _showBookingDetails(details),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<BookingDetailsModel?> _getBookingDetails(BookingModel booking) async {
    try {
      final scheduleDoc = await FirebaseFirestore.instance
          .collection('schedules')
          .doc(booking.scheduleId)
          .get();
      if (!scheduleDoc.exists) return null;
      final schedule = ScheduleModel.fromMap(scheduleDoc.data()!);

      final routeDoc = await FirebaseFirestore.instance
          .collection('routes')
          .doc(schedule.routeId)
          .get();
      if (!routeDoc.exists) return null;
      final route = RouteModel.fromMap(routeDoc.data()!);

      final busDoc = await FirebaseFirestore.instance
          .collection('buses')
          .doc(schedule.busId)
          .get();
      if (!busDoc.exists) return null;
      final bus = BusModel.fromMap(busDoc.data()!);

      final companyDoc = await FirebaseFirestore.instance
          .collection('companies')
          .doc(bus.companyId)
          .get();
      if (!companyDoc.exists) return null;
      final company = CompanyModel.fromMap(companyDoc.data()!);

      return BookingDetailsModel(
        booking: booking,
        schedule: schedule,
        route: route,
        bus: bus,
        company: company,
      );
    } catch (e) {
      return null;
    }
  }

  Color _getStatusColor(BookingStatus status) {
    switch (status) {
      case BookingStatus.confirmed:
        return Colors.green;
      case BookingStatus.pending:
        return Colors.orange;
      case BookingStatus.cancelled:
        return Colors.red;
      case BookingStatus.completed:
        return Colors.blue;
    }
  }

  IconData _getStatusIcon(BookingStatus status) {
    switch (status) {
      case BookingStatus.confirmed:
        return Icons.check_circle;
      case BookingStatus.pending:
        return Icons.access_time;
      case BookingStatus.cancelled:
        return Icons.cancel;
      case BookingStatus.completed:
        return Icons.done_all;
    }
  }

  void _showBookingDetails(BookingDetailsModel details) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Booking Details'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Receipt', details.receiptNumber),
              _buildDetailRow('Route', '${details.origin} → ${details.destination}'),
              _buildDetailRow('Company', details.busCompanyName),
              _buildDetailRow('Bus', details.busNumberPlate),
              _buildDetailRow('Seats', details.seatNumbers.join(", ")),
              _buildDetailRow('Departure', DateFormat('MMM d, yyyy h:mm a').format(details.departureTime)),
              _buildDetailRow('Arrival', DateFormat('MMM d, yyyy h:mm a').format(details.arrivalTime)),
              _buildDetailRow('Payment', details.paymentMethod),
              _buildDetailRow('Status', details.status.name.toUpperCase()),
              _buildDetailRow('Amount', 'UGX ${details.fee.toStringAsFixed(0)}'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
