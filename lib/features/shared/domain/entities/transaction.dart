import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:meta/meta.dart';

/// One saved transaction stored as a JSON file on disk.
///
/// ## Immutability model
///
/// **Core fields** (date, retailer, name, quantity, unitPrice, priceTotal,
/// currency, country, link) reflect the printed invoice and are immutable once
/// created. They are hashed into [coreHash] so any attempt to overwrite them
/// with different data is detected during sync.
///
/// **Envelope fields** (tags, notes, deleted, deletedAt) are user-curated
/// and may change. [updatedAt] timestamps every envelope write; the newer
/// timestamp wins during sync merges.
///
/// **Sync field** [serverSeq] is assigned by the server and must never be
/// mutated locally. `null` means the record has not yet been acknowledged.
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
    required this.coreHash,
    required this.updatedAt,
    this.link,
    this.tags = const IListConst([]),
    this.notes,
    this.serverSeq,
    this.deleted = false,
    this.deletedAt,
  });

  // ── Core (immutable) fields ───────────────────────────────────────────────

  final String id;
  final String date;
  final String retailer;
  final String name;
  final double quantity;
  final double unitPrice;
  final double priceTotal;
  final String currency;
  final String country;
  final String? link;

  /// SHA-256 of all core fields. Computed once at creation; never modified.
  final String coreHash;

  // ── Envelope (mutable) fields ─────────────────────────────────────────────

  final IList<String> tags;
  final String? notes;

  /// UTC ISO 8601 timestamp of the last envelope modification.
  final String updatedAt;

  /// Soft-delete flag. Hard deletes are never performed.
  final bool deleted;
  final String? deletedAt;

  // ── Sync field ────────────────────────────────────────────────────────────

  /// Monotonic sequence number assigned by the server. `null` = not yet acked.
  final int? serverSeq;

  // ── Factory constructor ───────────────────────────────────────────────────

  /// Create a brand-new transaction. Computes [coreHash] and sets [updatedAt]
  /// to the current UTC time.
  factory Transaction.create({
    required String id,
    required String date,
    required String retailer,
    required String name,
    required double quantity,
    required double unitPrice,
    required double priceTotal,
    required String currency,
    required String country,
    String? link,
    IList<String> tags = const IListConst([]),
    String? notes,
  }) => Transaction(
    id: id,
    date: date,
    retailer: retailer,
    name: name,
    quantity: quantity,
    unitPrice: unitPrice,
    priceTotal: priceTotal,
    currency: currency,
    country: country,
    link: link,
    coreHash: computeCoreHash(
      date: date,
      retailer: retailer,
      name: name,
      quantity: quantity,
      unitPrice: unitPrice,
      priceTotal: priceTotal,
      currency: currency,
      country: country,
      link: link,
    ),
    updatedAt: DateTime.now().toUtc().toIso8601String(),
    tags: tags,
    notes: notes,
  );

  // ── Core-hash computation ─────────────────────────────────────────────────

  /// SHA-256 fingerprint of the immutable financial fields.
  /// Fields are separated by `\x00` to prevent value-boundary collisions.
  static String computeCoreHash({
    required String date,
    required String retailer,
    required String name,
    required double quantity,
    required double unitPrice,
    required double priceTotal,
    required String currency,
    required String country,
    String? link,
  }) {
    final input = [
      date,
      retailer,
      name,
      quantity.toString(),
      unitPrice.toString(),
      priceTotal.toString(),
      currency,
      country,
      link ?? '',
    ].join('\x00');
    return sha256.convert(utf8.encode(input)).toString();
  }

  // ── Envelope mutation ─────────────────────────────────────────────────────

  /// Return a copy with updated envelope fields, bumping [updatedAt] to now.
  Transaction withEnvelope({
    IList<String>? tags,
    String? notes,
    bool? deleted,
  }) {
    final nowDeleted = deleted ?? this.deleted;
    return copyWith(
      tags: tags ?? this.tags,
      notes: notes ?? this.notes,
      deleted: nowDeleted,
      deletedAt:
          (nowDeleted && deletedAt == null)
              ? DateTime.now().toUtc().toIso8601String()
              : deletedAt,
      updatedAt: DateTime.now().toUtc().toIso8601String(),
    );
  }

  // ── Serialisation ─────────────────────────────────────────────────────────

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
    'core_hash': coreHash,
    'updated_at': updatedAt,
    'tags': tags.toList(),
    if (notes != null) 'notes': notes,
    if (serverSeq != null) 'server_seq': serverSeq,
    'deleted': deleted,
    if (deletedAt != null) 'deleted_at': deletedAt,
  };

  factory Transaction.fromJson(Map<String, dynamic> json) {
    final date = json['date'] as String;
    final retailer = json['retailer'] as String;
    final name = json['name'] as String;
    final quantity = (json['quantity'] as num).toDouble();
    final unitPrice = (json['unit_price'] as num).toDouble();
    final priceTotal = (json['price_total'] as num).toDouble();
    final currency = json['currency'] as String;
    final country = json['country'] as String;
    final link = json['link'] as String?;

    // Backwards-compat: compute hash when loading pre-migration files.
    final coreHash =
        json['core_hash'] as String? ??
        computeCoreHash(
          date: date,
          retailer: retailer,
          name: name,
          quantity: quantity,
          unitPrice: unitPrice,
          priceTotal: priceTotal,
          currency: currency,
          country: country,
          link: link,
        );

    return Transaction(
      id: json['id'] as String,
      date: date,
      retailer: retailer,
      name: name,
      quantity: quantity,
      unitPrice: unitPrice,
      priceTotal: priceTotal,
      currency: currency,
      country: country,
      link: link,
      coreHash: coreHash,
      // Old files have no updated_at; use min-date sentinel so the server
      // version always wins in envelope conflicts.
      updatedAt: json['updated_at'] as String? ?? '0001-01-01T00:00:00.000Z',
      tags: IList<String>(
        (json['tags'] as List<dynamic>? ?? []).cast<String>(),
      ),
      notes: json['notes'] as String?,
      serverSeq: json['server_seq'] as int?,
      deleted: json['deleted'] as bool? ?? false,
      deletedAt: json['deleted_at'] as String?,
    );
  }

  // ── copyWith ──────────────────────────────────────────────────────────────

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
    String? coreHash,
    String? updatedAt,
    IList<String>? tags,
    String? notes,
    int? serverSeq,
    bool? deleted,
    String? deletedAt,
  }) => Transaction(
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
    coreHash: coreHash ?? this.coreHash,
    updatedAt: updatedAt ?? this.updatedAt,
    tags: tags ?? this.tags,
    notes: notes ?? this.notes,
    serverSeq: serverSeq ?? this.serverSeq,
    deleted: deleted ?? this.deleted,
    deletedAt: deletedAt ?? this.deletedAt,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Transaction &&
          other.id == id &&
          other.coreHash == coreHash &&
          other.updatedAt == updatedAt &&
          other.tags == tags &&
          other.notes == notes &&
          other.serverSeq == serverSeq &&
          other.deleted == deleted;

  @override
  int get hashCode =>
      Object.hash(id, coreHash, updatedAt, tags, notes, serverSeq, deleted);

  @override
  String toString() =>
      'Transaction(id: $id, name: $name, priceTotal: $priceTotal, '
      'seq: $serverSeq, deleted: $deleted)';
}
