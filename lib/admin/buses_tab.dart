import 'dart:async';

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
  final List<CompanyModel> _companies = [];
  final List<CompanyModel> _bufferedCompanies = [];
  DocumentSnapshot<Map<String, dynamic>>? _lastCompanyDocument;
  bool _isLoadingCompanies = false;
  bool _isLoadingMoreCompanies = false;
  bool _hasMoreCompanies = true;

  static const int _companyPageSize = 4;
  static const int _companyQueryBatchSize = 18;

  Future<void> _createCompany() async {
    debugPrint('[CompaniesSubTab] Attempting to create company with name: ${_nameController.text}');
    if (_formKey.currentState!.validate()) {
      debugPrint('[CompaniesSubTab] Form validation passed');
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
        debugPrint('[CompaniesSubTab] Company created: ${company.id}');
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
        debugPrint('[CompaniesSubTab] Error creating company: $e');
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
    } else {
      debugPrint('[CompaniesSubTab] Form validation failed');
    }
  }

  @override
  void initState() {
    super.initState();
    _loadMoreCompanies(reset: true);
  }

  Future<void> _loadMoreCompanies({bool reset = false}) async {
    if (reset) {
      if (_isLoadingCompanies) return;
      setState(() {
        _isLoadingCompanies = true;
        _isLoadingMoreCompanies = false;
        _companies.clear();
        _bufferedCompanies.clear();
        _lastCompanyDocument = null;
        _hasMoreCompanies = true;
      });
    } else {
      if (_isLoadingMoreCompanies) return;

      if (_bufferedCompanies.isNotEmpty) {
        final takeCount = _bufferedCompanies.length >= _companyPageSize ? _companyPageSize : _bufferedCompanies.length;
        final toAdd = List<CompanyModel>.from(_bufferedCompanies.take(takeCount));
        setState(() {
          _companies.addAll(toAdd);
          _bufferedCompanies.removeRange(0, takeCount);
        });
        return;
      }

      if (!_hasMoreCompanies) return;

      setState(() {
        _isLoadingMoreCompanies = true;
      });
    }

    try {
      final List<CompanyModel> fetched = [];
      var localLastDocument = _lastCompanyDocument;
      var localHasMore = _hasMoreCompanies;

      while (fetched.length < _companyPageSize && localHasMore) {
        Query<Map<String, dynamic>> query = FirebaseFirestore.instance
            .collection('companies')
            .orderBy('name')
            .limit(_companyQueryBatchSize);

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
            .map((doc) => CompanyModel.fromMap(doc.data()))
            .toList();

        fetched.addAll(docs);

        if (snapshot.docs.length < _companyQueryBatchSize) {
          localHasMore = false;
        }
      }

      if (!mounted) return;

      setState(() {
        _hasMoreCompanies = localHasMore;
        _lastCompanyDocument = localLastDocument;

        if (fetched.isNotEmpty) {
          final takeCount = fetched.length >= _companyPageSize ? _companyPageSize : fetched.length;
          _companies.addAll(fetched.take(takeCount));
          _bufferedCompanies.addAll(fetched.skip(takeCount));
        }
      });
    } finally {
      if (!mounted) return;
      setState(() {
        if (reset) {
          _isLoadingCompanies = false;
        } else {
          _isLoadingMoreCompanies = false;
        }
      });
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
            child: Builder(
              builder: (context) {
                if (_isLoadingCompanies && _companies.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (_companies.isEmpty) {
                  return const EmptyStateWidget(
                    icon: Icons.business,
                    title: 'No companies yet',
                    subtitle: 'Create your first company to get started',
                  );
                }

                final companiesSnapshot = List<CompanyModel>.from(_companies);
                final showLoadMore = _bufferedCompanies.isNotEmpty || _hasMoreCompanies || _isLoadingMoreCompanies;
                final totalCount = companiesSnapshot.length + (showLoadMore ? 1 : 0);

                return RefreshIndicator(
                  onRefresh: () => _loadMoreCompanies(reset: true),
                  child: ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    itemCount: totalCount,
                    itemBuilder: (context, index) {
                      if (index >= companiesSnapshot.length) {
                        if (_isLoadingMoreCompanies) {
                          return const Padding(
                            padding: EdgeInsets.symmetric(vertical: 16),
                            child: Center(child: CircularProgressIndicator()),
                          );
                        }

                        if (_bufferedCompanies.isEmpty && !_hasMoreCompanies) {
                          return const SizedBox(height: 24);
                        }

                        return Padding(
                          padding: const EdgeInsets.only(top: 12, bottom: 24),
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: () => _loadMoreCompanies(),
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

                      final company = companiesSnapshot[index];
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
  final List<BusModel> _buses = [];
  final List<BusModel> _bufferedBuses = [];
  DocumentSnapshot<Map<String, dynamic>>? _lastBusDocument;
  bool _isLoadingBuses = false;
  bool _isLoadingMoreBuses = false;
  bool _hasMoreBuses = true;
  StreamSubscription<QuerySnapshot>? _companiesStreamSubscription;

  static const int _busPageSize = 4;
  static const int _busQueryBatchSize = 12;
  static const List<Map<String, String>> _amenityOptions = [
    {'label': 'WiFi', 'value': 'WiFi'},
    {'label': 'Air Conditioning', 'value': 'AC'},
    {'label': 'Spacious seats', 'value': 'Spacious seats'},
    {'label': 'TV', 'value': 'TV'},
    {'label': 'Charging ports', 'value': 'Charging ports'},
    {'label': 'Snacks', 'value': 'Snacks'},
  ];

  @override
  void initState() {
    super.initState();
    _subscribeToCompanies();
    _loadMoreBuses(reset: true);
  }

  void _subscribeToCompanies() {
    _companiesStreamSubscription = _databaseService.getCompaniesStream().listen((snapshot) {
      final companies = snapshot.docs
          .map((doc) => CompanyModel.fromMap(doc.data() as Map<String, dynamic>))
          .toList();

      setState(() {
        _companies = companies;

        if (_selectedCompany != null) {
          _selectedCompany = _companies.firstWhere(
            (company) => company.id == _selectedCompany!.id,
            orElse: () => _selectedCompany!,
          );
        }
      });
    });
  }

  @override
  void dispose() {
    _companiesStreamSubscription?.cancel();
    _numberPlateController.dispose();
    _totalSeatsController.dispose();
    _driverController.dispose();
    super.dispose();
  }

  Future<void> _loadMoreBuses({bool reset = false}) async {
    if (reset) {
      if (_isLoadingBuses) return;
      setState(() {
        _isLoadingBuses = true;
        _isLoadingMoreBuses = false;
        _buses.clear();
        _bufferedBuses.clear();
        _lastBusDocument = null;
        _hasMoreBuses = true;
      });
    } else {
      if (_isLoadingMoreBuses) return;

      if (_bufferedBuses.isNotEmpty) {
        final takeCount = _bufferedBuses.length >= _busPageSize ? _busPageSize : _bufferedBuses.length;
        final toAdd = List<BusModel>.from(_bufferedBuses.take(takeCount));
        setState(() {
          _buses.addAll(toAdd);
          _bufferedBuses.removeRange(0, takeCount);
        });
        return;
      }

      if (!_hasMoreBuses) return;

      setState(() {
        _isLoadingMoreBuses = true;
      });
    }

    try {
      final List<BusModel> fetched = [];
      var localLastDocument = _lastBusDocument;
      var localHasMore = _hasMoreBuses;

      while (fetched.length < _busPageSize && localHasMore) {
        Query<Map<String, dynamic>> query = FirebaseFirestore.instance
            .collection('buses')
            .orderBy('numberPlate')
            .limit(_busQueryBatchSize);

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
            .map((doc) => BusModel.fromMap(doc.data()))
            .toList();

        fetched.addAll(docs);

        if (snapshot.docs.length < _busQueryBatchSize) {
          localHasMore = false;
        }
      }

      if (!mounted) return;

      setState(() {
        _hasMoreBuses = localHasMore;
        _lastBusDocument = localLastDocument;

        if (fetched.isNotEmpty) {
          final takeCount = fetched.length >= _busPageSize ? _busPageSize : fetched.length;
          _buses.addAll(fetched.take(takeCount));
          _bufferedBuses.addAll(fetched.skip(takeCount));
        }
      });
    } catch (e) {
      debugPrint('[BusesSubTab] Error loading buses: $e');
    } finally {
      if (!mounted) return;
      setState(() {
        if (reset) {
          _isLoadingBuses = false;
        } else {
          _isLoadingMoreBuses = false;
        }
      });
    }
  }

  Future<void> _createBus() async {
    if (_formKey.currentState!.validate()) {
      debugPrint('[BusesSubTab] Form validation passed');
      setState(() => _isCreating = true);

      try {
        final formattedNumberPlate = _numberPlateController.text.trim().toUpperCase().replaceAll(RegExp(r'\s+'), ' ');
        _numberPlateController.text = formattedNumberPlate;

        debugPrint('[BusesSubTab] Selected company: ${_selectedCompany?.id}');
        final bus = BusModel(
          id: const Uuid().v4(),
          companyId: _selectedCompany!.id,
          numberPlate: formattedNumberPlate,
          driver: _driverController.text.trim(),
          totalSeats: int.parse(_totalSeatsController.text.trim()),
          type: _selectedBusType,
          amenities: _amenities,
        );
        debugPrint('[BusesSubTab] Creating bus with plate ${bus.numberPlate}');
        await _databaseService.createBus(bus);
        debugPrint('[BusesSubTab] Bus created successfully');
        _numberPlateController.clear();
        _driverController.clear();
        _totalSeatsController.clear();
        setState(() {
          _amenities.clear();
        });

        await _loadMoreBuses(reset: true);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Bus registered successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        debugPrint('[BusesSubTab] Error registering bus: $e');
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
    } else {
      debugPrint('[BusesSubTab] Form validation failed');
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
                      ..._amenityOptions.map(
                        (option) => Column(
                          children: [
                            CheckboxListTile(
                              title: Text(option['label']!),
                              value: _amenities.contains(option['value']!),
                              contentPadding: EdgeInsets.zero,
                              dense: true,
                              onChanged: (value) {
                                setState(() {
                                  if (value!) {
                                    if (!_amenities.contains(option['value']!)) {
                                      _amenities.add(option['value']!);
                                    }
                                  } else {
                                    _amenities.remove(option['value']!);
                                  }
                                });
                              },
                            ),
                            const SizedBox(height: 10),
                          ],
                        ),
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
          Builder(
            builder: (context) {
              if (_isLoadingBuses && _buses.isEmpty) {
                return const Center(child: CircularProgressIndicator());
              }

              if (_buses.isEmpty) {
                return const EmptyStateWidget(
                  icon: Icons.directions_bus,
                  title: 'No buses yet',
                  subtitle: 'Register your first bus to get started',
                );
              }

              final companyById = {for (final company in _companies) company.id: company};

              return Column(
                children: [
                  ..._buses.map((bus) {
                    final companyName = companyById[bus.companyId]?.name ?? 'Unknown Company';
                    return CustomCard(
                      padding: const EdgeInsets.all(14),
                      margin: const EdgeInsets.only(bottom: 12),
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
                                      companyName,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
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
                            spacing: 4,
                            runSpacing: 2,
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
                  }).toList(),
                  if (_isLoadingMoreBuses)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (_bufferedBuses.isNotEmpty || _hasMoreBuses)
                    Padding(
                      padding: const EdgeInsets.only(top: 12, bottom: 24),
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () => _loadMoreBuses(),
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
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}