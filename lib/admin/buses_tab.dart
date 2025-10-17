import 'package:bus_booking/models/bus_model.dart';
import 'package:bus_booking/models/company_model.dart';
import 'package:bus_booking/services/firebase_database_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

class BusesTab extends StatefulWidget {
  const BusesTab({super.key});

  @override
  State<BusesTab> createState() => _BusesTabState();
}

class _BusesTabState extends State<BusesTab> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Companies'),
            Tab(text: 'Buses'),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: const [
              CompaniesSubTab(),
              BusesSubTab(),
            ],
          ),
        ),
      ],
    );
  }
}

class CompaniesSubTab extends StatefulWidget {
  const CompaniesSubTab({super.key});

  @override
  State<CompaniesSubTab> createState() => _CompaniesSubTabState();
}

class _CompaniesSubTabState extends State<CompaniesSubTab> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final FirebaseDatabaseService _databaseService = FirebaseDatabaseService();

  Future<void> _createCompany() async {
    if (_formKey.currentState!.validate()) {
      final company = CompanyModel(
        id: const Uuid().v4(),
        name: _nameController.text,
        logoUrl: '', // Placeholder
        rating: 0.0, // Placeholder
      );
      await _databaseService.createCompany(company);
      _nameController.clear();
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
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Company Name'),
                  validator: (value) => value!.isEmpty ? 'Please enter a name' : null,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _createCompany,
                  child: const Text('Create Company'),
                ),
              ],
            ),
          ),
          const Divider(height: 32),
          Text('Existing Companies', style: Theme.of(context).textTheme.headlineSmall),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _databaseService.getCompaniesStream(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Text('Something went wrong');
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final companies = snapshot.data!.docs.map((doc) => CompanyModel.fromMap(doc.data() as Map<String, dynamic>)).toList();
                return ListView.builder(
                  itemCount: companies.length,
                  itemBuilder: (context, index) {
                    final company = companies[index];
                    return ListTile(
                      title: Text(company.name),
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

class BusesSubTab extends StatefulWidget {
  const BusesSubTab({super.key});

  @override
  State<BusesSubTab> createState() => _BusesSubTabState();
}

class _BusesSubTabState extends State<BusesSubTab> {
  final _formKey = GlobalKey<FormState>();
  final FirebaseDatabaseService _databaseService = FirebaseDatabaseService();
  final _numberPlateController = TextEditingController();
  final _totalSeatsController = TextEditingController();

  List<CompanyModel> _companies = [];
  CompanyModel? _selectedCompany;
  BusType _selectedBusType = BusType.standard;
  final List<String> _amenities = [];

  @override
  void initState() {
    super.initState();
    _fetchCompanies();
  }

  Future<void> _fetchCompanies() async {
    final snapshot = await _databaseService.getCompaniesStream().first;
    setState(() {
      _companies = snapshot.docs.map((doc) => CompanyModel.fromMap(doc.data() as Map<String, dynamic>)).toList();
    });
  }

  Future<void> _createBus() async {
    if (_formKey.currentState!.validate()) {
      final bus = BusModel(
        id: const Uuid().v4(),
        companyId: _selectedCompany!.id,
        numberPlate: _numberPlateController.text,
        totalSeats: int.parse(_totalSeatsController.text),
        type: _selectedBusType,
        amenities: _amenities,
      );
      await _databaseService.createBus(bus);
      _numberPlateController.clear();
      _totalSeatsController.clear();
      setState(() {
        _amenities.clear();
      });
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
                DropdownButtonFormField<CompanyModel>(
                  value: _selectedCompany,
                  items: _companies.map((company) {
                    return DropdownMenuItem(value: company, child: Text(company.name));
                  }).toList(),
                  onChanged: (value) => setState(() => _selectedCompany = value),
                  decoration: const InputDecoration(labelText: 'Company'),
                  validator: (value) => value == null ? 'Please select a company' : null,
                ),
                DropdownButtonFormField<BusType>(
                  value: _selectedBusType,
                  items: BusType.values.map((type) {
                    return DropdownMenuItem(value: type, child: Text(type.name.toUpperCase()));
                  }).toList(),
                  onChanged: (value) => setState(() => _selectedBusType = value!),
                  decoration: const InputDecoration(labelText: 'Bus Type'),
                ),
                TextFormField(
                  controller: _numberPlateController,
                  decoration: const InputDecoration(labelText: 'Number Plate'),
                  validator: (value) => value!.isEmpty ? 'Please enter a number plate' : null,
                ),
                TextFormField(
                  controller: _totalSeatsController,
                  decoration: const InputDecoration(labelText: 'Total Seats'),
                  keyboardType: TextInputType.number,
                  validator: (value) => value!.isEmpty ? 'Please enter the number of seats' : null,
                ),
                // Amenities Checkboxes (simplified)
                CheckboxListTile(
                  title: const Text('WiFi'),
                  value: _amenities.contains('WiFi'),
                  onChanged: (value) {
                    setState(() {
                      if (value!) {
                        _amenities.add('WiFi');
                      } else {
                        _amenities.remove('WiFi');
                      }
                    });
                  },
                ),
                 CheckboxListTile(
                  title: const Text('AC'),
                  value: _amenities.contains('AC'),
                  onChanged: (value) {
                    setState(() {
                      if (value!) {
                        _amenities.add('AC');
                      } else {
                        _amenities.remove('AC');
                      }
                    });
                  },
                ),
                const SizedBox(height: 16),
                ElevatedButton(onPressed: _createBus, child: const Text('Create Bus')),
              ],
            ),
          ),
          const Divider(height: 32),
          Text('Existing Buses', style: Theme.of(context).textTheme.headlineSmall),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _databaseService.getBusesStream(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Text('Something went wrong');
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final buses = snapshot.data!.docs.map((doc) => BusModel.fromMap(doc.data() as Map<String, dynamic>)).toList();
                return ListView.builder(
                  itemCount: buses.length,
                  itemBuilder: (context, index) {
                    final bus = buses[index];
                    return ListTile(
                      title: Text(bus.numberPlate),
                      subtitle: Text(bus.type.name.toUpperCase()),
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