abstract interface class QueueRepository {
  /// Returns all queued URLs.
  Future<List<String>> loadAll();

  /// Adds [url] to the queue (idempotent).
  Future<void> add(String url);

  /// Removes [url] from the queue.
  Future<void> remove(String url);

  /// Replaces the entire queue with [urls].
  Future<void> saveAll(List<String> urls);

  /// Clears all queued URLs.
  Future<void> clear();
}
