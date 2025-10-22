/// Pricing configuration for a specific route and bus type
/// Companies can set different prices for ordinary and VIP buses
class PricingModel {
  final String id;
  final String companyId;
  final String routeId;
  final BusTypeForPricing busType;
  final double passengerPrice;
  final double parcelStandardPrice;
  final double luggagePricePerKg;

  PricingModel({
    required this.id,
    required this.companyId,
    required this.routeId,
    required this.busType,
    required this.passengerPrice,
    required this.parcelStandardPrice,
    required this.luggagePricePerKg,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'companyId': companyId,
      'routeId': routeId,
      'busType': busType.name,
      'passengerPrice': passengerPrice,
      'parcelStandardPrice': parcelStandardPrice,
      'luggagePricePerKg': luggagePricePerKg,
    };
  }

  factory PricingModel.fromMap(Map<String, dynamic> map) {
    return PricingModel(
      id: map['id'] ?? '',
      companyId: map['companyId'] ?? '',
      routeId: map['routeId'] ?? '',
      busType: BusTypeForPricing.values.firstWhere(
        (e) => e.name == map['busType'],
        orElse: () => BusTypeForPricing.ordinary,
      ),
      passengerPrice: (map['passengerPrice'] ?? 0.0).toDouble(),
      parcelStandardPrice: (map['parcelStandardPrice'] ?? 0.0).toDouble(),
      luggagePricePerKg: (map['luggagePricePerKg'] ?? 0.0).toDouble(),
    );
  }

  PricingModel copyWith({
    String? id,
    String? companyId,
    String? routeId,
    BusTypeForPricing? busType,
    double? passengerPrice,
    double? parcelStandardPrice,
    double? luggagePricePerKg,
  }) {
    return PricingModel(
      id: id ?? this.id,
      companyId: companyId ?? this.companyId,
      routeId: routeId ?? this.routeId,
      busType: busType ?? this.busType,
      passengerPrice: passengerPrice ?? this.passengerPrice,
      parcelStandardPrice: parcelStandardPrice ?? this.parcelStandardPrice,
      luggagePricePerKg: luggagePricePerKg ?? this.luggagePricePerKg,
    );
  }
}

enum BusTypeForPricing {
  ordinary,
  vip,
}
