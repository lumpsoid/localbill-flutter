import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../domain/entities/transaction.dart';
import '../domain/repositories/transaction_repository.dart';

/// Stores each transaction as a JSON file in the app's documents directory
/// under `localbill/transactions/`.
class LocalTransactionRepository implements TransactionRepository {
  Future<Directory> _dir() async {
    final base = await getApplicationDocumentsDirectory();
    final dir = Directory('${base.path}/localbill/transactions');
    await dir.create(recursive: true);
    return dir;
  }

  File _file(Directory dir, String id) => File('${dir.path}/$id.json');

  @override
  Future<List<Transaction>> loadAll() async {
    final dir = await _dir();
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

    // Sort by date descending.
    transactions.sort((a, b) => b.date.compareTo(a.date));
    return transactions;
  }

  @override
  Future<void> save(Transaction transaction) async {
    final dir = await _dir();
    await _file(dir, transaction.id).writeAsString(
      jsonEncode(transaction.toJson()),
    );
  }

  @override
  Future<void> delete(String id) async {
    final dir = await _dir();
    final f = _file(dir, id);
    if (await f.exists()) await f.delete();
  }

  @override
  Future<bool> isDuplicate(String url) async {
    final all = await loadAll();
    return all.any((t) => t.link == url);
  }
}
