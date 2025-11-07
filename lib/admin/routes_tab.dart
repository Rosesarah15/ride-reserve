import 'package:bus_booking/models/route_model.dart';
import 'package:bus_booking/services/firebase_database_service.dart';
import 'package:bus_booking/utils/custom_widgets.dart';
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
  bool _isCreating = false;

  Future<void> _createRoute() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isCreating = true);

      try {
        final route = RouteModel(
          id: const Uuid().v4(),
          origin: _originController.text.trim(),
          destination: _destinationController.text.trim(),
        );
        await _databaseService.createRoute(route);
        _originController.clear();
        _destinationController.clear();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Route created successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error creating route: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isCreating = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(
            title: 'Create New Route',
            subtitle: 'Add routes between cities',
            icon: Icons.directions,
          ),
          Form(
            key: _formKey,
            child: Column(
              children: [
                CustomTextField(
                  controller: _originController,
                  labelText: 'Origin City',
                  hintText: 'e.g., Kampala',
                  prefixIcon: Icons.trip_origin,
                  validator: (value) => value == null || value.isEmpty ? 'Please enter an origin' : null,
                ),
                CustomTextField(
                  controller: _destinationController,
                  labelText: 'Destination City',
                  hintText: 'e.g., Mukono',
                  prefixIcon: Icons.location_on,
                  validator: (value) => value == null || value.isEmpty ? 'Please enter a destination' : null,
                ),
                CustomButton(
                  onPressed: _createRoute,
                  text: 'Create Route',
                  icon: Icons.add,
                  isLoading: _isCreating,
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          const Divider(),
          const SizedBox(height: 16),
          const SectionHeader(
            title: 'Existing Routes',
            icon: Icons.route,
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _databaseService.getRoutesStream(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Error: ${snapshot.error}',
                      style: const TextStyle(color: Colors.red),
                    ),
                  );
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const EmptyStateWidget(
                    icon: Icons.route,
                    title: 'No routes yet',
                    subtitle: 'Create your first route to get started',
                  );
                }

                final routes = snapshot.data!.docs.map((doc) => RouteModel.fromMap(doc.data() as Map<String, dynamic>)).toList();
                return ListView.builder(
                  itemCount: routes.length,
                  itemBuilder: (context, index) {
                    final route = routes[index];
                    return CustomCard(
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.black,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.directions_bus,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${route.origin} → ${route.destination}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Route ID: ${route.id.substring(0, 8)}...',
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
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