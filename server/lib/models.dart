import 'dart:convert';

/// Representation of a single transaction stored on the server.
///
/// The data is stored and returned as-is (opaque JSON map).
/// Typed accessors read the standard fields used by the sync algorithm.
class ServerTransaction {
  ServerTransaction({required this.id, required this.data});

  final String id;
  final Map<String, dynamic> data;

  // ── Typed accessors used by the sync algorithm ───────────────────────────

  String? get coreHash => data['core_hash'] as String?;
  String? get updatedAt => data['updated_at'] as String?;
  int? get seq => data['server_seq'] as int?;

  // ── Factory / serialisation ───────────────────────────────────────────────

  static ServerTransaction? fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    if (id is! String || id.isEmpty) return null;
    return ServerTransaction(id: id, data: json);
  }

  /// Returns a copy with [seq] written into the data map as `server_seq`.
  ServerTransaction withSeq(int seq) {
    final updated = Map<String, dynamic>.from(data);
    updated['server_seq'] = seq;
    return ServerTransaction(id: id, data: updated);
  }

  /// Returns a copy with envelope fields from [other] merged in if [other]'s
  /// `updated_at` is strictly later than this record's.
  ServerTransaction mergeEnvelopeFrom(ServerTransaction other) {
    final myUpdatedAt = updatedAt ?? '0001-01-01T00:00:00.000Z';
    final otherUpdatedAt = other.updatedAt ?? '0001-01-01T00:00:00.000Z';
    if (otherUpdatedAt.compareTo(myUpdatedAt) <= 0) return this;

    final merged = Map<String, dynamic>.from(data);
    // Envelope fields that may change: tags, notes, deleted, deleted_at.
    for (final key in ['tags', 'notes', 'deleted', 'deleted_at']) {
      if (other.data.containsKey(key)) {
        merged[key] = other.data[key];
      }
    }
    merged['updated_at'] = otherUpdatedAt;
    return ServerTransaction(id: id, data: merged);
  }

  Map<String, dynamic> toJson() => data;

  @override
  String toString() => 'ServerTransaction($id, seq=${seq ?? "??"})';
}

/// Encodes a list to a JSON string.
String encodeJson(Object value) => jsonEncode(value);

/// Decodes a JSON string.
dynamic decodeJson(String body) => jsonDecode(body);
