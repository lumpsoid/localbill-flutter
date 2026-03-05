import 'package:collection/collection.dart';
import 'package:flutter/widgets.dart';

/// A selector that works with [Listenable] objects and only rebuilds
/// the widget when the selector changes.
class Selector<T> extends StatefulWidget {
  /// Creates a [Selector] widget.
  ///
  /// The [builder] and [selector] must not be null.
  const Selector({
    required this.builder,
    required this.selector,
    required this.listenable,
    bool Function(T previous, T next)? shouldRebuild,
    this.child,
    super.key,
  }) : _shouldRebuild = shouldRebuild;

  /// A function that builds a widget tree from `child` and the last result of
  /// [selector]. This will be called when the selector changes.
  final ValueWidgetBuilder<T> builder;

  /// A function that takes the current state of the [Listenable] and
  /// returns a selected value that will be used for the [builder].
  final T Function(BuildContext) selector;

  /// The [Listenable] object to listen to for changes.
  final Listenable listenable;

  final bool Function(T previous, T next)? _shouldRebuild;

  final Widget? child;

  @override
  State<Selector<T>> createState() => _SelectorState<T>();
}

class _SelectorState<T> extends State<Selector<T>> {
  T? value;
  Widget? cache;
  Widget? oldWidget;

  @override
  void initState() {
    super.initState();
    // Register the listener for the initial listenable
    widget.listenable.addListener(_onListenableChange);
  }

  @override
  void dispose() {
    // Remove listener from the current listenable before disposing
    widget.listenable.removeListener(_onListenableChange);
    super.dispose();
  }

  @override
  void didUpdateWidget(Selector<T> oldWidget) {
    super.didUpdateWidget(oldWidget);

    // If the listenable has changed, we unregister the listener from the old
    // listenable and register the listener for the new listenable.
    if (widget.listenable != oldWidget.listenable) {
      oldWidget.listenable.removeListener(_onListenableChange);
      widget.listenable.addListener(_onListenableChange);
    }
  }

  /// This is called whenever the [Listenable] notifies its listeners.
  void _onListenableChange() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final selected = widget.selector(context);

    final shouldInvalidateCache =
        oldWidget != widget ||
        (widget._shouldRebuild != null &&
            widget._shouldRebuild!(value as T, selected)) ||
        (widget._shouldRebuild == null &&
            !const DeepCollectionEquality().equals(value, selected));

    if (shouldInvalidateCache) {
      value = selected;
      oldWidget = widget;
      cache = Builder(
        builder: (context) => widget.builder(
          context,
          selected,
          widget.child,
        ),
      );
    }
    return cache!;
  }
}
