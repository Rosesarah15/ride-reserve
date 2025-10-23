import 'package:bus_booking/home/presentation/pages/passenger_payment_page.dart';
import 'package:bus_booking/models/pricing_model.dart';
import 'package:bus_booking/models/trip_search_result.dart';
import 'package:bus_booking/services/firebase_database_service.dart';
import 'package:flutter/material.dart';

/// Page where users can choose to add luggage or proceed without it
class LuggageSelectionPage extends StatefulWidget {
  final TripSearchResult trip;
  final List<String> selectedSeats;

  const LuggageSelectionPage({
    super.key,
    required this.trip,
    required this.selectedSeats,
  });

  @override
  State<LuggageSelectionPage> createState() => _LuggageSelectionPageState();
}

class _LuggageSelectionPageState extends State<LuggageSelectionPage> {
  final FirebaseDatabaseService _databaseService = FirebaseDatabaseService();
  final TextEditingController _weightController = TextEditingController();
  bool _hasLuggage = false;
  PricingModel? _pricing;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPricing();
  }

  @override
  void dispose() {
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

  double get _passengerPrice => _pricing?.passengerPrice ?? widget.trip.schedule.fee;

  double get _luggagePricePerKg => _pricing?.luggagePricePerKg ?? 500;

  double get _totalPassengerFee => _passengerPrice * widget.selectedSeats.length;

  double get _luggageFee {
    if (!_hasLuggage || _weightController.text.trim().isEmpty) return 0;
    final weight = double.tryParse(_weightController.text.trim()) ?? 0;
    return weight * _luggagePricePerKg;
  }

  double get _grandTotal => _totalPassengerFee + _luggageFee;

  void _proceedToPayment() {
    final hasLuggage = _hasLuggage && _weightController.text.trim().isNotEmpty;
    final luggageWeight = hasLuggage
        ? double.tryParse(_weightController.text.trim())
        : null;

    if (hasLuggage && (luggageWeight == null || luggageWeight <= 0)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid luggage weight'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PassengerPaymentPage(
          trip: widget.trip,
          selectedSeats: widget.selectedSeats,
          passengerFee: _passengerPrice,
          hasLuggage: hasLuggage,
          luggageWeightInKg: luggageWeight,
          luggageFee: hasLuggage ? _luggageFee : null,
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
        title: const Text('Luggage'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Do you have luggage?',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 6),
            Text(
              'Add luggage to your booking if needed',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey.shade600,
                  ),
            ),
            const SizedBox(height: 24),
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: Colors.grey.shade300,
                  width: 1,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Checkbox(
                          value: _hasLuggage,
                          onChanged: (value) {
                            setState(() {
                              _hasLuggage = value ?? false;
                              if (!_hasLuggage) {
                                _weightController.clear();
                              }
                            });
                          },
                        ),
                        Expanded(
                          child: Text(
                            'I have luggage',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (_hasLuggage) ...[
                      const Divider(),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _weightController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: InputDecoration(
                          labelText: 'Weight (kg)',
                          hintText: 'Enter luggage weight',
                          suffixText: 'kg',
                          helperText:
                              'UGX ${_luggagePricePerKg.toStringAsFixed(0)} per kg',
                          prefixIcon: const Icon(Icons.luggage),
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                      if (_weightController.text.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Luggage fee:',
                                style: TextStyle(
                                  fontWeight: FontWeight.w500,
                                  fontSize: 13,
                                ),
                              ),
                              Text(
                                'UGX ${_luggageFee.toStringAsFixed(0)}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Card(
              elevation: 0,
              color: Colors.grey.shade50,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: Colors.grey.shade300,
                  width: 1,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Booking Summary',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Divider(height: 20),
                    _SummaryRow(
                      label: 'Passengers',
                      value: '${widget.selectedSeats.length}',
                    ),
                    const SizedBox(height: 8),
                    _SummaryRow(
                      label: 'Seats',
                      value: widget.selectedSeats.join(', '),
                    ),
                    const SizedBox(height: 8),
                    _SummaryRow(
                      label: 'Passenger fee',
                      value:
                          'UGX ${_totalPassengerFee.toStringAsFixed(0)}',
                    ),
                    if (_hasLuggage && _luggageFee > 0) ...[
                      const SizedBox(height: 8),
                      _SummaryRow(
                        label: 'Luggage fee',
                        value: 'UGX ${_luggageFee.toStringAsFixed(0)}',
                      ),
                    ],
                    const Divider(height: 20),
                    _SummaryRow(
                      label: 'Total',
                      value: 'UGX ${_grandTotal.toStringAsFixed(0)}',
                      isTotal: true,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, size: 16, color: Colors.blue.shade700),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Children under 5 years travel free and don\'t require a seat',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.blue.shade700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
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
            child: const Text(
              'Proceed to Payment',
              style: TextStyle(fontSize: 13),
            ),
          ),
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isTotal;

  const _SummaryRow({
    required this.label,
    required this.value,
    this.isTotal = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isTotal ? 14 : 13,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            color: isTotal ? Colors.black : Colors.grey.shade700,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: isTotal ? 15 : 13,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
