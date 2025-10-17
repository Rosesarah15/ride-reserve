
import 'package:bus_booking/home/presentation/pages/search_results_page.dart';
import 'package:bus_booking/services/firebase_database_service.dart';
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
  String? _selectedOrigin;
  String? _selectedDestination;
  DateTime? _selectedDate;

  List<String> _origins = [];
  List<String> _destinations = [];

  final FirebaseDatabaseService _databaseService = FirebaseDatabaseService();

  @override
  void initState() {
    super.initState();
    _getUserName();
    _getLocations();
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

  Future<void> _getLocations() async {
    final destinations = await _databaseService.getDestinations();
    final origins = await _databaseService.getOrigins();
    setState(() {
      _destinations = destinations;
      _origins = origins;
    });
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  void _search() {
    if (_selectedOrigin != null && _selectedDestination != null && _selectedDate != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => SearchResultsPage(
            origin: _selectedOrigin!,
            destination: _selectedDestination!,
            date: _selectedDate!,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Hello, ${_userFirstname ?? 'Guest'}'),
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
                return _origins.where((String option) {
                  return option.toLowerCase().contains(textEditingValue.text.toLowerCase());
                });
              },
              onSelected: (String selection) {
                setState(() {
                  _selectedOrigin = selection;
                });
              },
              fieldViewBuilder: (BuildContext context, TextEditingController textEditingController, FocusNode focusNode, VoidCallback onFieldSubmitted) {
                return TextField(
                  controller: textEditingController,
                  focusNode: focusNode,
                  decoration: const InputDecoration(
                    hintText: 'Enter your origin',
                    prefixIcon: Icon(Icons.location_on),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
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
                setState(() {
                  _selectedDestination = selection;
                });
              },
              fieldViewBuilder: (BuildContext context, TextEditingController textEditingController, FocusNode focusNode, VoidCallback onFieldSubmitted) {
                return TextField(
                  controller: textEditingController,
                  focusNode: focusNode,
                  decoration: const InputDecoration(
                    hintText: 'Enter your destination',
                    prefixIcon: Icon(Icons.location_on),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            TextField(
              readOnly: true,
              onTap: () => _selectDate(context),
              decoration: InputDecoration(
                hintText: _selectedDate == null ? 'Select a date' : DateFormat('yyyy-MM-dd').format(_selectedDate!),
                prefixIcon: const Icon(Icons.calendar_today),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _search,
              child: const Text('Search'),
            ),
          ],
        ),
      ),
    );
  }
}
