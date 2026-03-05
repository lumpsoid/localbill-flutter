import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:meta/meta.dart';

/// One saved transaction, stored as a JSON file on disk.
/// Mirrors the Rust `Transaction` struct (YAML front-matter).
@immutable
class Transaction {
  const Transaction({
    required this.id,
    required this.date,
    required this.retailer,
    required this.name,
    required this.quantity,
    required this.unitPrice,
    required this.priceTotal,
    required this.currency,
    required this.country,
    this.link,
    this.tags = const IListConst([]),
    this.notes,
  });

  /// Filename stem (e.g. `20240315T143000-mleko`).
  final String id;

  /// ISO 8601 datetime, e.g. `2024-03-15T14:30:00`.
  final String date;
  final String retailer;
  final String name;
  final double quantity;
  final double unitPrice;
  final double priceTotal;
  final String currency;
  final String country;
  final String? link;
  final IList<String> tags;
  final String? notes;

  Transaction copyWith({
    String? id,
    String? date,
    String? retailer,
    String? name,
    double? quantity,
    double? unitPrice,
    double? priceTotal,
    String? currency,
    String? country,
    String? link,
    IList<String>? tags,
    String? notes,
  }) {
    return Transaction(
      id: id ?? this.id,
      date: date ?? this.date,
      retailer: retailer ?? this.retailer,
      name: name ?? this.name,
      quantity: quantity ?? this.quantity,
      unitPrice: unitPrice ?? this.unitPrice,
      priceTotal: priceTotal ?? this.priceTotal,
      currency: currency ?? this.currency,
      country: country ?? this.country,
      link: link ?? this.link,
      tags: tags ?? this.tags,
      notes: notes ?? this.notes,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'date': date,
    'retailer': retailer,
    'name': name,
    'quantity': quantity,
    'unit_price': unitPrice,
    'price_total': priceTotal,
    'currency': currency,
    'country': country,
    if (link != null) 'link': link,
    'tags': tags.toList(),
    if (notes != null) 'notes': notes,
  };

  factory Transaction.fromJson(Map<String, dynamic> json) => Transaction(
    id: json['id'] as String,
    date: json['date'] as String,
    retailer: json['retailer'] as String,
    name: json['name'] as String,
    quantity: (json['quantity'] as num).toDouble(),
    unitPrice: (json['unit_price'] as num).toDouble(),
    priceTotal: (json['price_total'] as num).toDouble(),
    currency: json['currency'] as String,
    country: json['country'] as String,
    link: json['link'] as String?,
    tags: IList<String>.from(
      (json['tags'] as List<dynamic>? ?? []).cast<String>(),
    ),
    notes: json['notes'] as String?,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Transaction &&
          other.id == id &&
          other.date == date &&
          other.retailer == retailer &&
          other.name == name &&
          other.quantity == quantity &&
          other.unitPrice == unitPrice &&
          other.priceTotal == priceTotal &&
          other.currency == currency &&
          other.country == country &&
          other.link == link &&
          other.tags == tags &&
          other.notes == notes;

  @override
  int get hashCode => Object.hash(
    id, date, retailer, name, quantity, unitPrice, priceTotal,
    currency, country, link, tags, notes,
  );

  @override
  String toString() =>
      'Transaction(id: $id, date: $date, name: $name, priceTotal: $priceTotal)';
}
