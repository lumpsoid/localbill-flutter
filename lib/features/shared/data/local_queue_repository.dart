import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../domain/repositories/queue_repository.dart';

/// Stores the processing queue as a plain text file (one URL per line)
/// at `localbill/queue.txt`.
class LocalQueueRepository implements QueueRepository {
  Future<File> _file() async {
    final base = await getApplicationDocumentsDirectory();
    final dir = Directory('${base.path}/localbill');
    await dir.create(recursive: true);
    return File('${dir.path}/queue.txt');
  }

  @override
  Future<List<String>> loadAll() async {
    final f = await _file();
    if (!await f.exists()) return [];
    final lines = await f.readAsLines();
    return lines.map((l) => l.trim()).where((l) => l.isNotEmpty).toList();
  }

  @override
  Future<void> add(String url) async {
    final existing = await loadAll();
    if (existing.contains(url)) return;
    final f = await _file();
    await f.writeAsString('${existing.join('\n')}\n$url\n');
  }

  @override
  Future<void> remove(String url) async {
    final existing = await loadAll();
    await saveAll(existing.where((u) => u != url).toList());
  }

  @override
  Future<void> saveAll(List<String> urls) async {
    final f = await _file();
    await f.writeAsString(urls.isEmpty ? '' : '${urls.join('\n')}\n');
  }

  @override
  Future<void> clear() async {
    final f = await _file();
    if (await f.exists()) await f.delete();
  }
}
