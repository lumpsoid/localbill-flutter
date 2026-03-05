import 'dart:convert';

/// Representation of a single transaction stored on the server.
/// Stored as a JSON map; we treat it as opaque except for `id` and `date`.
class ServerTransaction {
  ServerTransaction({required this.id, required this.data});

  final String id;
  final Map<String, dynamic> data;

  static ServerTransaction? fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    if (id is! String || id.isEmpty) return null;
    return ServerTransaction(id: id, data: json);
  }

  Map<String, dynamic> toJson() => data;

  @override
  String toString() => 'ServerTransaction($id)';
}

/// Encodes a list to a JSON string.
String encodeJson(Object value) => jsonEncode(value);

/// Decodes a JSON string.
dynamic decodeJson(String body) => jsonDecode(body);
