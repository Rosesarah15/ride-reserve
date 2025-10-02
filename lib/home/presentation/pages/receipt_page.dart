import 'package:bus_booking/models/booking_model.dart';
import 'package:flutter/material.dart';

class ReceiptPage extends StatelessWidget {
  final BookingModel booking;

  const ReceiptPage({super.key, required this.booking});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Receipt'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Receipt Number: ${booking.receiptNumber}'),
            Text('Destination: ${booking.destination}'),
            Text('Bus Company: ${booking.busCompanyName}'),
            Text('Departure Time: ${booking.departureTime}'),
            Text('Amount Paid: UGX ${booking.fee.toStringAsFixed(0)}'),
          ],
        ),
      ),
    );
  }
}
