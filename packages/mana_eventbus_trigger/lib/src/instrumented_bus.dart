import 'dart:async';

import 'package:event_bus/event_bus.dart';

import 'eventbus_default_adapter.dart';

class ManaInstrumentedEventBus {
  final EventBus _inner;
  final EventBusDefaultAdapter _adapter;

  ManaInstrumentedEventBus(EventBus inner)
    : _inner = inner,
      _adapter = EventBusDefaultAdapter.forBus(inner);

  EventBus get bus => _inner;

  Stream<T> on<T>() {
    final label = _buildLabel(StackTrace.current.toString());
    return _InstrumentedStream<T>(_inner.on<T>(), _adapter, label);
  }

  void fire<T>(T event) {
    final label = _buildLabel(StackTrace.current.toString());
    _adapter.recordFire(event as Object, label);
    _inner.fire(event);
  }
}

String _buildLabel(String stack) {
  final framePattern = RegExp(r"#\d+\s+([^\s]+)\s+\(([^)]+)\)");
  final matches = framePattern.allMatches(stack);
  for (final m in matches) {
    final fn = m.group(1) ?? '';
    final loc = m.group(2) ?? '';
    if (loc.contains('package:event_bus') ||
        loc.contains('package:mana_eventbus_trigger') ||
        loc.contains('package:flutter')) {
      continue;
    }
    final mLoc = RegExp(r"([^/\\]+\.dart):(\d+)").firstMatch(loc);
    if (mLoc != null) {
      final file = mLoc.group(1) ?? '';
      final line = mLoc.group(2) ?? '';
      return fn.isNotEmpty ? '$fn $file:$line' : '$file:$line';
    }
    if (fn.isNotEmpty) return fn;
  }
  return 'listener';
}

class _InstrumentedStream<T> extends Stream<T> {
  final Stream<T> _inner;
  final EventBusDefaultAdapter _adapter;
  final String _label;

  _InstrumentedStream(this._inner, this._adapter, this._label);

  @override
  StreamSubscription<T> listen(
    void Function(T event)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) {
    _adapter.registerListener<T>(_label);
    final startEndWrapper = (T e) {
      final t0 = DateTime.now();
      try {
        if (onData != null) onData(e);
      } catch (err) {
        _adapter.recordListenerError(T.toString(), _label, err.toString());
        if (onError != null) {
          onError(err);
          return;
        }
        rethrow;
      } finally {
        final ms = DateTime.now().difference(t0).inMilliseconds;
        _adapter.recordListenerDuration(T.toString(), _label, ms);
      }
    };
    final innerSub = _inner.listen(
      onData != null ? startEndWrapper : null,
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError ?? false,
    );
    return _InstrumentedSubscription<T>(innerSub, () {
      _adapter.markListenerCancelled(T.toString(), _label);
    });
  }
}

class _InstrumentedSubscription<T> implements StreamSubscription<T> {
  final StreamSubscription<T> _inner;
  final void Function() _onCancel;
  _InstrumentedSubscription(this._inner, this._onCancel);

  @override
  Future<void> cancel() async {
    _onCancel();
    return _inner.cancel();
  }

  @override
  bool get isPaused => _inner.isPaused;

  @override
  void onData(void Function(T data)? handleData) => _inner.onData(handleData);

  @override
  void onDone(void Function()? handleDone) => _inner.onDone(handleDone);

  @override
  void onError(Function? handleError) => _inner.onError(handleError);

  @override
  void pause([Future<void>? resumeSignal]) => _inner.pause(resumeSignal);

  @override
  void resume() => _inner.resume();

  @override
  Future<E> asFuture<E>([E? futureValue]) => _inner.asFuture(futureValue);
}
