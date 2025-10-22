import 'package:bus_booking/models/bus_model.dart';
import 'package:bus_booking/models/company_model.dart';
import 'package:bus_booking/services/firebase_database_service.dart';
import 'package:bus_booking/utils/custom_widgets.dart';
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
  bool _isCreating = false;

  Future<void> _createCompany() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isCreating = true);

      try {
        final company = CompanyModel(
          id: const Uuid().v4(),
          name: _nameController.text.trim(),
          license: '', // Placeholder
          logoUrl: '', // Placeholder
          rating: 0.0, // Placeholder
        );
        await _databaseService.createCompany(company);
        _nameController.clear();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Company created successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error creating company: $e'),
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
            title: 'Create New Company',
            subtitle: 'Add bus companies',
            icon: Icons.business,
          ),
          Form(
            key: _formKey,
            child: Column(
              children: [
                CustomTextField(
                  controller: _nameController,
                  labelText: 'Company Name',
                  hintText: 'e.g., Post Bus Uganda',
                  prefixIcon: Icons.business,
                  validator: (value) => value == null || value.isEmpty ? 'Please enter a name' : null,
                ),
                CustomButton(
                  onPressed: _createCompany,
                  text: 'Create Company',
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
            title: 'Existing Companies',
            icon: Icons.apartment,
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _databaseService.getCompaniesStream(),
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
                    icon: Icons.business,
                    title: 'No companies yet',
                    subtitle: 'Create your first company to get started',
                  );
                }

                final companies = snapshot.data!.docs.map((doc) => CompanyModel.fromMap(doc.data() as Map<String, dynamic>)).toList();
                return ListView.builder(
                  itemCount: companies.length,
                  itemBuilder: (context, index) {
                    final company = companies[index];
                    return CustomCard(
                      child: Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: Colors.black,
                            radius: 20,
                            child: Text(
                              company.name[0].toUpperCase(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Text(
                              company.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
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
  BusType _selectedBusType = BusType.ordinary;
  final List<String> _amenities = [];
  final _driverController = TextEditingController();
  bool _isCreating = false;

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
      setState(() => _isCreating = true);

      try {
        final bus = BusModel(
          id: const Uuid().v4(),
          companyId: _selectedCompany!.id,
          numberPlate: _numberPlateController.text.trim(),
          driver: _driverController.text.trim(),
          totalSeats: int.parse(_totalSeatsController.text.trim()),
          type: _selectedBusType,
          amenities: _amenities,
        );
        await _databaseService.createBus(bus);
        _numberPlateController.clear();
        _driverController.clear();
        _totalSeatsController.clear();
        setState(() {
          _amenities.clear();
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Bus registered successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error registering bus: $e'),
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
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(
            title: 'Register New Bus',
            subtitle: 'Add buses to your fleet',
            icon: Icons.directions_bus,
          ),
          Form(
            key: _formKey,
            child: Column(
              children: [
                CustomDropdownField<CompanyModel>(
                  value: _selectedCompany,
                  items: _companies.map((company) {
                    return DropdownMenuItem(value: company, child: Text(company.name));
                  }).toList(),
                  onChanged: (value) => setState(() => _selectedCompany = value),
                  labelText: 'Select Company',
                  prefixIcon: Icons.business,
                  validator: (value) => value == null ? 'Please select a company' : null,
                ),
                CustomDropdownField<BusType>(
                  value: _selectedBusType,
                  items: BusType.values.map((type) {
                    return DropdownMenuItem(value: type, child: Text(type.name.toUpperCase()));
                  }).toList(),
                  onChanged: (value) => setState(() => _selectedBusType = value!),
                  labelText: 'Bus Type',
                  prefixIcon: Icons.category,
                ),
                CustomTextField(
                  controller: _numberPlateController,
                  labelText: 'Number Plate',
                  hintText: 'e.g., UAH 123A',
                  prefixIcon: Icons.pin,
                  validator: (value) => value == null || value.isEmpty ? 'Please enter a number plate' : null,
                ),
                CustomTextField(
                  controller: _totalSeatsController,
                  labelText: 'Total Seats',
                  hintText: 'e.g., 50',
                  prefixIcon: Icons.event_seat,
                  keyboardType: TextInputType.number,
                  validator: (value) => value == null || value.isEmpty ? 'Please enter the number of seats' : null,
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Amenities',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      const SizedBox(height: 8),
                      CheckboxListTile(
                        title: const Text('WiFi'),
                        value: _amenities.contains('WiFi'),
                        contentPadding: EdgeInsets.zero,
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
                        title: const Text('Air Conditioning'),
                        value: _amenities.contains('AC'),
                        contentPadding: EdgeInsets.zero,
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
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                CustomButton(
                  onPressed: _createBus,
                  text: 'Register Bus',
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
            title: 'Existing Buses',
            icon: Icons.directions_bus,
          ),
          StreamBuilder<QuerySnapshot>(
            stream: _databaseService.getBusesStream(),
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
                  icon: Icons.directions_bus,
                  title: 'No buses yet',
                  subtitle: 'Register your first bus to get started',
                );
              }

              final buses = snapshot.data!.docs.map((doc) => BusModel.fromMap(doc.data() as Map<String, dynamic>)).toList();
              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: buses.length,
                itemBuilder: (context, index) {
                  final bus = buses[index];
                  return CustomCard(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
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
                                    bus.numberPlate,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    bus.type.name.toUpperCase(),
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade200,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Text(
                                '${bus.totalSeats} seats',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (bus.amenities.isNotEmpty) ...[
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 6,
                            runSpacing: 4,
                            children: bus.amenities.map((amenity) {
                              return Chip(
                                label: Text(
                                  amenity,
                                  style: const TextStyle(fontSize: 11),
                                ),
                                backgroundColor: Colors.grey.shade100,
                                padding: EdgeInsets.zero,
                                visualDensity: VisualDensity.compact,
                              );
                            }).toList(),
                          ),
                        ],
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}