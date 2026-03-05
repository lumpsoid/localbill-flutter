import 'package:fast_immutable_collections/fast_immutable_collections.dart';

import '../../../core/presentation/presenter.dart';
import '../../shared/domain/entities/transaction.dart';
import 'models/search_state.dart';

class SearchPresenter extends Presenter<SearchState> {
  SearchPresenter([SearchState? initialState])
    : super(initialState ?? const SearchState());

  void setSearching(String query) => updateState(
    (s) => s.copyWith(status: SearchStatus.searching, query: query),
  );

  void setResults(String query, List<Transaction> matches) {
    if (matches.isEmpty) {
      updateState(
        (s) => s.copyWith(status: SearchStatus.empty, query: query),
      );
      return;
    }

    final items = IList(
      matches.map(
        (t) => SearchResultItem(
          id: t.id,
          date: t.date.length >= 10 ? t.date.substring(0, 10) : t.date,
          name: t.name,
          retailer: t.retailer,
          unitPriceLabel: '${t.unitPrice.toStringAsFixed(2)} ${t.currency}',
          link: t.link,
        ),
      ),
    );

    updateState(
      (s) => s.copyWith(
        status: SearchStatus.results,
        query: query,
        results: items,
      ),
    );
  }

  void setDuplicates(Map<String, List<String>> groups) {
    final dupes = IList(
      groups.entries
          .where((e) => e.value.length > 1)
          .map((e) => IList(e.value)),
    );
    updateState(
      (s) => s.copyWith(
        status: SearchStatus.results,
        duplicateGroups: dupes,
      ),
    );
  }

  void setError(String message) => updateState(
    (s) => s.copyWith(status: SearchStatus.error, errorMessage: message),
  );

  void reset() => updateState((s) => const SearchState());
}
