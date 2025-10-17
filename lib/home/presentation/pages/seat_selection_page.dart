import 'package:bus_booking/models/trip_search_result.dart';
import 'package:bus_booking/services/firebase_database_service.dart';
import 'package:flutter/material.dart';
import 'payment_page.dart';

class SeatSelectionPage extends StatefulWidget {
  final TripSearchResult trip;

  const SeatSelectionPage({super.key, required this.trip});

  @override
  State<SeatSelectionPage> createState() => _SeatSelectionPageState();
}

class _SeatSelectionPageState extends State<SeatSelectionPage> {
  final FirebaseDatabaseService _databaseService = FirebaseDatabaseService();
  String? _selectedSeat;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Your Seat'),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<String>>(
              stream: _databaseService.getBookedSeats(widget.trip.schedule.id),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                final bookedSeats = snapshot.data ?? [];
                final totalSeats = widget.trip.bus.totalSeats;

                return GridView.builder(
                  padding: const EdgeInsets.all(16.0),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    crossAxisSpacing: 8.0,
                    mainAxisSpacing: 8.0,
                  ),
                  itemCount: totalSeats,
                  itemBuilder: (context, index) {
                    final seatNumber = (index + 1).toString();
                    final isBooked = bookedSeats.contains(seatNumber);
                    final isSelected = _selectedSeat == seatNumber;

                    Color seatColor;
                    if (isBooked) {
                      seatColor = Colors.red;
                    } else if (isSelected) {
                      seatColor = Colors.orange;
                    } else {
                      seatColor = Colors.green;
                    }

                    return GestureDetector(
                      onTap: () {
                        if (!isBooked) {
                          setState(() {
                            _selectedSeat = seatNumber;
                          });
                        }
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: seatColor,
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        child: Center(
                          child: Text(
                            seatNumber,
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              onPressed: _selectedSeat != null ? () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PaymentPage(trip: widget.trip, selectedSeat: _selectedSeat!),
                  ),
                );
              } : null,
              child: const Text('Continue'),
            ),
          ),
        ],
      ),
    );
  }
}