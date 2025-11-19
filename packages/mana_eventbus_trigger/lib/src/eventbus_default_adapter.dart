import 'dart:convert';
import 'package:event_bus/event_bus.dart';
import 'eventbus_adapter.dart';

class RecordedEvent {
  final String type;
  final Object event;
  final DateTime ts;
  final Map<String, dynamic>? json;
  final String? label;
  RecordedEvent(this.type, this.event, this.ts, this.json, this.label);
}

class EventBusDefaultAdapter implements EventBusAdapter {
  static final Expando<EventBusDefaultAdapter> _expando =
      Expando<EventBusDefaultAdapter>('mana_eventbus_adapter');

  final EventBus bus;
  final Set<String> _events = <String>{};
  final Map<String, List<ListenerInfo>> _listeners = {};
  final Map<String, List<RecordedEvent>> _history = {};
  final Map<String, int> _fireCounts = {};
  final Map<String, (String? label, DateTime? ts)> _lastFire = {};
  final Map<
    String,
    (
      Map<String, dynamic> Function(Object) encode,
      Object Function(Map<String, dynamic>) decode,
    )
  >
  _serializers = {};

  Object Function(String name, String payload)? eventFactory;

  EventBusDefaultAdapter._(this.bus) {
    bus.on<Object>().listen((e) {
      final type = e.runtimeType.toString();
      _events.add(type);
      Map<String, dynamic>? json;
      final ser = _serializers[type];
      if (ser != null) {
        try {
          json = ser.$1(e);
        } catch (_) {}
      }
      final list = _history.putIfAbsent(type, () => <RecordedEvent>[]);
      list.add(RecordedEvent(type, e, DateTime.now(), json, null));
    });
  }

  static EventBusDefaultAdapter forBus(EventBus bus) =>
      _expando[bus] ??= EventBusDefaultAdapter._(bus);

  void registerListener<T>([String? label]) {
    final key = T.toString();
    var resolvedLabel = label;
    if (resolvedLabel == null) {
      final frames = StackTrace.current.toString().split('\n');
      String? candidate;
      for (final raw in frames) {
        final l = raw.trim();
        if (l.isEmpty) continue;
        if (l.contains('dart:')) continue;
        if (l.contains('package:event_bus')) continue;
        if (l.contains('package:mana_eventbus_trigger')) continue;
        final m1 = RegExp(r"^#\d+\s+([^\s]+)\s+\(([^)]+)\)").firstMatch(l);
        if (m1 != null) {
          final fn = m1.group(1) ?? '';
          final loc = m1.group(2) ?? '';
          final mLoc = RegExp(r"([^/\\]+\.dart):(\d+)").firstMatch(loc);
          if (mLoc != null) {
            final file = mLoc.group(1) ?? '';
            final line = mLoc.group(2) ?? '';
            candidate = '$fn $file:$line';
            break;
          }
          candidate = fn.isNotEmpty ? fn : l;
          break;
        }
        final m2 = RegExp(r"([^/\\]+\.dart):(\d+)").firstMatch(l);
        if (m2 != null) {
          final file = m2.group(1) ?? '';
          final line = m2.group(2) ?? '';
          candidate = '$file:$line';
          break;
        }
        candidate = l;
      }
      resolvedLabel = candidate ?? 'listener';
    }

    final list = _listeners.putIfAbsent(key, () => <ListenerInfo>[]);
    list.add(ListenerInfo(name: resolvedLabel, detail: key));
    _events.add(key);
  }

  void registerSerializer<T>(
    Map<String, dynamic> Function(T) encode,
    T Function(Map<String, dynamic>) decode,
  ) {
    final key = T.toString();
    _serializers[key] = ((o) => encode(o as T), (m) => decode(m) as Object);
  }

  List<RecordedEvent> historyOf(String eventType) =>
      List.unmodifiable(_history[eventType] ?? const []);

  void refireOriginal(String eventType, int index) {
    final h = _history[eventType];
    if (h == null || index < 0 || index >= h.length) return;
    bus.fire(h[index].event);
  }

  void refireJson(String eventType, String jsonText) {
    final ser = _serializers[eventType];
    if (ser == null) return;
    try {
      final map = json.decode(jsonText) as Map<String, dynamic>;
      final obj = ser.$2(map);
      bus.fire(obj);
    } catch (_) {}
  }

  @override
  List<String> get events => _events.toList()..sort();

  @override
  List<ListenerInfo> listenersOf(String eventName) =>
      List.unmodifiable(_listeners[eventName] ?? const []);

  @override
  void fire(String eventName, String payload) {
    final factory = eventFactory;
    if (factory == null) return;
    bus.fire(factory(eventName, payload));
  }

  @override
  bool get canFire => true;

  bool canEdit(String eventType) => _serializers.containsKey(eventType);

  @override
  int activeListenersCountOf(String eventType) {
    final ls = _listeners[eventType];
    if (ls == null) return 0;
    return ls.where((l) => l.active).length;
  }

  @override
  (String? label, DateTime? ts) lastFireOf(String eventType) =>
      _lastFire[eventType] ?? (null, null);

  @override
  int fireCountOf(String eventType) => _fireCounts[eventType] ?? 0;

  @override
  void markListenerCancelled(String eventType, String label) {
    final ls = _listeners[eventType];
    if (ls == null) return;
    for (final l in ls) {
      if (l.name == label) {
        l.active = false;
        break;
      }
    }
  }

  @override
  void recordListenerDuration(String eventType, String label, int ms) {
    final ls = _listeners[eventType];
    if (ls == null) return;
    for (final l in ls) {
      if (l.name == label) {
        l.totalCalls += 1;
        l.lastDurationMs = ms;
        break;
      }
    }
  }

  @override
  void recordListenerError(String eventType, String label, String error) {
    final ls = _listeners[eventType];
    if (ls == null) return;
    for (final l in ls) {
      if (l.name == label) {
        l.lastError = error;
        break;
      }
    }
  }

  @override
  void recordFire(Object event, String label) {
    final type = event.runtimeType.toString();
    _events.add(type);
    Map<String, dynamic>? json;
    final ser = _serializers[type];
    if (ser != null) {
      try {
        json = ser.$1(event);
      } catch (_) {}
    }
    final now = DateTime.now();
    final list = _history.putIfAbsent(type, () => <RecordedEvent>[]);
    list.add(RecordedEvent(type, event, now, json, label));
    _fireCounts[type] = (_fireCounts[type] ?? 0) + 1;
    _lastFire[type] = (label, now);
  }
}
