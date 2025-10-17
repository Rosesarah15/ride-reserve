
import 'package:bus_booking/models/bus_model.dart';
import 'package:bus_booking/models/route_model.dart';
import 'package:bus_booking/models/schedule_model.dart';
import 'package:bus_booking/services/firebase_database_service.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

class ScheduleEntryData {
  TimeOfDay? departureTime;
  TimeOfDay? arrivalTime;
  String fee = '';
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
  DateTime? _selectedDate;

  final List<ScheduleEntryData> _scheduleEntries = [];

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
      final List<ScheduleModel> schedules = [];
      for (final entry in _scheduleEntries) {
        if (entry.departureTime != null && entry.arrivalTime != null && entry.fee.isNotEmpty && entry.selectedBus != null) {
          final departureDateTime = DateTime(_selectedDate!.year, _selectedDate!.month, _selectedDate!.day, entry.departureTime!.hour, entry.departureTime!.minute);
          final arrivalDateTime = DateTime(_selectedDate!.year, _selectedDate!.month, _selectedDate!.day, entry.arrivalTime!.hour, entry.arrivalTime!.minute);

          schedules.add(ScheduleModel(
            id: const Uuid().v4(),
            routeId: _selectedRoute!.id,
            busId: entry.selectedBus!.id,
            departureTime: departureDateTime,
            arrivalTime: arrivalDateTime,
            fee: double.parse(entry.fee),
          ));
        }
      }
      if (schedules.isNotEmpty) {
        await _databaseService.createSchedules(schedules);
        // Clear form
        setState(() {
          _scheduleEntries.clear();
          _selectedRoute = null;
          _selectedDate = null;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            DropdownButtonFormField<RouteModel>(
              value: _selectedRoute,
              items: _routes.map((route) {
                return DropdownMenuItem(value: route, child: Text('${route.origin} to ${route.destination}'));
              }).toList(),
              onChanged: (value) => setState(() => _selectedRoute = value),
              decoration: const InputDecoration(labelText: 'Route'),
              validator: (value) => value == null ? 'Please select a route' : null,
            ),
            TextFormField(
              readOnly: true,
              onTap: () async {
                final picked = await showDatePicker(context: context, initialDate: DateTime.now(), firstDate: DateTime.now(), lastDate: DateTime(2101));
                if (picked != null) {
                  setState(() => _selectedDate = picked);
                }
              },
              decoration: InputDecoration(labelText: _selectedDate == null ? 'Select Date' : _selectedDate.toString().substring(0, 10)),
              validator: (value) => _selectedDate == null ? 'Please select a date' : null,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _addScheduleEntry,
              icon: const Icon(Icons.add),
              label: const Text('Add Time/Fee Schedule'),
            ),
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
            ElevatedButton(onPressed: _createSchedules, child: const Text('Create Schedules')),
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
  late TextEditingController _feeController;

  @override
  void initState() {
    super.initState();
    _feeController = TextEditingController(text: widget.entryData.fee);
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [IconButton(onPressed: widget.onRemove, icon: const Icon(Icons.close))],
            ),
            TextFormField(
              readOnly: true,
              onTap: () async {
                final picked = await showTimePicker(context: context, initialTime: TimeOfDay.now());
                if (picked != null) {
                  setState(() => widget.entryData.departureTime = picked);
                }
              },
              decoration: InputDecoration(labelText: widget.entryData.departureTime == null ? 'Departure Time' : widget.entryData.departureTime!.format(context)),
            ),
            TextFormField(
              readOnly: true,
              onTap: () async {
                final picked = await showTimePicker(context: context, initialTime: TimeOfDay.now());
                if (picked != null) {
                  setState(() => widget.entryData.arrivalTime = picked);
                }
              },
              decoration: InputDecoration(labelText: widget.entryData.arrivalTime == null ? 'Arrival Time' : widget.entryData.arrivalTime!.format(context)),
            ),
            TextFormField(
              controller: _feeController,
              decoration: const InputDecoration(labelText: 'Fee'),
              keyboardType: TextInputType.number,
              onChanged: (value) => widget.entryData.fee = value,
            ),
            DropdownButtonFormField<BusModel>(
              value: widget.entryData.selectedBus,
              items: widget.buses.map((bus) {
                return DropdownMenuItem(value: bus, child: Text(bus.numberPlate));
              }).toList(),
              onChanged: (value) => setState(() => widget.entryData.selectedBus = value),
              decoration: const InputDecoration(labelText: 'Bus'),
            ),
          ],
        ),
      ),
    );
  }
}
