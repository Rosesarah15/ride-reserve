import 'package:bus_booking/models/booking_status.dart';
import 'package:bus_booking/models/bus_model.dart';
import 'package:bus_booking/models/company_model.dart';
import 'package:bus_booking/models/package_booking_model.dart';
import 'package:bus_booking/models/route_model.dart';
import 'package:bus_booking/models/schedule_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class PackageBookingsTab extends StatefulWidget {
  const PackageBookingsTab({super.key});

  @override
  State<PackageBookingsTab> createState() => _PackageBookingsTabState();
}

class _PackageBookingsTabState extends State<PackageBookingsTab> {
  String _selectedStatus = 'All';
  final List<PackageBookingModel> _bookings = [];
  final List<PackageBookingModel> _bufferedBookings = [];
  DocumentSnapshot<Map<String, dynamic>>? _lastDocument;
  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _hasMore = true;

  static const int _pageSize = 4;
  static const int _queryBatchSize = 12;

  @override
  void initState() {
    super.initState();
    _loadMoreBookings(reset: true);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
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
                onChanged: (value) {
                  if (value != null) {
                    _onStatusChanged(value);
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _isLoading && _bookings.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : _bookings.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _selectedStatus == 'All'
                                  ? 'No package bookings found'
                                  : 'No package bookings for this status',
                            ),
                            if (_isLoadingMore)
                              const Padding(
                                padding: EdgeInsets.only(top: 12),
                                child: CircularProgressIndicator(),
                              )
                            else if (_bufferedBookings.isNotEmpty || _hasMore)
                              TextButton(
                                onPressed: () => _loadMoreBookings(),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: const [
                                    Text('Load more'),
                                    SizedBox(width: 4),
                                    Icon(Icons.keyboard_arrow_right),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: () => _loadMoreBookings(reset: true),
                        child: ListView.builder(
                          physics: const AlwaysScrollableScrollPhysics(),
                          itemCount: _bookings.length + 1,
                          itemBuilder: (context, index) {
                            if (index == _bookings.length) {
                              if (_isLoadingMore) {
                                return const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 16),
                                  child: Center(child: CircularProgressIndicator()),
                                );
                              }

                              if (_bufferedBookings.isEmpty && !_hasMore) {
                                return const SizedBox(height: 16);
                              }

                              return Padding(
                                padding: const EdgeInsets.only(top: 12, bottom: 24),
                                child: Align(
                                  alignment: Alignment.centerRight,
                                  child: TextButton(
                                    onPressed: () => _loadMoreBookings(),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: const [
                                        Text('Load more'),
                                        SizedBox(width: 4),
                                        Icon(Icons.keyboard_arrow_right),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            }

                            final booking = _bookings[index];
                            return FutureBuilder<PackageBookingDetails?>(
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
                                      backgroundColor: _getTypeColor(details.booking.packageType),
                                      child: Icon(
                                        _getTypeIcon(details.booking.packageType),
                                        color: Colors.white,
                                      ),
                                    ),
                                    title: Text('${details.origin} → ${details.destination}'),
                                    subtitle: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('${details.companyName} • ${details.packageTypeLabel}'),
                                        Text(DateFormat('MMM d, yyyy h:mm a').format(details.departureTime)),
                                        Text('Sender: ${details.booking.senderName} • Receiver: ${details.booking.receiverName}'),
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
                                        Text('UGX ${details.booking.totalPrice.toStringAsFixed(0)}'),
                                      ],
                                    ),
                                    onTap: () => _showBookingDetails(details),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  void _onStatusChanged(String value) {
    setState(() {
      _selectedStatus = value;
    });
    _loadMoreBookings(reset: true);
  }

  Future<void> _loadMoreBookings({bool reset = false}) async {
    if (reset) {
      if (_isLoading) return;
      setState(() {
        _isLoading = true;
        _isLoadingMore = false;
        _bookings.clear();
        _bufferedBookings.clear();
        _lastDocument = null;
        _hasMore = true;
      });
    } else {
      if (_isLoadingMore) return;
      if (_bufferedBookings.isNotEmpty) {
        final takeCount = _bufferedBookings.length >= _pageSize ? _pageSize : _bufferedBookings.length;
        final toAdd = List<PackageBookingModel>.from(_bufferedBookings.take(takeCount));
        setState(() {
          _bookings.addAll(toAdd);
          _bufferedBookings.removeRange(0, takeCount);
        });
        return;
      }
      if (!_hasMore) return;
      setState(() {
        _isLoadingMore = true;
      });
    }

    try {
      final List<PackageBookingModel> fetched = [];
      var localLastDocument = _lastDocument;
      var localHasMore = _hasMore;

      while (fetched.length < _pageSize && localHasMore) {
        Query<Map<String, dynamic>> query = FirebaseFirestore.instance
            .collection('package_bookings')
            .orderBy('bookingDate', descending: true)
            .limit(_queryBatchSize);

        if (localLastDocument != null) {
          query = query.startAfterDocument(localLastDocument);
        }

        final snapshot = await query.get();

        if (snapshot.docs.isEmpty) {
          localHasMore = false;
          break;
        }

        localLastDocument = snapshot.docs.last;

        final docs = snapshot.docs
            .map((doc) => PackageBookingModel.fromMap(doc.data()))
            .where(_matchesFilters)
            .toList();

        fetched.addAll(docs);

        if (snapshot.docs.length < _queryBatchSize) {
          localHasMore = false;
        }
      }

      if (!mounted) return;

      setState(() {
        _hasMore = localHasMore;
        _lastDocument = localLastDocument;

        if (fetched.isNotEmpty) {
          final takeCount = fetched.length >= _pageSize ? _pageSize : fetched.length;
          _bookings.addAll(fetched.take(takeCount));
          _bufferedBookings.addAll(fetched.skip(takeCount));
        }
      });
    } finally {
      if (!mounted) return;
      setState(() {
        if (reset) {
          _isLoading = false;
        } else {
          _isLoadingMore = false;
        }
      });
    }
  }

  bool _matchesFilters(PackageBookingModel booking) {
    if (_selectedStatus == 'All') {
      return true;
    }
    return booking.status.name == _selectedStatus;
  }

  Future<PackageBookingDetails?> _getBookingDetails(PackageBookingModel booking) async {
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

      return PackageBookingDetails(
        booking: booking,
        schedule: schedule,
        route: route,
        bus: bus,
        company: company,
      );
    } catch (_) {
      return null;
    }
  }

  void _showBookingDetails(PackageBookingDetails details) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Package Booking Details'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Booking ID', details.booking.id),
              _buildDetailRow('Route', '${details.origin} → ${details.destination}'),
              _buildDetailRow('Company', details.companyName),
              _buildDetailRow('Bus', details.busNumberPlate),
              _buildDetailRow('Package Type', details.packageTypeLabel),
              if (details.booking.weightInKg != null)
                _buildDetailRow('Weight', '${details.booking.weightInKg} kg'),
              _buildDetailRow('Sender', '${details.booking.senderName} (${details.booking.senderPhone})'),
              _buildDetailRow('Receiver', '${details.booking.receiverName} (${details.booking.receiverPhone})'),
              if (details.booking.description != null && details.booking.description!.isNotEmpty)
                _buildDetailRow('Description', details.booking.description!),
              _buildDetailRow('Departure', DateFormat('MMM d, yyyy h:mm a').format(details.departureTime)),
              _buildDetailRow('Payment', details.booking.paymentMethod),
              _buildDetailRow('Status', details.booking.status.name.toUpperCase()),
              _buildDetailRow('Amount', 'UGX ${details.booking.totalPrice.toStringAsFixed(0)}'),
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
            width: 110,
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

  Color _getTypeColor(PackageType type) {
    return switch (type) {
      PackageType.parcel => Colors.purple,
      PackageType.luggage => Colors.teal,
    };
  }

  IconData _getTypeIcon(PackageType type) {
    return switch (type) {
      PackageType.parcel => Icons.inventory_2,
      PackageType.luggage => Icons.luggage,
    };
  }
}

class PackageBookingDetails {
  final PackageBookingModel booking;
  final ScheduleModel schedule;
  final RouteModel route;
  final BusModel bus;
  final CompanyModel company;

  PackageBookingDetails({
    required this.booking,
    required this.schedule,
    required this.route,
    required this.bus,
    required this.company,
  });

  String get origin => route.origin;
  String get destination => route.destination;
  String get companyName => company.name;
  String get busNumberPlate => bus.numberPlate;
  DateTime get departureTime => schedule.departureTime;
  String get packageTypeLabel => booking.packageType.name.toUpperCase();
}

