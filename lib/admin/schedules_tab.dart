import 'package:bus_booking/models/bus_model.dart';
import 'package:bus_booking/models/route_model.dart';
import 'package:bus_booking/models/schedule_model.dart';
import 'package:bus_booking/services/firebase_database_service.dart';
import 'package:bus_booking/utils/custom_widgets.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

class ScheduleEntryData {
  TimeOfDay? departureTime;
  TimeOfDay? arrivalTime;
  BusModel? selectedBus;
}

class SchedulesTab extends StatefulWidget {
  const SchedulesTab({super.key});

  @override
  State<SchedulesTab> createState() => _SchedulesTabState();
}

class _SchedulesTabState extends State<SchedulesTab> {
  final FirebaseDatabaseService _databaseService = FirebaseDatabaseService();
  final _formKey = GlobalKey<FormState>();

  List<RouteModel> _routes = [];
  List<BusModel> _buses = [];
  RouteModel? _selectedRoute;

  final List<ScheduleEntryData> _scheduleEntries = [];
  bool _isCreating = false;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    final routesSnapshot = await _databaseService.getRoutesStream().first;
    final busesSnapshot = await _databaseService.getBusesStream().first;
    setState(() {
      _routes = routesSnapshot.docs.map((doc) => RouteModel.fromMap(doc.data() as Map<String, dynamic>)).toList();
      _buses = busesSnapshot.docs.map((doc) => BusModel.fromMap(doc.data() as Map<String, dynamic>)).toList();
    });
  }

  void _addScheduleEntry() {
    setState(() {
      _scheduleEntries.add(ScheduleEntryData());
    });
  }

  Future<void> _createSchedules() async {
    if (_formKey.currentState!.validate()) {
      if (_scheduleEntries.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please add at least one schedule entry'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      setState(() => _isCreating = true);

      try {
        final List<ScheduleModel> schedules = [];
        // Use epoch date (1970-01-01) as base since only time matters for recurring schedules
        final baseDate = DateTime(1970, 1, 1);

        for (final entry in _scheduleEntries) {
          if (entry.departureTime != null && entry.arrivalTime != null && entry.selectedBus != null) {
            final departureDateTime = DateTime(baseDate.year, baseDate.month, baseDate.day, entry.departureTime!.hour, entry.departureTime!.minute);
            final arrivalDateTime = DateTime(baseDate.year, baseDate.month, baseDate.day, entry.arrivalTime!.hour, entry.arrivalTime!.minute);

            schedules.add(ScheduleModel(
              id: const Uuid().v4(),
              routeId: _selectedRoute!.id,
              busId: entry.selectedBus!.id,
              departureTime: departureDateTime,
              arrivalTime: arrivalDateTime,
              fee: 0.0, // Fee is determined by pricing configuration
            ));
          }
        }

        if (schedules.isNotEmpty) {
          await _databaseService.createSchedules(schedules);

          // Clear form
          setState(() {
            _scheduleEntries.clear();
            _selectedRoute = null;
          });

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('${schedules.length} schedule(s) created successfully'),
                backgroundColor: Colors.green,
              ),
            );
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Please complete all schedule entry fields'),
                backgroundColor: Colors.orange,
              ),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error creating schedules: $e'),
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
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionHeader(
              title: 'Create Recurring Schedules',
              subtitle: 'Add daily bus schedules for routes',
              icon: Icons.schedule,
            ),
            CustomDropdownField<RouteModel>(
              value: _selectedRoute,
              items: _routes.map((route) {
                return DropdownMenuItem(value: route, child: Text('${route.origin} → ${route.destination}'));
              }).toList(),
              onChanged: (value) => setState(() => _selectedRoute = value),
              labelText: 'Select Route',
              prefixIcon: Icons.route,
              validator: (value) => value == null ? 'Please select a route' : null,
            ),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, size: 20, color: Colors.blue.shade700),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Schedules run daily. Set departure/arrival times that repeat every day.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue.shade700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            CustomButton(
              onPressed: _addScheduleEntry,
              text: 'Add Time/Fee Schedule',
              icon: Icons.add,
              height: 45,
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: _scheduleEntries.length,
                itemBuilder: (context, index) {
                  return ScheduleEntryCard(
                    entryData: _scheduleEntries[index],
                    buses: _buses,
                    onRemove: () {
                      setState(() {
                        _scheduleEntries.removeAt(index);
                      });
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            CustomButton(
              onPressed: _createSchedules,
              text: 'Create Schedules',
              isLoading: _isCreating,
            ),
          ],
        ),
      ),
    );
  }
}

class ScheduleEntryCard extends StatefulWidget {
  final ScheduleEntryData entryData;
  final List<BusModel> buses;
  final VoidCallback onRemove;

  const ScheduleEntryCard({super.key, required this.entryData, required this.buses, required this.onRemove});

  @override
  State<ScheduleEntryCard> createState() => _ScheduleEntryCardState();
}

class _ScheduleEntryCardState extends State<ScheduleEntryCard> {
  late TextEditingController _departureController;
  late TextEditingController _arrivalController;

  @override
  void initState() {
    super.initState();
    _departureController = TextEditingController();
    _arrivalController = TextEditingController();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Update controllers when we have context available
    if (widget.entryData.departureTime != null) {
      _departureController.text = widget.entryData.departureTime!.format(context);
    }
    if (widget.entryData.arrivalTime != null) {
      _arrivalController.text = widget.entryData.arrivalTime!.format(context);
    }
  }

  @override
  void dispose() {
    _departureController.dispose();
    _arrivalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CustomCard(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Schedule Entry',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              IconButton(
                onPressed: widget.onRemove,
                icon: const Icon(Icons.close, size: 20),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 12),
          CustomTextField(
            controller: _departureController,
            readOnly: true,
            onTap: () async {
              final picked = await showTimePicker(
                context: context,
                initialTime: widget.entryData.departureTime ?? TimeOfDay.now(),
              );
              if (picked != null) {
                setState(() {
                  widget.entryData.departureTime = picked;
                  _departureController.text = picked.format(context);
                });
              }
            },
            labelText: 'Departure Time',
            hintText: 'Select departure time',
            prefixIcon: Icons.access_time,
          ),
          CustomTextField(
            controller: _arrivalController,
            readOnly: true,
            onTap: () async {
              final picked = await showTimePicker(
                context: context,
                initialTime: widget.entryData.arrivalTime ?? TimeOfDay.now(),
              );
              if (picked != null) {
                setState(() {
                  widget.entryData.arrivalTime = picked;
                  _arrivalController.text = picked.format(context);
                });
              }
            },
            labelText: 'Arrival Time',
            hintText: 'Select arrival time',
            prefixIcon: Icons.access_time_filled,
          ),
          CustomDropdownField<BusModel>(
            value: widget.entryData.selectedBus,
            items: widget.buses.map((bus) {
              return DropdownMenuItem(value: bus, child: Text(bus.numberPlate));
            }).toList(),
            onChanged: (value) => setState(() => widget.entryData.selectedBus = value),
            labelText: 'Select Bus',
            prefixIcon: Icons.directions_bus,
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, size: 18, color: Colors.grey.shade700),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Pricing is set in the Pricing tab based on route and bus type',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
