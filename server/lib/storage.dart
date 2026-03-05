import 'dart:convert';
import 'dart:io';

import 'models.dart';

/// Simple file-backed JSON storage.
///
/// Layout under [dataDir]:
///   transactions.json  — list of all transaction JSON objects
///   queue.json         — list of queued URLs
///   seq.txt            — current sequence counter (integer)
///   conflicts.json     — list of conflict records for human review
class JsonStorage {
  JsonStorage({String dataDir = 'data'}) : _dataDir = dataDir;

  final String _dataDir;

  File get _txFile => File('$_dataDir/transactions.json');
  File get _queueFile => File('$_dataDir/queue.json');
  File get _seqFile => File('$_dataDir/seq.txt');
  File get _conflictsFile => File('$_dataDir/conflicts.json');

  Future<void> _ensureDir() async {
    await Directory(_dataDir).create(recursive: true);
  }

  // ── Transactions ──────────────────────────────────────────────────────────

  Future<Map<String, ServerTransaction>> loadTransactions() async {
    await _ensureDir();
    if (!await _txFile.exists()) return {};
    try {
      final content = await _txFile.readAsString();
      final list = jsonDecode(content) as List<dynamic>;
      final map = <String, ServerTransaction>{};
      for (final item in list) {
        final tx = ServerTransaction.fromJson(item as Map<String, dynamic>);
        if (tx != null) map[tx.id] = tx;
      }
      return map;
    } catch (_) {
      return {};
    }
  }

  Future<void> saveTransactions(Map<String, ServerTransaction> txs) async {
    await _ensureDir();
    final list = txs.values.map((t) => t.toJson()).toList();
    await _txFile.writeAsString(jsonEncode(list));
  }

  // ── Sequence counter ──────────────────────────────────────────────────────

  /// Returns the current sequence counter (0 if file does not exist).
  Future<int> loadSequence() async {
    await _ensureDir();
    if (!await _seqFile.exists()) return 0;
    try {
      return int.parse((await _seqFile.readAsString()).trim());
    } catch (_) {
      return 0;
    }
  }

  /// Atomically increments the counter and returns the new value.
  Future<int> nextSequence() async {
    final current = await loadSequence();
    final next = current + 1;
    await _seqFile.writeAsString('$next');
    return next;
  }

  /// Overwrites the counter. Use with care.
  Future<void> saveSequence(int seq) async {
    await _ensureDir();
    await _seqFile.writeAsString('$seq');
  }

  // ── Conflict log ──────────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> loadConflicts() async {
    await _ensureDir();
    if (!await _conflictsFile.exists()) return [];
    try {
      return (jsonDecode(await _conflictsFile.readAsString()) as List<dynamic>)
          .cast<Map<String, dynamic>>();
    } catch (_) {
      return [];
    }
  }

  Future<void> appendConflict(Map<String, dynamic> conflict) async {
    final existing = await loadConflicts();
    existing.add(conflict);
    await _conflictsFile.writeAsString(jsonEncode(existing));
  }

  // ── Queue ─────────────────────────────────────────────────────────────────

  Future<List<String>> loadQueue() async {
    await _ensureDir();
    if (!await _queueFile.exists()) return [];
    try {
      final content = await _queueFile.readAsString();
      return (jsonDecode(content) as List<dynamic>).cast<String>();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveQueue(List<String> urls) async {
    await _ensureDir();
    await _queueFile.writeAsString(jsonEncode(urls));
  }
}
