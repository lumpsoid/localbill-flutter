import 'dart:convert';

import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import 'models.dart';
import 'storage.dart';

Router buildRouter(JsonStorage storage) {
  final router = Router();

  // ── Health check ──────────────────────────────────────────────────────────

  router.get('/health', (Request request) {
    return Response.ok(
      jsonEncode({'status': 'ok'}),
      headers: _jsonHeaders,
    );
  });

  // ── Sync endpoint ─────────────────────────────────────────────────────────

  /// POST /sync
  ///
  /// Body:   { "transactions": [ ...Transaction JSON... ] }
  /// Response: { "new_transactions": [ ...Transaction JSON not known locally... ] }
  ///
  /// Strategy: last-write-wins by `id`. The server merges all client
  /// transactions into its store and returns any server-only records.
  router.post('/sync', (Request request) async {
    final body = await request.readAsString();
    final Map<String, dynamic> payload;
    try {
      payload = jsonDecode(body) as Map<String, dynamic>;
    } catch (_) {
      return Response(400, body: jsonEncode({'error': 'Invalid JSON'}));
    }

    final clientList =
        (payload['transactions'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>();

    final serverMap = await storage.loadTransactions();

    // Collect IDs the client already knows about.
    final clientIds = <String>{};
    for (final raw in clientList) {
      final tx = ServerTransaction.fromJson(raw);
      if (tx == null) continue;
      clientIds.add(tx.id);
      // Last-write-wins: always accept client version.
      serverMap[tx.id] = tx;
    }

    // Persist merged state.
    await storage.saveTransactions(serverMap);

    // Return transactions the client does not yet have.
    final newForClient = serverMap.values
        .where((t) => !clientIds.contains(t.id))
        .map((t) => t.toJson())
        .toList();

    return Response.ok(
      jsonEncode({'new_transactions': newForClient}),
      headers: _jsonHeaders,
    );
  });

  // ── Queue endpoints ───────────────────────────────────────────────────────

  /// GET /queue → { "items": [ ...urls... ] }
  router.get('/queue', (Request request) async {
    final queue = await storage.loadQueue();
    return Response.ok(
      jsonEncode({'items': queue}),
      headers: _jsonHeaders,
    );
  });

  /// POST /queue → add URLs to the queue
  /// Body: { "items": [ ...urls... ] }  or  { "item": "url" }
  router.post('/queue', (Request request) async {
    final body = await request.readAsString();
    final Map<String, dynamic> payload;
    try {
      payload = jsonDecode(body) as Map<String, dynamic>;
    } catch (_) {
      return Response(400, body: jsonEncode({'error': 'Invalid JSON'}));
    }

    final queue = await storage.loadQueue();
    final existing = Set<String>.from(queue);

    if (payload['item'] is String) {
      final url = payload['item'] as String;
      if (!existing.contains(url)) queue.add(url);
    }
    if (payload['items'] is List) {
      for (final url in (payload['items'] as List).cast<String>()) {
        if (!existing.contains(url)) queue.add(url);
      }
    }

    await storage.saveQueue(queue);
    return Response.ok(
      jsonEncode({'queued': queue.length}),
      headers: _jsonHeaders,
    );
  });

  /// DELETE /queue — remove successfully-processed items
  /// Body: { "items": [ ...urls... ] }
  router.delete('/queue', (Request request) async {
    final body = await request.readAsString();
    final Map<String, dynamic> payload;
    try {
      payload = jsonDecode(body) as Map<String, dynamic>;
    } catch (_) {
      return Response(400, body: jsonEncode({'error': 'Invalid JSON'}));
    }

    final toRemove = Set<String>.from(
      (payload['items'] as List<dynamic>? ?? []).cast<String>(),
    );
    final queue = await storage.loadQueue();
    final remaining = queue.where((u) => !toRemove.contains(u)).toList();
    await storage.saveQueue(remaining);

    return Response.ok(
      jsonEncode({'removed': toRemove.length, 'remaining': remaining.length}),
      headers: _jsonHeaders,
    );
  });

  // ── Individual transaction CRUD ───────────────────────────────────────────

  /// GET /transactions → all transactions
  router.get('/transactions', (Request request) async {
    final txs = await storage.loadTransactions();
    return Response.ok(
      jsonEncode({'transactions': txs.values.map((t) => t.toJson()).toList()}),
      headers: _jsonHeaders,
    );
  });

  /// POST /transactions — upsert a single transaction
  router.post('/transactions', (Request request) async {
    final body = await request.readAsString();
    final Map<String, dynamic> raw;
    try {
      raw = jsonDecode(body) as Map<String, dynamic>;
    } catch (_) {
      return Response(400, body: jsonEncode({'error': 'Invalid JSON'}));
    }

    final tx = ServerTransaction.fromJson(raw);
    if (tx == null) {
      return Response(
        400,
        body: jsonEncode({'error': 'Missing or invalid "id" field'}),
      );
    }

    final txs = await storage.loadTransactions();
    txs[tx.id] = tx;
    await storage.saveTransactions(txs);

    return Response.ok(
      jsonEncode({'saved': tx.id}),
      headers: _jsonHeaders,
    );
  });

  /// DELETE /transactions/<id>
  router.delete('/transactions/<id>', (Request request, String id) async {
    final txs = await storage.loadTransactions();
    final existed = txs.containsKey(id);
    txs.remove(id);
    await storage.saveTransactions(txs);

    return Response.ok(
      jsonEncode({'deleted': id, 'existed': existed}),
      headers: _jsonHeaders,
    );
  });

  return router;
}

const _jsonHeaders = {'content-type': 'application/json'};
