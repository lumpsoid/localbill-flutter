import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../domain/entities/transaction.dart';
import '../domain/repositories/transaction_repository.dart';

/// Stores each transaction as a JSON file in the app's documents directory
/// under `localbill/transactions/`.
///
/// Deletes are soft: the file is updated with `deleted: true` rather than
/// removed, so the sync engine can propagate deletions to the server.
///
/// The last acknowledged server sequence number is stored in
/// `localbill/last_seq.txt` as a plain integer.
class LocalTransactionRepository implements TransactionRepository {
  Future<Directory> _txDir() async {
    final base = await getApplicationDocumentsDirectory();
    final dir = Directory('${base.path}/localbill/transactions');
    await dir.create(recursive: true);
    return dir;
  }

  Future<File> _seqFile() async {
    final base = await getApplicationDocumentsDirectory();
    await Directory('${base.path}/localbill').create(recursive: true);
    return File('${base.path}/localbill/last_seq.txt');
  }

  File _txFile(Directory dir, String id) => File('${dir.path}/$id.json');

  Future<List<Transaction>> _readAll() async {
    final dir = await _txDir();
    final files = await dir
        .list()
        .where((e) => e is File && e.path.endsWith('.json'))
        .cast<File>()
        .toList();

    final transactions = <Transaction>[];
    for (final f in files) {
      try {
        final json = jsonDecode(await f.readAsString()) as Map<String, dynamic>;
        transactions.add(Transaction.fromJson(json));
      } catch (_) {
        // Skip corrupt files.
      }
    }
    return transactions;
  }

  @override
  Future<List<Transaction>> loadAll() async {
    final all = await _readAll();
    final active = all.where((t) => !t.deleted).toList();
    active.sort((a, b) => b.date.compareTo(a.date));
    return active;
  }

  @override
  Future<List<Transaction>> loadAllForSync() async {
    final all = await _readAll();
    all.sort((a, b) => b.date.compareTo(a.date));
    return all;
  }

  @override
  Future<void> save(Transaction transaction) async {
    final dir = await _txDir();
    await _txFile(dir, transaction.id).writeAsString(
      jsonEncode(transaction.toJson()),
    );
  }

  @override
  Future<void> delete(String id) async {
    final dir = await _txDir();
    final f = _txFile(dir, id);
    if (!await f.exists()) return;
    try {
      final json = jsonDecode(await f.readAsString()) as Map<String, dynamic>;
      final tx = Transaction.fromJson(json);
      await save(tx.withEnvelope(deleted: true));
    } catch (_) {
      // If the file is corrupt, leave it in place rather than hard-deleting.
    }
  }

  @override
  Future<bool> isDuplicate(String url) async {
    final all = await loadAll(); // Only checks non-deleted
    return all.any((t) => t.link == url);
  }

  @override
  Future<int> loadLastSeq() async {
    final f = await _seqFile();
    if (!await f.exists()) return 0;
    try {
      return int.parse((await f.readAsString()).trim());
    } catch (_) {
      return 0;
    }
  }

  @override
  Future<void> saveLastSeq(int seq) async {
    final f = await _seqFile();
    await f.writeAsString('$seq');
  }
}
