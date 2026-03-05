import 'dart:convert';
import 'dart:io';

import 'models.dart';

/// Simple file-backed JSON storage.
///
/// Transactions are stored in `data/transactions.json` and the queue in
/// `data/queue.json`, relative to the current working directory.
class JsonStorage {
  JsonStorage({String dataDir = 'data'}) : _dataDir = dataDir;

  final String _dataDir;

  File get _txFile => File('$_dataDir/transactions.json');
  File get _queueFile => File('$_dataDir/queue.json');

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
