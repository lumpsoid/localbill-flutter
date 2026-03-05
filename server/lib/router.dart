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
      headers: _json,
    );
  });

  // ── Sync endpoint ─────────────────────────────────────────────────────────

  /// POST /sync
  ///
  /// Request:
  /// ```json
  /// { "last_seq": 42, "records": [...Transaction JSON...] }
  /// ```
  ///
  /// Response:
  /// ```json
  /// {
  ///   "accepted":    [{"id": "...", "seq": N}, ...],
  ///   "conflicts":   [{"id": "...", "client_core_hash": "...",
  ///                    "server_version": {...}}],
  ///   "new_records": [...Transaction JSON with server_seq > last_seq...],
  ///   "server_seq":  N
  /// }
  /// ```
  ///
  /// ## Algorithm
  ///
  /// For each client record:
  ///   1. Not in server → Accept: assign next seq, save, add to accepted.
  ///   2. In server, coreHash matches → Accept: merge envelope by updatedAt,
  ///      keep existing seq, add to accepted.
  ///   3. In server, coreHash differs → Conflict: log it, do NOT overwrite
  ///      server record, add to conflicts response.
  ///
  /// new_records = server records where server_seq > last_seq
  ///               AND id not in accepted (client already has them).
  router.post('/sync', (Request request) async {
    final body = await request.readAsString();
    final Map<String, dynamic> payload;
    try {
      payload = jsonDecode(body) as Map<String, dynamic>;
    } catch (_) {
      return Response(400, body: jsonEncode({'error': 'Invalid JSON'}),
          headers: _json);
    }

    final lastSeq = (payload['last_seq'] as num?)?.toInt() ?? 0;
    final clientRecords =
        (payload['records'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>();

    final serverMap = await storage.loadTransactions();

    final accepted = <Map<String, dynamic>>[];
    final conflicts = <Map<String, dynamic>>[];
    final acceptedIds = <String>{};

    for (final raw in clientRecords) {
      final client = ServerTransaction.fromJson(raw);
      if (client == null) continue;

      final existing = serverMap[client.id];

      if (existing == null) {
        // New record: accept and assign a sequence number.
        final seq = await storage.nextSequence();
        final saved = client.withSeq(seq);
        serverMap[client.id] = saved;
        accepted.add({'id': client.id, 'seq': seq});
        acceptedIds.add(client.id);
      } else if (existing.coreHash == null ||
          existing.coreHash == client.coreHash) {
        // Known record with matching core: merge envelope, re-acknowledge.
        var merged = existing.mergeEnvelopeFrom(client);
        // Assign seq if not yet assigned (shouldn't normally happen).
        if (merged.seq == null) {
          final seq = await storage.nextSequence();
          merged = merged.withSeq(seq);
        }
        serverMap[client.id] = merged;
        accepted.add({'id': client.id, 'seq': merged.seq});
        acceptedIds.add(client.id);
      } else {
        // coreHash mismatch → conflict.
        final conflict = {
          'id': client.id,
          'client_core_hash': client.coreHash,
          'server_core_hash': existing.coreHash,
          'server_version': existing.toJson(),
          'detected_at': DateTime.now().toUtc().toIso8601String(),
        };
        conflicts.add({
          'id': client.id,
          'client_core_hash': client.coreHash,
          'server_version': existing.toJson(),
        });
        // Log the full conflict for human review.
        await storage.appendConflict(conflict);
      }
    }

    // Persist updated server state.
    await storage.saveTransactions(serverMap);

    // Collect records the client does not yet have: seq > last_seq and not
    // in the set of records that were just accepted (client will update those
    // from the accepted list).
    final newRecords = serverMap.values
        .where((t) {
          final s = t.seq;
          return s != null && s > lastSeq && !acceptedIds.contains(t.id);
        })
        .map((t) => t.toJson())
        .toList();

    final serverSeq = await storage.loadSequence();

    return Response.ok(
      jsonEncode({
        'accepted': accepted,
        'conflicts': conflicts,
        'new_records': newRecords,
        'server_seq': serverSeq,
      }),
      headers: _json,
    );
  });

  // ── Queue endpoints ───────────────────────────────────────────────────────

  /// GET /queue → { "items": [ ...urls... ] }
  router.get('/queue', (Request request) async {
    final queue = await storage.loadQueue();
    return Response.ok(jsonEncode({'items': queue}), headers: _json);
  });

  /// POST /queue — add URLs to the queue
  /// Body: { "items": [ ...urls... ] }  or  { "item": "url" }
  router.post('/queue', (Request request) async {
    final body = await request.readAsString();
    final Map<String, dynamic> payload;
    try {
      payload = jsonDecode(body) as Map<String, dynamic>;
    } catch (_) {
      return Response(400, body: jsonEncode({'error': 'Invalid JSON'}),
          headers: _json);
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
    return Response.ok(jsonEncode({'queued': queue.length}), headers: _json);
  });

  /// DELETE /queue — remove successfully-processed items
  /// Body: { "items": [ ...urls... ] }
  router.delete('/queue', (Request request) async {
    final body = await request.readAsString();
    final Map<String, dynamic> payload;
    try {
      payload = jsonDecode(body) as Map<String, dynamic>;
    } catch (_) {
      return Response(400, body: jsonEncode({'error': 'Invalid JSON'}),
          headers: _json);
    }

    final toRemove = Set<String>.from(
      (payload['items'] as List<dynamic>? ?? []).cast<String>(),
    );
    final queue = await storage.loadQueue();
    final remaining = queue.where((u) => !toRemove.contains(u)).toList();
    await storage.saveQueue(remaining);

    return Response.ok(
      jsonEncode({'removed': toRemove.length, 'remaining': remaining.length}),
      headers: _json,
    );
  });

  // ── Individual transaction CRUD ───────────────────────────────────────────

  /// GET /transactions → all transactions
  router.get('/transactions', (Request request) async {
    final txs = await storage.loadTransactions();
    return Response.ok(
      jsonEncode({'transactions': txs.values.map((t) => t.toJson()).toList()}),
      headers: _json,
    );
  });

  /// POST /transactions — upsert a single transaction
  router.post('/transactions', (Request request) async {
    final body = await request.readAsString();
    final Map<String, dynamic> raw;
    try {
      raw = jsonDecode(body) as Map<String, dynamic>;
    } catch (_) {
      return Response(400, body: jsonEncode({'error': 'Invalid JSON'}),
          headers: _json);
    }

    final tx = ServerTransaction.fromJson(raw);
    if (tx == null) {
      return Response(400,
          body: jsonEncode({'error': 'Missing or invalid "id" field'}),
          headers: _json);
    }

    final txs = await storage.loadTransactions();
    txs[tx.id] = tx;
    await storage.saveTransactions(txs);

    return Response.ok(jsonEncode({'saved': tx.id}), headers: _json);
  });

  /// DELETE /transactions/<id>
  router.delete('/transactions/<id>', (Request request, String id) async {
    final txs = await storage.loadTransactions();
    final existed = txs.containsKey(id);
    txs.remove(id);
    await storage.saveTransactions(txs);

    return Response.ok(
      jsonEncode({'deleted': id, 'existed': existed}),
      headers: _json,
    );
  });

  /// GET /conflicts — list all detected conflicts for human review
  router.get('/conflicts', (Request request) async {
    final conflicts = await storage.loadConflicts();
    return Response.ok(
      jsonEncode({'conflicts': conflicts}),
      headers: _json,
    );
  });

  return router;
}

const _json = {'content-type': 'application/json'};
