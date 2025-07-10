// lib/models/property_model.dart

class Property {
  final String id;
  final String ownerId;
  final String name;
  final String address;
  final int price;

  Property({
    required this.id,
    required this.ownerId,
    required this.name,
    required this.address,
    required this.price,
  });

  factory Property.fromJson(Map<String, dynamic> json) {
    return Property(
      id: json['\$id'],
      ownerId: json['ownerId'],
      name: json['name'],
      address: json['address'],
      price: json['price'],
    );
  }

  Null get data => null;

  String? get $id => null;

  Map<String, dynamic> toJson() {
    return {
      'ownerId': ownerId,
      'name': name,
      'address': address,
      'price': price,
    };
  }
}
