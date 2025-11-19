class ListenerInfo {
  final String? name;
  final String? detail;
  bool active;
  int totalCalls;
  int lastDurationMs;
  String? lastError;

  ListenerInfo({this.name, this.detail, this.active = true})
      : totalCalls = 0,
        lastDurationMs = 0;
}

abstract class EventBusAdapter {
  List<String> get events;
  List<ListenerInfo> listenersOf(String eventName);
  void fire(String eventName, String payload);
  bool get canFire => true;
  int fireCountOf(String eventType);
  (String? label, DateTime? ts) lastFireOf(String eventType);
  int activeListenersCountOf(String eventType);
  void markListenerCancelled(String eventType, String label);
  void recordListenerDuration(String eventType, String label, int ms);
  void recordListenerError(String eventType, String label, String error);
  void recordFire(Object event, String label);
}