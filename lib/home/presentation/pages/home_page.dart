import 'package:bus_booking/home/presentation/pages/booking_type_selection_page.dart';
import 'package:bus_booking/home/presentation/pages/search_page.dart';
import 'package:bus_booking/models/bus_model.dart';
import 'package:bus_booking/models/company_model.dart';
import 'package:bus_booking/models/pricing_model.dart';
import 'package:bus_booking/models/route_model.dart';
import 'package:bus_booking/models/schedule_model.dart';
import 'package:bus_booking/models/trip_search_result.dart';
import 'package:bus_booking/services/firebase_database_service.dart';
import 'package:bus_booking/utils/custom_widgets.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String? _userFirstname;
  final FirebaseDatabaseService _databaseService = FirebaseDatabaseService();

  @override
  void initState() {
    super.initState();
    _getUserName();
  }

  Future<void> _getUserName() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (doc.exists) {
        setState(() {
          _userFirstname = doc.data()!['FirstName'];
        });
      }
    }
  }

  void _navigateToSearch() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SearchPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Hello, ${_userFirstname ?? 'Guest'}'),
        actions: [
          IconButton(
            onPressed: _navigateToSearch,
            icon: const Icon(Icons.search, size: 22),
            tooltip: 'Search Trips',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Available Trips',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Book your next journey',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Colors.grey.shade600,
                      ),
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _databaseService.getSchedulesStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text('Error: ${snapshot.error}'),
                    ),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return EmptyStateWidget(
                    icon: Icons.event_busy,
                    title: 'No Trips Available',
                    subtitle: 'There are no scheduled trips at the moment. Check back later!',
                    actionText: 'Search Trips',
                    onAction: _navigateToSearch,
                  );
                }

                final schedules = snapshot.data!.docs
                    .map((doc) => ScheduleModel.fromMap(doc.data() as Map<String, dynamic>))
                    .toList();

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                  itemCount: schedules.length,
                  itemBuilder: (context, index) {
                    final schedule = schedules[index];
                    return TripCard(
                      schedule: schedule,
                      databaseService: _databaseService,
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
}

class TripCard extends StatefulWidget {
  final ScheduleModel schedule;
  final FirebaseDatabaseService databaseService;

  const TripCard({
    super.key,
    required this.schedule,
    required this.databaseService,
  });

  @override
  State<TripCard> createState() => _TripCardState();
}

class _TripCardState extends State<TripCard> {
  RouteModel? _route;
  BusModel? _bus;
  CompanyModel? _company;
  PricingModel? _pricing;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTripDetails();
  }

  Future<void> _loadTripDetails() async {
    try {
      // Fetch route
      final routeDoc = await FirebaseFirestore.instance
          .collection('routes')
          .doc(widget.schedule.routeId)
          .get();

      if (!routeDoc.exists) {
        setState(() => _isLoading = false);
        return;
      }

      final route = RouteModel.fromMap(routeDoc.data()!);

      // Fetch bus
      final busDoc = await FirebaseFirestore.instance
          .collection('buses')
          .doc(widget.schedule.busId)
          .get();

      if (!busDoc.exists) {
        setState(() => _isLoading = false);
        return;
      }

      final bus = BusModel.fromMap(busDoc.data()!);

      // Fetch company
      final companyDoc = await FirebaseFirestore.instance
          .collection('companies')
          .doc(bus.companyId)
          .get();

      if (!companyDoc.exists) {
        setState(() => _isLoading = false);
        return;
      }

      final company = CompanyModel.fromMap(companyDoc.data()!);

      // Fetch pricing
      final pricing = await widget.databaseService.getPricing(
        companyId: company.id,
        routeId: route.id,
        busType: bus.type.name,
      );

      if (mounted) {
        setState(() {
          _route = route;
          _bus = bus;
          _company = company;
          _pricing = pricing;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _selectTrip() {
    if (_route == null || _bus == null || _company == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to load trip details'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final trip = TripSearchResult(
      schedule: widget.schedule,
      route: _route!,
      bus: _bus!,
      company: _company!,
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BookingTypeSelectionPage(trip: trip),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return CustomCard(
        margin: const EdgeInsets.only(bottom: 12),
        child: Container(
          height: 120,
          alignment: Alignment.center,
          child: const CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    if (_route == null || _bus == null || _company == null) {
      return const SizedBox.shrink();
    }

    final departureTime = DateFormat('h:mm a').format(widget.schedule.departureTime);
    final arrivalTime = DateFormat('h:mm a').format(widget.schedule.arrivalTime);
    final duration = widget.schedule.arrivalTime.difference(widget.schedule.departureTime);
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final durationText = hours > 0 ? '${hours}h ${minutes}m' : '${minutes}m';

    return CustomCard(
      margin: const EdgeInsets.only(bottom: 12),
      onTap: _selectTrip,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Company and bus info
          Row(
            children: [
              CircleAvatar(
                backgroundColor: Colors.black,
                radius: 18,
                child: Text(
                  _company!.name[0].toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _company!.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(Icons.directions_bus, size: 12, color: Colors.grey.shade600),
                        const SizedBox(width: 4),
                        Text(
                          '${_bus!.numberPlate} • ${_bus!.type.name.toUpperCase()}',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (_pricing != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'UGX ${_pricing!.passengerPrice.toStringAsFixed(0)}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          // Route and time info
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.trip_origin, size: 14),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            _route!.origin,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Padding(
                      padding: const EdgeInsets.only(left: 10),
                      child: Text(
                        departureTime,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                children: [
                  Icon(Icons.arrow_forward, size: 16, color: Colors.grey.shade600),
                  const SizedBox(height: 2),
                  Text(
                    durationText,
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.location_on, size: 14),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            _route!.destination,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Padding(
                      padding: const EdgeInsets.only(left: 10),
                      child: Text(
                        arrivalTime,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Available seats indicator
          StreamBuilder<List<String>>(
            stream: widget.databaseService.getBookedSeats(widget.schedule.id),
            builder: (context, seatSnapshot) {
              final bookedSeats = seatSnapshot.data ?? [];
              final availableSeats = _bus!.totalSeats - bookedSeats.length;

              return Row(
                children: [
                  Icon(
                    Icons.event_seat,
                    size: 13,
                    color: availableSeats > 5 ? Colors.green : Colors.orange,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '$availableSeats seats available',
                    style: TextStyle(
                      fontSize: 11,
                      color: availableSeats > 5 ? Colors.green : Colors.orange,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
