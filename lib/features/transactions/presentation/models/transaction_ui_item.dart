import 'package:meta/meta.dart';

/// Pre-formatted data for one row in the transactions list,
/// also used to populate the full transaction detail page.
@immutable
class TransactionUiItem {
  const TransactionUiItem({
    required this.id,
    required this.dateLabel,
    required this.retailer,
    required this.name,
    required this.quantityLabel,
    required this.unitPriceLabel,
    required this.priceLabel,
    required this.currency,
    required this.country,
    required this.tags,
    required this.updatedAtLabel,
    this.link,
    this.notes,
  });

  final String id;
  final String dateLabel;
  final String retailer;
  final String name;
  final String quantityLabel;
  final String unitPriceLabel;
  final String priceLabel;
  final String currency;
  final String country;
  final List<String> tags;
  final String updatedAtLabel;
  final String? link;
  final String? notes;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TransactionUiItem &&
          other.id == id &&
          other.dateLabel == dateLabel &&
          other.retailer == retailer &&
          other.name == name &&
          other.quantityLabel == quantityLabel &&
          other.unitPriceLabel == unitPriceLabel &&
          other.priceLabel == priceLabel &&
          other.currency == currency &&
          other.country == country &&
          other.tags == tags &&
          other.updatedAtLabel == updatedAtLabel &&
          other.link == link &&
          other.notes == notes;

  @override
  int get hashCode => Object.hash(
        id,
        dateLabel,
        retailer,
        name,
        quantityLabel,
        unitPriceLabel,
        priceLabel,
        currency,
        country,
        Object.hashAll(tags),
        updatedAtLabel,
        link,
        notes,
      );
}
