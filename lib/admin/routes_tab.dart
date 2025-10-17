import 'package:bus_booking/models/route_model.dart';
import 'package:bus_booking/services/firebase_database_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

class RoutesTab extends StatefulWidget {
  const RoutesTab({super.key});

  @override
  State<RoutesTab> createState() => _RoutesTabState();
}

class _RoutesTabState extends State<RoutesTab> {
  final _formKey = GlobalKey<FormState>();
  final _originController = TextEditingController();
  final _destinationController = TextEditingController();
  final FirebaseDatabaseService _databaseService = FirebaseDatabaseService();

  Future<void> _createRoute() async {
    if (_formKey.currentState!.validate()) {
      final route = RouteModel(
        id: const Uuid().v4(),
        origin: _originController.text,
        destination: _destinationController.text,
      );
      await _databaseService.createRoute(route);
      _originController.clear();
      _destinationController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Form(
            key: _formKey,
            child: Column(
              children: [
                TextFormField(
                  controller: _originController,
                  decoration: const InputDecoration(labelText: 'Origin'),
                  validator: (value) => value!.isEmpty ? 'Please enter an origin' : null,
                ),
                TextFormField(
                  controller: _destinationController,
                  decoration: const InputDecoration(labelText: 'Destination'),
                  validator: (value) => value!.isEmpty ? 'Please enter a destination' : null,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _createRoute,
                  child: const Text('Create Route'),
                ),
              ],
            ),
          ),
          const Divider(height: 32),
          Text('Existing Routes', style: Theme.of(context).textTheme.headlineSmall),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _databaseService.getRoutesStream(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Text('Something went wrong');
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final routes = snapshot.data!.docs.map((doc) => RouteModel.fromMap(doc.data() as Map<String, dynamic>)).toList();
                return ListView.builder(
                  itemCount: routes.length,
                  itemBuilder: (context, index) {
                    final route = routes[index];
                    return ListTile(
                      title: Text('${route.origin} to ${route.destination}'),
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