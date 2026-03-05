import 'package:flutter/material.dart' hide SearchController;

import 'models/search_state.dart';
import 'search_controller.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({required this.controller, super.key});

  final SearchController controller;

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  late final ValueNotifier<SearchState> _state;
  final _queryController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _state = ValueNotifier(const SearchState());
    widget.controller.onViewAttach(
      updater: (s) => _state.value = s,
      pusher: _onEffect,
    );
  }

  void _onEffect(SearchEffect effect) {
    if (!mounted) return;
    switch (effect) {
      case SearchErrorEffect(:final message):
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(message)));
    }
  }

  @override
  void dispose() {
    widget.controller.onViewDetach();
    _state.dispose();
    _queryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<SearchState>(
      valueListenable: _state,
      builder: (context, state, _) {
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _queryController,
                      decoration: InputDecoration(
                        hintText: 'Search by product name…',
                        border: const OutlineInputBorder(),
                        isDense: true,
                        suffixIcon: _queryController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  _queryController.clear();
                                  widget.controller.onSearch('');
                                },
                              )
                            : null,
                      ),
                      onChanged: widget.controller.onSearch,
                    ),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton(
                    onPressed: widget.controller.onFindDuplicates,
                    child: const Text('Dupes'),
                  ),
                ],
              ),
            ),
            Expanded(child: _Body(state: state)),
          ],
        );
      },
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.state});

  final SearchState state;

  @override
  Widget build(BuildContext context) {
    switch (state.status) {
      case SearchStatus.idle:
        return const Center(child: Text('Type to search transactions.'));
      case SearchStatus.searching:
        return const Center(child: CircularProgressIndicator());
      case SearchStatus.empty:
        return Center(child: Text('No matches for "${state.query}".'));
      case SearchStatus.error:
        return Center(child: Text(state.errorMessage ?? 'Error'));
      case SearchStatus.results:
        if (state.duplicateGroups.isNotEmpty) {
          return _DuplicateList(groups: state.duplicateGroups);
        }
        return _ResultList(items: state.results);
    }
  }
}

class _ResultList extends StatelessWidget {
  const _ResultList({required this.items});

  final dynamic items;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: items.length,
      itemBuilder: (context, i) {
        final item = items[i] as SearchResultItem;
        return ListTile(
          title: Text(item.name, maxLines: 1, overflow: TextOverflow.ellipsis),
          subtitle: Text('${item.retailer} · ${item.date}'),
          trailing: Text(
            item.unitPriceLabel,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        );
      },
    );
  }
}

class _DuplicateList extends StatelessWidget {
  const _DuplicateList({required this.groups});

  final dynamic groups;

  @override
  Widget build(BuildContext context) {
    final dupes = (groups as Iterable).where((g) => (g as Iterable).length > 1).toList();
    if (dupes.isEmpty) {
      return const Center(child: Text('No duplicate invoice URLs found.'));
    }
    return ListView.builder(
      itemCount: dupes.length,
      itemBuilder: (context, i) {
        final group = dupes[i] as Iterable;
        return ExpansionTile(
          title: Text('Duplicate group ${i + 1} (${group.length} items)'),
          children: group
              .map<Widget>(
                (name) => ListTile(
                  dense: true,
                  leading: const Icon(Icons.arrow_right),
                  title: Text(name.toString()),
                ),
              )
              .toList(),
        );
      },
    );
  }
}
