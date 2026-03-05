import 'dart:convert';

import 'package:http/http.dart' as http;

import '../domain/entities/transaction.dart';
import '../domain/repositories/sync_repository.dart';

/// Syncs transactions with the localbill-server over HTTP.
///
/// The server exposes:
///   POST /sync          — full bidirectional sync
///   GET  /queue         — fetch remote queue
///   DELETE /queue       — remove processed items from remote queue
class HttpSyncRepository implements SyncRepository {
  HttpSyncRepository({required this.serverUrl});

  /// Base URL of the localbill-server, e.g. `http://192.168.1.2:8080`.
  final String serverUrl;

  @override
  Future<SyncResult> sync(List<Transaction> local) async {
    final response = await http.post(
      Uri.parse('$serverUrl/sync'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'transactions': local.map((t) => t.toJson()).toList(),
      }),
    );

    if (response.statusCode != 200) {
      throw SyncException('Sync failed: HTTP ${response.statusCode}');
    }

    final body = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
    final newTransactions = (body['new_transactions'] as List<dynamic>?)
            ?.map((e) => Transaction.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [];

    return SyncResult(
      pushed: local.length,
      pulled: newTransactions.length,
    );
  }

  @override
  Future<List<String>> fetchRemoteQueue() async {
    final response = await http.get(Uri.parse('$serverUrl/queue'));
    if (response.statusCode != 200) {
      throw SyncException('Fetch queue failed: HTTP ${response.statusCode}');
    }
    final body = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
    return (body['items'] as List<dynamic>?)?.cast<String>() ?? [];
  }

  @override
  Future<void> removeFromRemoteQueue(List<String> urls) async {
    final request = http.Request('DELETE', Uri.parse('$serverUrl/queue'))
      ..headers['Content-Type'] = 'application/json'
      ..body = jsonEncode({'items': urls});
    final streamed = await request.send();
    if (streamed.statusCode != 200) {
      throw SyncException(
        'Remove from remote queue failed: HTTP ${streamed.statusCode}',
      );
    }
  }
}

class SyncException implements Exception {
  const SyncException(this.message);
  final String message;

  @override
  String toString() => 'SyncException: $message';
}
