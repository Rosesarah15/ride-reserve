import 'package:bus_booking/models/booking_details_model.dart';
import 'package:flutter/material.dart';

class ReceiptPage extends StatelessWidget {
  final BookingDetailsModel bookingDetails;

  const ReceiptPage({super.key, required this.bookingDetails});

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
            Text('Receipt Number: ${bookingDetails.receiptNumber}'),
            Text('Destination: ${bookingDetails.destination}'),
            Text('Bus Company: ${bookingDetails.busCompanyName}'),
            Text('Departure Time: ${bookingDetails.departureTime}'),
            Text('Amount Paid: UGX ${bookingDetails.fee.toStringAsFixed(0)}'),
          ],
        ),
      ),
    );
  }
}
