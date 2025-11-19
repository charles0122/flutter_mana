import 'dart:async';
import 'package:event_bus/event_bus.dart';
import 'package:mana/mana.dart';

import 'package:mana_database/mana_database.dart';
import 'package:mana_eventbus_trigger/mana_eventbus_trigger.dart';
import 'package:mana_stream_viewer/mana_stream_viewer.dart';

import 'detail.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mana_align_ruler/mana_align_ruler.dart';
import 'package:mana_color_sucker/mana_color_sucker.dart';
import 'package:mana_device_info/mana_device_info.dart';
import 'package:mana_dio_inspector/mana_dio_inspector.dart';
import 'package:mana_fps_monitor/mana_fps_monitor.dart';
import 'package:mana_grid/mana_grid.dart';
import 'package:mana_license/mana_license.dart';
import 'package:mana_log_viewer/mana_log_viewer.dart';
import 'package:mana_memory_info/mana_memory_info.dart';
import 'package:mana_package_info/mana_package_info.dart';
import 'package:mana_screen_info/mana_screen_info.dart';
import 'package:mana_shared_preferences_viewer/mana_shared_preferences_viewer.dart';
import 'package:mana_show_code/mana_show_code.dart';
import 'package:mana_touch_indicator/mana_touch_indicator.dart';
import 'package:mana_visual_helper/mana_visual_helper.dart';
import 'package:mana_widget_info_inspector/mana_widget_info_inspector.dart';

import 'utils/dio_client.dart';
import 'utils/log_generator.dart';
import 'utils/sp_client.dart';
import 'widgets/animated_ball.dart';
import 'widgets/custom_button.dart';

final demoBus = ManaInstrumentedEventBus(EventBus());

void main() async {
  EventBusDefaultAdapter.forBus(demoBus.bus);

  ManaPluginManager.instance
    ..register(ManaScreenInfo())
    ..register(ManaTouchIndicator())
    ..register(ManaVisualHelper())
    ..register(ManaGrid())
    ..register(ManaLicense())
    ..register(ManaPackageInfo())
    ..register(ManaMemoryInfo())
    ..register(ManaShowCode())
    ..register(ManaLogViewer())
    ..register(ManaDeviceInfo())
    ..register(ManaColorSucker())
    ..register(ManaDatabase())
    ..register(ManaEventbusTrigger(bus: demoBus.bus))
    ..register(ManaStreamViewer())
    ..register(ManaDioInspector())
    ..register(ManaWidgetInfoInspector())
    ..register(ManaFpsMonitor())
    ..register(ManaSharedPreferencesViewer())
    ..register(ManaAlignRuler());

  runApp(ManaWidget(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Example',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blueAccent),
      ),
      home: HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key, this.title = 'Mana Example'});

  final String title;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  bool isLandscape = false;

  void toggleOrientation() {
    if (isLandscape) {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ]);
    } else {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    }
    setState(() {
      isLandscape = !isLandscape;
    });
  }

  Future<void> sendRequest() async {
    await DioClient().randomRequest();
  }

  void addLog() {
    LogGenerator.generateRandomLog();
  }

  Future<void> addSharedPreferences() async {
    await SpClient.insertRandom();
  }

  @override
  void initState() {
    super.initState();
    demoBus.on<_DemoEvent>().listen((e) {
      debugPrint('received: ${e.name} ${e.payload}');
    });
    demoBus.on<_DemoEvent2>().listen((e) {
      debugPrint('received: ${e.name} ${e.num}');
    });
  }

  void fireDemoEvent() {
    demoBus.fire(_DemoEvent('order.created', DateTime.now().toIso8601String()));
  }

  void fireDemoEvent2() {
    demoBus.fire(_DemoEvent2('order.created', 123));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              CustomButton(
                text: 'Detail Page',
                backgroundColor: Colors.orange,
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const DetailPage()),
                  );
                },
              ),
              CustomButton(
                text: 'Toggle Orientation',
                backgroundColor: Colors.blue,
                onPressed: toggleOrientation,
              ),
              CustomButton(
                text: 'Send Request',
                backgroundColor: Colors.red,
                onPressed: sendRequest,
              ),
              CustomButton(
                text: 'Add Log',
                backgroundColor: Colors.cyan,
                onPressed: addLog,
              ),
              CustomButton(
                text: 'Add SharedPreferences',
                backgroundColor: Colors.deepPurple,
                onPressed: addSharedPreferences,
              ),
              CustomButton(
                text: 'Fire Demo Event',
                backgroundColor: Colors.green,
                onPressed: fireDemoEvent,
              ),
              CustomButton(
                text: 'Fire Demo Event 2',
                backgroundColor: Colors.pink,
                onPressed: fireDemoEvent2,
              ),
              Container(
                width: double.infinity,
                color: Colors.grey.shade200,
                padding: EdgeInsets.all(16),
                child: SelectableText('Test Animation'),
              ),
              AnimatedBall(),
              SizedBox(
                width: 300,
                child: Image.asset('assets/test.jpeg', fit: BoxFit.cover),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DemoEvent {
  final String name;
  final String payload;
  _DemoEvent(this.name, this.payload);
}

class _DemoEvent2 {
  final String name;
  final int num;
  _DemoEvent2(this.name, this.num);
}
