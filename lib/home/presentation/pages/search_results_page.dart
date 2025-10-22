import 'package:bus_booking/home/presentation/pages/booking_type_selection_page.dart';
import 'package:bus_booking/models/trip_search_result.dart';
import 'package:bus_booking/services/firebase_database_service.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class SearchResultsPage extends StatefulWidget {
  final String origin;
  final String destination;
  final DateTime date;

  const SearchResultsPage({
    super.key,
    required this.origin,
    required this.destination,
    required this.date,
  });

  @override
  State<SearchResultsPage> createState() => _SearchResultsPageState();
}

class _SearchResultsPageState extends State<SearchResultsPage> {
  final FirebaseDatabaseService _databaseService = FirebaseDatabaseService();
  late Future<List<TripSearchResult>> _schedulesFuture;

  @override
  void initState() {
    super.initState();
    _schedulesFuture = _databaseService.searchSchedules(
      origin: widget.origin,
      destination: widget.destination,
      date: widget.date,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.origin} to ${widget.destination}'),
      ),
      body: FutureBuilder<List<TripSearchResult>>(
        future: _schedulesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No buses found for the selected route and date.'));
          }

          final results = snapshot.data!;

          return ListView.builder(
            itemCount: results.length,
            itemBuilder: (context, index) {
              final result = results[index];
              final company = result.company;
              final bus = result.bus;
              final schedule = result.schedule;

              return Card(
                margin: const EdgeInsets.all(8.0),
                child: ListTile(
                  leading: CircleAvatar(
                    // Placeholder for company logo
                    child: Text(company.name[0]),
                  ),
                  title: Text(company.name),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${bus.type.name.toUpperCase()} - ${bus.numberPlate}'),
                      Text('Departs: ${DateFormat('h:mm a').format(schedule.departureTime)}'),
                      Text('Arrives: ${DateFormat('h:mm a').format(schedule.arrivalTime)}'),
                    ],
                  ),
                  trailing: Text(
                    'UGX ${schedule.fee.toStringAsFixed(0)}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            BookingTypeSelectionPage(trip: result),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}