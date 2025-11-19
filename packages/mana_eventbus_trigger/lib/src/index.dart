import 'package:flutter/material.dart';
import 'package:mana/mana.dart';

import 'icon.dart';
import 'widgets/eventbus_trigger.dart';
import 'eventbus_adapter.dart';
import 'eventbus_default_adapter.dart';

class ManaEventbusTrigger extends ManaPluggable {
  final EventBusAdapter? adapter;
  final Object Function(String name, String payload)? eventFactory;
  final dynamic bus;

  ManaEventbusTrigger({this.adapter, this.eventFactory, this.bus});

  @override
  Widget? buildWidget(BuildContext? context) {
    EventBusAdapter? a = adapter;
    final b = bus;
    if (a == null && b != null) {
      try {
        final d = EventBusDefaultAdapter.forBus(b);
        d.eventFactory = eventFactory;
        a = d;
      } catch (_) {}
    }
    return EventbusTrigger(name: name, adapter: a);
  }

  @override
  ImageProvider<Object> get iconImageProvider => iconImage;

  @override
  String get name => 'mana_eventbus_trigger';

  @override
  String getLocalizedDisplayName(Locale locale) {
    if (locale.languageCode == 'zh') {
      return 'EventBus触发器';
    }
    return 'Eventbus Trigger';
  }
}
