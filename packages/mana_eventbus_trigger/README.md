# Mana Eventbus Trigger

一个用于调试 EventBus 的插件：查看所有事件、查看监听者、触发事件。

## 快速开始

```dart
import 'package:flutter/material.dart';
import 'package:mana/mana.dart';
import 'package:mana_eventbus_trigger/mana_eventbus_trigger.dart';
import 'package:event_bus/event_bus.dart';

class StringEvent {
  final String name;
  final String payload;
  StringEvent(this.name, this.payload);
}

// 方式一：零侵入（仅事件查看）
// 传入已有的 bus 实例（无需改造），即可查看已触发过的事件类型；
// 若需在面板中 Fire，请设置事件工厂。

void main() {
  final bus = EventBus();

  // 可选：设置事件工厂，使面板的 Fire 按钮能发出你需要的事件类型
  bus.setManaEventFactory((name, payload) => StringEvent(name, payload));

  // 可选：用 onSpy 记录监听者信息（同时保留原有监听行为）
  bus.onSpy<StringEvent>('order.created', (e) {});
  bus.onSpy<StringEvent>('user.login', (e) {});

  // 注册插件，直接传入 bus（不强制 adapter）
  ManaPluginManager.instance.register(ManaEventbusTrigger(bus: bus));

  runApp(ManaWidget(child: const App()));
}

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(body: Center(child: Text('Mana Eventbus Trigger'))),
    );
  }
}
```

## 功能

- 查看事件列表与监听者数量
- 查看选中事件的监听者详情
- 输入载荷并触发事件