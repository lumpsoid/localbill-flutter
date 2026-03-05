/// Type alias for state updater callback
typedef StateUpdater<State> = void Function(State state);

/// Abstract base presenter with generic state management
abstract class Presenter<State> {
  Presenter(this._current);

  StateUpdater<State>? _updater;

  State _current;

  /// Emits state to the UI
  void _emit(State model) {
    _updater?.call(model);
  }

  /// Updates the state using a reducer function
  void updateState(State Function(State) reducer) {
    _current = reducer(_current);
    _emit(_current);
  }

  /// Attaches the presenter to a UI sink
  void attach(StateUpdater<State> sink) {
    _updater = sink;
    _updater!(_current);
  }

  /// Detaches the presenter from the UI
  void detach() {
    _updater = null;
  }
}
