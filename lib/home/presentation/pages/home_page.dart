import 'package:bus_booking/home/presentation/pages/payment_page.dart';
import 'package:bus_booking/models/bus_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String? _userName;

  static const List<String> _destinations = <String>[
    'Kampala',
    'Gulu',
    'Mbarara',
    'Jinja',
    'Arua',
  ];

  final List<BusModel> _buses = [
    BusModel(
      id: '1',
      companyName: 'Jaguar',
      destination: 'Kampala',
      departureTime: '08:00 AM',
      arrivalTime: '12:00 PM',
      fee: 50000,
      totalSeats: 60,
      availableSeats: 20,
      busNumberPlate: 'UAS 123P',
      departureDate: DateTime.now(),
    ),
    BusModel(
      id: '2',
      companyName: 'Modern',
      destination: 'Gulu',
      departureTime: '10:00 AM',
      arrivalTime: '04:00 PM',
      fee: 70000,
      totalSeats: 60,
      availableSeats: 10,
      busNumberPlate: 'UAT 456P',
      departureDate: DateTime.now(),
    ),
    BusModel(
      id: '3',
      companyName: 'Global',
      destination: 'Mbarara',
      departureTime: '12:00 PM',
      arrivalTime: '06:00 PM',
      fee: 60000,
      totalSeats: 60,
      availableSeats: 30,
      busNumberPlate: 'UAU 789P',
      departureDate: DateTime.now(),
    ),
  ];

  List<BusModel> _filteredBuses = [];

  @override
  void initState() {
    super.initState();
    _getUserName();
    _filteredBuses = _buses;
  }

  Future<void> _getUserName() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (doc.exists) {
        setState(() {
          _userName = doc.data()!['fullName'];
        });
      }
    }
  }

  void _filterBuses(String destination) {
    setState(() {
      _filteredBuses = _buses.where((bus) => bus.destination.toLowerCase() == destination.toLowerCase()).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Hello, ${_userName ?? 'Guest'}'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Autocomplete<String>(
              optionsBuilder: (TextEditingValue textEditingValue) {
                if (textEditingValue.text == '') {
                  return const Iterable<String>.empty();
                }
                return _destinations.where((String option) {
                  return option.toLowerCase().contains(textEditingValue.text.toLowerCase());
                });
              },
              onSelected: (String selection) {
                _filterBuses(selection);
              },
              fieldViewBuilder: (BuildContext context, TextEditingController textEditingController, FocusNode focusNode, VoidCallback onFieldSubmitted) {
                return TextField(
                  controller: textEditingController,
                  focusNode: focusNode,
                  decoration: const InputDecoration(
                    hintText: 'Enter your destination',
                    prefixIcon: Icon(Icons.search),
                  ),
                );
              },
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                itemCount: _filteredBuses.length,
                itemBuilder: (context, index) {
                  final bus = _filteredBuses[index];
                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => PaymentPage(bus: bus),
                        ),
                      );
                    },
                    child: Card(
                      child: ListTile(
                        title: Text(bus.companyName),
                        subtitle: Text('${bus.departureTime} - ${bus.arrivalTime}'),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('UGX ${bus.fee.toStringAsFixed(0)}'),
                            Text('${bus.availableSeats} seats'),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}