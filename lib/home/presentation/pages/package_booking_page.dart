import 'package:bus_booking/home/presentation/pages/package_payment_page.dart';
import 'package:bus_booking/models/package_booking_model.dart';
import 'package:bus_booking/models/pricing_model.dart';
import 'package:bus_booking/models/trip_search_result.dart';
import 'package:bus_booking/services/firebase_database_service.dart';
import 'package:flutter/material.dart';

/// Page for booking packages (parcels or luggage freight) without seats
class PackageBookingPage extends StatefulWidget {
  final TripSearchResult trip;

  const PackageBookingPage({
    super.key,
    required this.trip,
  });

  @override
  State<PackageBookingPage> createState() => _PackageBookingPageState();
}

class _PackageBookingPageState extends State<PackageBookingPage> {
  final _formKey = GlobalKey<FormState>();
  final FirebaseDatabaseService _databaseService = FirebaseDatabaseService();

  final _senderNameController = TextEditingController();
  final _senderPhoneController = TextEditingController();
  final _receiverNameController = TextEditingController();
  final _receiverPhoneController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _weightController = TextEditingController();

  PackageType _packageType = PackageType.parcel;
  PricingModel? _pricing;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPricing();
  }

  @override
  void dispose() {
    _senderNameController.dispose();
    _senderPhoneController.dispose();
    _receiverNameController.dispose();
    _receiverPhoneController.dispose();
    _descriptionController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  Future<void> _loadPricing() async {
    try {
      final pricing = await _databaseService.getPricing(
        companyId: widget.trip.company.id,
        routeId: widget.trip.route.id,
        busType: widget.trip.bus.type.name,
      );
      setState(() {
        _pricing = pricing;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  double get _parcelPrice => _pricing?.parcelStandardPrice ?? 5000;

  double get _luggagePricePerKg => _pricing?.luggagePricePerKg ?? 500;

  double get _totalPrice {
    if (_packageType == PackageType.parcel) {
      return _parcelPrice;
    } else {
      final weight = double.tryParse(_weightController.text.trim()) ?? 0;
      return weight * _luggagePricePerKg;
    }
  }

  void _proceedToPayment() {
    if (!_formKey.currentState!.validate()) return;

    if (_packageType == PackageType.luggage) {
      final weight = double.tryParse(_weightController.text.trim());
      if (weight == null || weight <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please enter a valid weight'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PackagePaymentPage(
          trip: widget.trip,
          packageType: _packageType,
          senderName: _senderNameController.text.trim(),
          senderPhone: _senderPhoneController.text.trim(),
          receiverName: _receiverNameController.text.trim(),
          receiverPhone: _receiverPhoneController.text.trim(),
          description: _descriptionController.text.trim(),
          weightInKg: _packageType == PackageType.luggage
              ? double.parse(_weightController.text.trim())
              : null,
          totalPrice: _totalPrice,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Package Booking'),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Package Type',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 16),
              _PackageTypeCard(
                icon: Icons.inventory_2,
                title: 'Parcel',
                description: 'Standard price for parcels',
                price: 'UGX ${_parcelPrice.toStringAsFixed(0)}',
                isSelected: _packageType == PackageType.parcel,
                onTap: () {
                  setState(() {
                    _packageType = PackageType.parcel;
                    _weightController.clear();
                  });
                },
              ),
              const SizedBox(height: 12),
              _PackageTypeCard(
                icon: Icons.luggage,
                title: 'Luggage',
                description: 'Charged per kilogram',
                price: 'UGX ${_luggagePricePerKg.toStringAsFixed(0)}/kg',
                isSelected: _packageType == PackageType.luggage,
                onTap: () {
                  setState(() {
                    _packageType = PackageType.luggage;
                  });
                },
              ),
              if (_packageType == PackageType.luggage) ...[
                const SizedBox(height: 16),
                TextFormField(
                  controller: _weightController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Weight (kg)',
                    hintText: 'Enter luggage weight',
                    suffixText: 'kg',
                    prefixIcon: const Icon(Icons.scale),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter weight';
                    }
                    final weight = double.tryParse(value.trim());
                    if (weight == null || weight <= 0) {
                      return 'Please enter a valid weight';
                    }
                    return null;
                  },
                  onChanged: (_) => setState(() {}),
                ),
              ],
              const SizedBox(height: 32),
              Text(
                'Sender Information',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _senderNameController,
                decoration: const InputDecoration(
                  labelText: 'Sender Name',
                  hintText: 'Enter sender name',
                  prefixIcon: Icon(Icons.person),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter sender name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _senderPhoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Sender Phone',
                  hintText: 'Enter sender phone number',
                  prefixIcon: Icon(Icons.phone),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter sender phone';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 32),
              Text(
                'Receiver Information',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _receiverNameController,
                decoration: const InputDecoration(
                  labelText: 'Receiver Name',
                  hintText: 'Enter receiver name',
                  prefixIcon: Icon(Icons.person_outline),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter receiver name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _receiverPhoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Receiver Phone',
                  hintText: 'Enter receiver phone number',
                  prefixIcon: Icon(Icons.phone_outlined),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter receiver phone';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 32),
              Text(
                'Package Description (Optional)',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  hintText: 'Describe the package contents',
                  prefixIcon: Icon(Icons.description),
                ),
              ),
              const SizedBox(height: 24),
              if (_totalPrice > 0)
                Card(
                  color: Colors.grey.shade50,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Total Price:',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'UGX ${_totalPrice.toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: ElevatedButton(
            onPressed: _proceedToPayment,
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 50),
            ),
            child: const Text('Proceed to Payment'),
          ),
        ),
      ),
    );
  }
}

class _PackageTypeCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final String price;
  final bool isSelected;
  final VoidCallback onTap;

  const _PackageTypeCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.price,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: isSelected ? 4 : 1,
      color: isSelected ? Colors.black : Colors.white,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(
                icon,
                size: 32,
                color: isSelected ? Colors.white : Colors.black,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isSelected ? Colors.white : Colors.black,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 13,
                        color: isSelected
                            ? Colors.grey.shade300
                            : Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    price,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? Colors.white : Colors.black,
                    ),
                  ),
                  if (isSelected)
                    const Icon(
                      Icons.check_circle,
                      color: Colors.white,
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
