import 'package:bus_booking/models/booking_details_model.dart';
import 'package:bus_booking/services/firebase_database_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class MyTripsPage extends StatefulWidget {
  const MyTripsPage({super.key});

  @override
  State<MyTripsPage> createState() => _MyTripsPageState();
}

class _MyTripsPageState extends State<MyTripsPage> {
  final FirebaseDatabaseService _databaseService = FirebaseDatabaseService();
  late final Future<List<BookingDetailsModel>> _bookingsFuture;

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    _bookingsFuture = _databaseService.getUserBookingDetails(user!.uid);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Trips'),
      ),
      body: FutureBuilder<List<BookingDetailsModel>>(
        future: _bookingsFuture,
        builder: (BuildContext context, AsyncSnapshot<List<BookingDetailsModel>> snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.data == null || snapshot.data!.isEmpty) {
            return const Center(child: Text('No trips found'));
          }

          return ListView.builder(
            itemCount: snapshot.data!.length,
            itemBuilder: (context, index) {
              final bookingDetails = snapshot.data![index];
              return Card(
                margin: const EdgeInsets.all(8.0),
                child: ListTile(
                  title: Text('${bookingDetails.origin} → ${bookingDetails.destination}'),
                  subtitle: Text('${bookingDetails.busCompanyName} - ${bookingDetails.departureTime.toString().substring(0, 16)}'),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('Seat: ${bookingDetails.seatNumber}'),
                      Text('Receipt: ${bookingDetails.receiptNumber.substring(0, 8)}...'),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
