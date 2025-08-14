import 'package:bus_booking/home/presentation/pages/bus_booking_page.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const ApplicationEntry());
}

class ApplicationEntry extends StatelessWidget {
  const ApplicationEntry({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ride Reserve',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.black),
        ),
      home: const RideReservePage(),
    );
  }
}
