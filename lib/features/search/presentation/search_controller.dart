import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../core/presentation/presenter.dart';
import '../../../core/presentation/side_effect.dart';
import '../../shared/domain/repositories/transaction_repository.dart';
import 'models/search_state.dart';
import 'search_presenter.dart';

sealed class SearchEffect {
  const SearchEffect();
}

class SearchErrorEffect extends SearchEffect {
  const SearchErrorEffect(this.message);
  final String message;
}

class SearchController {
  SearchController({
    required TransactionRepository transactionRepository,
    SearchPresenter? presenter,
    SideEffector<SearchEffect>? effectPusher,
  }) : _repo = transactionRepository,
       _presenter = presenter ?? SearchPresenter(),
       _effectPusher = effectPusher ?? SideEffector<SearchEffect>();

  final TransactionRepository _repo;
  final SearchPresenter _presenter;
  final SideEffector<SearchEffect> _effectPusher;

  void onViewAttach({
    required StateUpdater<SearchState> updater,
    required SideEffectPusher<SearchEffect> pusher,
  }) {
    _presenter.attach(updater);
    _effectPusher.attach(pusher);
  }

  void onViewDetach() {
    _presenter.detach();
    _effectPusher.detach();
  }

  Future<void> onSearch(String query) async {
    if (query.trim().isEmpty) {
      _presenter.reset();
      return;
    }

    _presenter.setSearching(query);
    try {
      final all = await _repo.loadAll();
      final q = query.toLowerCase();
      final matches = all.where((t) => t.name.toLowerCase().contains(q)).toList();
      _presenter.setResults(query, matches);
    } on Object catch (e, trace) {
      debugPrint('SearchController.onSearch error: $e\n$trace');
      _presenter.setError('Search failed.');
      _effectPusher.push(const SearchErrorEffect('Search failed.'));
    }
  }

  Future<void> onFindDuplicates() async {
    _presenter.setSearching('duplicates');
    try {
      final all = await _repo.loadAll();
      // Group by invoice link URL.
      final groups = <String, List<String>>{};
      for (final t in all) {
        if (t.link == null || t.link!.isEmpty) continue;
        groups.putIfAbsent(t.link!, () => []).add(t.name);
      }
      _presenter.setDuplicates(groups);
    } on Object catch (e, trace) {
      debugPrint('SearchController.onFindDuplicates error: $e\n$trace');
      _presenter.setError('Failed to find duplicates.');
    }
  }
}
