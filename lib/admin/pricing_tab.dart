import 'package:bus_booking/models/company_model.dart';
import 'package:bus_booking/models/pricing_model.dart';
import 'package:bus_booking/models/route_model.dart';
import 'package:bus_booking/services/firebase_database_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

class PricingTab extends StatefulWidget {
  const PricingTab({super.key});

  @override
  State<PricingTab> createState() => _PricingTabState();
}

class _PricingTabState extends State<PricingTab> {
  final FirebaseDatabaseService _databaseService = FirebaseDatabaseService();
  String? _selectedCompanyId;
  List<CompanyModel> _companies = [];

  @override
  void initState() {
    super.initState();
    _loadCompanies();
  }

  Future<void> _loadCompanies() async {
    final snapshot = await FirebaseFirestore.instance.collection('companies').get();
    setState(() {
      _companies = snapshot.docs
          .map((doc) => CompanyModel.fromMap(doc.data()))
          .toList();
      if (_companies.isNotEmpty && _selectedCompanyId == null) {
        _selectedCompanyId = _companies.first.id;
      }
    });
  }

  void _showAddEditPricingDialog({PricingModel? pricing}) {
    if (_selectedCompanyId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add a company first'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AddEditPricingDialog(
        pricing: pricing,
        companyId: _selectedCompanyId!,
        databaseService: _databaseService,
      ),
    );
  }

  Future<void> _deletePricing(String pricingId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Pricing'),
        content: const Text('Are you sure you want to delete this pricing configuration?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _databaseService.deletePricing(pricingId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Pricing deleted successfully'),
              backgroundColor: Colors.black,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          if (_companies.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.grey.shade100,
              child: Row(
                children: [
                  const Text(
                    'Select Company:',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: DropdownButton<String>(
                      value: _selectedCompanyId,
                      isExpanded: true,
                      items: _companies.map((company) {
                        return DropdownMenuItem(
                          value: company.id,
                          child: Text(company.name),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedCompanyId = value;
                        });
                      },
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
            child: _selectedCompanyId == null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.attach_money,
                          size: 64,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 16),
                        const Text('No companies available'),
                        const SizedBox(height: 8),
                        const Text('Add a company first to configure pricing'),
                      ],
                    ),
                  )
                : StreamBuilder<QuerySnapshot>(
                    stream: _databaseService.getPricingStreamByCompany(_selectedCompanyId!),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      if (snapshot.hasError) {
                        return Center(child: Text('Error: ${snapshot.error}'));
                      }

                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.attach_money,
                                size: 64,
                                color: Colors.grey.shade400,
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'No pricing configured',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Text('Add pricing for routes'),
                            ],
                          ),
                        );
                      }

                      final pricingList = snapshot.data!.docs
                          .map((doc) => PricingModel.fromMap(doc.data() as Map<String, dynamic>))
                          .toList();

                      return ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: pricingList.length,
                        itemBuilder: (context, index) {
                          final pricing = pricingList[index];
                          return _PricingCard(
                            pricing: pricing,
                            onEdit: () => _showAddEditPricingDialog(pricing: pricing),
                            onDelete: () => _deletePricing(pricing.id),
                          );
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: _selectedCompanyId == null
          ? null
          : FloatingActionButton.extended(
              onPressed: () => _showAddEditPricingDialog(),
              icon: const Icon(Icons.add),
              label: const Text('Add Pricing'),
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
            ),
    );
  }
}

class _PricingCard extends StatelessWidget {
  final PricingModel pricing;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _PricingCard({
    required this.pricing,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: pricing.busType == BusTypeForPricing.vip
                        ? Colors.amber.shade100
                        : Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    pricing.busType.name.toUpperCase(),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: pricing.busType == BusTypeForPricing.vip
                          ? Colors.amber.shade900
                          : Colors.black,
                    ),
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: onEdit,
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: onDelete,
                ),
              ],
            ),
            const SizedBox(height: 12),
            FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance
                  .collection('routes')
                  .doc(pricing.routeId)
                  .get(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Text('Loading route...');
                }
                final route = RouteModel.fromMap(
                  snapshot.data!.data() as Map<String, dynamic>,
                );
                return Text(
                  '${route.origin} → ${route.destination}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                );
              },
            ),
            const Divider(height: 24),
            _PriceRow(
              icon: Icons.person,
              label: 'Passenger',
              price: pricing.passengerPrice,
            ),
            const SizedBox(height: 8),
            _PriceRow(
              icon: Icons.inventory_2,
              label: 'Parcel (Standard)',
              price: pricing.parcelStandardPrice,
            ),
            const SizedBox(height: 8),
            _PriceRow(
              icon: Icons.luggage,
              label: 'Luggage (per kg)',
              price: pricing.luggagePricePerKg,
            ),
          ],
        ),
      ),
    );
  }
}

class _PriceRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final double price;

  const _PriceRow({
    required this.icon,
    required this.label,
    required this.price,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.grey.shade600),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(color: Colors.grey.shade700),
        ),
        const Spacer(),
        Text(
          'UGX ${price.toStringAsFixed(0)}',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ],
    );
  }
}

class AddEditPricingDialog extends StatefulWidget {
  final PricingModel? pricing;
  final String companyId;
  final FirebaseDatabaseService databaseService;

  const AddEditPricingDialog({
    super.key,
    this.pricing,
    required this.companyId,
    required this.databaseService,
  });

  @override
  State<AddEditPricingDialog> createState() => _AddEditPricingDialogState();
}

class _AddEditPricingDialogState extends State<AddEditPricingDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _passengerPriceController;
  late TextEditingController _parcelPriceController;
  late TextEditingController _luggagePriceController;

  String? _selectedRouteId;
  BusTypeForPricing _selectedBusType = BusTypeForPricing.ordinary;
  List<RouteModel> _routes = [];
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _passengerPriceController = TextEditingController(
      text: widget.pricing?.passengerPrice.toString() ?? '',
    );
    _parcelPriceController = TextEditingController(
      text: widget.pricing?.parcelStandardPrice.toString() ?? '',
    );
    _luggagePriceController = TextEditingController(
      text: widget.pricing?.luggagePricePerKg.toString() ?? '',
    );

    if (widget.pricing != null) {
      _selectedRouteId = widget.pricing!.routeId;
      _selectedBusType = widget.pricing!.busType;
    }

    _loadRoutes();
  }

  Future<void> _loadRoutes() async {
    final snapshot = await FirebaseFirestore.instance.collection('routes').get();
    setState(() {
      _routes = snapshot.docs
          .map((doc) => RouteModel.fromMap(doc.data()))
          .toList();
      if (_routes.isNotEmpty && _selectedRouteId == null) {
        _selectedRouteId = _routes.first.id;
      }
    });
  }

  @override
  void dispose() {
    _passengerPriceController.dispose();
    _parcelPriceController.dispose();
    _luggagePriceController.dispose();
    super.dispose();
  }

  Future<void> _savePricing() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedRouteId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a route'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final pricing = PricingModel(
        id: widget.pricing?.id ?? const Uuid().v4(),
        companyId: widget.companyId,
        routeId: _selectedRouteId!,
        busType: _selectedBusType,
        passengerPrice: double.parse(_passengerPriceController.text.trim()),
        parcelStandardPrice: double.parse(_parcelPriceController.text.trim()),
        luggagePricePerKg: double.parse(_luggagePriceController.text.trim()),
      );

      await widget.databaseService.createOrUpdatePricing(pricing);

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.pricing == null
                  ? 'Pricing added successfully'
                  : 'Pricing updated successfully',
            ),
            backgroundColor: Colors.black,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.pricing == null ? 'Add Pricing' : 'Edit Pricing',
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
      content: SizedBox(
        width: MediaQuery.of(context).size.width * 0.9,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
              DropdownButtonFormField<String>(
                value: _selectedRouteId,
                decoration: const InputDecoration(
                  labelText: 'Route',
                  prefixIcon: Icon(Icons.route),
                ),
                items: _routes.map((route) {
                  return DropdownMenuItem(
                    value: route.id,
                    child: Text('${route.origin} → ${route.destination}'),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedRouteId = value;
                  });
                },
                validator: (value) {
                  if (value == null) return 'Please select a route';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<BusTypeForPricing>(
                value: _selectedBusType,
                decoration: const InputDecoration(
                  labelText: 'Bus Type',
                  prefixIcon: Icon(Icons.directions_bus),
                ),
                items: BusTypeForPricing.values.map((type) {
                  return DropdownMenuItem(
                    value: type,
                    child: Text(type.name.toUpperCase()),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedBusType = value!;
                  });
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passengerPriceController,
                decoration: const InputDecoration(
                  labelText: 'Passenger Price (UGX)',
                  hintText: 'e.g., 15000',
                  prefixIcon: Icon(Icons.person),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter passenger price';
                  }
                  if (double.tryParse(value.trim()) == null) {
                    return 'Please enter a valid number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _parcelPriceController,
                decoration: const InputDecoration(
                  labelText: 'Parcel Standard Price (UGX)',
                  hintText: 'e.g., 5000',
                  prefixIcon: Icon(Icons.inventory_2),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter parcel price';
                  }
                  if (double.tryParse(value.trim()) == null) {
                    return 'Please enter a valid number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _luggagePriceController,
                decoration: const InputDecoration(
                  labelText: 'Luggage Price per Kg (UGX)',
                  hintText: 'e.g., 500',
                  prefixIcon: Icon(Icons.luggage),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter luggage price';
                  }
                  if (double.tryParse(value.trim()) == null) {
                    return 'Please enter a valid number';
                  }
                  return null;
                },
              ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isSaving ? null : _savePricing,
          child: _isSaving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : Text(widget.pricing == null ? 'Add' : 'Update'),
        ),
      ],
    );
  }
}
