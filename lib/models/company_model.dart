
class CompanyModel {
  final String id;
  final String name;
  final String logoUrl;
  final double rating;

  CompanyModel({
    required this.id,
    required this.name,
    required this.logoUrl,
    required this.rating,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'logoUrl': logoUrl,
      'rating': rating,
    };
  }

  factory CompanyModel.fromMap(Map<String, dynamic> map) {
    return CompanyModel(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      logoUrl: map['logoUrl'] ?? '',
      rating: (map['rating'] ?? 0.0).toDouble(),
    );
  }
}
