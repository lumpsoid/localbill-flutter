import 'package:meta/meta.dart';

/// One line-item from a Serbian fiscal invoice API.
/// Mirrors the Rust `InvoiceItem` struct.
@immutable
class InvoiceItem {
  const InvoiceItem({
    required this.name,
    required this.quantity,
    required this.unitPrice,
    required this.total,
    this.gtin = '',
    this.label = '',
    this.labelRate = 0.0,
    this.taxBaseAmount = 0.0,
    this.vatAmount = 0.0,
  });

  final String name;
  final double quantity;
  final double unitPrice;
  final double total;
  final String gtin;
  final String label;
  final double labelRate;
  final double taxBaseAmount;
  final double vatAmount;

  factory InvoiceItem.fromJson(Map<String, dynamic> json) => InvoiceItem(
    name: json['name'] as String? ?? '',
    quantity: (json['quantity'] as num?)?.toDouble() ?? 0.0,
    unitPrice: (json['unitPrice'] as num?)?.toDouble() ?? 0.0,
    total: (json['total'] as num?)?.toDouble() ?? 0.0,
    gtin: json['gtin'] as String? ?? '',
    label: json['label'] as String? ?? '',
    labelRate: (json['labelRate'] as num?)?.toDouble() ?? 0.0,
    taxBaseAmount: (json['taxBaseAmount'] as num?)?.toDouble() ?? 0.0,
    vatAmount: (json['vatAmount'] as num?)?.toDouble() ?? 0.0,
  );

  @override
  String toString() =>
      'InvoiceItem(name: $name, quantity: $quantity, unitPrice: $unitPrice, total: $total)';
}
