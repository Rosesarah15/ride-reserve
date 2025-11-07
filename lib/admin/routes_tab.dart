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
  final List<RouteModel> _routes = [];
  final List<RouteModel> _bufferedRoutes = [];
  DocumentSnapshot<Map<String, dynamic>>? _lastRouteDocument;
  bool _isLoadingRoutes = false;
  bool _isLoadingMoreRoutes = false;
  bool _hasMoreRoutes = true;

  static const int _routePageSize = 6;
  static const int _routeQueryBatchSize = 18;

  @override
  void initState() {
    super.initState();
    _loadMoreRoutes(reset: true);
  }

  @override
  void dispose() {
    _originController.dispose();
    _destinationController.dispose();
    super.dispose();
  }

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

        await _loadMoreRoutes(reset: true);

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

  Future<void> _loadMoreRoutes({bool reset = false}) async {
    if (reset) {
      if (_isLoadingRoutes) return;
      setState(() {
        _isLoadingRoutes = true;
        _isLoadingMoreRoutes = false;
        _routes.clear();
        _bufferedRoutes.clear();
        _lastRouteDocument = null;
        _hasMoreRoutes = true;
      });
    } else {
      if (_isLoadingMoreRoutes) return;

      if (_bufferedRoutes.isNotEmpty) {
        final takeCount = _bufferedRoutes.length >= _routePageSize ? _routePageSize : _bufferedRoutes.length;
        final toAdd = List<RouteModel>.from(_bufferedRoutes.take(takeCount));
        setState(() {
          _routes.addAll(toAdd);
          _bufferedRoutes.removeRange(0, takeCount);
        });
        return;
      }

      if (!_hasMoreRoutes) return;

      setState(() {
        _isLoadingMoreRoutes = true;
      });
    }

    try {
      final List<RouteModel> fetched = [];
      var localLastDocument = _lastRouteDocument;
      var localHasMore = _hasMoreRoutes;

      while (fetched.length < _routePageSize && localHasMore) {
        Query<Map<String, dynamic>> query = FirebaseFirestore.instance
            .collection('routes')
            .orderBy('origin')
            .limit(_routeQueryBatchSize);

        if (localLastDocument != null) {
          query = query.startAfterDocument(localLastDocument);
        }

        final snapshot = await query.get();

        if (snapshot.docs.isEmpty) {
          localHasMore = false;
          break;
        }

        localLastDocument = snapshot.docs.last;

        final docs = snapshot.docs
            .map((doc) => RouteModel.fromMap(doc.data()))
            .toList();

        fetched.addAll(docs);

        if (snapshot.docs.length < _routeQueryBatchSize) {
          localHasMore = false;
        }
      }

      if (!mounted) return;

      setState(() {
        _hasMoreRoutes = localHasMore;
        _lastRouteDocument = localLastDocument;

        if (fetched.isNotEmpty) {
          final takeCount = fetched.length >= _routePageSize ? _routePageSize : fetched.length;
          _routes.addAll(fetched.take(takeCount));
          _bufferedRoutes.addAll(fetched.skip(takeCount));
        }
      });
    } finally {
      if (!mounted) return;
      setState(() {
        if (reset) {
          _isLoadingRoutes = false;
        } else {
          _isLoadingMoreRoutes = false;
        }
      });
    }
  }

  String _formatRouteId(String id) {
    if (id.length > 8) {
      return '${id.substring(0, 8)}...';
    }
    return id;
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
            child: Builder(
              builder: (context) {
                if (_isLoadingRoutes && _routes.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (_routes.isEmpty) {
                  return const EmptyStateWidget(
                    icon: Icons.route,
                    title: 'No routes yet',
                    subtitle: 'Create your first route to get started',
                  );
                }

                final routesSnapshot = List<RouteModel>.from(_routes);
                final showLoadMore = _bufferedRoutes.isNotEmpty || _hasMoreRoutes || _isLoadingMoreRoutes;
                final totalCount = routesSnapshot.length + (showLoadMore ? 1 : 0);

                return RefreshIndicator(
                  onRefresh: () => _loadMoreRoutes(reset: true),
                  child: ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    itemCount: totalCount,
                    itemBuilder: (context, index) {
                      if (index >= routesSnapshot.length) {
                        if (_isLoadingMoreRoutes) {
                          return const Padding(
                            padding: EdgeInsets.symmetric(vertical: 16),
                            child: Center(child: CircularProgressIndicator()),
                          );
                        }

                        if (_bufferedRoutes.isEmpty && !_hasMoreRoutes) {
                          return const SizedBox(height: 24);
                        }

                        return Padding(
                          padding: const EdgeInsets.only(top: 12, bottom: 24),
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: () => _loadMoreRoutes(),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text('Load more'),
                                  SizedBox(width: 4),
                                  Icon(Icons.keyboard_arrow_right),
                                ],
                              ),
                            ),
                          ),
                        );
                      }

                      final route = routesSnapshot[index];
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
                                    'Route ID: ${_formatRouteId(route.id)}',
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
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}