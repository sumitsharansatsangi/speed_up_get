import 'package:equatable/equatable.dart';
import 'package:get/get_rx/get_rx.dart';

/// GetRxDecorator for Rx<T> variables in Get library [https://pub.dev/packages/get]
/// This wrapper lets to apply UDF concept and makes it easier
/// to work with Getx' Rx<T> and Obx.
///
/// ============================================================================
///
/// Why one need to use this decorator? Because of problem with Rx<T> variables:
///
/// Mainly, direct using this reactive variables violates all of known
/// design patterns. Client (some View) send command to change state
/// and get result immediately without Model processing.
///
/// We should to hide variable itself behind accessors, and this decorator
/// makes it in very handy way.
///
/// ============================================================================
///
/// Without GetRxDecorator
///
/// ```dart
///   // declarations:
///
///   /// 1. Variable itself.
///   final _clickCounterUdf = 0.obs;
///
///   /// 2. Getter
///   int get clickCounterUdf => _clickCounterUdf();
///
///   /// 3. Setter
///   set clickCounterUdf(int v) => _clickCounterUdf(_process(v));
///
///   /// 4. Stream
///   Stream<int> get clickCounterStreamUdf => _clickCounterUdf.stream;
///
///   /// This processor drops values above 3 down to zero.
///   int _process(int v) => v > 3 ? 0 : v;
///
///   //=======================================================
///
///   // using:
///   // Somewhere in View
///   return Center(
///     child: ElevatedButton(
///       child: Obx(
///          () => Text('value = ${controller.clickCounterUdf}'),
///       ),
///       onPressed: () => controller.clickCounterUdf++,
///     ),
///   );
/// ```
///
/// With GetRxDecorator
///
/// ```dart
///
/// // declaration:
///
/// /// Encapsulated Rx variable
/// late var clickCounterDecor = 0.obsDeco(setter: (_, newValue, __) =>
///   _process(newValue ?? 0));
///
/// //=========================================================================
///
/// // using:
/// // Somewhere in View
/// return Center(
///  child: ElevatedButton(
///    child: Obx(
///          () => Text('value = ${controller.clickCounterDecor}'),
///    ),
///    onPressed: () => controller.clickCounterDecor++,
///  ),
/// );
///
/// ```
class GetRxDecorator<T> extends Equatable {
  GetRxDecorator(
    T initial, {
    this.forceUpdate,
    GetRxDecoratorSetter<T>? setter,
  })  : _src = Rx<T>(initial),
        _setter = setter;

  /// Inner .obs variable.
  final Rx<T> _src;

  /// Callback for adjust custom setter.
  /// [oldValue] parameter allows to apply specific algorithms,
  ///   e.g. without [newValue], like a Collatz conjecture (see tests).
  /// [args] parameter allows using additional arguments in algorithms,
  ///   e.g. type or instance of variable's sender or something (see tests).
  final GetRxDecoratorSetter<T>? _setter;

  /// Safe reference to inner value.
  T get value => _src();

  /// Reference to .obs inner stream.
  Stream<T> get stream => _src.stream;
  Stream<T> get value$ => stream;

  /// Force update - trigger even value is the same.
  final bool? forceUpdate;

  /// Use [this] as functional object with parameters:
  /// value means new value. Optional.
  /// args means additional argument(s) for some use cases. Optional.
  T? call({T? value, dynamic args}) {
    setValue(newValue: value, args: args);
    return value;
  }

  /// We can use either custom setter or default setting mechanism.
  ///
  /// newValue: value to be set. It may be null in some logic cases. Optional.
  /// args: optional dynamic parameter. In some cases, you may need
  ///   an additional call context to select the logic of changing a variable.
  void setValue({T? newValue, dynamic args}) {
    // Prepare for adjust latter auto refresh.
    final isSameValue = newValue == _src();

    if (_setter == null) {
      _src(newValue);
    } else {
      // Here we can return as `wrong` either [oldValue] or null.
      final candidate = _setter!(value, newValue, args);
      _src(candidate);
    }

    if (isSameValue && (forceUpdate ?? false)) {
      refresh();
    }
  }

  void refresh() => _src.refresh();

  /// Same as `toString()` but using a getter.
  String get string => value$.toString();

  @override
  String toString() => value$.toString();

  @override
  List<Object?> get props => [_src];
}

typedef GetRxDecoratorSetter<T> = T? Function(
    T oldValue, T? newValue, dynamic args);

////////////////////////////////////////////////////////////////////////////////
///
class GetRxDecoratorInt extends GetRxDecorator<int> {
  GetRxDecoratorInt(int initial,
      {bool? forceUpdate, GetRxDecoratorSetter<int>? setter})
      : super(initial, forceUpdate: forceUpdate, setter: setter);

  /// Addition operator.
  GetRxDecoratorInt operator +(int add) {
    setValue(newValue: _src.value + add);
    return this;
  }

  /// Subtraction operator.
  GetRxDecoratorInt operator -(int sub) {
    setValue(newValue: _src.value - sub);
    return this;
  }
}

///
extension IntGetRxDecoratorX on int {
  GetRxDecoratorInt obsDeco(
          {bool? forceUpdate, GetRxDecoratorSetter<int>? setter}) =>
      GetRxDecoratorInt(this, forceUpdate: forceUpdate, setter: setter);
}

///
class GetRxDecoratorDouble extends GetRxDecorator<double> {
  GetRxDecoratorDouble(double initial,
      {bool? forceUpdate, GetRxDecoratorSetter<double>? setter})
      : super(initial, forceUpdate: forceUpdate, setter: setter);

  /// Addition operator.
  GetRxDecoratorDouble operator +(double add) {
    setValue(newValue: _src.value + add);
    return this;
  }

  /// Subtraction operator.
  GetRxDecoratorDouble operator -(double sub) {
    setValue(newValue: _src.value - sub);
    return this;
  }
}

///
extension DoubleGetRxDecoratorX on double {
  GetRxDecoratorDouble obsDeco(
          {bool? forceUpdate, GetRxDecoratorSetter<double>? setter}) =>
      GetRxDecoratorDouble(this, forceUpdate: forceUpdate, setter: setter);
}

///
class GetRxDecoratorBool extends GetRxDecorator<bool> {
  GetRxDecoratorBool(bool initial,
      {bool? forceUpdate, GetRxDecoratorSetter<bool>? setter})
      : super(initial, forceUpdate: forceUpdate, setter: setter);

  GetRxDecoratorBool toggle() {
    setValue(newValue: _src.value = !_src.value);
    return this;
  }
}

///
extension BoolGetRxDecoratorX on bool {
  GetRxDecoratorBool obsDeco({
    bool? forceUpdate,
    GetRxDecoratorSetter<bool>? setter,
  }) =>
      GetRxDecoratorBool(this, forceUpdate: forceUpdate, setter: setter);
}

///
class GetRxDecoratorString extends GetRxDecorator<String>
    implements Comparable<String>, Pattern {
  GetRxDecoratorString(String initial,
      {bool? forceUpdate, GetRxDecoratorSetter<String>? setter})
      : super(initial, forceUpdate: forceUpdate, setter: setter);

  GetRxDecoratorString operator +(String add) {
    setValue(newValue: _src.value + add);
    return this;
  }

  @override
  Iterable<Match> allMatches(String string, [int start = 0]) {
    return _src.value.allMatches(string, start);
  }

  @override
  Match? matchAsPrefix(String string, [int start = 0]) {
    return _src.value.matchAsPrefix(string, start);
  }

  @override
  int compareTo(String other) {
    return _src.value.compareTo(other);
  }
}

///
extension StringGetRxDecoratorX on String {
  GetRxDecoratorString obsDeco({
    bool? forceUpdate,
    GetRxDecoratorSetter<String>? setter,
  }) =>
      GetRxDecoratorString(this, forceUpdate: forceUpdate, setter: setter);
}
