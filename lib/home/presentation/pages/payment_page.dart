import 'package:bus_booking/home/presentation/pages/receipt_page.dart';
import 'package:bus_booking/models/booking_model.dart';
import 'package:bus_booking/models/bus_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

enum PaymentMethod {
  airtelMoney,
  mtnMobileMoney,
  creditDebitCard,
}

class PaymentPage extends StatefulWidget {
  final BusModel bus;

  const PaymentPage({super.key, required this.bus});

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  PaymentMethod? _paymentMethod = PaymentMethod.airtelMoney;

  Future<void> _pay() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      // Handle user not logged in
      return;
    }

 final booking = BookingModel(
  id: FirebaseFirestore.instance.collection('bookings').doc().id,
  userId: user.uid,
  busId: widget.bus.id,
  destination: widget.bus.destination,
  busCompanyName: widget.bus.companyName,  // ✅ Correct
  busNumberPlate: widget.bus.busNumberPlate,
  departureTime: widget.bus.departureTime,
  fee: widget.bus.fee,  // ✅ Correct
  paymentMethod: _paymentMethod?.name ?? 'airtelMoney',  // ✅ Add missing required field
  paymentStatus: 'pending',  // ✅ Add missing required field
  receiptNumber: 'BK-${DateTime.now().millisecondsSinceEpoch}',
  bookingDate: DateTime.now(),
  departureDate: widget.bus.departureDate,  // ✅ Add missing required field
  status: BookingStatus.pending,  // ✅ Add missing required field
);

    await FirebaseFirestore.instance.collection('bookings').doc(booking.id).set(booking.toMap());

    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => ReceiptPage(booking: booking)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Destination: ${widget.bus.destination}'),
            Text('Bus Company: ${widget.bus.companyName}'),
            Text('Departure Time: ${widget.bus.departureTime}'),
            Text('Fee: UGX ${widget.bus.fee.toStringAsFixed(0)}'),
            const SizedBox(height: 20),
            const Text('Select Payment Method:', style: TextStyle(fontWeight: FontWeight.bold)),
            RadioListTile<PaymentMethod>(
              title: const Text('Airtel Money'),
              value: PaymentMethod.airtelMoney,
              groupValue: _paymentMethod,
              onChanged: (PaymentMethod? value) {
                setState(() {
                  _paymentMethod = value;
                });
              },
            ),
            RadioListTile<PaymentMethod>(
              title: const Text('MTN Mobile Money'),
              value: PaymentMethod.mtnMobileMoney,
              groupValue: _paymentMethod,
              onChanged: (PaymentMethod? value) {
                setState(() {
                  _paymentMethod = value;
                });
              },
            ),
            RadioListTile<PaymentMethod>(
              title: const Text('Credit/Debit Card'),
              value: PaymentMethod.creditDebitCard,
              groupValue: _paymentMethod,
              onChanged: (PaymentMethod? value) {
                setState(() {
                  _paymentMethod = value;
                });
              },
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _pay,
              child: const Text('Pay'),
            ),
          ],
        ),
      ),
    );
  }
}
