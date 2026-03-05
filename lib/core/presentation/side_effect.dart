typedef SideEffectPusher<T> = void Function(T effect);

/// Generic base class for emitting side effects
///
/// This class provides a decoupled mechanism for controllers to emit
/// one-time side effects (events) to the UI layer without direct dependencies.
///
/// ## Use Cases
///
/// - Navigation actions (push, pop, replace)
/// - Snackbar notifications
/// - Dialog displays
/// - Bottom sheet triggers
/// - Loading/Error state notifications
///
/// ## Example
///
/// ```dart
/// // Define your side effects as an enum or sealed class
/// sealed class AppSideEffect {
///   case navigateTo(Uri path);
///   case showSnackbar(String message);
///   case showDialog(Widget dialog);
/// }
/// ```
class SideEffector<T> {
  SideEffectPusher<T>? _pusher;

  /// Emits the given side effect to the registered pusher (if any).
  ///
  /// This is an internal method that [push] delegates to.
  /// It safely handles the case where no pusher is attached.
  void _emit(T effect) {
    _pusher?.call(effect);
  }

  /// Pushes a side effect to the UI layer.
  ///
  /// If a pusher has been attached via [attach], the effect will be
  /// delivered immediately. Otherwise, the call is a no-op.
  ///
  /// Parameters:
  /// - [effect]: The side effect to emit (e.g., navigation, snackbar)
  ///
  /// Example:
  /// ```dart
  /// controller.push(const NavigateToHome());
  /// controller.push(const ShowSnackbar('Operation successful'));
  /// ```
  void push(T effect) {
    _emit(effect);
  }

  /// Attaches a pusher function to receive side effects.
  ///
  /// Typically called by a StatefulWidget's initState or a Riverpod
  /// listener to wire up the controller to the UI.
  ///
  /// Parameters:
  /// - [pusher]: A function that handles the side effect
  ///
  /// Example:
  /// ```dart
  /// controller.attach((effect) {
  ///   switch (effect) {
  ///     case NavigateToHome():
  ///       Navigator.pushNamed(context, '/home');
  ///     case ShowSnackbar(:message):
  ///       ScaffoldMessenger.showSnackBar(SnackBar(message));
  ///   }
  /// });
  /// ```
  // ignore: use_setters_to_change_properties
  void attach(SideEffectPusher<T> pusher) {
    _pusher = pusher;
  }

  /// Detaches the current pusher, stopping further side effects delivery.
  ///
  /// Call this in dispose to clean up and prevent memory leaks.
  ///
  /// Example:
  /// ```dart
  /// @override
  /// void dispose() {
  ///   controller.detach();
  ///   super.dispose();
  /// }
  /// ```
  void detach() {
    _pusher = null;
  }
}
