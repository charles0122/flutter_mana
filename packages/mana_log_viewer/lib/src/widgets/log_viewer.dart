import 'package:flutter/material.dart';
import 'package:mana/mana.dart';

import 'log_viewer_setting.dart';
import 'log_viewer_content.dart';

class LogViewer extends StatefulWidget {
  final String name;

  const LogViewer({super.key, required this.name});

  @override
  State<LogViewer> createState() => _LogViewerState();
}

class _LogViewerState extends State<LogViewer> {
  bool _verboseLogs = false;

  @override
  void initState() {
    super.initState();
    _verboseLogs =
        ManaStore.instance.prefs.getBool('mana_log_viewer_verbose_logs') ??
        false;
  }

  void _onChange(bool? value) async {
    await ManaStore.instance.prefs.setBool(
      'mana_log_viewer_verbose_logs',
      value ?? false,
    );
    setState(() {
      _verboseLogs = value ?? false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ManaFloatingWindow(
      name: widget.name,
      showBarrier: false,
      initialWidth: double.infinity,
      position: PositionType.bottom,
      drag: false,
      content: LogViewerContent(verboseLogs: _verboseLogs),
      setting: LogViewerSetting(
        verboseLogs: _verboseLogs,
        onChanged: _onChange,
      ),
    );
  }
}
