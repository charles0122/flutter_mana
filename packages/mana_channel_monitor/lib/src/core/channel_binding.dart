import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mana_channel_monitor/src/core/mana_binary_messenger.dart';

/// 将默认 BinaryMessenger 替换为监控版本，以捕获通道消息
class ChannelMonitorBinding extends WidgetsFlutterBinding {
  /// 初始化并替换 BinaryMessenger 为监控版本
  static WidgetsBinding? ensureInitialized() {
    // if (WidgetsBinding.instance == null) {
    // make sure init this before WidgetsFlutterBinding ensureInitialized called
    ChannelMonitorBinding();
    // }
    return WidgetsBinding.instance;
  }

  @override
  @protected
  /// 替换默认 BinaryMessenger
  BinaryMessenger createBinaryMessenger() {
    return ChannelMonitorBinaryMessenger.binaryMessenger;
  }
}
