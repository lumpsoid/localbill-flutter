import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:meta/meta.dart';

@immutable
class SearchResultItem {
  const SearchResultItem({
    required this.id,
    required this.date,
    required this.name,
    required this.retailer,
    required this.unitPriceLabel,
    required this.link,
  });

  final String id;
  final String date;
  final String name;
  final String retailer;
  final String unitPriceLabel;
  final String? link;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SearchResultItem &&
          other.id == id &&
          other.name == name &&
          other.retailer == retailer;

  @override
  int get hashCode => Object.hash(id, name, retailer);
}

enum SearchStatus { idle, searching, results, empty, error }

class SearchState {
  const SearchState({
    this.status = SearchStatus.idle,
    this.query = '',
    this.results = const IListConst([]),
    this.duplicateGroups = const IListConst([]),
    this.errorMessage,
  });

  final SearchStatus status;
  final String query;
  final IList<SearchResultItem> results;

  /// For the duplicates view: each inner list is a group sharing a URL.
  final IList<IList<String>> duplicateGroups;
  final String? errorMessage;

  SearchState copyWith({
    SearchStatus? status,
    String? query,
    IList<SearchResultItem>? results,
    IList<IList<String>>? duplicateGroups,
    String? errorMessage,
  }) => SearchState(
    status: status ?? this.status,
    query: query ?? this.query,
    results: results ?? this.results,
    duplicateGroups: duplicateGroups ?? this.duplicateGroups,
    errorMessage: errorMessage ?? this.errorMessage,
  );
}
