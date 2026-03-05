import 'package:meta/meta.dart';

/// Pre-formatted data for one row in the transactions list.
@immutable
class TransactionUiItem {
  const TransactionUiItem({
    required this.id,
    required this.dateLabel,
    required this.retailer,
    required this.name,
    required this.priceLabel,
    required this.link,
  });

  final String id;
  final String dateLabel;
  final String retailer;
  final String name;
  final String priceLabel;
  final String? link;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TransactionUiItem &&
          other.id == id &&
          other.dateLabel == dateLabel &&
          other.retailer == retailer &&
          other.name == name &&
          other.priceLabel == priceLabel &&
          other.link == link;

  @override
  int get hashCode =>
      Object.hash(id, dateLabel, retailer, name, priceLabel, link);
}
