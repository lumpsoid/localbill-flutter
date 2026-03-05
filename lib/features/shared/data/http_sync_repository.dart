import 'dart:convert';

import 'package:http/http.dart' as http;

import '../domain/entities/transaction.dart';
import '../domain/repositories/sync_repository.dart';

/// Syncs transactions with the localbill-server over HTTP using the delta
/// sequence-number protocol.
///
/// ## Protocol (POST /sync)
///
/// **Request:**
/// ```json
/// {
///   "last_seq": 42,
///   "records": [ ...Transaction JSON for unacknowledged records only... ]
/// }
/// ```
///
/// **Response:**
/// ```json
/// {
///   "accepted":     [{"id": "...", "seq": 43}, ...],
///   "conflicts":    [{"id": "...", "client_core_hash": "...",
///                     "server_version": {...}}],
///   "new_records":  [ ...Transaction JSON with seq > last_seq... ],
///   "server_seq":   50
/// }
/// ```
///
/// The server never overwrites an existing transaction's core fields when a
/// coreHash mismatch is detected — it records a conflict instead.
class HttpSyncRepository implements SyncRepository {
  HttpSyncRepository({required this.serverUrl});

  String serverUrl;

  @override
  Future<SyncResult> sync({
    required List<Transaction> unacknowledged,
    required int lastSeq,
  }) async {
    final response = await http.post(
      Uri.parse('$serverUrl/sync'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'last_seq': lastSeq,
        'records': unacknowledged.map((t) => t.toJson()).toList(),
      }),
    );

    if (response.statusCode != 200) {
      throw SyncException('Sync failed: HTTP ${response.statusCode}');
    }

    final body =
        jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;

    // Parse accepted: [{"id": "...", "seq": N}, ...]
    final acceptedSeqs = <String, int>{};
    for (final item in (body['accepted'] as List<dynamic>? ?? [])) {
      final m = item as Map<String, dynamic>;
      final id = m['id'] as String?;
      final seq = m['seq'] as int?;
      if (id != null && seq != null) acceptedSeqs[id] = seq;
    }

    // Parse conflicts: [{"id": "...", "client_core_hash": "...",
    //                    "server_version": {...}}, ...]
    final conflicts = <SyncConflict>[];
    for (final item in (body['conflicts'] as List<dynamic>? ?? [])) {
      final m = item as Map<String, dynamic>;
      final id = m['id'] as String?;
      final serverVersionRaw = m['server_version'] as Map<String, dynamic>?;
      if (id == null || serverVersionRaw == null) continue;

      // Find matching client version from the unacknowledged list.
      final clientVersion = unacknowledged.where((t) => t.id == id).firstOrNull;
      if (clientVersion == null) continue;

      try {
        final serverVersion = Transaction.fromJson(serverVersionRaw);
        conflicts.add(
          SyncConflict(
            id: id,
            clientVersion: clientVersion,
            serverVersion: serverVersion,
          ),
        );
      } catch (_) {
        // Skip malformed conflict payload.
      }
    }

    // Parse new_records: full Transaction JSON for records with seq > last_seq.
    final newTransactions = <Transaction>[];
    for (final item in (body['new_records'] as List<dynamic>? ?? [])) {
      try {
        newTransactions.add(Transaction.fromJson(item as Map<String, dynamic>));
      } catch (_) {
        // Skip malformed record.
      }
    }

    final newServerSeq = body['server_seq'] as int?;

    return SyncResult(
      pushed: acceptedSeqs.length,
      pulled: newTransactions.length,
      conflicts: conflicts,
      newTransactions: newTransactions,
      acceptedSeqs: acceptedSeqs,
      newServerSeq: newServerSeq,
    );
  }

  @override
  Future<List<String>> fetchRemoteQueue() async {
    final response = await http.get(Uri.parse('$serverUrl/queue'));
    if (response.statusCode != 200) {
      throw SyncException('Fetch queue failed: HTTP ${response.statusCode}');
    }
    final body =
        jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
    return (body['items'] as List<dynamic>?)?.cast<String>() ?? [];
  }

  @override
  Future<void> removeFromRemoteQueue(List<String> urls) async {
    final request =
        http.Request('DELETE', Uri.parse('$serverUrl/queue'))
          ..headers['Content-Type'] = 'application/json'
          ..body = jsonEncode({'items': urls});
    final streamed = await request.send();
    if (streamed.statusCode != 200) {
      throw SyncException(
        'Remove from remote queue failed: HTTP ${streamed.statusCode}',
      );
    }
  }

  @override
  void setServerUrl(String url) {
    serverUrl = url;
  }
}

class SyncException implements Exception {
  const SyncException(this.message);
  final String message;

  @override
  String toString() => 'SyncException: $message';
}
