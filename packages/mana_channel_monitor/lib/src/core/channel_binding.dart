import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mana_channel_monitor/src/core/ume_binary_messenger.dart';

/// 将默认 BinaryMessenger 替换为监控版本，以捕获通道消息
class ChannelMonitorBinding extends WidgetsFlutterBinding {
  static WidgetsBinding? ensureInitialized() {
    // if (WidgetsBinding.instance == null) {
    // make sure init this before WidgetsFlutterBinding ensureInitialized called
    ChannelMonitorBinding();
    // }
    return WidgetsBinding.instance;
  }

  @override
  @protected
  // 替换 BinaryMessenger
  BinaryMessenger createBinaryMessenger() {
    return ChannelMonitorBinaryMessenger.binaryMessenger;
  }
}
