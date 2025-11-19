import 'dart:async';

import 'package:event_bus/event_bus.dart';

import 'eventbus_default_adapter.dart';

extension ManaEventBusExtensions on EventBus {
  /// Attach a factory to create events from name & payload for debug firing.
  void setManaEventFactory(
    Object Function(String name, String payload) factory,
  ) {
    final adapter = EventBusDefaultAdapter.forBus(this);
    adapter.eventFactory = factory;
  }

  /// Register listener and record it to the adapter for introspection.
  StreamSubscription<T> onSpy<T>(
    String label,
    void Function(T event) listener,
  ) {
    final adapter = EventBusDefaultAdapter.forBus(this);
    adapter.registerListener<T>(label);
    return on<T>().listen(listener);
  }

  /// Fire event normally but also mark the event type as seen.
  void fireSpy<T>(T event) {
    final adapter = EventBusDefaultAdapter.forBus(this);
    adapter.registerListener<T>('fired');
    fire(event);
  }

  /// Get adapter linked to this bus, for passing into UI when you don't want to use closures.
  EventBusDefaultAdapter get manaAdapter => EventBusDefaultAdapter.forBus(this);
}
