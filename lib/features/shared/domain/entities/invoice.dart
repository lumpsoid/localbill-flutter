import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:meta/meta.dart';

import 'invoice_item.dart';

/// A fully-parsed invoice fetched from the Serbian fiscal authority website.
/// Mirrors the Rust `Invoice` struct.
@immutable
class Invoice {
  const Invoice({
    required this.invoiceNumber,
    required this.retailer,
    required this.date,
    required this.totalPrice,
    required this.currency,
    required this.country,
    required this.url,
    required this.rawBillText,
    required this.items,
  });

  final String invoiceNumber;
  final String retailer;

  /// ISO 8601 datetime, e.g. `2024-03-15T14:30:00`.
  final String date;
  final double totalPrice;
  final String currency;
  final String country;
  final String url;
  final String rawBillText;
  final IList<InvoiceItem> items;

  @override
  String toString() =>
      'Invoice(invoiceNumber: $invoiceNumber, retailer: $retailer, '
      'date: $date, totalPrice: $totalPrice, items: ${items.length})';
}
